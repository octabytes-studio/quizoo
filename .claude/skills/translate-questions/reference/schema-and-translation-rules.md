# Quizoo translation schema & rules reference

Static reference for the `translate-questions` skill. It captures the exact
column contract, tier mapping, kind rules, translation-quality rules, and the
read-only SQL the skill runs. The full `questions` schema and content
calibration live in
`../generate-questions/reference/schema-and-samples.md` — read that file too;
this file only adds what is specific to translating an existing row.

## The `questions` column contract (quoting the sibling reference)

Every translated row is a normal `questions` row. The schema, the four-option
rule, `correct_index`, `tts_excluded`, `status`, storage conventions, and
content-quality rules are all defined in
`../generate-questions/reference/schema-and-samples.md` and are **not**
re-derived here. Read it first.

Two things differ for translated rows:

| Column | Rule for translated rows |
|---|---|
| `source` | Always `'translated'` (the migration `20261013223938_question_translation_provenance.sql` widened `questions_source_check` to allow it). |
| `translated_from` | The source question's `id` (uuid). Nullable FK → `questions.id`, `on delete set null`. A partial unique index `uq_questions_translation_target` on `(translated_from, language_code)` allows one source row to be translated **at most once per target language** (so the same source may feed both `ar` and `fr`). |
| `audio_url` | **Never present in the INSERT column list** — it stays NULL so `generate-audios` can backfill it later. |

Everything else (row `id`, `subcategory_id`, `kind`, `difficulty`,
`difficulty_tier_id`, `language_code`, `status`, `options`, `correct_index`,
`explanation`, `prompt`, `media_url`, `figure_svg`, `tts_excluded`) follows
the sibling reference. `id` is always `gen_random_uuid()` for translated rows
(there is no pre-generated storage path to match — images reuse the source's
existing `media_url`).

## Tier mapping (the live 3-tier ladder)

| `code` | `label` | levels | questions/level | legacy `difficulty` int | minimum useful batch (×3) |
|---|---|---|---|---|---|
| `easy` | Easy | 1–10 | 10 | 1 | 30 |
| `medium` | Medium | 11–20 | 15 | 2 | 45 |
| `hard` | Hard | 21–30 | 20 | 3 | 60 |

`difficulty` (int) must agree with `difficulty_tier_id` (resolved by the
`code` subquery). Never hardcode tier UUIDs.

## Translation-quality rules (hard)

1. **Native phrasing, not word-for-word.** The target prompt and every option
   must read as if written by a native speaker of the target language — not a
   literal gloss of the source. Keep the meaning, the tested fact, and the
   difficulty; rewrite the sentence.
2. **Facts and numbers are exact.** Proper nouns are rendered the target
   language's standard way (Arabic: `باريس`, `فيينا`; French: `Paris`,
   `Vienne`). Units, dates, and figures never change.
3. **Option order is preserved.** Option *i* of the translation corresponds to
   option *i* of the source, so `correct_index` is carried over unchanged.
   Never reorder to "shuffle" — that would silently break the index.
4. **Exactly four options.** Every translated row carries 4, `image` included.
   Where a legacy source image row has only 3, author one extra plausible,
   wrong, distinct distractor and append it at the **end** (index 3);
   `correct_index` stays unchanged. Flag the authored option in `review.html`.
5. **No leftover source-language text.** The only exceptions are proper nouns
   (which may keep their common target-script form) and `Credit: …` lines in
   image explanations, which stay byte-identical.
6. **No duplicate facts** against the existing target pool for the same
   sub-category + tier, and none within the batch — regardless of which source
   language each row came from.
7. **No repeated prompt template.** Same template-tracking discipline as
   `generate-questions`: blank the specifics, group by shape, vary openings.
8. **Explanations are translated too** — one genuine sentence, not a restated
   option; preserve any added detail from the source.

## Kind rules

### `text`
- 4 options, `tts_excluded = false`.
- Prompt and options translated naturally.

### `image`
- Reuse the source row's `media_url` **verbatim** (it keeps pointing into the
  source language's storage folder — intentional, no re-upload, no license
  re-check).
- Copy `tts_excluded` from the source.
- Always 4 options (expand legacy 3-option rows as in rule 4 above).
- The prompt must not name the answer.
- `Credit: <author>, <license short name>, <license URL>.` inside the source
  explanation is preserved verbatim; translate only the sentence(s) before it.
- Skip any image whose subject plausibly depends on in-image text (e.g. a
  labelled diagram) — the pipeline can't translate text baked into a photo.

### `figure`
- Reuse the source `figure_svg` artwork as-is (language-neutral shapes/numbers).
- **French:** options stay `["A","B","C","D"]`; SVG unchanged.
- **Arabic:** rewrite the four label glyphs with
  `scripts/relabel_figure_svg.py --labels rtl <file>` and set options to
  `["ا","ب","ج","د"]`. The badge, the label text, and the artwork must agree.
- `tts_excluded = true`.
- If the artwork does **not** have exactly one each of the single-glyph
  `A`/`B`/`C`/`D` labels, skip the row and report it — never guess a mapping.
- Never run `generate-questions/scripts/validate_figure_svg.py` on legacy
  artwork (old 640×400 canvas / 2–3.5 strokes would fail); reuse as-is and run
  the render-and-look check instead. `relabel_figure_svg.py` warns when the
  canvas isn't the current 640×360.

## RTL / script rules

