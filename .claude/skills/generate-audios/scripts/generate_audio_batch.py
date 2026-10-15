#!/usr/bin/env python3
"""Batch-generates ElevenLabs narration for a list of questions and uploads
each clip to a Supabase Storage bucket.

Invoked by the generate-audios skill, never run standalone with hardcoded
secrets: every credential is a *file path* passed in --input (or
--keys-json), read once into memory here, and never printed/logged. Only
structural results (question ids, resulting public URLs, the voice id used
for each clip, error strings, language codes) are written to --output for the
calling agent to read back. The api_key is never included in any output; a
voice_id is not a secret and *is* recorded, per question, so the database can
keep provenance of which voice produced each narration.

Two modes:
  --list-languages --keys-json <path> --output <path>
      Reads elevenlabs_keys.json (an array of accounts, each with one
      api_key and a voices list of per-language voice ids) and reports, per
      language, how many usable key/voice pairs exist (and which entries
      were malformed, by index path only). This mode reveals no api_key or
      voice_id value.
  --input <path> --output <path>
      The main batch-generation run.

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


def load_keys_config(
    path_str: str,
) -> tuple[dict[str, list[dict]] | None, list[dict], str | None]:
    """Reads elevenlabs_keys.json and groups key/voice pairs by language,
    preserving file order within each language (that order is the rotation
    sequence).

    The file is a JSON array of *accounts*, each shaped like:

        {"account": "label", "api_key": "sk_...",
         "voices": [{"language": "en", "voice_id": "..."}, ...]}

    Every voice an account lists becomes a (that account's api_key, that
    voice's voice_id) pair under that voice's language. Grouping order is
    accounts outermost (file order), each account's `voices` in their listed
    order — so a language's pair list is the rotation sequence for it. A
    single account's api_key may therefore back pairs in several languages;
    it is always paired with that account's voice_id for the language.

    Returns (grouped, malformed_entries, error). On any fatal problem
    (unreadable file, invalid JSON, not a JSON array), grouped is None and
    error explains why. Malformed entries are reported by index path only
    (e.g. "[0].voices[1]"), never by value.
    """
    path = Path(path_str).expanduser()
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as error:
        return None, [], f"Cannot read keys JSON file at {path_str!r}: {error}"

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as error:
        return None, [], f"Keys JSON file at {path_str!r} is not valid JSON: {error}"

    if not isinstance(data, list):
        return None, [], f"Keys JSON file at {path_str!r} must contain a JSON array."

    grouped: dict[str, list[dict]] = {}
    malformed: list[dict] = []
    for i, account in enumerate(data):
        if not isinstance(account, dict):
            malformed.append({"location": f"[{i}]"})
            continue

        api_key = account.get("api_key")
        if not isinstance(api_key, str) or not api_key.strip():
            malformed.append({"location": f"[{i}]"})
            continue
        api_key = api_key.strip()

        voices = account.get("voices")
        if not isinstance(voices, list) or not voices:
            malformed.append({"location": f"[{i}].voices"})
            continue

        for j, voice in enumerate(voices):
            language = voice.get("language") if isinstance(voice, dict) else None
            voice_id = voice.get("voice_id") if isinstance(voice, dict) else None
            if (
                not isinstance(language, str)
                or not language.strip()
                or not isinstance(voice_id, str)
                or not voice_id.strip()
            ):
                malformed.append({"location": f"[{i}].voices[{j}]"})
                continue
            grouped.setdefault(language.strip(), []).append(
                {"voice_id": voice_id.strip(), "api_key": api_key}
            )

    return grouped, malformed, None


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


def run_list_languages(keys_json_path: str, output_path: str) -> int:
    grouped, malformed, error = load_keys_config(keys_json_path)
    if error is not None:
        Path(output_path).write_text(
            json.dumps({"error": error, "languages": {}, "malformed_entries": []}, indent=2),
            encoding="utf-8",
        )
        return 1

    out = {
        "languages": {lang: len(pairs) for lang, pairs in grouped.items()},
        "malformed_entries": malformed,
    }
    Path(output_path).write_text(json.dumps(out, indent=2), encoding="utf-8")
    return 0


def run_batch(input_path: str, output_path: str) -> int:
    config = json.loads(Path(input_path).read_text(encoding="utf-8"))

    project_url: str = config["project_url"]
    bucket: str = config["bucket"]
    model_id: str = config["model_id"]
    output_format: str = config["output_format"]
    questions: list[dict] = config["questions"]

    result = {
        "generated": [],
        "failed": [],
        "key_events": [],
        "languages_exhausted": [],
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

    grouped, malformed, error = load_keys_config(config["keys_json_path"])
    if error is not None:
        result["stopped_early"] = True
        result["stop_reason"] = error
        Path(output_path).write_text(json.dumps(result, indent=2), encoding="utf-8")
        return 1

    for entry in malformed:
        result["key_events"].append({"event": "malformed_entry", **entry})

    if not grouped:
        result["stopped_early"] = True
        result["stop_reason"] = (
            f"No usable key/voice entries found in "
            f"{config['keys_json_path']!r}."
        )
        Path(output_path).write_text(json.dumps(result, indent=2), encoding="utf-8")
        return 1

    key_index: dict[str, int] = {lang: 0 for lang in grouped}
    exhausted_languages: set[str] = set()

    for question in questions:
        qid = question["id"]
        prompt = question["prompt"]
        language_code = question["language_code"]

        if language_code not in grouped:
            result["failed"].append(
                {
                    "id": qid,
                    "stage": "no_keys_for_language",
                    "error": f"No key/voice entries for language {language_code!r}.",
                }
            )
            continue

        if language_code in exhausted_languages:
            result["failed"].append(
                {
                    "id": qid,
                    "stage": "language_exhausted",
                    "error": (
                        f"All key/voice pairs for language {language_code!r} "
                        "were exhausted earlier in this run."
                    ),
                }
            )
            continue

        transient_attempts = 0
        audio_bytes: bytes | None = None
        used_voice_id: str | None = None

        while True:
            pairs = grouped[language_code]
            idx = key_index[language_code]
            pair = pairs[idx]

            status, body = call_elevenlabs(
                voice_id=pair["voice_id"],
                api_key=pair["api_key"],
                text=prompt,
                language_code=language_code,
                model_id=model_id,
                output_format=output_format,
            )

            if status == 200:
                audio_bytes = body
                used_voice_id = pair["voice_id"]
                break

            if is_quota_or_auth_failure(status, body):
                result["key_events"].append(
                    {
                        "language": language_code,
                        "index": idx,
                        "event": "exhausted_or_rejected",
                        "http_status": status,
                    }
                )
                key_index[language_code] += 1
                if key_index[language_code] >= len(pairs):
                    exhausted_languages.add(language_code)
                    result["failed"].append(
                        {
                            "id": qid,
                            "stage": "elevenlabs",
                            "error": (
                                f"All {len(pairs)} key/voice pairs for language "
                                f"{language_code!r} are exhausted or rejected "
                                f"(last HTTP status {status})."
                            ),
                        }
                    )
                    audio_bytes = None
                    break
                continue  # retry same question with the next pair

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
            result["generated"].append(
                {"id": qid, "audio_url": public_url, "voice_id": used_voice_id}
            )
        else:
            result["failed"].append(
                {
                    "id": qid,
                    "stage": "storage_upload",
                    "error": f"HTTP {up_status}: {up_body[:300]!r}",
                }
            )

        time.sleep(SLEEP_BETWEEN_REQUESTS_SECONDS)

    result["languages_exhausted"] = sorted(exhausted_languages)
    Path(output_path).write_text(json.dumps(result, indent=2), encoding="utf-8")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input")
    parser.add_argument("--output", required=True)
    parser.add_argument("--list-languages", action="store_true")
    parser.add_argument("--keys-json")
    args = parser.parse_args()

    if args.list_languages:
        if not args.keys_json:
            parser.error("--list-languages requires --keys-json")
        return run_list_languages(args.keys_json, args.output)

    if not args.input:
        parser.error("--input is required unless --list-languages is set")
    return run_batch(args.input, args.output)


if __name__ == "__main__":
    sys.exit(main())
