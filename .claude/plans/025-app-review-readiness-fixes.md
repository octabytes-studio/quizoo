# App Review Readiness Fixes

> Source spec: provided inline in conversation on 2026-10-17, after the App
> Review `Guideline 2.1 — Information Needed` message. The owner asked for a
> plan covering:
> 1. real account deletion (server + client) and removal of the `(mock)` copy;
> 2. hiding/removing the release-visible DEVELOPER section, dev routes,
>    `mock build` footer and mock share/stats strings;
> 3. the two `MockCatalog` crash paths and the empty countdown topic name;
> 4. attaching all three IAP products to the app version and sandbox-testing
>    the paywall on a release build;
> 5. wiring report-question, and adding player report/block plus username
>    filtering.
>
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history.
Read it in full before starting. Code may have moved on since it was written,
so spot-check every referenced file before editing.

Three hard constraints:

1. **`CLAUDE.md` §13: never run the app** — not on a simulator, device, or
   browser. All verification in this plan is static (`dart analyze`,
   `dart format`, tests, SQL checks). Anything that needs eyes-on confirmation
   is listed under **To verify** at the end for a human.
2. **Database changes go through the Supabase MCP `apply_migration`**, never
   `supabase db push` (convention from plans 007/017/020/023/024). Edge
   Functions deploy through the MCP `deploy_edge_function`.
3. **This plan includes destructive account deletion.** Read the SQL and the
   FK cleanup order in Phase 1 before applying anything. Test against a
   disposable account first; account deletion cannot be undone.

The static baseline on 2026-10-17 is green: `dart analyze` reports no issues
and `flutter test` reports 887 passing tests / 14 skipped. If either is not
green before starting, stop and fix that first.

## Objective

Make Quizoo 1.1.0 (2) genuinely ready for App Store review rather than merely
functional: account deletion must actually delete the auth user and all owned
data; the release build must not expose developer/mock surfaces; real topics
must not crash or show blank labels because they are absent from a fixture;
the three Pro products must be attached to the submitted version and proven in
sandbox; question reports must persist; and the app must offer the report/block
and username-moderation mechanisms Apple expects for public player names.

The work is deliberately staged so the highest-risk review blockers land
first, and so each phase can be verified independently.

## Scope

**In scope:**

- A server-side account-deletion path (SQL cleanup function + `delete-account`
  Edge Function), the client call, guest fallback, UI progress/error states,
  and removal of the `(mock)` wording.
- Release gating for the DEVELOPER settings group and the debug-only routes;
  a real version string; real share actions replacing the mock snackbars;
  removal of the mock stats/friends affordances and unused mock strings.
- `start_level_attempt` returning the topic name/category id; the client using
  those values instead of `MockCatalog`; fixing the profile best-category and
  badge-detail crash paths.
- App Store Connect product attachment, review screenshots, subscription
  ordering/labels, TestFlight sandbox purchase/restore verification, and the
  Android lifetime-product type correction.
- Persisting report-question submissions, with the real question id from both
  the play HUD and the failed-result review list.
- Player report/block tables, RPC/API, UI entry points, leaderboard filtering,
  matchmaking exclusions, blocked-player management, and a server-side
  username policy trigger.

**Out of scope:**

- A full moderation/admin dashboard. Reports are stored and reviewed by the
  owner through SQL; the plan documents the query.
- Friend-system implementation (`/friends` remains an unreachable design
  screen; this plan only removes its mock snackbar copy).
- Rewriting S-30's category-leaderboard header lookup. It still uses
  `MockCatalog`, but no release surface currently navigates to it (there is no
  call site for `AppRoutes.categoryLeaderboardPath`). Track it as a follow-up.
- Real screenshot/image capture for the App Store; the owner records those.
- Android store submission itself; only the RevenueCat product-type correction
  is included because it is cheap and prevents a later restore bug.
- Any pricing/trial decision. The owner already set the prices and the 1-week
  trial; the app renders store values.

## Research findings

### Live state (queried 2026-10-17, project `ughycvclcheuojifgkwx`)

- `48` profiles, `82,019` live questions, `43` active categories and `207`
  active subcategories across six content languages.
- `question_reports` has **0 rows**. The table and its insert-self/select-self
  RLS policies exist, but no client code writes to it.
- There is **no delete-account function** in `pg_proc` (0 matches).
- There is no `user_reports` or `user_blocks` table; `question_reports` is the
  only report table.
- `profiles.is_pro` is false for every row. `pro_subscriptions` contains only
  two expired Test Store monthly rows, so this is not evidence of a broken
  mirror; verify a fresh sandbox purchase after the Edge Function secrets are
  confirmed.

### RevenueCat (live, project `proj66ca87d0`)

The three iOS products exist and are attached to entitlement `quizoo_pro`,
offering `default`, packages `$rc_monthly` / `$rc_annual` / `$rc_lifetime`:

| Plan | iOS product id | US price | Trial | Store status |
|---|---|---|---|---|
| Monthly | `com.quizoo.play.monthly` | `$1.99` | 1 week | `needs_action` / `READY_TO_SUBMIT` |
| Yearly | `com.quizoo.play.yearly` | `$9.99` | 1 week | `needs_action` / `READY_TO_SUBMIT` |
| Lifetime | `com.quizoo.play.lifetime` | `$29.99` | — | `needs_action` / `READY_TO_SUBMIT` |

The subscription review screenshot is present only as a placeholder
(`filename: SOURCE`, 13 KB), and the App Store product display names are
generic (`Monthly`, `Yearly`). The products are **not yet submitted**.

Android note: `quizoo_pro_lifetime` (`prod3baa52e838`) is currently
`is_consumable: true` in RevenueCat. It must be non-consumable for restore to
work on Play.

### Code facts that drive the plan

- Account deletion is fake in exactly one place:
  `lib/features/settings/presentation/screens/delete_account_screen.dart:61-69`
  calls only `SessionCubit.continueAsGuest()`; the snackbar string is
  `"Account deleted (mock) — you're browsing as a guest"`
  (`lib/l10n/app_en.arb:1581`).
- The deletion blocker is not one FK: `level_attempts`, `score_events`,
  `wallet_ledger`, `question_reports`, `friendships`, `iap_transactions`,
  `duels` (p1/p2/winner/forfeited_by) and `app_notifications.challenger_id`
  reference `profiles` with `NO ACTION`. `auth.users → profiles` and most
  other profile children are `ON DELETE CASCADE`.
- Release-visible mock surfaces are ungated:
  - DEVELOPER group: `settings_screen.dart:174`;
  - version: `"Quizoo v1.0.0 (mock build)"` (`app_en.arb:1547`);
  - mock share snackbar (`commonSharedMock`, `app_en.arb:748`) used by
    `level_complete_screen`, `daily_result_screen`, `badge_unlocked_screen`,
    `topic_mastered_screen` and `router.dart`'s `_shareDemo`;
  - mock stats/friends snackbar (`commonMockFeature`, `app_en.arb:746`) used
    by `stats_screen.dart:60` and `friends_screen.dart:39`;
  - `/dev/screens` (`AppRoutes.screenIndex`) is registered unconditionally in
    `router.dart:418`; the report/share demo routes and the notification/
    force-update screens are likewise reachable in release.
