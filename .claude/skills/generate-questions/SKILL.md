---
name: generate-questions
description: Interactively generates a batch of Quizoo multiple-choice quiz questions for one sub-category, difficulty tier, and language, in Quizoo's exact `questions` table format. Supports four content modes via a `-mode` parameter — no `-mode`/`-mode text` (text-only, the original behavior), `-mode image` (verified open-license image questions — PD/CC0/CC-BY/CC-BY-SA, images downloaded from approved sources, normalized to a fixed 16:9 frame and re-hosted in the `question-media` bucket, with a credit line embedded in the explanation when the license requires attribution), `-mode pattern` (original 16:9 SVG pattern/IQ questions stored in `figure_svg`, drawn with a fixed stroke set so no artwork comes out with fat/overlapping lines), and `-mode all` (a mix of text, image, and — where the sub-category genuinely supports them — pattern questions). Asks for sub-category, question count, difficulty, and language (using the Supabase MCP server to list live choices when available, otherwise asking directly), checks existing live questions for that exact sub-category+difficulty+language via Supabase MCP so nothing generated duplicates content already in the database and no question-stem template repeats across the batch, then writes a review-ready, consistently-styled HTML review file (`review.html`), a NOT-yet-executed SQL insert script, and (for pattern rows) one SVG asset per question into a `questions/` folder next to the project directory. Never writes to the database itself — the user runs the SQL manually after reviewing it.
compatibility: Text and pattern modes work with or without the Supabase MCP server connected, but the duplicate-check against existing questions (Step 6) requires it — without it, the skill can only guarantee no duplicates *within* the newly generated batch, and must say so. Image mode (`image`/`all`) additionally requires the MCP server (for the project URL and the mandatory duplicate check), internet access to the approved image sources, Pillow for the 16:9 crop/normalizer (`scripts/prepare_question_media.py`), and a readable Supabase `service_role` key file (see Configuration). Pattern mode uses the built-in macOS `qlmanage` to render each artwork for its mandatory visual check. Never uses write/DDL Supabase tools — read-only queries only (`execute_sql` for SELECTs). The only Supabase Storage writes this skill ever makes are image uploads to `question-media` through `scripts/upload_question_media.py`; the only files it creates are the two output files plus `assets/*.svg` for pattern rows, all outside the project directory (see Step 7).
---

# Generate Questions

Author a batch of quiz questions for a specific sub-category + difficulty +
language, in exactly the shape Quizoo's `questions` table and the Flutter
`Question` model expect — as **draft output for human review**, never as a
direct database write.

> To re-express questions that already exist in another language's pool (for
> example Arabic/French from English/Spanish/Hindi/Urdu) instead of authoring
> new ones, use the sibling `translate-questions` skill.

The skill has four content **modes**:

| Invocation | What it generates | Question kinds |
|---|---|---|
| no `-mode`, or `-mode text` | Text questions only (the original behavior) | `text` |
| `-mode image` | Verified image questions only, sourced from approved open-license (PD/CC0/CC-BY/CC-BY-SA) sources | `image` |
| `-mode pattern` | Original SVG pattern/IQ questions only | `figure` |
| `-mode all` | A mix of text, image, and (where supported) pattern | `text` + `image` + `figure` |

Mode selection is a hard gate: a mode never silently substitutes one kind for
another, and a mode that cannot run for the chosen sub-category stops (or, for
`all`, drops the ineligible kind and says so) — see Steps 1 and 6.

## Hard rules (do not deviate)

1. **Never write to the database.** Do not call any Supabase write/DDL tool
   (`apply_migration`, `execute_sql` with INSERT/UPDATE/DELETE/DDL, etc.) as
   part of this skill. Read-only `SELECT` queries are fine and encouraged.
   The one exception is **Supabase Storage**, not the database: in
   `image`/`all` modes, verified images are uploaded to the public
   `question-media` bucket — and only through
   `scripts/upload_question_media.py`, never by another means and never with
   the key value handled in the conversation. The user runs the generated SQL
   script themselves, after reviewing it.
2. **Always produce exactly two output files** — a SQL insert script
   (`questions.sql`) and an HTML review document (`review.html`, Step 7) —
   **plus, for `figure` rows, one `<batch>/assets/q<N>.svg` per pattern
   question**. Never skip either main file, never merge them into one, never
   omit a pattern asset. The review file is always generated from
   `reference/review-template.html`: copy its structure and `<style>` block
   verbatim and only fill in content — every batch's `review.html` must have
   the identical UI/UX, layout, design, typography, theme, and formatting,
   and the correct option is always rendered in green.
3. **Full schema/format/knowledge lives in the reference files next to this
   file.** Read `reference/schema-and-samples.md` in full at the start of
   every run. **Additionally read `reference/image-sources.md` in full before
   any run whose mode includes `image`** (it is the approved-source catalog,
   license gate, and verification protocol). Do not re-derive the schema by
   reading Flutter source files or querying `information_schema` — the
   reference file already captures everything needed. Treat it as ground
   truth for format; treat live MCP queries as ground truth only for *which
   sub-categories/languages currently exist* and *what content already
   exists* (Step 6).
