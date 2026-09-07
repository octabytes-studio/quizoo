# Backend Foundation, Auth, Catalog & Core Gameplay Loop

> Source spec: provided inline in conversation — "connect the Quizoo Flutter
> app (currently 100% mock data) to the Supabase + Firebase backend the
> design bible §22 recommends, starting with the foundation and the core
> play loop."
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full. Code may have moved on since it was
written (Sep 2026), so spot-check the referenced files still match before
you begin — in particular, re-open `lib/core/mock/mock_api.dart` and
`CLAUDE.md` §9, since this plan's whole premise is the seam those two
establish.

**Prerequisite**: the manual setup in `docs/backend/01-supabase-project-setup.md`
through `04-flutter-app-configuration.md` must be done first — this plan
assumes a live Supabase project with `supabase/migrations/*.sql` and
`supabase/seed.sql` already applied, and a Firebase project with
`lib/firebase_options.dart` already generated. If those docs haven't been
run yet, do that before starting Phase 0 below.

**Companion plan**: `.claude/plans/006-social-economy-realtime-backend.md`
covers everything this plan doesn't — leaderboards, daily challenge,
achievements, shop/IAP, duels, settings/notifications. It depends on this
plan's Phase 0 (bootstrapping) and Phase 1 (auth) being done first, but is
otherwise independent of Phases 2-4 here.

## Objective

Replace the mock data layer with real calls to Supabase (Postgres, Auth,
Realtime, Storage) and wire in the Firebase client services (Crashlytics,
Analytics), for: app bootstrapping, authentication, the catalog/browse
surfaces, the core play loop (start a level → answer → submit → see
results), and the profile/stats screens. Every other feature (leaderboards,
daily challenge, achievements, shop, duels, settings, notifications) is
plan 006's job.

The guiding constraint, stated in `lib/core/mock/mock_api.dart`'s own doc
comment and worth repeating here because it is the reason this plan is
possible at all: *"When a backend lands, only the body of each
`*_api.dart` changes — repository, domain and presentation are untouched."*
This plan holds that promise everywhere it can, and calls out explicitly
the handful of places (below, in Assumptions) where reality forces a
slightly bigger change.

## Scope

**In scope:**
- Adding `supabase_flutter` + Firebase packages; initializing both in
  `main.dart`/`lib/app/app.dart`.
- `features/auth`: `AuthApi`, `AuthRepository` — real sign-in (anonymous
  guest bootstrap, Google, Apple, email), profile creation, username
  availability.
- `features/catalog`: `CatalogApi`, `CatalogRepository` — categories,
  subcategory browse, level map, single level lookup.
- `features/home`: `HomeApi`, `HomeRepository` — cached-home payload,
  popular rail, search.
- `features/quiz_play`: `QuizPlayApi`, `QuizPlayRepository` — fetching a
  level's questions from the real backend (`start_level_attempt`).
- `features/quiz_result`: `QuizResultApi`, `QuizResultRepository` —
  submitting a finished run (`submit_level_attempt`) and turning the
  response into `LevelResult`.
- `features/profile`: `ProfileApi`, `ProfileRepository` — summary and stats
  screens, reading real aggregates.
- `features/onboarding`: `OnboardingRepository` moving from in-memory to
  `shared_preferences` (first-run / language-chosen flags need to survive a
  cold start against a real backend, where a returning player shouldn't see
  onboarding again).
- Crashlytics + Analytics initialization (Remote Config is plan 006's
  concern, tied to the economy).

**Out of scope:**
- Leaderboards, daily challenge, achievements, shop/IAP, duels, settings
  sync, push notifications — all plan 006.
- Any new screen or visual change. This plan changes what data a screen
  reads, never how it renders.
- Local caching / offline-first (Drift or Isar). The design bible's §25
  build notes call for a `QuestionRepository` that "reads Drift/Isar first
  and Supabase second" — `QuizPlayRepository`'s existing in-memory prefetch
  cache (see Research findings) already satisfies §01's "no blocking network
  mid-level" contract without a persistence layer, so this plan does not add
  one. Flag this as a deliberate deferral, not an oversight — see
  Assumptions.
- Content authoring beyond what's in `supabase/seed.sql` (Football +
  Solar System, the two topics the mock UI already has real questions for).
  Everything else stays a "New"/locked tile, exactly as it renders today.

## Research findings

**Architecture (CLAUDE.md, read in full):**
- §1/§2: strict `Presentation → Domain → Data` layering, one
  `features/<name>/data/<name>_api.dart` + `<name>_repository.dart` pair per
  feature. Repositories are the *only* thing that talks to an `_api.dart`
  class; Cubits never import one directly.
- §9: "One `ApiClient` (Dio) in `core/network/`... Feature `*_api.dart`
  files use this shared client." **This plan does not introduce Dio** — see
  Assumptions #1.
- §10: cross-feature reuse only through `core/`; this plan adds nothing to
  `core/network/` beyond what's needed to hold the Supabase client itself
  (see Design overview).