- `MockCatalog.subcategories` has 26 entries; the live taxonomy has 207
  subcategories. Two direct lookups have no fallback and throw `StateError`:
  - `lib/features/profile/presentation/screens/profile_screen.dart:277`
    (tapping a "Best categories" row);
  - `lib/features/achievements/presentation/widgets/badge_detail_dialog.dart:122`
    (tapping a locked badge's "Play topic" CTA).
  The play surface has a third, non-crashing variant:
  `quiz_play_screen.dart:99-106` looks the topic up in the same 26-item list
  and passes `subcategoryName: ''`; `countdown_screen.dart:46` renders the
  blank label.
- The report sheet is opened from `quiz_play_screen.dart:351-372` but its
  `onSubmit` only pops and shows a snackbar. `level_failed_screen.dart:130`
  opens the **demo** route, which builds a fixture football question
  (`router.dart:480-503`).
- `ShareSheet` is real UI (`core/widgets/share_sheet.dart`), but every target
  callback is a mock snackbar; the level-complete share glyph pushes the demo
  route (`level_complete_screen.dart:150`).
- The account-deletion response can be implemented in the existing Edge
  Function style: `sync-pro-status/index.ts` verifies the bearer JWT with
  `admin.auth.getUser(token)` and calls a service-role RPC
  (`_shared/revenuecat.ts` shows the admin client). `supabase/config.toml`
  already has per-function `verify_jwt` entries.
- The project uses `bloc_test` + `mocktail`; widget tests live beside feature
  folders (`test/features/...`) and shared widgets in `test/core/widgets/`.
  `test/features/settings/delete_account_screen_test.dart` is currently an
  admitted placeholder and must become a real test.
- `flutter gen-l10n` is generated from `lib/l10n/app_en.arb` (template) and
  `app_ur.arb`; generated Dart files are checked in. Any new string needs both
  ARB files and a regeneration. Urdu deliberately ships an English subset, so
  adding English fallback strings to `app_ur.arb` is consistent with the
  existing pattern; `untranslated_messages.json` will change.

## Assumptions & open questions

- **Share approach:** this plan implements real WhatsApp/X/Copy actions using
  the already-present `url_launcher` and Flutter's `Clipboard`. It does not
  add `share_plus`. If the owner prefers to hide share instead, collapse
  Phase 2b to removing every `onShare` affordance and the share route.
- **Profanity list:** the username-policy term list is an owner-curated data
  set. This plan seeds reserved brand/role terms and a short common-profanity
  list; the owner can extend via SQL without a release. If the owner wants a
  licensed moderation service instead, that is a separate decision.
- **Retained purchase records:** the plan deletes `iap_transactions` and
  `revenuecat_events` rows tied to the user. Apple/RevenueCat retain their own
  billing records, and the Privacy Policy already says store billing records
  are not ours. Confirm this is acceptable before executing.
- **Guest account deletion:** guests are anonymous auth users but have no
  user-created account. The plan hides the Settings row for guests and shows
  an informational state if the route is reached. This avoids a dead-end
  screen for reviewers testing before account creation.
- **Version string:** the plan passes `APP_VERSION` from `scripts/build.sh`
  using the version already read from `pubspec.yaml`; IDE/test runs use the
  current default. This avoids adding `package_info_plus`.
- **IAP dashboard work is manual.** The code can only render what the store
  returns. Attaching products to the version, replacing review screenshots
  and using a sandbox account are owner/App Store Connect actions.
- **App Review reply is not code.** The reply/notes drafted in conversation
  must be updated after this plan lands so they describe the real deletion and
  safety flows. Do not send the old text claiming deletion works until Phase 1
  is shipped.

## Design overview

### 1. Account deletion

Add a service-role-only SQL function `public.delete_account_data(p_user_id
uuid)` that removes rows whose FKs would block the profile cascade. Then add a
`delete-account` Edge Function that:

1. verifies the caller's JWT;
2. calls `delete_account_data(user.id)` with the service-role client;
3. calls `admin.auth.admin.deleteUser(user.id)`, which cascades
   `profiles` and every `ON DELETE CASCADE` child;
4. returns `{ "deleted": true }`.

The app calls the function through `AuthApi`, then resets to a fresh anonymous
session exactly as `signOut()` already does. The screen shows progress and
only displays success after the function returns.

```
Flutter DeleteAccountScreen
  → SessionCubit.deleteAccount()
  → AuthRepository.deleteAccount()
  → AuthApi.deleteAccount()
  → supabase.functions.invoke('delete-account')
  → Edge Function verifies JWT
  → RPC delete_account_data(user.id)
  → auth.admin.deleteUser(user.id)
  → client signOut + signInAnonymously → SessionGuest
```

### 2. Release surface

A single `kDebugMode` gate excludes developer controls and demo routes from
release builds. All user-visible mock copy is either replaced with real
behavior (share) or removed (stats chip, friends mock CTAs). The version label
comes from a build-time define sourced from `pubspec.yaml`.

### 3. Topic context

The server already knows the topic/category. Extend the
`start_level_attempt` response with `subcategoryName` and `categoryId`,
carry them through `PreparedLevel`/`QuizPlayRepository`, and have
`QuizPlayCubit` read them when building `QuizRun`. Profile best-category rows
carry `categoryId` from the same query; badge progress carries
`nextCategoryId`/`nextSubcategoryName`. No presentation code needs
`MockCatalog` for navigation anymore.

### 4. Report question

Turn S-51 into a real route that receives a `ReportQuestionArgs` payload
(question id, text, topic/level context, content language). A small
`ReportQuestionCubit` inserts into the existing `question_reports` table and
reports success/failure. Both the play HUD and the failed-result missed-row
list use that route with the actual question id.

### 5. Player safety

Add two tables (`user_reports`, `user_blocks`) and a service-side
`_blocked_between(a,b)` helper. Blocking is enforced in three places:

- leaderboard rosters are filtered client-side by the viewer's block list;
- lobby feed/incoming requests exclude blocked players server-side;
- matchmaking pairing, challenge joins and join-request responses reject
  blocked pairs server-side.

Add a shared `PlayerActionsSheet` (report/block) to leaderboard rows and the
podium, plus a blocked-players management screen reached from Privacy. A
`profiles` trigger enforces a server-side username term policy; the two
profile screens map the new `username_not_allowed` error to human copy.

## Implementation steps

### Phase 0 — Baseline and pre-flight

- [ ] Confirm the working tree is clean or identify user-owned changes before
      touching anything (`git status`). Do not revert unrelated work.
- [ ] Run `dart analyze` and `flutter test` and record the baseline. Expected:
      no analyzer issues; 887 passing / 14 skipped.
- [ ] Re-query the live state with Supabase MCP: `pg_proc` has no
      delete-account function; 207 active subcategories; `question_reports` is
      empty; RevenueCat's three iOS products are `READY_TO_SUBMIT`.
- [ ] Read `CLAUDE.md` §§1–3, 9–13 and the existing plans 004 (S-52 stub),
      005 (auth), 017 (duels), 023 (Pro) before editing.

### Phase 1 — Real account deletion

#### 1.1 SQL cleanup function

Create a migration (suggested file
`supabase/migrations/20261017120000_account_deletion.sql`; apply through MCP
`apply_migration` with name `account_deletion`) containing:

```sql
create or replace function public.delete_account_data(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_duel_ids uuid[];
begin
  if p_user_id is null then
    raise exception 'user_id_required';
  end if;

  select coalesce(array_agg(id), '{}'::uuid[])
    into v_duel_ids
    from public.duels
    where p1 = p_user_id or p2 = p_user_id;

  -- app_notifications has NO ACTION FKs to profiles and duels.
  delete from public.app_notifications
   where user_id = p_user_id
      or challenger_id = p_user_id
      or duel_id = any (v_duel_ids);

  -- duels has NO ACTION FKs and a self-FK (rematch_of).
  update public.duels
     set rematch_of = null
   where rematch_of is not null
     and (p1 = p_user_id or p2 = p_user_id);

  delete from public.duels
   where p1 = p_user_id or p2 = p_user_id;

  delete from public.friendships
   where requester_id = p_user_id or addressee_id = p_user_id;

  delete from public.iap_transactions where user_id = p_user_id;
  delete from public.level_attempts    where user_id = p_user_id;
  delete from public.question_reports  where user_id = p_user_id;
  delete from public.score_events      where user_id = p_user_id;
  delete from public.wallet_ledger     where user_id = p_user_id;

  -- Provider ledger: our copy contains the user id in plain text.
  delete from public.revenuecat_events
   where app_user_id = p_user_id::text;
end;
$$;

revoke all on function public.delete_account_data(uuid)
  from public, anon, authenticated;
grant execute on function public.delete_account_data(uuid) to service_role;
```

Notes for the implementer:

- `profiles` is `ON DELETE CASCADE` from `auth.users`, and most profile-owned
  tables cascade from `profiles`. Do **not** delete `profiles` here; the Edge
  Function's `admin.deleteUser` does that and lets the cascade finish.
- `level_attempt_question_sets` and `user_question_history` reference
  `auth.users` directly with `ON DELETE CASCADE`, so they need no manual
  cleanup.
- `app_notifications.duel_id` has `NO ACTION`; delete the opponent's
  notifications tied to those duels too, as above.
- `duel_challenge_history` and `duel_challenges` set `duel_id` null; they do
  not block.
- If Phase 6 has already added `user_reports`/`user_blocks`, add:

```sql
delete from public.user_reports
 where reporter_id = p_user_id or reported_id = p_user_id;
delete from public.user_blocks
 where blocker_id = p_user_id or blocked_id = p_user_id;
```

  and re-apply the function in the Phase 6 migration so the final definition is
  the one in the database.

- After applying, confirm in a rolled-back transaction that the function
  exists and has the expected owner/grants:
  `select proname, proowner::regrole, prosecdef from pg_proc where proname =
  'delete_account_data';`

#### 1.2 `delete-account` Edge Function

Add `supabase/functions/delete-account/index.ts` modeled on
`supabase/functions/sync-pro-status/index.ts`:

- Reject non-POST with 405.
- Read the `Authorization: Bearer <jwt>` header; 401 if missing.
- `const admin = createSupabaseAdmin();` from `_shared/revenuecat.ts`.
- `const { data: { user }, error } = await admin.auth.getUser(token);` →
  401 on failure.
- `const { error: cleanupError } = await admin.rpc("delete_account_data", {
  p_user_id: user.id });` → 500 `"Account cleanup failed"` on error.
- `const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);`
  → 500 on error. If the error is a 404 / user-not-found, treat as success
  (a previous attempt may have completed after the client lost the response).
- Best-effort leaderboard refresh **after** the profile cascade:
  `await admin.rpc("_refresh_leaderboards")` inside a try/catch. The
  `lb_*` leaderboards are materialized views and otherwise retain the deleted
  player's row until the 2-minute cron tick (`_refresh_leaderboards` is the
  existing refresh function). A failed refresh must not fail the deletion;
  the cron is the backstop. If `service_role` lacks execute on that helper,
  add a tiny `refresh_leaderboards_after_deletion()` service-role wrapper in
  the same migration.