4. **No question may duplicate one already in the database — in content or
   in wording.** When Supabase MCP is available, Step 6's
   existing-questions query against the exact
   chosen sub-category + difficulty + language is mandatory — run it before
   drafting a single question, and check every drafted question against that
   list (not just against the rest of the new batch) before finalizing. In
   `image` mode also never reuse an image already referenced by another
   question in the same sub-category (Step 6's media query). In `pattern`
   mode never reuse an underlying rule that already exists. When MCP is
   unavailable (text/pattern only — image mode stops), this guarantee can't
   be made against the live database: say so explicitly to the user rather
   than silently only deduping within the batch.

   The same applies to *how* questions are phrased, not just what they ask.
   A batch whose prompts keep reusing one sentence shape ("Which planet…?",
   "Which country's flag is this?", "What is the largest…?") feels
   machine-generated even when every underlying fact is new. Track each
   prompt's *template* — the sentence shape with its specifics blanked
   out — as you draft it, never reuse a template back-to-back, and rewrite
   any prompt whose wording or opening echoes an earlier one in the batch.
   When Step 6a's fetch included existing prompts, also steer away from
   the stems that pool leans on. Step 6e is the mandatory final check for
   this; it applies in every mode, even when MCP is unavailable.
5. **Mode integrity + capability assessments.** Only write the question
   kinds the mode allows. Before generating anything, assess whether the
   chosen sub-category genuinely supports the requested media kinds
   (Step 1). If it does not: `image`/`pattern` modes **stop without writing
   any files** and state the verdict + reasoning; `all` mode drops the
   ineligible kind(s), continues with what remains, and states the drop. A
   pattern question is only legitimate when a pattern/IQ puzzle genuinely
   tests *that sub-category* — when in doubt, treat it as unsupported.
6. **Image license policy + verification + re-hosting.** Images come only
   from the approved sources in `reference/image-sources.md` and must be
   **openly licensed: PD, CC0, CC-BY, or CC-BY-SA** (reject CC-BY-NC,
   CC-BY-ND, GFDL-only, "fair use", and anything all-rights-reserved or
   unverifiable). They must be **viewed with the Read tool** before use
   (metadata alone is not verification) and **re-hosted** in
   `question-media` — never hotlink a source-site URL into `media_url`.
   Every CC-BY/CC-BY-SA image carries a **mandatory credit line** appended
   as the final sentence of its `explanation`, in this exact shape:
   `Credit: <author>, <license short name>, <license URL>.`
   (PD/CC0 need no credit line, but every image's source/author/license is
   still recorded in `review.html`. A CC-BY/CC-BY-SA image whose author
   can't be determined is rejected — it cannot be attributed.)
7. **Pattern originality.** Every pattern artwork is an original design.
   Never reproduce Raven's Progressive Matrices, published IQ-test items, or
   another app's puzzles. SVGs are self-contained (no scripts, external
   images/fonts/network references) and exactly one option is correct.
8. **Never expose secrets.** The `service_role` key is only ever read from a
   file path by `scripts/upload_question_media.py`. Do not read the key file
   with the Read tool, print its contents, or paste it into a command.
9. **Fixed media geometry — identical size for every question.** Every image
   this skill uploads is exactly 16:9 (a canonical 1280×720 down to 640×360),
   produced **only** by `scripts/prepare_question_media.py` from the
   downloaded source — never an un-cropped, portrait or arbitrary-ratio
   original. Every pattern artwork is drawn on exactly the 640×360 canvas
   (`viewBox="0 0 640 360"`), uses only stroke widths **6** (figure
   outlines) and **3** (construction lines), keeps ≥ 20 units of clear
   space between any two strokes and ≥ 24 units from the canvas edge, passes
   `scripts/validate_figure_svg.py`, and is then rendered and visually
   inspected (Step 6d). This is what makes every question's media render at
   the same size on the play screen — and what stops the fat, overlapping
   strokes of earlier pattern batches.

## Configuration (required per mode; see each subsection)

### Supabase `service_role` key

A readable file containing the project's `service_role` key:

`/Users/waleed/Documents/QuizooKeys/supabase_service_role.txt`

Uploads to `question-media` must use this key (it bypasses Storage RLS; the
anon key cannot upload). The key's *contents* are never read by the agent —
only passed to `scripts/upload_question_media.py` as a path. Resolve and
verify the file is readable before generating; if it is missing/unreadable,
stop and quote this section. (Same key file the `generate-audios` skill
uses.)

### Project URL

Resolve via the Supabase MCP server (`get_project_url`). If MCP is
unavailable in `image`/`all` mode, stop — image mode cannot run without it
(Hard rule 5 / Step 0).

### Media preparation (every mode that produces media)

- `scripts/prepare_question_media.py` — the **only** way an image-mode file
  becomes an upload: EXIF-upright crop to 16:9, downscale to a canonical
  size, re-encode (JPEG quality 88, or PNG for flat art). Requires Pillow
  (`python3 -c "import PIL"` to check; if missing, stop and tell the user to
  `python3 -m pip install Pillow`). Full protocol in Step 6c.
- `scripts/validate_figure_svg.py` — the mechanical gate for every pattern
  SVG (exact canvas, stroke budget, option labels, no external refs, size
  cap). The render-and-look check in Step 6d is mandatory *on top of* a
  passing validation.

## Step 0 — parse `-mode`, then one combined live lookup

**Parse the mode first.** The user may pass `-mode <value>` anywhere in the
invocation (case-insensitive value). Valid values: `text`, `image`,
`pattern`, `all`. No `-mode` → `text`. `-mode text` is equivalent to
omitting it. Any other value → stop immediately, generate nothing, and tell
the user the valid values. Carry the mode through the whole run and echo it
back at Steps 1, 5, and 8.

Then, if a Supabase MCP tool is available (commonly named
`mcp__supabase__execute_sql` or similar — check your tool list), run one
read-only query up front so Steps 1 and 4 below don't each need a separate
round trip:

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

If the MCP tool isn't in your tool list, times out, or errors:
- **`image`/`all` modes: stop here.** Say plainly: "Image mode needs the
  Supabase MCP server (project URL + the mandatory duplicate check) and
  can't run without it." Do not proceed.
- `text`/`pattern` modes: don't retry endlessly — fall through to the
  manual-input paths in Steps 1 and 4. Note to the user (briefly) that the
  picker is unavailable and why, and that the duplicate-check will be
  batch-internal only (Hard rule 4).

## Step 1 — which sub-category? (then assess its media capabilities)

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

### 1a. Image-capability assessment (only when mode includes `image`)

Decide — from the sub-category's name, category, and subject matter —
whether it can be tested with **openly licensed (PD/CC0/CC-BY/CC-BY-SA)
photographs whose subject has an unambiguous, metadata-confirmable
identity**. The gate is *license availability*, not subject matter: a topic
passes if the approved sources hold a suitable open-license photo of it,
whatever the topic. Positive signals: flags, countries/geography,
landmarks/architecture, art/paintings/artifacts, space/celestial bodies,
animals/plants/nature, historical archival subjects, and **public figures —
athletes, celebrities, historical personalities — with openly licensed
portraits on the approved sources** (Commons in particular holds CC-BY/
CC-BY-SA photographs of many athletes and famous people; check that pool
before declaring a topic infeasible). Negative signals: religion/doctrine,
language vocabulary/grammar, abstract math/logic (pattern mode fits better),
current events, private (non-public) individuals, and any topic where a
genuine search finds no suitable open-license photo — agency/press photos,
paparazzi shots, and stock previews never count, however many exist.

- `-mode image` and the sub-category is not feasible → **stop without
  writing any files**, state the verdict and reasoning, and suggest
  `-mode text` (or `-mode pattern` if 1b would pass).
- `-mode all` and not feasible → drop `image` from the plan, continue with
  the remaining capable kinds, and state the drop.
- Genuinely ambiguous → treat as not feasible (safer default) and say why.

### 1b. Pattern-capability assessment (only when mode includes `pattern`)

**Do your own research here; there is no DB flag and no allowlist.** Decide
whether pattern-recognition / IQ-style figure questions genuinely test *this
sub-category* — not merely whether they could be themed around its name.
Use the sub-category's display name, slug, category, and (when available) a
small read-only sample of its existing prompts, e.g.:

```sql
select prompt from questions
where subcategory_id = '<SUBCATEGORY_ID>' and language_code = '<LANGUAGE_CODE>'
order by created_at desc limit 20;
```

If the name is unclear, a quick web search for what the sub-category means is
allowed. Criteria:

- **Strong yes:** IQ/logic/reasoning categories, pattern/matrix/sequence/
  spatial/memory puzzles, number/math reasoning, coding/algorithmic thinking,
  visual odd-one-out — places where a figure puzzle is a legitimate question
  about the topic.
- **No:** factual/trivia domains — sports, geography facts, history,
  religion, language, science facts, pop culture. A shape sequence is not a
  question about Football.
- **Ambiguous → treat as not supported** and say why (safer default: it
  avoids dumping off-topic content into a live pool).

- `-mode pattern` and not supported → **stop immediately, generate nothing,
  write no files.** Tell the user plainly: the sub-category does not
  support pattern questions (verdict + one-line reasoning), and suggest
  `-mode text` / `-mode image` instead.
- `-mode all` and not supported → drop `pattern`, continue with text (and
  image if 1a passed), and state the drop.

Record both verdicts (supported/not + one-line rationale) — they go in the
Step 5 confirmation and the Step 8 summary.

## Step 2 — how many questions?

Ask for a count (e.g. 10, 50, 100, 200 — accept any positive integer). No
hard cap, but if it's large (100+), tell the user briefly that you'll track
facts/correct-answers *and question-stem templates* used so far in the batch
to keep everything unique in both content and wording (Hard rule 4) rather
than silently promising perfect uniqueness — then actually do that while
generating (Steps 6b–6e).

For `-mode all`, the split across kinds is resolved in Step 5 (default:
as even as possible across the capable kinds).

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

Resolve the kind split first, then summarize back to the user in one short
block before writing anything:

- **`text` mode:** N text questions (existing behavior).
- **`image` mode:** N image questions.
- **`pattern` mode:** N figure/pattern questions.
- **`all` mode:** split N as evenly as possible across the capable kinds
  (1a/1b verdicts), remainder order text → image → pattern. State the split
  explicitly; the user may correct it here. If only one kind is capable,
  `all` degenerates to that kind — say so.

```
Sub-category: <name> (<slug>) — category <category name>, language <Language (code)>
Difficulty:   <Label> — tier `<code>`, levels <start>–<end>, <secs>s/question
Count:        <N> questions
Mode:         <text|image|pattern|all> — <n1> text, <n2> image, <n3> pattern
Status:       text rows live; image/figure rows draft (only `live` rows get
              dealt; flip after review) — say "all live" to override
Output:       <parent of project dir>/questions/<folder>/{questions.sql, review.html[, assets/]}
```

Also state for `image`/`all`: images will come from approved open-license
sources (Wikimedia Commons, FlagCDN, NASA, Met, Art Institute of Chicago,
Cleveland), be normalized to a fixed 16:9 frame (1280×720 down to 640×360,
cropped so nothing a question depends on is lost), visually verified, and be
uploaded to `question-media` before the SQL is written. Licenses may be PD/CC0 or CC-BY/CC-BY-SA; the latter
carry a mandatory credit line as the explanation's final sentence
(`Credit: <author>, <license short name>, <license URL>.`).

Ask for a go/no-go (or a correction) before moving on. This is the one
deliberate pause in an otherwise autonomous skill — getting one of these
answers wrong wastes the entire generation effort, so confirm first.

## Step 6 — check for existing duplicates, then generate with varied wording

### 6a. Existing-content queries (mandatory when MCP is available)

Before drafting anything, query every live/draft question already in the
database for this *exact* combination — same sub-category, same difficulty
tier, same language:

```sql
select id, prompt, options, correct_index, kind, media_url
from questions
where subcategory_id = '<SUBCATEGORY_ID>'
  and difficulty_tier_id = (select id from difficulty_tiers where code = '<TIER_CODE>')
  and language_code = '<LANGUAGE_CODE>'
  and status <> 'suspended'
order by created_at;
```

For `image`/`all` modes, additionally fetch every existing image in the
sub-category so no image is reused across difficulties:

```sql
select id, media_url
from questions
where subcategory_id = '<SUBCATEGORY_ID>'
  and language_code = '<LANGUAGE_CODE>'
  and media_url is not null;
```

For `pattern`/`all` modes, sample existing figure prompts so rules aren't
repeated:

```sql
select prompt, explanation
from questions
where subcategory_id = '<SUBCATEGORY_ID>'
  and language_code = '<LANGUAGE_CODE>'
  and kind = 'figure';
```

Keep these result sets on hand while drafting, and skim the fetched
`prompt`s for the phrasing templates the pool already leans on (e.g. most
opening with "Which…") — new questions shouldn't clone the existing style
any more than its facts. If the first query is empty, note that (a fresh
pool) and proceed. If MCP is unavailable (text/pattern
only), tell the user plainly that you cannot check the live database for
duplicates and are only guaranteeing uniqueness within the new batch itself
— do not imply a DB-level guarantee you can't back up.

### 6b. Text questions (mode `text`, or the text share of `all`)

Write each question following every rule in
`reference/schema-and-samples.md`'s "Content-quality rules" and calibrated
against that file's difficulty samples for the chosen tier. In particular:

- `kind = 'text'`; 4 options; one correct answer; a genuine one-sentence
  explanation.
- Vary `correct_index` across the batch.
- **No question may match or closely paraphrase any prompt fetched above** —
  compare on the underlying fact being tested, not just exact string
  equality. If a drafted question collides, discard and replace it with a
  different fact before finalizing — don't just note the collision and move
  on.
- No duplicates within the batch itself, either.
- **No repeated phrasing.** Keep a running inventory of each drafted
  prompt's sentence shape with its specifics blanked out (e.g. "Which
  [thing] has the most [property]?" and "What is the [superlative]
  [thing]?" are different templates even when both are about planets). No
  template may be reused back-to-back, and across the batch vary openings
  and interrogatives (which/what/who/where/when/how, imperative forms like
  "Name the…", question vs. statement structures) so no single shape
  dominates. When the sub-category's natural phrasing space is genuinely
  narrow, rotate through the available shapes rather than settling on one.
  Vary `explanation` openings too — don't let them all start alike.
- Written natively in the target language/script (RTL script and RTL option
  badges — ا ب ج د — for `ur`/`ar`).
- Difficulty actually matches the chosen tier's calibration, not just its
  label — an "Easy" question must be answerable from common knowledge; a
  "Hard" question should be genuinely obscure or technical, per the samples.

### 6c. Image questions (mode `image`, or the image share of `all`)

Follow `reference/image-sources.md` in full. Per question, repeat:

1. **Pick a subject** that *tests* the sub-category (a flag question for
   Flags, a landmark question for Landmarks, a celestial body for Space…).
   Not merely an illustration.
2. **Find 1–3 candidates** on the approved sources, capturing each one's
   source page URL, title/description (identity!), author, and license.
   Prefer landscape/centered-subject files — every image is cropped to a
   16:9 band next, and the crop has to keep the answer-critical content.
3. **License-gate**: PD/CC0/CC-BY/CC-BY-SA only (any license version). No
   recognizable license, or an NC/ND/GFDL-only/"fair use"/all-rights-
   reserved one → reject the candidate. No exceptions. Capture author,
   license short name, license URL, and source page URL — CC-BY/CC-BY-SA
   needs all of them for the credit line.
4. **Download a large rendition** (JPEG/PNG only) to the scratchpad —
   1280–2048px wide when the source offers it, since the 16:9 crop trims
   height (per-source sizes in `reference/image-sources.md` §2) — with a
   descriptive User-Agent for Wikimedia. Verify with `file <path>` that it
   really is a JPEG/PNG (not an HTML error page).
5. **Normalize to 16:9** (Hard rule 9). First inspect:
   `python3 .claude/skills/generate-questions/scripts/prepare_question_media.py
   --input <scratch>/<subject>.jpg` (prints the suggested centered band),
   then write the normalized file:
   `... prepare_question_media.py --input <scratch>/<subject>.jpg
   --output <scratch>/<subject>-16x9.jpg --crop <x>,<y>,<w>`.
   Shift/shrink the band until the answer-critical content is fully inside —
   a flag's whole charge, the landmark, the animal, the person's face. The
   script derives the height (w×9/16), enforces the ≥640px width floor, and
   outputs an exact canonical size. Never upload the raw download; never
   upscale; on a too-small source, pick a larger rendition or swap subjects.
6. **View the normalized file with the Read tool.** Mandatory — metadata
   alone is never sufficient. Check the identity against the metadata,
   exactly one unambiguous answer, no watermarks/overlaid answer text, no
   lookalikes — and that the 16:9 crop kept everything the question needs.
7. **Accept or reject-and-swap.** On any doubt (including a crop that cuts
   context), discard and go back to step 1 or 2 — never force a weak image
   to hit the count.
8. **Write the question**: short prompt that doesn't give away the answer
   and doesn't echo the wording of other prompts in the batch (for a run
   of flags, "Which country's flag is this?", "This flag belongs to which
   country?" and "Which nation flies this flag?" are all fine — using one
   of them for every question is not); exactly **4 options** (one correct,
   three plausible); `correct_index` 0–3; a genuine one-sentence explanation.
   For CC-BY/CC-BY-SA images, append
   the **mandatory credit line** as the explanation's final sentence —
   `Credit: <author>, <license short name>, <license URL>.` (one space
   after the preceding sentence's period; use the author exactly as
   recorded in the source metadata). PD/CC0 need no credit line. Write all
   question text natively in the target language/script; the `Credit:`
   keyword and license URL stay as-is.