**The mock seam (`lib/core/mock/mock_api.dart`, read in full):** every
`*_api.dart` class extends `MockApi` and calls `respond(() => ...)`, which
adds artificial latency and an occasional simulated failure
(`ApiException`), then returns the built value. The class doc comment states
the exact contract this plan relies on: signatures are already what a real
client would have; only each method's *body* changes. Concretely, per
feature, the pattern is: replace `extends MockApi` + `respond(...)` with a
plain class holding a `SupabaseClient`, and translate every simulated
failure path to a real one (a thrown `PostgrestException` /
`AuthException` mapped to `ApiException`, per CLAUDE.md §9's "all Dio
exceptions are mapped to a single typed `ApiException`" — same idea, source
is Supabase's exception types instead of Dio's).

**`core/network/api_exception.dart`** (read in full): `ApiException` is
already backend-agnostic — `ApiErrorKind` (network/timeout/unauthorized/
notFound/server/parsing/unknown), a `message`, `statusCode`, `code`. Nothing
here needs to change; this plan adds one mapping function
(`ApiException.fromSupabase` — see Design overview) that every `*_api.dart`
class funnels its catch blocks through, matching §9's "mapped to a single
typed exception at the boundary" even though the boundary is now
`supabase_flutter` instead of Dio.

**Session/auth architecture** (`features/auth/presentation/bloc/
session_cubit.dart`, `session_state.dart`, read in full): `SessionCubit`'s
initial state is `SessionGuest()` with **no sign-in call made at all** —
today, a guest is simply "no `AuthUser`". `SessionState` is a 4-way sealed
class (`SessionGuest` / `SessionAuthenticating` / `SessionSignedIn` /
`SessionFailure`) that already matches Supabase's auth shape closely enough
that **`SessionCubit` and `SessionState` need zero changes** — see Design
overview for how `AuthRepository` bridges the gap (real guests need a real
`auth.uid()` for RLS to work at all, which `SessionGuest` alone doesn't
provide).

**`features/auth/data/auth_api.dart` / `auth_repository.dart`** (read in
full): four methods — `signInWithVendor(AuthProvider)`,
`startEmailSignIn()`, `createProfile({username, email, avatarEmoji,
countryName, countryFlag})`, `isUsernameAvailable(String)`. `AuthRepository`
additionally holds two **in-memory, session-lifetime** flags —
`hasCompletedALevel` / `hasShownSaveProgressPrompt` — driving whether S-24
(the save-progress sheet) is allowed to appear. These flags are explicitly
documented as "a known, accepted gap" in the mock phase (no
`shared_preferences`); this plan's Assumptions revisit whether that gap
should close now.

**`features/catalog/data/catalog_api.dart`** (read in full): three methods
— `fetchCategory(categoryId)` → `CategoryDetail` (category + topics +
playerCount), `fetchLevelMap({categoryId, subcategoryId})` → `LevelMap`
(category + subcategory + 20 `Level`s + rank), `fetchLevel({subcategoryId,
levelNumber})` → single `Level`. A missing id throws
`ApiException(kind: notFound, code: 'ERR_CONTENT_404')` — S-48 renders that
code on screen, so the real implementation must preserve the same
`ApiErrorKind`/`code` pairing on a genuine not-found.

**`core/models/level.dart`** (read in full): `Level.difficultyBand` and
`Level.secondsPerQuestion` are **derived from the level number alone**
(`MockCatalog.bandFor`/`secondsFor`, ported to SQL as
`_difficulty_band_for_level`/`_seconds_for_level` in the functions
migration) — there is no `levels` catalog table in the schema, by design;
see `supabase/migrations/20260907120200_functions_and_triggers.sql`.

**`features/quiz_play/data/quiz_play_api.dart` / `quiz_play_repository.dart`**
(read in full): one method, `fetchLevelQuestions({subcategoryId,
levelNumber, languageCode})` → `List<Question>`, called exactly once per
level by `QuizPlayRepository.prepareLevel` and cached in an in-memory map —
this *is* the "no blocking network mid-level" mechanism (§01), and this
plan keeps it exactly as-is, changing only what `QuizPlayApi` fetches from.

**`core/models/` domain models needing a schema reconciliation** — every
field below is accounted for in `supabase/migrations/20260907120000_
initial_schema.sql`; flagged here because getting them wrong breaks a
freezed model's `required` fields:
- `Question.correctIndex` is `required` → see Assumptions #2 (the
  anti-cheat trade-off).
- `Category`/`Subcategory` need `colorFrom`/`colorTo`/`emoji`/`plateColor`/
  `groupName`/`isNew`/`isLocked` — all present as real columns, not derived
  (`categories`/`subcategories` tables).
- `LevelMap.rank` ("#412") has no ready-made column — computed at read time
  (see Design overview).

**`features/quiz_result/data/quiz_result_api.dart`** (read in full): one
method, `submit(QuizRun)` → `RunRecord {isFirstClear, newlyEarnedBadgeIds}`.
Its doc comment states plainly what the real backend must do: *"the client's
own total is display only"* — `submit_level_attempt` (functions migration)
is the server-side implementation of exactly this method, recomputing score
from the answer log rather than trusting `QuizRun.score`.

