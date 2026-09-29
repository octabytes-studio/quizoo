---
name: generate-audios
description: Generates pre-recorded narration audio (via the ElevenLabs API) for Quizoo questions that don't have one yet, uploads each clip to the `question-audio` Supabase Storage bucket, and links it back by writing `questions.audio_url`. Use when the user wants to backfill question narration, e.g. "generate audio for the remaining questions", "/generate-audios", "/generate-audios -n 20". Always queries Supabase live via MCP to find questions with `audio_url IS NULL`, so every run only ever processes the actual remainder — never re-generates audio that already exists. Defaults to 100 questions per run; `-n <count>` processes that many instead, with no upper limit. API keys and voice ids come from a single `elevenlabs_keys.json` file (one entry per key/voice pair, possibly several per language) kept one directory above the project; any language with zero entries in that file is skipped entirely. Rotates through a language's configured key/voice pairs on quota/auth failure, moving on once that language's pairs are all exhausted while continuing other languages. Requires the Supabase MCP server (Hard Rule 1) and local file paths to the ElevenLabs keys JSON + a Supabase `service_role` key (see Configuration below) — refuses to run without them.
compatibility: Requires the Supabase MCP server to be connected — this skill does not fall back to any other means of reaching the database, per Hard Rule 1. Requires Python 3 (stdlib only, no extra installs) to run the batch script. Requires the Configuration section below to resolve to real, readable files before the first real run — a missing or malformed `elevenlabs_keys.json` causes the skill to stop immediately with instructions, rather than silently skipping key rotation or querying Supabase for the wrong languages.
---

# Generate Audios

Backfill pre-generated narration audio for Quizoo questions, per plan
`011-pregenerated-question-audio.md`'s consuming-side contract: one MP3 per
question, stored in the `question-audio` Supabase Storage bucket, referenced
by `questions.audio_url`. This is the "separate, out-of-scope authoring
skill" that plan explicitly deferred building — this skill is that piece.

Read `reference/schema-and-api-contract.md` in full now, before continuing —
it has the exact schema, storage path convention, the `elevenlabs_keys.json`
format, and both external API contracts (ElevenLabs + Supabase Storage) this
skill depends on.

## Configuration — fill in before running

This skill never stores a literal API key in this file or anywhere else in
the repo. Instead it points at **absolute file paths outside this project
directory** whose contents carry the real secrets.

### ElevenLabs API keys + voice ids

