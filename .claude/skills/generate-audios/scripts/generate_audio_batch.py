#!/usr/bin/env python3
"""Batch-generates ElevenLabs narration for a list of questions and uploads
each clip to a Supabase Storage bucket.

Invoked by the generate-audios skill, never run standalone with hardcoded
secrets: every credential is a *file path* passed in --input, read once into
memory here, and never printed/logged. Only structural results (question ids,
resulting public URLs, error strings) are written to --output for the calling
agent to read back.

Uses only the Python standard library (urllib) so no extra install step is
needed before this script can run.
"""

from __future__ import annotations

import argparse
import json
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

REQUEST_TIMEOUT_SECONDS = 30
MAX_TRANSIENT_RETRIES = 2
RETRY_BACKOFF_SECONDS = 1.5
SLEEP_BETWEEN_REQUESTS_SECONDS = 0.3


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


def is_quota_or_auth_failure(status: int, body: bytes) -> bool:
    if status == 429:
        return True
    if status == 401:
        return True
    return False


def call_elevenlabs(
    *, voice_id: str, api_key: str, text: str, language_code: str,
    model_id: str, output_format: str,
) -> tuple[int, bytes]:
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format={output_format}"
    payload = json.dumps(
        {"text": text, "model_id": model_id, "language_code": language_code}
    ).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=payload,
        method="POST",
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
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


def upload_to_storage(
    *, project_url: str, bucket: str, object_path: str, service_role_key: str,
    audio_bytes: bytes,
) -> tuple[int, bytes]:
    url = f"{project_url}/storage/v1/object/{bucket}/{object_path}"
    request = urllib.request.Request(
        url,
        data=audio_bytes,
        method="POST",
        headers={
            "Authorization": f"Bearer {service_role_key}",
            "apikey": service_role_key,
            "Content-Type": "audio/mpeg",
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    config = json.loads(Path(args.input).read_text(encoding="utf-8"))

    project_url: str = config["project_url"]
    bucket: str = config["bucket"]
    model_id: str = config["model_id"]
    output_format: str = config["output_format"]
    questions: list[dict] = config["questions"]

    result = {
        "generated": [],
        "failed": [],
        "key_events": [],
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
        Path(args.output).write_text(json.dumps(result, indent=2), encoding="utf-8")
        return 1

    usable_keys: list[str] = []
    for i, key_path in enumerate(config["elevenlabs_key_paths"]):
        key = load_key(key_path)
        if key is None:
            result["key_events"].append(
                {"index": i, "path": key_path, "event": "unreadable"}
            )
        else:
            usable_keys.append(key)

    if not usable_keys:
        result["stopped_early"] = True
        result["stop_reason"] = "No usable ElevenLabs API key files were found."
        Path(args.output).write_text(json.dumps(result, indent=2), encoding="utf-8")
        return 1

    key_index = 0

    for question in questions:
        qid = question["id"]
        prompt = question["prompt"]
        language_code = question["language_code"]
        voice_id = question["voice_id"]

        transient_attempts = 0

        while True:
            api_key = usable_keys[key_index]
            status, body = call_elevenlabs(
                voice_id=voice_id,
                api_key=api_key,
                text=prompt,
                language_code=language_code,
                model_id=model_id,
                output_format=output_format,
            )

            if status == 200:
                audio_bytes = body
                break

            if is_quota_or_auth_failure(status, body):
                result["key_events"].append(
                    {
                        "index": key_index,
                        "event": "exhausted_or_rejected",
                        "http_status": status,
                    }
                )
                key_index += 1
                if key_index >= len(usable_keys):
                    result["stopped_early"] = True
                    result["stop_reason"] = (
                        "All ElevenLabs API keys are exhausted or rejected "
                        f"(last HTTP status {status})."
                    )
                    Path(args.output).write_text(
                        json.dumps(result, indent=2), encoding="utf-8"
                    )
                    return 0
                continue  # retry same question with the next key

            transient_attempts += 1
            if transient_attempts > MAX_TRANSIENT_RETRIES:
                result["failed"].append(
                    {
                        "id": qid,
                        "stage": "elevenlabs",
                        "error": f"HTTP {status}: {body[:300]!r}",
                    }
                )
                audio_bytes = None
                break
            time.sleep(RETRY_BACKOFF_SECONDS)

        if audio_bytes is None:
            time.sleep(SLEEP_BETWEEN_REQUESTS_SECONDS)
            continue

        object_path = f"{language_code}/{qid}.mp3"
        up_status, up_body = upload_to_storage(
            project_url=project_url,
            bucket=bucket,
            object_path=object_path,
            service_role_key=service_role_key,
            audio_bytes=audio_bytes,
        )

        if up_status in (200, 201):
            public_url = f"{project_url}/storage/v1/object/public/{bucket}/{object_path}"
            result["generated"].append({"id": qid, "audio_url": public_url})
        else:
            result["failed"].append(
                {
                    "id": qid,
                    "stage": "storage_upload",
                    "error": f"HTTP {up_status}: {up_body[:300]!r}",
                }
            )

        time.sleep(SLEEP_BETWEEN_REQUESTS_SECONDS)

    Path(args.output).write_text(json.dumps(result, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
