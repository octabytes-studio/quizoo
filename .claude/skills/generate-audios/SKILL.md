---
name: generate-audios
description: Generates pre-recorded narration audio (via the ElevenLabs API) for Quizoo questions that don't have one yet, uploads each clip to the `question-audio` Supabase Storage bucket, and links it back by writing `questions.audio_url`. Use when the user wants to backfill question narration, e.g. "generate audio for the remaining questions", "/generate-audios", "/generate-audios -n 20". Always queries Supabase live via MCP to find questions with `audio_url IS NULL`, so every run only ever processes the actual remainder — never re-generates audio that already exists. Caps at 100 questions per run (fewer with `-n <count>`). Skips, per-language, any language whose `languages.voice_id` isn't set. Rotates through a configured list of ElevenLabs API keys on quota/auth failure, stopping only once every key has failed. Requires the Supabase MCP server (Hard Rule 1) and local file paths to the ElevenLabs keys + a Supabase `service_role` key (see Configuration below) — refuses to run without them.
compatibility: Requires the Supabase MCP server to be connected — this skill does not fall back to any other means of reaching the database, per Hard Rule 1. Requires Python 3 (stdlib only, no extra installs) to run the batch script. Requires the Configuration section below to be filled in with real, readable file paths before the first real run — placeholders left as `<...>` cause the skill to stop immediately with instructions, rather than silently skipping key rotation.
---

# Generate Audios

Backfill pre-generated narration audio for Quizoo questions, per plan
`011-pregenerated-question-audio.md`'s consuming-side contract: one MP3 per
question, stored in the `question-audio` Supabase Storage bucket, referenced
by `questions.audio_url`. This is the "separate, out-of-scope authoring
skill" that plan explicitly deferred building — this skill is that piece.

Read `reference/schema-and-api-contract.md` in full now, before continuing —
it has the exact schema, storage path convention, and both external API
contracts (ElevenLabs + Supabase Storage) this skill depends on.

## Configuration — fill in before running

This skill never stores a literal API key in this file or anywhere else in
the repo. Instead, list **absolute file paths outside this project
directory** (e.g. under `~/Documents/` or `~/Desktop/`) whose entire
contents — trimmed of whitespace, nothing else in the file — is exactly one
key.

### ElevenLabs API keys (tried in order; rotates to the next on quota/auth failure — Hard Rule 6)

1. `/Users/waleed/Documents/QuizooKeys/001_elevenlabs_key.txt`
2. `/Users/waleed/Documents/QuizooKeys/002_elevenlabs_key.txt`

Add more numbered lines as needed; at least one is required.

### Supabase `service_role` key (required to upload into `question-audio` — see reference doc's "Storage" section for why the anon key can't be used)

`/Users/waleed/Documents/QuizooKeys/supabase_service_role.txt`

**Before doing anything else**, check every path above. If any still reads
as a literal `<...>` placeholder, or a listed file doesn't exist / can't be
read: stop immediately and tell the user plainly which paths need to be
filled in or fixed, quoting this section. Do not attempt to run the batch
script with a placeholder path — that's not a rule this skill can safely
guess around.

## Hard rules (do not deviate)

1. **Supabase MCP is mandatory, with no fallback.** The very first action of
   any run is a live Supabase query through the MCP server (Step 1). If the
   MCP tool errors, times out, or isn't in your tool list at all: stop right
   there and show the user a clear error. Never fall back to a direct
   Postgres connection, the Supabase CLI, or hardcoded credentials to work
   around an unreachable MCP server.
2. **Only ever target questions with `audio_url IS NULL`.** Every run
   re-queries Supabase fresh (Step 1) — never assume yesterday's result set
   is still accurate. A question that already has an `audio_url` is never
   touched, re-generated, or overwritten.
3. **Hard cap: 100 questions per run.** If more than 100 are eligible, only
   the first 100 (oldest `created_at` first) are processed this run, and the
   final summary must say plainly that the cap was hit and more remain for a
   follow-up run. Never exceed 100 in a single invocation, regardless of
   `-n`.
4. **Voice id comes from `languages.voice_id`, matched to each question's
   `language_code`.** Never hardcode a voice id, never reuse one language's
   voice for another's questions.
5. **If a language's `voice_id` is `NULL`, skip every question in that
   language for this run** — not just the ones that would have been in this
   batch, but the language as a whole is excluded from candidate selection.
   Report which languages were skipped and how many questions each had, in
   the final summary.
6. **API key rotation on quota/auth failure.** If the active ElevenLabs key
   fails with a quota- or auth-shaped error, move to the next configured
   key and retry the same question — do not skip that question just because
   one key failed. If every configured key fails, stop the entire run
   immediately (don't keep burning through remaining questions with a dead
   key list) and say so clearly, including how many were generated before
   the stop.