A single JSON file, always expected **one directory above the project root**
(i.e. the project's parent directory), named `elevenlabs_keys.json`:

`/Users/waleed/Documents/projects/elevenlabs_keys.json`

This file is a JSON array. Each element is one key/voice pair for one
language:

```json
[
  {"language": "en", "voice_id": "MN7bvz2v9Z55XnbHzEk4", "api_key": "sk_..."},
  {"language": "en", "voice_id": "AnotherVoiceIdHere",   "api_key": "sk_..."},
  {"language": "ur", "voice_id": "o85TqPN3F4P7dWae2paA", "api_key": "sk_..."}
]
```

A language may have any number of entries (zero, one, or many). Multiple
entries for the same language are different accounts' key + voice pairs and
are tried **in file order** for that language (Hard Rule 6). A language with
**zero** entries in this file is not eligible for this run at all — see Hard
Rule 5. See `reference/schema-and-api-contract.md` for full format rules.

### Supabase `service_role` key (required to upload into `question-audio` — see reference doc's "Storage" section for why the anon key can't be used)

`/Users/waleed/Documents/QuizooKeys/supabase_service_role.txt`

**Before doing anything else**, resolve the paths above (Step 1 does this).
If the keys JSON doesn't exist, isn't valid JSON, isn't a JSON array, or
contains zero valid entries; or the service-role key file doesn't exist /
can't be read: stop immediately and tell the user plainly which path needs
to be fixed, quoting this section. Do not attempt to run the batch script
against a broken config — that's not a rule this skill can safely guess
around.

## Hard rules (do not deviate)

1. **Supabase MCP is mandatory, with no fallback.** The first
   *Supabase*-touching action of any run is a live query through the MCP
   server (Step 2 — it necessarily comes after Step 1's local, secret-free
   key/voice preflight, since that step determines which languages to even
   query for). If the MCP tool errors, times out, or isn't in your tool list
   at all: stop right there and show the user a clear error. Never fall back
   to a direct Postgres connection, the Supabase CLI, or hardcoded
   credentials to work around an unreachable MCP server.
2. **Only ever target questions with `audio_url IS NULL`.** Every run
   re-queries Supabase fresh (Step 2) — never assume yesterday's result set
   is still accurate. A question that already has an `audio_url` is never
   touched, re-generated, or overwritten.
3. **Effective count defaults to 100, with no upper limit.** Without `-n`,
   process up to 100 eligible questions (oldest `created_at` first). With
   `-n <count>`, process up to that many instead — any positive integer,
   however large; there is no cap to enforce. If more are eligible than the
   effective count, only the oldest that many are processed this run, and
   the final summary must say plainly that more remain for a follow-up run.
4. **Voice id and API key come from `elevenlabs_keys.json`, matched to each
   question's `language_code`.** Never hardcode a voice id or key, never
   reuse one language's pair for another's questions. `languages.voice_id`
   in Supabase is no longer read or trusted by this skill for any purpose.
5. **If a language has no entries in `elevenlabs_keys.json`, skip every
   question in that language for this run** — not just the ones that would
   have been in this batch, but the language as a whole is excluded from
   candidate selection (Step 2 only queries Supabase for languages that have
   at least one entry). Report which languages were skipped and how many
   questions each had, in the final summary.
6. **API key + voice rotation on quota/auth failure, scoped per language.**
   If the active key/voice pair for a question's language fails with a
   quota- or auth-shaped error, move to the *next* configured pair for that
   *same language* and retry the same question — do not skip that question
   just because one pair failed. If every configured pair for a language is
   exhausted, stop generating for **that language only** for the rest of
   this run (its remaining candidate questions in this run are marked
   failed) and continue processing other languages normally — other
   languages have their own independent key/voice lists and are unaffected.
   Only a fatal config problem (Configuration section unreadable/empty)
   stops the entire run.

## Step 1 — load the key/voice configuration (local, no secrets exposed)

Run the batch script in list-languages mode against the fixed
`elevenlabs_keys.json` path from Configuration:

```sh
python3 .claude/skills/generate-audios/scripts/generate_audio_batch.py \
  --list-languages --keys-json /Users/waleed/Documents/projects/elevenlabs_keys.json \
  --output <scratchpad>/languages.json
```

This mode never prints an API key or voice id — it only reports, per
language, how many usable key/voice entries exist, plus how many entries
were malformed (missing/empty `language`, `voice_id`, or `api_key`) and
their indices. Read `<scratchpad>/languages.json` back; it's safe, it
contains no secrets.

- If the script exits non-zero (file missing, not valid JSON, not a JSON
  array): stop immediately per the Configuration section's instructions —
  quote the reported error.
- If the file parses but `languages` is empty (every entry was malformed, or
  the array itself was empty): stop immediately — there are no usable
  key/voice pairs at all.
- If some entries were malformed but at least one language has usable
  entries: proceed, but mention the malformed entry count/indices in the
  final summary (Step 6) so the user can fix their JSON file.
- Also verify the Supabase `service_role` key path from Configuration is a
  real, readable file (a quick `Read` or shell `test -r` is enough — do not
  print its *contents*). If unreadable, stop here per the Configuration
  section.

The set of language codes with `languages[code] > 0` is this run's
**eligible language set** — carry it into Step 2.

## Step 2 — connect to Supabase and gather everything needed, in one go

Using the Supabase MCP server's SQL tool (commonly
`mcp__supabase__execute_sql`), run the queries from
`reference/schema-and-api-contract.md`'s "Candidate-selection SQL" and
"languages skipped" sections, using Step 1's eligible language set to fill
in the `language_code in (...)` / `not in (...)` lists:

- The skipped-languages report (which languages have eligible-otherwise
  questions but no entry in `elevenlabs_keys.json`, and how many each). If
  the eligible language set from Step 1 is empty, skip the `in (...)` /
  `not in (...)` filter entirely and just group all remaining
  eligible-otherwise questions by `language_code` — every one of them is
  skipped this run.
- The candidate list itself (restricted to the eligible language set),
  `LIMIT`ed to the **effective count** (see Step 3).

If this MCP call fails for any reason (tool missing, connection error,
timeout): stop immediately per Hard Rule 1. Tell the user: "Could not reach
Supabase via the MCP server — stopping, per this skill's Hard Rule 1," plus
the underlying error. Do not proceed to any later step.

