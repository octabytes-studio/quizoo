---
name: generate-questions
description: Interactively generates a batch of Quizoo multiple-choice quiz questions for one sub-category, difficulty tier, and language, in Quizoo's exact `questions` table format. Use when the user wants to author new quiz content, e.g. "generate 50 questions for Cricket", "add Hard Urdu questions for Solar System", "/generate-questions". Asks for sub-category, question count, difficulty, and language (using the Supabase MCP server to list live choices when available, otherwise asking directly), checks existing live questions for that exact sub-category+difficulty+language via Supabase MCP so nothing generated duplicates content already in the database, then writes a review-ready markdown file and a NOT-yet-executed SQL insert script into a `questions/` folder next to the project directory. Never writes to the database itself — the user runs the SQL manually after reviewing it. Self-contained: does not need to re-read the Flutter project or any prior conversation to produce identical output every run.
compatibility: Works with or without the Supabase MCP server connected, but the duplicate-check against existing questions (Step 6) requires it — without it, the skill can only guarantee no duplicates *within* the newly generated batch, and must say so. Never uses write/DDL Supabase tools — read-only queries only (`execute_sql` for SELECTs). The only files this skill creates are the two output files described in Step 7, written outside the project directory (see Step 7) — if your environment restricts writes to the project tree, ask the user how to proceed rather than silently writing inside the project instead.
---

# Generate Questions

Author a batch of quiz questions for a specific sub-category + difficulty +
language, in exactly the shape Quizoo's `questions` table and the Flutter
`Question` model expect — as **draft output for human review**, never as a
direct database write.

## Hard rules (do not deviate)

1. **Never write to the database.** Do not call any Supabase write/DDL tool
   (`apply_migration`, `execute_sql` with INSERT/UPDATE/DELETE/DDL, etc.) as
   part of this skill. Read-only `SELECT` queries (to list sub-categories,
   languages, or existing prompts) are fine and encouraged. The user runs the
   generated SQL script themselves, on their own schedule, after reviewing it.
2. **Always produce exactly two output files**: a SQL insert script and a
   Markdown review document (Step 7). Never skip either one, never merge them
   into one file.
3. **Full schema/format/sample-question knowledge lives in
   `reference/schema-and-samples.md`** next to this file — read it once at
   the start of a run. Do not re-derive the schema by reading Flutter source
   files or querying `information_schema` — that reference file already
   captures everything needed, kept in sync with the live schema as of
   2026-09-12. Treat it as ground truth for format; treat live MCP queries as
   ground truth only for *which sub-categories/languages currently exist* and
   *what content already exists* (Step 6).
4. **No question may duplicate one already in the database.** When Supabase
   MCP is available, Step 6's existing-questions query against the exact
   chosen sub-category + difficulty + language is mandatory, not optional —
   run it before drafting a single question, and check every drafted
   question against that list (not just against the rest of the new batch)
   before finalizing. When MCP is unavailable, this guarantee can't be made
   against the live database — say so explicitly to the user rather than
   silently only deduping within the batch.

Read `reference/schema-and-samples.md` in full now, before continuing.

## Step 0 — try one combined live lookup

If a Supabase MCP tool is available (commonly named `mcp__supabase__execute_sql`
or similar — check your tool list), run one read-only query up front so Steps
1 and 4 below don't each need a separate round trip:

```sql
select
  c.language_code,
  c.slug as category_slug,
  coalesce(tc.name, c.slug) as category_name,
  s.id as subcategory_id,
  s.slug as subcategory_slug,
  coalesce(ts.name, s.slug) as subcategory_name,
  s.is_active,
  s.ai_generation_allowed
from subcategories s
join categories c on c.id = s.category_id
left join taxonomy_i18n tc on tc.entity_type = 'category' and tc.entity_id = c.id and tc.locale = c.language_code
left join taxonomy_i18n ts on ts.entity_type = 'subcategory' and ts.entity_id = s.id and ts.locale = c.language_code
where s.is_active = true
order by c.language_code, c.slug, s.slug;
```

```sql
select code, name, native_name, is_rtl, is_active from languages order by sort_order;
```

