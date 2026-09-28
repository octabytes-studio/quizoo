# Edit Profile Screen, Home Streak/Level Bug Fix, and You-Screen Gear Icon

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-09-28). Three requests bundled together by the user: (1) a new Edit
> Profile screen (avatar, display name, language), (2) a Home Screen bug
> where every signed-in user sees a hardcoded "12-day streak", and (3) a
> UI fix to make the You screen's settings gear icon more prominent.
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full. Code may have moved on since it was
written (dated 2026-09-28), so spot-check the referenced files and line
numbers still match before you begin. The three parts (Edit Profile,
streak/level bug, gear icon) are independent of each other and can be
implemented and reviewed in any order or as separate commits/PRs, but all
three touch `lib/features/profile/presentation/screens/profile_screen.dart`
so do them in the same branch to avoid merge friction.

## Objective

1. **Edit Profile screen.** A new screen, reached by tapping the player's own
   avatar on either the Home screen or the You screen (S-32, `ProfileScreen`),
   where a player can view their profile (stats and earned badges,
   read-only) and change their avatar, display name, and content language.
   A language change must immediately refresh the app's language-filtered
   content (categories/subcategories/etc.), exactly as it already does
   everywhere else language is changed. A guest can open this screen (it is
   not gated behind sign-in), but cannot actually change their avatar or
   display name — they see a sign-in banner (reusing the You screen's
   existing sign-in/sign-up prompt) in place of working controls.
2. **Home streak/level bug fix.** The Home Screen's top bar always shows a
   hardcoded "12-day streak" (and, bundled in the same fix — see Assumption
   1 — a hardcoded "Level 12") for every signed-in user, regardless of their
   real data. The real values already exist in Postgres and are already
   read correctly by the Profile feature; Home just never fetches them.
3. **You-screen gear icon.** The settings gear in `ProfileScreen`'s header
   is a bare 17sp emoji glyph with no tap-target plate, sitting on a busy
   gradient — it doesn't read as an actionable, tappable icon. Make it
   visually prominent, matching the "glass" treatment already used by the
   avatar frame directly below it in the same header.

## Scope

**In scope:**
- New `EditProfileScreen` (`lib/features/profile/presentation/screens/edit_profile_screen.dart`), reached via a new route `AppRoutes.editProfile`.
- Making the avatar tappable in both `PlayerTopBar` (Home, signed-in) and `_ProfileHeader` (You screen, `isOwnProfile` only, guest or signed-in) to open Edit Profile.
- New `AuthApi.updateProfile` / `AuthRepository.updateProfile` / `SessionCubit.updateProfile` for persisting avatar + display name changes and refreshing the app-wide session.
- Reusing the existing avatar picker (`AvatarPickerSheet`/`AvatarPickerCubit`) and language picker (`LanguagePickerSheet`/`LanguagePickerCubit`/`ContentLanguageCubit`) infrastructure as-is — no new avatar or language machinery.
- Extracting `ProfileScreen`'s inline badges rail into a reusable `BadgesRail` widget so both `ProfileScreen` and `EditProfileScreen` render the same view-only badges UI without duplicating it.
- Extracting `ProfileScreen`'s private `_GuestSignInBanner` into a reusable public `GuestSignInBanner` widget so `EditProfileScreen` can show the same sign-in/sign-up prompt to a guest.
- Adding an `enabled` flag to `ProfileField` (and disabling the avatar tap and Save button) so a guest can see but not use Edit Profile's editable controls.
- Widening two `BlocListener`/`BlocBuilder` `listenWhen`/`buildWhen` predicates (`ProfileScreen`, `HomeScreen`) so a profile data change (not just a guest↔signed-in transition) refreshes the screens that show the player's name/avatar.
- Fixing `HomeContent`/`HomeApi`/`HomeRepository`/`HomeCubit`/`home_screen.dart` so the Home top bar's streak (and, per Assumption 1, level) come from the real `profiles` row instead of `MockPlayer`.
- Making the You screen's settings-gear icon a plated, higher-contrast tap target in `ProfileScreen`'s `_ProfileHeader`.
- New/updated `bloc_test`, repository, and widget tests per CLAUDE.md §11.
- New l10n strings in both `lib/l10n/app_en.arb` and `lib/l10n/app_ur.arb`.
- Updating `MOCKED_FEATURES.md`'s existing "Home — top bar shows fake level/streak" entry to a struck-through "Fixed by plan 019" line, matching the doc's own convention for other resolved entries.

