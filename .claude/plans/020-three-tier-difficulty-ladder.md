# Three-Tier Difficulty Ladder (Easy / Medium / Hard, 30 levels)

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-09-30).
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Read it in full before starting. It was written against `main` @
`931de8c` and a live-DB snapshot taken 2026-09-30. Code and data may have
moved on, so spot-check the referenced files and line numbers, and re-run the
**Phase 0 pre-flight queries** against the live DB, before changing anything.

## Objective

Collapse every sub-category's level ladder from **5 tiers / 50 levels / 20
questions per level** to **3 tiers / 30 levels** with per-tier question counts
and per-tier timers:

| Tier | Levels | Questions per level | Seconds per question |
|---|---|---|---|
| Easy | 1–10 | 10 | 20 |
| Medium | 11–20 | 15 | 15 |
| Hard | 21–30 | 20 | 10 |

The ladder is already data-driven (`difficulty_tiers` + `app_settings` in
Supabase, fetched once by the app through `LadderConfigRepository`), so most
of the change is a data migration. The Flutter work removes the two
now-dead tiers from the client, makes the client show the per-tier question
count (right now it always shows 20), and fixes a few places that hardcode the
old ladder.

Because level 30 is now the top of every topic, the plan also ends the climb
properly. "Next level" is hidden on level 30, and clearing it for the first
time opens a new **Topic Mastered** congratulations screen (Phase 3b), as the
developer requested on 2026-09-30.

## Scope

**In scope:**
- A new Supabase migration: rewrite the `difficulty_tiers` rows, set
  per-tier question counts, retire `expert`/`master`, re-home the questions
  still on those tiers, tighten the level-range check constraints from 1–50
  to 1–30, and make `start_level_attempt`/`submit_level_attempt` robust to a
  question count that varies by tier.
- Flutter: `DifficultyTier`/`LadderConfigApi`/`LadderConfigRepository`
  (question counts, total levels), `DifficultyBand` (3 values),
  `CatalogApi` (per-level question count, 30 levels), `serpentine_path.dart`
  labels, `MockCatalog`, `Subcategory.levelCount`, hardcoded `levelCount: 20`
  in Profile/Leaderboard, Profile's "fastest level" stat, l10n strings, and tests.
- **End of the ladder (developer decision, 2026-09-30):** the Level Complete
  screen hides "Next level" on level 30, and clearing level 30 opens a new
  full-screen **"Topic Mastered" congratulations screen** (Phase 3b), which
  gets its own small feature (`lib/features/topic_mastery/`), route, Cubit,
  and tests. There's also a small "🏆 Mastered" entry point on a completed
  topic's level map, so the screen can be opened again later.
- The project's `generate-questions` skill (`.claude/skills/generate-questions/`),
  which documents the 5-tier table and must now offer only 3 tiers.

**Out of scope:**
- Writing Medium/Hard question content. The live DB has almost none (see
  Research finding 2). That content gap already exists and this plan does not
  fill it; see Risks.
- Changes to scoring formulas, XP, coins, stars thresholds, boss multiplier,
  or achievements. Open questions 3–4 note where the smaller ladder may call
  for rebalancing later.
- Daily challenge and duels. Each has its own clock and question count
  (`daily_challenges.seconds_per_question`, `duel_config`) and doesn't read
  `difficulty_tiers`.
- The legacy `questions.difficulty` smallint (1–5), which `_daily_rollover`
  recalculates every night from pass rates. It stays 1–5 (see Assumption 4).

## Research findings

### Backend (Supabase)

1. **The ladder is table-driven.**
   `supabase/migrations/20260910090000_difficulty_ladder_v2.sql` created:
   - `difficulty_tiers(id, code unique, label, seconds_per_question, level_start, level_end, sort_order, override_questions_per_level)`.
   - `app_settings(key, value jsonb)`, with `questions_per_level = 20` and `boss_level_interval = 10`.
   - `get_difficulty_for_level(p_level)`, a range lookup.
   - `is_boss_level(p_level)`, which checks `p_level % boss_level_interval = 0`.

   `start_level_attempt` resolves N as
   `coalesce(v_tier.override_questions_per_level, app_settings.questions_per_level, 20)`,
   so a per-tier question count needs **no RPC logic change**. Only the
   `override_questions_per_level` data has to change.

2. **Live DB snapshot (2026-09-30, read-only queries):**
   - `difficulty_tiers` has 5 rows: easy 30s 1–10, medium 25s 11–20, hard 20s 21–30, expert 15s 31–40, master 10s 41–50. Every `override_questions_per_level` is null.
   - Live questions per tier:
     - easy: en 3155, hi 4450, ur 1051
     - medium: en 6
     - hard: en 5
     - expert: en 5
     - master: en 3
   - The 8 expert/master questions are seeded demo rows, all with audio. Their ids start `00000000-0000-4000-8000-0000000f00xx` / `…0a00xx`, and they belong to subcategories `…000101` and `…000201`.
   - `level_progress`: 79 rows, all at level ≤ 10. `level_attempts` has 80 rows with max level 4. `level_attempt_question_sets` has 75 rows, all on the `easy` tier. **No row anywhere is above level 30**, so tightening the constraints is safe today.
   - The level-range check constraints on live are:
     - `level_progress_level_range`: `level between 1 and 50`
     - `level_attempts_level_range`: same range
     - `level_attempt_question_sets_level_check`: same range, auto-named, from the inline `check` in `20260910090200_question_bank_and_anti_repeat.sql`
   - Two foreign keys point at `difficulty_tiers(id)`: `questions_difficulty_tier_id_fkey` and `level_attempt_question_sets_difficulty_tier_id_fkey`. Both are plain, with no `on delete` action, so the expert/master rows can't be deleted until those references are moved.

3. **Latest function bodies** (each `create or replace` supersedes the one before):
   - `start_level_attempt`: `20260917100200_start_level_attempt_audio_url.sql`. It is free-to-start (no heart deduction since `20260917090000`) and returns `attemptId`, `secondsPerQuestion`, `isBoss`, and `questions[]` (each with `audioUrl`).
   - `submit_level_attempt`: `20260919194353_real_achievement_engine.sql` (around line 370 onward). It calls `_evaluate_achievements`.
   - In `submit_level_attempt`, two lines matter here:
     - `v_seconds_total := (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question;`. The timer is re-derived at **submit** time from the *current* tier, not the one the attempt was started under.
     - `v_question_count := jsonb_array_length(p_answers);`. The level's size comes from the **client-sent** answers array. Stars (`_stars_for(correct, total)`) and the flawless check use it. A client could send a short array (e.g. 1 correct answer) and get 3 stars plus the flawless bonus. The gap is older than this plan, but now that N varies by tier the server should own the count: it's `array_length(level_attempt_question_sets.question_ids, 1)`.
   - `_stars_for(p_correct, p_total)` is percentage-based (≥60% / ≥80% / 100%), so it works unchanged at N = 10 or 15.
   - `v_thin_question_pools` (in `20260910090200…`) uses the *global* `questions_per_level × 3` as its "thin" threshold. It should use the per-tier N.
   - `get_level_questions()` (same file) is a reference-only, non-granted function. It already uses `override_questions_per_level` and needs no change.

4. **Achievements that depend on level numbers:**
   - `20260919194353_real_achievement_engine.sql` has `category_three_star_sweep` (`v_level = 20 and v_stars = 3`) and `subcategory_level20_count` (`v_level = 20`).
   - Their seed text is in `supabase/seed.sql:280,284`: "Reach Level 20…". Level 20 still exists (end of Medium), so both keep working. See Open question 3.

5. **Migration-application convention.** Memory records this for plans 007 and 017:
   - Remote migration history uses apply-time versions, not local filenames. **Never run `supabase db push`**: it would re-apply everything.
   - Apply with MCP `apply_migration`, or `supabase db query --linked -f <file>` plus a matching `supabase_migrations.schema_migrations` row.
   - Only apply on the developer's explicit go-ahead.
   - Do a `begin … rollback` dry run first.
   - Latest local migration is `20260928200659_duel_challenge_history_in_lobby_feed.sql`.

### Flutter

6. **`lib/core/ladder/`**
   - `ladder_config_api.dart`:
     - `fetchTiers()` selects `difficulty_tiers` ordered by `sort_order` and maps only `code/label/seconds_per_question/level_start/level_end`. It ignores `override_questions_per_level`.
     - `fetchBossLevelInterval()` reads `app_settings`, so that table is client-readable.
   - `ladder_config_repository.dart` is a plain class, not a Cubit:
     - It has `ensureLoaded()`, `tierFor(level)`, `secondsFor(level)` and `isBoss(level)`.
     - Its `_fallbackTier` is `easy / 30s / 1–50`.
     - `app.dart:91` creates it and `app.dart:151` provides it through `RepositoryProvider.value`.
     - `CatalogApi(supabase, context.read<LadderConfigRepository>())` is the only consumer, at `category_detail_screen.dart:45` and `level_map_screen.dart:58`.

7. **`lib/core/models/difficulty_tier.dart`** is a freezed and json model with no question-count field.

8. **`lib/core/models/level.dart`**
   - `enum DifficultyBand { warmUp, steady, sharp, brutal, master }`.
   - `Level.questionCount` is `@Default(20)` and is **never set** by `CatalogApi._levelFor`, so the level-map node label, the Play button sub-label and the brief sheet always read "20 questions".
   - Those three places:
     - `serpentine_path.dart:122` (`levelMapCurrent(level.questionCount, …)`)
     - `level_map_screen.dart:232-235` (`levelMapPlaySub`)
     - `level_brief_sheet.dart:165`

9. **`lib/core/models/subcategory.dart`**: `@Default(50) int levelCount`.
   - Neither `CatalogApi._subcategoryFromRow` nor `HomeApi._subcategoryFromRow` (`lib/features/home/data/home_api.dart:~318`) sets it, so the default flows through.
   - It drives the Home/search tile's "Lv x/total" and "completed" state (`core/widgets/subcategory_card.dart:59`), the level-map header "x/50" and subtitle (`level_map_screen.dart:378-396`), and `CatalogApi._levelsFor`'s loop bound (`catalog_api.dart:302`).

10. **`lib/features/catalog/data/catalog_api.dart`**
    - `_levelFor` (≈line 307) builds each `Level` from `_ladderConfig.tierFor/secondsFor/isBoss`.
    - `_bandForTierCode` (≈line 330) maps easy→warmUp, medium→steady, hard→sharp, expert→brutal, and anything else →master.
    - `fetchCategory` does **not** call `_ladderConfig.ensureLoaded()`. Only `fetchLevelMap` and `fetchLevel` do.