If the MCP tool isn't in your tool list, times out, or errors: don't retry
endlessly — fall through to the manual-input paths in Steps 1 and 4 below.
Note to the user (briefly) that the picker is unavailable and why.

## Step 1 — which sub-category?

**If Step 0's data is available:** present the active sub-categories grouped
by language and category (name, slug, language) and let the user pick one.
If a sub-category has `ai_generation_allowed = false`, exclude it from the
list (or show it but mark it unavailable) — this flag exists precisely to opt
a topic out of AI-authored content, and this skill must respect it.

**If not available:** ask the user for the sub-category's **UUID** (the
`subcategories.id` value — e.g. from the Supabase Table Editor, or a manual
`select id, slug, category_id from subcategories where slug ilike '%name%';`).
Recommend the UUID over the slug: slugs are only unique *within one
language's category* (`(category_id, slug)`), not globally — the same slug
(e.g. `solar-system`) can legitimately exist under both the English and Urdu
Science categories as two different rows. If the user only has a slug, also
ask which language it belongs to and treat that as the resolved language for
Step 4 rather than asking again.

Once resolved, you must know: the sub-category's `id`, `slug`, display name,
its category's `slug`/name, and — critically — its category's
`language_code`. Keep this language on hand for Step 4's cross-check.

## Step 2 — how many questions?

Ask for a count (e.g. 10, 50, 100, 200 — accept any positive integer). No
hard cap, but if it's large (100+), tell the user briefly that you'll track
facts/correct-answers used so far in the batch to keep everything unique
rather than silently promising perfect uniqueness — then actually do that
while generating (Step 6).

## Step 3 — which difficulty?

Ask the user to choose one of the 3 tiers: **Easy, Medium, Hard**. Map it via
`reference/schema-and-samples.md`'s `difficulty_tiers` table to get the tier
`code`, the legacy `difficulty` int, level range, seconds/question, and
questions/level — you'll need the `code` and int for generation and SQL, and
the level range/seconds/questions-per-level are useful to mention back to the
user for context. A "minimum useful batch" is 3× that tier's
questions-per-level (matching `v_thin_question_pools`' own thin-pool
threshold): 30 for Easy, 45 for Medium, 60 for Hard — suggest that as a
starting point if the user hasn't given a count yet.

## Step 4 — which language?

**If Step 0's language list is available:** show it (English name + native
name), defaulting the discussion toward whichever language the chosen
sub-category (Step 1) already belongs to, since that's the only value that
can actually be inserted for it.

**If not available:** ask for a language name, ISO code, or native name.

**Cross-check against Step 1 (mandatory):** the DB enforces via trigger that
every question's `language_code` must equal the language of its
`subcategory_id`'s own category — there is no way around this. If the
user's Step 4 answer doesn't match the sub-category resolved in Step 1:
- Tell them plainly: "That sub-category belongs to `<lang>`, not `<chosen
  lang>` — a question row can't mix the two."
- Ask them to either pick a different sub-category (in their desired
  language, if one exists) or accept the sub-category's actual language.
- Do not proceed until this is resolved — an unresolved mismatch means every
  row in the eventual SQL script would fail at insert time.

If the requested language has no active sub-categories at all yet (e.g. it's
in `languages` but `is_active = false`, or simply has zero categories),
this skill cannot proceed for it — creating new categories/subcategories/
languages is out of scope here. Tell the user and ask them to pick an
existing language or set up that language's taxonomy first.

## Step 5 — confirm before generating

Summarize back to the user in one short block before writing anything:

```
Sub-category: <name> (<slug>) — category <category name>, language <Language (code)>
Difficulty:   <Label> — tier `<code>`, levels <start>–<end>, <secs>s/question
Count:        <N> questions
Output:       <parent of project dir>/questions/<folder>/{questions.sql, review.md}
```

Ask for a go/no-go (or a correction) before moving on. This is the one
deliberate pause in an otherwise autonomous skill — getting one of these four
answers wrong wastes the entire generation effort, so confirm first.

## Step 6 — check for existing duplicates, then generate

**Mandatory when Supabase MCP is available** (see Hard rule 4): before
drafting anything, query every live/draft question already in the database
for this *exact* combination — same sub-category, same difficulty tier, same
language:

```sql
select id, prompt, options, correct_index
from questions
where subcategory_id = '<SUBCATEGORY_ID>'
  and difficulty_tier_id = (select id from difficulty_tiers where code = '<TIER_CODE>')
  and language_code = '<LANGUAGE_CODE>'
  and status <> 'suspended'
