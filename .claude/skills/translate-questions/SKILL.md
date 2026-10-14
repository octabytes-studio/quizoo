---
name: translate-questions
description: Re-expresses existing, already-reviewed live Quizoo questions from one language's pools (English, Spanish, Hindi, Urdu) into Arabic or French, for the same-slug sub-category and difficulty tier, and writes a review-ready HTML file (`review.html`) plus a NOT-yet-executed SQL insert script (`questions.sql`) into a `questions/` folder next to the project directory. Use this instead of authoring brand-new content whenever the target language lacks questions but an identical sub-category already exists in another language — e.g. "translate the English capitals questions into Arabic", "/translate-questions -lang ar -subcategory capitals -tier easy -count 150", or filling Arabic/French pools for parity. Preserves each source question's kind, difficulty tier, correct answer, media and TTS eligibility: image rows reuse the source `media_url` verbatim, figure rows reuse (Arabic relabels) the source artwork, and legacy 3-option image rows are expanded to 4 options with one authored distractor appended. Translated rows are inserted `status = 'live'`, `source = 'translated'`, `translated_from` = the source row id, and `audio_url = NULL` (narration is a separate `generate-audios` run). Never writes to the database — the user reviews `review.html` and runs `questions.sql` themselves.
compatibility: Requires the Supabase MCP server connected for the whole run (target resolution, source fetch, progress) — this skill cannot run or fall back without it. Read-only queries only (`execute_sql` for SELECTs); never uses write/DDL Supabase tools and never touches Supabase Storage. No `service_role` key is needed (nothing is uploaded). A file-writing environment that can create a folder next to the project directory is required (it never falls back to writing inside the repo). If the target language is Arabic and figure rows are translated, macOS `qlmanage` is used for the mandatory render-and-look check; when it is unavailable the skill says so and falls back to `scripts/relabel_figure_svg.py --check` plus a coordinate review (no silent skip).
---

# Translate Questions

Re-express questions that already exist and were already reviewed in one
language (a source pool) into another language, for the same-slug
sub-category + tier — as **draft output for human review**, never as a direct
database write. This is the sibling of `generate-questions`: that skill authors
new content, this one turns existing content into another language.

It exists so Arabic (`ar`) and French (`fr`) — active languages with full
taxonomies but empty pools — become playable without authoring ~10k+ brand-new
questions per language. The "general or identical" sub-categories are matched
**by slug within the same category slug** across languages; culture-specific
sub-categories with no counterpart are out of scope (author them with
`generate-questions`).

| Invocation | What it produces | Question kinds |
|---|---|---|
| `/translate-questions -lang ar -subcategory capitals -tier easy -count 150` | 150 Arabic rows translated from the English pool | `text` (+ `image`/`figure` when the source pool has them) |
| `... -mode text` | Text rows only (excludes media kinds) | `text` |
| `... -status draft` | Same rows, inserted `draft` instead of `live` | any |

## Hard rules (do not deviate)

1. **Never write to the database.** This skill makes **only** read-only
   `SELECT` queries through the Supabase MCP `execute_sql` tool. Never call
   `apply_migration`, never run `INSERT`/`UPDATE`/`DELETE`/DDL, never touch
   Supabase Storage. The user runs the generated SQL script themselves, after
   reviewing it.
2. **Always produce exactly two output files** — `questions.sql` and
   `review.html` (Step 6) — **plus one `<batch>/assets/q<N>.svg` per figure
   row**. Never skip either main file, never merge them, never omit a figure
   asset. `review.html` keeps the `generate-questions` template's UI/UX
   verbatim (same `<style>`, same card skeletons, correct option always mint
   green) and adds one source-comparison line per card.
3. **Reference files are ground truth for format.** Read
   `reference/schema-and-translation-rules.md` in full at the start of every
   run, **and** the sibling
   `../generate-questions/reference/schema-and-samples.md` (the full schema /
   content calibration). Do not re-derive the schema from Flutter source or
   `information_schema`. Live MCP queries are ground truth only for *what
   exists* (target resolution, source rows, progress, existing target pool).
4. **`audio_url` is never written.** It must not appear in the generated
   INSERT column list, so every translated row lands with `audio_url = NULL`
   and is picked up by `generate-audios` later. There is no exception.