11. **`lib/features/catalog/presentation/widgets/serpentine_path.dart:327-334`**: `difficultyLabel()` switches over all 5 bands and uses `l10n.difficultyExpert` and `difficultyMaster`.

12. **`lib/core/mock/mock_catalog.dart:390-451`**: `levelsFor`, `bandFor` and `secondsFor` hardcode the 5-tier 30/25/20/15/10 ladder.
    - Tests and mock fixtures use them: `test/features/catalog/catalog_cubit_test.dart:128` expects `hasLength(50)`, and `:233-250` asserts every band, clock and boss list `[10,20,30,40,50]`.
    - `lib/features/profile/data/profile_api.dart:380` also uses `MockCatalog.secondsFor(level)` in production code, to compute the "fastest level" stat from `level_attempts.answers[].secondsLeft`. Once the timers change, attempts played under the old 30s clock would produce negative or incorrect elapsed times.

13. **Hardcoded `levelCount: 20`** (stale even before this plan, since the ladder was 50):
    - `lib/features/profile/data/profile_api.dart:297`
    - `lib/features/leaderboard/data/leaderboard_api.dart:176`

14. **Level Complete "Next level" button.**
    - `lib/features/quiz_result/presentation/screens/level_complete_screen.dart:95-101` always pushes `levelId(run.subcategoryId, run.levelNumber + 1)`.
    - At the top of the ladder that points to a level that doesn't exist, so `start_level_attempt` raises "no difficulty tier configured". This already happens at 50 and would move to 30.
    - `category_leaderboard_screen.dart:216` uses the same pattern (`nextLevel`).

15. **Client timer**
    - `QuizPlayCubit.startLevel` (`quiz_play_cubit.dart:226-234`) takes `secondsPerQuestion` from the server's `start_level_attempt` response through `QuizPlayRepository.secondsPerQuestionFor`.
    - `questionCount` is `_questions.length`.
    - Both are already server-driven, so no quiz-play logic change is needed.

16. **Client scoring**: `lib/features/quiz_play/domain/scoring.dart`.
    - `stars()` and `correctForNextStar()` are percentage-based, so they're fine at any N.
    - Two doc comments are stale: "+1,000 for 20 of 20" and "Levels 5, 10, 15 and 20 pay double".

17. **l10n**
    - `lib/l10n/app_en.arb:310-319` has `difficultyEasy/Medium/Hard/Expert/Master`, with stale "Levels 1–5 / 6–10 / 11–15 / 16–20" descriptions.
    - `app_en.arb:130`: `"onboardingClimbTitle": "Climb 20 levels\nin every topic"`.
    - `app_ur.arb` translates none of these. They fall back to English and are tracked in `untranslated_messages.json`.
    - Generated `app_localizations*.dart` files are committed in `lib/l10n/` (`l10n.yaml`) and are regenerated with `flutter gen-l10n`.

18. **`generate-questions` skill**
    - `.claude/skills/generate-questions/SKILL.md` lines 105-111, 146, 195-197, 224 and 247 list 5 tiers.
    - `reference/schema-and-samples.md:29-37` has the tier table (5 rows) and `:123-138` has the Expert/Master calibration samples.

19. **Governance that applies (`CLAUDE.md`)**
    - §3/§11: a changed repository/Cubit needs `bloc_test` and `mocktail` tests.
    - §5: no raw literals for spacing.
    - §8: `dart format` and `dart analyze` must be clean.
    - §10: add to `core/` files but don't restructure them.
    - §13: never run the app. End with a "To verify" list.
    - Memory (plan 008): stub async failures with `.thenAnswer((_) async => throw e)`, not `.thenThrow`.

20. **Result flow and celebration patterns** (inputs to the Topic Mastered design):
    - `lib/features/quiz_result/presentation/screens/quiz_result_screen.dart` hosts S-21/S-22.
      - It builds `QuizResultCubit(QuizResultRepository(QuizResultApi(supabase), context.read<AuthRepository>()))`.
      - It switches exhaustively over the `sealed` `QuizResultState` (`Loading/Error/Completed/Failed`).
    - `QuizResultRepository.submit` (`lib/features/quiz_result/data/quiz_result_repository.dart`) builds the freezed `LevelResult` (`lib/features/quiz_result/domain/level_result.dart`), which already carries `isFirstClear` and "what next" flags (`shouldOfferSaveProgress`). **That's the right place for an `isFinalLevel`/`unlocksMastery` decision** (CLAUDE.md §1: business decisions below the widget layer).
    - `LevelCompleteScreen._runChain` (`level_complete_screen.dart:48-73`):
      1. Waits 2600 ms for the payout animation.
      2. Runs `celebrateBadges(context, ids)`, which pushes S-23 per badge and awaits each.
      3. Pushes `AppRoutes.saveProgress` if needed.

      The new mastery push slots in as the first step.
    - **Celebration screen precedents**:
      - `features/achievements/presentation/screens/badge_unlocked_screen.dart` (S-23): full-bleed purple 178° gradient, light status bar, eyebrow, 140.w gradient plate with a 70.sp emoji, a `displayMedium` 28.sp white title, `ChunkyButton.gold` Share plus `ChunkyButton.line` dismiss, and `ShareSheet` in an `AppBottomSheet` with mock targets.
      - `features/leaderboard/presentation/screens/league_promotion_screen.dart`: a gold wash.
      - `core/widgets/result_wash.dart`: accent → `s0` at 46%, with the ✕/↗ glyph top bar.
      - Note that S-23 and league promotion **inline hex colors** (`Color(0xFF7B4DFF)` and similar), which violates CLAUDE.md §5. Don't copy that: the new screen adds named tokens.
    - **Motion**:
      - `flutter_animate: ^4.5.2` is already a dependency (`StarsRow` uses `.animate().scale(...)`).
      - `lib/core/theme/app_motion.dart` has `pop` (340 ms, `ElasticOutCurve(0.9)`), `count` (900 ms, `easeOutExpo`), `slide`, and the reduced-motion helpers `AppMotion.durationOf`/`curveOf`/`reduceMotion`.
      - There's **no confetti package, and none should be added**; a small `CustomPainter` is enough.
      - Haptics: `HapticFeedback.mediumImpact()` is already used in `duel_arena_screen.dart:180`.
    - **Tokens**:
      - `lib/core/theme/app_colors.dart` defines the light/dark palettes (e.g. `lightGold 0xFFFFC61A`, `lightG 0xFF7B4DFF`).
      - `context.quizoo` (`quizoo_colors.dart`) exposes `s0…s3, tx…, p, g, ok, info, gold, goldShadow…`.
      - Other theme files: `AppGradients.linear/tile/tileFromHex/washAngle`, `AppSpacing`, `AppRadius` (`card`, `cardAll`, `pillAll`, `emojiPlate`), `AppTypography.glyph(size)`.
    - `lib/core/format/app_format.dart` has `AppFormat.number(value, localeName)` for grouping digits (used in `category_detail_screen.dart:298`).
    - **Routes**:
      - `lib/core/router/app_routes.dart` holds the constants plus `…Path()` builders.
      - `lib/app/router.dart:197-203` registers S-23 as a root-navigator `GoRoute` (`parentNavigatorKey: rootNavigatorKey`).
    - Existing strings to reuse:
      - `resultBackToMap` ("Back to map"), used by `level_failed_screen.dart:57`
      - `commonClose`, `commonSharedMock`, `shareSpoilerFree`
    - `resultBreakdownFlawless` is hardcoded "Flawless — 20 of 20" (`app_en.arb:565`, rendered by `score_breakdown_card.dart:120`). It's wrong for 10- and 15-question levels and must be parameterized.
    - `difficultyLabel(l10n, band)` is a top-level function in `features/catalog/.../serpentine_path.dart:327`, used by 3 catalog files. The mastery screen needs it too, and CLAUDE.md §10 forbids a cross-feature import, so it moves to `core/`.
    - `test/support/pump_screen.dart` provides the app-root repositories (`AuthRepository`, `QuizPlayRepository`, `ContentLanguageRepository`…) but **not** `LadderConfigRepository`. Widget tests that need it must add it there (Phase 6).
    - `level_attempts.created_at` exists (`20260907120000_initial_schema.sql:255`), so "days to master" can be computed.

## Assumptions & open questions

**Assumptions (made; revisit only if wrong):**

1. **Boss levels stay every 10th level** (`boss_level_interval = 10`), which puts them on 10, 20 and 30, the last level of each tier. The spec doesn't mention bosses.
2. **Per-tier question counts go in `difficulty_tiers.override_questions_per_level`** (10/15/20), the column built for this. `app_settings.questions_per_level` stays at 20 as the global fallback, and only its description is updated.
3. **The 8 live expert/master questions are re-homed to `hard`**, not deleted. They're real, audio-backed seed content, and deleting them would cascade into `user_question_history`. Their legacy `difficulty` int is set to 3 to match the tier mapping the `generate-questions` skill documents.
4. **`questions.difficulty` keeps its 1–5 check.** `_daily_rollover` recalculates it nightly from pass rates on a 1–5 scale, so it isn't a tier mirror. Only the `generate-questions` skill's authoring map changes (easy=1, medium=2, hard=3).
5. **`DifficultyBand` keeps its existing value names** (`warmUp/steady/sharp`) and just drops `brutal` and `master`. Renaming to `easy/medium/hard` would churn every call site and test for no behavior change.
6. **Players see the new timers immediately.** The app isn't in production (AdMob test IDs are still in place) and live progress is all at level ≤ 10, so there's no grandfathering. An attempt started under the old tier is graded with the seconds recorded at its start (see Design, step C).
7. **The Topic Mastered screen opens automatically only the *first* time level 30 is cleared** (`LevelResult.isFirstClear`). Replaying level 30 for more stars shows the normal Level Complete screen, without "Next level" and without replaying the whole ceremony each time. The screen can always be reopened from the level map's "🏆 Mastered" pill. Clearing level 30 already means all 30 levels are cleared, because levels unlock in order (`CatalogApi._levelFor`: only `levelsCleared + 1` is `current`). If the developer wants the ceremony on every level-30 clear, change one condition (`isFirstClear &&`) in `QuizResultRepository`.
8. **Guests get the screen too.** A guest's progress lives in `level_progress` under their session like everyone else's. The existing S-24 "save your progress" sheet still follows it in the chain, which is an especially good moment to offer it.
9. **No new reward or backend for mastery.** The screen shows stats already stored in `level_progress`/`level_attempts`. A mastery coin bonus or badge would be an economy change, left for a follow-up (see Risks).