order by created_at;
```

Keep this full result set on hand while drafting. If it's empty, note that
(a fresh pool) and proceed. If MCP is unavailable, tell the user plainly that
you cannot check the live database for duplicates and are only guaranteeing
uniqueness within the new batch itself — do not imply a DB-level guarantee
you can't back up.

Then write exactly `<N>` questions following every rule in
`reference/schema-and-samples.md`'s "Content-quality rules" and calibrated
against that file's difficulty samples for the chosen tier. In particular:

- `kind = 'text'` always; 4 options; one correct answer; a genuine
  one-sentence explanation.
- Vary `correct_index` across the batch.
- **No question may match or closely paraphrase any prompt fetched above** —
  compare on the underlying fact being tested, not just exact string
  equality (e.g. "Which planet is the Red Planet?" and "Mars is nicknamed
  the Red Planet — true or false framed as which-planet?" test the same
  fact and both count as a duplicate). If a drafted question collides,
  discard and replace it with a different fact before finalizing the batch —
  don't just note the collision and move on.
- No duplicates within the batch itself, either.
- Written natively in the target language/script (RTL script and RTL option
  badges — ا ب ج د — for `ur`/`ar`).
- Difficulty actually matches the chosen tier's calibration, not just its
  label — an "Easy" question must be answerable from common knowledge; a
  "Hard" question should be genuinely obscure or technical, per the samples.

## Step 7 — write the two output files

**These files are written outside the project directory, as a sibling of
it** — not under `.claude/` or anywhere inside the repo. Determine the
project root and its parent at run time (never hardcode an absolute path
from this skill file):

```sh
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PARENT_DIR=$(dirname "$PROJECT_ROOT")
OUTPUT_ROOT="$PARENT_DIR/questions"
```

So if the project lives at `/Users/you/dev/quizoo`, output goes under
`/Users/you/dev/questions/` — a folder that sits *next to* the project
folder, shared across however many batches you generate over time. Create
`$OUTPUT_ROOT` if it doesn't exist yet, then inside it create one subfolder
per batch, named:

```
<subcategory-name>-<difficulty>-<language-code>-<YYYYMMDD-HHMMSS>
```

- `<subcategory-name>`: the sub-category's display name, lowercased and
  slugified (spaces/punctuation → single hyphens), e.g. `solar-system`.
- `<difficulty>`: the tier `code` (`easy`/`medium`/`hard`).
- `<language-code>`: the ISO code, e.g. `en`, `ur`.
- Timestamp: the actual current date/time from your environment, e.g. via a
  `date +%Y%m%d-%H%M%S` shell call — never a hardcoded date from this file.

Example: `questions/solar-system-hard-en-20260913-142530/`.

If your environment can't write outside the project directory (sandboxed
tool permissions, etc.), don't silently fall back to writing inside the
project — tell the user and ask how they'd like to proceed.

Inside the batch subfolder, write:

### `questions.sql`

A single self-contained, idempotent-safe transaction. Follow this exact
shape (fill in every `<PLACEHOLDER>`; keep the guard block — it makes the
script safe to run in any environment without depending on this skill or
this conversation having verified anything):

```sql
-- Generated by generate-questions.
-- Sub-category: <subcategory name> (<slug>), language <language name> (<code>)
-- Difficulty: <Label> (tier `<code>`, levels <start>-<end>)
-- Count: <N>
-- Review the paired review.md FIRST. Nothing is saved until you run this
-- script yourself in the Supabase SQL editor.

begin;

do $$
declare
  v_subcategory_id uuid := '<SUBCATEGORY_ID>';
  v_language_code  text := '<LANGUAGE_CODE>';
  v_category_lang  text;
  v_ai_allowed     boolean;