If the candidate list comes back empty (nothing eligible at all, whether
because everything already has audio or every remaining language lacks a
key/voice entry): stop here and report that plainly — there's nothing to
generate.

## Step 3 — resolve the effective count

- Default: **100**.
- If invoked with `-n <count>`: effective count = `count`, used as-is — no
  upper limit is enforced, however large `count` is. If `count < 1`, ask
  for a valid positive integer instead of guessing.
- The effective count is a ceiling on *how many questions this run
  attempts*, not a guarantee — if fewer than that are eligible, process all
  of them and say so (don't imply more existed).

## Step 4 — run the batch script

Write a single JSON input file (e.g. into this session's scratchpad
directory) shaped like:

```json
{
  "project_url": "<from mcp__supabase__get_project_url>",
  "bucket": "question-audio",
  "model_id": "eleven_v3_conversational",
  "output_format": "mp3_44100_128",
  "keys_json_path": "/Users/waleed/Documents/projects/elevenlabs_keys.json",
  "service_role_key_path": "<path>",
  "questions": [
    {"id": "...", "prompt": "...", "language_code": "en"}
  ]
}
```

`questions` is exactly Step 2's candidate list (already limited to the
effective count) — note there
is no `voice_id` per question anymore; the script resolves voice id (and
which key to use) itself, per language, with its own rotation state. Then
run:

```sh
python3 .claude/skills/generate-audios/scripts/generate_audio_batch.py \
  --input <input.json> --output <output.json>
```

This script is the only thing in this skill that ever touches the actual
key/voice *values* — it reads `keys_json_path` itself, in its own process,
and never prints a key or voice id. Do not read the keys JSON file yourself
with the `Read` tool at this point either; pass the path through and let the
script open it (Step 1's `--list-languages` mode is the one sanctioned way
to learn anything about its contents from the conversation side, and even
that only reveals language names and counts).

The script handles ElevenLabs calls, per-language key/voice rotation (Hard
Rule 6), and Supabase Storage uploads (`x-upsert: true`, so a rerun after a
partial failure is safe) entirely on its own, one question at a time, and
writes a structured result to `--output`: `generated` (id + resulting
`audio_url`), `failed` (id + stage + error), `key_events`, `languages_exhausted`
(languages whose key/voice pairs all failed mid-run), and `stopped_early`/
`stop_reason` if a fatal config problem cut the whole run short.

Read the output JSON file back (this is safe — it contains no secrets, only
ids/URLs/error strings/language codes) to get the results.

## Step 5 — write `audio_url` back, batched

Using the reference doc's "Batched write-back SQL" shape, issue **one**
`UPDATE ... FROM (VALUES ...)` statement via the Supabase MCP SQL tool
covering every entry in `generated` from Step 4's output. Do not issue one
`UPDATE` per row. If `generated` is empty (everything failed or zero
key/voice pairs worked), skip this step — there's nothing to write.

## Step 6 — final summary to the user

State plainly, in your own words (don't just dump a template):

- **How many audio files were generated** this run, and for which
  language(s).
- **Languages skipped entirely** for lacking any entry in
  `elevenlabs_keys.json` (from Step 2), with counts.
- **Malformed entries in `elevenlabs_keys.json`**, if any were reported in
  Step 1 (indices), so the user can fix their file.
- **Any per-question failures** (from `failed` in the script's output) —
  id + stage + short reason, not just a count, so they're actionable.
- **Any languages that got exhausted mid-run** (`languages_exhausted` in the
  script's output) — i.e. every configured key/voice pair for that language
  failed during this run — and that the user needs to add/refresh
  key/voice entries for that language in `elevenlabs_keys.json` before its
  remainder can be generated. Other languages are unaffected by this.
- **Whether the whole run stopped early** due to a fatal config problem
  (`stopped_early`/`stop_reason`) — this should only happen for setup
  issues, not ordinary per-language exhaustion.
- **Whether more were eligible than the effective count** (Hard Rule 3) and,
  if so, that a follow-up run will pick up where this one left off
  (re-querying `audio_url IS NULL` means no extra bookkeeping is needed
  between runs).
- **How many eligible questions remain** after this run (re-run the
  candidate query as a bare count, no `LIMIT`, restricted to the same
  eligible language set) — so the user knows whether to run this skill
  again.
