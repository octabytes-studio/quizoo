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

## `elevenlabs_keys.json` — the key/voice gate (Hard Rules 4 & 5)

As of 2026-09-29 this skill no longer reads `languages.voice_id` for
anything (that column may still exist in Supabase for app-level purposes,
but this skill neither reads nor writes it). Instead, key and voice
selection is entirely driven by a local JSON file, always expected one
directory above the project root:

`/Users/waleed/Documents/projects/elevenlabs_keys.json`

Format — a JSON array of objects, one per key/voice pair:

```json
[
  {"language": "en", "voice_id": "MN7bvz2v9Z55XnbHzEk4", "api_key": "sk_..."},
  {"language": "en", "voice_id": "AnotherVoiceIdHere",   "api_key": "sk_..."},
  {"language": "ur", "voice_id": "o85TqPN3F4P7dWae2paA", "api_key": "sk_..."}
]
```

| Field | Relevance |
|---|---|
| `language` | Matches `questions.language_code`. A language with zero entries anywhere in the array ⇒ **skip every question of that language entirely** for this run — do not guess or fall back to another language's voice/key. |
| `voice_id` | The ElevenLabs voice id for this specific key/voice pair. |
| `api_key` | The ElevenLabs API key paired with that `voice_id`. Always used together — never mix a `voice_id` from one entry with an `api_key` from another. |

A language may have any number of entries. When a language has multiple
entries, they are tried **in file order** as the rotation sequence for that
language (see "Key-failure handling" below) — each rotation step swaps in
the *next entry's* `api_key` **and** `voice_id` together, not just the key.

An entry missing/empty `language`, `voice_id`, or `api_key` is malformed and
is skipped when the batch script loads the file (reported by index, never by
value, so no partial secret ever surfaces in a transcript). A malformed
entry does not invalidate the rest of the file.

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
  the same way**: rotate to the next key/voice pair *for that language*).
  Looping requests against a key that will never succeed is worse than
  rotating one pair too eagerly.
- `429` — rate-limited / over quota.

Any other status (400 bad request, 5xx, network timeout) is treated as a
per-question failure, not a key failure — retried a couple of times, then
that single question is marked failed and the run moves on to the next
question with the *same* key/voice pair still active.

Rotation is scoped **per language**, since each language has its own
independent list of key/voice pairs from `elevenlabs_keys.json`. Exhausting
every pair for one language (e.g. all 10 English pairs failing) stops
generation for that language only — the run continues normally with other
languages, each tracking rotation state independently. This is a deliberate
change from a single project-wide key list: with per-language pairs, one
language's exhaustion carries no information about another's.

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

## Candidate-selection SQL (Hard Rules 2, 4, 5, 7)

`<ELIGIBLE_LANGUAGES>` is the set of language codes that have at least one
entry in `elevenlabs_keys.json`, from Step 1 of `SKILL.md` — e.g.
`'en', 'ur'`. No join to the `languages` table is needed for this purpose
anymore.

Eligible candidates (feed to the batch script, `LIMIT` = the effective
count — default 100, or whatever `-n <count>` requested, with no upper
limit):

```sql
select q.id, q.prompt, q.language_code
from questions q
where q.audio_url is null
  and q.status = 'live'
  and q.tts_excluded = false
  and q.language_code in (<ELIGIBLE_LANGUAGES>)
order by q.created_at asc
limit <EFFECTIVE_COUNT>;
```

With `-f` (explicit-scope mode): `<FILE_IDS>` is the de-duplicated id set from
Step 1's `-f` file, written as a comma-separated list of quoted uuid string
literals (e.g. `'uuid-1', 'uuid-2', ...`). The same gates still apply, so an
id listed in the file but already carrying an `audio_url` (or otherwise
ineligible) is excluded here and thus never regenerated. `LIMIT` still
applies — see `SKILL.md` Step 3 for what the effective count is in `-f` mode:

```sql
select q.id, q.prompt, q.language_code
from questions q
where q.id in (<FILE_IDS>)
  and q.audio_url is null
  and q.status = 'live'
  and q.tts_excluded = false
  and q.language_code in (<ELIGIBLE_LANGUAGES>)
order by q.created_at asc, q.id asc
limit <EFFECTIVE_COUNT>;
```

Languages skipped entirely for lacking any `elevenlabs_keys.json` entry
(report these by name in the final summary, per Hard Rule 5):

```sql
select q.language_code, count(*) as missing_count
from questions q
where q.audio_url is null
  and q.status = 'live'
  and q.tts_excluded = false
  and q.language_code not in (<ELIGIBLE_LANGUAGES>)
group by q.language_code
order by q.language_code;
```

With `-f`, scope that same report to the file's ids:

```sql
select q.language_code, count(*) as missing_count
from questions q
where q.id in (<FILE_IDS>)
  and q.audio_url is null
  and q.status = 'live'
  and q.tts_excluded = false
  and q.language_code not in (<ELIGIBLE_LANGUAGES>)
group by q.language_code
order by q.language_code;
```

File-id audit (only in `-f` mode) — how the file's ids break down, so Step 6
can report ids already done vs. still eligible. `<FILE_IDS>` is the
de-duplicated id set from Step 1:

```sql
select
  count(*)                                                          as file_ids_found,
  count(*) filter (where audio_url is not null)                     as already_have_audio,
  count(*) filter (
    where audio_url is null
      and (status <> 'live' or tts_excluded)
  )                                                                 as ineligible_status_or_excluded,
  count(*) filter (
    where audio_url is null
      and status = 'live'
      and tts_excluded = false
  )                                                                 as eligible
from questions
where id in (<FILE_IDS>);
```

File ids that don't exist in the table are not counted by `file_ids_found`;
Step 6 reports the gap between the file's unique id count and that total as
"not found".

If `<ELIGIBLE_LANGUAGES>` is empty (no language has any entry in
`elevenlabs_keys.json` at all), drop the `not in (...)` clause entirely
(an empty `IN`/`NOT IN` list is invalid SQL) and just group every
otherwise-eligible question by `language_code` — all of them are skipped
this run.

Remaining eligible count after a run (re-run the first query's `where`
clause as a bare `count(*)`, no `limit`) — report this so the user knows
whether another run is needed. In `-f` mode, re-run the `-f` candidate
query's `where` clause (including the `id in (<FILE_IDS>)` restriction) as a
bare `count(*)` to get how many of that file's ids are still eligible.

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
