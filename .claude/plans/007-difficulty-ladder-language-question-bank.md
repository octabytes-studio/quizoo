# 50-Level Difficulty Ladder, Anti-Repeat Question Bank, Countdown/TTS & Multi-Language Content Model

> Source spec: `.claude/specs/quizoo-difficulty-language-questionbank-spec.md`
> (drafted by a prior cloud session, alongside `supabase/migrations/0003_difficulty_ladder_v2.sql`,
> `0004_multilingual_content_model.sql`, `0005_question_bank_and_anti_repeat.sql` — all three
> currently untracked in git, never applied to any database).
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history. Start
by reading it in full, then read the three companion migration files above — this
plan documents exact, line-referenced fixes to bugs found in them, rather than
repeating their full contents. Code may have moved on since this was written
(2026-09-12); re-open the files this plan cites before trusting a line number.

**Prerequisite**: plans `005-backend-foundation-core-loop.md` and
`006-social-economy-realtime-backend.md` are already implemented (git history:
`938d646 Merge pull request #9 .../feature/backend-integration`) — the app is
already on a real Supabase backend, not mock data, for auth/catalog/quiz-play/
duels/economy. This plan is an amendment to that live backend, not a fresh build.

**A note on the source spec's own framing**: the spec was written by a session
with **no live Supabase connection** and explicitly says so, asking that its
migrations be reconciled against the real schema before running. This plan is
that reconciliation — it was written by opening every file the spec's migrations
touch and the actual current schema/RPCs, and found several concrete bugs and one
significant architectural conflict, both detailed below.

## Objective

Implement all four changes from the source spec against this repo's actual
schema and Flutter code:
1. A bounded 50-level, 5-tier difficulty ladder (was: 20 levels, 4 bands), fully
   table-driven (`difficulty_tiers`, `app_settings`) rather than hardcoded in Dart or SQL.
2. A curated, per-user anti-repeat question bank as the primary runtime source
   (was: a live shuffle over a shared `questions`/`question_i18n` pool with no
   per-user repeat tracking).
3. A 3-2-1 countdown with TTS read-aloud and a staggered answer-option reveal,
   gated behind a new `QuestionPhase` state machine (was: options and timer both
   start the instant a question loads).
4. A multi-language content model where `categories`/`subcategories`/`questions`
   each belong to exactly one language, not a shared taxonomy translated via a
   join table (was, and largely still is for names: `taxonomy_i18n`/`question_i18n`).

## Scope

**In scope:**
- Fixing and correctly sequencing migrations `0003`/`0004`/`0005` (currently
  unrunnable as named/shaped — see Research findings) and adding one new
  migration that rewrites `start_level_attempt`/`submit_level_attempt` to the
  new model.
- `lib/core/models/level.dart`, `subcategory.dart` — 5-tier band, 50-level default.
- New `core/` ladder-config domain model + repository/api (tiers, boss interval —
  fetched once, not hardcoded).
- `features/catalog`: language-scoped category/subcategory queries; level
  building driven by fetched ladder config instead of `MockCatalog.bandFor`/`secondsFor`.
- `features/quiz_play`: question bank integration end to end (`start_level_attempt`
  response shape, `Question` model, `QuizPlayRepository`/`Api`, `submit_level_attempt`
  payload), `QuestionPhase` state machine, `flutter_tts` integration, HUD speaker
  icon, percentage-based star thresholds.
- `features/onboarding`: language picker sourced from live `languages.is_active` rows.
- `pubspec.yaml`: add `flutter_tts`.
- `lib/l10n/app_en.arb` / `app_ur.arb`: new strings (`difficultyMaster`, TTS-related copy).
- Tests: `bloc_test` updates for `QuizPlayCubit`, repository tests for the new
  API shapes, per CLAUDE.md §11.

**Out of scope (matches the source spec's own §12, confirmed against this repo):**
- `matchmake`/`resolve-duel`/`submit_duel_answer`/`resolve_duel_round`/`resolve_duel`/
  `submit_bot_duel` — untouched. They read `question_i18n` directly (see
  `duel_api.dart:125`), which migration `0004` explicitly leaves in place.
- `_daily_rollover`'s daily-challenge question pick (`_daily_rollover`,
  `20260907120200_functions_and_triggers.sql:1220-1225`) — still `order by
  random() limit 10` over ALL languages with no `language_code` filter. This is a
  **real gap this research surfaced** (a French player could get an English daily
  question once non-English content exists) but the source spec never mentions
  daily challenge, so it is flagged under Assumptions rather than silently fixed.
- An admin UI for content authoring beyond the Supabase table editor.
- Retiring `taxonomy_i18n`/`question_i18n` — deprecated, not dropped.

## Research findings

### The backend has no Edge Functions — everything is a Postgres RPC

The spec talks throughout about a `start-level` / `submit-level` **Edge
Function**. This repo has none (`find ... -iname "*functions*"` under
`supabase/` turns up nothing but migrations). Gameplay is `public.start_level_attempt`
and `public.submit_level_attempt`, two `security definer` PL/pgSQL functions in
`supabase/migrations/20260907120200_functions_and_triggers.sql:442-694`, called
directly via `supabase.rpc(...)` from `lib/features/quiz_play/data/quiz_play_api.dart`.
Wherever the spec says "the `start-level` Edge Function", read "`start_level_attempt`
RPC"; the plan below does the same.

### The current ladder is duplicated, hardcoded, in both SQL and Dart

- SQL: `_difficulty_band_for_level`/`_seconds_for_level`/`_question_difficulty_range`
  (`20260907120200_functions_and_triggers.sql:95-132`) hardcode 4 bands over
  levels 1-20, and `start_level_attempt` computes `is_boss` as `p_level % 5 = 0`
  inline (line 494, repeated at line 505).
- Dart: `MockCatalog.bandFor`/`secondsFor` (`lib/core/mock/mock_catalog.dart:439-452`)
  are a **deliberate** 1:1 mirror of the SQL functions — the class's own doc
  comment on `CatalogApi` says so explicitly (`catalog_api.dart:11-16`): "the
  schema deliberately has no `levels` table because of it." `CatalogApi._levelFor`
  (`catalog_api.dart:285-307`) and `QuizPlayCubit.startLevel`
  (`quiz_play_cubit.dart:157`) both independently hardcode `number % 5 == 0` for
  boss levels too.