**Out of scope:**
- `playerLevel`'s XP/leveling math itself — only which value backs the number changes, not how levels are computed (already correct in `profile_api.dart`).
- `MockPlayer.dayStreak` usage in `save_progress_sheet.dart` (S-24's guest "save your progress" card) — a different, pre-existing, lower-severity mock (documented in `MOCKED_FEATURES.md` line 84 as "illustrative example, not the guest's real state") that the user did not report and that behaves correctly for its own purpose (a guest genuinely has no streak yet).
- `MockPlayer.avatarEmoji`/`MockPlayer.name` uses in Duel screens — unrelated feature, not mentioned in the spec.
- Country editing — the spec lists avatar, display name, and language only; country is not part of this screen.
- Deleting/renaming `MockPlayer.dayStreak`/`playerLevel` constants themselves — left in place in case other mocked surfaces still reference them (`save_progress_sheet.dart` does); only the two call sites named above stop using them.
- Any Supabase schema change — `profiles.streak_days`, `profiles.player_level`, `profiles.username`, `profiles.avatar_key` all already exist and are already written/read by other features.

## Research findings

- **The bug is already diagnosed in the repo's own tracking doc.** `MOCKED_FEATURES.md:57-61` documents this exact issue: `home_screen.dart:302-306,496-500` passes `MockPlayer.dayStreak`/`MockPlayer.playerLevel` to `PlayerTopBar` unconditionally, rated "High" severity, and explicitly notes the real computation already exists correctly in `features/profile/data/profile_api.dart:122-123` (`profileRow['streak_days']`, `profileRow['player_level']`).
- **`HomeApi.fetchCachedHome`** (`lib/features/home/data/home_api.dart:99-107`) already runs a `profiles` query for the signed-in branch — `.select('coins, gems, hearts, max_hearts, hearts_updated_at')` — to build `PlayerCurrency`. Extending this single existing query's column list is the whole fix; no new round trip.
- **`HomeContent`** (`lib/features/home/domain/home_content.dart`) is a `@freezed` model with `@Default` fields (e.g. `DailyChallengePreview.questionCount`) — the pattern to follow for adding `dayStreak`/`playerLevel` as `@Default(0) int` fields.
- **`home_screen.dart`** uses `MockPlayer.dayStreak`/`MockPlayer.playerLevel` at exactly two call sites: line 306/307 (`_HomeContentView`, has real `content`) and line 500/501 (`_HomeSkeleton`, has no `HomeContent` yet — this is the loading flash before the first real fetch resolves).
- **Edit Profile has no bible screen ID.** The design bible's 54 fixed screens (`app_routes.dart`'s own doc comment: "All 54 screen IDs from the design bible are reserved here up front") do not include a dedicated profile-editing screen — S-32 (`Profile`) is view + entry to Settings only, and S-25 (`ProfileCreationScreen`) is onboarding-only, gated on `!user.isProfileComplete`. This mirrors plan 015's own precedent of extending the app (new `avatar_options` table + picker) beyond the original 54 IDs when a product spec calls for it. New route added without an `sXX` alias.
- **`SimpleTopBar`** (`lib/core/widgets/simple_top_bar.dart`) is explicitly documented as "the flat top bar every other **pushed** screen ... uses — Achievements, Stats, Friends, Category leaderboard", distinct from the two bespoke gradient headers (Category detail, Profile). Edit Profile is a pushed secondary screen off Profile, so it takes `SimpleTopBar`, not a second gradient header.
- **S-25 (`ProfileCreationScreen`, `lib/features/auth/presentation/screens/profile_creation_screen.dart`) is the closest existing analog** for nearly everything Edit Profile needs:
  - Avatar picking: `_pickAvatar()` opens `AvatarPickerSheet` via `AppBottomSheet.show<String>`, updates local `_avatarKey` on result (lines 143-152).
  - Language picking: `_pickLanguage()` opens `LanguagePickerSheet`, which calls `context.read<ContentLanguageCubit>().select(code)` **immediately on tap and pops** — no separate "Continue"/"Save" step (`language_picker_sheet.dart:80-86`). Reusing this sheet as-is satisfies the "refresh the app" requirement for free: `ContentLanguageCubit` is already watched by Home (`home_screen.dart:59,64` — keys `HomeCubit`'s `BlocProvider` on `(isSignedIn, languageCode)` so a language change forces a fresh fetch), Search, and catalog screens (per project memory: "Plan 008 status — ContentLanguageCubit filters Home/Search/catalog by picked language").
  - Username availability: debounced (350ms) live check via `AuthRepository.isUsernameAvailable`, tracked in local `StatefulWidget` state (`_isUsernameAvailable`, `_isCheckingUsername`, `_usernameDebounce`) — not a Cubit. This is the established, already-reviewed pattern in this codebase for exactly this kind of transient validation feedback (CLAUDE.md §3's "purely local, ephemeral UI state" carve-out), so Edit Profile's form-field bookkeeping follows the same shape rather than inventing a Cubit for it.
  - Fields: `ProfileField` (text input with focus/blur/error chrome) and `ProfilePickerField` (tap-to-open-sheet row with leading emoji + value), both in `lib/features/auth/presentation/widgets/profile_field.dart` — reused as-is, no feature-boundary violation since these already live under `auth`'s own widgets and are already imported by `profile_creation_screen.dart` only; Edit Profile importing them via a `package:quizoo/...` import is a normal cross-feature reuse (CLAUDE.md §8 — package imports across features are allowed; only *moving* shared widgets is what §2 restricts, and CLAUDE.md doesn't require moving something to `core/` just because a second feature starts consuming it, only that a widget *belongs* in `core/` once it becomes generic/reusable rather than staying feature-specific — `ProfileField`/`ProfilePickerField` remain profile-form-specific).
- **`AuthApi.createProfile`** (`lib/features/auth/data/auth_api.dart:111-148`) is the one-time onboarding write (`profiles.update({username, avatar_key, country_code})` for the current `auth.uid()`), called only from `SessionCubit.createProfile`, which emits `SessionAuthenticating` first — appropriate for "no profile yet" but wrong for editing an already-complete profile (would transiently make `SessionCubit.state is! SessionSignedIn` true, which nothing currently depends on badly, but is a state that doesn't describe reality — the player already has a full account). A new, parallel `updateProfile` path is added instead of reusing `createProfile`.
- **`SessionCubit.signOut()`** (`lib/features/auth/presentation/bloc/session_cubit.dart:139-147`) is the existing precedent for "a failed backend action while signed in must not disguise itself as a state change" — it rethrows the `ApiException` rather than emitting `SessionFailure` (which has no `.user` and would read as guest everywhere). The new `updateProfile` method follows this exact shape.
- **Two narrow `listenWhen`/`buildWhen` predicates already exist and must be widened**, or a display-name/avatar edit won't show up anywhere until the app restarts:
  - `ProfileScreen` (`profile_screen.dart:69-71`): `BlocListener<SessionCubit>` only reloads `ProfileCubit` on a guest↔signed-in *transition*, not on a data change within `SessionSignedIn`.
  - `HomeScreen` (`home_screen.dart:54-56`): `BlocBuilder<SessionCubit>`'s `buildWhen` has the identical narrow shape, so `PlayerTopBar`'s `name`/`avatarEmoji` (read directly from `session.user`, `_HomeContentView` line 258/303-304) wouldn't rebuild either.
  - Grepped for this exact pattern across `lib/` — these are the only two occurrences.
- **`ProfileSummary`** (`lib/features/profile/domain/profile_summary.dart`) already carries everything Edit Profile's read-only section needs: `avatarEmoji`, `username`, `dayStreak`, `playerLevel`, `badgeCount`, `recentBadges`, plus the four `StatStrip` numbers. `ProfileCubit`/`ProfileRepository`/`ProfileApi` (already fetch this) are reused as-is for Edit Profile's own `BlocProvider` — no new read-side Cubit needed (CLAUDE.md §1: don't add use-case classes for what a repository + Cubit already covers). `ProfileApi.fetchSummary()` already works identically for a guest (their real anonymous `profiles` row, per `ProfileScreen`'s own doc comment: "Every player — guest or signed in — already carries a real Supabase session ... `fetchSummary()` works and returns real data either way"), so `EditProfileScreen` needs no guest-specific data path — only a guest-specific *interaction* restriction (see Design overview).
- **`StatStrip`** (`lib/features/profile/presentation/widgets/stat_strip.dart`) and the inline badges rail in `_ProfileLoadedView` (`profile_screen.dart:223-272`) are the exact view-only widgets the new screen needs. `StatStrip` is already a standalone widget; the badges rail is not — it needs extracting first (see Design overview).
- **The avatar is already rendered, but not tappable, in both places the user wants it tappable.** `PlayerTopBar` (`home_top_bar.dart:89-99`) renders a 38px avatar `Container` with no `GestureDetector`; `_ProfileHeader` (`profile_screen.dart:485-503`) renders a 74px avatar `Container` the same way. `GuestTopBar` (Home's guest layout, `home_top_bar.dart:18-56`) has **no avatar at all** — a guest on Home sees only a welcome title and a search button — so the avatar-tap entry point only exists on Home for a signed-in player; a guest reaches Edit Profile through the You screen's avatar instead, which `_ProfileHeader` already renders for both guest and signed-in (a fixed 🐼 for guest, per that widget's own doc comment).
- **`_GuestSignInBanner`** (`profile_screen.dart:326-402`) is a private class — the exact "sign-in/sign-up widget" the user is referring to ("along with sign-in/sign-up widget which we are showing in the You screen already"): a guest badge row (🐼 + "Playing as Guest" + subtitle) plus a `ChunkyButton.secondary` that pushes `AppRoutes.saveProgress` (S-24, the real account-creation flow). It needs to be a public, standalone widget to be reusable from `EditProfileScreen` (CLAUDE.md §7 — one public widget per file; a private, single-file class can't be imported elsewhere).
- **`ProfileField`** (`lib/features/auth/presentation/widgets/profile_field.dart:12-38`) has no disabled/read-only mode today — its `TextField` is always interactive. A small `enabled` constructor param (default `true`) is the minimal addition needed to grey it out and stop accepting input for a guest, without forking the widget.
- **l10n**: two locales only, `lib/l10n/app_en.arb` and `lib/l10n/app_ur.arb` (Urdu, RTL) — every new string needs an entry in both files. Existing keys like `profileChangeAvatar`, `profileUsername*`, `profileChooseAvatar`, `profileStat*`, `profileRecentBadges`, `profileAllBadges`, `profileSettings` are reused unchanged.
- **Testing conventions**: `bloc_test` + `mocktail`, one `_Mock*Api`/`_Mock*Repository` per test file (`test/features/home/home_cubit_test.dart`, `test/features/auth/session_cubit_test.dart`). Widget tests live in `test/features/<feature>/`, use `test/support/pump_screen.dart`, and construct a real-but-unauthenticated `supabase` client the same DI-less way the screens under test do (`profile_screen_test.dart`'s own doc comment explains this pattern in detail).
- **Icon button precedent**: the design bible's shape/elevation table specifies `Icon button: radius 12, 1px line + 8y/20blur` as the generic `.ib` token, realized as `HomeIconButton` (`lib/features/home/presentation/widgets/home_top_bar.dart:147-186`, 38px, `quizoo.s1` fill, `quizoo.ln` border, `quizoo.shadow`). That token is designed for neutral surfaces (Home/Browse), not a gradient header. `_ProfileHeader`'s own avatar frame (`profile_screen.dart:485-496`) already solves "make a glyph read as a control on this specific gradient" with a translucent-white circle + white border — the gear icon fix reuses that exact treatment for visual consistency within the same header, rather than dropping in the neutral `.ib` token.
- **Material icons are an established pattern**, not a new one: `Icons.chevron_right` is already used in `lib/core/widgets/category_section_header.dart:103,119`, so swapping the `⚙️` emoji glyph for `Icons.settings_rounded` is consistent with existing practice, not a new dependency or style.
- **Routing**: `AppRoutes.you = '/you'`, `AppRoutes.achievements = '/you/achievements'`, `AppRoutes.stats = '/you/stats'` (`lib/core/router/app_routes.dart:135-146`) — sub-routes of `/you` are the established shape for profile-adjacent pushed screens. Registered as top-level routes with `parentNavigatorKey: rootNavigatorKey` in `lib/app/router.dart` (see `AppRoutes.stats`'s registration at `router.dart:274-278` for the exact shape to copy).

## Assumptions & open questions

1. **`playerLevel` is fixed alongside `dayStreak`, even though the user only reported the streak.** Both numbers are rendered by the same `l10n.homeStreakLevel(dayStreak, playerLevel)` string, come from the same already-open `profiles` row query, and are tracked as *one* "High" severity bug in the project's own `MOCKED_FEATURES.md`. Shipping a fix that corrects the streak but leaves "Level 12" hardcoded next to it would be an inconsistent, confusing half-fix for zero extra query cost. If the user wants *only* the streak touched, drop the `player_level` column/field additions and the `playerLevel:` line in the two `home_screen.dart` call sites — everything else in Design overview/Implementation steps for this part is unaffected.
2. **Edit Profile's entry point is the player's own avatar** on `PlayerTopBar` (Home) and `_ProfileHeader` (You screen) — per the user's explicit instruction — not a separate button or menu item. On the You screen this is gated by `isOwnProfile` (tapping someone *else's* avatar on a public profile must never open your own Edit Profile screen); Home's top bar has no concept of another player's avatar, so no equivalent gate is needed there.
3. **A guest can open Edit Profile, but cannot save an avatar/display-name change.** Per the user's explicit instruction: the screen loads and displays normally for a guest (their real, if empty/default, `profiles` row), but the avatar tap, the username field, and the Save button are all disabled, and a `GuestSignInBanner` (the same sign-in/sign-up prompt already shown on the You screen) is shown to explain why and offer the real fix (sign up via S-24). This preserves the bible's "guest → save progress" conversion moment while still letting a guest *see* what editing looks like.
4. **The language field stays enabled for a guest**, unlike the avatar/username. Reasoning: content-language selection is not gated behind an account anywhere else in the app — a guest can already freely change it from Settings' own `settingsLanguage` row (`context.push(AppRoutes.languagePicker)`, no `isSignedIn` check) or from S-25's own language field before an account even exists. Disabling it only inside Edit Profile would be a new, inconsistent restriction the rest of the app doesn't have. Only the two fields that require *persisting to an account* (`profiles.username`, `profiles.avatar_key` via `SessionCubit.updateProfile`) are guest-gated.
5. **Edit Profile shows stats + badges only, not "Best categories".** The spec's own wording is "show the user profile (also user stats and earned badges for view only purpose)" — best-categories is a third, separate `ProfileScreen` section not named in the spec, so it's left out to keep the new screen focused rather than a near-duplicate of `ProfileScreen`.
6. **Saving pops back to `ProfileScreen`** (mirrors `_ProfileCreationViewState._create()`'s success handling — snackbar, then `context.pop()`) rather than staying on the Edit Profile screen after a successful save.
7. **Username-unchanged case skips the availability re-check.** If the candidate text equals the original `ProfileSummary.username`, the field is treated as valid without calling `isUsernameAvailable` — otherwise a user opening Edit Profile and immediately tapping Save would see their own existing username reported as "taken" (since `isUsernameAvailable`'s query has no "exclude this user" clause and would find their own row). N/A for a guest, whose username field is disabled outright (Assumption 3).
8. **No Supabase RLS/schema change is needed.** `profiles.username`, `profiles.avatar_key`, `profiles.streak_days`, `profiles.player_level` all already exist and are already writable/readable by the authenticated user's own row (the same policies `createProfile`/`fetchSummary` already rely on). If a spot-check during implementation finds `username`/`avatar_key` update is blocked by RLS for a non-onboarding write, that's a genuine open question requiring a human decision (a migration), not something to silently work around.

## Design overview

### Part A — Edit Profile screen

**New route**: `AppRoutes.editProfile = '/you/edit-profile'` (added in `app_routes.dart` next to `AppRoutes.stats`), registered in `app/router.dart` as a top-level push:
```dart
GoRoute(
  path: AppRoutes.editProfile,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const EditProfileScreen(),
),
```

**New files**:
- `lib/features/profile/presentation/screens/edit_profile_screen.dart` — `EditProfileScreen` (StatelessWidget, provides its own `BlocProvider<ProfileCubit>(create: (_) => ProfileCubit(ProfileRepository(ProfileApi(supabase)))..load())`, same construction shape as `ProfileScreen`) wrapping `_EditProfileView` (StatefulWidget).
- `lib/features/profile/presentation/widgets/badges_rail.dart` — `BadgesRail` widget, extracted from `_ProfileLoadedView`'s inline badges section (`profile_screen.dart:223-272`: the `SectionHeader` + horizontal `ListView.separated` of badge medallions). Takes `badges: List<AppBadge>`, `badgeCount: int`, `onSeeAll: VoidCallback`. `ProfileScreen` is updated to use it instead of its inline copy (CLAUDE.md §7: extract once a UI piece is used more than once).
- `lib/features/profile/presentation/widgets/guest_sign_in_banner.dart` — `GuestSignInBanner` widget, extracted verbatim from `_GuestSignInBanner` (`profile_screen.dart:326-402`), made public. `ProfileScreen` updates its one call site to use it; `EditProfileScreen` gets its own new call site.

**Avatar-tap entry points** (Assumption 2):
- `PlayerTopBar` (`home_top_bar.dart:59-144`) gains a required `onAvatarTap: VoidCallback` param; its avatar `Container` (lines 89-99) is wrapped in a `GestureDetector`/`Semantics(button: true, label: l10n.profileEditAction, ...)`, matching the existing `HomeIconButton`'s `Semantics` shape. `home_screen.dart`'s two `PlayerTopBar(...)` call sites (loaded view + skeleton) pass `onAvatarTap: () => context.push(AppRoutes.editProfile)`.
- `_ProfileHeader` (`profile_screen.dart:485-503`)'s avatar `Container` is wrapped the same way, gated on `isOwnProfile`: `onTap: isOwnProfile ? () => context.push(AppRoutes.editProfile) : null` (a public-profile view, `isOwnProfile: false`, keeps the avatar inert). This applies to both the guest and signed-in visual states of the header, since both already render through the same `_ProfileHeader` — a guest tapping their own avatar on the You screen is exactly how Assumption 3's guest path is reached.

**`_EditProfileView` structure** (mirrors `_ProfileCreationViewState`'s shape):
- `Scaffold` with `SimpleTopBar(title: l10n.profileEditTitle)`.
- `BlocBuilder<ProfileCubit, ProfileState>`, switching exhaustively:
  - `ProfileInitial() || ProfileLoading()` → centered `CircularProgressIndicator` (this screen has no read-only-vs-editable skeleton shape worth building — a full loading flash is brief and matches `LanguagePickerSheet`'s own loading branch).
  - `ProfileError(:final error)` → `ErrorStateView` + retry, matching `_ProfileError`'s shape in `profile_screen.dart`.
  - `ProfileLoaded(:final summary)` → the form, built below.
- `final isSignedIn = context.watch<SessionCubit>().state is SessionSignedIn;` — the one new piece of state this screen reads beyond `ProfileCubit`, used to switch the form between its guest and editable presentations.
- Local `State` fields: `TextEditingController _username`, `late String _avatarKey`, `bool _initialized = false`, `bool _usernameTouched`, `bool? _isUsernameAvailable`, `bool _isCheckingUsername`, `Timer? _usernameDebounce`, `bool _isSaving`.
- On first build with `ProfileLoaded(:final summary)` (guarded by `!_initialized`, set `_initialized = true` inside `setState` so it only seeds once and never clobbers an in-progress edit on rebuild): `_avatarKey = summary.avatarEmoji; _username.text = summary.username;`.
- Form content (once loaded), in a `ListView` under the top bar:
  1. `if (!isSignedIn) GuestSignInBanner()` — shown first, above everything else, mirroring where `ProfileScreen` itself places it (`_ProfileLoadedView`'s first child when `isOwnProfile && !isSignedIn`).
  2. Centered avatar circle (88.w, same visual weight as S-25's). Tap handler is `isSignedIn ? _pickAvatar : null` (opens `AvatarPickerSheet` via `AppBottomSheet.show<String>`, exactly like S-25's `_pickAvatar()`, only when signed in); rendered at reduced opacity (e.g. `Opacity(opacity: isSignedIn ? 1 : 0.5, ...)`) when disabled, so its non-interactive state is visible, not just silently inert.
  3. `SizedBox` + `StatStrip` with the same four `(value, label)` pairs `_ProfileLoadedView` already builds (points/levels/accuracy/badges) — always shown, guest or signed in (view-only data, per Objective/spec).
  4. `BadgesRail(badges: summary.recentBadges, badgeCount: summary.badgeCount, onSeeAll: () => context.push(AppRoutes.achievements))` — likewise always shown.
  5. `ProfileField` for display name (label `l10n.profileUsername`), now with the new `enabled: isSignedIn` param (Design overview's `ProfileField` change below). When disabled: no focus, no `onBlur`-driven error chrome, no availability trailing widget — just a greyed, inert display of `summary.username` (empty for most guests). When enabled, identical to S-25: touched/error/trailing-availability chrome, debounced availability check via `context.read<AuthRepository>().isUsernameAvailable(...)`, **skipped when the trimmed candidate equals `summary.username`** (Assumption 7).
  6. `ProfilePickerField` for language (label `l10n.profileLanguage`) — **always enabled**, guest or signed in (Assumption 4). Value/flag sourced from `ContentLanguageCubit`/`LanguagePickerCubit` exactly as S-25 does (`languageFlags` map from `language_picker_sheet.dart`), `onTap` opens `LanguagePickerSheet` — applies immediately via `ContentLanguageCubit.select()`, no interaction with the Save button.
  7. Bottom-pinned `ChunkyButton` "Save changes" (`l10n.profileSaveChanges`) — `onPressed: null` (visibly disabled, never hidden, matching S-25's own CTA convention) whenever `!isSignedIn`; when signed in, enabled only when: username length ≥ 3, and (username unchanged OR `_isUsernameAvailable == true`), and not already `_isSaving`.
- `_save()` (only reachable when `isSignedIn`, since the button is disabled otherwise): sets `_isSaving = true`, calls `await context.read<SessionCubit>().updateProfile(username: ..., avatarEmoji: _avatarKey)` inside try/catch (mirrors `_confirmLogout`'s shape in `profile_screen.dart:155-178`): on success, `AppSnackbar.show(..., intent: SnackbarIntent.success)` then `context.pop()`; on `ApiException`, `AppSnackbar.show(..., intent: SnackbarIntent.error)` and stay on the form; `finally` resets `_isSaving = false` if still mounted.

**`ProfileField` change** (`lib/features/auth/presentation/widgets/profile_field.dart`): add `this.enabled = true` to the constructor; in `_ProfileFieldState.build()`, pass `enabled: widget.enabled` to the inner `TextField`, skip attaching the focus listener's error-arming behavior when disabled, and dim the container's border/text color (e.g. via `quizoo.tx3`/a lower-alpha border) when `!widget.enabled`. `ProfileCreationScreen`'s existing usage is unaffected (`enabled` defaults to `true`).

**`AuthApi.updateProfile`** (new method in `lib/features/auth/data/auth_api.dart`, placed next to `createProfile`):
```dart
Future<AuthUser> updateProfile({
  required String username,
  required String avatarEmoji,
}) async {
  final authUser = _client.auth.currentUser;
  if (authUser == null) {
    throw const ApiException('Not signed in', kind: ApiErrorKind.unauthorized);
  }
  try {
    await _client
        .from('profiles')
        .update({'username': username, 'avatar_key': avatarEmoji})
        .eq('id', authUser.id);
    return await _fetchCurrentAuthUser();
  } catch (error) {
    if (error is ApiException) rethrow;
    throw ApiException.fromSupabase(error);
  }
}
```
(Reuses the existing private `_fetchCurrentAuthUser()` to rebuild a consistent `AuthUser` from the DB rather than hand-assembling one, avoiding duplicating `createProfile`'s field-mapping logic.)

**`AuthRepository.updateProfile`** — one-line passthrough, same shape as `isUsernameAvailable`.

**`SessionCubit.updateProfile`** (new method, placed after `createProfile`):
```dart
/// Edit Profile: updates the signed-in player's own username/avatar.
///
/// Rethrows on failure rather than emitting [SessionFailure] — like
/// [signOut] — since a save error must never look like the player got
/// signed out. The caller (Edit Profile) shows its own error and keeps the
/// form open.
Future<void> updateProfile({
  required String username,
  required String avatarEmoji,
}) async {
  final updated = await _repository.updateProfile(
    username: username,
    avatarEmoji: avatarEmoji,
  );
  if (!isClosed) emit(SessionSignedIn(updated));
}
```

**Propagating the change to already-alive screens** (both are `StatefulShellRoute.indexedStack` branches built once and kept alive, per `ProfileScreen`'s own doc comment):
- `profile_screen.dart:69-71` — widen `listenWhen`:
  ```dart
  listenWhen: (previous, current) {
    final wasSignedIn = previous is SessionSignedIn;
    final isSignedIn = current is SessionSignedIn;
    if (wasSignedIn != isSignedIn) return true;
    return previous is SessionSignedIn &&
        current is SessionSignedIn &&
        previous.user != current.user;
  },
  ```
  (`AuthUser` is a `@freezed` model, so `!=` is already value-based equality — no new equality code needed.)
- `home_screen.dart:54-56` — widen the `BlocBuilder<SessionCubit>`'s `buildWhen` the same way, so `PlayerTopBar`'s `name`/`avatarEmoji` (sourced from `session.user`) repaint immediately after a save.

### Part B — Home streak/level bug fix

**`HomeContent`** (`home_content.dart`): add two fields to the `@freezed` factory:
```dart
@Default(0) int dayStreak,
@Default(0) int playerLevel,
```
(Per Assumption 1 — drop `playerLevel` here and below if the user wants streak-only.)

**`HomeApi.fetchCachedHome`** (`home_api.dart`):
- Extend the existing signed-in `profiles` query's `.select(...)` string from `'coins, gems, hearts, max_hearts, hearts_updated_at'` to `'coins, gems, hearts, max_hearts, hearts_updated_at, streak_days, player_level'`.
- After `currency = _currencyFromRow(profileRow);`, add:
  ```dart
  dayStreak = profileRow['streak_days'] as int? ?? 0;
  playerLevel = profileRow['player_level'] as int? ?? 1;
  ```
  (declare `var dayStreak = 0;` / `var playerLevel = 0;` alongside the existing `PlayerCurrency? currency;` local declarations above the `if (isSignedIn)` block).
- Pass both into the final `HomeContent(...)` return.

**`HomeRepository`**: no change needed — `fetchCachedHome` already passes the whole `HomeContent` through untouched.

**`home_screen.dart`**:
- Line ~306-307 (`_HomeContentView`, has real `content`): replace `dayStreak: MockPlayer.dayStreak, playerLevel: MockPlayer.playerLevel,` with `dayStreak: content.dayStreak, playerLevel: content.playerLevel,`.
- Line ~500-501 (`_HomeSkeleton`): this state has no `HomeContent` yet (it's the pre-first-fetch loading flash) — replace `MockPlayer.dayStreak`/`MockPlayer.playerLevel` with literal `0`s rather than inventing a fake fetch here. This briefly shows "0-day streak · Level 0" instead of a fabricated "12" during the sub-1.2s cold-open budget the `HomeCubit` doc comment describes — a correct, honest placeholder rather than a wrong specific number. (If this flash is judged visually distracting during review, the alternative is a `SkeletonBox` in place of that text line instead of real numbers — a small follow-up, not blocking this fix.)
- Remove the now-unused `import 'package:quizoo/core/mock/mock_player.dart';` from `home_screen.dart` if nothing else in the file still references `MockPlayer` (check `MockPlayer.currency` usage at line ~499 first — if that's still there, keep the import).

**`MOCKED_FEATURES.md`**: strike through the "Home — top bar shows fake level/streak" entry (lines 57-61 and its line-116 summary bullet), matching the doc's existing convention (see lines 44-45's `~~...~~ **Fixed by plan 017.**` pattern) — `**Fixed by plan 019.**`.

### Part C — You-screen gear icon

In `_ProfileHeader` (`profile_screen.dart:469-478`), replace:
```dart
if (isOwnProfile)
  Semantics(
    button: true,
    label: l10n.profileSettings,
    child: GestureDetector(
      onTap: () => context.push(AppRoutes.settings),
      behavior: HitTestBehavior.opaque,
      child: Text('⚙️', style: AppTypography.glyph(17.sp)),
    ),
  ),
```
with a plated circular button matching the avatar frame's own "glass on gradient" treatment two rows below it (`Colors.white.withValues(alpha: 0.16)` fill / `Colors.white.withValues(alpha: 0.5)` border):
```dart
if (isOwnProfile)
  Semantics(
    button: true,
    label: l10n.profileSettings,
    child: GestureDetector(
      onTap: () => context.push(AppRoutes.settings),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34.w,
        height: 34.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.settings_rounded,
          size: 18.sp,
          color: Colors.white,
        ),
      ),
    ),
  ),
```
This both plates the icon (a real 34dp tap target, up from the emoji's tight glyph bounds) and swaps the emoji for a crisp Material icon (`Icons.settings_rounded`), addressing the "you can change the icon" option. `AppTypography`/`Icon` imports: `Icon` comes from `package:flutter/material.dart`, already imported.

## Implementation steps

- [ ] **1. Routing.** Add `AppRoutes.editProfile = '/you/edit-profile'` to `app_routes.dart` (next to `AppRoutes.stats`). Register the `GoRoute` in `app/router.dart` next to `AppRoutes.stats`'s registration.
- [ ] **2. Data/domain — auth.** Add `AuthApi.updateProfile` (`auth_api.dart`) and `AuthRepository.updateProfile` (`auth_repository.dart`).
- [ ] **3. Session.** Add `SessionCubit.updateProfile` (`session_cubit.dart`), doc comment referencing `signOut`'s rethrow precedent.
- [ ] **4. Widen the two rebuild predicates.** `profile_screen.dart:69-71` and `home_screen.dart:54-56`, per Design overview.
- [ ] **5. Extract `BadgesRail`.** New `lib/features/profile/presentation/widgets/badges_rail.dart`; update `_ProfileLoadedView` in `profile_screen.dart` to use it in place of its inline badges block.
- [ ] **6. Extract `GuestSignInBanner`.** New `lib/features/profile/presentation/widgets/guest_sign_in_banner.dart`, made public; update `_ProfileLoadedView` in `profile_screen.dart` to use it in place of its private `_GuestSignInBanner`.
- [ ] **7. `ProfileField` `enabled` param.** Add the disabled/greyed-out rendering path described in Design overview to `lib/features/auth/presentation/widgets/profile_field.dart`.
- [ ] **8. New Edit Profile screen.** `lib/features/profile/presentation/screens/edit_profile_screen.dart`, per Design overview's `_EditProfileView` structure (guest banner, disabled avatar/username/Save, always-enabled language, always-visible stats/badges).
- [ ] **9. Avatar-tap entry points.** Add `onAvatarTap` to `PlayerTopBar` (`home_top_bar.dart`) and wire both `home_screen.dart` call sites; wrap `_ProfileHeader`'s avatar in `profile_screen.dart` with an `isOwnProfile`-gated tap handler. Both push `AppRoutes.editProfile`.
- [ ] **10. l10n.** Add to both `app_en.arb` and `app_ur.arb`: `profileEditTitle`, `profileEditAction` (now doubling as the avatar's `Semantics` label, e.g. "Edit profile"), `profileSaveChanges`, `profileChangesSaved`, `profileUpdateError` (plus each key's `@key` description entry, matching the file's existing convention). Run `flutter gen-l10n` (or the project's usual codegen trigger) to regenerate `AppLocalizations`.
- [ ] **11. Home streak/level fix — domain.** Add `dayStreak`/`playerLevel` fields to `HomeContent` (`home_content.dart`).
- [ ] **12. Home streak/level fix — data.** Extend the `profiles` select and populate the two new fields in `HomeApi.fetchCachedHome` (`home_api.dart`).
- [ ] **13. Home streak/level fix — presentation.** Update both `home_screen.dart` call sites (loaded view + skeleton) per Design overview; drop the `mock_player.dart` import if it's now unused there.
- [ ] **14. Regenerate generated code.** `dart run build_runner build --delete-conflicting-outputs` (for `home_content.freezed.dart`/`.g.dart` after step 11).
- [ ] **15. Gear icon.** Apply the `_ProfileHeader` change in `profile_screen.dart`, per Design overview Part C.
- [ ] **16. Docs.** Update `MOCKED_FEATURES.md`'s streak/level entry to struck-through "Fixed by plan 019", per Design overview Part B.
- [ ] **17. Format & analyze.** `dart format .` and `dart analyze` with zero warnings (CLAUDE.md §8), across all touched files.
- [ ] **18. Tests.** Per Testing strategy below.

## Data model / API changes

- `HomeContent` (freezed model): + `@Default(0) int dayStreak`, `@Default(0) int playerLevel`. No JSON shape change beyond the new optional-with-default fields (backward compatible with any cached/serialized `HomeContent` — none currently persisted to disk, per existing code).
- `profiles` table: no schema change. `HomeApi.fetchCachedHome`'s signed-in query gains two columns (`streak_days`, `player_level`) it wasn't previously selecting; both already exist (read by `profile_api.dart` today).
- New method surface (no new tables/endpoints): `AuthApi.updateProfile`, `AuthRepository.updateProfile`, `SessionCubit.updateProfile` — all thin wrappers over the existing `profiles` table's `update` RLS policy already exercised by `createProfile`.

## Dependencies

N/A — no new packages. `Icon`/`Icons.settings_rounded` comes from Flutter's own `material.dart`, already imported everywhere; Material icon usage is already established (`category_section_header.dart`).

## Testing strategy

Matches this repo's existing `bloc_test` + `mocktail` conventions (`test/features/home/home_cubit_test.dart`, `test/features/auth/session_cubit_test.dart`).

- **`test/features/auth/session_cubit_test.dart`** — add:
  - Success path: `blocTest` for `updateProfile`, seeded `SessionSignedIn`, mock `repository.updateProfile(...)` resolves to an updated `AuthUser`, expect `[isA<SessionSignedIn>().having((s) => s.user.displayName, ..., 'NewName')]` (no `SessionAuthenticating` step, unlike `createProfile`).
  - Failure path: mock `repository.updateProfile(...)` throws `ApiException.network()`, expect `[]` (no state change) with `errors: () => [isA<ApiException>()]` — mirrors the existing `signOut` failure test exactly.
- **New `test/features/auth/auth_repository_test.dart`** (or extend an existing one if `AuthApi`/`AuthRepository` already has a repository-level test file — check before creating): `mocktail`-mocked `AuthApi`, one test that `updateProfile` passes through to `_api.updateProfile` and returns its result.
- **New `test/features/profile/edit_profile_screen_test.dart`** — widget test following `profile_screen_test.dart`'s established DI-less pattern (real `supabase` client with no session, `ProfileCubit`'s `fetchSummary()` will hit `unauthorized`): at minimum, one test per `ProfileState` branch the screen switches on (Loading/Initial, Error, Loaded), per CLAUDE.md §11's "one test per state branch" rule for non-trivial conditional rendering. A `ProfileLoaded` render test needs a fake/seeded `ProfileCubit` (`BlocProvider.value` with a cubit already emitted into `ProfileLoaded`, mirroring how other tests seed Cubit state directly rather than driving a real fetch) to verify the form fields, `StatStrip`, and `BadgesRail` all render. Two more cases specific to this screen's guest/signed-in split: (a) with a guest `SessionCubit` seeded, `GuestSignInBanner` renders, the username field's `TextField` reports `enabled: false`, and the Save button's `onPressed` is `null`; (b) with a `SessionSignedIn` `SessionCubit` seeded, `GuestSignInBanner` is absent and the same controls are interactive.
- **`ProfileField` widget test** (new or extended, wherever `profile_field.dart`'s own tests live if any exist — check first): one case asserting `enabled: false` renders a non-interactive `TextField` and doesn't invoke `onBlur`.
- **`test/features/home/home_cubit_test.dart`** — update the existing `cached` fixture's expectations if any test asserts on `HomeContent`'s full field set (spot-check current fixtures still compile after the new fields are added — freezed's generated `==`/`copyWith` will include them). Add one new case: `HomeApi.fetchCachedHome`'s signed-in branch returns a `profiles` row including `streak_days`/`player_level`, and `HomeContent.dayStreak`/`playerLevel` reflect it — this may belong in a `home_api`-level test if one exists, otherwise add it as a `HomeRepository`-level passthrough assertion (matching the file's existing `HomeRepository` group's error-mapping-path style) since `HomeApi` itself hits a real `SupabaseClient` and isn't unit-tested directly elsewhere in this file.
- **Widget test**: extend `test/features/profile/profile_screen_test.dart` with cases asserting: the avatar's tap handler is present (non-null `onTap`) when `isOwnProfile: true` and absent/`null` when `isOwnProfile: false` (public profile), across the `isOwnProfile`/`isSignedIn` combinations already covered by that file's existing test matrix; and that the gear icon's `Semantics` button/label survive the visual change (existing accessibility contract unchanged).
- **`PlayerTopBar` widget test** (wherever `home_top_bar.dart`'s own tests live, or as part of `home_screen_test.dart` if that's where top-bar behavior is already covered): tapping the avatar invokes `onAvatarTap`.
- **`test/features/home/home_screen_test.dart`**: spot-check any existing assertion that reads `MockPlayer.dayStreak`/`playerLevel` off the rendered top bar — update to assert against the fixture's real `HomeContent.dayStreak`/`playerLevel` instead.

## Edge cases & error handling

- **Username unchanged on save**: handled by Assumption 6 — no false "taken" error, no unnecessary network round trip.
- **Avatar/username save fails mid-edit**: `SessionCubit.updateProfile` rethrows; the screen catches `ApiException`, shows an error snackbar, and leaves the form exactly as the user left it (nothing is lost, nothing pops).
- **Language changed then Edit Profile is backed out of without saving avatar/name**: language still applies (it's immediate/independent, matching S-25's own behavior) — only avatar/username are discarded, which is the expected "Cancel"-equivalent behavior for a back-navigation with no explicit save.
- **Guest opens Edit Profile via the You screen's avatar**: the screen loads normally (real, if empty, `ProfileSummary`), shows `GuestSignInBanner`, and disables the avatar tap, username field, and Save button — the guest can look but not touch those three; language stays editable (Assumption 4).
- **A guest signs up (S-24) while Edit Profile is open in the background**: not reachable in practice — `AppRoutes.saveProgress` is pushed on top of Edit Profile by `GuestSignInBanner`'s CTA, and completing it emits `SessionSignedIn`, which (per the widened `listenWhen`/`buildWhen`) will refresh `ProfileScreen`/`HomeScreen` once the user pops back; Edit Profile itself would need to be re-opened to see its now-enabled controls, since its own `isSignedIn` read is a one-time `context.watch` snapshot per rebuild — this is normal `BlocBuilder` behavior (it *will* rebuild live if the widget is still mounted underneath the pushed sign-up flow) and not a new gap introduced by this plan.
- **Home's brief pre-fetch skeleton**: shows `0`/`Level 0` momentarily instead of a fabricated `12` (Design overview Part B) — correct-but-empty beats wrong-but-specific, and the window is sub-second per the `HomeCubit` doc comment's own performance budget.
- **A brand-new account with `streak_days`/`player_level` null in Postgres**: both `?? 0`/`?? 1` fallbacks in `HomeApi.fetchCachedHome` mirror `profile_api.dart`'s existing `?? 0` fallback for the same columns — no divide-by-zero or null-cast risk introduced.
- **Two screens rebuilding off one `SessionCubit` emission**: widening both `listenWhen`/`buildWhen` predicates means a single `updateProfile` success triggers both `ProfileCubit.load()` (a re-fetch) and `HomeScreen`'s top bar repaint (a `session.user` field read, not a re-fetch) — no duplicate network storm, since `HomeCubit` itself is keyed only on `(isSignedIn, languageCode)`, not on `SessionCubit.state` as a whole, so it does not reload on this emission.

## Acceptance criteria

- [ ] Tapping the player's own avatar on the Home screen (signed in) or the You screen (guest or signed in) opens the new Edit Profile screen, showing their real avatar, display name, language, stats (points/levels/accuracy/badges), and recent badges (view-only).
- [ ] Tapping another player's avatar on a public profile (`isOwnProfile: false`) does not open Edit Profile.
- [ ] A signed-in player can change the avatar and/or display name and tap Save; both persist to `profiles` and are immediately reflected on the You screen and the Home top bar, without an app restart.
- [ ] Changing the display name to one already taken by another account shows the existing "someone has this one" error and blocks Save; changing it back to the original value (or leaving it untouched) never shows a false "taken" error.
- [ ] Changing the language from Edit Profile immediately re-filters Home/Search/catalog content to the new language, exactly as changing it from Settings' own language row already does — for both a guest and a signed-in player.
- [ ] A guest can open Edit Profile, but its avatar tap, username field, and Save button are all disabled, and a sign-in banner (the same one shown on the You screen) is visible explaining why.
- [ ] Two different signed-in accounts with different real `streak_days`/`player_level` values each see their own correct number on the Home top bar — never a fixed "12".
- [ ] The You screen's settings gear is a plated, higher-contrast circular button that clearly reads as tappable, still navigates to Settings, and still exposes the same `Semantics` button/label for accessibility.
- [ ] `dart analyze` reports zero warnings across all touched/added files; `dart format .` has been run.
- [ ] New/updated `bloc_test`, repository, and widget tests pass, per Testing strategy.

## Risks & rollout notes

- **No migration/rollback needed** — no schema change, only new columns being *selected* (already-existing, already-writable columns) and one new UI screen behind a new route. Reverting is a plain code revert.
- **`MockPlayer.dayStreak`/`playerLevel` constants become unused outside `save_progress_sheet.dart`** after this change — left in place (Out of scope) rather than deleted, since that file still depends on them for its own, separately-scoped illustrative card.
- **Widening the two rebuild predicates is the one change in this plan that touches shared, frequently-touched screens** (`ProfileScreen`, `HomeScreen`) for a reason beyond this feature's own new code — flagged explicitly per CLAUDE.md §10, since it's a real behavior change (these screens now also repaint on an in-place profile edit) rather than a pure addition. Both changes are narrow (one extra boolean branch in an existing `listenWhen`/`buildWhen`) and strictly additive (they fire in more cases, never fewer), so the risk of an unrelated regression is low, but it's worth a reviewer's explicit attention.
- **To verify** (per CLAUDE.md §13 — the implementer must not launch the app to check this; hand off to the developer):
  - Open the You screen as a signed-in test account with a known non-default `streak_days`/`player_level` in Postgres; confirm Home's top bar shows that exact number, not "12".
  - Tap the avatar on the Home top bar (signed-in) and confirm it opens Edit Profile; tap the avatar on the You screen and confirm the same.
  - As a guest, tap the You screen's avatar; confirm Edit Profile opens, shows the sign-in banner, and that the avatar, username field, and Save button are visibly disabled (greyed, unresponsive to tap), while the language row still opens the language picker and applies a change immediately.
  - As a guest inside Edit Profile, tap the sign-in banner's CTA and complete sign-up; confirm returning to the You screen now shows the real account's data (not the guest's).
  - As a signed-in player, open Edit Profile, change the avatar and display name, save; confirm both update immediately on the You screen header and Home's top bar without restarting the app.
  - Attempt to save a display name already taken by a different seeded account; confirm the inline error and disabled Save button.
  - Visit a public profile (tap another player from a leaderboard/friends row) and confirm tapping their avatar does *not* open Edit Profile.
  - Visually confirm the You screen's gear icon now reads as a clear, tappable control against the gradient header, in both light and dark mode, and that it still opens Settings.