9. **Pre-generate the question UUID** (`python3 -c "import uuid; print(uuid.uuid4())"`)
   and keep it — it becomes both the row id and the storage object path
   `<language_code>/<uuid>.<ext>`.
10. **Add to the upload manifest** — `file_path` is the **normalized** file
    from step 5 and `content_type` matches its format
    (`image/jpeg`/`image/png`) — and record the verification data (source
    page, author, license, scratchpad filename) for `review.html`.

Avoid entirely: source hotlinks, logos/trademarks/currency, graphic content,
images containing the answer as text, multi-answer photos, private
(non-public) individuals and privacy-sensitive candid shots, and anything
whose license you can't prove. Openly licensed portraits of public figures
are allowed — that's the point of the expanded gate.

### 6d. Pattern questions (mode `pattern`, or the pattern share of `all`)

Per question:

1. **Design an original puzzle** fitting the sub-category and tier — sequence
   completion, matrix completion, rotation/reflection, odd-one-out, counting,
   analogies, spatial reasoning. Never copy a known copyrighted puzzle (see
   Hard rule 7).
2. **Compose the SVG** per `reference/schema-and-samples.md`'s "Pattern
   (`figure`) authoring spec" — the geometry rules there are hard
   requirements: exactly `viewBox="0 0 640 360"` + `width="640" height="360"`;
   only stroke widths **6** (figure outlines) and **3** (construction lines)
   anywhere in the file; ≥ 20 units of clear space between any two strokes
   (strokes must never touch or cross) and ≥ 24 units from every canvas
   edge; identical stroke sizes across all four options; shapes + text only,
   no scripts/external refs/fonts; the full puzzle plus four labelled option
   figures (A–D, or ا–د for RTL) inside the one artwork; exactly one correct
   option; under ~10KB (hard cap 12KB), double quotes preferred.