- `core/models/level.dart:12`: `enum DifficultyBand { warmUp, steady, sharp, brutal }`
  — 4 values, referenced non-generically in `mock_catalog.dart`,
  `catalog/domain/level_map.dart:43`, `catalog/presentation/widgets/serpentine_path.dart:329-332`
  (label mapping), and `test/features/catalog/catalog_cubit_test.dart:203-209`.
- `core/models/subcategory.dart:29`: `@Default(20) int levelCount`.

**This is a direct conflict with the spec's own explicit goal** (§2.1: "Stored in
`difficulty_tiers`... not hardcoded in the app... a Supabase table edit, not an
app release"). Keeping `MockCatalog.bandFor`/`secondsFor` as literal Dart mirrors
of the SQL ladder would silently reintroduce the exact hardcoding the spec is
trying to eliminate. See Design overview for the fix (a fetched, cached ladder config).

### The question model is still the shared-taxonomy join, not per-language rows

`start_level_attempt` currently does `join public.question_i18n qi on qi.question_id
= q.id and qi.locale = p_locale` (`20260907120200_functions_and_triggers.sql:485`),
shuffles with `order by md5(v_seed || q.id::text) limit 20`, and has **no
per-user history tracking at all** — every level attempt is a fresh random draw
with no anti-repeat. `submit_level_attempt` re-derives correctness the same way,
from `question_i18n.correct_index` keyed by `(question_id, locale)`
(`functions_and_triggers.sql:574-575`). Migrations `0004`/`0005` are meant to
replace this, but see the bugs below — as drafted, they don't fully integrate
with the tables `start_level_attempt`/`submit_level_attempt` actually use.

### `CatalogApi` already hardcodes English; `LocaleCubit` already exists app-root

`CatalogApi._defaultLocale = 'en'` (`catalog_api.dart:25`) with a comment
admitting it: "taxonomy renders in English regardless of the active locale for
now (plan 005, Design overview)." **The app-wide locale mechanism this needs
already exists**: `lib/app/locale_cubit.dart` + `locale_state.dart`
(`LocaleSystem`/`LocaleSelected`, `Locale? get locale`), provided at app root
per CLAUDE.md §3's "genuinely app-wide" exception, and already read by
`quiz_play_screen.dart:74` (`Localizations.localeOf(context).languageCode`). The
gap is narrower than it looks: `CatalogApi` needs to actually *use* the active
locale to filter, not invent a new mechanism.

`lib/features/onboarding/presentation/screens/language_picker_screen.dart:50-91`
hardcodes 5 static language options (en/ur/ar/hi/es), independent of any table.

### Bugs found in the three draft migrations (must fix before they can run)

These were found by tracing `0003`/`0004`/`0005` against the actual base schema
(`20260907120000_initial_schema.sql`) and the actual `start_level_attempt`/
`submit_level_attempt` bodies. None of this is a judgment call — these are
concrete defects:

1. **Filename ordering will break a full migration replay.** Supabase (and
   `supabase db reset`) applies `supabase/migrations/*.sql` in **filename
   lexicographic order**. `0003_...` sorts *before* `20260907120000_initial_schema.sql`
   (`'0' < '2'`), so on a fresh database or fresh branch — exactly what the
   spec's own §0 rollout instructions call for ("run on a staging project or a
   Supabase branch first") — `0004`'s `alter table categories add column
   language_code` would run before `categories` even exists, and fail outright.
   **Fix**: rename all three files to sort after the newest existing migration
   (`20260909120100_...`), e.g. `20260910090000_difficulty_ladder_v2.sql`,
   `20260910090100_multilingual_content_model.sql`,
   `20260910090200_question_bank_and_anti_repeat.sql` (content unchanged except
   the other fixes below).

2. **`get_level_questions()` selects a column that doesn't exist.**
   `0005_question_bank_and_anti_repeat.sql:113` does `select q.id, q.prompt,
   q.options ... from questions q`, but `0004_multilingual_content_model.sql`'s
   column-add list (lines 66-73) never adds `prompt` to `questions` — only
   `language_code`, `difficulty_tier_id`, `status`, `source`, `kind`, `options`,
   `correct_index`, `explanation`. Every call to `get_level_questions()` would
   fail with "column q.prompt does not exist". **Fix**: add
   `alter table questions add column if not exists prompt text;` to the
   migration, backfilled from `question_i18n.prompt` for the row's own
   `language_code` (see Assumption 3 below for the one case this backfill can't
   handle blindly).

3. **`v_thin_question_pools` references a column `subcategories` doesn't have.**
   `0005:176` does `sc.name as subcategory_name ... from subcategories sc`, but
   `subcategories` has no `name` column in this schema — names live in
   `taxonomy_i18n` (`initial_schema.sql:144-151`). A view definition is checked
   at creation time, so this `create or replace view` fails immediately on
   `column sc.name does not exist`, meaning **migration `0005` cannot complete at
   all** as drafted. **Fix**: use `sc.slug` instead (existing column, sufficient
   for an internal ops view — no need to join `taxonomy_i18n` for a display name
   an ops query doesn't need).

4. **A new status vocabulary silently fails to apply.** `0004`'s `do $$ ... if
   not exists (conname = 'questions_status_check') ...` (lines 76-79) is meant
   to change the allowed `status` values from `('draft','live','suspended')` to
   `('draft','live','retired')`. But the base schema's inline check on
   `questions.status` (`initial_schema.sql:160`) auto-names to
   `questions_status_check` (Postgres's default single-column check-constraint
   naming), which **already exists** — so the `if not exists` guard skips
   silently, and `'retired'` is never actually a valid value; `'suspended'`
   stays. Not fatal to `get_level_questions()` (it only ever checks `status =
   'live'`), but it means §3.6's content lifecycle (retiring bad AI drafts)
   quietly doesn't work. **Fix**: `alter table questions drop constraint if
   exists questions_status_check;` before re-adding it with the new value list
   — or, more simply, keep `'suspended'` as the retire-value and skip
   introducing `'retired'` at all, since nothing downstream requires the new
   name. This plan recommends the latter (smaller diff, no behavior actually
   needed changes).

### The one real architectural conflict: `correct_index` on the client

`start_level_attempt`'s own comment block (`functions_and_triggers.sql:425-441`)
documents, at length, **a previous deliberate decision**: this app ships
`correct_index` to the client and lets it render right/wrong instantly with zero
network round-trip, specifically because `Question.correctIndex` is a `required`
field the whole play surface is built around. Concretely:
`quiz_play_screen.dart:342` (`_optionState`) colors the correct option mint the
moment *any* answer lands, by reading `state.question.correctIndex` directly, and
`quiz_play_cubit.dart:259` compares the tapped index to it client-side. Anti-cheat
already rests entirely on `submit_level_attempt` re-deriving correctness
server-side and never trusting the client's claim — never on hiding the answer key.

The new spec's §3.5/§8 says the opposite: "The client never receives
`correct_index`... grade by matching each submitted answer to its `question_id`
explicitly." Implementing that literally would mean either a per-question
network round-trip (breaking the explicitly-documented "no blocking network
mid-level" invariant this codebase already committed to) or a shuffle-token
scheme — a materially bigger change than anything else in this spec, undoing a
decision the same codebase already reasoned through once.

**Recommendation (see Assumptions #2)**: keep the existing behavior — ship
`correct_index` to the client, keep server-side re-derivation as the actual
anti-cheat boundary — and do not implement §3.5/§8's "hide `correct_index`"
requirement. Everything else in the spec (anti-repeat tracking, 50-level ladder,
multi-language, TTS) is independent of this and is implemented in full.

## Assumptions & open questions

1. **Migration renaming/fixes (Research findings #1-4) are not really "open"** —
   they're required corrections with an unambiguous fix, folded into
   Implementation Phase 0. Flagged here only because they mean the three
   migration files this plan inherits cannot be run as-is.

2. **`correct_index` stays on the client** (Research findings, last section).
   This is a deliberate, flagged deviation from spec §3.5/§8, carried forward
   from a decision this same codebase already made once for the same reason.
   **This needs an explicit human sign-off before implementation**, since it's
   a real product/security trade-off, not a mechanical fix — if whoever executes
   this plan disagrees, §3.5/§8 can still be implemented, but it changes the
   `get_level_questions()` response contract, removes the instant-color-reveal
   UX, and requires a design for *how* the player learns they were right (a
   per-question RPC after each answer, most likely) that this plan does not
   attempt to design.

3. **Whether real bilingual content already exists in `question_i18n`/
   `taxonomy_i18n` is unknown from this session** (same caveat the source spec
   itself raised in §5.3, still unresolved — no live DB access here either).
   This matters for the `prompt` backfill (Research finding #2): if a given
   `questions.id` has **only one** `question_i18n` row (locale = 'en'), folding
   its `prompt`/`options`/`correct_index`/`explanation` onto the same row is a
   straight 1:1 backfill. If a question has **both** an `en` and a `ur` row, the
   new per-language model requires the `ur` content to become a **new**
   `questions` row (new id, under a `ur`-language subcategory) — categories/
   subcategories would need the same split first. That split cannot be safely
   scripted blind (same reasoning the spec's own §5.3 gives). **Before running
   the fixed migrations**: run `select question_id, count(*) from question_i18n
   group by question_id having count(*) > 1 limit 1;` against the real
   database. Zero rows → the straightforward backfill in Phase 0/1 is sufficient.
   Any rows → stop and write a dedicated data-migration for the multi-locale
   rows before proceeding (out of scope for this plan to design blind).

4. **`start_level_attempt` absorbs `get_level_questions()`'s job rather than the
   client calling both.** The spec's §8 has the client call
   `rpc('get_level_questions', {...})` directly, which mints its own `attempt_id`
   into `level_attempt_question_sets` — entirely disconnected from
   `level_attempts` (the table `submit_level_attempt` actually keys off, and
   where hearts are spent, `seed`, `locale`/`language_code`, and `is_boss` are
   recorded). Implementing the spec literally would mean **two** attempt
   concepts that don't talk to each other. **This plan's design**: rewrite
   `start_level_attempt` to do the anti-repeat pick itself (inlining the ranking
   query `get_level_questions()` specifies), using the `level_attempts.id` it
   already creates as the same id it writes into `level_attempt_question_sets`.
   The client keeps calling `start_level_attempt` exactly as today — no RPC name
   or call-site changes on the Flutter side beyond the response shape gaining a
   few fields. `get_level_questions()` as its own standalone grantable RPC is
   **not created**; its selection logic lives inside `start_level_attempt`
   instead. If a reviewer wants `get_level_questions()` kept as a separately
   callable RPC (e.g. for a future practice mode), it can be factored out as an
   internal helper both functions call — flagged as an easy follow-up, not done
   here to avoid two ways to start a level existing at once.

5. **Star thresholds need converting to percentages.** `_stars_for` (SQL,
   `functions_and_triggers.sql:166-176`) and `Scoring.stars`/`correctForNextStar`
   (Dart, `scoring.dart:72-86`) hardcode absolute correct-answer counts (12/16/20
   of a fixed 20). Once `app_settings.questions_per_level` is configurable
   (spec §2.3/§3.3) or a tier overrides it, a level with, say, N=10 could never
   reach 2 stars. **Fix**: convert both to percentage bands — ≥60% → 1 star,
   ≥80% → 2, 100% → 3 (exactly reproduces today's 12/16/20-of-20 breakpoints at
   N=20, so this is behavior-preserving at the current default and only changes
   behavior if N is ever edited away from 20).

6. **Where the fetched ladder config (tiers + boss interval) should live
   client-side is a placement call, not a hard rule.** It's needed by both
   `features/catalog` (level map/category detail rendering) and
   `features/quiz_play` (deriving `secondsPerQuestion`/`isBoss` display before
   `start_level_attempt` returns, and for the countdown screen). CLAUDE.md §10
   says cross-feature reuse goes through `core/`; §2 describes `core/` as for
   "genuinely app-wide, reused-by-3+-features" code, and this is reused by
   exactly 2 features plus arguably the leaderboard's difficulty display later.
   **This plan recommends `core/`** (a small `core/models/difficulty_tier.dart`
   domain model + a `core/network`-adjacent read, cached once at app start,
   same shape as how `languages`/`app_settings` are both "select for everyone"
   per spec §7) on the grounds that it's infrastructure-like config, not
   feature-specific business logic — closer to `AppSpacing`/`Breakpoints` than
   to a feature's domain model. Flagged in case a reviewer prefers it live
   inside `catalog/` with `quiz_play` importing `catalog`'s public repository
   (CLAUDE.md doesn't forbid a Cubit depending on another feature's repository
   interface, only reaching into another feature's `data`/`domain` internals
   directly — either placement is defensible).

7. **Daily challenge doesn't filter by language** (Scope, above) — a real gap
   this research surfaced, not mentioned in the source spec at all. Flagged
   here rather than fixed, since `_daily_rollover` is untouched by every one of
   the source spec's four requested changes and touching it now would be
   scope creep beyond what was asked. Worth a one-line follow-up once
   non-English content actually exists.

8. **Language picker (`language_picker_screen.dart`) hardcodes 5 languages**,
   including `ar`/`hi`/`es`, which the spec seeds as `is_active = false` (only
   `en`/`ur` active). Recommendation: source the picker's option list from the
   `languages` table filtered to `is_active = true`, so flipping a language on
   later needs zero app release — matching the spec's own stated intent for
   `languages.is_active` (§5.1: "no schema change needed to add a language...
   just flip `is_active`"). The minimal alternative (hardcode the picker down
   to just `en`/`ur`, drop the other three options entirely, still static) is
   called out as a smaller-diff fallback if a live-fetched picker is judged out
   of scope for this change.

9. **TTS audio-preference storage should reuse the existing `AppSettings.soundOn`
   toggle**, not invent a third one. `features/settings/domain/app_settings.dart`
   already has a persisted `soundOn` (S-42, via `SettingsRepository`) that
   currently does nothing (plan 002's own note: "nothing plays sound... in this
   phase"). Separately, `PauseSheet.isSoundOn`/`toggleSound()`
   (`pause_sheet.dart`) is a **different, ephemeral, non-persisted** per-run
   toggle that also does nothing. This plan wires the new HUD speaker icon (§4.2
   requirement: "persists across sessions") to `AppSettings.soundOn` via
   `SettingsRepository`, giving that setting its first real behavior. The
   pause sheet's separate, still-inert toggle is left exactly as it is — unifying
   it with the real preference is a reasonable follow-up but is not something
   this spec asked for, and changing pause-sheet behavior is out of scope here.

10. **`flutter_tts` version is not pinned in this plan.** Check the current
    stable version on pub.dev at implementation time rather than trusting a
    number written here; this plan was not run against a live pub.dev query.

## Design overview

### Backend (Postgres — Supabase)

**Phase 0 — fix the three draft migrations in place** (they were never run, so
editing them directly is correct; there is no "already applied" history to
preserve for these three specifically):
- Rename per Research finding #1.
- Add the `prompt` column + backfill per Research finding #2 (guarded by the
  Assumption #3 pre-check).
- Change `v_thin_question_pools` to use `sc.slug` per Research finding #3.
- Drop the `questions_status_check` rewrite (Research finding #4) — keep
  `'suspended'`, don't introduce `'retired'`.

**Phase 1 — a new migration** (timestamp after Phase 0's renamed files) that:
- Rewrites `start_level_attempt(p_subcategory_id, p_level, p_locale)` — keeping
  its exact signature so the Flutter call site
  (`quiz_play_api.dart:35-42`) needs no RPC-name/param change:
  - Still: `_settle_hearts`, hearts-check, `_grant_currency(... 'hearts', -1 ...)`.
  - New: resolve `difficulty_tiers` row via `get_difficulty_for_level(p_level)`
    instead of `_question_difficulty_range`; resolve `is_boss` via
    `is_boss_level(p_level)` instead of `p_level % 5 = 0`.
  - New: create the `level_attempts` row **first** (so its `id` exists), then run
    the anti-repeat ranked-pool selection (the query `get_level_questions()` in
    `0005` specifies: `order by h.last_seen_at asc nulls first`, tiled with
    modulo indexing when the pool is smaller than N) filtered by
    `subcategory_id`, `difficulty_tier_id`, `language_code = p_locale`,
    `status = 'live'`, writing the result into `level_attempt_question_sets`
    using **that same `level_attempts.id`** as its `id`, and upserting
    `user_question_history`.
  - Response JSON keeps its existing shape (`attemptId`, `secondsPerQuestion`,
    `isBoss`, `questions[]`) but each question row now comes from `questions`
    directly (`prompt`, `options`, `correct_index`, `explanation`,
    `tts_excluded` — see below) instead of joining `question_i18n`, and
    `secondsPerQuestion`/`isBoss` come from the resolved tier / `is_boss_level`
    rather than the old 4-band functions. Per Assumption #2, `correctIndex` is
    still included in each question row — no anti-cheat regression, since
    `submit_level_attempt` never trusted it anyway.
  - `p_level`'s check constraint is already widened to `1..50` by (renamed)
    `0003` — no change needed here beyond what that migration already does.
- Rewrites `submit_level_attempt` to:
  - Look up each answer's `correct_index` from `questions.correct_index` via
    `level_attempt_question_sets.question_ids` for this `p_attempt_id`
    (join `level_attempt_question_sets` on `id = p_attempt_id`), matched by
    `question_id` — never by array position, per spec §3.5 — instead of
    `question_i18n` keyed by `(question_id, locale)`.
  - Replace `_seconds_for_level` with `get_difficulty_for_level(v_attempt.level)
    .seconds_per_question`.
  - Replace the hardcoded `v_question_count = 20 and v_correct_count = 20` with
    `v_correct_count = v_question_count` (already dynamic on the *count reached*,
    just drop the literal 20).
  - Replace `_stars_for(p_correct_count)` with a percentage-based version taking
    both `p_correct_count` and `p_total_count` (Assumption #5); `is_boss` already
    reads from the stored `level_attempts.is_boss` (now itself set from
    `is_boss_level()`, not `% 5`), so no change needed there.
  - Mark `level_attempt_question_sets.graded_at = now()` for this attempt
    (existing column, currently never written by anything in `0005`).
- Adds `questions.tts_excluded boolean not null default false` (§4.4) — a
  straightforward `alter table ... add column if not exists`, folded into this
  migration since it's new to this phase, not part of `0004`'s original scope.
- No changes needed to `_check_level_achievements`, `_grant_currency`,
  `_touch_daily_streak`, wallet/league logic — level 41-50 and a bigger N both
  flow through the existing formulas without a hardcoded ceiling (confirmed:
  `_difficulty_multiplier`, XP, and coin formulas are all `level`-scaled with no
  literal cap — the spec's §2.2 "revert the diffMult freeze" instruction is
  **not applicable here**: this codebase's `_difficulty_multiplier`
  (`functions_and_triggers.sql:144-149`) was never frozen in the first place).

### Flutter — new shared ladder config (`core/`)

- `core/models/difficulty_tier.dart` (new, freezed): `code` (String — matches
  `difficulty_tiers.code`), `label`, `secondsPerQuestion`, `levelStart`,
  `levelEnd`.
- A small new read (placement per Assumption #6) fetching all 5
  `difficulty_tiers` rows plus `app_settings` (`boss_level_interval`) once,
  cached for the process lifetime (same "fetch once, hold in memory" shape as
  `QuizPlayRepository._prefetched`, not a Cubit — this is static-for-the-session
  reference data, not UI state). Exposes:
  - `tierFor(int level) -> DifficultyTier` (replaces `MockCatalog.bandFor`)
  - `secondsFor(int level) -> int` (replaces `MockCatalog.secondsFor`)
  - `isBoss(int level) -> bool` (replaces every `% 5 == 0` / `% 10 == 0` site)

### `core/models/level.dart` / `subcategory.dart`

- `DifficultyBand`: add a 5th value `master` (keep `warmUp/steady/sharp/brutal`
  names — renaming them buys nothing functionally and multiplies the diff across
  `mock_catalog.dart`, `level_map.dart`, `serpentine_path.dart`, and the catalog
  test). Every exhaustive switch over it (`serpentine_path.dart:329-332`'s
  `difficultyLabel`) gets a 5th arm mapping to a new `l10n.difficultyMaster`
  string (add to both `app_en.arb` and `app_ur.arb`, mirroring the existing
  `difficultyEasy`/`difficultyMedium`/`difficultyHard`/`difficultyExpert` entries
  at `app_en.arb:300-307`).
- `Subcategory.levelCount` default: `20` → `50`.
- `level_map.dart:43`'s placeholder `Level` (`DifficultyBand.warmUp`) is
  unaffected — still valid, just one of 5 values now.

### `features/catalog`

- `CatalogApi`: drop the hardcoded `_defaultLocale` fallback-chain design;
  accept the active language code (already threaded as `locale` params in
  `fetchCategory`/`fetchLevelMap`, just never called with anything but the
  default) from the call site, which reads it from `LocaleCubit`'s current
  `Locale` (same pattern `quiz_play_screen.dart:74` already uses). Add
  `.eq('language_code', languageCode)` to the `categories`/`subcategories`
  queries. Since each entity now belongs to exactly one language,
  `_taxonomyNames`'s two-locale fallback (`locale`, then `_defaultLocale`) can
  simplify to a single-locale lookup (a category never has taxonomy_i18n rows in
  a locale other than its own `language_code`).
- `_levelFor`/`levelsFor`: replace `MockCatalog.bandFor(number)`/
  `MockCatalog.secondsFor(number)`/`number % 5 == 0` with the new ladder-config
  lookups (`tierFor`/`secondsFor`/`isBoss`).
- `Subcategory.levelCount` naturally becomes 50 via the model default; no
  per-row override needed since every subcategory has all 5 tiers.

### `features/quiz_play`

- `Question` domain model (`question.dart`): add `ttsExcluded` (`@Default(false)
  bool`), sourced from `questions.tts_excluded`.
- `PreparedLevel`/`QuizPlayApi.fetchLevelQuestions` (`quiz_play_api.dart`):
  currently discards `secondsPerQuestion`/`isBoss` from `start_level_attempt`'s
  response (bug independent of this spec, surfaced by this research — see
  Research findings). Extend `PreparedLevel` to carry `secondsPerQuestion` and
  `isBoss` through from the RPC response, so `QuizPlayCubit.startLevel` uses the
  **server's authoritative values** instead of `MockCatalog.secondsFor(levelNumber)`
  / `levelNumber % 5 == 0` (`quiz_play_cubit.dart:154,157`) — this removes the
  last hardcoded-ladder-shape dependency from the play-surface Cubit entirely.
- `QuizPlayRepository`: thread the two new fields through `questionsFor`'s
  companion accessors the same way `attemptIdFor` already works.
- `scoring.dart`: `Scoring.stars`/`correctForNextStar` become percentage-based,
  taking a `totalCount` parameter (mirrors the SQL fix — Assumption #5), called
  everywhere with `run.questionCount` (already available on `QuizRun`).
- `QuizPlayCubit`: new `QuestionPhase` enum — `speaking`, `revealing`,
  `answering` (a deliberate 3-value simplification of the spec's 4-value
  `speaking → revealing → answering → answered` list: "answered" is already
  fully represented by the existing `QuestionFeedback` sealed hierarchy once
  `feedback is! NoFeedback`, so a 4th phase value would be redundant state — see
  Design notes below).
  - `QuizPlayInProgress` gains a `phase: QuestionPhase` field, defaulting to
    `answering` (today's behavior) when audio is off or `question.ttsExcluded`.
  - `_beginQuestion`: if audio on and not excluded, emit `phase: speaking`, call
    the injected TTS service's `speak(question.text)`; **do not start the
    clock**. On its completion callback, transition to `revealing` (drives the
    staggered fade+slide entrance animation on the options — a presentation
    concern, `70-90ms` stagger per option per spec §4.2), then to `answering`
    once the animation window elapses, and **only then** call `_startClock()`.
    If audio off / excluded, go straight to `answering` and start the clock
    immediately (today's exact behavior, unchanged).
  - New `toggleAudio()`-adjacent method: on the speaker-icon tap mid-`speaking`,
    call the TTS service's `stop()` and jump straight to `answering` (start the
    clock now) per spec §4.2 point 4 — don't wait for a completion callback that
    will never fire.
  - Guard every TTS completion callback against a stale callback firing after
    `next()`/`skipCountdown()`/`_finish()` already moved on (compare against the
    question index the callback was registered for, same defensive pattern the
    existing `_countdownTimer` callback already uses at `quiz_play_cubit.dart:170-171`).
  - **Testability**: wrap `flutter_tts` behind a small injectable interface
    (e.g. `abstract class TtsService { Future<void> speak(String text); Future<void>
    stop(); void onComplete(void Function() cb); }`) rather than importing the
    plugin directly into the Cubit, so `bloc_test`/`fake_async` can supply a fake
    that completes synchronously or on a controlled delay — mirrors this
    project's existing "the Cubit is pure Dart, tested without a widget
    binding" convention (`quiz_play_cubit.dart:41-48`'s own doc comment explains
    exactly this reasoning for why the clock is a `Timer`, not a `Ticker`).
- `QuizHud`: add a speaker icon (mirrors `_ChromeButton`'s existing style),
  reading/writing `AppSettings.soundOn` via an injected `SettingsRepository`
  (Assumption #9) rather than a new preference.
- `run.isBoss` (`quiz_play_cubit.dart:157`) now comes from `PreparedLevel`
  (server-authoritative), not `levelNumber % 5 == 0`.

### `features/onboarding`

- `LanguagePickerScreen._options`: replace the hardcoded list with rows fetched
  from `languages` where `is_active = true`, ordered by `sort_order`
  (Assumption #8's recommended path) — `flag`/`quizCount` per option either come
  from new columns on `languages` (out of scope to add speculatively) or stay as
  small local lookup tables keyed by `code`, since those are cosmetic and not
  part of the spec's data model. The **minimal fallback**, if a live fetch here
  is judged out of scope: trim the static list down to just `en`/`ur` (drop
  `ar`/`hi`/`es` entirely, since offering a language with zero live content
  behind it is a worse experience than not offering it).

## Implementation steps

### Phase 0 — Fix and reorder the draft migrations
- [ ] Rename `0003_difficulty_ladder_v2.sql` → `20260910090000_difficulty_ladder_v2.sql`
      (content unchanged).
- [ ] Rename `0004_multilingual_content_model.sql` →
      `20260910090100_multilingual_content_model.sql`; add the `prompt` column +
      backfill (Research finding #2); run the Assumption #3 pre-check query
      against the real database before deciding how to handle any multi-locale
      rows found.
- [ ] Rename `0005_question_bank_and_anti_repeat.sql` →
      `20260910090200_question_bank_and_anti_repeat.sql`; fix
      `v_thin_question_pools` to select `sc.slug` (Research finding #3).
- [ ] Confirm `questions_status_check` in `0004` is left as a no-op (Research
      finding #4) — remove that `do $$` block or leave it inert; document why in
      a one-line comment so a future reader doesn't "fix" it into breaking the
      existing `'suspended'` vocabulary.

### Phase 1 — New RPC-rewrite migration
- [ ] New file `20260910090300_ladder_rpc_rewrite.sql`:
  - `alter table questions add column if not exists tts_excluded boolean not
    null default false;`
  - `create or replace function public.start_level_attempt(...)` per Design
    overview (tier/boss lookup, anti-repeat pick inlined, `level_attempts.id`
    shared with `level_attempt_question_sets.id`).
  - `create or replace function public._stars_for(p_correct_count int,
    p_total_count int)` — percentage bands; update its one caller in
    `submit_level_attempt`.
  - `create or replace function public.submit_level_attempt(...)` per Design
    overview (question_ids/correct_index lookup, dynamic flawless check,
    `get_difficulty_for_level` for seconds, `graded_at` write).
  - Re-run the `grant execute on function public.start_level_attempt(uuid,
    smallint, text) to authenticated;` / `submit_level_attempt(...)` grants
    (signatures unchanged, but `create or replace` doesn't require a re-grant —
    include for clarity/idempotency anyway).

### Phase 2 — Shared Dart ladder config (`core/`)
- [ ] `core/models/difficulty_tier.dart` (new freezed model, per Design overview).
- [ ] A small repository/api pair (or a single class, per Assumption #6's
      placement note) fetching `difficulty_tiers` + `app_settings.boss_level_interval`
      once, exposing `tierFor`/`secondsFor`/`isBoss`; register at app root
      (`app/app.dart`) alongside other app-wide providers, fetched once at boot
      similar to how auth/session bootstrapping already happens.
- [ ] `core/models/level.dart`: add `DifficultyBand.master`.
- [ ] `core/models/subcategory.dart`: `levelCount` default `20` → `50`.
- [ ] `lib/l10n/app_en.arb` / `app_ur.arb`: add `difficultyMaster` (mirror the
      existing 4 entries' `@description` shape at `app_en.arb:300-307`); run
      the project's `flutter gen-l10n` / `build_runner` step to regenerate
      `app_localizations_en.dart`/`_ur.dart`.

### Phase 3 — `features/catalog`
- [ ] `CatalogApi`: thread the active language code into `fetchCategory`/
      `fetchLevelMap`/`fetchLevel` call sites (from `LocaleCubit`), add
      `.eq('language_code', ...)` to the `categories`/`subcategories` queries,
      simplify `_taxonomyNames` to a single-locale lookup.
  - Note: 0004's model has subcategories inherit their language from their
    parent category (no `language_code` column on `subcategories` itself) —
    filtering subcategories by language therefore means filtering by
    `category_id` (already language-scoped), not a direct column match.
- [ ] `_levelFor`/`levelsFor`: replace `MockCatalog.bandFor`/`secondsFor`/
      `% 5 == 0` with the Phase 2 ladder-config lookups.
- [ ] `serpentine_path.dart:329-332`'s `difficultyLabel` switch: add the
      `DifficultyBand.master => l10n.difficultyMaster` arm.
- [ ] `test/features/catalog/catalog_cubit_test.dart:203-209`: update expected
      band boundaries for the new 50-level/5-tier shape, add a 5th assertion
      for the Master tier.

### Phase 4 — `features/quiz_play` question-bank + ladder integration
- [ ] `question.dart`: add `ttsExcluded`.
- [ ] `quiz_play_api.dart`: extend `PreparedLevel` with `secondsPerQuestion`,
      `isBoss`; parse both from `start_level_attempt`'s (already-returning)
      response fields.
- [ ] `quiz_play_repository.dart`: expose the two new fields alongside
      `attemptIdFor`.
- [ ] `quiz_play_cubit.dart`: `startLevel` uses `PreparedLevel.secondsPerQuestion`/
      `.isBoss` instead of `MockCatalog.secondsFor`/`% 5 == 0`.
- [ ] `scoring.dart`: `Scoring.stars`/`correctForNextStar` take a `totalCount`
      param, percentage bands (Assumption #5); update every call site
      (`quiz_result` feature, wherever `Scoring.stars` is called for display —
      grep before editing to catch all call sites).
- [ ] `test/features/quiz_play/quiz_play_repository_test.dart`,
      `quiz_play_cubit_test.dart`: update fixtures for the new response shape.

### Phase 5 — Countdown, TTS, staggered reveal
- [ ] `pubspec.yaml`: add `flutter_tts` (check current stable version on
      pub.dev — Assumption #10).
- [ ] New `TtsService` abstraction + a `FlutterTtsService` implementation
      (quiz_play `data/`), injected into `QuizPlayCubit` alongside
      `QuizPlayRepository`.
- [ ] `QuizPlayCubit`: `QuestionPhase` enum, `_beginQuestion` rework, mid-speech
      toggle handling, stale-callback guards — per Design overview.
- [ ] `QuizPlayInProgress`: add `phase` field; `quiz_play_state.dart` update.
- [ ] Staggered reveal animation on the options list
      (`quiz_play_screen.dart`'s `_QuestionView`, the `for (var index = 0; ...)`
      loop building `AnswerOption`s at lines 421-436) — only render/animate
      options once `phase == answering` or `revealing`; fade+slide-up,
      ~70-90ms stagger per option (use `flutter_animate`, already a dependency,
      matching the existing `.animate()` usage pattern in this same file and in
      `countdown_screen.dart`).
- [ ] `QuizHud`: speaker icon (new `_ChromeButton`-styled control), wired to
      `AppSettings.soundOn` via an injected `SettingsRepository` (Assumption #9).
- [ ] Handle `setLanguage`/voice-pack failure per spec §4.1: catch the TTS
      service's language-set error, fall back to silent mode (skip straight to
      `answering`) rather than blocking the question screen.

### Phase 6 — Multi-language app-side (onboarding)
- [ ] `LanguagePickerScreen`: source options from `languages` where
      `is_active = true` (or apply the minimal `en`/`ur`-only fallback —
      Assumption #8), ordered by `sort_order`.

### Phase 7 — Tests
- [ ] `bloc_test` for `QuizPlayCubit`'s new phase transitions: initial
      `speaking` → `revealing` → `answering` (audio on, TTS completes), and the
      audio-off / `ttsExcluded` path going straight to `answering` — per
      CLAUDE.md §11's "initial state + success + failure" minimum, plus the
      mid-speech-toggle-off path as an explicit case.
  - **Test-timing note** (matches this project's own recorded gotcha — memory
    `feedback_flutter_test_timing.md` — worth re-reading before writing these):
    a fake `TtsService` that completes synchronously will race the Cubit's own
    state emissions in a way a real plugin never would; drive it under
    `fake_async` and control exactly when `onComplete` fires, the same way the
    existing clock tests already control `Timer.periodic` under `fake_async`.
    A widget-level `pumpAndSettle()` on a screen with a live periodic ticker
    (the per-question clock) will run it to completion, not just one frame —
    use a single bounded `pump()` if a test only wants the reveal-animation's
    immediate effect, exactly per that memory's second gotcha.
- [ ] Repository/API tests (`mocktail`) for `CatalogApi`'s new
      `language_code`-filtered queries and `QuizPlayApi`'s extended
      `PreparedLevel` parsing.
- [ ] A manual/SQL smoke test (not a Dart test, run against staging) matching
      the source spec's own §10.6: play levels 5, 25, 45; confirm a row lands
      in both `level_attempt_question_sets` and `user_question_history`, and
      replaying the same level serves different questions until the pool
      rotates.

## Data model / API changes

**New/changed tables** (via the fixed/renamed migrations, Phase 0-1):
- `languages`, `difficulty_tiers`, `app_settings`, `user_question_history`,
  `level_attempt_question_sets`, `v_thin_question_pools` (view) — as specified,
  with the Phase 0 fixes applied.
- `categories` +`language_code` (FK, `unique(language_code, slug)`).
- `subcategories` +`ai_generation_allowed` (language inherited via `category_id`).
- `questions` +`language_code`, +`difficulty_tier_id`, +`status` (unchanged
  vocabulary — Research finding #4), +`source`, +`kind`, +`options`,
  +`correct_index`, +`explanation`, +`prompt` (the fix), +`tts_excluded` (new,
  Phase 1).
- `level_progress`/`level_attempts.level` check constraint: `1..20` → `1..50`.

**`start_level_attempt(p_subcategory_id uuid, p_level smallint, p_locale text)`**
— unchanged signature, response shape unchanged
(`{attemptId, secondsPerQuestion, isBoss, questions: [{id, subcategoryId,
difficulty, text, options, correctIndex, explanation, hasImage, imageAsset,
ttsExcluded}]}`), internals rewritten per Design overview. `ttsExcluded` is the
one new field in each question row.

**`submit_level_attempt(p_attempt_id uuid, p_answers jsonb, p_used_power_up
boolean, p_ending text)`** — unchanged signature and response shape, internals
re-derive correctness via `level_attempt_question_sets`/`questions.correct_index`
instead of `question_i18n`.

No new client-facing RPC is added (Assumption #4) — `get_level_questions()` is
not exposed as its own callable function in this plan's design.

## Dependencies

- `flutter_tts` (pub.dev, MIT) — new. Version: check pub.dev at implementation
  time (Assumption #10).
- No other new packages. `flutter_animate` (existing), `shared_preferences`
  (existing, if the speaker-preference design changes to need direct prefs
  access rather than going through `SettingsRepository`), `supabase_flutter`
  (existing) cover the rest.

## Testing strategy

Matches CLAUDE.md §11 and this repo's existing conventions
(`test/features/quiz_play/*`, `test/features/catalog/catalog_cubit_test.dart`,
`test/support/pump_app.dart`/`pump_screen.dart`, `mocktail` for API mocks,
`bloc_test` for Cubits, `fake_async` for the play-surface clock):
- Every rewritten/new Cubit behavior (the `QuestionPhase` machine) gets
  `bloc_test` coverage: initial state, the audio-on success path (speaking →
  revealing → answering, clock starts only on `answering`), the audio-off/
  excluded path (unchanged instant-reveal behavior — a regression guard, since
  this is the code path every existing test currently exercises), and the
  mid-speech-toggle-off path.
- `CatalogApi`/`QuizPlayApi` get `mocktail`-mocked-Supabase-client unit tests
  for the new language-filter and extended-response-parsing behavior, per
  CLAUDE.md §11's repository-test requirement.
- Reuse this project's own recorded gotchas (memory `feedback_flutter_test_timing.md`,
  cited in Phase 7) rather than rediscovering them: give any new loading state a
  real animating widget if a widget test needs `pumpAndSettle()` past it, and
  don't let `pumpAndSettle()` run a live periodic ticker to completion when a
  test only wants an immediate effect.

## Edge cases & error handling

- **Pool smaller than N**: handled by the inherited tiling/modulo-indexing logic
  from `0005` (unchanged by this plan) — `is_repeat_padded` flag preserved for
  observability.
- **Pool empty for a (subcategory, tier, language)**: `start_level_attempt`
  raises (inherits `get_level_questions()`'s exception per spec §8) — the
  existing `QuizPlayCubit.startLevel`'s `ApiException` → `QuizPlayFailed` path
  already handles an RPC error from this call (`quiz_play_cubit.dart:112-115`),
  no new client-side error handling needed.
- **TTS voice pack missing / `setLanguage` fails**: fall back to silent mode
  per spec §4.1 — skip to `answering` immediately, don't block the question screen.
- **Toggling audio off mid-speech**: stop TTS, reveal immediately if not
  already revealed, per spec §4.2 point 4 (Design overview, `QuizPlayCubit`).
- **A stale TTS completion callback** firing after the player has already
  skipped/advanced/quit: guarded against (Design overview) — must not resurrect
  a phase transition for a question that's no longer current.
- **Multi-locale legacy content in `question_i18n`** (Assumption #3): migration
  must not run blind past this — explicit pre-check query required first.

## Acceptance criteria

- [ ] All three original migrations (renamed) plus the new RPC-rewrite
      migration apply cleanly, in order, on a fresh Supabase branch/staging
      project (`supabase db reset` or equivalent) — verifying Research finding #1's
      fix.
- [ ] `get_level_questions` selection logic (inlined in `start_level_attempt`)
      returns a full `questions_per_level`-sized set even when a pool has fewer
      live rows than that, and never repeats a question for a user while any
      unseen one remains in the same (subcategory, tier, language) pool.
- [ ] Playing the same level twice as the same user serves different questions
      the second time, until the pool is exhausted, at which point the least-
      recently-seen ones rotate back in (source spec §10.6's smoke test).
- [ ] `submit_level_attempt` grades every answer via `question_id`, never array
      position, and produces the same score/stars/coins/XP shape as before,
      correct now at levels 41-50 (was previously unreachable — `level_attempts`
      capped at 20).
- [ ] Level 50 is playable, is a boss level, and scores at the plain (unfrozen)
      `diffMult` formula (`1 + (level-1)*0.05` = ×3.45) — confirming Research
      findings' note that the spec's "revert the freeze" instruction doesn't
      apply here since no freeze exists in this codebase.
- [ ] A player who switches the app's active language sees an independent
      category/subcategory list and independent level progress for that
      language (spec §5.2), for `en` and `ur`.
- [ ] The countdown-to-question transition: with audio on and a
      non-`ttsExcluded` question, the timer visibly does not start and options
      are not tappable until TTS finishes speaking and the stagger-reveal
      animation completes; with audio off, behavior is pixel-for-pixel what it
      is today (instant reveal, immediate timer start).
- [ ] `dart analyze` reports zero warnings; `dart format` applied to every
      touched file (CLAUDE.md §8).

## Risks & rollout notes

- **Follow the source spec's own §0/§10 rollout order**: staging/branch first,
  never production directly; take a backup before applying to any database with
  real data.
- **Assumption #3's pre-check is a hard gate**, not a suggestion — running the
  fixed migrations against a database with real multi-locale `question_i18n`
  content, without first checking for it, risks silently dropping non-English
  content that only exists as a second `question_i18n` row.
- **Content volume**: per spec §11, the anti-repeat system is only as good as
  how many questions exist per (subcategory, tier, language) — `v_thin_question_pools`
  (now querying `sc.slug`, Research finding #3's fix) is the tool to watch before
  opening any level to real players.
- **Language rollout order**: `hi`/`ar`/`fr`/`es` stay `is_active = false` until
  real content exists for them — flipping the flag early (or wiring the language
  picker to show them, Assumption #8) would show an empty content tree.
- **Assumption #2 (`correct_index` on the client) needs explicit sign-off**
  before implementation proceeds past Phase 1 — it's the one place this plan
  deliberately does not implement something the source spec asked for.
- **Duels are untouched but share `questions`/`question_i18n`/`difficulty`** —
  confirmed no breakage (Scope, above), but the source spec's own §11 recommends
  a short, focused follow-up spec before duels get their own anti-repeat/fairness
  treatment. Not this plan's job.
