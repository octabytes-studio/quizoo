# Arabic & French Question Translation from Existing Language Pools

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-10-13): "investigate … the questions from all the languages, all of
> their sub-categories and difficulty tiers and come up with the most efficient
> approach to use the questions in French and Arabic language. Basically
> instead of generating the questions for the general or identical
> sub-categories in French and Arabic language I want to translate the existing
> questions from the questions already saved in existing languages such as
> English, Urdu, Hindi, Spanish etc. … Make sure that the questions being
> translated must be saved with no audio url because we will be generating
> audios for these translated questions separately."
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation. Read it
in full before starting. It was written against live Supabase state queried on
**2026-10-13** (every count in this document comes from that query, not from
memory) and against repo state at `main` @ `74eabcf` (two uncommitted
modifications exist in `.claude/skills/generate-audios/` — user work, leave
them alone).

Three things to know before starting:

1. **`CLAUDE.md` §13: never run the app.** All verification in this plan is
   static (SQL, script output, rendered files). End with a "To verify:" list
   where a human must look at something.
2. **Database changes go through the Supabase MCP `apply_migration`** — never
   `supabase db push` (convention from plans 007/017/020/023).
3. **Content batches follow the `generate-questions` convention exactly**:
   the skill never writes to the database; it produces a `review.html` +
   `questions.sql` pair for a human to review and run. This plan keeps that
   gate.

## Objective

Arabic (`ar`) and French (`fr`) are both `is_active = true` with fully
populated 37-subcategory taxonomies — and **zero questions**, so any level
start in either language today fails with
`no live questions for subcategory …, tier …, language …`. Instead of
authoring ~10k+ new questions per language, build a **translation pipeline**
that re-expresses existing, already-reviewed live questions from English,
Spanish, Hindi and Urdu into Arabic and French for every sub-category whose
slug exists in both languages, preserving each source question's kind,
difficulty tier, correct answer, media and TTS eligibility (legacy 3-option
image rows are expanded to 4 options — see Decisions below).
Translated rows are inserted **live with `audio_url = NULL`**, so the existing
`generate-audios` skill can backfill narration later without touching them
again.

## Decisions already made (owner, 2026-10-13)

All open questions were resolved by the owner before implementation:

| Topic | Decision |
|---|---|
| Coverage | **Staged**: minimum-viable first (30/45/60 per tier), then parity top-up (150/tier) |
| Provenance | **Full migration**: `translated_from` + partial unique index + `'translated'` source value |
| Legacy 3-option image rows | **Expand to 4 options** — author one extra distractor per row (appended at the end; `correct_index` unchanged) |
| Arabic figure rows | **Included**, with the A–D → ا–د label swap |
| Source priority | **English-first**; `es`/`hi`/`ur` only as gap-fillers |
| Row status | All translated rows inserted **`live`** |
| SQL application | **Manual** — the owner runs each batch's `questions.sql` in the Supabase SQL editor |
| Review | **Every batch** fully reviewed before its SQL is run |
| Batch size | **150** questions per batch |
| Top-up order | `general` → `science` → `sports` (football, olympics) → `iq` → `maths` → the rest |
| Parallelism | **Sequential** batches — one at a time |

## Scope

**In scope:**

- A small additive migration on `public.questions` adding translation
  provenance (`translated_from`), an idempotency guard (partial unique index)
  and a `translated` value for the `source` check constraint.
- A new project skill `.claude/skills/translate-questions/` that reads source
  questions (read-only Supabase MCP), translates them natively, and writes one
  `review.html` + `questions.sql` per batch — same output contract as
  `generate-questions`, plus a source-comparison line per question card.
- Kind-specific handling: text (4 options), image (reuse the source
  `media_url` by URL; legacy 3-option rows gain a fourth authored distractor),
  figure (reuse the source `figure_svg`; Arabic swaps the four A/B/C/D label
  glyphs to ا/ب/ج/د).
- An inventory + phased execution order (pilot → minimum-viable coverage →
  parity top-up) covering the **24 Arabic** and **21 French** matched
  sub-categories (Appendix A/B).
- Verification queries proving rows landed live, language-matched, and with
  `audio_url IS NULL`.

**Out of scope:**

- Generating brand-new questions for the **13 Arabic / 16 French**
  sub-categories with no same-slug source (Appendix C) — that stays with the
  `generate-questions` skill.
- Generating audio. The plan only guarantees the translated rows are *picked
  up* by `generate-audios`; running it is a separate task and currently
  requires adding `ar`/`fr` entries to `elevenlabs_keys.json` (see Phase 5).
- Any Flutter app change — none is needed (verified: the app reads questions
  through the `start_level_attempt` RPC and a new DB column is invisible to it).
- Re-uploading images or re-verifying their licenses (the source `media_url`
  is reused as-is).
- Translating culture-specific categories that have no counterpart by design:
  `hi` Bollywood/Hinduism/India-history, `ur` Urdu-literature/Pakistan-South-Asia,
  `es` Christianity/Hispanic-heritage. Slug matching already excludes them —
  this is intentional, not an omission.

## Research findings

All counts below are live queries against the project's Supabase (2026-10-13).

### 1. The gap

| Language | Categories | Sub-categories | Live questions | With audio | Playable today? |
|---|---|---|---|---|---|
| `en` | 6 | 26 | 13,279 | 1,318 | yes |
| `hi` | 8 | 39 | 22,170 | 3,159 | yes |
| `es` | 7 | 33 | 11,792 | 0 | yes |
| `ur` | 8 | 35 | 9,751 | 278 | yes |
| `ar` | 7 | 37 | **0** | 0 | **no — empty** |
| `fr` | 7 | 37 | **0** | 0 | **no — empty** |

