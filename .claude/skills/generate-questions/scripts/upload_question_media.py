#!/usr/bin/env python3
"""Uploads verified question images to the `question-media` Supabase Storage
bucket.

Invoked by the generate-questions skill (image/all modes) and never run
standalone with hardcoded secrets: the service_role key is passed as a *file
path* in --input, read into memory here, and never printed/logged. Only
structural results (question ids, object paths, public URLs, byte sizes,
error strings) are written to --output for the calling agent to read back.

Uses only the Python standard library (urllib) so no extra install step is
needed.
"""

from __future__ import annotations

import argparse
import json
import re
import ssl
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

REQUEST_TIMEOUT_SECONDS = 60
MAX_UPLOAD_RETRIES = 2
RETRY_BACKOFF_SECONDS = 1.5

# Only the two formats the Flutter side can render without an SVG/webp
# dependency. The skill is expected to have already picked a jpg/png
# rendition from the source.
CONTENT_TYPE_EXTENSIONS = {
    "image/jpeg": "jpg",
    "image/png": "png",
}

_LANGUAGE_CODE_RE = re.compile(r"^[a-z]{2,3}$")


def _build_ssl_context() -> ssl.SSLContext | None:
    """Some Python installs (notably python.org's on macOS) ship without a
    populated default CA bundle, so `urlopen` fails every HTTPS request with
    CERTIFICATE_VERIFY_FAILED. If `certifi` happens to be installed, use its
    bundle explicitly; otherwise fall back to the interpreter's own default
    (via `None`, still verified, not disabled) rather than skip verification.
    """
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return None


_SSL_CONTEXT = _build_ssl_context()


def load_key(path_str: str) -> str | None:
    path = Path(path_str).expanduser()
    try:
        value = path.read_text(encoding="utf-8").strip()
    except OSError:
        return None
    return value or None


def upload_to_storage(
    *,
    project_url: str,
    bucket: str,
    object_path: str,
    service_role_key: str,
    image_bytes: bytes,
    content_type: str,
) -> tuple[int, bytes]:
    url = f"{project_url}/storage/v1/object/{bucket}/{object_path}"
    request = urllib.request.Request(
        url,
        data=image_bytes,
        method="POST",
        headers={
            "Authorization": f"Bearer {service_role_key}",
            "apikey": service_role_key,
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )
    try:
        with urllib.request.urlopen(
            request, timeout=REQUEST_TIMEOUT_SECONDS, context=_SSL_CONTEXT
        ) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()
    except (urllib.error.URLError, OSError) as error:
        return 0, str(error).encode("utf-8")


def run(input_path: str, output_path: str) -> int:
    config = json.loads(Path(input_path).read_text(encoding="utf-8"))

    project_url: str = config["project_url"].rstrip("/")
    bucket: str = config.get("bucket", "question-media")
    items: list[dict] = config["items"]

    result: dict = {
        "uploaded": [],
        "failed": [],
        "stopped_early": False,
        "stop_reason": None,
    }

    service_role_key = load_key(config["service_role_key_path"])
    if service_role_key is None:
        result["stopped_early"] = True
        result["stop_reason"] = (
            f"Cannot read service_role key file at "
            f"{config['service_role_key_path']!r}."
        )
        Path(output_path).write_text(json.dumps(result, indent=2), encoding="utf-8")
        return 1

    for item in items:
        question_id = str(item.get("question_id", ""))
        language_code = str(item.get("language_code", ""))

        try:
            uuid.UUID(question_id)
        except ValueError:
            result["failed"].append(
                {
                    "question_id": question_id,
                    "stage": "validate",
                    "error": "question_id must be a valid UUID (it becomes the storage object path).",
                }
            )
            continue

        if not _LANGUAGE_CODE_RE.match(language_code):
            result["failed"].append(
                {
                    "question_id": question_id,
                    "stage": "validate",
                    "error": f"language_code {language_code!r} is not a 2-3 letter lowercase code.",
                }
            )
            continue

        file_path = Path(str(item.get("file_path", ""))).expanduser()
        content_type = str(item.get("content_type") or "")
        extension = CONTENT_TYPE_EXTENSIONS.get(content_type)
        if extension is None:
            result["failed"].append(
                {
                    "question_id": question_id,
                    "stage": "validate",
                    "error": (
                        f"Unsupported content_type {content_type!r}; only "
                        f"image/jpeg and image/png are allowed (the skill must "
                        f"download a raster rendition)."
                    ),
                }
            )
            continue

        try:
            image_bytes = file_path.read_bytes()
        except OSError as error:
            result["failed"].append(
                {
                    "question_id": question_id,
                    "stage": "read_file",
                    "error": f"Cannot read {str(file_path)!r}: {error}",
                }
            )
            continue

        if not image_bytes:
            result["failed"].append(
                {
                    "question_id": question_id,
                    "stage": "read_file",
                    "error": f"File {str(file_path)!r} is empty.",
                }
            )
            continue

        object_path = f"{language_code}/{question_id}.{extension}"

        status, body = 0, b""
        for attempt in range(MAX_UPLOAD_RETRIES + 1):
            status, body = upload_to_storage(
                project_url=project_url,
                bucket=bucket,
                object_path=object_path,
                service_role_key=service_role_key,
                image_bytes=image_bytes,
                content_type=content_type,
            )
            if 200 <= status < 300:
                break
            if status == 0 and attempt < MAX_UPLOAD_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS)

        if 200 <= status < 300:
            result["uploaded"].append(
                {
                    "question_id": question_id,
                    "language_code": language_code,
                    "object_path": object_path,
                    "public_url": (
                        f"{project_url}/storage/v1/object/public/"
                        f"{bucket}/{object_path}"
                    ),
                    "size_bytes": len(image_bytes),
                }
            )
        else:
            result["failed"].append(
                {
                    "question_id": question_id,
                    "stage": "storage_upload",
                    "error": (
                        f"HTTP {status}: "
                        f"{body[:300].decode('utf-8', 'replace')}"
                    ),
                }
            )

    Path(output_path).write_text(json.dumps(result, indent=2), encoding="utf-8")
    return 1 if result["stopped_early"] else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Upload verified question images to the question-media Supabase "
            "Storage bucket. Reads the service_role key from a file path in "
            "--input; never prints it."
        )
    )
    parser.add_argument("--input", required=True, help="Path to the upload manifest JSON.")
    parser.add_argument("--output", required=True, help="Path to write the result JSON.")
    args = parser.parse_args()
    return run(args.input, args.output)


if __name__ == "__main__":
    sys.exit(main())