begin
  select c.language_code, s.ai_generation_allowed
    into v_category_lang, v_ai_allowed
  from subcategories s
  join categories c on c.id = s.category_id
  where s.id = v_subcategory_id;

  if v_category_lang is null then
    raise exception 'Subcategory % does not exist.', v_subcategory_id;
  end if;

  if v_category_lang <> v_language_code then
    raise exception 'Language mismatch: subcategory % belongs to language "%", but this script targets "%".',
      v_subcategory_id, v_category_lang, v_language_code;
  end if;

  if v_ai_allowed is false then
    raise exception 'Subcategory % has ai_generation_allowed = false; AI-authored questions are not permitted here.', v_subcategory_id;
  end if;
end $$;

insert into questions (
  id, subcategory_id, kind, difficulty, difficulty_tier_id,
  language_code, status, source, options, correct_index,
  explanation, prompt, tts_excluded
) values
  -- Q1: <first few words of the prompt>
  (gen_random_uuid(), '<SUBCATEGORY_ID>', 'text', <DIFFICULTY_INT>,
   (select id from difficulty_tiers where code = '<TIER_CODE>'),
   '<LANGUAGE_CODE>', 'live', 'ai_batch',
   '["<option A>","<option B>","<option C>","<option D>"]'::jsonb, <CORRECT_INDEX>,
   '<explanation>', '<prompt text>', false),
  -- Q2: <first few words of the prompt>
  (gen_random_uuid(), '<SUBCATEGORY_ID>', 'text', <DIFFICULTY_INT>,
   (select id from difficulty_tiers where code = '<TIER_CODE>'),
   '<LANGUAGE_CODE>', 'live', 'ai_batch',
   '["<option A>","<option B>","<option C>","<option D>"]'::jsonb, <CORRECT_INDEX>,
   '<explanation>', '<prompt text>', false)
  -- ... one tuple per question, comma-separated, no trailing comma after the LAST tuple
returning id, prompt;

commit;
```

Notes for whoever edits this file after reviewing `review.md`:
- To drop a question, delete its whole `(...)` tuple (and its `-- Qn` comment
  line) and fix the commas — the tuple immediately before the one you removed
  must lose its trailing comma if you removed the last tuple, and gain one if
  it didn't already have one.
- To edit a question, edit the literal values inside its tuple directly —
  the shape never changes.
- Escape any literal `'` inside prompt/option/explanation text by doubling it
  (SQL string escaping: `it's` → `it''s`).

### `review.md`

```markdown
# Generated Questions — <Subcategory name> (<Language name>, <Difficulty label>)

- Sub-category: <name> (`<slug>`, id `<uuid>`)
- Category: <category name>
- Language: <Language name> (`<code>`)
- Difficulty: <Label> — tier `<code>`, levels <start>–<end>, <secs>s/question
- Count: <N>
- Generated: <current date>
- Paired SQL file: `questions.sql` (same folder)

> Nothing has been written to the database. Review each question below. If
> you remove or edit one here, make the matching edit in `questions.sql`
> (each question is numbered and commented there). When you're satisfied,
> run `questions.sql` yourself in the Supabase SQL editor — that's the only
> step that saves anything.

---

### Q1

**Prompt:** <prompt text>

| Option | Text |
|---|---|
| A | <option A> |
| B | <option B> |
| C | <option C> |
| D | <option D> |

**Correct:** <letter> — <correct option text>

**Explanation:** <explanation>

---

<repeat per question, using the same numbering as the `-- Qn` comments in questions.sql>
```

For an RTL language (`ur`, `ar`), use option labels **ا ب ج د** instead of
**A B C D** in the table, matching what the app itself renders.

## Step 8 — final message to the user

State plainly, in your own words (don't just dump the template):
- Both file paths (the full `questions/<batch>/...` paths, sitting next to
  the project directory, not inside it).
- Whether the duplicate-check against the live database actually ran
  (MCP available) or was skipped (MCP unavailable, batch-internal uniqueness
  only) — don't let this go unstated.
- A one-line reminder: nothing was saved to the database.
- Next step: review `review.md`, edit both files together for anything you
  want to change, then run `questions.sql` in the Supabase SQL editor
  yourself when ready.