**Open questions (need a human decision; defaults in bold are what this plan implements if nobody objects):**

1. ~~What should "Next level" do after level 30?~~ **Resolved by the developer (2026-09-30):** hide "Next level" on level 30, and show a congratulations screen after level 30. The screen's design was left to the planner and is specified in Phase 3b.
2. **Should the server count questions per level, or trust the client?** Research finding 3 describes the gap. **Default: fix it in this migration**, because variable-N levels make the client-sent count matter more. If the developer wants a pure ladder change, drop Phase 1 step E and keep `jsonb_array_length(p_answers)`.
3. **Achievements tied to level 20.** "Scholar" (reach level 20 in 5 topics) and "Category King" (level 20 with 3 stars in every topic of a category) were written when level 20 was the top of a 20-level ladder. Level 20 is now the end of Medium, not the summit. **Default: leave them unchanged.** Moving them to level 30 would need a `seed.sql` text change, an `_evaluate_achievements` change, and a history backfill: a separate task.
4. **The flawless bonus** (+1000, `Scoring.flawlessBonus` and the server's `submit_level_attempt`) is flat. It's now much easier on a 10-question Easy level than on a 20-question Hard one. **Default: leave it unchanged.** Flag this for the next economy pass.

## Design overview

**Backend**: one migration, `supabase/migrations/20261001090000_three_tier_difficulty_ladder.sql`, wrapped in a transaction.

- **A. Tier rows.** Upsert `easy`, `medium` and `hard` with the new seconds, ranges and `override_questions_per_level` (10/15/20).
- **B. Retire `expert`/`master`.**
  - Move the questions on those tiers to `hard` (and set `difficulty = 3`).
  - Move any `level_attempt_question_sets` rows to `hard`. There are none live; this is defensive.
  - Delete the two tier rows.
- **C. Record the clock per attempt.** Add `level_attempts.seconds_per_question smallint` (nullable):
  - `start_level_attempt` writes it.
  - `submit_level_attempt` grades speed bonus and average answer time with `coalesce(v_attempt.seconds_per_question, <current tier seconds>)`.
  - Profile's "fastest level" stat reads it instead of `MockCatalog.secondsFor`.
  - Backfill existing rows from the **old** ladder (all current rows are levels 1–4, so 30).
- **D. Tighten the three level-range constraints** from 1–50 to 1–30. If any row violates the new range, adding the constraint fails the whole transaction: a built-in guard.
- **E. Server-owned question count.** `submit_level_attempt` takes `v_question_count` from `level_attempt_question_sets.question_ids`, not from `p_answers`.
- **F. `v_thin_question_pools`** uses per-tier N.
- **G. Update `app_settings` descriptions.**

The ladder shape stays **data**: no RPC hardcodes 30 or the per-tier counts. The client never needs another release to change them later. The one exception is the check-constraint bound, which must be edited if the ladder ever grows past 30.

**Flutter**: the app keeps reading the ladder from `difficulty_tiers`.

- `DifficultyTier` gains a resolved `questionsPerLevel`.
- `LadderConfigRepository` gains:
  - `questionsFor(level)`
  - `totalLevels` (the max `levelEnd`)
  - a public `static const fallbackTotalLevels = 30`. It's used both before the ladder loads and by the few display sites that don't have the repository (Home tiles, Profile, Leaderboard).
- `CatalogApi` stamps each `Level` with `questionCount` and each `Subcategory` it builds with `levelCount: totalLevels`.
- `DifficultyBand` shrinks to 3 values, and the exhaustive switches that use it lose two arms.

**End of ladder** (Phase 3 and Phase 3b):

```
level 30 cleared
  └─ QuizResultRepository.submit → LevelResult{ isFinalLevel: true, unlocksMastery: isFirstClear }
       └─ LevelCompleteScreen (S-21): no "Next level"; primary CTA "See your trophy 🏆" when unlocksMastery
            └─ _runChain (after the 2.6 s payout):
                 1. push AppRoutes.topicMasteredPath(categoryId, subcategoryId)   ← NEW, only if unlocksMastery
                 2. celebrateBadges(...)                                           (existing)
                 3. push AppRoutes.saveProgress                                    (existing)

level map (topic fully cleared) ── "🏆 Mastered" pill ──► same route (revisit)
```

- The quiz_result feature never imports `features/topic_mastery`. It only pushes a route constant, which is the same pattern it already uses for S-23 badges (`core/navigation/badge_celebration.dart`).
- The mastery screen fetches its own data through its own Cubit (`TopicMasteryCubit` → `TopicMasteryRepository` → `TopicMasteryApi`), so it works as a deep link or when reopened from the level map, and doesn't depend on `extra`.

## Implementation steps

### Phase 0 — Pre-flight (read-only)

- [ ] Re-run these against the live project (Supabase MCP `execute_sql`, SELECT only) and compare with Research finding 2. **Stop and ask** if any row has a level above 30. The constraint step would abort, and a data decision is needed first (delete those rows, or keep the 50-level range).
  ```sql
  select code, seconds_per_question, level_start, level_end, override_questions_per_level from difficulty_tiers order by sort_order;
  select max(level) from level_progress;
  select max(level) from level_attempts;
  select max(level) from level_attempt_question_sets;
  select dt.code, count(*) from level_attempt_question_sets s join difficulty_tiers dt on dt.id = s.difficulty_tier_id group by 1;
  select dt.code, q.language_code, count(*) from questions q join difficulty_tiers dt on dt.id = q.difficulty_tier_id group by 1,2 order by 1,2;
  select conrelid::regclass, conname, pg_get_constraintdef(oid) from pg_constraint
   where contype = 'c' and connamespace = 'public'::regnamespace and pg_get_constraintdef(oid) ilike '%level%';
  ```
- [ ] Fetch the **live** bodies of both RPCs. Use them as the base for Phase 1, in case something newer than the migration files was applied:
  ```sql
  select pg_get_functiondef('public.start_level_attempt(uuid, smallint, text)'::regprocedure);
  select pg_get_functiondef('public.submit_level_attempt(uuid, jsonb, boolean, text)'::regprocedure);
  ```
  Diff them against `20260917100200_start_level_attempt_audio_url.sql` and `20260919194353_real_achievement_engine.sql`. If they differ, base the rewrite on the live version and note that in the migration header.

### Phase 1 — Supabase migration

Create `supabase/migrations/20261001090000_three_tier_difficulty_ladder.sql`. The header comment should name this plan (`.claude/plans/020-three-tier-difficulty-ladder.md`), in the style of the existing migrations. It has one `begin; … commit;` block with the steps below, in this order:

- [ ] **A. Tier rows.**
  ```sql
  insert into public.difficulty_tiers
    (code, label, seconds_per_question, level_start, level_end, sort_order, override_questions_per_level)
  values
    ('easy',   'Easy',   20,  1, 10, 1, 10),
    ('medium', 'Medium', 15, 11, 20, 2, 15),
    ('hard',   'Hard',   10, 21, 30, 3, 20)
  on conflict (code) do update set
    label = excluded.label,
    seconds_per_question = excluded.seconds_per_question,
    level_start = excluded.level_start,
    level_end = excluded.level_end,
    sort_order = excluded.sort_order,
    override_questions_per_level = excluded.override_questions_per_level;
  ```
- [ ] **B. Retire expert/master.**
  ```sql
  update public.questions q
     set difficulty_tier_id = (select id from public.difficulty_tiers where code = 'hard'),
         difficulty = 3
   where q.difficulty_tier_id in (select id from public.difficulty_tiers where code in ('expert','master'));

  update public.level_attempt_question_sets s
     set difficulty_tier_id = (select id from public.difficulty_tiers where code = 'hard')
   where s.difficulty_tier_id in (select id from public.difficulty_tiers where code in ('expert','master'));

  delete from public.difficulty_tiers where code in ('expert','master');
  ```
  Check whether `questions` has an `updated_at` trigger or an `enforce_question_language_match` trigger (`20260910090100…:302`). Updating the tier doesn't change language, so the trigger should pass.
- [ ] **C. Record the clock per attempt.**
  ```sql
  alter table public.level_attempts add column if not exists seconds_per_question smallint;
  -- Backfill from the ladder the attempt was actually played under (the old
  -- 5-tier one) — every live row today is level 1–10, i.e. 30s.
  update public.level_attempts set seconds_per_question = case
      when level <= 10 then 30 when level <= 20 then 25 when level <= 30 then 20
      when level <= 40 then 15 else 10 end
   where seconds_per_question is null;
  ```
- [ ] **D. Constraints.**
  ```sql
  alter table public.level_progress drop constraint if exists level_progress_level_range;
  alter table public.level_progress add constraint level_progress_level_range check (level between 1 and 30);
  alter table public.level_attempts drop constraint if exists level_attempts_level_range;
  alter table public.level_attempts add constraint level_attempts_level_range check (level between 1 and 30);
  alter table public.level_attempt_question_sets drop constraint if exists level_attempt_question_sets_level_check;
  alter table public.level_attempt_question_sets add constraint level_attempt_question_sets_level_range check (level between 1 and 30);
  ```
  Use the exact constraint names Phase 0 returned.
- [ ] **`start_level_attempt`**: `create or replace` using the Phase 0 live body. Make **one** change: add `seconds_per_question` to the `insert into public.level_attempts (...)` column list with value `v_tier.seconds_per_question`. Everything else stays byte-identical: signature, free-to-start, anti-repeat pool, `audioUrl`/`ttsExcluded` payload, and the `level_attempt_question_sets` insert. Keep `grant execute … to authenticated`.
- [ ] **`submit_level_attempt`**: `create or replace` using the Phase 0 live body, with exactly two changes:
  1. Replace `v_seconds_total := (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question;` with:
     ```sql
     v_seconds_total := coalesce(
       v_attempt.seconds_per_question,
       (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question
     );
     ```
  2. (**E**, Open question 2) Replace `v_question_count := jsonb_array_length(p_answers);` with:
     ```sql
     select coalesce(array_length(s.question_ids, 1), jsonb_array_length(p_answers))
       into v_question_count
       from public.level_attempt_question_sets s where s.id = p_attempt_id;
     v_question_count := coalesce(v_question_count, jsonb_array_length(p_answers));
     ```
     The fallback covers attempts older than the question-set table (no such rows exist live). Everything else stays identical: the `_evaluate_achievements` context, `score_events`, league points and the response shape.

  Keep the grant.
- [ ] **F. `v_thin_question_pools`**: `create or replace view` with the same columns. Compute the threshold per tier as `coalesce(dt.override_questions_per_level, (select (value #>> '{}')::int from app_settings where key = 'questions_per_level'), 20) * 3`, in both `recommended_minimum` and the `having` clause (group by `dt.override_questions_per_level` too). Column names and order must not change: `create or replace view` can't rename or drop columns.
- [ ] **G. Settings copy.**
  ```sql
  update public.app_settings set description =
    'Fallback questions per level attempt when a tier has no override_questions_per_level. Tiers override it: Easy 10 / Medium 15 / Hard 20.'
   where key = 'questions_per_level';
  update public.app_settings set description =
    'Every Nth level is a boss level (double payout). With 10-level tiers this lands boss levels on 10/20/30 -- the last level of every tier.'
   where key = 'boss_level_interval';
  ```
- [ ] **Dry run** (after the developer approves touching the DB): run the whole file inside `begin; … rollback;` through MCP `execute_sql` with the file's own `begin/commit` stripped. Add smoke assertions before the rollback:
  - `select * from difficulty_tiers` returns 3 rows.
  - `get_difficulty_for_level(30)` is `hard`; `get_difficulty_for_level(31)` returns a null row.
  - No questions remain on a deleted tier id.
- [ ] **Apply** only on the developer's explicit go-ahead. Use MCP `apply_migration` with name `three_tier_difficulty_ladder`, or `supabase db query --linked -f` plus a `schema_migrations` row, matching plans 007 and 017. **Never `supabase db push`.**
- [ ] After applying, run `get_advisors` (security and performance) and confirm nothing new appears beyond known INFOs.

### Phase 2 — Flutter core ladder (`lib/core/`)

- [ ] `lib/core/models/difficulty_tier.dart`: add `required int questionsPerLevel` (the resolved value: tier override, else global default). Update the doc comment from "50-level, 5-tier" to "30-level, 3-tier". Regenerate with `dart run build_runner build --delete-conflicting-outputs`, which updates `difficulty_tier.freezed.dart` and `.g.dart`.
- [ ] `lib/core/ladder/ladder_config_api.dart`:
  - `fetchTiers({required int defaultQuestionsPerLevel})` also reads `override_questions_per_level` and maps `questionsPerLevel: (row['override_questions_per_level'] as int?) ?? defaultQuestionsPerLevel`.
  - Add `Future<int> fetchDefaultQuestionsPerLevel()`, mirroring `fetchBossLevelInterval()`: reads `app_settings.questions_per_level` and falls back to 20.

  Alternatively, fetch both `app_settings` keys in one `.inFilter('key', [...])` call. Either way, errors go through `ApiException.fromSupabase`, as they do now.
- [ ] `lib/core/ladder/ladder_config_repository.dart`:
  - `_load()`: fetch the default question count first, then the tiers (passing the default), then the boss interval.
  - Add `int questionsFor(int level) => tierFor(level).questionsPerLevel;`.
  - Add `int get totalLevels => _tiers.isEmpty ? fallbackTotalLevels : _tiers.map((t) => t.levelEnd).reduce(max);`.
  - Add `static const int fallbackTotalLevels = 30;`, with a doc comment saying it mirrors the seeded ladder and is used before load and by display sites without the repository.
  - `_fallbackTier` becomes `DifficultyTier(code: 'easy', label: 'Easy', secondsPerQuestion: 20, levelStart: 1, levelEnd: 30, questionsPerLevel: 10)`.
  - Update the class doc comment.
- [ ] `lib/core/models/level.dart`:
  - `enum DifficultyBand { warmUp, steady, sharp }`, with the doc comment updated to "20s → 15s → 10s per question as the player climbs the 30-level ladder".
  - Change `Level.questionCount`'s default from 20 to 10, matching the first tier, and update the doc comment "One of the twenty levels" → "One of the levels".
  - Fix the `isBoss` comment ("Every fifth level" → "Every tenth level").
  - Regenerate freezed.
- [ ] `lib/core/models/subcategory.dart`: `@Default(LadderConfigRepository.fallbackTotalLevels) int levelCount`. A freezed `@Default` accepts a const expression. Importing `core/ladder` from `core/models` is fine: both are `core/`. If the import creates a cycle (`ladder_config_repository.dart` → `difficulty_tier.dart`, not `subcategory.dart`, so it shouldn't), use the literal `30` with a comment pointing at the constant. Regenerate.
- [ ] `lib/core/mock/mock_catalog.dart`:
  - `bandFor`: `<= 10 → warmUp`, `<= 20 → steady`, `_ → sharp`.
  - `secondsFor`: warmUp 20, steady 15, sharp 10.
  - Add `static int questionsFor(int levelNumber) => switch (bandFor(levelNumber)) { warmUp => 10, steady => 15, sharp => 20 };`.
  - `_level` sets `questionCount: questionsFor(number)`.
  - Update the doc comments at ≈lines 390-396 and 434-445 to the 30-level, 3-tier ladder.
  - Keep `isBoss: number % 10 == 0`.
  - Check that `levelsCleared: 20` (line ≈132) is still ≤ 30. It is.

### Phase 3 — Flutter feature changes

- [ ] `lib/features/catalog/data/catalog_api.dart`:
  - `fetchCategory`: add `await _ladderConfig.ensureLoaded();` at the top of the `try`, so `totalLevels` is real.
  - `_subcategoryFromRow`: make it an instance method, or pass the value in, and set `levelCount: _ladderConfig.totalLevels`.
  - `_levelFor`: add `questionCount: _ladderConfig.questionsFor(number)`.
  - `_bandForTierCode`: `'easy' => warmUp, 'medium' => steady, _ => sharp`, with a comment that an unknown future code renders as the hardest band rather than crashing.
  - Update the `_levelProgressBySubcategory` doc comment ("at most 20 rows per topic" → "at most 30").
- [ ] `lib/features/catalog/domain/level_map.dart`:
  - Fix the doc comments: "its twenty levels" → "its levels"; "Stars earned of the 60 available across twenty levels" → "… `levels.length * 3` …".
  - `_placeholder.secondsPerQuestion`: 30 → 20.
- [ ] **Move `difficultyLabel`** out of `lib/features/catalog/presentation/widgets/serpentine_path.dart:327-334` into a new `lib/core/format/difficulty_label.dart`, with the same signature `String difficultyLabel(AppLocalizations l10n, DifficultyBand band)`. It needs to be in `core/` because `topic_mastery` needs it too. Drop the `brutal` and `master` arms; the switch stays exhaustive over 3 values. Update the three catalog call sites' imports (`serpentine_path.dart`, `level_map_screen.dart:233`, `level_brief_sheet.dart:151`) to `package:quizoo/core/format/difficulty_label.dart`.
- [ ] `lib/features/profile/data/profile_api.dart`:
  - `:297`: `levelCount: LadderConfigRepository.fallbackTotalLevels`.
  - `_fastestLevel` (≈:374-400) and its query at `:178`: add `seconds_per_question` to the `.select(...)` and use `(row['seconds_per_question'] as int?) ?? MockCatalog.secondsFor(level)`.

  Check for other `level_attempts` selects feeding `_fastestLevel`; grep `_fastestLevel(` for its call site and the rows it's given.
- [ ] `lib/features/leaderboard/data/leaderboard_api.dart:176`: `levelCount: LadderConfigRepository.fallbackTotalLevels`.
- [ ] **End of ladder: the decision lives in the domain** (Open question 1, resolved).
  - `lib/features/quiz_result/domain/level_result.dart`: add two documented fields to the freezed class:
    - `@Default(false) bool isFinalLevel`: this run was the ladder's last level (30), so there's no next level.
    - `@Default(false) bool unlocksMastery`: this run just mastered the topic (final level, first clear, completed). Drives the Topic Mastered push.

    Regenerate freezed/json.
  - `lib/features/quiz_result/data/quiz_result_repository.dart`:
    - Inject `LadderConfigRepository` as a third constructor argument (`QuizResultRepository(this._api, this._authRepository, this._ladderConfig)`).
    - In `submit`, compute `final isFinalLevel = run.levelNumber >= _ladderConfig.totalLevels;` and pass `isFinalLevel` and `unlocksMastery: run.isComplete && isFinalLevel && record.isFirstClear`.

    Leave the rest of `submit` unchanged.
  - `lib/features/quiz_result/presentation/screens/quiz_result_screen.dart:41-46`: pass `context.read<LadderConfigRepository>()` into the repository. It's provided at app root in `app/app.dart:151`, and already loaded, because the player reached the level through the level map. `totalLevels` falls back to 30 anyway.
- [ ] **`lib/features/quiz_result/presentation/screens/level_complete_screen.dart`**:
  - **`actions`** (≈line 95-110) becomes a three-way choice:
    - `result.unlocksMastery`:
      1. `ChunkyButton.gold(label: l10n.resultSeeTrophy, onPressed: _openMastery)`. `_openMastery` pushes the mastery route, so the player can open it straight away without waiting for the chain.
      2. If `result.stars < 3`, the existing `ChunkyButton.line(resultReplay)`.
    - `result.isFinalLevel`, not a first clear:
      1. `ChunkyButton(label: l10n.resultBackToMap, onPressed: _close)`
      2. The `resultReplay` line button if `stars < 3`
    - Otherwise: exactly today's "Next level" plus replay.

    **"Next level" is never rendered when `isFinalLevel`.**
  - **`_runChain`**: right after the 2600 ms delay and the `mounted` check, add:
    ```dart
    if (widget.state.result.unlocksMastery) {
      await _openMastery();
      if (!mounted) return;
    }
    ```
    Then comes the existing `celebrateBadges` and S-24 logic. Update the class doc comment ("first S-23 if a badge…") to list the new first step.
  - `Future<void> _openMastery() => context.push(AppRoutes.topicMasteredPath(run.categoryId, run.subcategoryId));`: a route push only, with no import of `features/topic_mastery`, the same way S-23 is reached.
  - Guard double-opening: if the auto-push is in flight and the user taps the button, there's no issue, because the chain awaits the first push and a second push simply stacks. For good measure, keep a `bool _masteryShown` field that `_runChain` checks and `_openMastery` sets, so the chain skips its push if the user already opened it via the button during the payout.
- [ ] **`lib/features/leaderboard/presentation/screens/category_leaderboard_screen.dart:~200-218`**: its "Play {topic} level {nextLevel}" CTA would push level 31 for a mastered topic. Read how `nextLevel` is computed there, clamp it to `LadderConfigRepository.fallbackTotalLevels`, and when the topic is fully cleared, hide the CTA or relabel it to open the level map (`AppRoutes.levelMapPath`). Pick whichever keeps that screen's layout intact.
- [ ] **`lib/features/quiz_result/presentation/widgets/score_breakdown_card.dart:120`**: `ScoreLineKind.flawless => l10n.resultBreakdownFlawless(result.run.questionCount)`. The string becomes parameterized (Phase 4).

### Phase 3b — Topic Mastered congratulations screen (new)

A new feature, `lib/features/topic_mastery/`, shaped per CLAUDE.md §2:

```
features/topic_mastery/
├── data/
│   ├── topic_mastery_api.dart
│   └── topic_mastery_repository.dart
├── domain/
│   ├── topic_mastery.dart            # freezed
│   └── tier_mastery.dart             # freezed
└── presentation/
    ├── screens/topic_mastered_screen.dart
    ├── widgets/
    │   ├── mastery_medallion.dart     # rays + medallion + crown hero
    │   ├── mastery_confetti.dart      # one-shot CustomPainter burst
    │   ├── tier_journey_strip.dart    # EASY ✓ — MEDIUM ✓ — HARD ✓
    │   └── mastery_stats_card.dart    # 2×2 stats grid
    └── bloc/
        ├── topic_mastery_cubit.dart
        └── topic_mastery_state.dart
```

#### Data

- [ ] **`domain/tier_mastery.dart`**: `TierMastery({required DifficultyBand band, required int starsEarned, required int starsAvailable, required int secondsPerQuestion})`.
- [ ] **`domain/topic_mastery.dart`**:
  ```dart
  TopicMastery({
    required String categoryId,
    required String subcategoryId,
    required String topicName,
    required String emoji,
    required String plateColor,        // '#RRGGBB', the topic tile's plate
    required int levelsCleared,
    required int levelCount,           // ladder total (30)
    required int starsEarned,
    required int perfectLevels,        // levels with 3 stars
    required int totalScore,           // Σ level_progress.best_score
    required List<TierMastery> tiers,  // in ladder order
    DateTime? startedAt,               // min(level_attempts.created_at) for this topic
    DateTime? masteredAt,              // level_progress.completed_at of the final level
  })
  ```
  Derived getters:
  - `starsAvailable => levelCount * 3`
  - `missingStars => starsAvailable - starsEarned`
  - `isFlawless => missingStars == 0`
  - `isMastered => levelsCleared >= levelCount`
  - `int? get daysToMaster`: whole days between `startedAt` and `masteredAt`, at least 1. Null if either is missing.
- [ ] **`data/topic_mastery_api.dart`**: `TopicMasteryApi(SupabaseClient client, LadderConfigRepository ladderConfig)`, with `Future<TopicMastery> fetch({required String categoryId, required String subcategoryId, required String locale})`. It mirrors `CatalogApi`'s conventions: row → domain mapping inside the API, errors through `ApiException.fromSupabase`, and `_contentNotFound` → `ApiException(kind: notFound, code: 'ERR_CONTENT_404')`.
  1. `await _ladderConfig.ensureLoaded();`
  2. `subcategories` row by id (`emoji`, `plate_color`, `slug`). Throw not-found if missing.
  3. Topic name from `taxonomy_i18n` (`entity_id = subcategoryId`, `locale`), falling back to the slug. This is the same single-locale lookup `CatalogApi._taxonomyNames` does. Copy the small query rather than importing across features; plan 008 already accepted this duplication.
  4. `level_progress` for `(user_id = auth uid, subcategory_id)`: `level, stars, best_score, completed_at`. Aggregate in Dart:
     - `levelsCleared` counts rows with non-null `completed_at`.
     - `starsEarned` sums `stars`.
     - `perfectLevels` counts rows with `stars == 3`.
     - `totalScore` sums `best_score`.
     - Per tier, group by `_ladderConfig.tierFor(level)`, giving each tier `starsAvailable = (levelEnd - levelStart + 1) * 3`.
     - `masteredAt` is the `completed_at` of level `totalLevels`.
  5. `level_attempts` for the same user and topic: `.select('created_at').order('created_at').limit(1)` gives `startedAt`.
  6. `levelCount: _ladderConfig.totalLevels`. Map each tier code to `DifficultyBand` with the same easy→warmUp, medium→steady, else→sharp mapping. The API can't call `CatalogApi._bandForTierCode` across features, so put a tiny `DifficultyBand bandForTierCode(String code)` in `lib/core/ladder/ladder_config_repository.dart` (or next to `DifficultyBand` in `core/models/level.dart`), and make `CatalogApi._bandForTierCode` delegate to it. That's one mapping, owned by `core/`.

  With no signed-in user id (shouldn't happen: guests have an anonymous session), throw `ApiException(kind: unauthorized…)`, using whichever `ApiErrorKind` the enum offers.
- [ ] **`data/topic_mastery_repository.dart`**: a thin pass-through `Future<TopicMastery> fetch(...)`, matching `CatalogRepository`'s shape.

#### State

- [ ] **`bloc/topic_mastery_state.dart`**: `sealed class TopicMasteryState extends Equatable` with `TopicMasteryLoading`, `TopicMasteryLoaded(TopicMastery mastery)` and `TopicMasteryError(ApiException error)`. Name them for this feature (CLAUDE.md §3).
- [ ] **`bloc/topic_mastery_cubit.dart`**: pure Dart, with the repository injected. `load({categoryId, subcategoryId, locale})` emits Loading, then Loaded or Error, and checks `isClosed` after every await. **If the fetched mastery `!isMastered`** (someone deep-linked early), emit `TopicMasteryError` with a not-found-kind `ApiException`, so the screen never congratulates an unfinished topic.

#### Route

- [ ] `lib/core/router/app_routes.dart`: add, near the other progression routes:
  ```dart
  /// Topic Mastered — the congratulations screen after a topic's final level (plan 020).
  static const String topicMastered =
      '/category/:categoryId/subcategory/:subcategoryId/mastered';
  static String topicMasteredPath(String categoryId, String subcategoryId) =>
      '/category/$categoryId/subcategory/$subcategoryId/mastered';
  ```
  The class doc says all bible screens were "reserved up front". This is a new, non-bible screen, so adding one constant is an **addition** (CLAUDE.md §10), not a restructure. If there's a count comment ("All 54 screen IDs") or an `sNN` alias list, don't invent an S-number; leave the alias list untouched.
- [ ] `lib/app/router.dart`: register it with the S-23 badge route pattern (`:197-203`):
  ```dart
  GoRoute(
    path: AppRoutes.topicMastered,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => TopicMasteredScreen(
      categoryId: state.pathParameters['categoryId']!,
      subcategoryId: state.pathParameters['subcategoryId']!,
    ),
  ),
  ```
  Use a fade-plus-scale page transition if the router already has a helper for custom pages, like `_sheetPage`. Otherwise the default builder is fine.

#### Visual design — "Topic Mastered"

The screen should feel like the summit of a climb, the biggest celebration in the app, bigger than S-21's level payout and S-23's badge. It shares the S-23/S-21 visual language (full-bleed 178° wash, white type, chunky buttons, emoji hero) so it reads as part of the same family. It looks the same in light and dark mode, like the other full-bleed celebration surfaces.

**Wireframe (portrait, 375×812 design size):**

```
┌───────────────────────────────────────┐
│ ✕                                  ↗  │  top bar: close / share glyphs (same as ResultWash)
│                                       │
│          ✦ TOPIC MASTERED ✦           │  eyebrow, gold, letter-spaced
│                                       │
│        ╲   ╲  │  ╱   ╱                │  slow-rotating gold sunburst rays behind the hero
│          ╭──── 👑 ────╮               │  crown drops onto the medallion
│        ─ │  ╭──────╮  │ ─             │
│          │  │  ⚽  │  │               │  gold ring (gold→goldShadow) around the topic's
│        ─ │  ╰──────╯  │ ─             │  own plate-color disc with its emoji
│          ╰────────────╯               │
│         ╱   ╱  │  ╲   ╲               │
│         ┌──────────────────┐          │
│         │   30 / 30 LEVELS │          │  gold ribbon pill under the medallion
│         └──────────────────┘          │
│                                       │
│          Football Mastered!           │  displayMedium, white
│   You conquered every level — Easy,   │  bodyMedium, white 88%
│        Medium and Hard. Legend.       │
│                                       │
│  ( EASY ✓ )──( MEDIUM ✓ )──( HARD ✓ ) │  tier journey strip
│   ⭐ 28/30     ⭐ 26/30      ⭐ 24/30  │  stars per tier under each pill
│                                       │
│ ┌───────────────────────────────────┐ │
│ │  ⭐ 78 / 90        🏅 21          │ │  stats card: frosted white 12% on the wash,
│ │  STARS             PERFECT LEVELS │ │  2×2 grid, values count up
│ │                                   │ │
│ │  🎯 184,320        📅 12          │ │
│ │  TOTAL SCORE       DAYS TO MASTER │ │
│ └───────────────────────────────────┘ │
│                                       │
│  12 stars still up for grabs —        │  nudge line (or the flawless line if 90/90)
│  replay any level to perfect it.      │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │           Continue              │  │  ChunkyButton.gold (primary)
│  └─────────────────────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │         Share my trophy         │  │  ChunkyButton.line
│  └─────────────────────────────────┘  │
└───────────────────────────────────────┘
```

**Colors.** New named tokens, per CLAUDE.md §5: never inline hex.
- [ ] Add to `lib/core/theme/app_colors.dart`, beside the existing palette, with a doc comment "Topic Mastered wash — identical in both themes, like the other full-bleed celebration surfaces":
  - `masteryWashTop = Color(0xFF3A1C9E)`: deep royal violet, one step darker than `lightG`.
  - `masteryWashBottom = Color(0xFF120D25)`: the same value as `darkS0`, so the wash sinks into the night.
  - `masteryRay = Color(0xFFFFC61A)`: the gold, drawn at low alpha.
  - `masteryConfetti = [lightGold, lightOk, lightInfo, lightP, lightBad, Color(0xFFFFFFFF)]` (a `static const List<Color>`).

  Because the screen is theme-invariant, there's no dark-mode twin to add (§5's sync rule is about themed components). Say so in the doc comment.
- [ ] Gold elements (eyebrow, ring, ribbon, tier checkmarks) use `context.quizoo.gold`/`goldShadow`. Body text is `Colors.white` at 100% or 88% alpha, as on S-23.

**Layout and components** (all sizes via screenutil; spacing from `AppSpacing`, radii from `AppRadius`):
1. **Scaffold**, with an `AnnotatedRegion` for a light status bar (copy S-23's). Body: `DecoratedBox` with `AppGradients.linear(AppGradients.washAngle, [AppColors.masteryWashTop, AppColors.masteryWashBottom])`. Put a `Stack` inside a `SafeArea`: layer 0 is `MasteryConfetti` (IgnorePointer, full-screen); layer 1 is the content `Column`.
2. **Top bar**: ✕ (close) on the left and ↗ (share) on the right, using the same 38.w glyph-button look as `ResultWash._WashGlyphButton`. That widget is private to `core/widgets/result_wash.dart`. Don't make it public just for this; either copy it as a private `_GlyphButton` in the screen file, or, if the reviewer prefers, promote it to `core/widgets/wash_glyph_button.dart` and use it from both.
3. **Scrollable body** (`SingleChildScrollView`, horizontal padding `AppSpacing.xl.w`), so small phones and large text scales never overflow:
   - **Eyebrow** `l10n.masteryEyebrow` ("✦ TOPIC MASTERED ✦"): `textTheme.labelSmall`, gold, `letterSpacing: 2`.
   - **`MasteryMedallion`**: a 220.w square hero area.
     - **Rays**: a `CustomPainter` drawing 16 wedge rays from the center with a radial fade. Color `AppColors.masteryRay` at 0.16 alpha. It rotates slowly (one turn per 24 s, `RotationTransition`), repeating. Under reduced motion it's static.
     - **Ring**: a 150.w circle with a `LinearGradient` gold→goldShadow and a soft gold glow `BoxShadow` (blur 40, alpha 0.45).
     - **Disc**: inset by 10.w, filled with `AppGradients.tileFromHex(plateColor, plateColor)` darkened slightly at the bottom, holding the topic emoji at `AppTypography.glyph(64.sp)`.
     - **Crown**: 👑 at `glyph(44.sp)`, positioned over the ring's top edge and rotated −12°.
     - **Ribbon pill** (overlapping the ring's bottom edge by 12.h): gold fill, `AppRadius.pillAll`, text `l10n.masteryLevelsRibbon(levelsCleared, levelCount)` ("30 / 30 LEVELS") in `labelSmall` w800, color `AppColors.lightTx` (dark ink on gold, matching the `ChunkyButton.gold` label ink). If a gold-ink token already exists for `ChunkyButton.gold`, reuse it.
   - **Title** `l10n.masteryTitle(topicName)` ("{topic} Mastered!"): `textTheme.displayMedium`, 28.sp, white, centered, `maxLines: 2`.
   - **Subtitle** `l10n.masterySubtitle` ("You conquered every level — Easy, Medium and Hard."): `bodyMedium`, 13.5.sp, white 88%, line height 1.5.
   - **`TierJourneyStrip`**: a `Row` of 3 tier pills joined by 2 short gold connector lines.
     - Each pill is a white-12% frosted chip with a gold ✓ and `difficultyLabel(l10n, band).toUpperCase()`.
     - Under each pill, `⭐ {earned}/{available}` in `labelSmall` white 85%.
     - Tiers render from `mastery.tiers`, so a future ladder change needs no code change.
     - In RTL (Urdu), the `Row` mirrors automatically: journey order follows reading direction, which is correct.
   - **`MasteryStatsCard`**: `Container` with `color: Colors.white.withValues(alpha: 0.10)`, a 1px border at white 16%, `AppRadius.cardAll`, and padding `AppSpacing.base`. It holds a 2×2 grid (two `Row`s of `Expanded` cells). Each cell is an emoji at `glyph(20.sp)`, a value in `titleLarge` white w800, and a caption in `labelSmall` white 70% with `letterSpacing: 1`. The cells are:
     - ⭐ `"{starsEarned} / {starsAvailable}"`, caption `masteryStatStars`
     - 🏅 `perfectLevels`, caption `masteryStatPerfect`
     - 🎯 `AppFormat.number(totalScore, localeName)`, caption `masteryStatScore`
     - 📅 `daysToMaster`, caption `masteryStatDays`; when null, show 🔥 `levelsCleared` with caption `masteryStatLevels` instead, so the grid never shows a blank cell
   - **Nudge line**, centered `labelSmall` white 85%:
     - `mastery.isFlawless` → `l10n.masteryFlawless` ("Every single star collected. Flawless mastery 💎")
     - otherwise → `l10n.masteryMissingStars(missingStars)` ("{count} stars still up for grabs — replay any level to perfect this topic."), ICU plural
4. **Pinned actions** (same padding as `ResultWash`'s action area):
   - `ChunkyButton.gold(label: l10n.masteryContinue, onPressed: _continue)`, where `_continue` does `context.canPop() ? context.pop() : context.go(AppRoutes.levelMapPath(categoryId, subcategoryId))`, which is S-23's dismiss pattern.
   - `SizedBox(height: 9.h)`.
   - `ChunkyButton.line(label: l10n.masteryShare, onPressed: _share)`, where `_share` opens `AppBottomSheet.show` with a `ShareSheet` exactly as `badge_unlocked_screen.dart:_share` does (mock WhatsApp/X/Copy targets → `commonSharedMock` snackbar), plus a small preview card: topic emoji plate + "{topic} Mastered · ⭐ x/90".

**Motion choreography** (all through `flutter_animate`, durations through `AppMotion.durationOf`, curves through `AppMotion.curveOf`):

| t (ms) | What happens |
|---|---|
| 0 | Wash is visible. Rays fade in (0→1 over 600 ms) and start rotating |
| 120 | Medallion scales 0.3→1 with `AppMotion.pop` / `popCurve` (elastic). On landing (≈460 ms), `HapticFeedback.mediumImpact()` fires once and the confetti burst starts |
| 460 | Confetti: 70 particles in `masteryConfetti` colors, launched upward in a 120° fan from just above the medallion, then falling with gravity and fading. It lasts 2.4 s, runs **once** and doesn't loop. Particles are small rotated rects and circles (4–8.w), driven by a single `AnimationController` and seeded `Random`, with no per-particle widgets |
| 520 | Crown drops from −40.h with a slight overshoot (`slideY` + `fadeIn`, 340 ms, `Curves.easeOutBack`) |
| 700 | Ribbon pill: `scaleX` 0→1 (260 ms) |
| 820 | Title: `fadeIn` + `slideY(begin: 0.3)` (`AppMotion.slide`) |
| 920 | Subtitle: same, +100 ms |
| 1050 | Tier pills pop in with a 120 ms stagger, each ✓ doing a small scale pop; connector lines grow (`scaleX`) between them |
| 1450 | Stats card: `fadeIn` + `slideY(0.15)`; the four values count up from 0 over `AppMotion.count` / `countCurve` (`TweenAnimationBuilder<int>`) |
| 1900 | Nudge line fades in; buttons fade in (they're tappable from the start: fading is decorative) |

**Reduced motion** (`AppMotion.reduceMotion(context)`): no confetti, no ray rotation, no count-up (show final values), and every entrance shows instantly. The haptic still fires once, since it's feedback, not motion. This matches the bible's reduce-motion rule noted in `app_motion.dart`.

**Other states**:
- `TopicMasteryLoading`: the wash plus a white `CircularProgressIndicator`, as on S-23.
- `TopicMasteryError`: the wash plus the S-23 error pattern (`contentErrorTitle` + `ChunkyButton.ghost(commonClose)` → `_continue`).

**Accessibility**:
- Wrap the medallion in `Semantics(label: l10n.masteryTitle(topicName), image: true)`.
- Each stat cell is a single merged `Semantics` node ("78 of 90 stars").
- Confetti and rays are `ExcludeSemantics`.
- Text scales with the system: the body scrolls, and nothing is fixed-height except the medallion.

**Code-shape rules**:
- Every widget above is its own public class in its own file (CLAUDE.md §7), with `const` constructors where possible.
- The screen's `build()` stays composition: `BlocProvider` + `BlocBuilder` + an exhaustive `switch` over the sealed state, with no `default` branch.
- `setState` isn't used at all: animations are `flutter_animate` or `AnimationController`s owned by the widgets that need them.

#### Level map entry point (revisit)

- [ ] `lib/features/catalog/presentation/screens/level_map_screen.dart`, header block (≈lines 370-400, the progress bar and "x/30" row): when `subcategory.levelsCleared >= subcategory.levelCount`, render a small gold pill "🏆 Mastered" (`l10n.levelMapMastered`) to the right of the "x/30" text. The pill is tappable and does `context.push(AppRoutes.topicMasteredPath(category.id, subcategory.id))`. Keep it small (`labelSmall`, gold background at 18%, gold text, `AppRadius.pillAll`) so it doesn't crowd the header. If it's used only here, make it a private `_MasteredPill` in that file, or a widget under `features/catalog/presentation/widgets/`.
- [ ] `lib/features/quiz_play/domain/scoring.dart`: comment-only fixes. "+1,000 for 20 of 20" → "+1,000 for a flawless level". "Levels 5, 10, 15 and 20 pay double" → "Boss levels (every tenth) pay double". "L1 = 1.00 … L20 = 1.95" → "L1 = 1.00 … L30 = 2.45".

### Phase 4 — l10n

- [ ] `lib/l10n/app_en.arb`:
  - Delete `difficultyExpert`, `@difficultyExpert`, `difficultyMaster` and `@difficultyMaster`.
  - Fix the descriptions of `difficultyEasy` ("Levels 1–10 difficulty tier."), `difficultyMedium` ("Levels 11–20 …") and `difficultyHard` ("Levels 21–30 …").
  - `onboardingClimbTitle` → `"Climb 30 levels\nin every topic"`.
  - `resultBreakdownFlawless` → `"Flawless — {count} of {count}"`, with a `placeholders.count` int.
  - **New keys** (each with an `@key` description naming "Topic Mastered (plan 020)" or S-21):

    | Key | English |
    |---|---|
    | `resultSeeTrophy` | `"See your trophy 🏆"` |
    | `masteryEyebrow` | `"✦ TOPIC MASTERED ✦"` |
    | `masteryTitle` | `"{topic} Mastered!"` |
    | `masterySubtitle` | `"You conquered every level — Easy, Medium and Hard."` |
    | `masteryLevelsRibbon` | `"{cleared} / {total} LEVELS"` |
    | `masteryStatStars` | `"STARS"` |
    | `masteryStatPerfect` | `"PERFECT LEVELS"` |
    | `masteryStatScore` | `"TOTAL SCORE"` |
    | `masteryStatDays` | `"{count, plural, =1{DAY TO MASTER} other{DAYS TO MASTER}}"` |
    | `masteryStatLevels` | `"LEVELS CLEARED"` |
    | `masteryMissingStars` | `"{count, plural, =1{1 star still up for grabs — replay a level to perfect this topic.} other{{count} stars still up for grabs — replay any level to perfect this topic.}}"` |
    | `masteryFlawless` | `"Every single star collected. Flawless mastery 💎"` |
    | `masteryContinue` | `"Continue"` |
    | `masteryShare` | `"Share my trophy"` |
    | `masteryShareTitle` | `"Share your mastery"` |
    | `levelMapMastered` | `"🏆 Mastered"` |

    `masterySubtitle` names the three tiers in copy. That's acceptable, because the tier strip right below it is data-driven, and the copy only needs to change if the ladder gains a tier.
  - Urdu (`app_ur.arb`): Urdu is a proof-of-concept subset (`l10n.yaml`), so the new keys may stay untranslated and be tracked in `untranslated_messages.json`. If the implementer is confident, adding Urdu for the mastery title/subtitle/continue is a nice touch but not required.
- [ ] `lib/l10n/app_ur.arb`: remove the Expert/Master keys if present. They aren't today; confirm with grep.
- [ ] Run `flutter gen-l10n` to regenerate `app_localizations*.dart` and `untranslated_messages.json`, then grep `lib/` and `test/` for any remaining `difficultyExpert` or `difficultyMaster`.

### Phase 5 — `generate-questions` skill

- [ ] `.claude/skills/generate-questions/reference/schema-and-samples.md`:
  - Retitle the tier table "(3 fixed rows) — the Easy/Medium/Hard mapping".
  - Rows: easy 20s L1–10, 10 q/level, int 1; medium 15s L11–20, 15 q/level, int 2; hard 10s L21–30, 20 q/level, int 3. Add a "questions/level" column.
  - Delete the Expert and Master calibration sections (≈lines 123-138).
  - Widen Hard's description so it covers the most demanding content: "dedicated-enthusiast recall … up to niche/technical facts". It's now the top tier.
- [ ] `.claude/skills/generate-questions/SKILL.md`:
  - Step 3 (≈105-111): "choose one of the 3 tiers: Easy, Medium, Hard".
  - ≈195-197: replace the "Master question should be genuinely obscure" example with Hard.
  - ≈224: `(easy/medium/hard)`.
  - Update the skill description if it mentions 5 tiers.
  - Suggest a "minimum useful batch" in Step 3: 3× that tier's questions/level, matching `v_thin_question_pools`.

### Phase 6 — Tests

- [ ] `test/features/catalog/catalog_cubit_test.dart`:
  - `:128`: `hasLength(30)`.
  - `:233-250`: rewrite as "follows the 30-level, 3-tier ladder". Assert:
    - levels[0] is warmUp / 20s / 10 questions
    - levels[15] is steady / 15s / 15 questions
    - levels[25] is sharp / 10s / 20 questions
    - bosses are `[10, 20, 30]`
    - there's still exactly one current node
- [ ] **New** `test/core/ladder/ladder_config_repository_test.dart` (`mocktail`-mocked `LadderConfigApi`). Cover:
  - `tierFor`, `secondsFor`, `questionsFor` and `totalLevels` after a successful load of the three seeded tiers.
  - The fallbacks before load (`totalLevels == 30`, 20s, 10 questions).
  - A failed load rethrows, and a second `ensureLoaded()` retries. Stub the failure with `.thenAnswer((_) async => throw …)`, not `.thenThrow` (plan 008 memory).
- [ ] **New or extended** test for `DifficultyTier` resolution: an override present beats the default, and a null override takes the default. Put it in the repository test above if `fetchTiers` isn't unit-testable without a Supabase client, which matches `CatalogApi`'s testing approach.
- [ ] `test/core/widgets/core_widgets_test.dart:338,374`: update the `levelCount = 50` fixtures to 30 wherever the assertion depends on the total ("Lv x/50" text). Leave them if the test only checks a relative state.
- [ ] `test/features/catalog/level_brief_sheet_test.dart`: add or adjust an assertion that the sheet shows the level's own `questionCount` (e.g. a Medium level shows 15).
- [ ] **`test/support/pump_screen.dart`**: add `RepositoryProvider<LadderConfigRepository>` to its `MultiRepositoryProvider` (≈line 79), backed by a `LadderConfigRepository` over a fake/mocktail `LadderConfigApi` that returns the three seeded tiers. Expose an optional override param, following the `contentLanguage` override pattern from plan 008.
- [ ] **`QuizResultRepository`** (`test/features/quiz_result/`): extend the existing tests, or add `quiz_result_repository_test.dart` with mocktail `QuizResultApi`/`AuthRepository`/`LadderConfigRepository`. Cover:
  - A level 5 completion gives `isFinalLevel == false` and `unlocksMastery == false`.
  - A level 30 first clear gives `isFinalLevel` and `unlocksMastery` both true.
  - A level 30 replay (`isFirstClear: false`) gives `isFinalLevel == true` and `unlocksMastery == false`.
  - Level 30 not completed (out of hearts) gives `unlocksMastery == false`.
  - Update `QuizResultRepository(...)` constructor calls in `quiz_result_cubit_test.dart` and `result_screen_test.dart`.
- [ ] **Level Complete widget tests** (`test/features/quiz_result/result_screen_test.dart`, or a new `level_complete_screen_test.dart`). Test these branches:
  1. Level 5 shows "Next level →".
  2. Level 30 with `unlocksMastery` shows "See your trophy 🏆" and **no** "Next level".
  3. A level 30 replay shows "Back to map" and no "Next level".
  4. After the 2.6 s payout on a level 30 first clear, the router received a push to `AppRoutes.topicMasteredPath(...)` before any badge route. Use a `MockGoRouter`/`InheritedGoRouter` or whatever that test file already uses for route assertions. Mind the memory note on `pumpAndSettle` vs timers: advance with `tester.pump(const Duration(milliseconds: 2600))`, not `pumpAndSettle`.
- [ ] **`TopicMasteryCubit`**: new `test/features/topic_mastery/topic_mastery_cubit_test.dart` (`bloc_test` + mocktail repository). Cover:
  - The initial state.
  - Success: `[Loading, Loaded]`.
  - Failure: the repository throws `ApiException` (stubbed with `.thenAnswer((_) async => throw …)`), giving `[Loading, Error]`.
  - Not mastered: a `TopicMastery` with `levelsCleared: 29` gives `[Loading, Error]`.
- [ ] **`TopicMastery` domain**: a unit test for `starsAvailable`, `missingStars`, `isFlawless`, `isMastered`, and `daysToMaster` (null handling, same-day → 1).
- [ ] **`TopicMasteryApi`/`Repository`**: CLAUDE.md §11 asks for a mocktail-mocked-API repository test. Add `topic_mastery_repository_test.dart` covering success pass-through and `ApiException` propagation. The API's Dart-side aggregation (per-tier grouping, perfect-level count, score sum, `masteredAt`) should be a **pure static helper** (e.g. `static TopicMastery aggregate({required rows, required tiers, …})`), like `CatalogApi.resumeTopic`, and unit-tested directly without a Supabase client.
- [ ] **`TopicMasteredScreen` widget tests** (`test/features/topic_mastery/topic_mastered_screen_test.dart`), one per state branch (CLAUDE.md §11). Pump with `MediaQuery(disableAnimations: true)` so confetti, rays and the count-up are skipped and the test settles:
  - **Loading** shows a spinner.
  - **Error** shows `contentErrorTitle` and a close button.
  - **Loaded, not flawless** shows the title "Football Mastered!", "30 / 30 LEVELS", three tier labels (EASY/MEDIUM/HARD), "78 / 90", and the missing-stars nudge; tapping "Continue" pops.
  - **Loaded, flawless** shows the flawless line instead of the nudge.
  - **Loaded, `startedAt` null** shows the "LEVELS CLEARED" cell instead of "DAYS TO MASTER".
- [ ] **Level map**: in the catalog widget/cubit tests, or a new small widget test, check that a fully-cleared `LevelMap` renders the "🏆 Mastered" pill and a partially-cleared one doesn't.
- [ ] **`difficultyLabel` move**: update any test import of `serpentine_path.dart` that used `difficultyLabel`.
- [ ] Grep `test/` for `DifficultyBand.brutal`, `DifficultyBand.master`, `secondsPerQuestion: 30`, `secondsPerQuestion: 25` and `hasLength(50)`, and fix every hit.
- [ ] Run `dart format .`, `dart analyze` (zero warnings) and the full `flutter test` suite. The last recorded baseline is roughly 578 passing and 14 pre-existing skips; the only failures allowed are the ones this plan intentionally changes, and those must be fixed.

## Data model / API changes

| Object | Change |
|---|---|
| `difficulty_tiers` rows | easy 20s/1–10/10q; medium 15s/11–20/15q; hard 10s/21–30/20q; `expert` and `master` **deleted** |
| `questions` | 8 rows re-homed from expert/master to `hard` (`difficulty = 3`) |
| `level_attempts` | **new column** `seconds_per_question smallint null`, backfilled |
| `level_progress`, `level_attempts`, `level_attempt_question_sets` | level check narrowed from `1..50` to `1..30` |
| `start_level_attempt(uuid, smallint, text)` | signature and response unchanged; also writes `level_attempts.seconds_per_question` |
| `submit_level_attempt(uuid, jsonb, boolean, text)` | signature and response unchanged; clock taken from the attempt; question count taken from the served set |
| `v_thin_question_pools` | threshold becomes per-tier |
| `app_settings` | descriptions only (`questions_per_level` stays 20 as fallback) |
| `start_level_attempt` response | same keys. `secondsPerQuestion` is now 20/15/10 and `questions[]` has length 10/15/20 |
| Flutter `DifficultyTier` | + `questionsPerLevel` |
| Flutter `DifficultyBand` | − `brutal`, − `master` |
| Flutter `Subcategory.levelCount` default | 50 → 30 |
| Flutter `LevelResult` | + `isFinalLevel`, + `unlocksMastery` |
| Flutter route | + `AppRoutes.topicMastered` = `/category/:categoryId/subcategory/:subcategoryId/mastered` |
| Flutter new feature | `features/topic_mastery/` (`TopicMastery`, `TierMastery`, API/repository/Cubit/screen) |
| Topic Mastered data sources | read-only `subcategories`, `taxonomy_i18n`, `level_progress`, `level_attempts.created_at`. **No new backend** for the screen |

## Dependencies

N/A: no new packages. `build_runner` (freezed/json) and `flutter gen-l10n` are already set up.

## Testing strategy

- **Unit and `bloc_test`** (per CLAUDE.md §11):
  - The new `LadderConfigRepository` test with a mocktail API.
  - The updated `catalog_cubit_test` ladder assertions.
  - The existing `quiz_play_cubit_test` and `quiz_result_cubit_test` should pass unchanged, because they read the server's `secondsPerQuestion` and `_questions.length`. If a fixture there hardcodes 30s or 20 questions only as sample data, leave it.
- **Widget tests**: the level brief sheet question count, and the Level Complete last-level branch.
- **SQL**: the Phase 1 `begin … rollback` dry run with smoke assertions, plus an optional **authenticated** smoke test in the same rolled-back transaction:
  - `set local role authenticated; set local request.jwt.claims = '{"sub":"<a dev profile id>"}';`
  - `select start_level_attempt('<subcategory with easy en questions>', 1::smallint, 'en')`: expect 10 questions and `secondsPerQuestion` 20.
  - Level 11: expect 15 questions (padded from the 6 medium questions if that subcategory owns them) and 15s.
  - `submit_level_attempt` with 1 answer: expect `stars = 0` and not flawless (Phase 1 step E).
- **Static**: `dart format`, `dart analyze` zero warnings, full `flutter test`. Never run the app (CLAUDE.md §13).

## Edge cases & error handling

- **Rows above level 30**: none live. If Phase 0 finds any, the constraint step aborts the transaction by design. Stop and ask.
- **An attempt in flight across the migration** (started at old 30s, submitted after): it's graded with the backfilled or recorded `seconds_per_question`, not the new tier's value, so no speed-bonus distortion.
- **A thin Medium/Hard pool** (most topics have 0): `start_level_attempt` raises `no live questions for subcategory …`. This already happens today for levels 11+, and the quiz screen maps it to an `ApiException` failure state. A pool smaller than N is padded by tiling (`is_repeat_padded = true`). Both behaviors stay as they are.
- **Ladder not loaded yet** (`fetchCategory` before `ensureLoaded` resolves): now awaited. The `fallbackTotalLevels`/`_fallbackTier` defaults are consistent (30 levels, Easy 20s/10q), so nothing renders 50 even briefly.
- **An unknown tier code** added to the DB later: `_bandForTierCode` renders it as `sharp` and `DifficultyBand` stays exhaustive. Adding a real 4th tier would need a client change, as it does today.
- **The Level Complete screen at level 30**: no "Next level" push to a nonexistent level 31. The first clear gets "See your trophy 🏆"; a replay gets "Back to map".
- **The player closes S-21 (✕) during the 2.6 s payout on a level-30 first clear**: the chain's `mounted` check stops the auto-push, so they miss the ceremony. The level map's "🏆 Mastered" pill lets them open it at any time. This is accepted, not a bug.
- **Topic Mastered opened for an unfinished topic** (deep link, or stale navigation): the Cubit emits an error state and the screen shows the close-only error view. It never congratulates early.
- **`level_attempts` has no row for the topic** (e.g. progress written some other way), so `startedAt` is null: the stats grid swaps "Days to master" for "Levels cleared".
- **A long topic name** (Urdu, or a long English name like "Famous Paintings & Painters"): the title wraps to 2 lines with `maxLines: 2` and ellipsis. The medallion and body scroll, so nothing overflows at a large text scale.
- **The ladder is extended later** (e.g. to 40 levels): `isFinalLevel`, `levelCount`, the ribbon and the tier strip all read `LadderConfigRepository`/`TopicMastery.tiers`, so the screen adapts. Only `masterySubtitle`'s copy names the tiers.
- **Reduced motion**: no confetti, rays or count-up; everything else renders instantly; one haptic.
- **Achievement "avg answer seconds" (Quick Draw/Rocket)**: computed from `v_seconds_total - secondsLeft`. Using the per-attempt seconds keeps it correct across the timer change.
- **An old app build** (if any exists): it reads `difficulty_tiers` live, so it shows 30 levels and 3 bands. Its `_bandForTierCode` still maps easy/medium/hard. It would label every level "20 questions" (the bug fixed here) but still play correctly.

## Acceptance criteria

- [ ] `difficulty_tiers` on live has exactly 3 rows: easy (20s, levels 1–10, 10 questions), medium (15s, 11–20, 15), hard (10s, 21–30, 20).
- [ ] `start_level_attempt` serves 10 / 15 / 20 questions at levels in Easy / Medium / Hard (given a non-empty pool), with `secondsPerQuestion` 20 / 15 / 10.
- [ ] `start_level_attempt` for level 31 fails, and inserting `level_progress` with level 31 violates `level_progress_level_range`.
- [ ] No `questions` or `level_attempt_question_sets` row references a deleted tier. The 8 former expert/master questions are `hard`.
- [ ] `submit_level_attempt` derives stars and flawless from the served question count, not from the length of the client's answers array (unless Open question 2 is declined).
- [ ] The level map shows 30 nodes in three bands labelled EASY · 20s, MEDIUM · 15s and HARD · 10s, with bosses on 10, 20 and 30.
- [ ] The level map's current-node label, Play-button sub-label and brief sheet show 10 / 15 / 20 questions according to the level's tier.
- [ ] Home/search tiles and the level-map header show "x/30".
- [ ] No "Next level" button after completing level 30, whether it's a first clear or a replay.
- [ ] Clearing level 30 for the first time opens the **Topic Mastered** screen automatically after the level payout. It opens before any badge screen and before the save-progress sheet, and it can also be opened straight away with "See your trophy 🏆".
- [ ] The Topic Mastered screen shows:
  - the topic emoji medallion with a crown
  - "N / N LEVELS"
  - "{topic} Mastered!"
  - a data-driven Easy/Medium/Hard journey strip with per-tier stars
  - a 2×2 stats card (stars, perfect levels, total score, days to master)
  - the missing-stars nudge, or the flawless line
  - Continue and Share buttons

  It plays confetti, rays and count-up, all disabled under reduced motion, and uses no inline hex colors: the new tokens are in `AppColors`.
- [ ] Replaying level 30 does **not** re-open the Topic Mastered screen automatically.
- [ ] A fully-cleared topic's level map shows a "🏆 Mastered" pill that opens the Topic Mastered screen.
- [ ] Opening the Topic Mastered route for an unfinished topic shows the error view, not a congratulation.
- [ ] The score breakdown's flawless line reads "Flawless — 10 of 10" / "15 of 15" / "20 of 20" to match the level.
- [ ] Profile's "fastest level" stat uses each attempt's recorded clock.
- [ ] `DifficultyBand` has 3 values; `difficultyExpert`/`difficultyMaster` no longer exist in any `.arb` or generated file.
- [ ] The `generate-questions` skill offers only Easy/Medium/Hard, with the new timers and question counts.
- [ ] `dart format` makes no changes, `dart analyze` reports 0 issues, and the full `flutter test` suite passes.

## Risks & rollout notes

- **Content gap (the biggest practical risk).** Live Medium/Hard content is 6 + 5 (+8 re-homed) English questions across 2 demo subcategories, and none in hi/ur. Level 11+ is unplayable for nearly every topic after this change, exactly as it already is. The per-tier minimums before the ladder feels right, using `v_thin_question_pools`' 3× rule, are **45 Medium and 60 Hard live questions per subcategory per language**. Plan Medium/Hard authoring with `/generate-questions` (updated in Phase 5) as a follow-up. `select * from v_thin_question_pools` shows where to start.
- **Order of operations.** Apply the migration **before** shipping the Flutter build. The old client reads the tier table live, so it degrades gracefully against the new DB. The new client against the old DB would show 50 levels via `totalLevels = max(levelEnd)` with 5 tiers, and `_bandForTierCode` would map expert/master → sharp. That's harmless, but applying the DB first avoids the mismatch.
- **Rollback.** The migration is reversible by hand: re-upsert the 5-tier rows (the values are in `20260910090000_difficulty_ladder_v2.sql`), widen the constraints to 1–50, and restore the two RPC bodies from `20260917100200…`/`20260919194353…`. Re-homed questions can stay on `hard`. Keep `level_attempts.seconds_per_question`: it's harmless. Write this down in the migration's header comment.
- **Mastery rewards (follow-up idea, not in this plan).** A one-time coin bonus or a "Topic Master" badge on first mastery would fit naturally. It needs `submit_level_attempt` to grant it and return a flag, plus an achievements seed row. Keep it out of this plan so the economy is reviewed on its own. The screen already has room for a reward pill under the ribbon if that's added later.
- **Migration history.** Follow the memory-recorded convention: MCP `apply_migration` or `db query --linked -f` plus a `schema_migrations` row. **Never `supabase db push`.** Only apply on the developer's explicit instruction.
- **Docs to update after implementation**:
  - Add a memory note `project_plan_020_status.md`, following the other plan-status memories.
  - Grep `README.md`/`MOCKED_FEATURES.md` for "50 levels"; none was found at planning time.
- **To verify (developer, on device, after implementation):**
  1. Open any topic's level map. Expect 30 nodes and three band dividers reading "EASY · 20s PER QUESTION", "MEDIUM · 15s …" and "HARD · 10s …", with crowns on 10, 20 and 30.
  2. The current-node label and the "Play Level N" sub-label read "10 questions · 20s each" on an Easy level.
  3. Open the brief sheet for a Medium level (use a dev account, or temporarily insert `level_progress` rows) and check it says 15 questions / 15s.
  4. Play level 1 of an English Easy topic. The HUD shows "1/10", the clock starts at 20, and the level ends after 10 questions with the correct stars.
  5. Home tiles and the level-map header read "x/30".
  6. Fake-complete levels 1–29 for a test account on one topic (insert `level_progress` rows with `completed_at = now()`, varied `stars`), then play level 30.
     - The Level Complete screen shows "See your trophy 🏆" and no "Next level".
     - After about 2.6 s the Topic Mastered screen slides in: rays rotate, the medallion pops with a haptic, confetti bursts once, the crown drops, the tier pills pop in order, and the stats count up.
     - Check that the numbers match the seeded stars and scores, and that the missing-stars nudge count is right.
     - Tap **Continue**. You're back on Level Complete, and any badge screen follows after it.
     - Tap **Share my trophy** and check that the mock share sheet opens with the preview card.
  7. Replay level 30. Level Complete shows "Back to map", with no "Next level" and no automatic trophy screen.
  8. On that topic's level map, tap the "🏆 Mastered" pill and check that the Topic Mastered screen opens.
  9. Turn on the OS "Reduce motion" setting and reopen the Topic Mastered screen. There should be no confetti, no rotation and no count-up, and everything should appear at once.
  10. Check Topic Mastered in Urdu (RTL): the tier strip reads right-to-left and the long title wraps cleanly. Check it at the largest system text size: the body scrolls with no overflow stripes.
  7. The onboarding climb slide reads "Climb 30 levels in every topic".