5. **Exactly four options, always.** Every translated row (including `image`)
   carries 4 options. A legacy 3-option source image row is expanded by
   authoring one extra plausible *wrong* distractor, appended at the end
   (index 3) — `correct_index` never changes. Flag the authored option in
   `review.html`.
6. **Source priority is English-first.** Query `en`; only when it cannot supply
   the remaining requested rows do you move to `es`, then `hi`, then `ur`.
   Never blend sources just to hit a count English alone can reach. The
   `-source` flag overrides this when the user names one explicitly.
7. **Kind fidelity + reuse.** Preserve each source row's `kind`. Image rows
   reuse the source `media_url` verbatim (no re-upload, no license re-check);
   figure rows reuse the source `figure_svg` as-is, except Arabic relabels the
   four option glyphs. `Credit: …` lines in image explanations stay
   byte-identical; only the preceding sentence is translated.
8. **No duplicate facts and no repeated templates.** No translated row may
   test a fact already in the target sub-category + tier pool, nor repeat a
   fact or prompt template within the batch — regardless of source language.
   Step 5 is the mandatory audit; fix, don't just note.
9. **Refuse before generating on a bad target.** Stop with no files written if:
   Supabase MCP is unavailable; `-lang`/`-subcategory` don't resolve (or
   resolve ambiguously); the resolved sub-category's category language ≠
   `-lang`; `is_active = false`; or `ai_generation_allowed = false`. Report the
   shortfall — never pad — if fewer source rows are available than requested.
10. **Never expose secrets.** Not applicable to normal runs: this skill needs
    no API key, no `service_role` key, and uploads nothing. Never introduce one
    to work around a missing MCP server (Hard rule 1).

## Step 0 — parse args, resolve the target, and read progress

**Parse the invocation first** (flags may appear in any order; values are
case-insensitive):

| Flag | Required | Meaning |
|---|---|---|
| `-lang <code>` | yes | Target language, `ar` or `fr` (must exist and be active). |
| `-subcategory <slug>` | yes | Target sub-category slug, e.g. `capitals`. |
| `-tier <easy\|medium\|hard>` | yes | Difficulty tier. |
| `-count <n>` | no | Rows to translate. Default **150**. Warn above 200 (big review file); split into multiple batches if the user prefers. |
| `-source <en\|es\|hi\|ur>` | no | Force one source language. Default: English-first cascade. |
| `-mode <text\|all>` | no | Default **`all`** (text + image + figure); `text` excludes media kinds. Any other value → stop and list valid values. |
| `-status <live\|draft>` | no | Default **`live`** (owner decision: translated rows go live). |

Read `reference/schema-and-translation-rules.md` **and**
`../generate-questions/reference/schema-and-samples.md` in full now, before
querying anything.

Then, if the Supabase MCP `execute_sql` tool is available (check your tool
list), run the resolve + progress queries from the reference doc
("Resolve the target" and "Remaining per-source counts") to learn:

- the target `subcategory_id`, `category_slug`, category/sub-category display
  names, `is_active`, `ai_generation_allowed`;
- how many untranslated live source rows remain per source language and kind,
  for the requested tier.

Apply the Hard rule 9 guards now:

- MCP tool missing/errors/timeout → **stop**, write nothing, tell the user this
  skill cannot run without the Supabase MCP server.
- Query returns no row → the slug doesn't exist in that language: stop and say
  so (suggest `generate-questions` if this sub-category has no source at all).
- More than one row → ambiguous slug: stop and ask which category.
- `is_active = false` or `ai_generation_allowed = false` → stop and say why.
- `-lang` doesn't match the resolved category's language → stop (the DB
  trigger `trg_enforce_question_language_match` would reject every row).

If the requested count exceeds the remaining source pool for the entire
cascade (summed across `en` → `es` → `hi` → `ur`), that's fine — translate
what exists and report the shortfall (never pad). If the mode is `all` but the
source pool has no `image`/`figure` rows at this tier, the batch is all text;
say so.

## Step 1 — confirm the batch

Summarize back in one short block before fetching or writing anything, and ask
for go/no-go:

```
Target:   <sub-category name> (<slug>) — category <category name>, <Language (code)>
Difficulty: <Label> — tier `<code>`, levels <start>–<end>, <secs>s/question
Requested:  <N> questions (<mode>)
Source:     <source language cascade, and how many remaining rows each offers>
Existing target pool: <count> live rows at this tier
Output:     <parent of project dir>/questions/<folder>/{questions.sql, review.html[, assets/]}
```

State explicitly: rows will be inserted `status = '<live|draft>'`,
`source = 'translated'`, `translated_from` = source id, and `audio_url = NULL`
(narration is a separate `generate-audios` run, currently requiring `ar`/`fr`
entries in `elevenlabs_keys.json`). Ask for a go/no-go or a correction.

## Step 2 — fetch source rows and the existing target pool

Fetch `-count` untranslated live source rows for the target slug + tier, in the
source-priority order (English first; only continue to the next language if
English can't supply the remainder, unless `-source` pins one). Use the
reference doc's "Source rows to translate" query, with `q.kind in ('text')` when
`-mode text`. Rows already translated into the target language are excluded by
the query's `not exists` guard; `on conflict` in the SQL is the backstop.

In the same step, fetch every existing live prompt in the **target**
sub-category + tier (reference doc's "Existing target pool" query) for
fact-level dedup. Keep both sets on hand while translating. If the source
result is empty, stop and report — there is nothing to translate (this can mean
the pool is already fully translated for this language).

## Step 3 — translate

For each source row, produce the target-language row. Hard rules 5–8 and the
reference doc's "Translation-quality rules" apply in full:

- **Native phrasing, never word-for-word.** Keep the tested fact, the
  difficulty, and the option order; rewrite the sentence so it reads as if
  written by a native speaker.
- **Numbers/dates/figures exact; proper nouns in the target language's
  standard form.**
- **Option *i* maps to option *i*.** `correct_index` is carried over unchanged
  — never shuffle.
- **Exactly 4 options** (rule 5). Never leave source-language filler behind
  (only proper nouns and `Credit:` lines may remain non-target).
- **Vary the wording** across the batch and against the existing target pool's
  dominant stems — swap the sentence shape, not just the nouns.

## Step 4 — kind-specific handling

- **`text`** — 4 options; `tts_excluded = false`; prompt and options
  translated.
- **`image`** — copy `media_url` and `tts_excluded` verbatim from the source;
  always 4 options (expand a legacy 3-option row with one authored distractor
  appended at index 3, `correct_index` unchanged); the prompt must not name the
  answer; translate only the sentence(s) before any
  `Credit: <author>, <license short name>, <license URL>.` line and keep that
  line byte-identical. Skip (and report) any image whose subject plausibly
  depends on text baked into the image.
- **`figure`** — copy `figure_svg`; `tts_excluded = true`.
  - **French:** leave the SVG and options as `["A","B","C","D"]`.
  - **Arabic:** save the source SVG to a scratch path, run
    `python3 .claude/skills/translate-questions/scripts/relabel_figure_svg.py --labels rtl <file>`
    (it checks for exactly one each of the single-glyph `A`/`B`/`C`/`D` labels
    and rewrites just those four to `ا/ب/ج/د`), then set options to
    `["ا","ب","ج","د"]`. If the check fails, **skip the row and report it** —
    never guess a mapping.
  - Write the final SVG to `<batch>/assets/q<N>.svg` and render-check it
    (macOS: `qlmanage -t -s 1280 -o <scratch>/svg-preview <file>.svg`, then
    Read the resulting PNG) for every Arabic figure — the mandatory visual
    check. If `qlmanage` is unavailable, say so in the final message and fall
    back to `relabel_figure_svg.py --check` plus a careful coordinate review.
  - Never run `generate-questions/scripts/validate_figure_svg.py`: legacy
    artwork uses the old 640×400 canvas and 2/3.5 strokes and would fail the
    newer 640×360 + stroke-6/3 spec.

## Step 5 — self-audit (mandatory, before any file is written)

Run this pass over the whole batch and **fix** violations, not just note them:

1. **Option count** — every row has exactly 4 options; no 3-option rows; each
   expanded legacy image row's authored distractor is plausible, wrong, and
   distinct from the others; `correct_index` unchanged from the source.
2. **Fact dedup** — no translated row tests a fact already in the fetched
   target pool, and none repeat a fact within the batch (across source
   languages too).
3. **Template variety** — blank each prompt's specifics, group by shape; no
   template reused back-to-back, and no shape dominating the batch; don't
   clone the target pool's dominant stems.
4. **Arabic figures** — every Arabic `figure` row has exactly 4 relabeled
   glyphs and matching `["ا","ب","ج","د"]` options.
5. **Language purity** — no leftover English/Spanish/Hindi/Urdu text anywhere
   except proper nouns (rendered normally) and `Credit:` lines.

Record what the audit changed; it goes in the Step 8 summary.

## Step 6 — write `review.html`

Determine the project root and its parent at run time (never hardcode an
absolute path from this file), and write the batch folder as a sibling of the
project:

```sh
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PARENT_DIR=$(dirname "$PROJECT_ROOT")
OUTPUT_ROOT="$PARENT_DIR/questions"
```

Create `$OUTPUT_ROOT` if needed, then one subfolder named
`<subcategory-slug>-<tier>-<lang>-<YYYYMMDD-HHMMSS>` (timestamp from
`date +%Y%m%d-%H%M%S`). If the environment can't write outside the project,
tell the user — do not fall back to writing inside the repo.

Read `reference/review-template.html`, copy it to the batch folder, and fill it
in. Keep its `<style>` block, colors, fonts, spacing, and structure
**unchanged**; only replace placeholders and expand `{{QUESTIONS}}`. Translate
the two `notice` blocks: the first ("nothing written to the database") applies
as-is; **replace the second (the draft-rows notice) with a translation
notice** — translated rows are inserted `'<live|draft>'`, `audio_url` is
intentionally NULL. Keep the same `<div class="notice notice-warn">` element.

Placeholders:

| Placeholder | Value |
|---|---|
| `{{LANG_CODE}}` | target ISO code, e.g. `ar`, `fr` |
| `{{LANGUAGE_CODE}}` | same, as displayed text |
| `{{DIR}}` | `rtl` for `ar`, `ltr` for `fr` |
| `{{PAGE_TITLE}}` | `<Subcategory name> — <Language name> (<Difficulty label>) · Quizoo Review` |
| `{{SUBCATEGORY_NAME}}` / `{{SUBCATEGORY_SLUG}}` / `{{SUBCATEGORY_ID}}` | target values |
| `{{CATEGORY_NAME}}` / `{{LANGUAGE_NAME}}` | target values |
| `{{DIFFICULTY_LABEL}}` / `{{TIER_CODE}}` / `{{LEVELS}}` / `{{SECS}}` | tier values |
| `{{MODE}}` | `translate` |
| `{{SPLIT}}` | actual kind split + sources, e.g. `24 text, 6 image · source: en` |
| `{{COUNT}}` | total rows in the batch |
| `{{GENERATED}}` | current date |
| `{{QUESTIONS}}` | one card per question, numbered to match `-- Q<N>` |

One `<article class="card">` per question, using the template's exact kind
skeleton (text / image / figure — the image skeleton's media `<figure>` and the
figure skeleton's `assets/q<N>.svg`). The correct option carries
`class="option correct"` plus `<span class="mark">✓</span>`. Status chip is
`chip-live` or `chip-draft` per `-status`. **Add exactly one source line per
card**, immediately after the explanation:

```html
<p class="source">Source: <SOURCE_LANG> · <code><SOURCE_ID></code> — “<SOURCE_PROMPT>”</p>
```

For an expanded legacy image row, mark the authored option inside its
`opt-text`, e.g. `<OPTION_D> <em>(new — authored distractor)</em>`.

For an RTL Arabic batch use the labels `ا ب ج د` for every option key and
`opt-text` (and the figure SVG already carries them). HTML-escape every value
inserted into a text position (`&`→`&amp;`, `<`→`&lt;`, `>`→`&gt;`); keep
`src`/`href`/`alt` in double quotes.

Before finishing: `grep -c '{{' review.html` must print `0`; the number of
`class="option correct"` occurrences must equal the question count; every
referenced `assets/q<N>.svg` must exist; every `<article>` must be closed.

## Step 7 — write `questions.sql`

A single self-contained transaction with the guard block from the plan. Fill in
every placeholder; keep the shape exactly (including `audio_url` **absent** from
the column list):

```sql
-- Generated by translate-questions.
-- Target: <subcategory name> (<slug>) — <Language name> (<code>)
-- Difficulty: <Label> (tier `<code>`), <N> questions, source pool: <src lang(s)>
-- Review the paired review.html FIRST. Nothing is saved until you run this.

begin;

do $$
declare
  v_subcategory_id uuid := '<TARGET_SUBCATEGORY_ID>';
  v_language_code  text := '<TARGET_LANG>';
  v_category_lang  text;
  v_ai_allowed     boolean;
begin
  select c.language_code, s.ai_generation_allowed
    into v_category_lang, v_ai_allowed
  from subcategories s join categories c on c.id = s.category_id
  where s.id = v_subcategory_id;

  if v_category_lang is null then
    raise exception 'Subcategory % does not exist.', v_subcategory_id;
  end if;
  if v_category_lang <> v_language_code then
    raise exception 'Language mismatch: subcategory % belongs to "%", script targets "%".',
      v_subcategory_id, v_category_lang, v_language_code;
  end if;
  if v_ai_allowed is false then
    raise exception 'Subcategory % has ai_generation_allowed = false.', v_subcategory_id;
  end if;
end $$;

insert into questions (
  id, subcategory_id, kind, difficulty, difficulty_tier_id,
  language_code, status, source, options, correct_index,
  explanation, prompt, media_url, figure_svg, tts_excluded,
  translated_from
) values
  -- Q1 (text) <- en <source-uuid>: <first words of the source prompt>
  (gen_random_uuid(), '<TARGET_SUBCATEGORY_ID>', 'text', 1,
   (select id from difficulty_tiers where code = 'easy'),
   'ar', 'live', 'translated',
   '["<option 1>","<option 2>","<option 3>","<option 4>"]'::jsonb, 2,
   '<translated explanation>', '<translated prompt>', null, null, false,
   '<source-uuid>'::uuid)
  -- ... one tuple per question; image tuples carry the reused media_url and
  -- 4 options (a 4th distractor authored where the source had 3, appended at
  -- the end); figure tuples carry the (relabeled) figure_svg and
  -- tts_excluded = true. audio_url is deliberately NOT in the column list.
on conflict (translated_from, language_code) where translated_from is not null
  do nothing
returning id, prompt, translated_from;

commit;
```

Notes for whoever edits this file after reviewing `review.html`:

- `difficulty` int per tier: easy 1, medium 2, hard 3.
- `correct_index` stays identical to the source's — options are translated in
  place, order preserved.
- Image rows: `media_url` = the source URL (kept in the source language's
  folder — intentional); always 4 options (legacy 3-option sources gain one
  authored distractor at index 3, `correct_index` unchanged).
- Figure rows (Arabic): `options = ["ا","ب","ج","د"]`, SVG relabeled; French:
  options and SVG unchanged.
- Double every literal `'` inside text (SQL escaping); escape `"` inside
  option JSON as `\"`.
- To drop a question: delete its tuple and the `-- Q<N>` comment, fix commas.
- Re-running the script is safe: the `on conflict … do nothing` clause and the
  `uq_questions_translation_target` index make it idempotent.

## Step 8 — final message to the user

State plainly, in your own words:

- Both file paths (the full `questions/<batch>/...` paths, next to the project
  directory, not inside it), plus `assets/` when figure rows exist.
- `-mode`, the actual kind split, and which source language(s) were used (and
  whether English alone sufficed).
- The self-audit result (Step 5): what it changed (facts dropped/replaced,
  templates rewritten, authored distractors added), and that no 3-option rows
  were emitted.
- For Arabic figure rows: that each passed `relabel_figure_svg.py` and was
  rendered and visually checked — or, if `qlmanage` was unavailable, that the
  visual check could not run.
- The status choice (`live` by default), and that `audio_url` is NULL so
  `generate-audios` will pick these rows up later (currently blocked for
  `ar`/`fr` until `elevenlabs_keys.json` has entries for them).
- A one-line reminder: nothing was saved to the database — review
  `review.html`, then run `questions.sql` in the Supabase SQL editor yourself.