- Return `Response.json({ deleted: true })`.
- Log errors with `user.id` only, never emails or tokens.

Add to `supabase/config.toml`:

```toml
[functions.delete-account]
verify_jwt = true
```

Deploy with the Supabase MCP `deploy_edge_function` (`name: "delete-account"`,
`entrypoint_path: "index.ts"`, `verify_jwt: true`, including
`_shared/revenuecat.ts` in the uploaded files if the deploy tool requires the
relative dependency). If the MCP deploy tool cannot include `../_shared`,
inline a minimal admin-client helper in the function and leave a comment; do
not duplicate the RevenueCat logic.

#### 1.3 Client wiring

- [ ] `lib/features/auth/data/auth_api.dart`
  - Add `Future<void> deleteAccount()`:
    - invoke `delete-account` through `_client.functions.invoke`;
    - throw `ApiException` on status ≥ 400;
    - on success, call the same guest-reset path as `signOut()`.
  - Extract the body of `signOut()` into a private
    `Future<void> _restartAsGuest()` that:
    1. attempts `auth.signOut()` and swallows an invalid-session error;
    2. attempts `signInAnonymously()` and preserves the existing fallback
       behavior.
  - Map every thrown value with `ApiException.fromSupabase`, as the file does
    elsewhere.
- [ ] `lib/features/auth/data/auth_repository.dart`: add
      `Future<void> deleteAccount() => _api.deleteAccount();`.
- [ ] `lib/features/auth/presentation/bloc/session_cubit.dart`: add
      `Future<void> deleteAccount()` that awaits the repository, emits
      `SessionGuest` on success, and rethrows on failure (same contract as
      `signOut`).
- [ ] `lib/features/settings/presentation/screens/delete_account_screen.dart`:
  - add `_isDeleting` local state;
  - `_deletePermanently` becomes async; on success pop to the first route and
    show `deleteAccountDone`; on `ApiException` show a new
    `deleteAccountError` snackbar and keep the screen open;
  - disable the button and show a small progress indicator while deleting;
  - add a guard at the top: if `SessionCubit.state is SessionGuest`, render an
    informational state instead of the typed-username gate (or, if the row is
    hidden for guests in Settings, still handle a deep link gracefully).
- [ ] `lib/features/settings/presentation/screens/settings_screen.dart`: show
      the Delete account row only for `SessionSignedIn`. Do not show a
      destructive account action to a guest with no account.
- [ ] l10n:
  - change `deleteAccountDone` to `"Account deleted"` (no `(mock)`);
  - add `deleteAccountError` (e.g. `"We couldn't delete your account. Check
    your connection and try again."`);
  - add `deleteAccountGuestTitle` / `deleteAccountGuestBody` if the screen's
    guard needs copy.
- [ ] Verify the existing `SubscriptionCubit` auth-stream listener switches to
      the new anonymous user and clears the cached Pro flag. If it does not,
      explicitly have `SessionCubit.deleteAccount()` notify the subscription
      layer through the existing auth-state stream rather than adding a
      screen-level dependency.

#### 1.4 Tests

- [ ] `test/features/auth/session_cubit_test.dart`: success emits
      `[SessionGuest]`; failure rethrows and does not emit guest.
- [ ] `test/features/auth/auth_repository_test.dart`: delegation and error
      mapping.
- [ ] Replace the placeholder `test/features/settings/delete_account_screen_test.dart`
      with a widget test using mocked `SessionCubit`/`ProfileCubit`:
      - typed username gates the button;
      - success shows the success snackbar;
      - failure shows the error and leaves the screen open;
      - guest state renders the informational guard.
- [ ] Add a SQL smoke test (MCP `execute_sql`, wrapped in
      `begin; ... rollback;` when possible) that creates a disposable test
      user or uses a dedicated test account, calls
      `delete_account_data`, and asserts the NO ACTION tables are empty for
      that id. If auth-user creation is not safe through SQL, skip the SQL
      test and rely on the human sandbox test in **To verify**.

### Phase 2 — Release surface cleanup

#### 2.1 Gate developer UI and dev routes

- [ ] `settings_screen.dart`: import `package:flutter/foundation.dart` and wrap
      the DEVELOPER group (`_GroupLabel(settingsDeveloper)` through the
      notification-permission row) in `if (kDebugMode) ...[ ... ]`.
- [ ] `lib/app/router.dart`: import `foundation.dart` and register these routes
      only under `if (kDebugMode)`:
      - `AppRoutes.screenIndex`;
      - `AppRoutes.share` (the demo sheet; after 2.3 the real share is opened
        inline, so this route has no release call site);
      - `AppRoutes.notificationPermission`;
      - `AppRoutes.forceUpdate`.
      Keep `AppRoutes.reportQuestion` registered after Phase 5 makes it real.
      Keep `AppRoutes.offline` (it is a real offline state route, not a dev
      demo).