**`features/profile/data/profile_api.dart`** (read in full): two methods,
`fetchSummary()` → `ProfileSummary`, `fetchStats()` → `StatsSummary`. Several
`ProfileSummary` fields are aggregates with no single source table
(`totalPoints`, `totalLevels`, `accuracyPercent`, `bestCategories`) — see
Design overview for the query shape.

**Testing conventions (CLAUDE.md §11, `pubspec.yaml`'s dev_dependencies):**
`bloc_test` + `mocktail` are already project dependencies. Repository tests
mock the `*_api.dart` layer with `mocktail`, not a real Supabase client —
this plan's testing strategy follows that exactly; no test in this plan
talks to a real (or even a local Supabase CLI) database.

## Assumptions & open questions

1. **No `dio`, no `ApiClient` class, despite CLAUDE.md §9's literal
   wording.** §9 says "One `ApiClient` (Dio) in `core/network/`... Feature
   `*_api.dart` files use this shared client." `supabase_flutter`'s
   `Supabase.instance.client` already *is* a shared, singleton, once-
   configured client covering Postgrest (data), Auth, Realtime, Storage and
   Edge Function invocation — adding Dio on top would mean running two HTTP
   stacks for no reason. This plan treats `Supabase.instance.client` as the
   thing §9's "one shared client" rule is actually protecting against
   duplication of (a *second* client instantiated ad hoc inside a feature),
   and keeps the letter of the rule ("never instantiate a new client inside
   a feature") while updating what the client *is*. Flagging this rather
   than silently complying with a rule that would produce worse code — a
   human should confirm this reading of §9 before Phase 0 lands, since it's
   the one place this plan knowingly deviates from the letter of the
   project's own governance file.

2. **`Question.correctIndex` ships to the client, ahead of submission** —
   a deviation from the design bible's literal RLS note ("never ship
   correct_index to the client before the answer is submitted"). Reasoning
   is in the SQL comment on `start_level_attempt` in the functions
   migration; the short version: `Question.correctIndex` is a `required`
   field the whole `quiz_play` feature is built around for instant, offline,
   per-tap feedback, and hiding it would mean either a per-question network
   round trip (breaking §01's "no blocking network mid-level" pillar) or a
   shuffle-token scheme whose protection is marginal for a single-player,
   no-real-money game. `submit_level_attempt` still independently re-derives
   correctness server-side rather than trusting the client's classification
   — the score/currency-facing anti-cheat guarantee holds; only the
   "player can theoretically read the answer key via decompilation/network
   inspection before answering" guarantee is relaxed. **A human should
   confirm this trade-off explicitly** — it's the single biggest security
   posture call in this plan, and the alternative (Option B: per-question
   RPC or a shuffle-token scheme) is a bigger, riskier change to
   `quiz_play`'s Cubit if it turns out to be needed later (e.g. before a
   real-money or ranked-ladder feature).

3. **Email sign-in becomes a magic link, not a password.** The mock's
   `startEmailSignIn()`/`createProfile()` pair has no password field
   anywhere in the UI (`profile_creation_screen.dart` collects username,
   avatar, country — not a password), and Supabase's own recommended
   passwordless flow is `signInWithOtp(email: ...)` (magic link or numeric
   OTP). **Open question for whoever executes this plan**: does the redirect
   land the player back in-app via the deep link set up in
   `docs/backend/04-flutter-app-configuration.md` §4 (silent, matching
   today's "tap a button, you're in" simplicity), or does the flow need a
   lightweight "check your email" / "enter the 6-digit code" state added to
   `profile_creation_screen.dart`'s flow? This plan's Phase 1 assumes the
   magic-link/deep-link route (no new screen) as the smaller change; revisit
   before implementing if that assumption is wrong for the target audience
   (a numeric OTP is often more reliable than a mail-client deep link on
   Android, where the OS may open the link in a different browser context
   than the app).

4. **Guests get a real (anonymous) Supabase session, invisibly, at app
   launch.** `SessionGuest` in the mock has no backing identity at all; RLS
   policies throughout `supabase/migrations/20260907120100_rls_policies.sql`
   require `auth.uid()` for anything a guest can do (start/submit a level,
   at minimum). This plan calls `Supabase.instance.client.auth.
   signInAnonymously()` once, transparently, the first time `AuthRepository`
   is constructed with no existing session — never surfaced to the player,
   and `SessionCubit`/`SessionState` stay exactly as they are (the anonymous
   session is an implementation detail inside `AuthRepository`, not a new
   `SessionState` variant). Signing in with Google/Apple/email later calls
   Supabase's identity-linking API to **upgrade the same user id in place**,
   which is what makes a guest's progress (already written against their
   anonymous `auth.uid()`) carry over to the real account with zero data
   migration. This is the standard Supabase pattern for "play first, sign in
   later" and is a design decision this plan is making, not an open
   question — noted here because it has no analog in the mock code at all.

5. **`OnboardingRepository`'s two flags move to `shared_preferences`, not
   Supabase.** They're per-device UX state ("has this install seen the
   onboarding carousel"), not player data — no `profiles` column exists or
   should exist for them. Flagged as an assumption only because the mock's
   own doc comment calls the in-memory version "a known, accepted gap"
   without saying what the real fix is; this plan's answer is local
   persistence, not a server round trip.

6. **`AuthRepository`'s save-progress-prompt flags (`hasCompletedALevel`,
   `hasShownSaveProgressPrompt`) also move to `shared_preferences`.** The
   design bible's own rule is "at most once per 24 h," which an in-memory
   flag can't honor across a cold start. Local persistence is enough — this
   is a per-device prompt-suppression flag, not player data that needs to
   sync across devices.

7. **`CategoryDetail.playerCount` and `LevelMap.rank` are both "live
   engagement" numbers with no single authoritative source in the mock
   either** (the mock hardcodes them per category / looks up a fixed
   `MockPlayer.subcategoryRank`). This plan computes `playerCount` from
   `categories.player_count` (maintained by daily-rollover, plan 006 — until
   that job has run at least once, it reads `0`, matching a freshly seeded
   database's honest state) and `rank` via a query against `level_progress`
   ordered by `best_score` for that subcategory (see Design overview) —
   good enough for launch; a materialized per-subcategory rank view is a
   fair thing to add later if this read proves slow at scale.

## Design overview

**New `core/` additions** (the only `core/` changes this plan makes,
consistent with CLAUDE.md §10's "add to, don't restructure" rule for shared
files):

- `core/network/supabase_client.dart` — a single top-level accessor,
  `SupabaseClient get supabase => Supabase.instance.client;`, so every
  `*_api.dart` file imports one thing rather than reaching into
  `Supabase.instance` directly. This is the "shared client" §9 asks for,
  reinterpreted per Assumption #1.
- `core/network/api_exception.dart` — **add**, don't replace, a factory:
  `ApiException.fromSupabase(Object error)` that pattern-matches
  `AuthException`, `PostgrestException`, and a raw `SocketException`/
  network failure into the existing `ApiErrorKind` values (e.g. a Postgrest
  `PGRST116` "no rows" → `ApiErrorKind.notFound`; an `AuthException` with
  no active session → `ApiErrorKind.unauthorized`; anything unrecognized →
  `ApiErrorKind.unknown`). Every `*_api.dart` method in this plan wraps its
  body in `try { ... } catch (e) { throw ApiException.fromSupabase(e); }`.

**`lib/app/app.dart` / `main.dart` changes:**
- `main.dart` (currently just a `runApp` shim — confirm its exact current
  content before editing) becomes `Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); await Supabase.initialize(url:
  ..., anonKey: ...); await Firebase.initializeApp(options:
  DefaultFirebaseOptions.currentPlatform); FlutterError.onError =
  FirebaseCrashlytics.instance.recordFlutterFatalError; runApp(const
  QuizooApp()); }` — reading the Supabase URL/anon key via
  `String.fromEnvironment`, per `docs/backend/04-flutter-app-configuration.md`
  §3.
- `QuizooApp`'s `_QuizooAppState` (in `app/app.dart`) currently constructs
  `AuthRepository(AuthApi())` and `QuizPlayRepository(QuizPlayApi())`
  directly in field initializers — this stays structurally identical; only
  `AuthApi()`/`QuizPlayApi()`'s constructors change (no more `MockApi`
  latency/failure-rate parameters, since those were mock-only).

**Auth flow** (`features/auth/data/auth_api.dart` rewritten):
```dart
class AuthApi {
  AuthApi(this._client);
  final SupabaseClient _client;

  Future<AuthUser> ensureGuestSession() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
    return _fetchCurrentAuthUser();
  }

  Future<AuthUser> signInWithVendor(AuthProvider provider) async {
    // google/apple -> OAuth().signInWithOAuth(...) per Assumption #4's
    // identity-linking note when currentSession is anonymous, else a fresh
    // sign-in. See Supabase Flutter's linkIdentity() for the "upgrade in
    // place" call.
  }

  Future<AuthUser> startEmailSignIn(String email) =>
      _client.auth.signInWithOtp(email: email) /* per Assumption #3 */;

  Future<AuthUser> createProfile({...}) async {
    // UPDATE profiles set username=..., avatar_key=..., country_code=...
    // (RLS's column-scoped grant in the RLS migration is exactly this set)
    // via .from('profiles').update({...}).eq('id', _client.auth.currentUser!.id)
  }

  Future<bool> isUsernameAvailable(String username) async {
    final row = await _client.from('profiles').select('id')
        .eq('username', username).maybeSingle();
    return row == null;
  }
}
```
`_fetchCurrentAuthUser()` selects the caller's own `profiles` row and maps
it to `AuthUser` (`isProfileComplete = username != null`, per the schema
comment in the initial-schema migration).

`AuthRepository.shouldOfferSaveProgress`/`markLevelCompleted`/
`markSaveProgressPromptShown` (Assumption #6) read/write
`shared_preferences` instead of instance fields, keeping their exact
signatures.

**Catalog flow** (`features/catalog/data/catalog_api.dart` rewritten):
- `fetchCategory(categoryId)`: one query joining `categories` +
  `taxonomy_i18n` (locale from the active `LocaleCubit`, passed in — check
  how the current mock decides "en" vs "ur" and thread the same value
  through) for the category row, then `subcategories` + `taxonomy_i18n` for
  its topics, `playerCount` from `categories.player_count`. A missing
  category → Postgrest returns zero rows → mapped to `ApiException(kind:
  notFound, code: 'ERR_CONTENT_404')` exactly as the mock does.
- `fetchLevelMap({categoryId, subcategoryId})`: `categories` +
  `subcategories` rows, `level_progress` rows for
  `(auth.uid(), subcategoryId)` to build all 20 `Level`s (status/stars/
  bestScore per level number; levels with no `level_progress` row are
  `locked` except the lowest unattempted number, which is `current` — port
  `MockCatalog._level`'s exact status logic), `rank` via `select count(*)+1
  from level_progress where subcategory_id = ? and best_score > (select
  best_score from level_progress where user_id = auth.uid() and
  subcategory_id = ?)` (0 for a guest with no rows yet, matching the mock's
  `subcategory.levelsCleared == 0 ? 0 : ...`).
- `fetchLevel({subcategoryId, levelNumber})`: same per-level construction as
  above, single row.

**Home flow** (`features/home/data/home_api.dart` rewritten):
- `fetchCachedHome({isSignedIn})`: `categories` + `subcategories` (all,
  `is_active = true`) joined with the caller's `level_progress` for
  per-subcategory progress; `currency` from the caller's `profiles` row
  (coins/gems/hearts/maxHearts/heartRefillAt — call `_settle_hearts` first
  via a lightweight RPC or accept the lazily-stale value and let the next
  wallet-touching action settle it); `daily` from
  `daily_challenges.challenge_date = today` (`minutesRemaining` computed
  client-side from `now()` to end of day UTC, or a small RPC — plan 006
  owns the actual daily-challenge feature, so this field can be a thin
  pass-through here); `continueEntry` from `level_progress` ordered by
  `last_played_at desc` where `completed_at is null` (or `stars < 3`,
  matching "unfinished" loosely — confirm against `MockCatalog`'s exact
  semantics for what counts as "continue-able" before finalizing the WHERE
  clause).
- `fetchPopularRail()`: `featured_quizzes` where `is_active` and not
  expired, ordered by `sort_order`.
- `fetchTrendingSearches()`: same query as the popular rail — the mock
  literally reuses it (`HomeApi.fetchTrendingSearches` returns `_popular`),
  keep that.
- `HomeRepository.search(query)`'s client-side matching logic (name/
  groupName/category name, case-insensitive `contains`) is domain logic
  that stays in the repository unchanged — only what `fetchCachedHome`
  returns changes, not how search filters it. (A future optimization could
  push this to a Postgres full-text query; out of scope here since the
  mock's own behavior is the bar to match, not beat.)

**Quiz play flow** (`features/quiz_play/data/quiz_play_api.dart`
rewritten):
```dart
class QuizPlayApi {
  QuizPlayApi(this._client);
  final SupabaseClient _client;

  Future<StartLevelResult> startLevel({
    required String subcategoryId,
    required int levelNumber,
    required String languageCode,
  }) async {
    final response = await _client.rpc('start_level_attempt', params: {
      'p_subcategory_id': subcategoryId,
      'p_level': levelNumber,
      'p_locale': languageCode,
    });
    // response: {attemptId, secondsPerQuestion, isBoss, questions: [...]}
    // -> List<Question> via Question.fromJson per element, attemptId
    //    threaded through QuizPlayRepository for submit_level_attempt later.
  }
}
```
**This is the one place a method signature actually changes** — the mock's
`fetchLevelQuestions` returns bare `List<Question>`; the real backend also
hands back an `attemptId` the submit step needs (heart-spend/anti-cheat
tracking is per-attempt, not re-derivable from `subcategoryId` +
`levelNumber` alone, since a player can retry a failed level). `QuizPlayRepository`'s
prefetch cache (`_prefetched` map) is the natural place to also hold the
attempt id alongside the question list — extend its cached value from
`List<Question>` to a small `PreparedLevel {attemptId, questions}` record,
and thread `isPrepared`/`prepareLevel`/`questionsFor`'s call sites
(`quiz_play_cubit.dart`, `level_brief_sheet.dart` — confirm both still
compile) to read `.questions` where they used the bare list today.
`QuizResultRepository.submit` (below) is what needs `.attemptId`.

Handle `ApiException` with `code: 'out_of_hearts'` (from the RPC's raised
exception, mapped via `fromSupabase`) distinctly — this is
`OutOfLivesDialog`'s trigger; confirm `QuizPlayCubit`'s current out-of-hearts
handling (client-side heart depletion mid-run, per `QuizRun.heartsRemaining`
— see Research findings' distinction between *account* hearts, spent once
to start, and *in-run* hearts/lives, spent per wrong answer) so this new
"can't even start" error path is added alongside it, not confused with it.

**Quiz result flow** (`features/quiz_result/data/quiz_result_api.dart`
rewritten):
```dart
Future<RunRecord> submit(QuizRun run, {required String attemptId}) async {
  final response = await _client.rpc('submit_level_attempt', params: {
    'p_attempt_id': attemptId,
    'p_answers': run.answers.map((a) => {
      'questionId': a.question.id,
      'chosenIndex': a.chosenIndex,
      'secondsLeft': a.secondsLeft,
      'action': switch (a.outcome) {
        AnswerOutcome.timedOut => 'timedOut',
        AnswerOutcome.skipped => 'skipped',
        _ => 'answered',
      },
    }).toList(),
    'p_used_power_up': run.usedPowerUp,
    'p_ending': switch (run.ending) {
      RunEnding.finished => 'finished',
      RunEnding.outOfHearts => 'outOfHearts',
      RunEnding.quit => 'quit',
      RunEnding.inProgress => throw StateError('cannot submit an in-progress run'),
    },
  });
  // response: {isFirstClear, finalScore, stars, coinsEarned, xpEarned,
  //            playerLevel, newlyEarnedBadgeIds}
}
```
`QuizResultRepository.submit` currently computes `finalScore`/`stars`/
`coinsEarned`/`xpEarned` **client-side** via the `Scoring` class after
calling `_api.submit`. With a real backend, the server response already
carries the authoritative versions of all of these — `QuizResultRepository`
should use the response's values directly rather than recomputing them
(deleting the client-side `Scoring.total`/`Scoring.stars`/
`Scoring.coinsEarned`/`Scoring.xpEarned` *calls* from this repository, while
leaving the `Scoring` class itself in place — `quiz_play_cubit.dart` still
needs it for the in-run running-score display, which has no server round
trip per question). Cross-check: the SQL in `submit_level_attempt` was
transcribed from the same `Scoring` formulas specifically so client and
server agree during play; this repository change is about *which* number
becomes the one shown on the result screen, not about the formulas
disagreeing.

**Profile flow** (`features/profile/data/profile_api.dart` rewritten):
- `fetchSummary()`: `profiles` row for `auth.uid()` (username, avatarKey,
  countryCode+city, xp/playerLevel via `_player_level_from_xp`,
  streak_days, league) + `_rank_title_for_level` + a `user_achievements`
  count/recent-3 join to `achievements` (for `badgeCount`/`recentBadges`) +
  a `level_progress` aggregate grouped by `subcategory_id` ordered by
  `stars_earned`/`best_score` for `bestCategories` (top 2, matching the
  mock's fixed 2). `totalPoints`/`totalLevels`/`accuracyPercent` need a
  `level_attempts` aggregate (`sum(server_score)`, `count(*) where
  completed_at is not null`, `sum(correct_count)::float /
  sum(question_count)` — question_count per attempt is always 20 for a
  finished run, adjust if a `quit`/`outOfHearts` run should count partially;
  confirm against how `QuizRun.accuracyPercent`'s own doc comment defines
  it: "measured on what it played, not on the twenty it never saw" —
  mirror that in the aggregate's denominator).
- `fetchStats()`: `pointsPerDayPercents` (7-day `score_events` sum per day,
  normalized to a 0-100 scale the way the screen's bar chart expects —
  check `stats_screen.dart`'s rendering assumption before picking a
  normalization base), `categoryAccuracies` (per-category `level_attempts`
  aggregate), `fastestAverageSeconds`/`fastestSubcategoryName`/
  `fastestLevelNumber`/`fastestPercentileLabel` (this last one has no
  percentile-ranking infrastructure in the schema yet — a fair v1 shortcut
  is computing the player's own fastest level directly and leaving the
  percentile label as a fixed "Top X%" placeholder until enough
  `level_attempts.avg_answer_ms` data exists to rank against; note this as
  a known simplification in the PR/commit that implements this method,
  since it's a design call being made during implementation, not something
  this plan can fully resolve in advance).

## Implementation steps

**Phase 0 — Bootstrapping**
- [ ] Add `supabase_flutter`, `firebase_core`, `firebase_crashlytics`,
      `firebase_analytics`, `shared_preferences` to `pubspec.yaml` (per
      `docs/backend/04-flutter-app-configuration.md` §1).
- [ ] Run `flutterfire configure` if `lib/firebase_options.dart` doesn't
      exist yet (it's generated, not hand-written — confirm it isn't
      already present before regenerating).
- [ ] Create `core/network/supabase_client.dart`.
- [ ] Add `ApiException.fromSupabase(...)` to `core/network/api_exception.dart`.
- [ ] Update `main.dart` per Design overview.
- [ ] Confirm `flutter analyze` is still zero-warnings (CLAUDE.md §8) before
      moving on — this phase touches nothing feature-specific, so it should
      be a clean, independently-reviewable commit.

**Phase 1 — Auth**
- [ ] Rewrite `features/auth/data/auth_api.dart` per Design overview.
- [ ] Update `features/auth/data/auth_repository.dart`: swap the two
      in-memory flags for `shared_preferences` reads/writes (Assumption
      #6); constructor now takes the real `AuthApi`.
- [ ] Wire `AuthRepository`'s anonymous-session bootstrap (Assumption #4)
      into `app/app.dart`'s `_authRepository` field initializer or
      `initState` — confirm which is more testable given `QuizooApp`'s
      existing `StatefulWidget` shape before picking one.
- [ ] Resolve Assumption #3 (email flow) with a human before implementing
      `startEmailSignIn`/the email branch of `createProfile` — this is the
      one sub-step in this plan most likely to need a small UI addition
      alongside the data-layer change, which would be an amendment to this
      plan's Scope, not a silent addition.
- [ ] `bloc_test` update: `session_cubit_test.dart` (if it exists — check;
      CLAUDE.md §11 requires one) needs its mocked `AuthRepository` calls
      updated for the new method signatures, if any changed.

**Phase 2 — Catalog & Home**
- [ ] Rewrite `features/catalog/data/catalog_api.dart` per Design overview.
- [ ] Rewrite `features/home/data/home_api.dart` per Design overview.
- [ ] Leave `features/catalog/data/catalog_repository.dart`'s `sorted(...)`
      static method and `features/home/data/home_repository.dart`'s
      `search(...)`/`_matches(...)` untouched — both are pure client-side
      logic over already-fetched data, per Research findings.
- [ ] Verify `LevelMapScreen`/`CategoryDetailScreen`/`HomeScreen` still
      compile against the (unchanged) `LevelMap`/`CategoryDetail`/
      `HomeContent` domain models — this phase should produce no
      presentation-layer diffs at all if Phase 0/1's exception mapping and
      the repository signatures are right.

**Phase 3 — Quiz play & result**
- [ ] Rewrite `features/quiz_play/data/quiz_play_api.dart` per Design
      overview, including the `attemptId` threading change.
- [ ] Update `features/quiz_play/data/quiz_play_repository.dart`'s cache
      value type (`List<Question>` → `PreparedLevel`) and its call sites.
- [ ] Rewrite `features/quiz_result/data/quiz_result_api.dart` and update
      `features/quiz_result/data/quiz_result_repository.dart` to use the
      server's authoritative score/stars/coins/xp rather than recomputing
      them (Design overview).
- [ ] Confirm `QuizPlayCubit`'s heart-handling (in-run `QuizRun.
      heartsRemaining` vs. the new "can't start, out of account hearts"
      RPC error) are wired to the right UI states — this is the one Phase 3
      step likely to touch `quiz_play_cubit.dart` itself, not just the data
      layer, so give it its own review pass.
- [ ] `bloc_test`/repository test updates for both features per Testing
      strategy below.

**Phase 4 — Profile & stats**
- [ ] Rewrite `features/profile/data/profile_api.dart` per Design overview.
- [ ] Confirm `ProfileScreen`/`StatsScreen` render correctly against
      real (likely sparser, freshly-seeded) data — a brand-new account has
      zero `level_attempts`, so check every division-by-zero path
      (`accuracyPercent`, `xpProgress`, `weakest` category picking) behaves
      like the screens' existing empty-state handling expects, not like a
      crash.

**Phase 5 — Onboarding persistence**
- [ ] Move `features/onboarding/data/onboarding_repository.dart`'s two
      flags to `shared_preferences` (Assumption #5).

## Data model / API changes

Schema: `supabase/migrations/20260907120000_initial_schema.sql` (tables),
`20260907120100_rls_policies.sql` (RLS), `20260907120200_functions_and_
triggers.sql` (the two RPCs this plan calls directly: `start_level_attempt`,
`submit_level_attempt`, plus every helper function they depend on). Seed
data: `supabase/seed.sql`.

**RPC contracts this plan's Flutter code calls directly** (see the SQL
files' own comments for full detail):
- `start_level_attempt(p_subcategory_id uuid, p_level smallint, p_locale
  text) returns jsonb` → `{attemptId, secondsPerQuestion, isBoss,
  questions: [{id, subcategoryId, difficulty, text, options, correctIndex,
  explanation, hasImage, imageAsset}]}`.
- `submit_level_attempt(p_attempt_id uuid, p_answers jsonb, p_used_power_up
  boolean, p_ending text) returns jsonb` → `{isFirstClear, finalScore,
  stars, coinsEarned, xpEarned, playerLevel, newlyEarnedBadgeIds}`.

No REST/Edge Function endpoints are needed for this plan's scope — every
read is a direct Postgrest query against a table the RLS migration already
makes safely readable, and the two writes go through the RPCs above. (The
design bible's `start-level`/`submit-level` **Edge Functions** are a thin
optional wrapper around these same RPCs, useful mainly for request-level
rate limiting or logging — plan 006 or a later hardening pass can add them
without this plan's Flutter code changing, since the RPC contract is the
same either way.)

## Dependencies

- `supabase_flutter` — Postgrest, Auth, Realtime, Storage, Functions in one
  client (design bible §25).
- `firebase_core`, `firebase_crashlytics`, `firebase_analytics` — client
  services only, no Firestore/Firebase Auth (design bible §22).
- `shared_preferences` — local persistence for onboarding flags, the
  save-progress-prompt flags, and (per plan 006) local-only settings.

## Testing strategy

Matches CLAUDE.md §11 exactly — this plan changes no test *conventions*,
only what a repository test mocks:
- Every rewritten `*_api.dart` class gets its `mocktail`-mocked-`SupabaseClient`
  repository test (success path + at least one error-mapping path), per §11.
  Mocking `SupabaseClient`/`PostgrestFilterBuilder` directly is awkward with
  `mocktail` (fluent builder chains); the pragmatic approach other Supabase-
  Flutter projects use is wrapping each `*_api.dart` method's Supabase calls
  behind the class's own public methods (already true here, since
  `*_api.dart` is the boundary) and mocking *that* class in the repository
  test, exactly as the mock phase already does for `AuthApi`/`CatalogApi`/
  etc. — no new mocking pattern needed.
- `bloc_test` suites for every Cubit that consumes an updated repository
  (`SessionCubit`, `QuizPlayCubit`, `QuizResultCubit`, `HomeCubit`,
  `CategoryDetailCubit`, `LevelMapCubit`, `ProfileCubit`, `StatsCubit`) —
  confirm each still passes unmodified where the repository's *return
  types* didn't change, and update the mocked repository's stubbed
  responses where they did (`QuizPlayRepository`'s `PreparedLevel` change
  is the one guaranteed touch point).
- No test in this plan hits a real Supabase project — that's an integration-
  test concern this plan doesn't add (CLAUDE.md doesn't describe an existing
  integration-test setup to extend, and inventing one is a bigger, separate
  decision better made explicitly than folded into this plan).

## Edge cases & error handling

- **Anonymous session expiry/loss** (app reinstall, user clears app data):
  a "guest" becomes a brand-new anonymous user with zero progress — this
  matches the mock's own behavior (a cold start today also forgets
  everything, per the Research findings on `OnboardingRepository`), so it's
  not a regression, just worth confirming nobody assumes guest progress is
  durable across a reinstall without signing in.
- **`start_level_attempt` raising `out_of_hearts`**: map to a distinct
  `ApiErrorKind` (or reuse `code: 'out_of_hearts'` on `ApiErrorKind.unknown`
  — pick one and document it in the `fromSupabase` mapping) so
  `OutOfLivesDialog` or an equivalent "come back later / buy a refill" path
  triggers before a level even starts, not just mid-run.
- **`submit_level_attempt` called twice for the same attempt** (a retried
  network call after a timeout that actually succeeded server-side): the
  function raises `attempt_already_submitted` — `QuizResultRepository`
  should treat this as "already have a result, fetch it" rather than a hard
  failure; add a `level_attempts` select-by-id fallback read in that catch
  branch (RLS already allows the owner to `select` their own attempt row).
- **A category/subcategory with zero seeded questions** (24 of the 26
  seeded subcategories, and all 8 unseeded categories — see `seed.sql`'s
  own "PLACEHOLDER" note): `start_level_attempt` returns an empty
  `questions` array rather than erroring. Confirm `QuizPlayRepository`/
  `QuizPlayCubit` degrade the same way the mock's
  `MockQuestions.poolFor(...) => const []` fallback already does (the mock
  already models this case — it should carry over unchanged, but verify).

## Acceptance criteria

- [ ] A fresh install can play Football or Solar System, guest or signed
      in, start to finish, with the result screen showing a
      server-computed score that matches what `Scoring`'s formulas would
      produce for the same answer log (spot-check a handful of runs by
      hand against `submit_level_attempt`'s SQL).
- [ ] Signing in with Google/Apple after guest play preserves the guest's
      `level_progress`/`profiles.xp`/coins — no data loss on the identity
      upgrade (Assumption #4).
- [ ] `flutter analyze` reports zero warnings (CLAUDE.md §8) after every
      phase.
- [ ] Every `bloc_test`/repository test CLAUDE.md §11 requires exists and
      passes for every Cubit/repository this plan touches.
- [ ] No screen's visual output changes — a side-by-side against the
      current mock build (same seeded content) looks identical except
      where data genuinely differs (e.g. a fresh account's stats being
      empty rather than `MockPlayer`'s fixture numbers).

## Risks & rollout notes

- **Rollback**: since every change is confined to `*_api.dart` (+ the two
  repository/cache-shape changes called out above), reverting this plan is
  reverting those files' git history — domain/presentation are untouched,
  so a rollback can't strand the UI in a broken state.
- **Staged rollout**: land Phase 0-1 (bootstrapping + auth) as one
  reviewable unit first — everything downstream depends on a working
  Supabase client and a real `auth.uid()`, and it's the phase most likely to
  surface an environment/config problem (wrong redirect URL, missing RLS
  grant) cheaply, before three more phases are built on top of it.
- **Docs to update after implementation**: `README.md` at the project root
  currently likely describes the app as mock-data-only (confirm and update
  its wording once this plan lands) so a new contributor doesn't set up a
  Supabase project unnecessarily for a task that doesn't need one, or skip
  setup for a task that does.
