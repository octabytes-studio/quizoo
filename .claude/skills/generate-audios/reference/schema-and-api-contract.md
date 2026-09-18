# Quizoo question-audio schema & API contract reference

Static reference data captured from the live Quizoo Supabase project and from
plan `011-pregenerated-question-audio.md` (which designed the consuming side
of this exact feature) on 2026-09-18. `SKILL.md` points here so the skill
doesn't have to re-derive this at run time. If the live schema ever changes,
update this file.

## Table: `questions` — columns this skill reads/writes

| Column | Type | Relevance |
|---|---|---|
| `id` | uuid | Storage object path and SQL update key. |
| `prompt` | text | The exact text sent to ElevenLabs — narration is of the question prompt only, never the answer options (matches the pre-plan-011 live behavior of `TtsService.speak(question.text)`, where `text` was sourced from `prompt`). |
| `language_code` | text | FK → `languages.code`. Selects which voice to use and which storage sub-folder the clip goes in. |
| `status` | text | This skill only ever generates audio for `status = 'live'` questions — narrating `draft`/`suspended` content wastes ElevenLabs quota on rows that aren't served to users yet (or ever). |
| `tts_excluded` | boolean | Rows with `tts_excluded = true` are permanently skipped — per plan 011's own design note, these are expected to never get an `audio_url` (they lean on visuals a voice can't describe). |
| `audio_url` | text, nullable | The column this skill fills in. `NULL` = "needs audio, eligible" (until Hard Rule 4/5 language gating narrows that further). Never overwritten if already non-`NULL` — that's what makes reruns only pick up the remainder. |

## Table: `languages` — the voice_id gate (Hard Rules 4 & 5)

| Column | Relevance |
|---|---|
| `code` | Joins to `questions.language_code`. |
| `voice_id` | The ElevenLabs voice id to use for every question in that language. `NULL` ⇒ **skip every question of that language entirely** for this run — do not guess or fall back to another language's voice. |

Snapshot as of 2026-09-18 (always re-query live — this row set changes as
languages are added/activated):

| `code` | name | `voice_id` |
|---|---|---|
| `en` | English | `MN7bvz2v9Z55XnbHzEk4` |
| `ur` | Urdu | `o85TqPN3F4P7dWae2paA` |
| `hi` | Hindi | `NULL` — not yet provisioned |
| `ar` | Arabic | `NULL` |
| `fr` | French | `NULL` |
| `es` | Spanish | `NULL` |

## Storage: `question-audio` bucket

- **Already exists**, public-read (created by plan 011's migration
  `20260917100100_question_audio_storage_bucket.sql`). This skill never
  creates or alters the bucket or its policies.
- **No authenticated-insert policy exists on it** — only public `select`.
  Uploads must use the project's `service_role` key, which bypasses RLS/storage
  policies entirely. This is why the skill needs a `service_role` key path,
  not just the app's anon key.
- **Path convention**: `question-audio/<language_code>/<question id>.mp3` —
  one object per question row, exactly mirroring plan 011's documented
  contract. Do not change this shape; the Flutter app's `audio_url` values
  and any future re-runs of this skill depend on it being stable.
- **Public URL shape**: `<project_url>/storage/v1/object/public/question-audio/<language_code>/<id>.mp3`
  — this is the exact string written into `questions.audio_url`.
- **Format**: mp3, `output_format=mp3_44100_128` — matches what the
  now-deleted `ElevenLabsTtsApi`/`ElevenLabsTtsService` already used, so any
  clip this skill produces is bit-format-compatible with anything generated
  under the old live-synthesis code path.

## ElevenLabs API contract

Endpoint (from the deleted `lib/features/quiz_play/data/elevenlabs_tts_api.dart`,
preserved here since that file no longer exists in the repo):

```
POST https://api.elevenlabs.io/v1/text-to-speech/<voice_id>?output_format=mp3_44100_128
Headers:
  xi-api-key: <key>
  Content-Type: application/json
Body:
  {"text": "<question prompt>", "model_id": "eleven_v3_conversational", "language_code": "<language_code>"}
```

Response body (200): raw `audio/mpeg` bytes — no JSON wrapper.

`eleven_v3_conversational` is the same model id the app used previously; it
was chosen (per plan 010) as the only ElevenLabs model family that covers
this project's non-English content (Urdu). Keep using it unless a future
plan changes it.

### Key-failure handling (Hard Rule 6)

ElevenLabs signals quota exhaustion and auth failure both via 4xx status
codes, most commonly:
- `401` — either an expired/invalid key *or* a quota-exceeded key (the JSON
  body's `detail.status` distinguishes them, but this skill treats **both
  the same way**: rotate to the next key). Looping requests against a key
  that will never succeed is worse than rotating one key too eagerly.
- `429` — rate-limited / over quota.

Any other status (400 bad request, 5xx, network timeout) is treated as a
per-question failure, not a key failure — retried a couple of times, then
that single question is marked failed and the run moves on to the next
question with the *same* key still active.

## Supabase Storage upload contract

```
POST <project_url>/storage/v1/object/question-audio/<language_code>/<id>.mp3
Headers:
  Authorization: Bearer <service_role_key>
  apikey: <service_role_key>
  Content-Type: audio/mpeg
  x-upsert: true
Body: raw mp3 bytes
```

`x-upsert: true` makes the upload idempotent — safe to re-run this skill
after a partial failure without first checking whether the object already
exists (e.g. TTS succeeded, upload succeeded, but the DB `UPDATE` step never
ran because the process was interrupted — a rerun just overwrites the same
object with the same bytes and proceeds to retry the `UPDATE`).

## Candidate-selection SQL (Hard Rules 2, 4, 5)

Eligible candidates (feed to the batch script, `LIMIT` = the effective cap):

```sql
select q.id, q.prompt, q.language_code, l.voice_id
from questions q
join languages l on l.code = q.language_code
where q.audio_url is null
  and q.status = 'live'
  and q.tts_excluded = false
  and l.voice_id is not null
order by q.created_at asc
limit <EFFECTIVE_CAP>;
```

Languages skipped entirely for lacking a `voice_id` (report these by name in
the final summary, per Hard Rule 5):

```sql
select q.language_code, count(*) as missing_count
from questions q
join languages l on l.code = q.language_code
where q.audio_url is null
  and q.status = 'live'
  and q.tts_excluded = false
  and l.voice_id is null
group by q.language_code
order by q.language_code;
```

Remaining eligible count after a run (re-run the first query's `where`
clause as a bare `count(*)`, no `limit`) — report this so the user knows
whether another run is needed.

## Batched write-back SQL

After the batch script returns, write all successes back in one statement
(never one `UPDATE` per row — this table can have hundreds of rows in a
single run):

```sql
update questions as q
set audio_url = v.audio_url
from (values
  ('<id-1>'::uuid, '<url-1>'),
  ('<id-2>'::uuid, '<url-2>')
) as v(id, audio_url)
where q.id = v.id;
```