3. **Save it** to `<batch>/assets/q<N>.svg` where `<N>` matches the
   question's number in `review.html` and the `-- Q<N>` comment in
   `questions.sql`.
4. **Validate it** with
   `python3 .claude/skills/generate-questions/scripts/validate_figure_svg.py <file>.svg`
   — it must print `OK` (canvas, stroke budget, labels, refs, size). Fix
   every `FAIL` and re-run until clean.
5. **Render it and look at it** (mandatory — the validator can't see overlap
   or clipping):
   `mkdir -p <scratch>/svg-preview && qlmanage -t -s 1280 -o <scratch>/svg-preview <file>.svg`,
   then Read the produced `<file>.svg.png`. Confirm: uniform stroke weights,
   no touching/overlapping lines, every option inside its own panel, labels
   legible, nothing clipped or cramped at the edges, exactly one correct
   option. Fix and re-render on any doubt. If `qlmanage` is unavailable
   (non-macOS), say so plainly in the final message and fall back to the
   validator plus a careful coordinate review.
6. **Write the question**: `kind = 'figure'`; prompt in the target language
   — short, and rotated across standard variants ("Which figure completes
   the pattern?", "Which figure continues the sequence?", "Which shape
   comes next?") rather than the identical stem on every pattern question;
   options are exactly the four labels `["A","B","C","D"]` (or
   `["ا","ب","ج","د"]` for RTL);
   `correct_index` 0–3 pointing at the correct label; `tts_excluded = true`;
   a one-sentence explanation that states the rule; `figure_svg` gets the
   same SVG markup (SQL-escaped).
7. **No rule reuse** — neither within the batch nor against the existing
   figure prompts fetched in 6a.

### 6e. Wording-variety audit (all modes — mandatory before Step 7)

Before any file is written, run one dedicated pass over every drafted
prompt in the batch (all kinds) — unique facts are not enough:

1. Write out each prompt with its specifics blanked out to expose its
   template, and group the prompts by template. Also list each prompt's
   first two words.
2. Fix, don't just note:
   - two consecutive (or near-adjacent) questions sharing a template →
     rewrite one in a different shape;
   - in a batch of 10+, any template used more than twice (for batches
     over ~30, more than ~10% of questions) → rewrite the excess in fresh
     shapes (pattern prompts, whose phrasing space is deliberately
     narrow, may reuse a variant up to 2–3 times but never
     consecutively);
   - more than a couple of prompts opening with the same first word →
     vary the openings;
   - a prompt whose wording merely swaps a noun into a shape borrowed
     from an existing DB prompt (Step 6a) → rewrite it.
3. Skim the explanations' first words too; if most start with the same
   phrase, vary a few.

Unique facts with templated wording is still a Hard rule 4 violation —
this audit is what makes "unique" true in practice, so it runs in every
mode, even when MCP (and therefore the DB duplicate check) is unavailable.

### 6f. Upload images (mode `image`/`all` only)

Once all image questions are drafted and every image accepted, write one
upload manifest JSON to the scratchpad:

```json
{
  "project_url": "<from mcp__supabase__get_project_url>",
  "bucket": "question-media",
  "service_role_key_path": "/Users/waleed/Documents/QuizooKeys/supabase_service_role.txt",
  "items": [
    {
      "question_id": "<pre-generated uuid>",
      "language_code": "<lang>",
      "file_path": "<scratchpad>/<subject>.jpg",
      "content_type": "image/jpeg"
    }
  ]
}
```

Then run:

```sh
python3 .claude/skills/generate-questions/scripts/upload_question_media.py \
  --input <manifest.json> --output <result.json>
```

Read the result JSON (safe — ids/URLs/errors only). Fill each image row's
`media_url` from its `public_url`. If an upload failed: retry once; if it
still fails, drop that question from the batch (adjust the count and the
split honestly) or replace the image, and report the failure in Step 8.
Never hand-construct a storage URL for a file that didn't upload.

## Step 7 — write the output files

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
this conversation having verified anything). The column list is the same for
every mode; the per-kind tuple shapes differ as shown:

```sql
-- Generated by generate-questions.
-- Sub-category: <subcategory name> (<slug>), language <language name> (<code>)
-- Difficulty: <Label> (tier `<code>`, levels <start>-<end>)
-- Mode: <text|image|pattern|all> — <N> questions (<n1> text, <n2> image, <n3> pattern)
-- Review the paired review.html FIRST. Nothing is saved until you run this
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
  explanation, prompt, media_url, figure_svg, tts_excluded
) values
  -- Q1 (text): <first few words of the prompt>
  (gen_random_uuid(), '<SUBCATEGORY_ID>', 'text', <DIFFICULTY_INT>,
   (select id from difficulty_tiers where code = '<TIER_CODE>'),
   '<LANGUAGE_CODE>', '<live|draft>', 'ai_batch',
   '["<option A>","<option B>","<option C>","<option D>"]'::jsonb, <CORRECT_INDEX_0_3>,
   '<explanation>', '<prompt text>', null, null, false),
  -- Q2 (image, id must match the storage object path): <first few words of the prompt>
   ('<QUESTION_UUID>', '<SUBCATEGORY_ID>', 'image', <DIFFICULTY_INT>,
    (select id from difficulty_tiers where code = '<TIER_CODE>'),
    '<LANGUAGE_CODE>', '<live|draft>', 'ai_batch',
    '["<option A>","<option B>","<option C>","<option D>"]'::jsonb, <CORRECT_INDEX_0_3>,
    '<explanation>', '<prompt text>', '<MEDIA_URL>', null, <tts_excluded>),
  -- Q3 (figure/pattern): <first few words of the prompt>
  (gen_random_uuid(), '<SUBCATEGORY_ID>', 'figure', <DIFFICULTY_INT>,
   (select id from difficulty_tiers where code = '<TIER_CODE>'),
   '<LANGUAGE_CODE>', '<live|draft>', 'ai_batch',
   '["A","B","C","D"]'::jsonb, <CORRECT_INDEX_0_3>,
   '<explanation>', '<prompt text>', null, '<SVG MARKUP>', true)
  -- ... one tuple per question, comma-separated, no trailing comma after the LAST tuple
returning id, prompt;

commit;
```

