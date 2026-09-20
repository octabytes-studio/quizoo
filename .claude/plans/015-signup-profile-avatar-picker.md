# Sign-up Profile: Display Name + Backend-Driven Avatar Picker

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-09-20). "When user signup to an account (Apple or Google) I want to
> show user a screen where user should be able to change his display name
> and display picture/avatar. The backend should have multiple avatars
> available and the app show those avatars to pick from when user signs up
> for the first time."
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full. Code may have moved on since it was
written (dated 2026-09-20), so spot-check the referenced files and line
numbers still match before you begin.

Two clarifying decisions were made with the user before drafting this plan
(see "Assumptions & open questions" for the full reasoning):

1. **Avatars stay emoji-based.** The backend gets a new lookup table listing
   the selectable avatar emoji (replacing the hardcoded `MockPlayer.
   avatarChoices` list), not real image assets. Every existing
   avatar-rendering surface (home top bar, notifications, leaderboard) keeps
   working unchanged, since `profiles.avatar_key` stays a single emoji
   string.
2. **Vendor sign-in prefill.** For Google/Apple, the profile screen should
   pre-fill the display-name field from the vendor's own profile name
   (editable) and skip the email field entirely, since Supabase already has
   the player's email from the vendor.

## Objective

Today, a fresh Google/Apple sign-in already lands on the profile-creation
screen (S-25, `ProfileCreationScreen`) — `SaveProgressSheet` already checks
`!user.isProfileComplete` and pushes `AppRoutes.profileCreation` for a
vendor sign-in exactly as it does for email (see `save_progress_sheet.dart:97-104`).
So the routing/gating half of this request is **already built**. What's
missing is:

- The avatar choices on that screen are a hardcoded 8-emoji Dart list
  (`MockPlayer.avatarChoices`) cycled one-at-a-time by tapping the avatar
  bubble — not a backend-driven set the player picks from.
- The screen always shows a blank, required "Email" field and an empty
  "Username" field, even for a vendor sign-in where Supabase already has
  the player's email and (usually) their real name — forcing them to
  re-type data the vendor already gave.

This plan: (1) adds a Supabase-backed avatar catalog and a real "pick one"
UI on S-25, sourced live from the database instead of a hardcoded list, and
(2) pre-fills the display name and removes the redundant email field for a
vendor (Google/Apple) sign-in, while leaving the email-route behavior (which
still needs to *collect* an email) untouched.

## Scope

**In scope:**
- New `public.avatar_options` table (emoji, sort order, active flag) + RLS,
  seeded with the existing 8 emoji so there's no visible regression.
- A new `features/auth` data/domain/bloc stack (`AvatarsApi`,
  `AvatarsRepository`, `AvatarOption`, `AvatarPickerCubit`) that fetches
  `avatar_options` where `is_active = true`, mirroring
  `features/onboarding`'s `LanguagesApi`/`LanguagesRepository`/
  `LanguageOption`/`LanguagePickerCubit` stack exactly.
- Replacing S-25's tap-to-cycle avatar bubble with a real picker: tapping it
  opens a bottom sheet showing every active avatar as a selectable grid,
  sourced from `AvatarPickerCubit`.
- `AuthUser` gains a `suggestedDisplayName` field, populated from the
  vendor's own profile name (Supabase `raw_user_meta_data`) when the
  session is a fresh, incomplete vendor sign-in.
- S-25 pre-fills the username field with `suggestedDisplayName` (still
  editable, still runs the live availability check) and hides the email
  field entirely for a vendor sign-in, sending `user.email` straight
  through to `createProfile` instead.
- Deleting `MockPlayer.avatarChoices` once nothing references it.

**Out of scope:**
- Real image/picture avatars (uploaded photos or illustrated assets). The
  `avatars` Storage bucket already exists for a *future* custom-photo-upload
  feature (`storage_buckets.sql`'s own comment: "for a future custom-avatar
  upload, not in v1's scope") — that is a separate, larger feature and not
  what this plan builds.
- Migrating other avatar-rendering surfaces (home top bar, notifications,
  leaderboard, friends, duel) to anything other than the emoji string they
  already render — they are unaffected by this plan.
- Any change to the email sign-in route's own S-25 flow (it still needs to
  collect an email, since that route has none yet).