Both `ar` and `fr` are active in `languages` (`is_active = true`, sort orders
4 and 5), have full `taxonomy_i18n` display names, and all 37 of their
sub-categories have `is_active = true` and `ai_generation_allowed = true`.
They are visible in the app and fail only for lack of content.

### 2. How questions are served (why translated rows just work)

- `start_level_attempt` (migration `20261001090000_three_tier_difficulty_ladder.sql`,
  lines ~174–183) picks a level's pool by
  `subcategory_id + difficulty_tier_id + language_code + status = 'live'`.
  A translated row inserted with the target language's sub-category id, the
  same tier and `status='live'` is served immediately; the anti-repeat pool
  (`user_question_history`) treats each new row as never-seen.
- `_daily_rollover` builds one daily challenge per active language from that
  language's live questions, so `ar`/`fr` daily challenges start working as
  soon as the first rows land.
- `v_thin_question_pools` flags pools under `override_questions_per_level × 3`
  — Easy 30 / Medium 45 / Hard 60 — the "minimum useful batch" this plan
  uses as its first coverage milestone.
- DB integrity: `trg_enforce_question_language_match` rejects any question
  whose `language_code` differs from its sub-category's category language, so
  the pipeline must insert into the **target language's own sub-category row**
  (resolved live by `(category slug, sub-category slug)`, never hardcoded).
- `questions_source_check` currently allows only
  `('manual','ai_batch','legacy_migrated')` (the migration adds `'translated'`);
  `questions_options_check` allows 3 options **only** for `kind='image'` — but
  the owner decision is to never emit new 3-option rows, so every translated
  image row carries 4; `questions_correct_index_check` is 0–3; `difficulty`
  is 1–5 (this ladder uses 1/2/3 for easy/medium/hard).

### 3. What matches what (the translatable set)

Sub-categories were matched **by slug within the same category slug** across
languages — this is exactly the "general or identical sub-categories" rule.

- **Arabic: 24 of 37** sub-categories have a same-slug source.
  English covers **all 24**; Spanish covers 20 of them, Hindi 16, Urdu 18.
- **French: 21 of 37** sub-categories have a same-slug source.
  English covers 19; Spanish covers 20 and is the *only* source for
  `christianity/cathedrals-sacred-art` (279) and `sports/cycling` (272)
  (`sports/formula1` is English-only).

The English pools are the backbone: **every one of the 45 matched
sub-categories has ≥ 150 English questions per tier** (except where noted
below), so an English-primary strategy can hit 150/tier everywhere without
mixing sources (which matters — see §5).

### 4. Kind composition of the source pools

- **Text** dominates: ~150/tier/sub-category, some easy pools larger
  (250–500). Translating text is the bulk of the work.
- **Image** rows exist only in the **medium** tier, 20–50 per sub-category,
  in: `general/flags`, `general/world-facts`, `islam/islamic-history`,
  `science/biology`, `science/solar-system` (2), `sports/basketball`,
  `sports/boxing-mma`, `sports/football`, `sports/formula1`, `sports/olympics`,
  `sports/tennis` (English view). Media is a hosted photo/flag — **reuse
  `media_url` verbatim, no re-upload, no license re-check**.
  Legacy 3-option image rows exist (`en` 202, `hi` 350, `ur` 150 — `es` has
  0). Per owner decision these are translated by **adding a fourth authored
  distractor** (never emitting 3-option rows), matching the newer 4-option
  convention; the added option is appended at the end so `correct_index` is
  unchanged, and it is flagged in `review.html` for review.
- **Figure** rows (SVG artwork) exist only in IQ and Maths sub-categories:
  `en` 50 easy per IQ sub-cat (150 total); `es` 50 easy for IQ
  lateral-thinking, and 50/75/150 (easy/medium/hard) for iq/memory,
  iq/pattern-logic and all three maths sub-cats (1,425 total); `hi` 100
  medium per IQ sub-cat (300).
  The artwork is language-neutral (shapes + numeric sequences + `?`), except
  the four label glyphs `A`–`D`. For **French** the SVG is reused unchanged.
  For **Arabic**, the four label `<text>` elements must be rewritten to
  ا/ب/ج/د and the row's options array becomes `["ا","ب","ج","د"]` — the app
  renders RTL option badges from `Question.urduKeys = ['ا','ب','ج','د']`
  (`lib/features/quiz_play/domain/question.dart:85`,
  `quiz_play_screen.dart:406`) and renders `options[index]` as the label, so
  artwork, badge and label must agree.
  Note: existing figure SVGs use the older 640×400 canvas and 2/3.5 stroke
  widths, so **`generate-questions/scripts/validate_figure_svg.py` must NOT be
  run on them** (it enforces the new 640×360 + stroke-6/3 spec and would
  reject valid legacy art). Translation reuses the artwork as-is and only
  relabels it.

### 5. Hard-tier sourcing caveat

`es` and `ur` pools are mostly easy/medium: e.g. `es` has zero hard questions
in `capitals`, `movies`, `world-facts`, `chemistry`, `space-exploration`,
`stars-galaxies`, all sports, and lateral-thinking; `ur` has zero hard
questions in every matched sub-category except none at all (its hard counts
are all 0 in Appendix A). `en` and `hi` are the only sources with full
hard-tier depth. Combined with the fact that the same fact often exists in
several source languages (e.g. "Red Planet" in all four), the default source
strategy is **English first; `es`/`hi`/`ur` only to fill a gap English can't**
— and a hard rule that no two translated rows in the same target
sub-category+tier may test the same fact, whatever their source.

