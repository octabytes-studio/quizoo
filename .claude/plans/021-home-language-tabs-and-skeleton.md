# Home Language Tabs, Skeleton Fix & Hidden-When-Empty Popular Rail

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-10-01).
> Status: Implemented 2026-10-01 (uncommitted on `main`)

## How to use this plan

This plan is self-contained: you don't need any earlier conversation to
execute it. Read it in full before you start. It was written against `main` @
`b045a1e`, with a live-DB snapshot taken 2026-10-01. Code may have moved on
since then, so spot-check the files and symbols it references before changing
anything. **There's no database migration.** Everything is Flutter-side.

## Objective

Let players switch the quiz-content language straight from Home, using a row
of language pills pinned at the top of the screen. Right now they have to go
through Settings or Edit Profile. The row always leads with the player's
**default** language, which is the language the app launched with. Home only
loads that language's content on arrival. Any other language loads the first
time its pill is tapped. Tapping a pill makes that language the new persisted
default right away (Daily, Duels, Search and the level screens all follow it).
The pill order doesn't change until the **next cold launch**, so the row never
reshuffles under the player's finger.

The same change fixes two Home UI problems:
1. Home's skeleton doesn't look like the real layout, and it's nearly
   invisible in light theme.
2. The "🔥 Popular this week" section still shows when it has nothing in it.
   Today that's the case for **every language except English** (see the
   research findings).

## Scope

**In scope:**
- A pinned, horizontally scrolling row of language pills directly under
  Home's top bar (guest and signed-in), built from the live `languages`
  table.
- Pill order is the process's *lead* language first, then every other active
  language in `languages.sort_order`.
- Lazy per-language loading, plus an in-memory per-language cache for the
  life of Home's Cubit. Returning to a pill you've already visited is
  instant.
- Persisting the tapped language as the default (local `shared_preferences`
  plus a best-effort `profiles.locale` sync, the same way `select` works
  today) while keeping the pill order fixed until the next launch.
- A redesigned, shape-matched Home skeleton that only covers the content area.
  The top bar and the language row stay real chrome.
- New skeleton color tokens (light and dark) so skeletons show up on the
  light `--s0` background. `SkeletonBox` switches its defaults to them, which
  improves every skeleton in the app, not just Home's.
- Hiding the Popular section (header and rail) when its data comes back
  empty.
- An empty state for a language that has no categories at all (defensive;
  every live language has content today).
- Moving the shared `languages` data stack (`LanguageOption`,
  `LanguagesApi`, `LanguagesRepository`, `languageFlags`) from
  `features/onboarding` / `features/auth` into `core/content_language/`,
  because a fourth feature (Home) now needs it (see Assumption 1).
- Tests: `bloc_test` for the new and changed Cubits, plus widget tests for the
  new widgets and theme tokens.

**Out of scope:**
- Any Supabase schema or data change, including seeding
  `featured_quizzes` for non-English languages. That's content work, not code.
- Changing how Settings' language picker, onboarding's S-03, or Edit Profile's
  language sheet behave (they keep calling `ContentLanguageCubit.select`).
- Replacing the pre-existing `MockPlayer.currency` placeholder that
  `_HomeSkeleton`'s signed-in top bar shows before the first fetch (noted
  under Risks).
- Offline Home (S-46). It keeps its current full-screen layout with no language
  row, since switching language needs the network.
- The UI locale (`LocaleCubit`) is unaffected. Only the *content* language
  changes.

## Research findings

### Content language today (plan 008)
- `lib/app/content_language_cubit.dart` defines `ContentLanguageCubit`,
  provided at the app root (`lib/app/app.dart`, `BlocProvider.value` over
  a `late final _contentLanguageCubit`). The initial state is
  `ContentLanguageLoaded(_repository.current)`, which is synchronous.
  `select(code)` awaits `_repository.select(code)`, then emits.
  `adoptFromBackend()` runs once on a guest→signed-in transition (the
  `BlocListener<SessionCubit>` in `app.dart`).
- `lib/app/content_language_state.dart` is a sealed `ContentLanguageState`
  with a single `code` field. `ContentLanguageLoaded` is its only subclass.
- `lib/core/content_language/content_language_repository.dart`: `current`
  reads the prefs key `content_language.code` (fallback `'en'`). `select`
  writes prefs (awaited), then does
  `unawaited(_api.updateProfileLocale(code).catchError(...))`.
- Every content call site reads
  `context.read<ContentLanguageCubit>().state.code`. That includes Daily,
  Duels, Search, category detail, level map, level brief, and quiz play. So
  changing `code` automatically carries over to every other screen, which is
  exactly what "the system will mark Urdu as default" needs.

### Home today
- `lib/features/home/presentation/screens/home_screen.dart`:
  - `HomeScreen` wraps a `BlocProvider<HomeCubit>` with
    `key: ValueKey((isSignedIn, languageCode))`, where `languageCode` comes from
    `context.watch<ContentLanguageCubit>()`. So **any** content-language change
    throws away the Cubit and refetches from scratch. `HomeCubit` is created
    inline over `HomeRepository(HomeApi(supabase))`, and there's no injection
    seam.
  - `_HomeView` switches over `HomeState`. Each branch renders **its own**
    top bar: `_HomeSkeleton` renders `PlayerTopBar`/`GuestTopBar`,
    `_HomeContentView` renders them, and `_HomeError` renders none. That's why
    a language row has no single place to go today.
  - `_HomeContentView` builds `leading` widgets (Popular `SectionHeader` →
    `_PopularRail` → daily banner / `SaveProgressCard` → Continue), then
    `ListView.builder` over `content.sections` (`_CategorySection`).
    **Popular is added unconditionally.**
  - `_PopularRail` shows 3 `SkeletonBox`es while
    `state.isPopularRailLoading`, otherwise `PopularQuizCard`s. Its
    `firstWhere(..., orElse: () => content.subcategories.first)` would throw
    if `subcategories` were empty (that can't happen today because popular is
    scoped by subcategory ids).
  - `_HomeSkeleton` is a **full-width** 64h box, a 180w bar, one **full-width**
    `PopularQuizCard.height` box, then a title bar plus one full-width
    `SubcategoryCard.railHeight` box, twice. It doesn't match the real layout:
    there are no individual cards, no rail bleed, no section medallions, and no
    hairlines.
  - `_HomeOfflineView` (S-46) takes over the whole area when offline.