Notes for whoever edits this file after reviewing `review.html`:
- **Every kind takes exactly 4 options**: `text`, `image` and `figure` rows
  all carry four options, and `correct_index` (0–3) must point at an
  existing one. (Some legacy `image` rows from before 2026-10-10 still carry
  3 options and remain valid in the DB — never emit new 3-option rows.)
- **Image rows keep their pre-generated `id`** — it matches the storage
  object path; don't regenerate it. `text`/`figure` rows use
  `gen_random_uuid()`.
- To drop a question, delete its whole `(...)` tuple (and its `-- Qn` comment
  line) and fix the commas. Dropping an image question leaves its uploaded
  object orphaned in `question-media` — harmless; optionally delete it in the
  Supabase Storage dashboard.
- To edit a question, edit the literal values inside its tuple directly —
  the shape never changes.
- Escape any literal `'` inside prompt/option/explanation/SVG text by
  doubling it (SQL string escaping: `it's` → `it''s`).
- The default statuses are `live` for text rows and `draft` for
  image/figure rows — only `live` rows are dealt in play mode, and review is
  the gate, so flip the drafts to `live` here once they're approved (or say
  "all live" during generation to start them live).

### `review.html`

Read `reference/review-template.html`, then copy it **verbatim** into the
batch folder as `review.html` and fill it in. The template is the single
source of truth for the review file's UI/UX, layout, design, typography,
theme, and formatting: **never edit its `<style>` block, colors, fonts,
spacing, or structure, and never add or remove sections** — only replace the
placeholders below and expand `{{QUESTIONS}}`. Every batch's review file must
render identically.