### 6. Volume (what "translate everything" would cost)

| Target | Minimum-viable (30/45/60 per tier) | Parity (150/tier) | English pool ceiling |
|---|---|---|---|
| `ar` (24 sub-cats) | **3,240** | **10,800** | 12,239 |
| `fr` (21 sub-cats) | **2,715** | **9,101** | 11,390 |

At 150 questions per batch this is ~40 batches for minimum-viable and ~133
for parity across both languages; batches are generated sequentially (owner
decision). Minimum-viable makes both languages fully playable end-to-end
(no repeats inside a level, ≥3 unique levels per tier per sub-category);
parity matches the existing languages' density.

### 7. Existing project machinery to reuse

- `.claude/skills/generate-questions/SKILL.md` — output contract
  (`review.html` + `questions.sql` in a `<parent>/questions/<subcat>-<tier>-<lang>-<timestamp>/`
  folder next to the project), SQL guard-block shape, review template
  (`reference/review-template.html` — has a `.source` line class already),
  figure asset convention (`assets/q<N>.svg`), status defaults, escaping
  rules. The new skill mirrors this contract.
- `.claude/skills/generate-audios/` — picks up `audio_url IS NULL AND
  status='live' AND tts_excluded=false` per language listed in
  `/Users/waleed/Documents/projects/elevenlabs_keys.json`. That file currently
  has **8 `en`, 7 `hi`, 7 `ur` entries and zero `ar`/`fr` entries**, so audio
  generation will skip Arabic and French until entries are added.
- `supabase/migrations/` naming + `apply_migration` convention; latest
  migration `20261006210547_play_question_media_and_figure_payloads.sql`.

## Remaining assumptions & open questions

All decisions are recorded in "Decisions already made" above. What remains is
not a choice but a set of execution constraints to keep in mind:

- **Reviewer proficiency.** The `review.html` gate is only as good as the
  reviewer — someone who reads Arabic and French must review each batch. No
  automated translation-quality check is proposed beyond the skill's
  self-audit.
- **`ai_generation_allowed`.** All 37+37 target sub-categories and all source
  sub-categories are `true` today, so no exclusion is needed; the skill still
  checks it at run time and refuses if it ever flips to `false`.
- **`translated` source value.** The migration adds it, so
  `.claude/skills/generate-questions/reference/schema-and-samples.md`
  (which documents `source ∈ manual/ai_batch/legacy_migrated`) must be
  updated in the same change (Phase 0).
- **Two French hard-tier gaps** (`christianity/cathedrals-sacred-art`,
  `sports/cycling`) have no source at any tier — they stay empty until a
  future `generate-questions` run; not part of this plan.
- **Storage-path deviation.** Reused `media_url`s keep pointing into the
  source language's storage folder; this is intentional (no re-upload), not a
  bug to fix later.

## Design overview

```
                    ┌───────────────────────────────┐
  Supabase (read)   │  source questions (en/es/hi/ur)│
                    └──────────────┬────────────────┘
                                   │  select untranslated, by subcat+tier
                                   ▼
        .claude/skills/translate-questions  ──►  review.html  (source vs translation)
        (new skill, batch of N)             ──►  questions.sql (NOT executed)
                                   │
                 human reviews both files, then runs questions.sql
                                   ▼
  questions rows (ar/fr): translated_from = source id,
                          status = live, source = 'translated',
                          audio_url = NULL  ──►  generate-audios later
```

**Why a new skill instead of extending `generate-questions`:** the source of
truth changes (read an existing row and re-express it), and the skill needs
its own hard rules (always 4 options, reuse media, figure relabel,
`audio_url` stays NULL). `generate-questions` is already ~930 lines; a sibling
skill keeps both single-purpose and lets the translation skill cross-reference
the existing schema reference instead of duplicating it.

**Provenance model:** `questions.translated_from → questions.id` (nullable,
`on delete set null`) plus a **partial unique index on
`(translated_from, language_code)`** — one source row can be translated at
most once per target language. This gives:

- idempotent re-runs (`on conflict … do nothing`),
- per-batch and per-language progress in one query,
- review/audit traceability from any translated row back to its original,
- room to translate the same source row into both `ar` and `fr` (different
  `language_code`).

**Batch contract (mirrors `generate-questions`):** output folder
`<parent-of-project>/questions/<subcategory>-<tier>-<lang>-<timestamp>/`
containing `review.html` (same template/UI as generate-questions, plus a
per-card `Source: <lang> · <source id> — "<source prompt>"` line) and
`questions.sql` (guarded transaction, one tuple per question, `-- Q<N>`
comments naming the source row), plus `assets/q<N>.svg` for figure rows.

**Skill invocation surface (planned):**

```
/translate-questions -lang ar -subcategory capitals -tier easy -count 150 \
                     [-source en] [-status live|draft] [-mode text|all]
```

- `-lang` / `-subcategory` / `-tier` are required; the skill resolves the
  target sub-category id, its category, and its language live.
- `-source` optional (default `en`, then `es` → `hi` → `ur` only if the
  requested `-count` exceeds the remaining English pool).
- `-count` default 150, no hard cap (larger batches → bigger review file; the
  skill warns above 200).
- `-mode` default `all` (text+image+figure); `text` excludes media kinds.
- Refuses: target language mismatch, `ai_generation_allowed = false`,
  missing source rows, or `-lang`/`-subcategory` that don't resolve.

## Implementation steps

### Phase 0 — Provenance migration (one file, one MCP call)