## Step 1 — connect to Supabase and gather everything needed, in one go

Using the Supabase MCP server's SQL tool (commonly
`mcp__supabase__execute_sql`), run the three read-only queries from
`reference/schema-and-api-contract.md`'s "Candidate-selection SQL" and
"languages skipped" sections:

- The skipped-languages report (which languages have eligible-otherwise
  questions but no `voice_id`, and how many each).
- The candidate list itself, `LIMIT`ed to the **effective cap** (see Step 2).

If this MCP call fails for any reason (tool missing, connection error,
timeout): stop immediately per Hard Rule 1. Tell the user: "Could not reach
Supabase via the MCP server — stopping, per this skill's Hard Rule 1," plus
the underlying error. Do not proceed to any later step.

If the candidate list comes back empty (nothing eligible at all, whether
because everything already has audio or every remaining language lacks a
voice id): stop here and report that plainly — there's nothing to generate.

## Step 2 — resolve the effective cap

- Default cap: **100**.
- If invoked with `-n <count>`: effective cap = `min(count, 100)`. If
  `count > 100`, tell the user you're capping at 100 (Hard Rule 3) rather
  than silently truncating without saying so. If `count < 1`, ask for a
  valid positive integer instead of guessing.
- The effective cap is a ceiling on *how many questions this run attempts*,
  not a guarantee — if fewer than the cap are eligible, process all of them
  and say so (don't imply more existed).

## Step 3 — check the Configuration section

Before spending any ElevenLabs quota: verify every path under
"Configuration" above resolves to a real, readable file (a quick `Read` or
a shell `test -r` check is enough — do not print the file's *contents* into
the conversation, since that would put a raw secret in the transcript for
no benefit). If the Configuration section is still unfilled or broken, stop
here per the Configuration section's own instructions — do not proceed to
Step 4 and silently generate zero clips.

## Step 4 — run the batch script

Write a single JSON input file (e.g. into this session's scratchpad
directory) shaped like:

```json
{
  "project_url": "<from mcp__supabase__get_project_url>",
  "bucket": "question-audio",
  "model_id": "eleven_v3_conversational",
  "output_format": "mp3_44100_128",
  "elevenlabs_key_paths": ["<path 1>", "<path 2>"],
  "service_role_key_path": "<path>",
  "questions": [
    {"id": "...", "prompt": "...", "language_code": "en", "voice_id": "..."}
  ]
}
```

`questions` is exactly Step 1's candidate list (already capped). Then run:

```sh
python3 .claude/skills/generate-audios/scripts/generate_audio_batch.py \
  --input <input.json> --output <output.json>
```

This script is the only thing in this skill that ever touches the actual
key *values* — it reads each key path itself, in its own process, and never
prints a key. Do not read the key files yourself with the `Read` tool before
this step; pass the paths through and let the script open them.

The script handles ElevenLabs calls, key rotation (Hard Rule 6), and
Supabase Storage uploads (`x-upsert: true`, so a rerun after a partial
failure is safe) entirely on its own, one question at a time, and writes a
structured result to `--output`: `generated` (id + resulting `audio_url`),
`failed` (id + stage + error), `key_events`, and `stopped_early`/
`stop_reason` if key exhaustion cut the run short.

Read the output JSON file back (this is safe — it contains no secrets, only
ids/URLs/error strings) to get the results.

## Step 5 — write `audio_url` back, batched

Using the reference doc's "Batched write-back SQL" shape, issue **one**
`UPDATE ... FROM (VALUES ...)` statement via the Supabase MCP SQL tool
covering every entry in `generated` from Step 4's output. Do not issue one
`UPDATE` per row. If `generated` is empty (everything failed or zero keys
worked), skip this step — there's nothing to write.

## Step 6 — final summary to the user

State plainly, in your own words (don't just dump a template):

- **How many audio files were generated** this run, and for which
  language(s).
- **Languages skipped** for lacking a `voice_id` (from Step 1), with counts.
- **Any per-question failures** (from `failed` in the script's output) —
  id + stage + short reason, not just a count, so they're actionable.
- **Whether the run stopped early** due to every ElevenLabs key failing
  (Hard Rule 6) — if so, how many succeeded before the stop, and that the
  user needs to add/refresh keys before the remainder can be generated.
- **Whether the 100-cap was hit** (Hard Rule 3) and, if so, that a follow-up
  run will pick up where this one left off (re-querying `audio_url IS NULL`
  means no extra bookkeeping is needed between runs).
- **How many eligible questions remain** after this run (re-run the
  candidate query as a bare count, no `LIMIT`) — so the user knows whether
  to run this skill again.