- Arabic (`ar`) is RTL: `dir="rtl"`, option keys `ا ب ج د`, text written in
  Arabic script. French (`fr`) is LTR with `A B C D`.
- Never mix scripts or leave English filler inside an Arabic/French row.

## Source selection — English first, others only to fill a gap

Default source order is `en` → `es` → `hi` → `ur`. Query `en` first; only if
it cannot supply the requested `-count` remaining rows do you move to the next
language, and so on. Never blend sources just to reach the count when English
alone can.

### Resolve the target (Step 0)

```sql
select c.language_code,
       c.slug  as category_slug,
       coalesce(tc.name, c.slug) as category_name,
       s.id    as subcategory_id,
       s.slug  as subcategory_slug,
       coalesce(ts.name, s.slug) as subcategory_name,
       s.is_active,
       s.ai_generation_allowed
from subcategories s
join categories c on c.id = s.category_id
left join taxonomy_i18n tc
  on tc.entity_type = 'category' and tc.entity_id = c.id and tc.locale = c.language_code
left join taxonomy_i18n ts
  on ts.entity_type = 'subcategory' and ts.entity_id = s.id and ts.locale = c.language_code
where c.language_code = '<TARGET_LANG>'
  and s.slug = '<SUBCATEGORY_SLUG>';
```

If this returns more than one row, the slug is ambiguous within the language:
stop and ask which category. Refuse if `is_active = false` or
`ai_generation_allowed = false`.

### Remaining per-source counts (Step 0 / Step 2)

Substitute the resolved target `subcategory_id` and the tier code. This returns
how many untranslated live source rows exist per source language and kind.

```sql
with target as (
  select s.id as subcategory_id, c.slug as category_slug,
         s.slug as subcategory_slug, c.language_code as target_lang
  from subcategories s
  join categories c on c.id = s.category_id
  where s.id = '<TARGET_SUBCATEGORY_ID>'
)
select sc.language_code as source_lang, q.kind, count(*) as remaining
from questions q
join subcategories ss on ss.id = q.subcategory_id
join categories sc on sc.id = ss.category_id
join target t on t.category_slug = sc.slug and t.subcategory_slug = ss.slug
join difficulty_tiers dt on dt.id = q.difficulty_tier_id
where sc.language_code in ('en','es','hi','ur')
  and dt.code = '<TIER_CODE>'
  and q.status = 'live'
  and q.kind in ('text','image','figure')
  and coalesce(q.prompt, '') <> ''
  and q.options is not null
  and q.correct_index is not null
  and not exists (
    select 1 from questions t2
    where t2.translated_from = q.id and t2.language_code = t.target_lang
  )
group by 1, 2
order by 1, 2;
```

### Source rows to translate (Step 2)

One query per source language, in priority order, until the requested count is
met. `-mode text` restricts `q.kind` to `('text')`; the default `all` uses
`('text','image','figure')`. `q.created_at` ordering makes repeated runs pick
up where the last left off (already-translated rows are excluded by the
`not exists` guard).

```sql
select q.id, q.language_code as source_lang, q.kind, q.difficulty,
       dt.code as tier, q.prompt, q.options, q.correct_index,
       q.explanation, q.media_url, q.figure_svg, q.tts_excluded, q.created_at
from questions q
join subcategories ss on ss.id = q.subcategory_id
join categories sc on sc.id = ss.category_id
join difficulty_tiers dt on dt.id = q.difficulty_tier_id
where sc.language_code = '<SOURCE_LANG>'
  and sc.slug = '<TARGET_CATEGORY_SLUG>'
  and ss.slug = '<TARGET_SUBCATEGORY_SLUG>'
  and dt.code = '<TIER_CODE>'
  and q.status = 'live'
  and q.kind in ('text','image','figure')      -- ('text') for -mode text
  and coalesce(q.prompt, '') <> ''
  and q.options is not null
  and q.correct_index is not null
  and not exists (
    select 1 from questions t2
    where t2.translated_from = q.id and t2.language_code = '<TARGET_LANG>'
  )
order by q.created_at
limit <COUNT>;
```

### Existing target pool (Step 2, fact-level dedup)

```sql
select id, prompt, options, correct_index, kind
from questions
where subcategory_id = '<TARGET_SUBCATEGORY_ID>'
  and difficulty_tier_id = (select id from difficulty_tiers where code = '<TIER_CODE>')
  and status <> 'suspended'
order by created_at;
```

(Language is implied by the sub-category. This is usually empty on the first
pass for a target sub-category and grows as batches land.)

## Batch SQL shape

The generated `questions.sql` is a guarded transaction; the exact shape is in
`SKILL.md` Step 7. Key points: `source = 'translated'`, `translated_from` set
per row, `audio_url` absent from the column list, and an `on conflict
(translated_from, language_code) where translated_from is not null do nothing`
clause so re-running a batch is a no-op.

## Verification (read-only, after a batch's SQL is run)

```sql
-- rows landed, live, and silent
select count(*) filter (where translated_from is not null) as translated,
       count(*) filter (where audio_url is not null)       as with_audio,
       count(*) filter (where status <> 'live')            as not_live
from questions
where language_code = '<TARGET_LANG>'
  and subcategory_id = '<TARGET_SUBCAT>'
  and difficulty_tier_id = (select id from difficulty_tiers where code = '<TIER_CODE>');

-- no duplicate translations
select translated_from, language_code, count(*)
from questions
where translated_from is not null
group by 1, 2
having count(*) > 1;
```