- `lib/features/home/presentation/bloc/home_cubit.dart`: `load({isSignedIn,
  languageCode})` does a two-stage paint. It emits `HomeLoading`, then the
  cached read → `HomeLoaded(isPopularRailLoading: true)`, then
  `fetchPopularRail` → `HomeLoaded`. A rail failure is swallowed.
  **There's no stale-request guard** (it never needed one, since the Cubit was
  recreated per language). **Nothing reloads Home after the first load**
  (grep: `HomeCubit.load` is only called in `create:` and in `_HomeError`'s
  retry), so a per-language cache adds no new staleness.
- `home_state.dart` has four states: `HomeInitial`, `HomeLoading`,
  `HomeLoaded({content, isPopularRailLoading})`, and `HomeError(ApiException)`.
- `lib/features/home/data/home_api.dart`: `fetchCachedHome` filters
  `categories.language_code`. `fetchPopularRail(subcategoryIds)` returns
  `const []` for no ids.
- The router (`lib/app/router.dart`) puts Home in a
  `StatefulShellRoute.indexedStack` branch, so Home **stays alive** across
  bottom-tab switches. A per-Cubit cache survives tab switches, but not a
  sign-in/out (the key changes).

### Live data (Supabase, 2026-10-01)
- `languages` has 6 active rows: `en`(1), `ur`(2, RTL), `hi`(3), `ar`(4, RTL),
  `fr`(5), `es`(6). The number in brackets is `sort_order`.