Replace every placeholder in the template:

| Placeholder | Value |
|---|---|
| `{{LANG_CODE}}` | ISO code for the `<html lang>` attribute, e.g. `en`, `ur` |
| `{{LANGUAGE_CODE}}` | the same ISO code as displayed text, e.g. `en`, `ur` |
| `{{DIR}}` | `ltr`, or `rtl` for `ur`/`ar` |
| `{{PAGE_TITLE}}` | `<Subcategory name> — <Language name> (<Difficulty label>) · Quizoo Review` |
| `{{SUBCATEGORY_NAME}}` | sub-category display name |
| `{{SUBCATEGORY_SLUG}}` | sub-category slug |
| `{{SUBCATEGORY_ID}}` | sub-category UUID |
| `{{CATEGORY_NAME}}` | category display name |
| `{{LANGUAGE_NAME}}` | language display name |
| `{{DIFFICULTY_LABEL}}` | `Easy` / `Medium` / `Hard` |
| `{{TIER_CODE}}` | `easy` / `medium` / `hard` |
| `{{LEVELS}}` | tier level range, e.g. `1–10` |
| `{{SECS}}` | seconds per question for the tier, e.g. `20` |
| `{{MODE}}` | `text` / `image` / `pattern` / `all` |
| `{{SPLIT}}` | actual kind split, e.g. `4 text, 3 image, 3 pattern` |
| `{{COUNT}}` | total questions generated |
| `{{GENERATED}}` | current date |
| `{{QUESTIONS}}` | one question card per question, numbered in order |

Then replace `{{QUESTIONS}}` with one `<article class="card">` per question,
numbered to match the `-- Q<N>` comments in `questions.sql`. Use the exact
skeleton for the question's kind — the correct option carries
`class="option correct"` plus a trailing `<span class="mark">✓</span>`, and
that is the only styling difference between options:

**Text (`kind = 'text'`)** — four options, status chip `live`:

```html
<article class="card" id="q<N>">
  <div class="card-head">
    <span class="qno">Q<N></span>
    <span class="chip chip-text">text</span>
    <span class="chip chip-live">live</span>
  </div>
  <p class="prompt"><PROMPT></p>
  <ol class="options">
    <li class="option"><span class="key">A</span><span class="opt-text"><OPTION_A></span></li>
    <li class="option correct"><span class="key">B</span><span class="opt-text"><OPTION_B></span><span class="mark">✓</span></li>
    <li class="option"><span class="key">C</span><span class="opt-text"><OPTION_C></span></li>
    <li class="option"><span class="key">D</span><span class="opt-text"><OPTION_D></span></li>
  </ol>
  <p class="answer">Correct: <strong><LETTER></strong> — <CORRECT_OPTION_TEXT></p>
  <p class="explanation"><span class="label">Explanation</span><EXPLANATION></p>
</article>
```

