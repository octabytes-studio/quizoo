# Content language selection, persistence & filtering

> Source spec: provided inline in conversation (user's `/do-plan` arguments, 2026-09-13)
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history.
Start by reading it in full. Code may have moved on since it was written, so
spot-check the referenced files still match before you begin — in particular,
re-run the live-schema check in "Research findings" (`profiles.locale`,
`categories.language_code`) since this plan's biggest simplification depends
on those already existing.

## Objective

Today the language picker (S-03, reachable both on first launch and from
Settings) only ever changes `LocaleCubit` — the app's **UI** localization —
and that choice is never persisted anywhere. Meanwhile `HomeApi` fetches
*every* language's categories and subcategories unfiltered, so Home always
shows a mixed-language taxonomy regardless of what was picked.

This plan introduces a single, persisted **content language** — distinct
from the UI's l10n language — that is: (1) cached locally for instant reuse,
(2) saved to the user's backend profile, (3) used to filter every
category/subcategory (and question) fetch so only that language's content
ever renders, and (4) hot-reloaded into Home the moment it changes from
Settings. Per the spec's explicit item 5, the app's own UI chrome (buttons,
labels, headings — everything `AppLocalizations` provides) must keep
rendering in English regardless of which content language is picked; only
backend-authored text (category/subcategory names, question prompts and
options) follows the pick.

## Scope

**In scope:**
- A new, persisted "content language" concept, decoupled from `LocaleCubit`/
  `MaterialApp.locale`.
- Local persistence (`shared_preferences`) for instant boot-time reuse.
- Backend persistence, reusing the **already-existing** `profiles.locale`
  column (see Research findings — no new table).
- Filtering `categories`/`subcategories` (Home, Search) by that language, so
  no other language's taxonomy ever renders.
- Reloading Home's content the moment the language changes from Settings.
- Consistently sourcing every other content-fetch call site (Category
  detail, Level map, Quiz play, Daily, Duel) from the same content-language
  value, since the spec's item 5 explicitly names "questions, MCQs" as
  backend text that must follow the pick too.
- Wiring the S-03 picker (used both at first launch and from Settings) to
  write to this new mechanism instead of `LocaleCubit`.
- Test-harness updates so existing widget tests that pump the touched
  screens keep working.

**Out of scope:**
- Any change to `LocaleCubit`, `MaterialApp.locale`, `AppLocalizations`,
  `supportedLocales`, or the device-locale-follow behavior. The UI l10n
  mechanism is left exactly as it is today (see Assumptions — this is a
  deliberate reading of item 5, flagged as an open question).
- Adding new active languages, new translations, or new content. Only `en`
  and `ur` currently have any live categories/questions (see Research
  findings) — this plan does not change that.
- `ProfileApi`'s own separate, pre-existing, hardcoded-to-`'en'`
  `taxonomy_i18n` lookup (stats screen's category-accuracy names) — noted
  as a related gap in Risks & rollout notes, not fixed here, since the
  spec's items 1–4 name Home explicitly and the stats screen isn't a
  category/subcategory *listing*.
- Real matchmaking, admin content-authoring UI, anything already flagged
  out-of-scope by plan 007 (see `project_plan_007_status` memory) — unchanged.

## Research findings

**The spec's own suggestion ("create a user settings table") is already
unnecessary — flagging this conflict per this skill's own instructions.**
`supabase/migrations/20260907120000_initial_schema.sql` (lines 26–73) already
gives every `profiles` row a `locale text not null default 'en'` column, and
`20260907120200_functions_and_triggers.sql`'s `_handle_new_user()` trigger
(lines 21–39) inserts a `profiles` row for **every** `auth.users` insert,
including anonymous ones — confirmed live via `mcp__supabase__list_tables`
(1 row in `profiles`, `locale` column present, default `'en'`). `lib/main.dart`
(lines 35–66) signs every guest in anonymously at boot, so **every** session,
guest or signed-in, already has a `profiles` row to store this on. RLS
already permits the write: `20260907120100_rls_policies.sql` line 62:
`grant update (username, avatar_key, country_code, city, locale) on public.profiles to authenticated;`
— and Supabase anonymous sessions are `authenticated` role, so a guest can
write it too, exactly the way `AuthApi.createProfile`
(`lib/features/auth/data/auth_api.dart:97-108`) already updates other
profile columns via `.from('profiles').update({...}).eq('id', authUser.id)`.
**No migration, no new table, is needed.**

**The actual bug is in `HomeApi`, not in persistence.**
`lib/features/home/data/home_api.dart`'s `fetchCachedHome` (lines 32-151)
queries `categories`/`subcategories` filtered only by `is_active = true` —
never by language — then names them via a stale dual-locale
`_taxonomyNames` (lines 188-212) left over from before plan 007's
single-language-per-entity model landed. This exact gap is already recorded
in memory (`project_plan_007_status`: "HomeApi's own categories/subcategories
listing still mixes every language's content together unfiltered... a
separate, pre-existing gap"). `HomeRepository.search` (line 34-37 of
`lib/features/home/data/home_repository.dart`) also hardcodes
`languageCode: 'en'`.

**The correct pattern already exists one feature over, in `CatalogApi`.**
`lib/features/catalog/data/catalog_api.dart`'s `fetchCategory` (lines 24-75)
already does this right: `.from('categories').select().eq('id', categoryId).eq('language_code', locale)`,
then a **single**-locale `_taxonomyNames` (lines 169-184:
`.from('taxonomy_i18n').select('entity_id, name').inFilter('entity_id', entityIds).eq('locale', locale)`).
This works because, per the multilingual migration
(`20260910090100_multilingual_content_model.sql`, confirmed live): `categories`
has its own `language_code` (FK to `languages.code`); `subcategories` has
**no** language column of its own and inherits language purely via
`category_id → categories.language_code`; and `taxonomy_i18n` now has
exactly one row per entity (34 rows total = 7 categories + 27 subcategories,
confirmed live) — a category/subcategory is never multi-locale. `HomeApi`
needs to be brought up to this same shape, not invent a new one.
`ProfileApi._taxonomyNames` (`lib/features/profile/data/profile_api.dart:324-335`)
is a *third*, still-hardcoded-to-`'en'` copy of this same small lookup —
noted, not fixed, in Risks & rollout notes.

**Live content is genuinely sparse outside `en`/`ur` today** (confirmed via
`execute_sql`): `en` has 6 categories/26 subcategories/274 questions; `ur`
has 1 category/1 subcategory/51 questions; `hi`/`ar`/`fr`/`es` are all
`is_active = false` in `languages` and have zero categories — so they never
even appear in the picker (`LanguagesApi.fetchActiveLanguages` filters
`is_active = true`). This plan does not need to handle "an active language
with zero categories" as anything other than Home's pre-existing empty grid.

**Content-language selection is currently piggy-backing on `LocaleCubit`, and
requirement #5 explicitly ends that.** `lib/app/locale_cubit.dart`/
`locale_state.dart` drive `MaterialApp.locale` (`lib/app/app.dart:149-169`).
`lib/features/onboarding/presentation/screens/language_picker_screen.dart`'s
`_continue` (line 96-102) currently calls
`context.read<LocaleCubit>().select(Locale(code))` — which, for `code == 'ur'`
(one of only two `supportedLocales`), really does flip every UI string to
Urdu today. Per item 5 this must stop: picking a content language must never
change UI l10n. `LocaleCubit`'s own doc comment already names this coupling
as one of its "two honest limitations" for the mock-data phase; this plan
resolves it by giving content language an entirely separate home rather than
extending `LocaleCubit`.

**Every other content-language call site currently reads the *device*
locale, not any persisted pick** (`grep -rn "Localizations.localeOf(context).languageCode"`):
`home_screen.dart:59,566`, `quiz_play_screen.dart:80`,
`category_detail_screen.dart:39`, `level_map_screen.dart:51`,
`level_brief_sheet.dart:51`, `daily_result_screen.dart:32`,
`daily_screen.dart:35,416`, `duel_play_screen.dart:47`,
`language_picker_screen.dart:90` (the picker's own pre-selection fallback).
Every one of these already threads a `languageCode`/`locale` param into its
own Cubit's `load`/`start`/`play` call — the *API* layer for
daily/duel/quiz-play already accepts and uses this param correctly. Only the
*source* of the value needs to change.

**Reference pattern for a new app-root, fetched-once/cached repository**:
`core/ladder/ladder_config_repository.dart` + `ladder_config_api.dart`,
wired in `lib/app/app.dart`'s `_QuizooAppState` (constructed once, provided
via `RepositoryProvider.value`, best-effort-fetched in `initState` with
`.catchError((_) {})`). This plan's new `core/content_language/` pair mirrors
that shape.

**Reference pattern for a persisted, no-IO-in-the-Cubit preference**:
`lib/features/settings/data/settings_repository.dart` (sync
`shared_preferences` getter/setter, `unawaited` writes) +
`lib/features/settings/presentation/bloc/settings_cubit.dart`/`settings_state.dart`
(sealed state, single `SettingsLoaded` subclass, explicit doc comment on why
there's no loading/error state — CLAUDE.md §3's sealed-state rule applied to
a Cubit that does no IO). `lib/app/theme_cubit.dart`/`theme_state.dart` is
the matching app-root-Cubit version of the same idiom.

**Test-harness blast radius** (important — found by reading, not assumed):
`test/support/pump_screen.dart`'s `pumpScreen()` extension provides
`SessionCubit`, `ConnectivityCubit`, `AuthRepository`, `QuizPlayRepository`,
`SettingsRepository` at its own root, but nothing that would satisfy a
`context.read<ContentLanguageCubit>()` call. It's used by
`test/features/quiz_play/quiz_play_screen_test.dart` and
`test/features/home/home_screen_test.dart` — both of which pump screens this
plan edits to read the new Cubit. Without updating `pump_screen.dart`, both
suites break with a `ProviderNotFoundException`. `test/app/app_test.dart` and
`test/app/localization_test.dart` pump the real `QuizooApp` (which will wire
its own `ContentLanguageCubit` internally, same as it already does for
`SettingsRepository`/`LadderConfigRepository`), so they need no changes —
both are also already `skip: true`. No `*_api.dart` file in this codebase has
a dedicated unit test anywhere (`find test -name "*_api_test.dart"` is
empty) — only repositories (mocking their Api) and Cubits are unit-tested —
so `HomeApi`'s query fix is not expected to get a new automated test; that
matches existing project convention, not a gap introduced here.

## Assumptions & open questions

1. **Backend write is fire-and-forget, matching `SettingsRepository`'s own
   convention**, not awaited/surfaced like `AuthApi.createProfile`. The
   local write is synchronous and authoritative for the running app; the
   `profiles.locale` write happens in the background and a failure is
   swallowed (logged, not surfaced as a snackbar/error state). This mirrors
   `SettingsRepository.update`'s `unawaited(_preferences.setBool(...))` and
   `LadderConfigRepository`'s boot-time `.catchError((_) {})`. If the
   product actually wants a visible failure/retry affordance for the
   backend leg, that's a different, larger UX decision — flagging rather
   than deciding.
2. **Backend-wins reconciliation only fires at the moment a *signed-in*
   (non-anonymous) session resolves**, not at every cold boot. Reasoning
   in Design overview: a truly fresh install always creates a *new*
   anonymous session (`main.dart`), so local cache and that fresh
   anonymous profile's `locale` are trivially in sync; the only case where
   backend and local can legitimately diverge is a **returning** signed-in
   identity (same vendor account, different device/install), which can only
   resolve via `SessionCubit`'s sign-in-completion paths, never at cold
   boot on a fresh install. If this reasoning is wrong for some auth flow
   not covered here, the fallback is safe either way — the worst case is a
   stale local language rendering until the next explicit pick.
3. **The picker's pre-selection default changes from "the device's
   locale" to "the current content language (fallback `'en'`)"** —
   `language_picker_screen.dart`'s `_resolveSelected` (line 86-94) no
   longer has a reason to consult `Localizations.localeOf(context)` once
   content language is decoupled from UI locale. This loses the minor
   convenience of a Urdu-device user seeing Urdu pre-highlighted on their
   very first launch; flagging as a UX trade-off implied by item 5, not
   silently kept.
4. **Item 5 ("the app must show all text in English") is read narrowly**:
   this plan stops the *content-language picker* from ever touching UI
   l10n (closing the actual coupling that exists today). It does **not**
   additionally force `LocaleCubit`/`MaterialApp.locale` to hard-pin
   English regardless of the *device's own* OS-level locale — `LocaleSystem`
   (locale: null) still lets Flutter resolve UI strings to Urdu on a
   Urdu-OS device, exactly as today, since `ur` remains a `supportedLocales`
   entry. **Open question for a human to confirm**: does "must show all
   text in English" mean only "must not flip via the in-app picker" (this
   plan's reading), or "must never render non-English UI chrome under any
   circumstance, including a Urdu OS"? The latter is a materially bigger,
   separate change (dropping/ignoring device-locale resolution entirely,
   possibly removing Urdu from `supportedLocales`) that this plan does not
   make.
5. **`LocaleCubit` is left in place but becomes effectively unused** by any
   real user flow once its only real caller (`language_picker_screen.dart`)
   stops calling `.select()`. Not deleted — CLAUDE.md §10 discourages
   restructuring shared/app-root files beyond a single feature's needs, and
   `LocaleCubit`/`MaterialApp.locale` may still matter for a future,
   separate "actually translate the UI" effort. Flagging as dead-code-in-
   waiting rather than silently removing it.
6. **Search's content language is fixed at the moment `SearchScreen` is
   built**, not live-updated while the search screen is open (mirrors how
   `CategoryDetailScreen`/`LevelMapScreen` already read their `locale` once
   at `BlocProvider.create`). Search is a pushed route, not part of the
   persistent tab shell, so this matches existing precedent and is not a
   new limitation this plan introduces.

## Design overview

A new, app-root **content language** concept, kept structurally and
semantically separate from `LocaleCubit`:

```
core/content_language/
├── content_language_api.dart          # profiles.locale reads/writes over Supabase
└── content_language_repository.dart   # local shared_preferences cache + best-effort backend sync

lib/app/
├── content_language_cubit.dart        # app-root Cubit, mirrors theme_cubit.dart
└── content_language_state.dart        # sealed state, mirrors theme_state.dart / settings_state.dart
```

- `ContentLanguageRepository.current` is a **synchronous** `shared_preferences`
  read (fallback `'en'`) — exactly like `SettingsRepository.current` — so
  `ContentLanguageCubit`'s initial state is available at app construction
  with no network wait, keeping Splash's 1.2 s budget untouched.
- `ContentLanguageRepository.select(code)` awaits the local write (so
  `current` is correct the instant it returns), then fires-and-forgets a
  `profiles.locale` update in the background (Assumption 1).
- `ContentLanguageRepository.reconcileWithBackend()` fetches `profiles.locale`
  for the current auth user and returns it only if it differs from the local
  cache, updating the cache as a side effect; called once, from `app.dart`,
  via a `BlocListener<SessionCubit, SessionState>` that fires on a
  guest→signed-in transition (Assumption 2) — never from `initState`
  directly, so it never races the mandatory first-launch picker.
- `ContentLanguageCubit` is provided at the app root
  (`_QuizooAppState`'s `MultiBlocProvider`), exactly alongside
  `ThemeCubit`/`LocaleCubit`/`ConnectivityCubit`/`SessionCubit` — every
  content-fetching screen in the app is downstream of it, matching CLAUDE.md
  §3's stated exception for genuinely app-wide Cubits.
- **`HomeApi.fetchCachedHome`** gets `.eq('language_code', languageCode)`
  added to its `categories` query, and its `subcategories` query gets
  `.inFilter('category_id', categoryIds)` added (using the now-language-
  filtered `categoryIds`) — subcategories have no language column of their
  own, so constraining by their already-filtered parent categories is the
  only correct filter, exactly mirroring how `CatalogApi.fetchCategory`
  already does it. `_taxonomyNames` is simplified to the single-locale shape
  `CatalogApi` already uses.
- **`HomeScreen`**'s `BlocProvider<HomeCubit>` key becomes
  `ValueKey((isSignedIn, languageCode))` instead of `ValueKey(isSignedIn)` —
  the same "rebuild the Cubit fresh" idiom the file already uses for a
  session change, now also covering a language change. This is what
  satisfies spec item 4: the moment `ContentLanguageCubit` emits a new code
  (from Settings), `HomeScreen` rebuilds against a new key, a new `HomeCubit`
  is constructed, and `..load(...)` runs fresh against the new language —
  no manual `BlocListener`/refresh plumbing needed.
- Every other `Localizations.localeOf(context).languageCode` call site used
  for **content** (not UI l10n) is swapped for
  `context.read<ContentLanguageCubit>().state.code` (or `.watch` where the
  screen needs to react live, i.e. only `HomeScreen`).

## Implementation steps

### Phase 1 — Core content-language infrastructure (new files)

- [ ] Create `lib/core/content_language/content_language_api.dart`:
  ```dart
  class ContentLanguageApi {
    ContentLanguageApi(this._client);
    final SupabaseClient _client;

    Future<void> updateProfileLocale(String code) async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return; // best-effort; nothing to attach it to yet
      try {
        await _client.from('profiles').update({'locale': code}).eq('id', userId);
      } catch (error) {
        throw ApiException.fromSupabase(error);
      }
    }

    Future<String?> fetchProfileLocale() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      try {
        final row = await _client
            .from('profiles')
            .select('locale')
            .eq('id', userId)
            .maybeSingle();
        return row?['locale'] as String?;
      } catch (error) {
        throw ApiException.fromSupabase(error);
      }
    }
  }
  ```
- [ ] Create `lib/core/content_language/content_language_repository.dart`:
  ```dart
  class ContentLanguageRepository {
    ContentLanguageRepository(this._api, this._preferences);
    final ContentLanguageApi _api;
    final SharedPreferences _preferences;

    static const _key = 'content_language.code';
    static const fallback = 'en';

    String get current => _preferences.getString(_key) ?? fallback;

    Future<void> select(String code) async {
      await _preferences.setString(_key, code);
      unawaited(_api.updateProfileLocale(code).catchError((_) {}));
    }

    /// Best-effort: returns the backend's value only if it differs from the
    /// local cache (and adopts it locally too), null otherwise/on failure.
    Future<String?> reconcileWithBackend() async {
      try {
        final backend = await _api.fetchProfileLocale();
        if (backend == null || backend == current) return null;
        await _preferences.setString(_key, backend);
        return backend;
      } catch (_) {
        return null;
      }
    }
  }
  ```
- [ ] Create `lib/app/content_language_state.dart` (sealed, single concrete
      subclass, doc-commented like `settings_state.dart` on why there's no
      loading/error variant — `current` is synchronous, so there's nothing
      to be "loading"):
  ```dart
  part of 'content_language_cubit.dart';

  sealed class ContentLanguageState extends Equatable {
    const ContentLanguageState(this.code);
    final String code;
    @override
    List<Object?> get props => [code];
  }

  final class ContentLanguageLoaded extends ContentLanguageState {
    const ContentLanguageLoaded(super.code);
  }
  ```
- [ ] Create `lib/app/content_language_cubit.dart`:
  ```dart
  class ContentLanguageCubit extends Cubit<ContentLanguageState> {
    ContentLanguageCubit(this._repository)
        : super(ContentLanguageLoaded(_repository.current));

    final ContentLanguageRepository _repository;

    Future<void> select(String code) async {
      if (code == state.code) return;
      await _repository.select(code);
      if (!isClosed) emit(ContentLanguageLoaded(code));
    }

    Future<void> adoptFromBackend() async {
      final backend = await _repository.reconcileWithBackend();
      if (backend != null && !isClosed) emit(ContentLanguageLoaded(backend));
    }
  }
  ```

### Phase 2 — App-root wiring

- [ ] `lib/app/app.dart`: add imports for the three new files; add a field
      `late final ContentLanguageRepository _contentLanguageRepository = ContentLanguageRepository(ContentLanguageApi(supabase), widget.preferences);`
      alongside the existing `_settingsRepository` field (same constructor
      shape, same `widget.preferences` source); add
      `late final ContentLanguageCubit _contentLanguageCubit = ContentLanguageCubit(_contentLanguageRepository);`.
- [ ] Add `BlocProvider<ContentLanguageCubit>.value(value: _contentLanguageCubit)`
      to the existing `MultiBlocProvider.providers` list (next to
      `LocaleCubit`/`ThemeCubit`).
- [ ] Wrap the existing `ScreenUtilInit(...)` subtree in a
      `BlocListener<SessionCubit, SessionState>` that calls
      `unawaited(context.read<ContentLanguageCubit>().adoptFromBackend())`
      with `listenWhen: (previous, current) => current is SessionSignedIn && previous is! SessionSignedIn`
      (Assumption 2 — fires once per guest→signed-in transition, not on
      every rebuild).

### Phase 3 — Fix Home's language filtering (the core bug)

- [ ] `lib/features/home/data/home_api.dart`:
  - Add `.eq('language_code', languageCode)` to the `categories` query
    (line ~40, right after `.eq('is_active', true)`).
  - After computing `categoryIds`, add `.inFilter('category_id', categoryIds)`
    to the `subcategories` query (guard the case `categoryIds.isEmpty` by
    skipping the query and returning `<Map<String, dynamic>>[]`, since
    Postgrest's `inFilter` with an empty list behaves inconsistently across
    versions and an empty-categories language trivially has zero
    subcategories anyway).
  - Replace `_taxonomyNames` (lines 188-212) with the single-locale shape
    already proven in `CatalogApi._taxonomyNames` (lines 169-184): drop the
    `entityType` param and the `{locale, _defaultLocale}` union/fallback,
    filter purely by `entity_id`+`.eq('locale', languageCode)`. Call it once
    with `[...categoryIds, ...subcategoryIds]` instead of twice.
  - Remove the now-unused `static const String _defaultLocale = 'en';` field
    and its doc comment (line 14-16) — the comment's own premise ("until
    locale is threaded from LocaleCubit") is what this plan resolves.
- [ ] `lib/features/home/data/home_repository.dart`: change `search`'s
      signature to `Future<List<Subcategory>> search(String query, {required String languageCode})`
      and pass it through to `_api.fetchCachedHome(isSignedIn: false, languageCode: languageCode)`
      (replacing the hardcoded `'en'` at line 36).
- [ ] `lib/features/home/presentation/screens/home_screen.dart`:
  - Line 59: replace `final languageCode = Localizations.localeOf(context).languageCode;`
    with `final languageCode = context.watch<ContentLanguageCubit>().state.code;`
    (`watch`, not `read` — this is exactly the value the new `ValueKey` below
    needs to react to).
  - Line 63: change `key: ValueKey(isSignedIn)` to
    `key: ValueKey((isSignedIn, languageCode))`.
  - Line 566 (the error-state retry button): same one-line swap to
    `context.read<ContentLanguageCubit>().state.code`.

### Phase 4 — Thread content language into Search

- [ ] `lib/features/home/presentation/bloc/search_cubit.dart`: add a
      `required String languageCode` constructor param (final field,
      fixed for the Cubit's lifetime per Assumption 6); use it in `_search`:
      `await _repository.search(query, languageCode: languageCode)`.
- [ ] `lib/features/home/presentation/screens/search_screen.dart`: pass
      `languageCode: context.read<ContentLanguageCubit>().state.code` into
      `SearchCubit(...)`'s construction.

### Phase 5 — Swap every remaining device-locale-derived content call site

Each of these is a mechanical one-line source swap — the receiving
`load`/`start`/`play` call already accepts and correctly uses the
`languageCode`/`locale` param; only where the value comes from changes.

- [ ] `lib/features/catalog/presentation/screens/category_detail_screen.dart:39`:
      `Localizations.localeOf(context).languageCode` → `context.read<ContentLanguageCubit>().state.code`.
- [ ] `lib/features/catalog/presentation/screens/level_map_screen.dart:51`: same swap.
- [ ] `lib/features/catalog/presentation/widgets/level_brief_sheet.dart:51`: same swap.
- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart:80`: same swap.
- [ ] `lib/features/daily/presentation/screens/daily_result_screen.dart:32`: same swap.
- [ ] `lib/features/daily/presentation/screens/daily_screen.dart:35` and `:416`: same swap (both call sites).
- [ ] `lib/features/duel/presentation/screens/duel_play_screen.dart:47`: same swap.
- [ ] `lib/features/onboarding/presentation/screens/language_picker_screen.dart`:
  - Line 90 (`_resolveSelected`): replace the device-locale fallback with
    `context.read<ContentLanguageCubit>().state.code` (Assumption 3).
  - Lines 96-102 (`_continue`): remove
    `context.read<LocaleCubit>().select(Locale(code));`; replace with
    `await context.read<ContentLanguageCubit>().select(code);` (make
    `_continue` `async` and `await` it before `..markLanguageChosen()`/
    `context.go(AppRoutes.home)`, so the local cache is guaranteed correct
    before Home is reached — the backend leg stays fire-and-forget inside
    the repository per Assumption 1). Drop the now-unused
    `import 'package:quizoo/app/locale_cubit.dart';` and the `Locale`
    import if nothing else in the file needs it.

### Phase 6 — Test harness & new tests

- [ ] `test/support/pump_screen.dart`: add a
      `class FakeContentLanguageApi extends Mock implements ContentLanguageApi {}`
      next to the existing `FakeAuthApi`/`FakeQuizPlayApi`; add an optional
      `ContentLanguageCubit? contentLanguage` param to `pumpScreen`; build a
      default via a small `_fakeContentLanguageRepository()` helper mirroring
      `_fakeAuthRepository()` (its own `SharedPreferences.getInstance()` call
      placed after `pumpScreen`'s existing `setMockInitialValues({'settings.soundOn': false})`
      reset at line 56, so it reads an empty content-language key and
      defaults to `'en'` — matching `pumpApp`'s existing default
      `locale: Locale('en')`); add
      `BlocProvider<ContentLanguageCubit>.value(value: contentLanguage ?? default)`
      to the `MultiBlocProvider` list. This is required, not optional — without
      it, `quiz_play_screen_test.dart` and `home_screen_test.dart` break with
      `ProviderNotFoundException` the moment Phase 3/5's screens read the new
      Cubit.
- [ ] New `test/app/content_language_cubit_test.dart`, mirroring
      `test/app/theme_cubit_test.dart`'s shape with a
      `class _MockContentLanguageRepository extends Mock implements ContentLanguageRepository {}`:
  - initial state reflects `repository.current`.
  - `select(code)` (repository stubbed to succeed) emits
    `ContentLanguageLoaded(code)` and calls `repository.select(code)`.
  - `select(code)` with `code == state.code` emits nothing (dedupe).
  - `adoptFromBackend()` emits a new state when `repository.reconcileWithBackend()`
    resolves a non-null value; emits nothing when it resolves null.
- [ ] New `test/core/content_language/content_language_repository_test.dart`,
      mirroring `test/features/settings/settings_repository_test.dart`'s
      `SharedPreferences.setMockInitialValues({})` style, plus a
      `class _MockContentLanguageApi extends Mock implements ContentLanguageApi {}`:
  - `current` defaults to `'en'` with nothing cached.
  - `select(code)` persists locally (`current` reads it back) and calls
    `api.updateProfileLocale(code)` (verify via mocktail).
  - `select(code)` does not throw even when the mocked Api throws (fire-and-
    forget contract).
  - `reconcileWithBackend()` returns the backend value and updates `current`
    when the Api returns something different from the local cache; returns
    `null` and leaves `current` unchanged when the Api returns the same
    value, `null`, or throws.

## Data model / API changes

**N/A — no migration.** `profiles.locale` and its RLS update grant already
exist and are already live on the connected Supabase project (see Research
findings). This plan only adds Dart-side callers of an existing, already-
granted column.

## Dependencies

N/A. `shared_preferences` and `supabase_flutter` are already project
dependencies (`pubspec.yaml`), and every new file only uses what's already
imported elsewhere in the codebase for the identical pattern
(`core/ladder/`, `SettingsRepository`).

## Testing strategy

Matches this project's existing convention exactly (see Research findings):
`bloc_test` + `mocktail` for the two new Cubit/Repository pairs (Phase 6),
no new test for `HomeApi` itself (no `*_api_test.dart` exists anywhere in
this codebase — Api classes are exercised manually against the live/dev
Supabase project, not unit-tested). Existing `HomeCubit`/`SearchCubit`
`bloc_test`s in `test/features/home/home_cubit_test.dart` mock at the
`HomeRepository` boundary and pass `languageCode` values already — they
need **no changes**, since `HomeApi`'s internal query fix and
`SearchCubit`'s new constructor param don't change either Cubit's own
observable contract in a way those tests assert on (`SearchCubit`'s tests
construct it directly and will need `languageCode: 'en'` added to each
`SearchCubit(repository)` call to keep compiling — a mechanical update, not
a logic change).

## Edge cases & error handling

- **An active language with zero categories** (not true for `en`/`ur` today,
  but true for any language flipped `is_active = true` before its content is
  seeded): Home's grid renders empty via its existing empty-content path —
  no crash, no special-casing needed, matches how an empty
  `HomeContent.categories`/`subcategories` already renders.
- **`ContentLanguageApi` calls with no current auth user** (a 45-second
  anonymous-sign-in timeout per `main.dart`'s own bootstrap comment): both
  `updateProfileLocale`/`fetchProfileLocale` no-op/return null rather than
  throwing on a null `!` — the local pick still works immediately regardless.
- **Backend write races a subsequent, different pick** (user taps Urdu then
  immediately English again before the first background write lands): the
  local cache is authoritative for `current` at every point, and the last
  `select()` call's backend write is simply the last one to land — an
  eventually-consistent outcome, acceptable for a soft preference exactly
  like every other `unawaited`-persisted setting in this codebase.
- **`reconcileWithBackend` racing the mandatory first-launch picker**: cannot
  happen per Assumption 2 — reconciliation is gated on an actual sign-in
  completion, which cannot occur before the picker is shown on a genuinely
  fresh install (no stored session exists yet to restore).

## Acceptance criteria

- [ ] Picking a language on first launch (S-03) persists it to
      `shared_preferences` and (best-effort) to `profiles.locale`, and does
      **not** change any `AppLocalizations`-sourced UI string.
- [ ] Relaunching the app with no network available still shows the
      previously-picked language's categories/subcategories on Home (local
      cache, no network round trip required for `current`).
- [ ] Home's category chip row and subcategory grid show only the picked
      language's rows — verified against the live schema, only `en`-owned or
      only `ur`-owned rows ever render together, never mixed.
- [ ] Changing the language from Settings → S-03 → picking a different
      language lands back on Home already showing that language's content,
      with no manual pull-to-refresh needed.
- [ ] Search, Category detail, Level map, Quiz play, Daily, and Duel all
      request content in the same picked language as Home, not the device's
      OS language.
- [ ] No existing widget test (`quiz_play_screen_test.dart`,
      `home_screen_test.dart`, `force_update_screen_test.dart`,
      `pinned_self_row_test.dart`, `result_screen_test.dart`) regresses after
      `pump_screen.dart`'s update; `flutter analyze` and `dart format` stay
      clean per CLAUDE.md §8.

## Risks & rollout notes

- **`ProfileApi`'s stats-screen category-name lookup** (`profile_api.dart:324-335`)
  stays hardcoded to `'en'` after this plan — a pre-existing, separate gap,
  not introduced here, but now slightly more visible once Home correctly
  shows Urdu categories: a Urdu-content player's stats screen would still
  label a category in English. Worth a small follow-up plan, not bundled
  into this one (CLAUDE.md §10: don't restructure a shared/adjacent file
  beyond a single feature spec's needs).
- **`HomeApi`/`CatalogApi`/`ProfileApi` now have three independent copies**
  of the same small `taxonomy_i18n` single-locale lookup. Extracting a
  shared `core/` helper would be a reasonable follow-up, but is exactly the
  kind of "notice it, don't fix it here" case this skill calls out — flagged
  rather than done, since none of the three files strictly needs the others
  touched to satisfy this spec.
- **No rollback concern**: nothing here is a migration; reverting is a pure
  Dart-code revert with no data cleanup.