- Active content per language (categories / subcategories / active featured
  quizzes): `en` 6/26/**5**, `ur` 8/35/**0**, `hi` 8/39/**0**, `ar` 7/37/**0**,
  `fr` 7/37/**0**, `es` 7/33/**0**. **Only English has a Popular rail.** Every
  other language shows an empty "Popular this week" header today, which is
  UI fix #2.

### Languages list plumbing (to be promoted to core)
- `lib/features/onboarding/domain/language_option.dart` is the freezed
  `LanguageOption{code, name, nativeName, isRtl, sortOrder}` (plus
  `.freezed.dart` and `.g.dart`).
- `lib/features/onboarding/data/languages_api.dart` has
  `LanguagesApi.fetchActiveLanguages()`, which selects `languages` where
  `is_active` ordered by `sort_order`. `languages_repository.dart` is a
  pass-through.
- `lib/features/onboarding/presentation/bloc/language_picker_cubit.dart`
  (`LanguagePickerCubit`) is already imported **across features** by
  `features/auth/presentation/widgets/language_picker_sheet.dart`,
  `features/auth/presentation/screens/profile_creation_screen.dart` and
  `features/profile/presentation/screens/edit_profile_screen.dart`. That's an
  existing §10 deviation.
- `languageFlags` (a public `Map<String,String>`) lives in
  `features/auth/presentation/widgets/language_picker_sheet.dart` and is
  imported by `profile_creation_screen.dart` and `edit_profile_screen.dart`.
  Onboarding's `language_picker_screen.dart` has a private duplicate
  `_flags`.
- Full importer list, from a grep for `onboarding/data/languages_`,
  `onboarding/domain/language_option`, `language_picker_cubit`, and
  `language_picker_sheet.dart`: the six onboarding files themselves, the two
  auth files, `edit_profile_screen.dart`, and
  `test/features/onboarding/language_picker_cubit_test.dart`.

### Design system (`.claude/docs/quizoo-design-bible.html`)
- `.cat` chip: 36px tall, 14px horizontal padding, pill radius, `--s1` fill,
  1px `--ln` border, 12.5px/700 `--tx2` text. `.cat.on` inverts to a `--tx`
  fill with `--s1` text. `.cats` row: `gap: 8px; padding: 0 20px`, scrolls
  horizontally. This is **exactly** `AppChip` (category variant) in
  `lib/core/widgets/app_chip.dart`, with `AppChip.categoryHeight = 36`.
  Language pills should reuse it rather than invent a new pill.
- `.sk` skeleton: `linear-gradient(90deg, --s3 25%, --s2 50%, --s3 75%)`, 1.4s
  shimmer, shown after 300ms, shape-matched. S-45 (Home loading): "The tab bar
  and top bar are *never* skeletons". The S-45 frame shows a 62px/18r banner
  block, a 150w section-title bar, **two separate 172×132/20r popular cards
  bleeding off the rail**, then a section-title bar and tiles.
- Light tokens: `--s0` #F3F0FC (app background), `--s2` #F8F6FE, `--s3` #EDE8FA.
  **A `--s3` skeleton on the `--s0` background has a contrast of about
  1.07:1**, and the `--s2` highlight is *lighter* than the ground. That's
  why the light-theme skeleton looks invisible. Dark (`--s3` #181233 on `--s0`
  #120D25 with a #2A2154 sweep) reads fine.
- `SkeletonBox` (`lib/core/widgets/skeleton_box.dart`) defaults to
  `baseColor: quizoo.s3` and `highlightColor: quizoo.s2`, with
  `appearAfter = AppMotion.skeletonDelay` (300ms), and handles reduced motion.
  Callers that pass explicit colors, and so won't be affected by a default
  change: `profile_screen.dart` (white-alpha on a gradient) and
  `duel/.../challenge_feed.dart` (arena colors).
- Real dimensions to mirror: `PopularQuizCard.width/height` = 172/132
  (`AppRadius.card` 20). `SubcategoryCard.railWidth/railHeight` = 164/116
  (`AppRadius.tileAll` 18). `CategorySectionHeader.medallionSize` = 30
  (`AppRadius.medallion` 10). Home banner uses `AppRadius.card`.
  `AppSpacing`: xs 4, sm 8, md 12, base 16, lg 20, xl 24, xxl 32,
  screenMargin 20.
- `AppMotion.durationOf(context, d)` returns `Duration.zero` under reduced
  motion. `AppMotion.slide` is 260ms with `slideCurve` easeOutCubic.

### CLAUDE.md rules that bite here
- §3: sealed states with exhaustive `switch`, pure-Dart Cubits, each new Cubit
  paired with a `bloc_test` (initial, success, failure). `BlocProvider` goes
  as close as possible to where it's used.
- §2/§10: shared code used by 3+ features belongs in `core/`. New features
  don't modify other features' files. Shared `core/theme/*` files can only be
  **added to**.
- §5: no inline colors. New colors go in `core/theme/app_colors.dart`, and
  light and dark must be added together.
- §6: all sizes use `.w/.h/.r/.sp`, with no raw numeric padding.
- §7: extract widgets as classes, not `_buildX()` methods, and keep one public
  widget per file.
- §13: never run the app. Verification is static only, and the summary
  ends with "To verify:".

### Test conventions
- `test/features/home/home_cubit_test.dart` uses `_MockHomeRepository extends
  Mock implements HomeRepository` and `blocTest` with `isA<>().having(...)`.
  It also holds the `HomeContent.sections`, `SearchCubit` and `HomeRepository`
  groups.
- `test/app/content_language_cubit_test.dart` uses
  `_MockContentLanguageRepository`, and expects `const
  ContentLanguageLoaded('ur')`.
- `test/support/pump_screen.dart`: `pumpScreen(widget, {brightness,
  contentLanguage, session, ...})` provides app-root Cubits.
  `SharedPreferences.setMockInitialValues` is used.
- `home_screen_test.dart` notes that `HomeScreen` can't be given fake data
  (it builds `HomeApi(supabase)` inline, and the placeholder client fails
  fast). That's why the new UI pieces below are extracted into
  **public widgets that take plain data** and are widget-tested directly.
- Memory note (`feedback_flutter_test_timing`): a loading branch must animate
  something (a skeleton or spinner), otherwise `pumpAndSettle` exits early.
  Also, `mocktail` `.thenThrow` on an async method throws synchronously. Use
  `.thenAnswer((_) async => throw …)` when the failure has to happen inside
  the Future.
- `bloc_test`'s `MockCubit`/`whenListen` are already in use (e.g.
  `test/features/duel/*_screen_test.dart`).

## Assumptions & open questions

1. **Promote the `languages` stack to `core/` (CLAUDE.md tension, flagged).**
   Home is the 4th feature that needs the language list. §2/§10 say this
   belongs in `core/`, but §10 also says a new feature shouldn't touch other
   features' files. The plan **moves** the files and only updates imports in
   onboarding, auth and profile, which is a mechanical change with no
   behavior change. *Alternative, if the developer rejects the move:* Home
   imports `features/onboarding/...` directly, following the precedent auth
   and profile already set. Phase 1 is the only phase that changes if this
   decision flips.
2. **"Top-most section" means directly under the top bar, pinned.** The top
   bar (avatar, wallet, search) is chrome per bible S-45. The pills sit
   immediately below it and **don't scroll away**, so switching is always one
   tap away. *If the developer literally meant above the top bar,* only the
   order of two children in `_HomeView`'s `Column` changes.
3. **Which actions reorder the pills.** Only a **Home pill tap** keeps the
   order frozen. An explicit change of default elsewhere (Settings → Language,
   onboarding S-03, Edit Profile's language sheet, and the backend
   `profiles.locale` adopted on sign-in) re-pins the new language first
   straight away. Those are deliberate "change my default" actions, and the
   player comes back to Home from a different screen, so the "row reshuffles
   under my finger" confusion doesn't apply. *Open question:* confirm this
   is wanted. If the pills should stay frozen for the whole process no matter
   what, `select`/`adoptFromBackend` also have to preserve `leadCode` (a
   one-line change in each).
4. **Pill label = flag + native name** (e.g. "🇵🇰 اردو", "🇮🇳 हिन्दी"). This
   matches S-03 and the Edit Profile sheet, and a language switcher shows a
   language in its own script so a speaker of it can find it. The screen-reader
   label spells it out ("Show quizzes in Urdu").
5. **No confirmation toast on tap.** The spec asks for "simple and
   straightforward". The selected pill's inverted fill is the feedback.
   *Open question:* switching also changes the language of Daily, Duels and
   Search. If the developer wants that made explicit, an info-intent
   `AppSnackbar` ("Urdu is now your quiz language") could fire from the
   `BlocListener` once per session. It isn't included by default.
6. **Languages with no content still get a pill.** All 6 active languages have
   content today. If one ever doesn't, Home shows an empty state under the
   row instead of hiding the pill. Activation is controlled by
   `languages.is_active`, not by the app.
7. **The row hides when fewer than 2 languages are active, or when the list
   fails to load.** Home stays fully usable, and Settings is still a way to
   change language. A load failure is retried the next time Home's Cubits are
   created, or by the error view's Retry.
8. **Skeleton tokens are an additive deviation from the bible's `.sk`
   (`--s3`/`--s2`).** The bible's own light values give ~1.07:1 against
   `--s0`, which is the reported bug. New `skeleton`/`skeletonHighlight`
   tokens are added (the dark values equal today's `--s3`/`--s2`, so **dark
   looks exactly the same**). `SkeletonBox` switches its defaults to them. That
   makes **every** light-theme skeleton in the app more visible, not just
   Home's, which is intended because the cause is the same everywhere. Callers
   with explicit colors are unaffected.
9. **Popular collapses after loading.** The rail can't know it's empty until
   the network returns. While loading, the popular skeleton shows. If the
   result is empty, the section collapses with an `AnimatedSize` (260ms, or
   instantly under reduced motion) instead of vanishing abruptly.
10. **The per-language cache lives for the Cubit's lifetime and is
    in-memory only.** It's dropped on sign-in/out (the Cubit is recreated)
    and on cold start. This matches today's semantics, where Home never
    reloads after its first load.

## Design overview

```
ContentLanguageCubit (app root)
  state: ContentLanguageLoaded(code, leadCode)
    code      = the current content language (persisted default)
    leadCode  = the language Home pins first for THIS process
  select(code)     -> persist; emit(code, leadCode: code)      // explicit change
  switchTo(code)   -> persist; emit(code, leadCode: unchanged) // Home pill tap
  adoptFromBackend -> emit(backend, leadCode: backend)
  (cold start: code = leadCode = prefs value → next launch leads with last pick)

HomeScreen
  BlocBuilder<SessionCubit> (unchanged buildWhen)
   └ MultiBlocProvider(key: ValueKey(isSignedIn))
       ├ HomeCubit(HomeRepository(HomeApi(supabase)))..load(code)
       └ HomeLanguageTabsCubit(LanguagesRepository(LanguagesApi(supabase)))..load(leadCode)
      └ MultiBlocListener<ContentLanguageCubit>
          ├ listenWhen code changed     -> HomeCubit.load(isSignedIn, code)
          └ listenWhen leadCode changed -> HomeLanguageTabsCubit.pinLead(leadCode)
         └ _HomeView
             if offline && HomeLoaded -> _HomeOfflineView (unchanged, full-area)
             else Column[
               _HomeTopBar            (reads HomeState → real/previous wallet)
               HomeLanguageBar        (tabs cubit state + ContentLanguageCubit.code)
               Expanded(AnimatedSwitcher(
                 HomeInitial/Loading → HomeContentSkeleton
                 HomeError           → _HomeError (retry)
                 HomeLoaded          → _HomeContentView (PageStorageKey per language)
               ))
             ]
```

**Why a single long-lived `HomeCubit` instead of today's per-language key?**
It makes the per-language cache possible, and it keeps the top bar and pill row
mounted during a switch. Only the body swaps. `HomeCubit.load` becomes
cache-aware and **stale-guarded**: a slow Urdu response arriving after the
player has already tapped Hindi is dropped.

**Why a separate `HomeLanguageTabsCubit`?** Ordering (lead first, then
`sort_order`) is business logic that belongs in a Cubit, not in `build()`
(§1). It also has its own loading/error lifecycle that's independent of the
content, and it's pure and unit-testable.

**Chrome vs body.** The top bar and pill row render in *every* non-offline
state, so the player can switch away from a failed or empty language. The
body cross-fades (`AnimatedSwitcher`, `AppMotion.slide`, reduced-motion aware)
between skeleton, error and content. It's keyed by `(state kind, languageCode)`.

## Implementation steps

### Phase 1 — Promote the languages stack to `core/content_language/`
- [ ] `git mv` these files (keep their contents, and fix only the `package:`
      imports inside them):
  - `lib/features/onboarding/domain/language_option.dart` (and its
    `.freezed.dart` and `.g.dart`) → `lib/core/content_language/language_option.dart`
    (+ generated siblings). The `part` directives are relative, so they stay
    valid.
  - `lib/features/onboarding/data/languages_api.dart` →
    `lib/core/content_language/languages_api.dart`
  - `lib/features/onboarding/data/languages_repository.dart` →
    `lib/core/content_language/languages_repository.dart`
- [ ] Create `lib/core/content_language/language_flags.dart` holding the
      public `const Map<String, String> languageFlags` (moved verbatim from
      `language_picker_sheet.dart`, doc comment updated to say it's the one
      shared flag lookup). Remove the map from `language_picker_sheet.dart`.
- [ ] Update imports only in: `features/onboarding/presentation/bloc/
      language_picker_cubit.dart`, `.../language_picker_state.dart` (a `part`
      file, so the import goes in the cubit), `features/onboarding/
      presentation/screens/language_picker_screen.dart`, `features/auth/
      presentation/widgets/language_picker_sheet.dart`,
      `features/auth/presentation/screens/profile_creation_screen.dart`,
      `features/profile/presentation/screens/edit_profile_screen.dart`, and
      `test/features/onboarding/language_picker_cubit_test.dart`. Onboarding's
      private `_flags` duplicate may be swapped for `languageFlags`. That's
      optional, and harmless if left alone.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` so the
      moved freezed part files regenerate cleanly, then `dart analyze`.
      Commit Phase 1 on its own if convenient (a pure move).

### Phase 2 — `ContentLanguageCubit`: lead language
- [ ] `lib/app/content_language_state.dart`: add `final String leadCode;` to
      the sealed base (`const ContentLanguageState(this.code, this.leadCode)`,
      `props => [code, leadCode]`), with a doc comment explaining that it's
      the language Home's pill row pins first for this process, frozen across
      Home pill taps and re-pinned by explicit default changes (plan 021).
      Subclass:
      `const ContentLanguageLoaded(String code, {String? leadCode}) :
      super(code, leadCode ?? code);`. Existing `ContentLanguageLoaded('ur')`
      call sites and tests still compile and mean lead = code.
- [ ] `lib/app/content_language_cubit.dart`:
  - The constructor stays `ContentLanguageLoaded(_repository.current)`, so
    lead equals the launch default.
  - `select(code)`: unchanged. It emits `ContentLanguageLoaded(code)`, so lead
    follows. Also update the guard: `if (code == state.code && code ==
    state.leadCode) return;`. That way picking the current language in
    Settings after pill-switching still re-pins it.
  - Add `Future<void> switchTo(String code)`. If `code == state.code`, return.
    Otherwise `await _repository.select(code)`, then
    `if (!isClosed) emit(ContentLanguageLoaded(code, leadCode: state.leadCode))`.
    Doc: "Home's pill tap. Persists exactly like [select] (so the next cold
    launch leads with [code]) but leaves [ContentLanguageState.leadCode]
    alone, so the row does not reorder under the player's finger (plan 021)."
  - `adoptFromBackend`: unchanged (emits `ContentLanguageLoaded(backend)`,
    so lead follows).

### Phase 3 — Theme tokens and `SkeletonBox` visibility
- [ ] `lib/core/theme/app_colors.dart` (additive only): add, next to each
      theme's neutrals, with doc comments explaining the ~1.07:1 `--s3`-on-
      `--s0` problem:
  - `lightSkeleton = Color(0xFFDDD5F2)` (≈1.26:1 on `--s0`, visibly a
    placeholder but still quieter than `--tx3`)
  - `lightSkeletonHighlight = Color(0xFFECE7FA)`
  - `darkSkeleton = Color(0xFF181233)` (same as `darkS3`, so dark is unchanged)
  - `darkSkeletonHighlight = Color(0xFF2A2154)` (same as `darkS2`)
  The light hex values are a starting point. Tune them by eye if needed, but keep
  `lightSkeleton`'s contrast ratio against `lightS0` ≥ 1.2 (a test enforces this).
- [ ] `lib/core/theme/quizoo_colors.dart`: add `required this.skeleton,
      required this.skeletonHighlight` fields (documented as "skeleton sweep
      base / highlight — a dedicated pair because `--s3` vanishes on light
      `--s0` (plan 021)"). Wire them into `light`/`dark`, `copyWith`, and
      `lerp`. Search `lib/` and `test/` for other `QuizooColors(` constructor
      calls and add the two args to each.
- [ ] `lib/core/widgets/skeleton_box.dart`: the defaults become
      `quizoo.skeleton` / `quizoo.skeletonHighlight`. Update the `baseColor` and
      `highlightColor` doc comments. No other behavior changes.

### Phase 4 — `AppChip` semantic label (additive)
- [ ] `lib/core/widgets/app_chip.dart`: add an optional `final String?
      semanticLabel;` to the default constructor (not to `.status`). In the
      tappable branch, `Semantics(label: semanticLabel ?? label, ...)`, and
      wrap the chip in `ExcludeSemantics` when `semanticLabel != null` so the
      visible native-script text isn't read twice. Default behavior doesn't
      change.

### Phase 5 — Home language tabs (new Cubit and widget)
- [ ] `lib/features/home/presentation/bloc/home_language_tabs_state.dart`
      (`part of 'home_language_tabs_cubit.dart'`): a sealed
      `HomeLanguageTabsState extends Equatable`:
  - `HomeLanguageTabsLoading`
  - `HomeLanguageTabsLoaded(List<LanguageOption> languages)`, **already
    ordered** for display
  - `HomeLanguageTabsError(ApiException error)`, with props
    `[error.kind, error.message]` (the same pattern as `HomeError`)
- [ ] `lib/features/home/presentation/bloc/home_language_tabs_cubit.dart`:
  ```dart
  class HomeLanguageTabsCubit extends Cubit<HomeLanguageTabsState> {
    HomeLanguageTabsCubit(this._repository)
        : super(const HomeLanguageTabsLoading());
    final LanguagesRepository _repository;
    List<LanguageOption> _all = const [];
    String _leadCode = ContentLanguageRepository.fallback;

    Future<void> load({required String leadCode}) async { /* emit Loading,
      fetchActiveLanguages, on ApiException emit Error; else _all = result;
      emit Loaded(orderForTabs(_all, _leadCode)) — isClosed guards */ }

    void pinLead(String leadCode) { _leadCode = leadCode;
      if (state is HomeLanguageTabsLoaded) emit(Loaded(orderForTabs(_all, leadCode))); }

    /// Lead first (if present), then the rest in `sortOrder`. A lead that is
    /// not an active language leaves the list in plain `sortOrder`.
    @visibleForTesting
    static List<LanguageOption> orderForTabs(List<LanguageOption> all, String leadCode);
  }
  ```
  `orderForTabs` sorts a copy by `sortOrder` and doesn't trust the API's
  order.
- [ ] `lib/features/home/presentation/widgets/home_language_bar.dart`: the
      public `HomeLanguageBar` (a `StatelessWidget`, `const`):
  - `BlocBuilder<HomeLanguageTabsCubit, HomeLanguageTabsState>`, plus
    `context.select((ContentLanguageCubit c) => c.state.code)` for the
    selected pill. It switches exhaustively:
    - `HomeLanguageTabsLoading()` → `_LanguagePillSkeletonRow`: 3
      `SkeletonBox`es with pill radius (`AppRadius.pillAll`), height
      `AppChip.categoryHeight.h`, widths `_skeletonPillWidths = [96, 84, 104]`
      (`static const`, each `.w`), and gap `AppSpacing.sm.w`.
    - `HomeLanguageTabsError()` → `const SizedBox.shrink()`
    - `HomeLanguageTabsLoaded(:final languages) when languages.length < 2` →
      `const SizedBox.shrink()`
    - `HomeLanguageTabsLoaded(:final languages)` → `_LanguagePillRow`
  - `_LanguagePillRow`: a `SizedBox(height: AppChip.categoryHeight.h)` holding
    `ListView.separated(scrollDirection: Axis.horizontal, padding:
    EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
    separatorBuilder: SizedBox(width: AppSpacing.sm.w))`. Each item is
    `AppChip(label: language.nativeName, leading: languageFlags[language.code]
    ?? '🌐', isSelected: language.code == selectedCode, semanticLabel:
    l10n.homeLanguageTabSemantics(language.name), onTap: () =>
    context.read<ContentLanguageCubit>().switchTo(language.code))`. RTL
    mirroring comes for free from `ListView`.
  - Outer `Padding(padding: EdgeInsets.only(bottom: AppSpacing.md.h))` so
    there's a gap before the body. When the bar collapses to `SizedBox.shrink`,
    the padding should collapse too, so apply it inside the visible branches.

### Phase 6 — `HomeCubit`: cache and stale guard
- [ ] `home_state.dart`:
  - `HomeLoading({this.previous})`: `final HomeContent? previous;` (the last
    content shown, so the top bar keeps the real wallet during a language
    switch), with props `[previous]`.
  - `HomeLoaded({required this.languageCode, required this.content,
    this.isPopularRailLoading = false})`: add `languageCode` to the fields,
    `copyWith`, and `props`.
  - `HomeError(this.error, {this.previous})`, with props
    `[error.kind, error.message, previous]`.
- [ ] `home_cubit.dart`:
  ```dart
  final Map<String, HomeContent> _cache = {};
  HomeContent? _lastShown;
  String? _requestedCode;
  bool _isStale(String code) => isClosed || _requestedCode != code;

  Future<void> load({required bool isSignedIn, required String languageCode}) async {
    _requestedCode = languageCode;
    if (_cache[languageCode] case final hit?) {
      _show(HomeLoaded(languageCode: languageCode, content: hit));
      return;
    }
    final previous = _lastShown;
    emit(HomeLoading(previous: previous));
    // cached leg → on ApiException: if (!_isStale) emit(HomeError(e, previous: previous)); return
    // if (_isStale(languageCode)) return;  _show(Loaded(rail loading: true))
    // rail leg → content = cached.copyWith(popular: popular) | on ApiException content = cached
    // if (_isStale(languageCode)) return;  _cache[languageCode] = content; _show(Loaded(content))
  }
  void _show(HomeLoaded s) { _lastShown = s.content; emit(s); }
  ```
  Update the class doc comment to cover the cache ("per-language, Cubit
  lifetime, see plan 021 Assumption 10") and the stale guard. Retry
  (`_HomeError`) calls `load` again. Errors are never cached, so it refetches.

### Phase 7 — Popular section (extracted and hidden when empty)
- [ ] `lib/features/home/presentation/widgets/home_popular_section.dart`: the
      public `HomePopularSection({required List<PopularQuiz> popular, required
      bool isLoading, required VoidCallback onSeeAll, required
      ValueChanged<PopularQuiz> onQuizTap})`. It takes over `_PopularRail`'s
      body plus the `SectionHeader` and the trailing `SizedBox(height:
      AppSpacing.lg.h - 2.h)`:
  - `final isVisible = isLoading || popular.isNotEmpty;`
  - `AnimatedSize(duration: AppMotion.durationOf(context, AppMotion.slide),
    curve: AppMotion.curveOf(context, AppMotion.slideCurve), alignment:
    AlignmentDirectional.topStart, child: isVisible ? Column(header, gap,
    rail, trailing gap) : const SizedBox(width: double.infinity))`
  - Rail items are unchanged: 3 `SkeletonBox`es while `isLoading`, otherwise a
    `PopularQuizCard(onTap: () => onQuizTap(quiz))`.
- [ ] In `home_screen.dart`, delete `_PopularRail`. The subcategory lookup for
      navigation moves into `_HomeContentView`'s `onQuizTap`. Keep the
      existing `firstWhere … orElse` behavior, but guard for empty
      `subcategories` by returning early. That's defensive only, because a
      non-empty rail implies non-empty subcategories.

### Phase 8 — New skeleton
- [ ] `lib/features/home/presentation/widgets/home_content_skeleton.dart`:
      the public `HomeContentSkeleton` (`const`). It covers the **body only**
      (chrome is real) and mirrors `_HomeContentView` exactly, following bible
      S-45:
  ```
  ListView(physics: NeverScrollableScrollPhysics(), padding: EdgeInsets.zero, children: [
    Padding(h: screenMargin) → SkeletonBox(width: 150.w, height: 16.h)          // "🔥 Popular this week"
    SizedBox(height: AppSpacing.md.h)
    _SkeletonRail(PopularQuizCard.width, PopularQuizCard.height, AppRadius.cardAll)
    SizedBox(height: AppSpacing.lg.h - 2.h)
    Padding(h: screenMargin) → SkeletonBox(height: bannerHeight.h, borderRadius: AppRadius.cardAll)
    _SkeletonCategorySection(isFirst: true)
    _SkeletonCategorySection(isFirst: false)
  ])
  ```
  - `static const double bannerHeight = 62;` (bible S-45's banner block).
  - `_SkeletonRail`: `SizedBox(height: itemHeight.h)` holding
    `ListView.separated(scrollDirection: Axis.horizontal, physics:
    NeverScrollableScrollPhysics(), padding: symmetric(horizontal:
    AppSpacing.screenMargin.w), itemCount: 3, separator:
    SizedBox(width: AppSpacing.md.w))` of fixed-size `SkeletonBox`es. The
    third card bleeds off-screen, exactly like the real rails.
  - `_SkeletonCategorySection`: the same spacing as `_CategorySection`
    (`isFirst ? lg-2 : md` top gap, and for non-first sections the `quizoo.ln`
    1px hairline plus an `md` gap). Then a header row `Padding(h: screenMargin)`
    → `Row[SkeletonBox(CategorySectionHeader.medallionSize.w square, radius
    AppRadius.medallion.r), SizedBox(sm), SkeletonBox(width: 120.w, height:
    16.h), Spacer(), SkeletonBox(width: 56.w, height: 12.h)]`, an `md` gap,
    and `_SkeletonRail(SubcategoryCard.railWidth, SubcategoryCard.railHeight,
    AppRadius.tileAll)`.
- [ ] Delete `_HomeSkeleton` from `home_screen.dart`.

### Phase 9 — Restructure `home_screen.dart`
- [ ] `HomeScreen.build`: keep the `BlocBuilder<SessionCubit>` and its
      `buildWhen` exactly as they are. Replace the single `BlocProvider` with
      `MultiBlocProvider(key: ValueKey(isSignedIn), providers: [HomeCubit …
      ..load(isSignedIn:, languageCode: context.read<ContentLanguageCubit>()
      .state.code), HomeLanguageTabsCubit(LanguagesRepository(LanguagesApi(
      supabase)))..load(leadCode: context.read<ContentLanguageCubit>().state
      .leadCode)])`. **Remove** the `context.watch<ContentLanguageCubit>()`
      (it's what used to recreate Home on each language change). Update the
      comment that cites plan 008.
- [ ] Wrap `_HomeView` in a `MultiBlocListener`:
  - `BlocListener<ContentLanguageCubit, ContentLanguageState>(listenWhen:
    (a, b) => a.code != b.code, listener: (context, state) =>
    context.read<HomeCubit>().load(isSignedIn: isSignedIn, languageCode:
    state.code))`
  - `BlocListener<ContentLanguageCubit, ContentLanguageState>(listenWhen:
    (a, b) => a.leadCode != b.leadCode, listener: (context, state) =>
    context.read<HomeLanguageTabsCubit>().pinLead(state.leadCode))`
- [ ] `_HomeView.build`: `BlocBuilder<HomeCubit, HomeState>` at the top. If
      `isOffline && state is HomeLoaded`, return `_HomeOfflineView(state:)`
      unchanged. Otherwise return a `Column`:
  1. `_HomeTopBar(session: session, state: state, onSearchPressed: …)`, a new
     private widget. It resolves `HomeContent? content = switch (state) {
     HomeLoaded(:final content) => content, HomeLoading(:final previous) =>
     previous, HomeError(:final previous) => previous, HomeInitial() => null }`
     (exhaustive), then:
     - signed-in and `content?.currency != null` → `PlayerTopBar` with the
       real values (today's loaded behavior)
     - signed-in and `content == null` → today's `_HomeSkeleton` top bar
       (`MockPlayer.currency`, streak/level 0), kept as-is
     - otherwise → `GuestTopBar`. This matches today's rule that a signed-in
       session whose content has no currency falls back to the guest bar.
  2. `const HomeLanguageBar()`
  3. `Expanded(child: AnimatedSwitcher(duration: AppMotion.durationOf(context,
     AppMotion.slide), child: KeyedSubtree(key: ValueKey(<kind + language>),
     child: switch (state) { HomeInitial() || HomeLoading() => const
     HomeContentSkeleton(), HomeError(:final error) => _HomeError(error:
     error), HomeLoaded() => _HomeContentView(...) })))`. The key is built
     from `state.runtimeType`, plus `languageCode` for `HomeLoaded`.
- [ ] `_HomeContentView`: remove its own top bar, since chrome is hoisted.
      Replace the Popular `SectionHeader`, `_PopularRail` and the gap with
      `HomePopularSection(...)`. Give the `ListView.builder`
      `key: PageStorageKey<String>('home-content-${state.languageCode}')` so
      each language keeps its own scroll offset and a new language starts at
      the top. If `content.sections.isEmpty`, append one extra item:
      `Padding(padding: EdgeInsets.only(top: AppSpacing.xxl.h), child:
      SizedBox(height: _emptyHeight.h, child: EmptyStateView(emoji: '🌱',
      title: l10n.homeLanguageEmptyTitle, message:
      l10n.homeLanguageEmptyBody)))`, with `static const double _emptyHeight =
      280`. The bounded height is needed because `EmptyStateView` contains a
      `SingleChildScrollView`. The language names aren't parameterized here,
      because `_HomeContentView` has no `LanguageOption`. Keep the copy
      generic (see Phase 10).
- [ ] `_HomeError`: it now sits under the chrome instead of full-screen. Keep
      `Center(ErrorStateView…)`. Retry calls `HomeCubit.load(...)` as today,
      **and** `context.read<HomeLanguageTabsCubit>().load(leadCode: …)` if the
      tabs state is `HomeLanguageTabsError`.
- [ ] Remove imports that are now unused (`skeleton_box.dart`,
      `section_header.dart` if `_HomeOfflineView` no longer needs it (it does,
      so keep that one), `popular_quiz_card.dart` if unused, and so on). Let
      `dart analyze` guide this.
- [ ] Update the class and method doc comments that describe the old layout
      (`HomeScreen`'s key comment, the S-45 note).

### Phase 10 — l10n
- [ ] `lib/l10n/app_en.arb` (with `@` metadata/placeholders like the
      neighbors):
  - `"homeLanguageTabSemantics": "Show quizzes in {language}"` (placeholder
    `language: String`)
  - `"homeLanguageEmptyTitle": "Quizzes are on the way"`
  - `"homeLanguageEmptyBody": "Nothing in this language yet. Pick another one above to keep playing."`
- [ ] `lib/l10n/app_ur.arb`:
  - `"homeLanguageTabSemantics": "{language} میں کوئز دکھائیں"`
  - `"homeLanguageEmptyTitle": "کوئز جلد آ رہے ہیں"`
  - `"homeLanguageEmptyBody": "اس زبان میں ابھی کچھ نہیں۔ کھیلتے رہنے کے لیے اوپر سے کوئی اور زبان چنیں۔"`
- [ ] Regenerate: `flutter gen-l10n`, or let the build do it. Check that
      `lib/l10n/untranslated_messages.json` doesn't gain the new keys.

### Phase 11 — Tests (see Testing strategy), then static verification
- [ ] `dart format lib test` and `dart analyze` must report zero issues. Then
      run the full `flutter test`. **Don't run the app** (CLAUDE.md §13).

## Data model / API changes

- **No database or API changes.** The `languages` query (`is_active`, ordered
  by `sort_order`) and `profiles.locale` write already exist.
- Client-side state shape changes:
  - `ContentLanguageState` gains `leadCode`.
  - `HomeLoading.previous`, `HomeError.previous`, and `HomeLoaded.languageCode`
    are new.
  - `QuizooColors` gains `skeleton` and `skeletonHighlight`. `AppColors` gains
    4 constants.
  - `AppChip` gains an optional `semanticLabel`.
- File moves: 3 onboarding files (+2 generated) and the `languageFlags` map
  go to `lib/core/content_language/`.

## Dependencies

N/A. Everything used (`flutter_bloc`, `bloc_test`, `mocktail`, `freezed`,
`shared_preferences`, `flutter_screenutil`) is already in `pubspec.yaml`.

## Testing strategy

These follow the existing conventions (mocktail `Mock implements …`,
`blocTest` with `isA<>().having`, and `pumpScreen` from
`test/support/pump_screen.dart`).

- **`test/app/content_language_cubit_test.dart`** (extend):
  - the initial state has `leadCode == code == repository.current`
  - `switchTo('ur')` emits `ContentLanguageLoaded('ur', leadCode: 'en')` and
    verifies `repository.select('ur')`
  - `switchTo` to the current code emits nothing
  - `select('ur')` after `switchTo('hi')` emits lead `'ur'`
  - `select(current)` while `leadCode != code` re-pins (emits
    `ContentLanguageLoaded(code)`)
  - `adoptFromBackend` sets the lead to the backend value
  - **Next-launch behavior:** a new `ContentLanguageCubit` built after
    `switchTo('ur')` (with the mock's `current` now returning `'ur'`) starts
    with lead `'ur'`
- **`test/features/home/home_language_tabs_cubit_test.dart`** (new):
  - the initial state is `HomeLanguageTabsLoading`
  - success: `load(leadCode: 'hi')` over `en(1), ur(2), hi(3)` emits
    `[Loading, Loaded([hi, en, ur])]`
  - failure: the repository throws `ApiException.network()` (use
    `thenAnswer((_) async => throw …)`), which emits `[Loading, Error]`
  - `pinLead('ur')` after a load reorders to `[ur, en, hi]`. `pinLead` while
    in Loading or Error emits nothing
  - `orderForTabs`: a lead missing from the list leaves plain `sortOrder`, and
    an input that isn't in `sortOrder` is still sorted
- **`test/features/home/home_cubit_test.dart`** (update and extend):
  - update the existing expectations for the new `languageCode` field and
    `HomeLoading(previous:)`
  - **cache hit:** `load('en')` then `load('ur')` then `load('en')`. The last
    one emits a single `HomeLoaded(languageCode: 'en')` and
    `verify(fetchCachedHome(languageCode: 'en')).called(1)`
  - **stale guard:** use a `Completer` for `'ur'`, call `load('ur')`, then
    `load('hi')` (which resolves right away), then complete `'ur'`. No
    `HomeLoaded(languageCode: 'ur')` is ever emitted, and the final state is
    `hi`
  - **previous carried:** after `en` has loaded, `load('ur')` first emits
    `HomeLoading` whose `previous` is the `en` content
  - an error on the second language emits `HomeError` with `previous` set
- **`test/features/home/home_language_bar_test.dart`** (new widget test):
  provide a `MockCubit<HomeLanguageTabsState>` (bloc_test) and a real
  `ContentLanguageCubit` through `pumpScreen(contentLanguage:)`.
  - Loaded with `[en, ur, hi]` renders 3 `AppChip`s in that order. `en` is
    selected.
  - Tap "हिन्दी": `ContentLanguageCubit.state.code == 'hi'` and `leadCode` is
    still `'en'`. The Hindi chip is selected and the order is unchanged
    (check the chip order by the `find.byType(AppChip)` index).
  - Error renders no `AppChip`. Loaded with 1 language renders no `AppChip`.
  - Loading renders `SkeletonBox`es (pump past `AppMotion.skeletonDelay`).
  - Semantics: the chip label is `homeLanguageTabSemantics('Urdu')`.
- **`test/features/home/home_popular_section_test.dart`** (new):
  - empty and not loading: `homePopularThisWeek` text isn't found (after
    `pumpAndSettle`)
  - loading: 3 `SkeletonBox`es and the header are visible
  - non-empty: `PopularQuizCard` count equals the input, and tapping one calls
    `onQuizTap` with that quiz
- **`test/features/home/home_content_skeleton_test.dart`** (new): in light and
  dark, it pumps with no exception or overflow. After `skeletonDelay`, there
  are ≥ 3 `SkeletonBox`es sized `PopularQuizCard.width.w` ×
  `PopularQuizCard.height.h` and ≥ 6 sized as `SubcategoryCard` rail cards.
- **`test/core/theme/app_theme_test.dart`** (extend): both themes' extensions
  expose `skeleton`/`skeletonHighlight`. The dark values equal `darkS3`/`darkS2`.
  The **light `skeleton` contrast ratio against `lightS0` is ≥ 1.2**, computed
  with `computeLuminance()`: `(L1+0.05)/(L2+0.05)`.
- **`test/core/widgets/core_widgets_test.dart`** (extend): an `AppChip` with
  `semanticLabel` exposes that label and not the visible text.
  `SkeletonBox` with no colors uses `quizoo.skeleton`.
- **`test/features/home/home_screen_test.dart`**: the existing 3 tests must
  still pass. The error test now finds `ErrorStateView` *below* the top bar,
  and `find.byType(ErrorStateView)` still works. Add one test that
  `HomeScreen` renders a `HomeLanguageBar` in the first frame.
- **`test/features/onboarding/language_picker_cubit_test.dart`**: update
  imports only.

## Edge cases & error handling

- **Rapid tapping (Urdu → Hindi → Arabic):** the stale guard in `HomeCubit`
  makes only the latest request emit. `switchTo` persists each tap. The last
  write wins in prefs, and `profiles.locale` writes are fire-and-forget, so
  their order could race server-side. That's acceptable, and it matches how
  `select` behaves today.
- **Tapping the already-selected pill:** `switchTo` is a no-op, so nothing
  reloads.
- **A language with no categories:** the sections list is empty, so the
  Popular section collapses (it's empty too) and `EmptyStateView` renders
  under the banner. The pill row stays, so it's not a dead end.
- **Failure loading a language:** `HomeError` renders under the chrome, with
  the top bar showing the previous wallet. The player can Retry or tap another
  pill.
- **The languages list fails or has fewer than 2 entries:** the row is hidden
  and Home works exactly as before. Retry on the Home error view reloads it
  too.
- **The lead language gets deactivated server-side:** `orderForTabs` falls
  back to plain `sortOrder`. Content still loads for the persisted code (as
  it does today). No pill is highlighted if that code isn't in the list.
- **Sign in or out mid-session:** `MultiBlocProvider` is re-keyed on
  `isSignedIn`, so both Cubits are recreated and the cache is dropped.
  `adoptFromBackend` may then emit a new code *and* lead. The listeners reload
  content and re-pin, and the stale guard covers the create-time load racing
  the listener's load.
- **Offline:** unchanged. The S-46 view takes over the full area with no pill
  row, because a pill tap needs the network.
- **RTL UI locale (Urdu):** the pill row, the rails and the skeleton rails
  mirror through `ListView`/`Row` directionality. The skeleton uses
  `EdgeInsets.symmetric` and `AlignmentDirectional`.
- **Reduced motion:** `AnimatedSwitcher`/`AnimatedSize` durations go through
  `AppMotion.durationOf`, which makes them instant. `SkeletonBox` already
  stops its shimmer.
- **A popular rail that loaded fine but is empty** is cached as empty for that
  language, so Popular stays hidden on revisits within the session.

## Acceptance criteria

- [ ] Home shows a row of language pills directly under the top bar, for
      both guests and signed-in players, using `AppChip`'s `.cat` styling (flag
      + native name, selected pill inverted).
- [ ] The first pill is the default language the app launched with. The rest
      follow `languages.sort_order`.
- [ ] On arrival, Home fetches content for the default language only. Another
      language's content is fetched only when its pill is tapped, and revisiting
      an already-loaded pill doesn't refetch within the session.
- [ ] Tapping a pill switches Home's content to that language and makes it the
      persisted default (Daily, Duels and Search follow it immediately), and
      **the pill order doesn't change**.
- [ ] After a cold relaunch, the last-tapped language is the first pill and is
      selected.
- [ ] Changing the language from Settings, onboarding or Edit Profile still
      works, and re-pins that language first (Assumption 3).
- [ ] Home's loading skeleton matches the real layout: the Popular header,
      separate bleeding popular cards, the banner, and two category sections
      with medallion, title, hairline and bleeding subcategory cards. The top
      bar and pill row stay real (not skeletons).
- [ ] Skeletons are clearly visible in light theme (test: contrast against
      `--s0` ≥ 1.2), and dark theme looks unchanged.
- [ ] "🔥 Popular this week" (header and rail) doesn't appear when its data
      is empty. With live data today, that's every language except English.
- [ ] `dart format` makes no changes, `dart analyze` shows zero issues, and
      `flutter test` passes in full, including the new tests.

## Risks & rollout notes

- **Wider skeleton change.** The new `SkeletonBox` defaults make every
  light-theme skeleton darker: Search, category detail, level map, Daily,
  duel topic picker, VS header, leaderboards, achievements, stats and
  notifications. That's intended, but it should be looked at on at least two
  non-Home screens (see To verify).
- **Phase 1 file move** touches onboarding, auth and profile imports. It's
  mechanical, but it's the only cross-feature edit here. If it's rejected, see
  Assumption 1's fallback.
- **Pre-existing and left alone:** a signed-in cold start still shows
  `MockPlayer.currency` in the top bar until the first content arrives (the old
  `_HomeSkeleton` behavior, which now lives in `_HomeTopBar`). It's worth a
  follow-up to cache the last-known wallet.
- **Content gap:** non-English Home has no Popular rail until
  `featured_quizzes` rows exist for those languages. That's a content task,
  not part of this plan.
- There's no migration or feature flag. Rolling back means reverting the
  commit(s).
- After implementation, update the auto-memory with a "Plan 021 status"
  entry.

## To verify (manual, by the developer, per CLAUDE.md §13)

1. **Cold start, English default:** the row reads 🇬🇧 English (selected, first),
   then اردو, हिन्दी, العربية, Français, Español. Only English content loads
   (optionally confirm in the Supabase logs that only `language_code=en`
   categories are queried).
2. **Tap اردو:** the body cross-fades to Urdu content, the Urdu pill is
   selected, **the order is unchanged**, and there's no Popular section. Tap
   English again: it's instant, with no skeleton.
3. **Kill and relaunch the app:** اردو is now the first pill and selected.
   Open Daily and a duel topic picker: both use Urdu content.
4. **Settings → Language → Hindi → Continue:** back on Home, हिन्दी leads the
   row.
5. **Skeleton, light theme:** on a slow network (or with Network Link
   Conditioner), the skeleton shows separate popular cards bleeding off the
   right edge, a banner block, and two category sections, all clearly visible
   on the light background. Check it in dark theme too.
6. **Another light skeleton** (Search or a category screen): it's visible and
   not too heavy.
7. **Urdu UI locale (RTL):** the pill row and skeleton rails mirror correctly.