- A real country picker (S-25's country field stays the existing mocked
  `MockPlayer.countries` cycle — untouched, and not part of this request).
- An admin UI for managing `avatar_options` rows — rows are managed directly
  in Supabase (matching how `languages`/`rank_titles`/other reference tables
  are managed today).

## Research findings

- **S-25 already fires for Google/Apple, not just email.** `save_progress_
  sheet.dart`'s `_onSessionChange` (lines 89-123) pushes `AppRoutes.
  profileCreation` for *any* provider once `SessionSignedIn` arrives with
  `isProfileComplete == false` — the code comment there is explicit: "A
  vendor never hands back a `profiles.username`... Google/Apple need S-25
  exactly as much as the email route already gets it, just via a different
  entry point." No router or gating change is needed.
- **`AuthUser.isProfileComplete`** (`auth_user.dart:42`) is `username !=
  null`, computed in `AuthApi._toAuthUser` (`auth_api.dart:194`). A vendor
  sign-in's `profiles` row is created by the `_handle_new_user` trigger
  (`20260907120200_functions_and_triggers.sql:21-34`), which never sets
  `username` — confirmed no per-vendor default exists anywhere.
- **`profiles.avatar_key`** (`20260907120000_initial_schema.sql:40-43`) is
  `text not null default '🐼'`, and its own comment says it is "stored as
  the emoji itself... not a lookup key into an asset catalogue" — this
  plan keeps that contract; only the *set of offered choices* moves
  server-side, the column itself is untouched.
- **The exact pattern to mirror already exists**: `features/onboarding`'s
  language picker is a live, backend-driven reference-data picker built the
  same shape this plan needs:
  - `data/languages_api.dart` — `SupabaseClient` query, `.eq('is_active',
    true).order('sort_order')`, maps rows to a domain model, wraps errors
    in `ApiException.fromSupabase`.
  - `data/languages_repository.dart` — a thin pass-through with no logic
    of its own.
  - `domain/language_option.dart` — a `freezed` model, one field per column.
  - `presentation/bloc/language_picker_cubit.dart` +
    `language_picker_state.dart` — `Loading`/`Loaded`/`Error` sealed states,
    one `load()` method.
  - `presentation/screens/language_picker_screen.dart:38-44` — wraps the
    view in `BlocProvider<LanguagePickerCubit>(create: (_) =>
    LanguagePickerCubit(LanguagesRepository(LanguagesApi(supabase)))
    ..load(), ...)`, i.e. built and loaded right where it's provided, no
    app-root registration (correct per CLAUDE.md §3 — this is screen-local
    state, not app-wide).
  - This plan's `avatars_api.dart`/`avatars_repository.dart`/
    `avatar_option.dart`/`avatar_picker_cubit.dart` follow this shape file
    for file.
- **Reference-table RLS pattern**, confirmed across `rank_titles`,
  `app_settings`, `difficulty_tiers`, and `languages`
  (`20260910090400_ladder_rls_and_grants_cleanup.sql:26-28`):
  ```sql
  alter table public.<t> enable row level security;
  create policy <t>_select_all on public.<t> for select using (true);
  ```
  No additional `grant select` statement is needed — Postgres's default
  privileges already cover it for every other reference table in this
  schema.
- **Test convention for a thin pass-through repository**: `LanguagesRepository`
  has **no** dedicated repository test file — only `language_picker_cubit_
  test.dart` exists, mocking `LanguagesRepository` directly with `mocktail`
  (`class _MockLanguagesRepository extends Mock implements
  LanguagesRepository {}`). `AvatarsRepository` should follow the same
  convention: no repository test, since it has zero logic beyond a
  pass-through call (CLAUDE.md §11's repository-test rule is for
  repositories with real mapping/error-handling logic to verify, which a
  bare pass-through doesn't have — matching how this codebase already
  treats `LanguagesRepository`).
- **Seed-data gap to avoid repeating**: `languages`' actual rows exist only
  in the live Supabase project — there is no `insert into public.languages`
  anywhere in `supabase/migrations/` or `supabase/seed.sql`, meaning a fresh
  local/staging database would have an empty table. This plan's migration
  seeds `avatar_options` **inside the migration itself**, idempotently
  (`insert ... on conflict do nothing`), matching the pattern
  `20260907130000_storage_buckets.sql` already uses for its own seed rows —
  so every environment (local, staging, prod) gets the same 8 avatars the
  moment the migration runs, with no separate live-only step.
- **S-25's current structure** (`profile_creation_screen.dart`): a single
  `StatefulWidget` owning username/email controllers, a `_avatarIndex` int,
  and a `_countryIndex` int. The avatar bubble (lines 208-244) is a
  `GestureDetector` that increments `_avatarIndex` modulo
  `MockPlayer.avatarChoices.length` on tap — this is the exact code being
  replaced with a picker-sheet trigger.
- **`AppBottomSheet.show`** (`core/widgets/app_bottom_sheet.dart:39-63`) is
  the app's one sheet-presentation entry point (CLAUDE.md §2's "shared
  widgets belong in core/" — this already exists there) — the avatar picker
  sheet is built with it, not a bespoke `showModalBottomSheet` call.
- **Vendor profile name**: `supabase_flutter`'s `User.userMetadata` exposes
  Supabase's `raw_user_meta_data`, which Google's OAuth provider populates
  with `full_name`/`name`; Apple populates it only on the *very first*
  authorization if the name scope was granted (may be absent on later
  sign-ins to the same Apple ID) — the fallback chain below already accounts
  for it being frequently empty.

## Assumptions & open questions

- **Avatar type (resolved with user):** backend-driven **emoji** catalog,
  not real image avatars. Real avatars would require a new image-asset
  pipeline and touch every avatar-rendering widget across the app
  (home top bar, notifications, leaderboard, friends, duel) — a
  significantly larger, separate piece of work. Flagged and confirmed
  before drafting.
- **Vendor prefill (resolved with user):** pre-fill display name from the
  vendor + hide the email field for Google/Apple, confirmed before drafting.
- **Apple's name may be empty.** Since Apple only ever supplies a name on
  the account's very first authorization to this app, `suggestedDisplayName`
  will often be `null` for Apple. The username field simply starts empty in
  that case (today's existing behavior) — no special-cased Apple copy is
  planned; if product wants Apple-specific messaging here, that's a
  follow-up, not part of this plan.
- **Uniqueness of `suggestedDisplayName` isn't pre-checked.** It's dropped
  straight into the existing username field, which already runs the live
  `isUsernameAvailable` debounce check on every keystroke — so a taken
  suggested name surfaces the existing "Someone has this one" error exactly
  as if the player had typed it, needing no new handling.
- **Existing 8 emoji become the seed data**, preserving today's visual
  choices exactly; adding more later is a Supabase-side data change, no app
  release needed (matching `languages`' own "flip it on without a release"
  rationale).
- **No new l10n needed for the sheet's core copy** beyond one new string
  (a picker sheet title) — reusing `profileChangeAvatar` for the trigger's
  own label since it already reads naturally as a button/link.

## Design overview

**Backend:** one new table, `public.avatar_options`, plus its RLS policy,
in a new migration. No changes to `profiles` or any existing table/RPC.

**Flutter — data layer:** a new mini vertical slice inside the existing
`features/auth` folder (not a new top-level feature — this is auth-scoped
reference data feeding one auth screen, same relationship
`languages`/`LanguagePickerCubit` has to `features/onboarding`):

```
features/auth/
├── data/
│   ├── avatars_api.dart          # NEW
│   └── avatars_repository.dart   # NEW
├── domain/
│   └── avatar_option.dart        # NEW (freezed)
└── presentation/
    ├── bloc/
    │   ├── avatar_picker_cubit.dart    # NEW
    │   └── avatar_picker_state.dart    # NEW
    ├── screens/
    │   └── profile_creation_screen.dart  # MODIFIED
    └── widgets/
        └── avatar_picker_sheet.dart     # NEW