- [ ] `lib/features/leaderboard/presentation/screens/friends_screen.dart`:
      remove `_showMockSnackbar` and every call site (`_InviteCard`, the empty
      state's Invite/Find people actions, the Add-friend button, and the
      friend-row Duel action). The screen remains an unreachable design
      screen; use a neutral empty-state body without a button that promises a
      missing feature.
- [ ] `lib/features/profile/presentation/screens/stats_screen.dart`: remove the
      tappable `AppChip.status(label: l10n.statsRangeChip)` and the
      `commonMockFeature` snackbar. Do not replace it with a different fake
      filter.
- [ ] Remove `commonMockFeature` from `app_en.arb`/`app_ur.arb` once no call
      sites remain. Remove `statsRangeChip` if the chip is deleted. Keep
      `forceUpdateMock` and `devPlaceholderBody` only if their routes are
      debug-gated; otherwise remove them too.

#### 2.2 Real version label

- [ ] Add `lib/core/app_version.dart`:

```dart
/// Read from `--dart-define=APP_VERSION=...` by scripts/build.sh; the default
/// keeps IDE/test builds honest and must match pubspec.yaml at release time.
const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.1.0 (2)',
);
```

- [ ] In `scripts/build.sh`, after `VERSION` is read, add:
      `DART_DEFINE_ARGS+=(--dart-define=APP_VERSION="$VERSION")`.
- [ ] Change `settingsVersion` in the ARB files to `"Quizoo v{version}"` with a
      `version` placeholder; pass `appVersion` from the Settings footer.
- [ ] Do not add `package_info_plus`; the build script is the single source of
      truth for release builds.

#### 2.3 Replace mock share with real share

- [ ] Add `lib/core/share/share_links.dart`:

```dart
abstract final class ShareLinks {
  static Future<bool> whatsApp(String text) =>
      _launch(Uri.https('wa.me', '/', {'text': text}));

  static Future<bool> x(String text) =>
      _launch(Uri.https('x.com', '/intent/post', {'text': text}));

  static Future<bool> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] Add ARB strings for share text and feedback:
  - `commonCopied` (`"Copied to clipboard"`);
  - `commonShareFailed` (`"Couldn't open that app"`);
  - one share-text builder per surface (result, daily, badge, mastery), e.g.
    `shareResultText`, `shareDailyText`, `shareBadgeText`,
    `shareMasteryText`. Keep them spoiler-free (no answers).
- [ ] Replace every `_confirmShared` mock snackbar:
  - `level_complete_screen.dart`: open a `ShareSheet` inline with a result
    preview and `ShareLinks` targets; stop pushing `AppRoutes.share`.
  - `daily_result_screen.dart`, `badge_unlocked_screen.dart`,
    `topic_mastered_screen.dart`: keep their existing sheets and previews,
    but wire the three targets to `ShareLinks` with their own text builders.
  - On success, close the sheet; for Copy show `commonCopied`; for an external
    launch failure show `commonShareFailed`.
- [ ] `router.dart`'s `_shareDemo` (debug-only after 2.1): replace its mock
      callback with the same `ShareLinks` calls and remove
      `commonSharedMock` from the ARB files.
- [ ] Remove `commonSharedMock` from `app_en.arb`/`app_ur.arb` and regenerate
      localizations.
- [ ] Add a unit test for `ShareLinks` URL construction (Use a pure helper for
      the Uri so the test does not launch anything) and for the share-text
      builders.

#### 2.4 Localization and tests

- [ ] Run `flutter gen-l10n`; check the generated `lib/l10n/*.dart` diff and
      `lib/l10n/untranslated_messages.json`.
- [ ] Update tests that expected mock copy. Add a release-surface test only if
      a testable constant is extracted; otherwise the release check is manual
      (see **To verify**).

### Phase 3 — Topic context and MockCatalog crash paths

#### 3.1 Return topic context from `start_level_attempt`

- [ ] Apply a migration (suggested name `start_level_attempt_topic_context`)
      that re-creates `public.start_level_attempt` from the **newest live
      body** — at the time of writing that is
      `supabase/migrations/20261006210547_play_question_media_and_figure_payloads.sql`
      (it is the migration that renamed `imageAsset` to `mediaUrl` and added
      `figureSvg`; `20261001175452_quizoo_pro_subscriptions.sql` is an older
      body and must not be used as the template) — and adds exactly two keys
      to the return object:

```sql
return jsonb_build_object(
  'attemptId', v_attempt_id,
  'secondsPerQuestion', v_tier.seconds_per_question,
  'isBoss', v_is_boss,
  'categoryId', (
    select s.category_id from public.subcategories s
     where s.id = p_subcategory_id
  ),
  -- Localized display name, not the English slug: Arabic/Urdu/Hindi
  -- subcategory slugs are English (e.g. 'abbasid-caliphate') while
  -- taxonomy_i18n carries the name for the attempt's locale.
  'subcategoryName', coalesce(
    (
      select t.name from public.taxonomy_i18n t
       where t.entity_type = 'subcategory'
         and t.entity_id = p_subcategory_id
         and t.locale = p_locale
    ),
    (select s.slug from public.subcategories s
      where s.id = p_subcategory_id),
    ''
  ),
  'questions', coalesce(v_questions, '[]'::jsonb)
);
```

- [ ] Verify the live function still returns the existing keys and the new
      ones for a real `subcategory_id` via `execute_sql` in a rolled-back
      transaction. Do not change the level-lock, question selection, attempt
      row or history behavior.

#### 3.2 Carry the context through the client

- [ ] `lib/features/quiz_play/data/quiz_play_api.dart`:
  - add `required String categoryId` and `required String subcategoryName` to
    `PreparedLevel`;
  - parse `response['categoryId'] as String? ?? ''` and
    `response['subcategoryName'] as String? ?? ''` in `fetchLevelQuestions`
    (tolerant of a rolled-back server function during a staged rollout).
- [ ] `lib/features/quiz_play/data/quiz_play_repository.dart`: add
      `categoryIdFor(levelId, {languageCode})` and
      `subcategoryNameFor(levelId, {languageCode})`, mirroring
      `secondsPerQuestionFor`/`isBossFor`.
- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart`:
  - remove the `categoryId` and `subcategoryName` parameters from
    `startLevel`;
  - after `questionsFor` resolves, read
    `_repository.categoryIdFor(...) ?? ''` and
    `_repository.subcategoryNameFor(...) ?? ''` when constructing `QuizRun`;
  - keep `subcategoryId`/`levelNumber` parsing from `MockCatalog.parseLevelId`
    for now (it is a pure ID-format helper, not fixture data).
- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`: drop
      the `MockCatalog.subcategories` lookup and the two arguments; remove the
      `core/mock/mock_catalog.dart` import. The countdown will now show the
      server-provided `subcategoryName`.
- [ ] Fix the daily countdown's blank equivalent: `startDaily` deliberately
      leaves `subcategoryName: ''`, so `countdown_screen.dart:46` currently
      renders `" · LEVEL 0"` for the daily challenge. Add a
      `countdownDailyMeta` string (e.g. `"DAILY CHALLENGE"`) and have the
      countdown render it when `state.run.isDaily`, instead of
      `countdownMeta`. This is the same visible blank-label bug under a
      second entry point.
- [ ] Update the three test fakes that construct `PreparedLevel`
      (`quiz_play_repository_test`, `quiz_play_screen_test`,
      `level_brief_sheet_test`) and the `startLevel` call in
      `quiz_play_cubit_test`.

#### 3.3 Profile best-category navigation

- [ ] `lib/features/profile/domain/profile_summary.dart`: add
      `required String categoryId` to `BestCategoryEntry`.
- [ ] `lib/features/profile/data/profile_api.dart` `_bestCategories`:
      select `category_id` from `subcategories` and pass it into the entry.
- [ ] `lib/features/profile/presentation/screens/profile_screen.dart`: navigate
      with `AppRoutes.levelMapPath(entry.categoryId, entry.subcategoryId)`;
      remove the `MockCatalog` import.
- [ ] `test/features/profile/profile_screen_test.dart`: add a case with a
      non-fixture subcategory id and assert the correct level-map route is
      pushed (or the correct route path is built).

#### 3.4 Badge detail navigation

- [ ] `lib/features/achievements/domain/badge_progress.dart`: add optional
      `nextCategoryId` and `nextSubcategoryName`.
- [ ] `lib/features/achievements/data/achievements_api.dart`:
  - extend `_ClosestProgress` with `nextCategoryId`/`nextSubcategoryName`;
  - in `_categoryKingProgress`, set `nextCategoryId = bestCategoryId` and
    `nextSubcategoryName = subcategoryRows.first['slug']` alongside
    `nextSubcategoryId`;
  - pass both through `_progressFromRow`.
- [ ] `lib/features/achievements/presentation/widgets/badge_detail_dialog.dart`:
      use `progress.nextSubcategoryName` for the label and
      `progress.nextCategoryId` + `progress.nextSubcategoryId` for the route;
      show the CTA only when all three are non-null; remove the `MockCatalog`
      import and the `_subcategoryName` fallback.
- [ ] Add a widget test for a badge whose next topic is not in the fixture
      list; tapping the CTA must not throw and must build the correct route.

#### 3.5 Residual

- [ ] Leave `category_leaderboard_screen.dart`'s fallback-to-Football alone
      only if it remains unreachable. Add a one-line note in the plan's
      follow-ups; do not let this phase silently expand into a catalog
      refactor.

### Phase 4 — IAP attachment and sandbox proof (owner/manual)

These are App Store Connect + device actions; the agent must not run the app.

#### 4.1 App Store Connect

- [ ] Open the `1.1.0 (2)` version page → **In-App Purchases and
      Subscriptions** and add all three:
      `com.quizoo.play.monthly`, `com.quizoo.play.yearly`,
      `com.quizoo.play.lifetime`. The first subscription must be submitted
      with this version.
- [ ] Replace each product's review screenshot with a real paywall screenshot
      (the current RevenueCat state shows the placeholder `SOURCE`).
- [ ] In the `Quizoo Pro` subscription group, put **Yearly above Monthly**
      (plan 023's upgrade/downgrade rule) and use clear display names:
      `Quizoo Pro Monthly`, `Quizoo Pro Yearly`. Keep the lifetime product's
      name `Quizoo Pro Lifetime`.
- [ ] Confirm the 1-week free trial is attached to both subscriptions and
      that the price/period shown on the paywall is store-provided.
- [ ] Confirm the paid-apps agreement, tax and banking are complete.

#### 4.2 RevenueCat hygiene

- [ ] Confirm the `default` offering contains the three packages and the
      `quizoo_pro` entitlement contains all three iOS products (already true
      on 2026-10-17).
- [ ] Android only: change `prod3baa52e838` (`quizoo_pro_lifetime`) from
      consumable to non-consumable:
      `update-product` with `body.type = "non_consumable"`. If RevenueCat
      rejects the type change, archive the product, recreate it as
      non-consumable, and re-attach it to `$rc_lifetime`. Do not change the
      Android store SKU.

#### 4.3 TestFlight / sandbox

- [ ] Build a release IPA with `scripts/build.sh ipa` (the script forces
      `SHOW_TEST_ADS=false` and now passes `APP_VERSION`).
- [ ] Upload to TestFlight and install on a physical iPhone running the latest
      iOS.
- [ ] In App Store Connect, create/use a sandbox tester; on the device, sign
      out of the production App Store account and use the sandbox account for
      purchases.
- [ ] Verify:
  - the paywall loads all three plans (not the unavailable state);
  - monthly/yearly show the 1-week trial and the disclosure;
  - a sandbox purchase reaches the welcome/membership screens;
  - ads disappear, locked levels open, power-ups double, the free revive
    appears, Pro avatars are selectable, answer review is available;
  - **Restore Purchases** finds the purchase after reinstall;
  - the management link opens the store's subscription page;
  - `profiles.is_pro` becomes true (allow the webhook a minute; if not, check
    the RevenueCat Edge Function secrets and the webhook delivery log).
- [ ] Confirm the final submitted build is the same build tested.

#### 4.4 Docs

- [ ] Update `.claude/docs/backend/03-store-iap-push-setup.md` to the actual
      iOS product IDs (`com.quizoo.play.monthly`/`.yearly`/`.lifetime`), the
      actual prices/trial (if the owner wants them documented), and mark
      checklist items 1–3 as done once they are.
- [ ] Record the sandbox test date and result in the doc.

### Phase 5 — Real report-question flow

#### 5.1 Domain and data

- [ ] Add `lib/features/quiz_play/domain/report_reason.dart` with a small enum
      carrying a stable server code and an ARB label key:

```dart
enum ReportReason {
  wrong('wrong'),
  unclear('unclear'),
  translation('translation'),
  offensive('offensive'),
  image('image');
  const ReportReason(this.code);
  final String code;
}
```

- [ ] Add to `QuizPlayApi`:

```dart
Future<void> reportQuestion({
  required String questionId,
  required String reasonCode,
  required String locale,
}) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) {
    throw const ApiException('Not signed in',
        kind: ApiErrorKind.unauthorized);
  }
  try {
    await _client.from('question_reports').insert({
      'question_id': questionId,
      'user_id': userId,
      'locale': locale,
      'reason': reasonCode,
    });
  } catch (error) {
    throw ApiException.fromSupabase(error);
  }
}
```

- [ ] Add `QuizPlayRepository.reportQuestion(...)` delegating to the API.
      No new table or RLS policy is needed: `question_reports` already has
      insert-self and select-self policies.

#### 5.2 Presentation

- [ ] Add `ReportQuestionCubit` + sealed state
      (`ReportQuestionIdle`, `ReportQuestionSending`,
      `ReportQuestionSent`, `ReportQuestionFailed`) in
      `features/quiz_play/presentation/bloc/`.
- [ ] Add `ReportQuestionArgs` (question id, question text, topic/level label,
      language code) in `features/quiz_play/domain/` — not in the screen file,
      so `features/quiz_result` can construct it without importing another
      feature's presentation layer — and a real `ReportQuestionScreen` under
      `features/quiz_play/presentation/screens/`.
- [ ] Replace `router.dart`'s `_reportQuestionDemo` route builder with
      `ReportQuestionScreen(args: state.extra as ReportQuestionArgs?)`. In
      debug builds only, allow a null-arg fallback to the old fixture; in
      release, a null arg should show a clean empty/error state instead of a
      fixture question.
- [ ] `quiz_play_screen.dart` `_openReportSheet`: push
      `AppRoutes.reportQuestion` with the current question id, text,
      topic/level label and content language instead of opening the sheet
      inline.
- [ ] `level_failed_screen.dart`: replace `context.push(AppRoutes.reportQuestion)`
      with a push carrying the tapped `answer.question.id`, its text, the run's
      topic/level and language. This removes the "tap a missed question, see a
      random football question" bug.
- [ ] The screen builds the localized reason list from `ReportReason.values`,
      maps the selected index to the code, calls the cubit, shows
      `reportQuestionSent` on success and a new `reportQuestionError` on
      failure, then pops.
- [ ] Remove the old demo `question` import/fixture use from `router.dart` if
      it becomes unused.

#### 5.3 Tests / verification

- [ ] Cubit test: success emits `Sent`; failure emits `Failed` with the mapped
      error.
- [ ] Widget test: selecting a reason enables Submit; success closes the
      screen; failure keeps it open.
- [ ] SQL check after a manual report: the row exists with the expected
      `question_id`, `user_id`, `locale` and `reason`.
- [ ] Add the moderation query to the plan/docs:
      `select * from public.question_reports where resolved = false order by
      created_at;`.

### Phase 6 — Player safety: report, block, username policy

This phase is larger and should be applied only after Phase 1 is live, because
it extends the delete-account cleanup.

#### 6.1 Schema and RLS

Create `supabase/migrations/<timestamp>_player_safety.sql` and apply via MCP:

```sql
create table if not exists public.user_reports (
  id bigserial primary key,
  reporter_id uuid not null references public.profiles(id),
  reported_id uuid not null references public.profiles(id),
  reason text not null,
  note text,
  resolved boolean not null default false,
  created_at timestamptz not null default now(),
  constraint user_reports_no_self check (reporter_id <> reported_id)
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id),
  blocked_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_no_self check (blocker_id <> blocked_id)
);
```

- [ ] Enable RLS on both.
- [ ] `user_reports`: insert-self (`reporter_id = auth.uid()`) and select-self
      (`reporter_id = auth.uid()`) policies; no update/delete for clients.
- [ ] `user_blocks`: select/insert/delete-self policies
      (`blocker_id = auth.uid()`); no access for the blocked user.
- [ ] Revoke direct table privileges if the project's default grants expose
      too much; the client will use the Data API only through these policies.

#### 6.2 Helpers and duel enforcement

- [ ] Add a private helper:

```sql
create or replace function public._blocked_between(p_a uuid, p_b uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_blocks
    where (blocker_id = p_a and blocked_id = p_b)
       or (blocker_id = p_b and blocked_id = p_a)
  );
$$;
revoke all on function public._blocked_between(uuid, uuid)
  from public, anon, authenticated;
```

- [ ] Re-create the affected functions from their current live bodies, adding
      only the block predicates:
  - `public._duel_try_pair`: add
    `and not public._blocked_between(p_user_id, q.user_id)` to the candidate
    query;
  - `public.request_duel_join`: after the `own_challenge` check, raise
    `blocked` when `_blocked_between(v_me, v_c.creator_id)`;
  - `public.respond_duel_join`: likewise reject a request from a blocked
    requester;
  - `public.get_duel_lobby`: add
    `and not public._blocked_between(v_me, f.creator_id)` to the feed query,
    and hide `v_incoming` when the requester is blocked.
  - Keep every other line of these functions byte-for-byte identical. Add a
    header comment listing the added predicates.
- [ ] Extend `delete_account_data` with the two safety-table deletes from
      Phase 1.1 (both reporter/blocker and reported/blocked sides) and re-grant
      execute.

#### 6.3 Client safety API

Create `lib/core/safety/` (shared by leaderboard and duels; both are existing
features, so core is the correct home for the shared repository):

- [ ] `safety_api.dart`:
  - `Future<Set<String>> blockedIds()` — select `blocked_id` for the current
    user from `user_blocks` (RLS only exposes rows where the caller is the
    blocker, which is what the leaderboard filter needs; server-side
    `_blocked_between` handles mutual exclusion for duels);
  - `Future<List<BlockedPlayer>> blockedPlayers()` — join `profiles` for
    name/avatar, ordered by `created_at`;
  - `Future<void> block(String playerId)` — upsert `(blocker_id, blocked_id)`;
  - `Future<void> unblock(String playerId)` — delete the row;
  - `Future<void> reportPlayer({required String playerId, required String
    reason, String? note})` — insert into `user_reports` with the current user
    as reporter.
  - Map every error to `ApiException`.
- [ ] `safety_repository.dart` wrapping the API.
- [ ] `safety_cubit.dart` + sealed state for the actions sheet:
  `idle`, `busy`, `done(message)`, `failed(error)`; expose `isBlocked` for
  the target player.
- [ ] `domain/blocked_player.dart` (id, name, avatar, blockedAt).

#### 6.4 UI entry points

- [ ] Add `lib/core/widgets/player_actions_sheet.dart`:
  - title with the player's name;
  - "Report player" → a small reason list (offensive name, harassment,
    cheating, impersonation, other) and a submit button;
  - "Block player" / "Unblock player";
  - a busy state and error snackbar.
  - Uses `AppBottomSheet`, `ListRowTile`, `ChunkyButton`, and the existing
    `AppSnackbar`; follows the theme/spacing rules.
- [ ] `leaderboard_screen.dart`:
  - pass `onTap` to `Podium` and add a small `⋯` affordance to non-self
    `_LeaderboardRow`s; both open the actions sheet;
  - after a block/unblock, reload the leaderboard cubit so the row disappears
    or returns immediately.
- [ ] `leaderboard_api.dart`: add a private `_blockedIds()` helper (select the
      viewer's own `blocked_id` rows) and filter `fetchRoster`,
      `fetchCategoryRoster` and `_friendsRoster` results so a blocked player
      is hidden from the blocker's leaderboard. Keep `fetchSelfEntry`
      untouched.
- [ ] Optional but cheap: add `onOpponentTap` to `VsHeader` and wire it from
      `live_duel_screen.dart` / `duel_result_screen.dart` so an in-duel
      opponent can also be reported/blocked. Skip if the leaderboard entry
      point is already covered and the phase is getting long; note it as a
      follow-up.
- [ ] `privacy_settings_screen.dart`: remove the two fake `setState` toggles
      (`_showOnLeaderboards`, `_showActivityToFriends`). Keep the conditional
      "Ad privacy choices" row. Add a "Blocked players" row that pushes a new
      `BlockedPlayersScreen` (list + Unblock), plus a one-line helper that
      explains blocked players are hidden from leaderboards and matchmaking.
- [ ] Add `AppRoutes.blockedPlayers` (e.g. `/settings/blocked-players`) and
      register it in `router.dart`; it is a real settings route, not a dev
      demo. Put the screen at
      `lib/features/settings/presentation/screens/blocked_players_screen.dart`
      (the data/cubit live in `core/safety/`), and reuse `SimpleTopBar`,
      `ListRowTile` and the existing `EmptyStateView`.
- [ ] Remove the now-unused privacy toggle strings from the ARB files.

#### 6.5 Username policy

- [ ] In the same safety migration (or a separate
      `<timestamp>_username_policy.sql`), add:

```sql
create table if not exists public.username_policy_terms (
  term text primary key,
  kind text not null default 'profanity'
    check (kind in ('reserved', 'profanity'))
);
alter table public.username_policy_terms enable row level security;
revoke all on public.username_policy_terms from public, anon, authenticated;

insert into public.username_policy_terms (term, kind) values
  ('quizoo', 'reserved'),
  ('admin', 'reserved'),
  ('administrator', 'reserved'),
  ('moderator', 'reserved'),
  ('official', 'reserved'),
  ('support', 'reserved'),
  ('helpdesk', 'reserved'),
  ('staff', 'reserved'),
  ('fuck', 'profanity'),
  ('shit', 'profanity'),
  ('bitch', 'profanity'),
  ('cunt', 'profanity'),
  ('nazi', 'profanity'),
  ('hitler', 'profanity'),
  ('rape', 'profanity'),
  ('slut', 'profanity'),
  ('whore', 'profanity')
on conflict (term) do nothing;
```

  The owner should extend this list; no app release is needed for data-only
  additions.

- [ ] Add a normalized-policy helper and trigger. Normalization must strip
      punctuation/spaces, lowercase, and map common leet substitutions:

```sql
create or replace function public._username_is_allowed(p_username text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select not exists (
    select 1
    from public.username_policy_terms t
    where translate(
            regexp_replace(lower(p_username), '[^a-z0-9]', '', 'g'),
            '013457@$', 'oieastas'
          ) like '%' || t.term || '%'
  );
$$;

create or replace function public._enforce_username_policy()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  if new.username is not null
     and not public._username_is_allowed(new.username) then
    raise exception 'username_not_allowed';
  end if;
  return new;
end;
$$;

revoke all on function public._username_is_allowed(text)
  from public, anon, authenticated;

drop trigger if exists trg_enforce_username_policy on public.profiles;
create trigger trg_enforce_username_policy
  before insert or update of username on public.profiles
  for each row execute function public._enforce_username_policy();
```

  The existing `profiles` insert trigger from auth must remain unaffected; a
  null username passes. Add a read-only audit query for existing usernames
  that would violate the policy, and decide manually whether to rename them.

- [ ] Client error mapping:
  - `AuthApi.createProfile`/`updateProfile` already throw
    `ApiException.fromSupabase`; a Postgres `raise exception
    'username_not_allowed'` arrives as `code == 'username_not_allowed'` via
    the P0001 mapping in `api_exception.dart`.
  - `ProfileCreationScreen._create` and `EditProfileScreen._save`: show a new
    `profileUsernameNotAllowed` string for that code instead of the generic
    `profileUpdateError`.
  - Add the string to both ARB files and regenerate.
  - Optional: add a `username_is_allowed` client pre-check for inline feedback;
    not required because the trigger is authoritative and the save path now
    maps the error.

#### 6.6 Report/block tests

- [ ] Repository tests with mocked `SafetyApi`: blocked ids, block/unblock,
      report insert, error mapping.
- [ ] Cubit tests: busy → done / failed.
- [ ] Widget test for `PlayerActionsSheet`: report opens reasons; block shows
      the blocked state; unblock clears it.
- [ ] Leaderboard cubit/API test: a blocked id is removed from roster,
      category roster and friends roster.
- [ ] SQL smoke test for `_username_is_allowed`: reserved term rejected,
      leet/punctuation variant rejected, clean name accepted. Test the helper
      directly; if inserting into `profiles` needs an auth user, use a
      disposable test user or the rolled-back transaction pattern.
- [ ] SQL smoke test for `_blocked_between` and the duel predicates (at least
      the helper and a candidate-row exclusion query).

### Phase 7 — Documentation, App Review text, and final verification

- [ ] Update `MOCKED_FEATURES.md` with a dated "2026-10-17 App Review fixes"
      section marking:
  - account deletion resolved (server + client);
  - report-question resolved;
  - mock share/stats/settings surfaces removed;
  - player report/block and username policy added.
- [ ] Update `website/privacy.html` §3/§9/§16 to mention report/block records
      and that moderation data is used to keep public names safe. Update
      `website/terms.html` §4 if needed (it already prohibits harassment).
      The deletion page is already accurate once Phase 1 lands.
- [ ] Update `.claude/docs/backend/03-store-iap-push-setup.md` product IDs and
      checklist status (Phase 4.4).
- [ ] Update the App Review reply/notes drafted in conversation:
  - item 1 recording now includes the real deletion and, if Phase 6 lands,
    the report/block mechanism;
  - item 3 says deletion is immediate and server-side, with the exact
    Settings path;
  - item 4 mentions the safety/moderation data if asked;
  - item 6 remains "not a regulated industry" plus open-license image credits.
  Do not send the old reply before Phase 1 is live.
- [ ] Run `dart format .` (or the project's format command), `dart analyze`,
      `flutter gen-l10n`, and `flutter test`. Zero analyzer issues; all tests
      green.
- [ ] Inspect a release build (static inspection or `flutter build ios
      --no-codesign` if the owner permits) to confirm:
  - no `DEVELOPER` group;
  - no `mock`/`mock build` visible strings;
  - no `/dev/screens` route registration in release (kDebugMode false);
  - the version footer matches `pubspec.yaml`.
  `CLAUDE.md` §13 forbids launching it; this is a build/static check only.

## Data model / API changes

### New SQL

| Object | Purpose |
|---|---|
| `public.delete_account_data(p_user_id uuid)` | Service-role cleanup of NO ACTION rows before auth-user deletion. |
| `public.user_reports` | Player reports: reporter, reported, reason, note, resolved, created. |
| `public.user_blocks` | Directed block pairs; both directions are checked by `_blocked_between`. |
| `public._blocked_between(uuid, uuid)` | Shared predicate for feed/matchmaking/join checks. |
| `public.username_policy_terms` | Owner-curated reserved/profanity terms. |
| `public._username_is_allowed(text)` | Normalized policy check. |
| `public._enforce_username_policy()` + trigger | Rejects disallowed usernames at insert/update. |

### Changed SQL functions

- `public.start_level_attempt(uuid, smallint, text)` — return object gains
  `categoryId` and `subcategoryName`; no other behavior changes.
- `public._duel_try_pair(uuid)` — exclude blocked candidates.
- `public.request_duel_join(uuid)` / `public.respond_duel_join(...)` — reject
  blocked pairs with `blocked`.
- `public.get_duel_lobby(text)` — hide blocked creators' cards and blocked
  requesters' incoming request.
- `public.delete_account_data(uuid)` — extended with `user_reports` /
  `user_blocks` cleanup once Phase 6 exists.

### New Edge Function

`delete-account` (POST, `verify_jwt = true`)
- Request: `Authorization: Bearer <Supabase access token>`, empty body.
- Success: `200 { "deleted": true }`.
- Errors: `401` invalid/missing JWT; `500` cleanup or auth deletion failure.
- Side effects: deletes owned rows, then the auth user; cascades the profile.

### Client API changes

- `AuthApi.deleteAccount()`, `AuthRepository.deleteAccount()`,
  `SessionCubit.deleteAccount()`.
- `PreparedLevel` + `QuizPlayRepository` topic-context getters;
  `QuizPlayCubit.startLevel` signature drops `categoryId`/`subcategoryName`.
- `BestCategoryEntry.categoryId`; `BadgeProgress.nextCategoryId` /
  `nextSubcategoryName`.
- `QuizPlayApi.reportQuestion` / `QuizPlayRepository.reportQuestion`;
  `ReportQuestionCubit` and `ReportQuestionScreen`.
- `SafetyApi` / `SafetyRepository` / `SafetyCubit`; `PlayerActionsSheet`;
  `BlockedPlayersScreen`.

## Dependencies

- No new Flutter packages. Share uses the existing `url_launcher` and
  `flutter/services` (`Clipboard`). Version display uses a build-time
  `--dart-define`.
- No new Edge Function npm dependencies beyond `@supabase/supabase-js@2`,
  already used by `_shared/revenuecat.ts`.
- No new database extensions.

## Testing strategy

- **Static:** `dart format`, `dart analyze`, `flutter gen-l10n`, `flutter
  test`.
- **Unit:** `bloc_test` for `SessionCubit.deleteAccount`, `ReportQuestionCubit`
  and `SafetyCubit`; `mocktail` tests for `AuthRepository`, `QuizPlayRepository`
  and `SafetyRepository`; pure tests for share URL construction and the
  leaderboard block filter.
- **Widget:** `DeleteAccountScreen` (guest/success/failure), report screen,
  player-actions sheet, blocked-players screen, profile best-category tap,
  badge-detail CTA, countdown topic label.
- **SQL (MCP `execute_sql`, rolled back):** `delete_account_data` cleanup
  order; `_username_is_allowed`; `_blocked_between`; the duel candidate
  exclusion. If auth-user creation is not safe in SQL, use a disposable test
  account and document the result instead of a transaction test.
- **Manual (owner, release build):** App Store sandbox purchase/restore and
  physical-device account deletion; see **To verify**.

## Edge cases & error handling

### Account deletion

- **Guest:** no account to delete → Settings row hidden; deep link shows an
  informational guard, not an enabled destructive button.
- **Network failure before the Edge Function runs:** show `deleteAccountError`,
  keep the account and the screen open.
- **Cleanup succeeds, auth deletion fails:** retry is safe because
  `delete_account_data` is idempotent. The Edge Function returns 500; the user
  sees an error and can retry.
- **Auth deletion succeeds, response is lost:** a retry's `getUser` returns
  401. The client should treat a 401 from a deletion retry as "session is
  already invalid" and reset to guest rather than trapping the user.
- **Active duel / opponent:** deleting `duels` removes the user's duel
  records. The opponent's history may lose that match; this is accepted as
  part of erasure and is consistent with the Privacy Policy's deletion
  promise.
- **Pro member:** store subscription remains with the Apple ID / Google
  account; the screen should mention cancelling in the store. Deleting the
  Quizoo account does not refund or cancel the store subscription.
- **Local caches:** the auth stream must switch the Purchase SDK to the new
  anonymous id; verify the cached `subscription.isPro` flag is cleared. If
  not, fix the subscription layer rather than leaving a ghost Pro state.

### Report / block / username

- Self-report and self-block are rejected by DB checks.
- Duplicate block is idempotent (upsert / `on conflict do nothing`).
- Blocking a player who has already sent a pending duel request: the lobby
  hides the request; the server rejects a response.
- Unblocking restores the player to leaderboards after a reload; matchmaking
  includes them again.
- Reports are write-only for the reporter; there is no client-side read of
  other users' reports.
- Username normalization handles case, spaces/punctuation and basic leet.
  Homoglyphs/Unicode confusables are not fully solved; the owner can expand
  terms or add manual moderation. Existing violating names are audited, not
  automatically renamed.
- Missing WhatsApp/X apps: `launchUrl` returns false/catches; show
  `commonShareFailed` and leave the sheet usable.
- Clipboard copy: show `commonCopied`; no external dependency.

### IAP

- Products unavailable in sandbox usually mean the product is not attached to
  the version, not approved, or missing a review screenshot. Check
  `get-product-store-state` before changing code.
- A purchase that succeeds but `profiles.is_pro` stays false is a server mirror
  issue (Edge Function secret/webhook), not a paywall issue. The client
  entitlement still unlocks the device; fix the mirror before release.
- Restore Purchases must be tested after a reinstall, not only from the same
  session.

## Acceptance criteria

- [ ] `Settings → Delete account` on a signed-in account deletes the auth user
      and all owned rows; the app returns to Guest; signing in again creates a
      fresh account. The snackbar says "Account deleted", with no `(mock)`.
- [ ] No release screen shows `DEVELOPER`, `mock build`, `Mock —`, `Shared!
      (mock`, or any equivalent mock wording.
- [ ] The Settings version label reflects `pubspec.yaml` in a release build.
- [ ] `/dev/screens`, the share demo, notification-permission preview and
      force-update routes are not registered in release.
- [ ] Tapping a best-category row for a topic not in `MockCatalog` opens the
      correct level map; tapping a locked badge's CTA does the same.
- [ ] The countdown screen shows the real topic name for any of the 207 live
      subcategories.
- [ ] All three Pro products are selected on the 1.1.0 (2) version, have real
      review screenshots, and pass a sandbox purchase + restore on a physical
      device. The paywall shows the store prices and the 1-week trial.
- [ ] A report from a question inserts a `question_reports` row for the actual
      question; a report from a missed question in the failed-result list does
      the same, not a fixture.
- [ ] A player can be reported and blocked from the leaderboard; the blocked
      player disappears from the viewer's leaderboard, cannot be matched with
      or joined in a duel, and can be unblocked from Privacy → Blocked
      players.
- [ ] A username containing a reserved/profanity term is rejected with
      `profileUsernameNotAllowed`, including a leet/punctuation variant.
- [ ] `dart analyze` is clean and `flutter test` is green after all phases.

## Risks & rollout notes

- **Migration order matters.** Apply Phase 1's deletion function before
  deleting any account. Apply Phase 6 after Phase 1 and re-create
  `delete_account_data` with the safety-table deletes. Keep each migration's
  rollback note in its header.
- **Hard delete is irreversible.** Do not run the Edge Function against the
  developer's own account. Use a disposable test account. Back up any data
  needed for accounting before testing.
- **Edge Function deployment:** `delete-account` must have `verify_jwt = true`;
  a missing deploy or a wrong shared import will make deletion fail. Verify
  the function is listed (`list_edge_functions`) and the config matches.
- **Service-role RPC:** `delete_account_data` must be executable only by
  `service_role`; do not grant it to `authenticated` or it becomes a
  delete-any-account endpoint.
- **IAP product IDs are permanent.** Do not rename the three iOS IDs after
  submission. The current RevenueCat catalog and the plan-023 doc disagree on
  the IDs (`com.quizoo.play.monthly` vs `quizoo_pro_monthly`); the live IDs
  above are the ones in App Store Connect.
- **Submission coupling:** the first subscription must go to review with the
  app version. If the products are not attached, the paywall will show its
  unavailable state and Guideline 3.1.1 is likely.
- **UGC scope:** report/block + username filtering is a meaningful feature, not
  a cosmetic change. Expect owner moderation work after launch; add a simple
  review routine for `user_reports` (daily/weekly) and keep the support email
  visible in the legal pages.
- **Privacy copy:** adding report/block data changes the privacy story. Update
  the policy before shipping Phase 6.
- **No app launch by the agent.** The final IAP, deletion and share checks are
  human device checks; list them explicitly for the owner.

### Rollback notes

- **Account deletion:** the data erase cannot be undone. The SQL function can
  be dropped/replaced, but a deleted account is gone. Test on a disposable
  account only.
- **`start_level_attempt`:** keep the previous full function body in the
  migration header; re-applying it restores the old return shape. The client
  parser must tolerate the missing keys if rolled back? It will fail to parse
  required `categoryId`; coordinate rollback with the app build or make the
  client parse fall back to `''` during the transition. Prefer not rolling
  back after release.
- **Username policy:** drop the trigger to disable enforcement; the term table
  can stay. Existing renamed usernames are not restored by a rollback.
- **IAP:** product IDs and review metadata are dashboard changes; do not
  archive/rename after submission without a plan.

## To verify (human, physical device / dashboards)

- [ ] **Account deletion:** create a throwaway account on the TestFlight build,
      note its username, delete it from Settings, confirm the success snackbar
      (no "mock"), relaunch, and confirm the app is a fresh guest. Re-sign in
      with the same Apple ID; it must create a new profile, not restore the
      old one. Check the DB has no profile or owned rows for the old id, and
      that the old username is gone from the leaderboards (allow one 2-minute
      matview refresh cycle; the Edge Function also attempts an immediate
      refresh).
- [ ] **Release surface:** open Settings on the submitted release build and
      confirm there is no DEVELOPER section, the footer shows the real
      version, and no screen displays "mock".
- [ ] **Crash paths:** play a topic whose subcategory is not one of the old 26
      fixtures; confirm the countdown shows its name; open You → Best
      categories and tap the topic; open a locked badge's detail and tap its
      CTA. Both must land on the correct level map, with no exception.
- [ ] **Report question:** report a question from the HUD and from a missed
      row on the failed-result screen; confirm `question_reports` has two rows
      with the correct question ids.
- [ ] **Player safety:** from Ranks, report and block another player; confirm
      the row disappears after reload, Privacy → Blocked players lists them,
      unblocking restores them, and a blocked opponent cannot be matched or
      joined in a duel. Try a username containing a reserved term and a
      punctuation/leet variant; both must be rejected with the new message.
- [ ] **IAP:** on a sandbox account, confirm the three plans and trial on the
      paywall, purchase monthly, confirm Pro perks and ads-off, restore after
      reinstall, and check `profiles.is_pro` flips true. Confirm the version
      page has all three products attached and real review screenshots.
- [ ] **Share:** tap each target on a result; WhatsApp/X open the respective
      app/composer, Copy puts text on the clipboard, and a missing app shows
      the error snackbar instead of a mock message.