- [ ] Create `supabase/migrations/<YYYYMMDDHHMMSS>_question_translation_provenance.sql`
      (use the actual current timestamp; the SQL is in "Data model / API
      changes" below).
- [ ] Apply it with the Supabase MCP `apply_migration` tool (never
      `supabase db push`).
- [ ] Verify with the read-only check queries in "Testing strategy".
- [ ] Update
      `.claude/skills/generate-questions/reference/schema-and-samples.md`'s
      `source` row to include `translated` (part of the full-migration
      decision).

### Phase 1 — Build the `translate-questions` skill

Create `.claude/skills/translate-questions/` with:

- [ ] `SKILL.md` — frontmatter (name, description, compatibility) and steps
      0–8, mirroring `generate-questions`' structure:
  - **Step 0 — resolve config + progress.** Read
    `reference/schema-and-translation-rules.md`. Parse args. Run one read-only
    MCP query resolving: target sub-category id + category slug + language,
    `ai_generation_allowed`, and remaining untranslated source counts for the
    requested target/tier (see "Testing strategy" for the query). If Supabase
    MCP is unavailable, stop (this skill cannot run without it).
  - **Step 1 — confirm the batch.** Print: target (language, category,
    sub-category, tier), source language chosen, N to translate, existing
    target-pool size, kind split, output folder. Ask go/no-go.
  - **Step 2 — fetch source rows + existing target prompts.** Query
    `-count` live source rows for the target slug/tier, ordered by
    `created_at`, excluding anything already translated for this language
    (`not exists (select 1 from questions t where t.translated_from = q.id and
    t.language_code = '<target>')`). Also fetch every existing live prompt in
    the **target** sub-category+tier (for fact-level dedup). Keep both sets.
  - **Step 3 — translate.** Hard rules (see below). Native phrasing in the
    target language, never word-for-word; preserve option order and produce
    exactly 4 options (expanded with an authored distractor where the source
    had 3). `correct_index` unchanged; facts/numbers exact; proper nouns
    rendered the target language's standard way.
  - **Step 4 — kind-specific handling.**
    - text: 4 options, `tts_excluded = false`.
    - image: copy `media_url` and `tts_excluded` from the source; always
      produce **4 options** — for legacy 3-option source rows, author one
      extra plausible distractor and append it at the end (`correct_index`
      unchanged); the prompt must not name the answer.
    - figure: copy `figure_svg`; for Arabic run
      `scripts/relabel_figure_svg.py --labels rtl` and set options to
      `["ا","ب","ج","د"]`; for French leave SVG and options as-is;
      `tts_excluded = true`; write `assets/q<N>.svg` for the review file.
    - `Credit: …` lines inside image explanations stay verbatim (only the
      sentence before them is translated).
  - **Step 5 — self-audit.** Per batch: no repeated prompt template (blank the
    specifics and group), no duplicate facts (against the fetched target
    pool and within the batch), every row has exactly 4 options (expanded
    legacy image rows' added distractor is plausible, wrong, and distinct),
    every Arabic figure has exactly 4 relabeled glyphs, no English/Spanish/
    Hindi/Urdu text left behind except proper nouns and credit lines.
  - **Step 6 — write `review.html`.** Copy
    `generate-questions/reference/review-template.html` **verbatim** (same
    `<style>`, same card skeletons) and add one `<p class="source">` per card:
    `Source: <LANG> · <source id> — “<source prompt>”`. Flag the newly
    authored option on expanded legacy image rows (e.g. a trailing `+ new`
    marker) so the reviewer checks it. RTL layout (`dir=rtl`, ا ب ج د keys)
    for Arabic. `grep -c '{{' review.html` must be 0.
  - **Step 7 — write `questions.sql`.** Exact shape in "Data model / API
    changes". `audio_url` must not appear in the column list. Guard block
    checks the target sub-category exists, its language matches, and
    `ai_generation_allowed`.
  - **Step 8 — final message.** Paths, counts by kind, source language(s),
    what the self-audit changed, and the reminder: nothing was saved; review
    `review.html`, then run `questions.sql` yourself.
- [ ] `reference/schema-and-translation-rules.md` — the `questions` column
      contract (quote `generate-questions/reference/schema-and-samples.md`
      rather than re-deriving), the tier mapping (easy=1, medium=2, hard=3;
      codes `easy`/`medium`/`hard`), translation-quality rules, kind rules,
      and the exact source-selection SQL.
- [ ] `reference/review-template.html` — copy of the generate-questions
      template (do not edit its style block).
- [ ] `scripts/relabel_figure_svg.py` — stdlib-only. Modes:
  - `--check`: assert exactly one each of `<text …>A</text>`, `B`, `C`, `D`
    (single-glyph content only); exit non-zero with the offending file
    printed otherwise.
  - `--labels rtl`: same check, then rewrite A→ا, B→ب, C→ج, D→د inside those
    four elements only; print each replacement.
  - Never runs `validate_figure_svg.py` (legacy canvas/strokes would fail);
    prints a warning when the canvas isn't 640×360 so the render check isn't
    skipped.
- [ ] Update `.claude/skills/generate-questions/SKILL.md`'s "Related skills"
      area (if such a note exists) — or add one line to its description-adjacent
      text — pointing at the new skill for translation runs. Keep the diff
      minimal; do not restructure the file (CLAUDE.md §10 spirit).

### Phase 2 — Pilot batch (proves the whole pipeline)

- [ ] Run `/translate-questions -lang ar -subcategory capitals -tier easy -count 30`
      (the smallest full loop; `general/capitals` is the simplest pool —
      world capitals, no media, no culture-specific content).
- [ ] Review `review.html`; fix anything by editing `questions.sql` directly
      (the skill's contract).
- [ ] Run the SQL in the Supabase SQL editor.
- [ ] Verify with the acceptance queries (count = 30, `audio_url IS NULL`,
      language match, `translated_from` populated).
- [ ] Verify a level attempt can be started for an `ar` `general/capitals`
      easy pool: the pool query returns ≥1 live row (read-only SQL; do not
      run the app).
- [ ] Confirm `generate-audios` *would* pick these up (read-only query: rows
      match `audio_url IS NULL AND status='live' AND tts_excluded=false`;
      actual generation is Phase 5 and currently blocked by missing `ar`
      entries in `elevenlabs_keys.json`).

### Phase 3 — Minimum-viable coverage (both languages)

- [ ] For every row in Appendix A (`ar`, 24 sub-cats) and Appendix B (`fr`,
      21 sub-cats): one batch per sub-category+tier to the minimum-viable
      target — Easy 30, Medium 45, Hard 60 — using English as source
      (`es` only for `fr` `cathedrals-sacred-art` and `cycling`).
      Batches are generated **sequentially** (owner decision, one at a time);
      each is reviewed and applied independently.
- [ ] Two known shortfalls (no source reaches the target): `fr`
      `christianity/cathedrals-sacred-art` Hard (es hard = 0) and `fr`
      `sports/cycling` Hard (es hard = 0) — translate what exists
      (Easy 30 / Medium 45 / Hard 0) and note the hard-tier gap for
      `generate-questions` later.
- [ ] Re-run the coverage query; every matched sub-category+tier should have
      ≥ its target (or the shortfall noted). `v_thin_question_pools` should
      shrink to only the genuinely thin pools.

### Phase 4 — Parity top-up (150/tier)

- [ ] Top up every matched sub-category+tier from its current count to 150
      (cap; the oversized English easy pools — `stars-galaxies` 500,
      `flags` 250, `space-exploration` 250, `basketball`/`boxing-mma`/
      `olympics`/`tennis` 250 — are capped at 150 unless the user asks for
      more).
- [ ] Suggested priority order: `general/*` → `science/*` → `sports/football`
      + `sports/olympics` → `iq/*` → `maths/*` → remaining sports, then the
      rest. The order is a convenience, not a correctness requirement.
- [ ] Re-run the coverage query after each language completes.

### Phase 5 — Audio enablement (hand-off; run is separate)

- [ ] Add `ar` and `fr` key/voice entries to
      `/Users/waleed/Documents/projects/elevenlabs_keys.json` (format:
      `{"language":"ar","voice_id":"…","api_key":"sk_…"}`). Without entries
      for a language, `generate-audios` skips it entirely.
- [ ] Run `/generate-audios` for `ar`/`fr` (optionally `-f` with a file of
      translated row ids; the skill filters to `audio_url IS NULL` anyway).
- [ ] Verify a sample row's `audio_url` is populated and points into
      `question-audio/<lang>/<id>.mp3`.

## Data model / API changes

### Migration (Phase 0) — `supabase/migrations/<timestamp>_question_translation_provenance.sql`

```sql
-- Translation provenance for questions translated from another language's pool
-- (plan 024). Additive and safe: existing rows keep translated_from = null.
begin;

alter table public.questions
  add column if not exists translated_from uuid
    references public.questions(id) on delete set null;

comment on column public.questions.translated_from is
  'Source question this row was translated from (null for non-translations).';

-- one source row -> at most one translation per target language
create unique index if not exists uq_questions_translation_target
  on public.questions (translated_from, language_code)
  where translated_from is not null;

create index if not exists idx_questions_translated_from
  on public.questions (translated_from)
  where translated_from is not null;

-- widen the source vocabulary so translations are queryable as such
do $$ begin
  if exists (select 1 from pg_constraint where conname = 'questions_source_check') then
    alter table public.questions drop constraint questions_source_check;
  end if;
  alter table public.questions add constraint questions_source_check
    check (source in ('manual','ai_batch','legacy_migrated','translated'));
end $$;

commit;
```

No Flutter/API change: the app consumes questions only through
`start_level_attempt` (and duels/daily RPCs), which select named columns; a
new column is invisible. No Edge Function touches `questions`.

### Batch SQL shape (what the skill writes per batch)

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

Notes for the executor:

- `difficulty` int per tier: easy 1, medium 2, hard 3 (matches the live
  3-tier ladder).
- Keep `correct_index` identical to the source's — options are translated
  in place, order preserved, so the index stays correct.
- Image rows: `media_url` = the source row's URL (still in the source
  language's storage folder — intentional, no re-upload); always 4 options —
  legacy 3-option sources get one authored distractor appended at index 3,
  `correct_index` unchanged.
- Figure rows (Arabic): `options = ["ا","ب","ج","د"]`, SVG relabeled; French:
  options and SVG unchanged.
- SQL string escaping: double every literal `'` inside text.
- To drop a question: delete its tuple and the `-- Q<N>` comment, fix commas.

## Dependencies

- No new packages. The skill is documentation + one stdlib-only Python
  script; the batch SQL runs in the Supabase SQL editor.
- Supabase MCP server (required for the skill: target resolution, source
  fetch, progress; and for applying the Phase 0 migration).
- `qlmanage` (macOS) for the mandatory visual check of relabeled Arabic figure
  SVGs; if unavailable, the skill must say so and fall back to the
  `--check`-mode structural validation (no silent skip).
- `elevenlabs_keys.json` (Phase 5 only) — currently missing `ar`/`fr`.

## Testing strategy

There is no Flutter code in this plan, so `bloc_test`/`mocktail` conventions
do not apply. Verification is static:

1. **Migration checks (read-only SQL, after Phase 0):**
   ```sql
   select column_name from information_schema.columns
   where table_name = 'questions' and column_name = 'translated_from';
   select indexname from pg_indexes
   where tablename = 'questions' and indexname like '%translation%';
   select pg_get_constraintdef(oid) from pg_constraint
   where conname = 'questions_source_check';
   ```
2. **Batch-level acceptance (read-only SQL, after each SQL run):**
   ```sql
   -- rows landed, live, and silent
   select count(*) filter (where translated_from is not null)        as translated,
          count(*) filter (where audio_url is not null)              as with_audio,
          count(*) filter (where status <> 'live')                   as not_live
   from questions
   where language_code = '<TARGET>' and subcategory_id = '<TARGET_SUBCAT>';
   ```
   `with_audio` must be 0 and `not_live` 0 for the batch's tier.
3. **Coverage / progress (read-only SQL):**
   ```sql
   select c.language_code, c.slug as category, s.slug as subcategory,
          dt.code as tier, count(*) as live_count,
          count(*) filter (where q.translated_from is not null) as translated_count
   from questions q
   join subcategories s on s.id = q.subcategory_id
   join categories c on c.id = s.category_id
   join difficulty_tiers dt on dt.id = q.difficulty_tier_id
   where c.language_code in ('ar','fr') and q.status = 'live'
   group by 1,2,3,4
   order by 1,2,3,4;
   ```
4. **Audio pickup check (read-only SQL):**
   ```sql
   select language_code, count(*)
   from questions
   where language_code in ('ar','fr')
     and audio_url is null and status = 'live' and tts_excluded = false
   group by language_code;
   ```
   This is exactly the `generate-audios` candidate set for those languages.
5. **Script-level checks:** `relabel_figure_svg.py --check` on every Arabic
   figure row (exactly four labels), then the render-and-look check
   (`qlmanage -t -s 1280 …` + Read the PNG) per the generate-questions
   convention. French figures: structural check only.
6. **Skill self-audit (Step 5)** is the content-level test: template variety,
   fact dedup against the existing target pool, option-count parity, no
   leftover source-language text.
7. **Human review** of each `review.html` before its SQL is run — the only
   quality gate for translation accuracy. Arabic/French proficiency required.
8. `CLAUDE.md` §13 applies: no app runs. The "To verify:" list is at the end
   of this plan.

## Edge cases & error handling

- **Source row already translated** (re-run): the selection
  query excludes it and `on conflict … do nothing` is the backstop; no
  duplicates possible once the unique index exists.
- **Same source row needed in both `ar` and `fr`**: allowed — the index is
  per `(translated_from, language_code)`.
- **Legacy 3-option image rows**: translated by authoring a fourth
  distractor (appended at the end, `correct_index` unchanged) and flagged in
  the review file — never emit a 3-option row.
- **Arabic figure rows with ≠ 4 single-glyph labels** (unexpected artwork):
  skip the row and report it; never guess a mapping.
- **Figure SVG with text other than the labels** (`?`, numeric sequences):
  untouched — the relabel script only rewrites single-glyph `A`–`D` text
  elements.
- **Image with embedded source-language text**: photos/flags/landmarks are
  safe by the generate-questions rules (no overlaid answer text), but the
  skill spot-checks the fetched source prompts and skips any image whose
  content plausibly depends on in-image text (e.g. a labelled diagram).
- **Credit lines** (`Credit: <author>, <license>, <url>.`) in image
  explanations: preserved verbatim; only the sentence before them is
  translated.
- **Source row suspended / missing tier / null prompt/options/correct_index**:
  filtered out by the selection query; if the resulting batch is smaller than
  requested, the skill reports the shortfall instead of padding.
- **Duplicate facts across source languages**: avoided by English-first
  sourcing + Step 5's fact dedup against the target pool.
- **`-lang`/`-subcategory` mismatch or `ai_generation_allowed = false`**:
  refuse before generating anything (same hard gate as generate-questions).
- **Batch SQL re-run after partial failure**: idempotent via the unique
  index; the skill's Step 0 progress query is the source of truth for what
  remains.
- **Source question deleted later**: `translated_from` becomes null
  (`on delete set null`); the translation survives.
- **`audio_url` accidentally set**: impossible via the generated SQL (column
  absent), and caught by the acceptance query; fix by `update … set
  audio_url = null` for the affected ids.
- **Very large `-count`**: warn above 200 (review file size); the skill may
  split the batch into multiple output folders.

## Acceptance criteria

- [ ] Migration applied: `translated_from` column, both indexes and the
      widened `source` constraint exist (checks in Testing strategy §1).
- [ ] `translate-questions` skill exists with SKILL.md, schema/translation
      reference, review template, and `relabel_figure_svg.py`; a dry run
      produces a `review.html` + `questions.sql` pair for a real target
      without writing to the DB.
- [ ] Pilot: 30 `ar` `general/capitals` easy rows inserted, `status='live'`,
      `source='translated'`, `translated_from` populated, **`audio_url IS
      NULL`**, `language_code='ar'`.
- [ ] Minimum-viable coverage reached for every Appendix A/B row (or its
      documented shortfall: the two French hard tiers with no source).
- [ ] No question row anywhere in `ar`/`fr` has `audio_url IS NOT NULL` for
      a translated row (`select count(*) … = 0`).
- [ ] Every translated row has exactly 4 options, including expanded legacy
      image rows (no 3-option rows emitted).
- [ ] No duplicate translations: `select translated_from, language_code,
      count(*) from questions where translated_from is not null group by 1,2
      having count(*) > 1` returns zero rows.
- [ ] `v_thin_question_pools` no longer lists any `ar`/`fr` matched
      sub-category+tier below its target (except the two documented French
      hard gaps).
- [ ] A level-start pool query for a sample `ar` and `fr` sub-category+tier
      returns ≥ 10 (easy) / 15 (medium) / 20 (hard) live rows — i.e. no
      repeat padding for a full level.
- [ ] `generate-audios` candidate query returns the translated rows for both
      languages (blocked only on `elevenlabs_keys.json` entries, Phase 5).

## Risks & rollout notes

- **Translation quality is the main risk.** Mitigations: native-phrasing
  rules, source-vs-translation review file, batch self-audit, and a human
  bilingual review before each SQL run. Do not skip the review gate to "go
  faster" — bad translations are live immediately once inserted.
- **Volume/time.** Parity is ~20k rows across both languages (~133 batches
  at 150/batch). Phasing (pilot → minimum-viable → parity) means the
  languages become fully playable after ~40 batches and can stop at any
  point without leaving a broken state (every batch is self-contained and
  idempotent).
- **Sequential batches (owner decision).** One batch at a time keeps review
  and application simple; each batch keeps its own review folder, and a bad
  batch is easy to identify and delete (delete its rows by
  `translated_from in (…)`).
- **Content nuance.** Some source facts are region-flavoured (e.g. `ur`
  football includes Asian Cup/African Cup facts; `hi` sports has kabaddi —
  but those sub-categories don't match). The matched sub-categories are
  world-oriented (spot-checked), but reviewers should flag anything that
  reads oddly in `ar`/`fr`.
- **Storage convention deviation.** Reused `media_url`s point into the
  *source* language's folder (`question-media/en/<source-id>.png`). This is
  intentional and documented; nothing in the app or DB requires the path to
  match the question's language. Do not "fix" it by re-uploading thousands
  of images.
- **`source='translated'` value** must be reflected in the generate-questions
  reference doc (Phase 0) so future runs of that skill don't treat it as
  unknown.
- **Rollback.** Per batch: `delete from questions where translated_from in
  (…batch source ids…) and language_code = '<target>'`. Global: same with a
  language filter. The migration itself is additive and does not need
  rollback.
- **Docs to update after implementation:** the two skill docs (Phase 1),
  `generate-questions/reference/schema-and-samples.md` (`source` vocabulary),
  and optionally `.claude/docs/backend/01-supabase-project-setup.md` if it
  enumerates content tables' columns.

## To verify (human, after implementation)

1. Open a pilot batch's `review.html` in a browser and read 10 random cards
   against their source lines — Arabic reads naturally, options match the
   source meaning, the correct answer is the same fact.
2. Run the pilot `questions.sql` in the Supabase SQL editor; re-run the
   Testing-strategy §2 query and confirm 30 translated / 0 with audio /
   0 not live.
3. In the app (once you choose to run it yourself): switch the language tab
   to العربية and play one level of العواصم (capitals) — questions appear in
   Arabic with ا/ب/ج/د badges; then the same for French.
4. For an Arabic figure row: open its `assets/q<N>.svg` and confirm the four
   labels read ا/ب/ج/د and the artwork is unchanged otherwise.

---

## Appendix A — Arabic (`ar`) translatable inventory

Source pools are live-question counts per tier, `E/M/H`, from the 2026-10-13
snapshot. `—` = no such source. English covers every row; the other columns
are optional top-up depth. Target columns are this plan's two milestones
(min-viable / parity).

| # | Category / Sub-category | en E/M/H | es E/M/H | hi E/M/H | ur E/M/H | Min-viable | Parity |
|---|---|---|---|---|---|---|---|
| 1 | general / capitals | 150/150/150 | 149/166/— | 300/200/200 | 250/150/— | 30/45/60 | 150/150/150 |
| 2 | general / flags | 250/200/150 | 150/225/131 | 300/200/200 | 250/—/— | 30/45/60 | 150/150/150 |
| 3 | general / movies | 150/150/150 | 250/225/— | — | 250/—/— | 30/45/60 | 150/150/150 |
| 4 | general / world-facts | 150/200/150 | 147/225/— | 300/200/199 | 250/—/— | 30/45/60 | 150/150/150 |
| 5 | iq / lateral-thinking | 200/150/150 | 150/150/— | 250/350/200 | — | 30/45/60 | 150/150/150 |
| 6 | iq / memory | 200/150/150 | 150/225/150 | 250/350/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 7 | iq / pattern-logic | 200/150/150 | 150/225/150 | 250/350/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 8 | islam / islamic-history | 150/200/150 | — | — | 150/—/— | 30/45/60 | 150/150/150 |
| 9 | islam / quran | 150/150/150 | — | — | — | 30/45/60 | 150/150/150 |
| 10 | islam / seerah | 150/150/150 | — | — | 150/150/— | 30/45/60 | 150/150/150 |
| 11 | maths / geometry | 150/150/150 | 150/225/150 | 250/150/198 | 150/150/— | 30/45/60 | 150/150/150 |
| 12 | maths / mental-maths | 150/150/150 | 150/225/150 | 250/150/199 | 150/150/— | 30/45/60 | 150/150/150 |
| 13 | maths / number-theory | 150/150/150 | 150/225/150 | 250/150/199 | 150/150/— | 30/45/60 | 150/150/150 |
| 14 | science / biology | 150/200/150 | 150/175/149 | 150/200/200 | 150/200/— | 30/45/60 | 150/150/150 |
| 15 | science / chemistry | 150/150/150 | 100/150/— | 150/150/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 16 | science / solar-system | 150/152/155 | 110/170/10 | 150/200/200 | 201/200/— | 30/45/60 | 150/150/150 |
| 17 | science / space-exploration | 250/150/150 | 114/180/— | 150/150/197 | 150/200/— | 30/45/60 | 150/150/150 |
| 18 | science / stars-galaxies | 500/150/150 | 119/202/— | 150/200/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 19 | sports / basketball | 250/170/150 | 150/177/— | — | — | 30/45/60 | 150/150/150 |
| 20 | sports / boxing-mma | 250/170/150 | 111/176/— | — | — | 30/45/60 | 150/150/150 |
| 21 | sports / football | 150/174/158 | 119/194/— | 150/150/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 22 | sports / formula1 | 150/170/150 | — | — | — | 30/45/60 | 150/150/150 |
| 23 | sports / olympics | 250/170/150 | 122/163/— | 150/150/198 | 150/150/— | 30/45/60 | 150/150/150 |
| 24 | sports / tennis | 250/170/150 | 197/225/— | — | — | 30/45/60 | 150/150/150 |

**Totals:** minimum-viable **3,240**; parity **10,800**; English pool
ceiling 12,239.

## Appendix B — French (`fr`) translatable inventory

| # | Category / Sub-category | en E/M/H | es E/M/H | hi E/M/H | ur E/M/H | Min-viable | Parity |
|---|---|---|---|---|---|---|---|
| 1 | christianity / cathedrals-sacred-art | — | 129/150/— | — | — | 30/45/0 | 129/150/0 |
| 2 | general / capitals | 150/150/150 | 149/166/— | 300/200/200 | 250/150/— | 30/45/60 | 150/150/150 |
| 3 | general / flags | 250/200/150 | 150/225/131 | 300/200/200 | 250/—/— | 30/45/60 | 150/150/150 |
| 4 | general / movies | 150/150/150 | 250/225/— | — | 250/—/— | 30/45/60 | 150/150/150 |
| 5 | general / world-facts | 150/200/150 | 147/225/— | 300/200/199 | 250/—/— | 30/45/60 | 150/150/150 |
| 6 | iq / lateral-thinking | 200/150/150 | 150/150/— | 250/350/200 | — | 30/45/60 | 150/150/150 |
| 7 | iq / memory | 200/150/150 | 150/225/150 | 250/350/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 8 | iq / pattern-logic | 200/150/150 | 150/225/150 | 250/350/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 9 | maths / geometry | 150/150/150 | 150/225/150 | 250/150/198 | 150/150/— | 30/45/60 | 150/150/150 |
| 10 | maths / mental-maths | 150/150/150 | 150/225/150 | 250/150/199 | 150/150/— | 30/45/60 | 150/150/150 |
| 11 | maths / number-theory | 150/150/150 | 150/225/150 | 250/150/199 | 150/150/— | 30/45/60 | 150/150/150 |
| 12 | science / biology | 150/200/150 | 150/175/149 | 150/200/200 | 150/200/— | 30/45/60 | 150/150/150 |
| 13 | science / chemistry | 150/150/150 | 100/150/— | 150/150/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 14 | science / solar-system | 150/152/155 | 110/170/10 | 150/200/200 | 201/200/— | 30/45/60 | 150/150/150 |
| 15 | science / space-exploration | 250/150/150 | 114/180/— | 150/150/197 | 150/200/— | 30/45/60 | 150/150/150 |
| 16 | science / stars-galaxies | 500/150/150 | 119/202/— | 150/200/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 17 | sports / cycling | — | 100/172/— | — | — | 30/45/0 | 100/150/0 |
| 18 | sports / football | 150/174/158 | 119/194/— | 150/150/200 | 150/150/— | 30/45/60 | 150/150/150 |
| 19 | sports / formula1 | 150/170/150 | — | — | — | 30/45/60 | 150/150/150 |
| 20 | sports / olympics | 250/170/150 | 122/163/— | 150/150/198 | 150/150/— | 30/45/60 | 150/150/150 |
| 21 | sports / tennis | 250/170/150 | 197/225/— | — | — | 30/45/60 | 150/150/150 |

**Totals:** minimum-viable **2,715**; parity **9,101**; English pool ceiling
11,390. Rows 1 and 17 have **no Hard source** — their hard tiers stay empty
until generated.

## Appendix C — No-source sub-categories (out of scope for translation)

These have no same-slug source in any of `en/es/hi/ur` and still need
`generate-questions` (or another authoring path). Counts shown are what
parity (150/tier) would need.

**Arabic (13 sub-categories → 5,850 generated at parity):**
`arab-heritage/` abbasid-caliphate, andalusia, arabic-poetry,
house-of-wisdom, islamic-golden-age, middle-east-geography,
one-thousand-and-one-nights · `general/inventions-discoveries` ·
`islam/` fiqh-worship, hadith, names-of-allah · `sports/` handball,
volleyball.

**French (16 sub-categories → 7,200 + 300 for the two hard gaps = 7,500):**
`christianity/` biblical-literature, christian-history-france,
christian-holidays, saints-figures · `general/` french-language, gastronomy ·
`history-geography/` european-geography, francophonie, french-regions,
french-revolution, kings-and-queens, napoleon-empire, paris-monuments ·
`sports/` boxing-martial-arts, rugby, winter-sports · plus the Hard tiers of
`christianity/cathedrals-sacred-art` and `sports/cycling`.