(The `correct` class is shown on B for illustration only — put it on
whichever option is actually correct. `id="q<N>"` and `Q<N>` use the
question's number.)

**Image (`kind = 'image'`)** — four options, media plate, source line,
status chip `draft` (or `live` if the user opted into "all live"):

```html
<article class="card" id="q<N>">
  <div class="card-head">
    <span class="qno">Q<N></span>
    <span class="chip chip-image">image</span>
    <span class="chip chip-draft">draft</span>
  </div>
  <p class="prompt"><PROMPT></p>
  <figure class="media"><img src="<MEDIA_URL>" alt="Q<N> image"></figure>
  <ol class="options">
    <li class="option"><span class="key">A</span><span class="opt-text"><OPTION_A></span></li>
    <li class="option correct"><span class="key">B</span><span class="opt-text"><OPTION_B></span><span class="mark">✓</span></li>
    <li class="option"><span class="key">C</span><span class="opt-text"><OPTION_C></span></li>
    <li class="option"><span class="key">D</span><span class="opt-text"><OPTION_D></span></li>
  </ol>
  <p class="answer">Correct: <strong><LETTER></strong> — <CORRECT_OPTION_TEXT></p>
  <p class="explanation"><span class="label">Explanation</span><EXPLANATION></p>
  <p class="source">Source: <a href="<SOURCE_PAGE_URL>" rel="noopener"><SOURCE_TITLE></a> — <AUTHOR>, <LICENSE_SHORT_NAME>. Stored at <code>question-media/<LANG_CODE>/<UUID>.<ext></code>.</p>
</article>
```

For a CC-BY/CC-BY-SA image, link `<LICENSE_SHORT_NAME>` to its license URL
(see `reference/image-sources.md` §5 for the exact source-line shape), and
remember its credit line is already part of `<EXPLANATION>`.

**Pattern (`kind = 'figure'`)** — four label options, artwork from
`assets/`, status chip `draft` (or `live` on override):

```html
<article class="card" id="q<N>">
  <div class="card-head">
    <span class="qno">Q<N></span>
    <span class="chip chip-figure">pattern</span>
    <span class="chip chip-draft">draft</span>
  </div>
  <p class="prompt"><PROMPT></p>
  <figure class="media media-figure"><img src="assets/q<N>.svg" alt="Q<N> pattern"></figure>
  <ol class="options">
    <li class="option"><span class="key">A</span><span class="opt-text">A</span></li>
    <li class="option correct"><span class="key">B</span><span class="opt-text">B</span><span class="mark">✓</span></li>
    <li class="option"><span class="key">C</span><span class="opt-text">C</span></li>
    <li class="option"><span class="key">D</span><span class="opt-text">D</span></li>
  </ol>
  <p class="answer">Correct: <strong><LETTER></strong></p>
  <p class="explanation"><span class="label">Explanation</span><EXPLANATION></p>
</article>
```

**Content escaping and final checks:**

- HTML-escape everything inserted into text positions: `&` → `&amp;`,
  `<` → `&lt;`, `>` → `&gt;`. Keep `src`/`href`/`alt` values in double quotes.
  Never paste a raw `<` or `&` from a prompt/option/explanation into the file.
- For an RTL language (`ur`, `ar`), set `{{DIR}}` to `rtl` — the layout flips
  automatically (the accent bars, key badges, and ✓ mark move with it) — and
  use the labels **ا ب ج د** instead of **A B C D** for every option
  key/`opt-text` and in the pattern SVG labels, matching what the app itself
  renders.
- Before declaring the batch done: `grep -c '{{' review.html` must print `0`
  (its non-zero exit status in that case is expected and fine); the number of
  `class="option correct"` occurrences must equal the question count; every
  `assets/q<N>.svg` referenced by a pattern card must exist; and every
  `<article>` must be closed with `</article>`.
- The image `src` is the uploaded `media_url` (loads when online); the
  pattern `src` is the relative `assets/q<N>.svg` — keep that relative path
  so the batch folder stays portable.

### `assets/` (pattern rows only)

Write each pattern question's SVG to `assets/q<N>.svg` (N = question number)
as described in Step 6d, before finalizing `questions.sql` — the SQL embeds
the same markup inline. Every file must pass
`scripts/validate_figure_svg.py` and the visual render check (Step 6d.5)
before the batch is declared done.

## Step 8 — final message to the user

State plainly, in your own words (don't just dump the template):
- Both file paths (the full `questions/<batch>/...` paths, sitting next to
  the project directory, not inside it), plus the `assets/` folder when
  pattern rows exist.
- The mode and the actual kind split generated.
- That the wording-variety audit (Step 6e) ran and roughly how many
  prompts it rewrote to avoid repeated stems/templates.
- The capability verdicts from Step 1 (image/pattern supported or not, and
  the reasoning) when they were relevant.
- Whether the duplicate-check against the live database actually ran
  (MCP available) or was skipped (MCP unavailable, batch-internal uniqueness
  only) — don't let this go unstated.
- For image runs: how many images were uploaded, from which sources, and any
  upload failures or dropped/replaced questions. State the license mix
  (PD/CC0 vs CC-BY/CC-BY-SA) and confirm every attribution-required image
  carries its credit line. Confirm every uploaded file was normalized to an
  exact 16:9 frame by `prepare_question_media.py`, and say how many
  candidates were rejected because no 16:9 crop kept the answer-critical
  content.
- For pattern runs: confirm every artwork passed `validate_figure_svg.py`
  and was rendered and visually checked (uniform strokes, no overlap, labels
  legible) — or, if `qlmanage` was unavailable, say plainly that the visual
  check could not run.
- The status choice (text live; image/figure draft by default — only `live`
  rows get dealt, so say "all live" if these should start live).
- A one-line reminder: nothing was saved to the database.
- Next step: open `review.html` in a browser (open the `assets/*.svg` files
  directly for pattern batches if you want a closer look), edit both files
  together for anything you want to change, then run `questions.sql` in the
  Supabase SQL editor yourself when ready.