```

**Flow:**
1. `ProfileCreationScreen.build` wraps its existing view in
   `BlocProvider<AvatarPickerCubit>(create: (_) =>
   AvatarPickerCubit(AvatarsRepository(AvatarsApi(supabase)))..load(), ...)`
   — same shape as `LanguagePickerScreen`.
2. The avatar bubble's `onTap` now calls `AppBottomSheet.show(context,
   builder: (_) => AvatarPickerSheet(selected: _avatarKey, onSelect: ...))`
   instead of incrementing an index.
3. `AvatarPickerSheet` reads `AvatarPickerCubit`'s state via `BlocBuilder`
   and renders `Loading` (spinner), `Error` (retry), or `Loaded` (a
   `GridView` of emoji bubbles, the selected one ringed in `quizoo.g` —
   same visual language the current bubble already uses) — closing the
   sheet via `Navigator.pop(context, emoji)` on tap.
4. `_create()` (the submit handler) is unchanged in shape — it still calls
   `SessionCubit.createProfile(..., avatarEmoji: _avatarKey, ...)`; only
   where `_avatarKey`'s value comes from has changed.

**Vendor prefill:**
1. `AuthUser` gains `String? suggestedDisplayName` (freezed field,
   regenerate `.freezed.dart`/`.g.dart`).
2. `AuthApi._toAuthUser` sets it from `authUser.userMetadata['full_name'] as
   String? ?? authUser.userMetadata['name'] as String?`, but **only** when
   `username == null` (i.e. only matters pre-profile-completion; a
   completed profile's `displayName` already comes from `username`).
3. `ProfileCreationScreen` reads `context.read<SessionCubit>().state.user`
   on `initState`, seeding `_username.text` with `user?.suggestedDisplayName
   ?? ''` when present, and computing `_isVendorSignIn = user?.provider !=
   AuthProvider.email`.
4. When `_isVendorSignIn`, the email `ProfileField` is not built at all
   (the `Column`'s children list omits it), and `_create()` passes
   `user!.email!` instead of `_email.text.trim()`. `_isValid` drops the
   email-completeness clause for this case.

## Data model / API changes

**New table** (new migration,
`supabase/migrations/20260920120000_avatar_options.sql`):

```sql
create table public.avatar_options (
  id uuid primary key default gen_random_uuid(),
  emoji text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

alter table public.avatar_options enable row level security;
create policy avatar_options_select_all
  on public.avatar_options for select using (true);

insert into public.avatar_options (emoji, sort_order) values
  ('🐼', 1),
  ('🦊', 2),
  ('🐯', 3),
  ('🦉', 4),
  ('🐨', 5),
  ('🐸', 6),
  ('🦁', 7),
  ('🐵', 8)
on conflict do nothing;
```

(`on conflict do nothing` here has no unique constraint to key off — since
`id` is a fresh `gen_random_uuid()` every run, use a guard instead so
re-running the migration doesn't duplicate rows:
`insert ... select ... where not exists (select 1 from public.avatar_options)`,
or add `unique (emoji)` and conflict on that column. Either is fine; pick
whichever this project's migration author prefers — flagging here rather
than silently picking one, since neither is used elsewhere in this schema.)

**Client read** (`AvatarsApi.fetchActiveAvatars`):
```dart
Future<List<AvatarOption>> fetchActiveAvatars() async {
  try {
    final rows = await _client
        .from('avatar_options')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return [
      for (final row in rows)
        AvatarOption(
          id: row['id'] as String,
          emoji: row['emoji'] as String,
          sortOrder: row['sort_order'] as int,
        ),
    ];
  } catch (error) {
    throw ApiException.fromSupabase(error);
  }
}
```

**`AuthUser` addition** (`auth_user.dart`):
```dart
/// The vendor's own profile name, offered as S-25's starting point for a
/// fresh Google/Apple sign-in — null once a username exists, or when the
/// vendor (most often Apple, on a repeat authorization) never supplied one.
String? suggestedDisplayName,
```

No change to `profiles.avatar_key` or any existing RPC/table.

## Dependencies

N/A — no new packages. Uses the existing `supabase_flutter`, `freezed`,
`flutter_bloc` already in `pubspec.yaml`.

## Implementation steps

**Phase 1 — Backend: avatar catalog**
- [ ] Add `supabase/migrations/20260920120000_avatar_options.sql`: create
      `public.avatar_options`, enable RLS with the `select_all` policy, seed
      the 8 existing emoji idempotently (resolve the conflict-target
      question above before writing the final `insert`).
- [ ] Apply the migration to the project's local/dev environment and
      confirm `select * from avatar_options` returns the 8 seeded rows.

**Phase 2 — Flutter: avatar data/domain/bloc stack**
- [ ] `lib/features/auth/domain/avatar_option.dart` — `freezed` model:
      `id` (String), `emoji` (String), `sortOrder` (int). Run
      `build_runner` to generate `.freezed.dart`/`.g.dart`.
- [ ] `lib/features/auth/data/avatars_api.dart` — `AvatarsApi(SupabaseClient)`
      with `fetchActiveAvatars()`, mirroring `LanguagesApi` exactly (query
      shape, error wrapping).
- [ ] `lib/features/auth/data/avatars_repository.dart` — thin pass-through,
      mirroring `LanguagesRepository`.
- [ ] `lib/features/auth/presentation/bloc/avatar_picker_state.dart` +
      `avatar_picker_cubit.dart` — sealed `AvatarPickerLoading`/`Loaded`/
      `Error` states and a `load()` method, mirroring
      `LanguagePickerCubit`/`LanguagePickerState` exactly.

**Phase 3 — Flutter: the picker sheet**
- [ ] `lib/features/auth/presentation/widgets/avatar_picker_sheet.dart` —
      a `StatelessWidget` taking `selectedEmoji` and returning the tapped
      emoji via `Navigator.pop`. Body: `BlocBuilder<AvatarPickerCubit,
      AvatarPickerState>` switching over `Loading` (centered
      `CircularProgressIndicator`), `Error` (reuse `core/widgets/
      error_state_view.dart`'s `ErrorStateView` with a retry that calls
      `context.read<AvatarPickerCubit>().load()`, matching
      `LanguagePickerScreen`'s own error handling), `Loaded` (a `GridView.
      builder` — 4 columns, one bubble per `AvatarOption`, using the same
      circular-container-with-border visual the bubble on S-25 already has,
      `quizoo.g` border + checkmark or scale-up on the selected one).
      Wrapped in `AppBottomSheet(title: l10n.<new key>, child: ...)`.
- [ ] Add one new l10n key (`profileChooseAvatar` or similar, e.g. "Choose
      your avatar") to `lib/l10n/app_en.arb` + regenerate/translate per the
      project's existing l10n workflow (`app_localizations*.dart`,
      `app_localizations_ur.dart`, `untranslated_messages.json` all show up
      as generated/derived files elsewhere in this repo's history — follow
      whatever command/process normally regenerates them here, e.g. `flutter
      gen-l10n`).

**Phase 4 — Flutter: wire S-25 to the real picker**
- [ ] `lib/features/auth/presentation/screens/profile_creation_screen.dart`:
  - Rename the current class body to a private `_ProfileCreationView`
    (`StatefulWidget`), and make `ProfileCreationScreen` a `StatelessWidget`
    that wraps it in `BlocProvider<AvatarPickerCubit>(create: (_) =>
    AvatarPickerCubit(AvatarsRepository(AvatarsApi(supabase)))..load(),
    child: const _ProfileCreationView())` — mirroring
    `LanguagePickerScreen`/`_LanguagePickerView`'s split exactly.
  - Replace `_avatarIndex` (int) with `_avatarKey` (`String`), defaulted
    from `context.read<SessionCubit>().state.user?.avatarEmoji ?? '🐼'` in
    `initState`.
  - Replace the avatar bubble's `onTap` (currently incrementing
    `_avatarIndex`) with `await AppBottomSheet.show<String>(context,
    builder: (_) => AvatarPickerSheet(selectedEmoji: _avatarKey))`, and on a
    non-null result, `setState(() => _avatarKey = result)`.
  - Delete the `_avatar` getter's dependency on `MockPlayer.avatarChoices`
    (now just returns `_avatarKey`).
- [ ] Same file — vendor prefill:
  - In `initState`, also read `final user = context.read<SessionCubit>()
    .state.user;` and seed `_username.text = user?.suggestedDisplayName ??
    ''` (only if the field was otherwise going to start empty — a
    resumed/partial profile with an already-typed username should not be
    clobbered, but since this is `initState` there is no prior value to
    clobber).
  - Compute `final bool _isVendorSignIn = user?.provider !=
    AuthProvider.email;` once in `initState` (store as a field).
  - In `build()`, only include the email `ProfileField` in the `ListView`'s
    `children` when `!_isVendorSignIn`.
  - Update `_isValid` to drop the `_isCompleteEmail(...)` clause when
    `_isVendorSignIn`.
  - Update `_create()`: when `_isVendorSignIn`, pass `user!.email!` as the
    `email` argument to `SessionCubit.createProfile` instead of
    `_email.text.trim()`.
- [ ] `lib/features/auth/domain/auth_user.dart`: add `String?
      suggestedDisplayName` field (with a doc comment matching the style of
      the existing fields), regenerate `.freezed.dart`/`.g.dart`.
- [ ] `lib/features/auth/data/auth_api.dart`: in `_toAuthUser`
      (`auth_api.dart:176-196`), compute
      `final suggestedDisplayName = username == null
          ? (authUser.userMetadata['full_name'] as String? ??
             authUser.userMetadata['name'] as String?)
          : null;`
      and pass it through to the returned `AuthUser`.
- [ ] `lib/core/mock/mock_player.dart`: delete `avatarChoices` once
      `profile_creation_screen.dart` no longer references it. Leave
      `avatarEmoji`, `countries`, and `takenUsernames` untouched (out of
      scope).

**Phase 5 — Tests**
- [ ] `test/features/auth/avatar_picker_cubit_test.dart` (new) — mirroring
      `test/features/onboarding/language_picker_cubit_test.dart`: mock
      `AvatarsRepository`, cover initial state (`AvatarPickerLoading`), a
      success path (`load()` → `AvatarPickerLoaded` with the mocked list),
      and a failure path (`load()` → `AvatarPickerError` on a thrown
      `ApiException`).
- [ ] No new `avatars_repository_test.dart` — matches this codebase's
      existing convention of not testing a bare pass-through repository
      (see Research findings).
- [ ] `test/features/auth/session_cubit_test.dart` or a new
      `auth_api`-level test (check whether this project unit-tests
      `AuthApi` directly anywhere before deciding placement — if not, add
      the `suggestedDisplayName` coverage as an `AuthUser`-shape assertion
      inside the existing vendor-sign-in `blocTest` in
      `session_cubit_test.dart`, since that test already builds a fake
      vendor `Session`/`User`): confirm a vendor `Session` whose `User.
      userMetadata` contains `full_name` produces an `AuthUser` with that
      value in `suggestedDisplayName` when `username` is null, and `null`
      when `userMetadata` is empty (the existing `_fakeSession()` helper in
      that file already has an empty `userMetadata: const {}` — add a second
      variant with `full_name` populated for the positive case).
- [ ] Widget-level: if this project has a `profile_creation_screen_test.dart`
      already (none was found during research), skip adding one — CLAUDE.md
      §11's widget-test bar is for screens with multiple `sealed`-state
      branches; S-25 has none (it's a single form, not a state-switched
      screen). Otherwise, a minimal test confirming the email field is
      absent for a vendor `SessionSignedIn` user and present for an email
      one would be reasonable to add if this project's reviewer wants it —
      noted as optional, not required.

## Testing strategy

Matches this project's existing conventions exactly:
- `bloc_test` for the new `AvatarPickerCubit` (initial + success + failure),
  per CLAUDE.md §11 and the `LanguagePickerCubit` precedent.
- No dedicated repository test for `AvatarsRepository` (bare pass-through,
  matching `LanguagesRepository`'s precedent — see Research findings).
- Extend the existing `session_cubit_test.dart` vendor-sign-in coverage for
  `suggestedDisplayName` rather than creating a new test file, since the
  fixture (`_fakeSession()`) already lives there.
- `dart analyze` clean and `dart format` run before considering any file
  done (CLAUDE.md §8).

## Edge cases & error handling

- **Avatar fetch fails** (network/RLS/table issue): `AvatarPickerSheet`
  shows `ErrorStateView` with retry — the player is never blocked from
  finishing sign-up; they can retry or, if they never open the sheet at
  all, `_avatarKey`'s pre-seeded default (`'🐼'` or the current
  `avatar_key`) still submits successfully.
- **`avatar_options` returns zero active rows**: `Loaded` state renders an
  empty grid; the default `_avatarKey` still submits — not a crash, just an
  unlikely misconfiguration to flag if seen (no special empty-state copy
  planned, matching how `LanguagePickerLoaded` doesn't special-case zero
  languages either).
- **Vendor gives no name at all** (Apple, most sign-ins): `suggestedDisplayName`
  is `null`, `_username` starts empty — identical to today's existing
  behavior for every provider, so no regression.
- **Vendor's suggested name is already taken**: surfaces through the
  existing live `isUsernameAvailable` check exactly as a manually-typed
  taken name would — no new handling needed.
- **Player picks an avatar, then backs out of the sheet without selecting**:
  `AppBottomSheet.show` resolves to `null` on dismiss; the calling code
  only updates `_avatarKey` on a non-null result, so backing out is a no-op
  (matches `LanguagePickerScreen`'s pattern of only acting on an explicit
  selection).
- **A resumed email sign-in with `_isVendorSignIn == false`**: entirely
  unaffected — the email field, its validation, and `_create()`'s existing
  `_email.text.trim()` path are untouched for this branch.

## Acceptance criteria

- [ ] `public.avatar_options` exists, RLS-readable by anyone, seeded with
      at least the original 8 emoji.
- [ ] A fresh Google or Apple sign-in that reaches S-25 shows: the username
      field pre-filled with the vendor's name when one was supplied (empty
      otherwise), no email field at all, and an avatar bubble that opens a
      real picker sheet listing every active `avatar_options` row.
- [ ] Picking a different avatar in the sheet updates the bubble shown on
      S-25 immediately, and that emoji is what gets saved to
      `profiles.avatar_key` on submit.
- [ ] Submitting from a vendor sign-in sends the vendor's own `email`
      (never an empty string) to `createProfile`.
- [ ] The existing email sign-in route's S-25 behavior (email field
      present, required, validated) is unchanged.
- [ ] `MockPlayer.avatarChoices` no longer exists / has no references.
- [ ] `dart analyze` is clean; new `bloc_test` coverage for
      `AvatarPickerCubit` passes; the extended vendor-sign-in test in
      `session_cubit_test.dart` passes.

## Risks & rollout notes

- **Migration ordering**: the new migration must run after
  `20260907120000_initial_schema.sql` (obviously) but has no dependency on
  any plan-007-era migration — it's fully independent, low-risk, additive
  DDL.
- **No backfill needed**: existing `profiles.avatar_key` values are
  untouched; this only changes where the *offered choices* come from for
  new sign-ups, not any stored data.
- **Rollback**: dropping `avatar_options` and reverting the Flutter changes
  is safe and non-destructive — no other table references it (no FK), and
  `profiles.avatar_key` has no constraint tying it to this table (it never
  did, and this plan doesn't add one — a player's stored emoji stays valid
  even if the catalog is later trimmed).
- **Follow-up worth flagging to the user, not part of this plan**: if
  "display picture" later needs to mean real images, that's a materially
  bigger effort (Storage assets, a new image-rendering widget swapped in
  across every avatar surface, and probably the very `avatars` bucket
  already reserved for user-uploaded photos) — worth its own plan rather
  than folding into this one.
