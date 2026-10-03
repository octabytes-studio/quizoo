# In-App Subscription — Quizoo Pro (RevenueCat)

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-10-01): "introduce the in app subscription … verified icon / crown
> badge … all levels of all sub-categories unlocked … removal of all the ads
> (excluding the ad to earn a life) … full integration including creation of
> subscriptions on RevenueCat (MCP connected) … beautiful and user friendly
> screens." Owner decisions taken in the same conversation are recorded under
> "Decisions already made".
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation. Read it
in full before you start. It was written against `main` @ `0961774` **plus the
uncommitted plan 022 (ads) work in the working tree** — `lib/app/ads_cubit.dart`,
`lib/core/ads/`, and the ad widgets in `lib/core/widgets/` all exist on disk.
Code may have moved on since, so spot-check the files and symbols referenced
here before changing anything.

Three things to know before starting:

1. **Prerequisite: plan 022 must be finished first.** Its Flutter code is in
   place, but when this plan was written `test/core/ads/` was empty,
   `test/app/ads_cubit_test.dart` did not exist, and
   `test/support/pump_screen.dart` did not yet provide an `AdsCubit`. Finish
   plan 022's step 7.1 (harness + tests) before Phase 3 of this plan, or the
   suite will not be green to start from.
2. **`CLAUDE.md` §13: never run the app.** Static checks and tests only; end
   with the "To verify:" list at the bottom of this plan.
3. **This plan changes three live systems**: the Supabase database (one
   migration + two Edge Functions), the RevenueCat project, and the app.
   Database changes go through the Supabase MCP `apply_migration` — **never
   `supabase db push`** (plans 007/017/020). `build_runner` must be run with
   `--force-jit` in this repo (the default AOT mode hangs silently).

## Objective

Add a second revenue stream: **Quizoo Pro**, an auto-renewing subscription
(monthly, yearly) plus a lifetime purchase, sold through RevenueCat. Pro gives
a player a visible status badge, every level of every topic unlocked, no
interstitial/banner/native ads, and five smaller gameplay and identity perks.
The plan covers the RevenueCat catalogue, the server-side entitlement mirror
that makes Pro visible to other players and enforceable, the app-wide
entitlement state, the paywall and membership screens, and every place a perk
or an invitation to subscribe appears.

## Decisions already made (owner, 2026-10-01)

| Topic | Decision |
|---|---|
| Product name | **Quizoo Pro** (matches the existing RevenueCat entitlement `quizoo_pro`) |
| Plans | **Monthly + Yearly + Lifetime** |
| Prices | **Owner sets them** in App Store Connect / Play Console. The plan fixes no prices. |
| Store apps | **Both exist** (App Store Connect and Play Console apps for `com.quizoo.play`) |
| Guests | **Guests may buy.** After purchase they are nudged to sign in; on sign-in the purchase transfers to the account. |
| Badge | **Gold crown on the avatar corner + gold verified tick after the username** |
| Entry points | Locked level tap · Home card + Profile/Settings rows · Out-of-lives dialog link · Ad-free upsell (ad label link + one sheet after the third interstitial) |

**The benefit set** (the owner's three, plus five chosen from the research):

| # | Benefit | Where it is enforced |
|---|---|---|
| 1 | **Pro badge** — crown on avatar, tick after name, visible to everyone | Server (`profiles.is_pro`), read by every identity surface |
| 2 | **All levels unlocked** in every topic | Server (`start_level_attempt`) + client level map |
| 3 | **No ads** — interstitial, banner, native. The opt-in rewarded heart ad stays. | Client (`AdsCubit`) |
| 4 | **One free revive per level** — an instant extra life with no ad | Client (`QuizPlayCubit`) |
| 5 | **Double power-ups** — 2× 50:50 and 2× +5s per level | Client (`QuizPlayCubit`) |
| 6 | **Streak shield** — streak freezes refill to 2 every month | Server (cron) |
| 7 | **Exclusive avatars** — a Pro-only set in the avatar picker | Server (trigger) + client picker |
| 8 | **Answer review** — every question, correct answer and explanation after a level | Client (new screen) |

Rejected during research, with reasons, so nobody re-adds them casually:
a coin/gem multiplier (coins and gems have had no spend surface since plan 013
deleted the Shop, so it would be worth nothing); a leaderboard points boost
(pay-to-win on the app's core competitive surface); 5 lives, advanced stats and
an XP boost (offered, not chosen).

## Scope

**In scope:**
- RevenueCat: App Store and Play Store apps, six real products, entitlement
  and offering wiring, webhook integration.
- Supabase: `profiles.is_pro`, a private `pro_subscriptions` mirror, an event
  ledger, two Edge Functions (webhook receiver, client-triggered sync), a
  server-side level lock, streak-freeze refill, Pro avatars, `isPro` in the
  duel identity JSON.
- App: `purchases_flutter`, an entitlement layer in `lib/core/subscription/`,
  an app-root `SubscriptionCubit`, a new `features/subscription/` feature
  (paywall, welcome, membership screens), shared badge and upsell widgets,
  and the eight benefits wired into the existing features.
- l10n (English + Urdu), tests per `CLAUDE.md` §11, docs.

**Out of scope:**
- Prices, free-trial length and promotional offers (owner; the paywall
  renders whatever the store products carry — see Assumption 6).
- RevenueCat's hosted Paywalls / Customer Center UI (`purchases_ui_flutter`).
  The spec asks for the app's own screens.
- Web/desktop purchases, Stripe/Web Billing, family sharing, gifting, promo
  codes UI, win-back offers, A/B price experiments.
- Custom analytics events (RevenueCat's own charts cover conversion).
- Restoring a coin/gem economy or a Shop.
- Fixing the pre-existing mocks listed in `MOCKED_FEATURES.md`.

## Research findings

### RevenueCat (read through the MCP on 2026-10-01)

- Project **Quizoo**, id `proj66ca87d0`.
- One app only: **Test Store**, id `app4ae025b9bd`. **No App Store or Play
  Store app is registered yet.**
- Products (all on the Test Store app): `monthly` (`proddd41ad3919`, P1M),
  `yearly` (`prod59fc6a0fca`, P1Y), `lifetime` (`prod9c538a5aaa`,
  non-consumable).
- Entitlement `quizoo_pro` ("Quizoo Pro"), id `entl290e4fc2fe`.
- Offering `default` (current), id `ofrng2dff8fa3f7`, packages
  `$rc_monthly` (`pkge613ecd0497`), `$rc_annual` (`pkgeb29dea268b`),
  `$rc_lifetime` (`pkgef19a26d05e`).
- No webhook integrations, no paywalls.
- Not checked: whether the three Test Store products are attached to the
  entitlement and packages. Step 1.1 verifies this.
- The MCP's `create-webhook-integration` **cannot set the `Authorization`
  header** and `create-app` **cannot upload store credentials** — both are
  dashboard-only (owner checklist).

### Supabase (live project `ughycvclcheuojifgkwx`, read through the MCP)

- `profiles` has no subscription column. Columns include `username`,
  `avatar_key`, `is_guest`, `streak_days`, `streak_freezes` (default 2),
  `max_hearts`, `elo`, `league`.
- RLS on `profiles`: `profiles_select_all` (`true`) — every profile row is
  readable by every client, which is what lets a public `is_pro` flag drive
  badges. `profiles_update_self` (`id = auth.uid()`), and the `authenticated`
  role holds **column-level** UPDATE on only `avatar_key`, `city`,
  `country_code`, `locale`, `username`. A new column is therefore not
  client-writable by default. (`anon` holds a table-level grant, but RLS
  gives it no rows because `auth.uid()` is null.)
- `iap_transactions` exists (0 rows) from the removed Shop's design. Unused;
  leave it alone.
- **No Edge Functions are deployed** and `supabase/functions/` does not
  exist. Extensions present: `pg_cron`, `supabase_vault`. `pg_net` is not
  installed (not needed here).
- Cron jobs: `refresh-lb-weekly`, `daily-rollover`,
  `refresh-featured-quizzes`, `duel-sweeper`.
- **Level locks are not enforced by the server.** `start_level_attempt
  (p_subcategory_id uuid, p_level smallint, p_locale text)` starts any level
  for any authenticated user (see
  `supabase/migrations/20261001090000_three_tier_difficulty_ladder.sql:124-241`;
  that migration is applied live as version `20260930175539`). The lock
  exists only in the client.
- `_touch_daily_streak` spends one `streak_freezes` on a gap of 2+ days and
  nothing ever refills them.
- `_duel_player_json(p_user_id, p_subcategory_id)` builds each duel side's
  identity from `profiles`. `_duel_challenge_card` and
  `_duel_requester_json` build theirs from **snapshot columns** on
  `duel_challenges` / `duel_join_requests`
  (`supabase/migrations/20260927120200_duel_arena_challenge_functions.sql:356-367, 428+`).
- `avatar_options (id, emoji unique, sort_order, is_active)`, 56 rows,
  public select.
- Leaderboards are materialized views (`lb_weekly_totals`, `lb_alltime`, …)
  keyed by `user_id`; names and avatars are looked up separately from
  `profiles`.
- Scoring: `_difficulty_multiplier(level) = 1 + (level − 1) × 0.05`, plus
  first-clear XP. See Assumption 3 (fairness).

### The app

- Stack: Flutter (Dart `^3.12.2`), `flutter_bloc` 9, `go_router` 16,
  `flutter_screenutil`, `freezed` 3, `supabase_flutter` 2.17,
  `google_mobile_ads` 9.1, Firebase (Remote Config, Analytics, Crashlytics).
  `in_app_purchase: ^3.3.0` is declared in `pubspec.yaml:48` but **not
  imported anywhere under `lib/`**.
- Identifiers: Android `applicationId` and iOS bundle id are both
  `com.quizoo.play`. Android `minSdk` 23, `launchMode="singleTop"`,
  `MainActivity : FlutterActivity`. iOS deployment target 15.0. The iOS
  entitlements file holds only Sign in with Apple.
- **App-root pattern.** App-wide Cubits live in `lib/app/` as
  `<name>_cubit.dart` + `<name>_state.dart` (`part of`, sealed, `Equatable`)
  and are provided in `lib/app/app.dart:218-228`. Session-lifetime services
  are `RepositoryProvider`s at `app.dart:196-217`. `QuizooApp` takes optional
  `router` and `adsCubit` parameters so tests can inject fakes. The class doc
  comment explains why each root Cubit earns its place — extend it.
- **Ads layer (plan 022).** `AdsCubit` (`lib/app/ads_cubit.dart`) has states
  `AdsInitial | AdsDisabled | AdsReady(config, privacyOptionsRequired)`;
  `isPlacementEnabled(placement)` gates every slot widget through
  `context.select` in `lib/core/widgets/inline_ad_slot.dart:48`, and
  `showInterstitialIfDue` is called from three result screens. Its own doc
  comment says it "is also the single switch a future 'Remove ads' purchase
  would flip." The rewarded heart ad is deliberately not gated by it.
- **Service seam pattern.** SDK-backed services are an abstract class plus
  one implementation (`core/ads/interstitial_ad_service.dart` +
  `admob_interstitial_ad_service.dart`; `features/quiz_play/data/
  rewarded_ad_service.dart` + `admob_rewarded_ad_service.dart`), and tests
  use hand-written **fakes** with `Completer`s, not mocktail
  (`test/features/quiz_play/heart_ad_cubit_test.dart`).
- **Identity.** `main.dart:35-48` signs every device in anonymously, so a
  guest already has a real `auth.uid()` and a `profiles` row.
  `AuthApi.signInWithVendor` uses `signInWithOAuth` (not `linkIdentity`), so
  **a guest who signs in with Google/Apple gets a different user id**; the
  email route keeps the same id; `signOut` creates a fresh anonymous id
  (`lib/features/auth/data/auth_api.dart:53-200`). `AuthRepository
  .authStateChanges` exposes Supabase's auth stream.
- **Level map.** `CatalogApi._levelFor`
  (`lib/features/catalog/data/catalog_api.dart:308-331`) marks a level
  `done` if it has a completed `level_progress` row, `current` if it is not
  cleared and `number == levelsCleared + 1`, else `locked`. `levelsCleared`
  is a **count**, which is wrong once clears can be non-contiguous.
  `LevelStatus { locked, current, done }` lives in
  `lib/core/models/level.dart`. `SerpentinePath` passes `onTap: null` for a
  locked node (`serpentine_path.dart:86-88`) and `LevelNode` ignores taps
  when locked (`level_node.dart:51`). `LevelMapScreen` reloads on
  `didPopNext`.
- **Play mode.** `QuizPlayCubit.startLevel` builds the `QuizRun` with
  `heartsRemaining: MockPlayer.livesPerLevel` (3) and
  `powerUps: const PowerUpInventory(fiftyFifty: 1, addTime: 1)`
  (`quiz_play_cubit.dart:236-239`; the daily run repeats this at `:310-313`
  but hearts never deplete there and the dock is hidden). `usePowerUp`
  (`:707-745`) has no per-question guard beyond "has one left".
  `grantHeartFromAd()` (`:855`) and the private `_grantHearts` put a player
  back in the run. `OutOfLivesDialog`
  (`features/quiz_play/presentation/widgets/out_of_lives_dialog.dart`) offers
  "watch ad" and "back to map". `LevelBriefSheet` prints
  `MockPlayer.livesPerLevel`, `fiftyFiftyCount`, `addTimeCount`
  (`level_brief_sheet.dart:175-194`).
- **Results.** `Question.explanation` exists and is shown only in the
  in-play `feedback_banner.dart:49`. `LevelFailedScreen` lists missed
  questions with `MissedQuestionRow`; `LevelCompleteScreen` has no review.
  `QuizRun.answers` (`AnsweredQuestion`: question, outcome, `chosenIndex`)
  already holds everything a review screen needs and rides on the route
  `extra`.
- **Identity surfaces** (every place a name/avatar is drawn):
  `home_top_bar.dart` (`PlayerTopBar`), `profile_screen.dart`
  (`_ProfileHeader`, avatar at `:392-412`, name at `:418-428`),
  `leaderboard/…/podium.dart`, `leaderboard_screen.dart:252` and
  `category_leaderboard_screen.dart:195` (`ListRowTile`),
  `pinned_self_row.dart`, `league_promotion_screen.dart:201`,
  `friend_row.dart`, and in duels `challenge_card.dart` (`_Avatar`,
  `_NameAndRating`), `duel_player_label.dart`, `vs_header.dart`,
  `match_intro_view.dart`, `incoming_request_banner.dart`,
  `duel_round_view.dart`, `duel_result_screen.dart`.
  `LeaderboardApi._profilesFor` (`leaderboard_api.dart:433-450`) is the one
  profile lookup behind every leaderboard, league and friends row; it
  returns a positional record `(name, avatar, location)`.
- **Avatars.** `AvatarOption (id, emoji, sortOrder)`, `AvatarsApi
  .fetchActiveAvatars`, `AvatarPickerCubit` (sealed states),
  `AvatarPickerSheet` (pops the chosen emoji), used by
  `profile_creation_screen.dart:149` and `edit_profile_screen.dart:150`.
- **Theme tokens.** `context.quizoo` (`s0…s3`, `tx/tx2/tx3`, `ln`, `p`
  orange, `g` grape, `ok`, `bad`, `info`, `gold`, `goldShadow`, `shadow`),
  `AppColors` (incl. `onGold`, `masteryWashTop/Bottom`), `AppGradients
  .linear/tile`, `AppSpacing` (`xs 4 … xxl 32`, `screenMargin`),
  `AppRadius` (`card 20`, `sheet 28`, `pill`, `listRow 16`), `AppMotion`,
  `AppTypography.glyph`. Shared widgets: `ChunkyButton` (default,
  `.secondary`, `.success`, `.gold`, `.danger`, `.ghost`, `.line`),
  `AppBottomSheet.show`, `AppDialog`, `SimpleTopBar`, `ListRowTile`,
  `SectionHeader`, `ResultWash`, `SettingsRow`.
- **Routing.** All paths are constants in `lib/core/router/app_routes.dart`;
  routes are registered only in `lib/app/router.dart`; sheets-as-routes use
  the private `_sheetPage`.
- **l10n.** `lib/l10n/app_en.arb` (template, ~1,700 lines) and `app_ur.arb`
  (a deliberate subset); generated files are committed;
  `untranslated_messages.json` tracks Urdu gaps.
- **Tests.** `test/support/pump_app.dart` (theme + ScreenUtil + l10n at
  390×844), `test/support/pump_screen.dart` (app-root providers + catch-all
  router), mocktail `class FakeX extends Mock implements X {}` for API
  classes, `bloc_test` for Cubits. Saved gotcha: a fake that never completes
  or leaves a timer running hangs `pumpAndSettle`.

### Rules that shape the design

From `CLAUDE.md`:
- §1/§3: decisions live in Cubits; Cubits are pure Dart with constructor
  injection; sealed states; exhaustive `switch`; navigation only from
  `BlocListener`.
- §2: code used by 3+ features goes in `core/`; shared widgets in
  `core/widgets/`; one public class per file; feature code under
  `lib/features/<feature>/{data,domain,presentation}`.
- §3: an app-root `BlocProvider` only for genuinely app-wide state.
- §4: paths only via `AppRoutes`; routes only in `app/router.dart`.
- §5/§6: tokens only; screenutil for sizing; new colours added to
  `core/theme/` for **both** themes.
- §8: package imports across features; `dart format`; zero analyzer
  warnings; no `// ignore:`.
- §10: a feature never edits another feature's files; shared files are added
  to, not restructured (see Assumption 1).
- §11: `bloc_test` per Cubit; repository tests; widget tests per state
  branch.

From the design bible (`.claude/docs/quizoo-design-bible.html`):
- Anti-pillar: "No dark-pattern purchase prompts on a loss screen." S-22
  (Level Failed) "never shows an ad or an offer."
- §04 colour rule: mint and raspberry appear only where they communicate
  correctness — "no mint 'premium' badge". **The Pro badge is gold.**
- §14: "Everything purchasable is also earnable"; §20: coins "never buy
  progress or answers." (Conflicts — see Assumption 2.)
- S-36: "'Remove ads' explicitly promises to keep rewarded ads available."

## Assumptions & open questions

**Assumptions**

1. **Editing other features' files is allowed here.** §10 forbids a new
   feature from modifying another feature's files, but this task *is*
   "apply Pro across existing surfaces" (same reasoning as plan 022,
   Assumption 2). Each touch is a small additive edit inside that feature's
   own files; all shared logic lives in `core/`; no feature imports
   `features/subscription/`. Features reach the paywall only through
   `AppRoutes`.
2. **The spec overrides two bible lines.** "All levels unlocked" is paid
   progress that is not earnable faster any other way, which contradicts
   §14/§20. The owner asked for it explicitly, so those lines are treated as
   superseded for Pro. The bible's behavioural rules are kept: no offer on
   Level Failed, nothing on the play surface except the existing
   out-of-lives dialog, gold (never mint) for the badge.
3. **Leaderboard fairness is accepted as-is.** A Pro player can jump to
   level 30, where the difficulty multiplier is 2.45×. Free players reach
   the same levels by playing, and harder levels are harder, so no scoring
   change is made. If this proves abusive, cap the multiplier for levels
   played out of order — a later, separate change.
4. **The out-of-lives link is not a "loss screen" prompt.** The owner chose
   it. It is a single quiet text link under the two existing buttons, never
   a button, and Level Failed stays untouched.
5. **The entitlement layer lives in `core/subscription/`**, not in the
   feature, because eight features read it (the plan 021 precedent:
   `core/content_language/` with its Cubit in `lib/app/`). The paywall UI is
   the feature.
6. **The paywall is data-driven.** Prices, currency, period and any free
   trial come from the store products through RevenueCat at runtime. The
   paywall shows trial copy only when the selected product carries a free
   introductory offer, and a "save N%" pill only when monthly and yearly
   prices are both known. Nothing about price is hardcoded.
7. **RevenueCat SDK keys are code constants in one file**, following the
   owner's ad-unit-id decision (plan 022, Assumption 6). They are public
   keys by design.
8. **Debug builds use RevenueCat's Test Store key; release builds use the
   platform key.** A `--dart-define=RC_USE_REAL_STORE=true` flag lets a
   debug build talk to the real sandbox stores.
9. **A lapsed Pro player keeps what they earned**: cleared levels stay
   cleared, a Pro avatar already chosen stays, held streak freezes stay.
   They lose the badge, ad-free play, jump access, and the per-level perks.
10. **The server trusts RevenueCat, not the client.** The client can ask the
    server to re-check (`sync-pro-status`), but the server always fetches
    the answer from RevenueCat's REST API itself.
11. **Pro status tolerates a late webhook.** The server treats a
    subscription as active until 3 days after `expires_at`, covering
    billing grace periods and delayed events; a daily sweep clears stale
    badges.
12. **`Subcategory.levelsCleared + 1` labels are left alone.**
    `category_detail_screen.dart:213` and
    `category_leaderboard_screen.dart:116` print "next level" as
    `levelsCleared + 1`. For a Pro player with out-of-order clears this can
    name an already-cleared level. Cosmetic; noted under Edge cases.

**Open questions (need the owner)**

1. **Store credentials in RevenueCat.** Upload the App Store Connect API
   key, the In-App Purchase key, and the Play service-account JSON in the
   RevenueCat dashboard (checklist items 1–2). Until then Phase 1 can only
   register the apps; it cannot create or validate store products.
2. **Prices and trial.** Decide the three prices and whether yearly gets a
   free trial (7 days is the common choice). Either give the numbers to the
   executing agent, which can then create the store products through the
   MCP, or create the products yourself with the exact ids in
   "Data model / API changes".
3. **Terms of Use and Privacy Policy URLs.** Both stores require them on a
   subscription paywall. The plan puts them in
   `core/subscription/revenuecat_config.dart` as constants; real URLs are
   needed before release.
4. **Pro avatar set.** The plan proposes twelve emoji (Step 2.6). Confirm
   or replace.
5. **Should Pro be offered during onboarding?** Not planned (first
   impressions stay offer-free). Revisit with data.

## Design overview

### How Pro status flows

```
Store purchase ──► RevenueCat ──webhook──► Edge Function revenuecat-webhook
      │                 ▲                          │ (asks RevenueCat's REST API
      │                 │                          │  for the customer's real state)
      ▼                 │                          ▼
purchases_flutter SDK   │              public._apply_pro_status(...)
      │                 │                ├─ pro_subscriptions  (private mirror)
      ▼                 │                └─ profiles.is_pro    (public flag)
SubscriptionCubit ──────┘ app calls                 │
  (instant, cached)       sync-pro-status           ▼
      │                   after buy/restore   badges for everyone, server-side
      ▼                                       level lock, Pro avatars, freezes
perks + ad-free on this device
```

Two sources, each used for what it is good at:

- **This device's own perks** read `SubscriptionCubit`, which is fed by the
  RevenueCat SDK. It is instant after a purchase and works from the SDK's
  cache offline.
- **Anything another player sees, or anything the server must enforce**,
  reads `profiles.is_pro`, written only by the server.

### Identity

RevenueCat's app user id is always the current Supabase `auth.uid()`.

- App start: configure the SDK with the current uid.
- The uid changes (guest signs in with a vendor, or anyone signs out):
  `Purchases.logIn(newUid)`. If the player was Pro on the old id **and the
  change is a sign-in**, call `syncPurchases()` so the store receipt
  attaches to the new id (RevenueCat's default "transfer to new App User ID"
  behaviour moves the entitlement and fires a `TRANSFER` webhook). On
  sign-out no sync is done: Pro stays with the account.
- A guest who buys and never signs in keeps Pro on that device and can
  restore after a reinstall with "Restore purchases".

### New and changed code

```
lib/core/subscription/
  revenuecat_config.dart            SDK keys, entitlement id, legal URLs
  pro_plan.dart                     enum ProPlan { monthly, yearly, lifetime }
  pro_membership.dart               freezed: plan, expiresAt, willRenew, …
  pro_offer.dart                    freezed: one purchasable plan + its price text
  pro_perks.dart                    const perks for free vs Pro
  purchases_service.dart            abstract seam over the SDK
  revenuecat_purchases_service.dart purchases_flutter implementation
  pro_status_api.dart               invokes the sync-pro-status Edge Function
  subscription_repository.dart      seam → domain models; the only caller of both
  pro_promo_store.dart              SharedPreferences: promo dismissals, counters
  paywall_source.dart               where the paywall was opened from
lib/app/
  subscription_cubit.dart, subscription_state.dart   app-root entitlement state
lib/core/widgets/
  pro_avatar_crown.dart             crown overlay for any avatar
  pro_tick.dart                     inline verified tick
  pro_name.dart                     name + tick in one line (ellipsis-safe)
  pro_upsell_sheet.dart             small "this is a Pro perk" sheet
  go_pro_card.dart                  the gradient promo card (Home)
  ad_break.dart                     interstitial + one-time ad-free offer
lib/features/subscription/
  domain/pro_benefit.dart           the eight benefits as data
  presentation/bloc/paywall_cubit.dart, paywall_state.dart
  presentation/screens/paywall_screen.dart
  presentation/screens/pro_welcome_screen.dart
  presentation/screens/pro_membership_screen.dart
  presentation/widgets/paywall_hero.dart
  presentation/widgets/pro_benefit_row.dart
  presentation/widgets/pro_plan_card.dart
  presentation/widgets/paywall_legal_footer.dart
lib/features/quiz_result/presentation/screens/answer_review_screen.dart
lib/features/quiz_result/presentation/widgets/review_question_card.dart
supabase/migrations/20261002090000_quizoo_pro_subscriptions.sql
supabase/functions/_shared/revenuecat.ts
supabase/functions/revenuecat-webhook/index.ts
supabase/functions/sync-pro-status/index.ts
```

`features/subscription/` has no `data/` folder: its data layer is
`core/subscription/`, shared with the root Cubit. This is a stated deviation
from §2's template, for the reason in Assumption 5.

### Screens and flows (UI/UX)

All three screens use one fixed look in light and dark, like the arena and
the Topic Mastered screen: a deep grape-to-night wash with gold accents. Add
the tokens in Step 3.2. Gold carries "Pro" everywhere; mint and raspberry are
not used decoratively.

**Paywall (`/pro`)** — one scrollable screen, pinned purchase area:

```
┌──────────────────────────────────────┐
│ ✕                                    │  close, top-start, always visible
│            🦉 (owl mark + 👑)        │  PaywallHero, gentle pop-in
│            Quizoo Pro                │  displayMedium, white
│   Play without limits. Stand out.    │  bodyMedium, white 85%
│                                      │
│  👑  Pro badge        Crown and tick… │  ProBenefitRow ×8, in a
│  🔓  Every level open  Jump to any…   │  translucent card; emoji plate,
│  🚫  No ads            No banners…    │  title (titleSmall), one line
│  ❤️  Free revive       One extra…     │  of plain copy (labelSmall)
│  🎯  Double power-ups  2× 50:50…      │
│  🛡️  Streak shield     Freezes refill │
│  🦄  Exclusive avatars Pro-only…      │
│  📖  Answer review     See every…     │
├──────────────────────────────────────┤  pinned bottom area (SafeArea)
│ ┌ Yearly ───────── BEST VALUE ─────┐ │  ProPlanCard ×3, radio-style;
│ │ $X / year · $Y per month  -NN%   │ │  yearly preselected; gold border
│ └──────────────────────────────────┘ │  + check on the selected card
│ ┌ Monthly ── $X / month ───────────┐ │
│ ┌ Lifetime ─ $X once ──────────────┐ │
│ [   Continue  /  Start free trial  ] │  ChunkyButton.gold
│ Renews automatically. Cancel anytime.│  disclosure, changes per plan
│ Restore purchases · Terms · Privacy  │  PaywallLegalFooter
└──────────────────────────────────────┘
```

- Copy is plain and specific; each benefit is one short sentence a new
  player understands.
- The disclosure line under the button states the real price and period of
  the selected plan ("$X per year, renews automatically until cancelled" /
  "One payment. Yours forever."), which both stores require.
- While a purchase is in flight the button shows a busy label and every
  control is inert. A user-cancelled purchase returns silently to the
  paywall. A failure shows an `AppSnackbar` with retry.
- If offers cannot be loaded (offline, store unavailable): the benefits
  still render, the plan area shows a compact error with "Try again", and
  Restore stays available.
- At widths ≥ `Breakpoints` tablet, a `LayoutBuilder` centres the content at
  a max width instead of stretching.

**Pro Welcome (`/pro/welcome`)** — shown once, right after a successful
purchase or a restore that found Pro: the player's own avatar wearing the
crown, "You're Pro!", three chips of what just changed ("Ads off", "All
levels open", "Badge on"), and one button "Start playing". A guest also
sees a secondary line button "Save Pro to your account", which opens the
existing save-progress sheet.

**Pro Membership (`/pro/membership`)** — what a Pro player sees instead of
the paywall: plan name, "Renews on {date}" / "Ends on {date}" / "Lifetime
member", a billing-issue notice when there is one, the benefit list with
gold checks, "Manage subscription" (opens the store's management page),
and "Restore purchases". For a guest: the same "Save Pro to your account"
action.

**Entry points** (all push `AppRoutes.paywall` with a `PaywallSource`):

| Entry | Where | Behaviour |
|---|---|---|
| Locked level | Level Map node tap | `ProUpsellSheet`: "Clear level N to open this, or unlock every level with Pro." Buttons: "See Quizoo Pro", "Not now". |
| Home card | Home feed, after the top banner | `GoProCard`, dismissible (✕). Hidden for 7 days after dismissal, and for Pro players. |
| Profile row | You tab, first item of the list | Free: gold "Go Pro" row. Pro: "Quizoo Pro · Active" row → membership screen. |
| Settings | Account group | "Quizoo Pro" row (same target) + "Restore purchases" row. |
| Out of lives | `OutOfLivesDialog` | Free: text link "Get a free revive every level with Pro". Pro: the revive button itself. |
| Ad label | Above native and rectangle ads | "Remove ads" link beside "Advertisement". |
| After an ad | Once ever, after the 3rd interstitial | `ProUpsellSheet`: "Enjoying Quizoo? Play without ads." |
| Pro avatar | Avatar picker | Tapping a crowned avatar as a free player opens `ProUpsellSheet`. |
| Answer review | Level Complete | "Review answers" button; free players get `ProUpsellSheet`. |

Nothing opens the paywall automatically except the one post-interstitial
sheet. `pro_enabled = false` in Remote Config hides every entry point.

## Implementation steps

### Phase 0 — Pre-flight (read-only)

- [ ] **0.1** Confirm plan 022 is complete: `test/core/ads/` has tests,
      `test/support/pump_screen.dart` provides an `AdsCubit`, and
      `flutter test` is green. If not, stop and finish plan 022 first.
- [ ] **0.2** Re-read the live definitions this plan rewrites, with the
      Supabase MCP `execute_sql`:
      `select pg_get_functiondef(oid) from pg_proc where pronamespace =
      'public'::regnamespace and proname in ('start_level_attempt',
      '_duel_player_json', '_duel_challenge_card',
      '_duel_challenge_history_card', '_duel_requester_json');`
      Every rewrite in Phase 2 must start from these live bodies, not from
      the migration files (they have drifted before — see plan 020's
      header).
- [ ] **0.3** Re-list the RevenueCat project (`list-apps`, `list-products`,
      `list-entitlements`, `list-offerings` with `expand:
      ["items.package.product"]`, `get-products-from-entitlement`) and
      compare with "Research findings". Reconcile any difference before
      creating anything — `create-product` and `create-app` are not
      idempotent.
- [ ] **0.4** Check the resolved `purchases_flutter` requirements (Android
      `minSdk`, iOS target, any `MainActivity` requirement) on pub.dev for
      the version `flutter pub add` will pick. Version 10.14.0 was current
      on 2026-10-01 (iOS 13+, Android 21+). This project is at minSdk 23 /
      iOS 15.

### Phase 1 — RevenueCat catalogue (MCP, project `proj66ca87d0`)

- [ ] **1.1 Test Store wiring.** Make sure the three Test Store products are
      attached to entitlement `entl290e4fc2fe`
      (`attach-products-to-entitlement`, idempotent) and each to its package
      (`attach-products-to-package`, `eligibility_criteria: "all"`):
      `proddd41ad3919` → `pkge613ecd0497`, `prod59fc6a0fca` →
      `pkgeb29dea268b`, `prod9c538a5aaa` → `pkgef19a26d05e`. If the Test
      Store products have no price, set USD placeholder prices with a
      product-store-state plan (`store: "test_store"`,
      `common.pricing.currency_prices`) — Test Store prices are for
      development only and are not the owner's real prices.
- [ ] **1.2 Register the store apps** with `create-app`:
      `{name: "Quizoo iOS", type: "app_store", app_store: {bundle_id:
      "com.quizoo.play"}}` and `{name: "Quizoo Android", type: "play_store",
      play_store: {package_name: "com.quizoo.play"}}`. Record both app ids
      in the plan's hand-off notes and in
      `.claude/docs/backend/03-store-iap-push-setup.md`.
- [ ] **1.3 Wait for credentials (owner checklist 1–2), then validate** with
      `validate-app-credentials` (`app_store_connect_key`,
      `app_store_subscriptions_key`, `google_play_service_account`). Do not
      continue to 1.4 until all three pass. Phases 2–9 do not depend on this
      and can proceed against the Test Store meanwhile.
- [ ] **1.4 Create the six real products.** Identifiers are fixed in "Data
      model / API changes". Two routes, depending on Open question 2:
      - *Owner supplied prices:* build one
        `create-product-store-state-plan` per store with
        `create_revenuecat_product` for each product, the price in
        `common.pricing.territory_prices` (US base) and, for App Store
        subscriptions, `equalize_missing_subscription_prices:
        {base_territory: "US"}`, `common.duration` (`P1M` / `P1Y`),
        `store_state.subscription_group_name: "Quizoo Pro"`, English
        localizations (name ≤ 30 chars, description ≤ 45), and the trial
        offer if the owner wants one. Ask the owner which territories to
        make available before setting `common.availability`. Preview with
        `plan-product-store-state-plan`, show the owner the diff, then
        `apply-product-store-state-plan`.
      - *Owner created the products in the consoles:* register each with
        `create-product` (`type: "subscription"` for the four subscription
        items, `"non_consumable"` for the App Store lifetime, `"one_time"`
        for the Play lifetime).
- [ ] **1.5 Attach** all six products to the entitlement and to their
      packages in the `default` offering (same calls as 1.1). Each package
      ends up with three products: Test Store, App Store, Play Store.
- [ ] **1.6 Webhook.** After Phase 2's functions are deployed:
      `create-webhook-integration` with `{name: "Supabase – Quizoo Pro",
      url: "https://ughycvclcheuojifgkwx.supabase.co/functions/v1/
      revenuecat-webhook"}` and no filters (all events, both environments).
      The Authorization header is an owner step (checklist 4).
- [ ] **1.7 Fetch the public SDK keys** with `list-app-public-api-keys` for
      the three apps; they go into `revenuecat_config.dart` (Step 3.3).

### Phase 2 — Supabase

One migration file, `supabase/migrations/20261002090000_quizoo_pro_
subscriptions.sql`, wrapped in `begin; … commit;`, applied with the MCP
`apply_migration` (name `quizoo_pro_subscriptions`). Header comment in the
style of the existing migrations, including a rollback note. Dry-run it
first on a Supabase branch (`create_branch`) or inside a transaction that
is rolled back.

- [ ] **2.1 Schema.**

      ```sql
      alter table public.profiles
        add column is_pro boolean not null default false;
      comment on column public.profiles.is_pro is
        'Public Pro badge flag. Written only by _apply_pro_status (service role).';

      create table public.pro_subscriptions (
        user_id uuid primary key references public.profiles (id) on delete cascade,
        is_active boolean not null default false,
        plan text check (plan in ('monthly', 'yearly', 'lifetime')),
        store text,
        product_id text,
        period_type text,
        expires_at timestamptz,            -- null = lifetime
        will_renew boolean not null default false,
        billing_issue_at timestamptz,
        environment text,
        last_event_at timestamptz,
        updated_at timestamptz not null default now()
      );
      alter table public.pro_subscriptions enable row level security;
      create policy pro_subscriptions_select_self on public.pro_subscriptions
        for select using (user_id = auth.uid());

      create table public.revenuecat_events (
        id text primary key,               -- RevenueCat event id
        type text not null,
        app_user_id text,
        payload jsonb not null,
        received_at timestamptz not null default now()
      );
      alter table public.revenuecat_events enable row level security;
      -- no policies: service role only

      alter table public.avatar_options
        add column is_pro boolean not null default false;
      ```

      After the `alter table profiles`, verify with a query on
      `information_schema.column_privileges` that `authenticated` holds no
      INSERT/UPDATE on `is_pro`; if it does, `revoke insert (is_pro),
      update (is_pro) on public.profiles from authenticated, anon;`.
- [ ] **2.2 `_is_pro` and `_apply_pro_status`.**

      ```sql
      create or replace function public._is_pro(p_user_id uuid)
      returns boolean language sql stable security definer
      set search_path to 'public' as $$
        select exists (
          select 1 from public.pro_subscriptions s
          where s.user_id = p_user_id and s.is_active
            and (s.expires_at is null or s.expires_at > now() - interval '3 days')
        );
      $$;

      create or replace function public._apply_pro_status(
        p_user_id uuid, p_is_active boolean, p_plan text, p_store text,
        p_product_id text, p_period_type text, p_expires_at timestamptz,
        p_will_renew boolean, p_billing_issue_at timestamptz,
        p_environment text, p_event_at timestamptz
      ) returns void language plpgsql security definer
      set search_path to 'public' as $$ … $$;
      ```

      `_apply_pro_status`: return if no `profiles` row exists for
      `p_user_id`; upsert `pro_subscriptions` (skip the write when the
      stored `last_event_at` is newer than `p_event_at`); set
      `profiles.is_pro = public._is_pro(p_user_id)`; when the profile just
      became Pro, `streak_freezes = greatest(streak_freezes, 2)`.
      `revoke execute … from public, anon, authenticated` on both, then
      `grant execute on function public._apply_pro_status(…) to
      service_role` (matching `20260927120600_revoke_internal_helper_
      execute.sql`).
- [ ] **2.3 Server-side level lock.** Rewrite `start_level_attempt` from the
      live body (Step 0.2) with exactly one addition, right after the tier
      lookup:

      ```sql
      if p_level > 1
         and not public._is_pro(v_user_id)
         and not exists (
           select 1 from public.level_progress lp
           where lp.user_id = v_user_id and lp.subcategory_id = p_subcategory_id
             and lp.level in (p_level, p_level - 1) and lp.completed_at is not null
         ) then
        raise exception 'level_locked';
      end if;
      ```

      A free player may start level 1, any level they have already cleared,
      and the level after one they have cleared — exactly what the client
      allows today, plus replays for a lapsed Pro player. Keep the function
      signature and grant unchanged. `ApiException.fromSupabase` already
      turns the message into `code: 'level_locked'`.
- [ ] **2.4 Streak shield + expiry sweep (pg_cron).**

      ```sql
      select cron.schedule('pro-streak-freeze-refill', '5 0 1 * *',
        $$update public.profiles set streak_freezes = 2
          where is_pro and streak_freezes < 2$$);
      select cron.schedule('pro-expiry-sweep', '20 0 * * *',
        $$update public.profiles p set is_pro = false
          where p.is_pro and not public._is_pro(p.id)$$);
      ```
- [ ] **2.5 Duel identity JSON.** Rewrite from the live bodies, one added
      key each:
      - `_duel_player_json`: `'isPro', p.is_pro`.
      - `_duel_challenge_card`, `_duel_challenge_history_card`: inside the
        `creator` object, `'isPro', coalesce((select is_pro from
        public.profiles where id = <creator id column>), false)`.
      - `_duel_requester_json`: the same lookup on the requester id.
      Re-apply each function's existing `revoke`/`grant` lines exactly as
      they are live.
- [ ] **2.6 Pro avatars.** Insert twelve Pro avatars with `is_pro = true`
      and `sort_order` after the current maximum, `on conflict (emoji) do
      nothing`: `👑 🦄 🐉 🦁 🦅 🧙 🥷 🧞 🦸 🧜 🤴 👸`. First run
      `select emoji from public.avatar_options` and drop any already present
      from the list (never flip an existing free avatar to Pro). Add the
      guard:

      ```sql
      create or replace function public._enforce_pro_avatar() returns trigger
      language plpgsql security definer set search_path to 'public' as $$
      begin
        if new.avatar_key is distinct from old.avatar_key
           and exists (select 1 from public.avatar_options
                       where emoji = new.avatar_key and is_pro)
           and not public._is_pro(new.id) then
          raise exception 'pro_avatar_required';
        end if;
        return new;
      end; $$;
      create trigger trg_enforce_pro_avatar before update of avatar_key
        on public.profiles for each row execute function public._enforce_pro_avatar();
      ```
- [ ] **2.7 Edge Functions** (the project's first; create
      `supabase/functions/`). TypeScript on Deno, `@supabase/supabase-js`
      via the `jsr:`/`npm:` specifier the Supabase docs currently recommend
      (check with the MCP `search_docs`).
      - `_shared/revenuecat.ts` — `syncCustomer(admin, appUserId, eventAt)`:
        return early unless `appUserId` is a UUID (skips
        `$RCAnonymousID:…`); `GET https://api.revenuecat.com/v1/subscribers/
        {appUserId}` with `Authorization: Bearer ${REVENUECAT_SECRET_KEY}`;
        read `subscriber.entitlements.quizoo_pro` (`expires_date`,
        `product_identifier`) and the matching entry in
        `subscriber.subscriptions` / `non_subscriptions` (`store`,
        `period_type`, `unsubscribe_detected_at`,
        `billing_issues_detected_at`, `is_sandbox`); derive `plan` from the
        product id (contains `monthly` / `yearly` / `lifetime`, including
        the Play form `quizoo_pro:monthly` and the Test Store ids);
        `is_active` = entitlement present and (`expires_date` null or in the
        future); call `admin.rpc('_apply_pro_status', {...})`.
      - `revenuecat-webhook/index.ts` — POST only. Compare the
        `Authorization` header to `Bearer ${REVENUECAT_WEBHOOK_SECRET}` in
        constant time; 401 otherwise. Insert `event.id` into
        `revenuecat_events` (`on conflict do nothing`); if it already
        existed, return 200. For a `TEST` event return 200. Otherwise call
        `syncCustomer` for every distinct id among `event.app_user_id`,
        `event.original_app_user_id`, `event.aliases`,
        `event.transferred_from`, `event.transferred_to`. Return 200 on
        success and 500 on a sync failure so RevenueCat retries.
      - `sync-pro-status/index.ts` — requires a valid user JWT
        (`verify_jwt` on). Resolve the caller with
        `supabase.auth.getUser(jwt)`, call `syncCustomer` for that id only,
        return `{isPro: boolean}`.
      - `supabase/config.toml`: add `[functions.revenuecat-webhook]
        verify_jwt = false` and `[functions.sync-pro-status] verify_jwt =
        true`.
      - Deploy both with the MCP `deploy_edge_function`. Secrets
        (`REVENUECAT_SECRET_KEY`, `REVENUECAT_WEBHOOK_SECRET`) are an owner
        step; until they are set the functions must fail closed (401/500),
        never grant Pro.
- [ ] **2.8 Verify** with SQL on the live project after applying: a free
      test user gets `level_locked` for level 5 and succeeds for level 1;
      calling `_apply_pro_status` for that user (via `execute_sql`) flips
      `profiles.is_pro`, lets level 5 start, allows a Pro avatar, and
      `_duel_player_json` returns `isPro: true`; then deactivate and confirm
      it all reverses. Run `get_advisors` (security) and resolve anything
      new. Clean up the test rows.

### Phase 3 — App foundation

- [ ] **3.1 Dependencies.** `flutter pub add purchases_flutter`; remove the
      unused `in_app_purchase` line from `pubspec.yaml`. Add a comment in
      the style of the other dependency comments. No native code changes
      are expected (Step 0.4 confirms); if the package's install notes
      require one, make only that change.
- [ ] **3.2 Theme tokens** (`lib/core/theme/app_colors.dart`, added, not
      restructured). Fixed-look Pro surface colours, with a comment saying
      the Pro screens look the same in both themes like the mastery wash:
      `proWashTop`, `proWashBottom`, `proGoldFrom`, `proGoldTo`, `proCard`
      (translucent white surface), `proCardBorder`. The badge itself uses
      the existing themed `quizoo.gold` / `quizoo.goldShadow` / 
      `AppColors.onGold`, which already have light and dark values.
- [ ] **3.3 `lib/core/subscription/` domain + config.**
      - `revenuecat_config.dart`: `abstract final class RevenueCatConfig`
        with `appleApiKey`, `googleApiKey`, `testStoreApiKey` (from 1.7),
        `entitlementId = 'quizoo_pro'`, `termsUrl`, `privacyUrl`, and
        `static String? apiKeyFor(TargetPlatform, {required bool
        useRealStore})` returning null on unsupported platforms. The only
        file that may contain a RevenueCat key.
      - `pro_plan.dart`: `enum ProPlan { monthly, yearly, lifetime }`.
      - `pro_membership.dart` (`@freezed`): `ProPlan? plan`, `DateTime?
        expiresAt`, `bool willRenew`, `bool isTrial`, `bool hasBillingIssue`,
        `String? managementUrl`.
      - `pro_offer.dart` (`@freezed`): `ProPlan plan`, `String packageId`,
        `String priceLabel` (store-formatted), `double price`, `String
        currencyCode`, `int? trialDays`, plus `String? perMonthLabel` for
        yearly.
      - `pro_perks.dart`: `class ProPerks { const ProPerks.free(); const
        ProPerks.pro(); }` with `fiftyFifty` (1 / 2), `addTime` (1 / 2),
        `freeRevives` (0 / 1), `livesPerLevel` (3 / 3), and
        `factory ProPerks.of({required bool isPro})`. The single home of
        these numbers.
      - Run `dart run build_runner build --delete-conflicting-outputs
        --force-jit`.
- [ ] **3.4 Service seam.** `purchases_service.dart`:

      ```dart
      /// What the SDK reports about the current customer.
      class PurchasesSnapshot { bool isPro; ProMembership? membership; }

      sealed class PurchaseOutcome {}          // purchased | cancelled | pending | failed(message)

      abstract class PurchasesService {
        Future<void> configure({required String apiKey, required String userId});
        Future<PurchasesSnapshot> logIn(String userId);
        Future<PurchasesSnapshot> current();
        Stream<PurchasesSnapshot> get changes;
        Future<List<ProOffer>> offers();        // current offering → offers
        Future<PurchaseOutcome> purchase(ProOffer offer);
        Future<PurchasesSnapshot> restore();    // user-initiated
        Future<PurchasesSnapshot> syncPurchases(); // silent, no OS prompt
      }
      ```

      `revenuecat_purchases_service.dart` implements it with
      `purchases_flutter`: `Purchases.configure(PurchasesConfiguration
      (apiKey)..appUserID = userId)`, `addCustomerInfoUpdateListener` →
      `changes`, `getOfferings().current` → the `monthly` / `annual` /
      `lifetime` packages, `Purchases.purchase(...)` with
      `PlatformException` mapped through `PurchasesErrorHelper` (user
      cancelled → `cancelled`, payment pending → `pending`). Trial days come
      from the product's introductory price when its price is zero. All
      SDK types stay inside this file. Check method names against the
      installed package version.
- [ ] **3.5 `pro_status_api.dart`** — `ProStatusApi(SupabaseClient)` with
      `Future<bool> sync()` calling
      `_client.functions.invoke('sync-pro-status')`, errors mapped with
      `ApiException.fromSupabase`.
- [ ] **3.6 `subscription_repository.dart`** — `SubscriptionRepository
      (PurchasesService, ProStatusApi, SharedPreferences)`:
      `bool get cachedIsPro` / private cache write on every snapshot (key
      `subscription.isPro`); `start(userId)`; `switchUser(userId,
      {required bool carryPurchases})`; `Stream<PurchasesSnapshot> get
      changes`; `offers()`; `purchase(offer)`; `restore()`. After a
      successful purchase, restore or carry-over it calls
      `_proStatusApi.sync()` un-awaited and swallows its error (the webhook
      is the backstop). Throws only `ApiException`.
- [ ] **3.7 `pro_promo_store.dart`** — `ProPromoStore(SharedPreferences)`:
      `bool get shouldShowHomeCard` (not dismissed in the last 7 days;
      injectable clock), `dismissHomeCard()`, `int get
      interstitialsSeen`, `noteInterstitialSeen()`, `bool get
      adFreeOfferShown`, `markAdFreeOfferShown()`. Keys prefixed
      `subscription.`.
- [ ] **3.8 `lib/app/subscription_state.dart` + `subscription_cubit.dart`.**

      ```dart
      sealed class SubscriptionState extends Equatable {
        bool get isPro;
        ProPerks get perks => ProPerks.of(isPro: isPro);
      }
      final class SubscriptionFree extends SubscriptionState {
        final bool isAvailable;      // false: unsupported platform or pro_enabled=false
        final bool showHomePromo;
      }
      final class SubscriptionPro extends SubscriptionState {
        final ProMembership? membership;   // null while only the cache is known
      }

      class SubscriptionCubit extends Cubit<SubscriptionState> {
        SubscriptionCubit({required SubscriptionRepository repository,
                           required ProPromoStore promos,
                           required Stream<String?> userIds,
                           required String? initialUserId,
                           required String? apiKey,
                           required bool isEnabled});
        Future<void> initialize();
        Future<void> refresh();
        void dismissHomePromo();
      }
      ```

      The initial state comes from `repository.cachedIsPro`, so a returning
      Pro player never sees an ad flash at launch. `initialize()` never
      throws: a null `apiKey`, `isEnabled == false`, a null user id or any
      failure leaves the cached state (and `isAvailable: false` when
      free). It subscribes to `repository.changes` and to `userIds`; on a
      new non-null id it calls `repository.switchUser(id, carryPurchases:
      state.isPro && <the new id is not anonymous>)` — pass that second
      fact in through the `userIds` stream as a small record
      `({String id, bool isAnonymous})` built in `app.dart`. Cancel both
      subscriptions in `close()`.
- [ ] **3.9 `AdsCubit` goes ad-free.** In `lib/app/ads_state.dart` add
      `final bool isAdFree` to `AdsReady` (default false, in `props`). In
      `ads_cubit.dart`: a private `_isAdFree`, `void setAdFree(bool
      value)` that stores it and re-emits `AdsReady` with the new flag;
      `initialize()` emits with the stored flag and skips the interstitial
      preload when ad-free; `isPlacementEnabled` returns false when
      `isAdFree`; `showInterstitialIfDue` returns early when `isAdFree`.
      Turning ad-free off preloads an interstitial. The rewarded heart ad
      is untouched. Update the class doc comment.
- [ ] **3.10 `lib/main.dart`.** Add `'pro_enabled': true` to the Remote
      Config defaults with a "Quizoo Pro (plan 023)" comment.
- [ ] **3.11 `lib/app/app.dart`.** Add an optional `SubscriptionCubit?
      subscriptionCubit` constructor parameter (tests inject one, like
      `adsCubit`). Build `RevenueCatPurchasesService`,
      `ProStatusApi(supabase)`, `SubscriptionRepository`, `ProPromoStore`
      and the Cubit as `late final` fields; `apiKey:
      RevenueCatConfig.apiKeyFor(defaultTargetPlatform, useRealStore:
      kReleaseMode || const bool.fromEnvironment('RC_USE_REAL_STORE'))`
      (null on web); `isEnabled:
      FirebaseRemoteConfig.instance.getBool('pro_enabled')`; `userIds`
      mapped from `_authRepository.authStateChanges`; `initialUserId:
      supabase.auth.currentUser?.id`. Add
      `RepositoryProvider<SubscriptionRepository>.value`,
      `RepositoryProvider<ProPromoStore>.value` (read by `runAdBreak`,
      Step 5.6) and `BlocProvider<SubscriptionCubit>.value`. In `initState`, when not
      injected, `unawaited(_subscriptionCubit.initialize())` and call
      `_adsCubit.setAdFree(_subscriptionCubit.state.isPro)` **before**
      `_adsCubit.initialize()`. Wrap the existing `BlocListener` in a
      `MultiBlocListener` and add `BlocListener<SubscriptionCubit,
      SubscriptionState>(listenWhen: (a, b) => a.isPro != b.isPro,
      listener: … context.read<AdsCubit>().setAdFree(state.isPro))`. Close
      the Cubit in `dispose` only if this state created it. Extend the
      class doc comment with a "Plan 023 adds [SubscriptionCubit]…"
      paragraph.
- [ ] **3.12 Routes.** `lib/core/router/app_routes.dart`: `paywall =
      '/pro'`, `proWelcome = '/pro/welcome'`, `proMembership =
      '/pro/membership'`, `answerReview = '/play/:levelId/review'` with
      `answerReviewPath(levelId)`; doc comments noting they are not among
      the bible's 54 ids. `lib/app/router.dart`: register the four routes
      on the root navigator (static `/pro/...` paths need no ordering
      care; put `answerReview` beside the result routes). `paywall` reads
      `state.extra as PaywallSource? ?? PaywallSource.direct`;
      `answerReview` reads `state.extra as QuizRun?`.

### Phase 4 — Subscription feature (screens)

- [ ] **4.1 Domain.** `core/subscription/paywall_source.dart` (in `core/`
      because the shared upsell widgets and eight features pass it):
      `enum PaywallSource { direct, lockedLevel, homeCard, profile,
      settings, outOfLives, adLabel, adBreak, proAvatar, answerReview }`.
      `features/subscription/domain/pro_benefit.dart`: `enum ProBenefit { badge, allLevels, noAds,
      freeRevive, doublePowerUps, streakShield, avatars, answerReview }`
      with an `emoji` getter; titles and descriptions come from l10n in the
      widget via an exhaustive `switch`.
- [ ] **4.2 `PaywallCubit`** (`presentation/bloc/`), created by the screen
      with `context.read<SubscriptionRepository>()`.

      ```dart
      sealed class PaywallState extends Equatable {}
      final class PaywallLoading extends PaywallState {}
      final class PaywallReady extends PaywallState {
        final List<ProOffer> offers; final ProPlan selected;
        final bool isBusy;                 // purchase or restore in flight
        final PaywallNotice? notice;       // one-shot: failed | pending | nothingToRestore
        int? get yearlySavingsPercent;     // from monthly×12 vs yearly, same currency
      }
      final class PaywallUnavailable extends PaywallState { final ApiException error; }
      final class PaywallPurchased extends PaywallState { final bool wasRestore; }
      ```

      Methods: `load()` (preselect yearly, else the first offer),
      `select(plan)`, `purchase()`, `restore()`, `clearNotice()`. A
      cancelled purchase returns to `PaywallReady` with no notice. All
      decisions (default plan, savings maths, which notice) live here.
- [ ] **4.3 `paywall_screen.dart`.** `BlocProvider` + `BlocConsumer`. The
      listener: `PaywallPurchased` → `context.pushReplacement
      (AppRoutes.proWelcome)`; a `notice` → `AppSnackbar` then
      `clearNotice()`. If `SubscriptionCubit` already says Pro when the
      screen opens, `pushReplacement(AppRoutes.proMembership)` from a
      listener (never from a builder). Layout per "Screens and flows":
      `Scaffold` with the Pro wash, a scrolling body (hero + benefits) and
      a pinned bottom area (plans, button, disclosure, footer). Exhaustive
      `switch` on state: loading → skeleton plan cards; unavailable →
      compact error + "Try again" + Restore; ready → plan cards.
      Semantics labels on every tappable; the selected plan is announced.
- [ ] **4.4 Widgets** (one public class per file): `PaywallHero`,
      `ProBenefitRow`, `ProPlanCard` (title, price line, optional pill,
      selected state), `PaywallLegalFooter` (Restore · Terms · Privacy;
      links via `url_launcher`, already a dependency). Entrance motion
      with `flutter_animate`, respecting `AppMotion.durationOf`.
- [ ] **4.5 `pro_welcome_screen.dart`.** Stateless composition over
      `SessionCubit` (avatar, guest or not) and `SubscriptionCubit`. Uses
      `ProAvatarCrown` at hero size. "Start playing" pops back to whatever
      opened the paywall (`context.pop()`); the guest action pushes
      `AppRoutes.saveProgress`.
- [ ] **4.6 `pro_membership_screen.dart`.** `BlocBuilder<SubscriptionCubit,
      …>` with an exhaustive switch: `SubscriptionPro` → membership card
      (plan, date line chosen by a small pure function in the file's
      domain helper: lifetime / renews / ends / in trial), billing-issue
      notice, benefits with checks, "Manage subscription"
      (`membership.managementUrl`, hidden when null or lifetime), "Restore
      purchases" (through a `PaywallCubit` scoped to this screen so
      restore has one code path); `SubscriptionFree` → `pushReplacement`
      to the paywall from a listener.
- [ ] **4.7 l10n.** Add every string to `app_en.arb` with `@` descriptions
      and to `app_ur.arb`: paywall title/tagline, eight benefit titles and
      descriptions, plan names, "BEST VALUE", "Save {percent}%", per-plan
      disclosures with `{price}` placeholders, "Start {days}-day free
      trial", "Continue", busy label, restore/terms/privacy, notices,
      welcome and membership copy, upsell sheet copy, "Go Pro", "Quizoo
      Pro · Active", "Remove ads", "Use free revive", "Review answers",
      level-node label for an open level, streak-shield line, Pro avatar
      label. Run `flutter gen-l10n`; commit the generated files.

### Phase 5 — Shared Pro widgets (`lib/core/widgets/`)

- [ ] **5.1 `pro_avatar_crown.dart`** — `ProAvatarCrown({required bool
      isPro, required double size, required Widget child})`: when `isPro`,
      a `Stack` placing a small gold disc with 👑 at the top-end corner
      (directional, so it mirrors in RTL), sized as a fraction of `size`,
      with a `Semantics(label: l10n.proBadgeLabel)`. When not Pro it
      returns `child` unchanged.
- [ ] **5.2 `pro_tick.dart`** — `ProTick({double? size})`: a gold verified
      glyph (`Icons.verified_rounded`, `quizoo.gold`), with the same
      semantics label, excluded from the name's own text.
- [ ] **5.3 `pro_name.dart`** — `ProName({required String name, required
      bool isPro, TextStyle? style, int maxLines = 1})`: a `Row` of
      `Flexible(Text(…ellipsis))` + `ProTick`, so a long name truncates
      and the tick always shows.
- [ ] **5.4 `pro_upsell_sheet.dart`** — `ProUpsellSheet.show(context,
      {required String emoji, required String title, required String
      message, required PaywallSource source})` built on `AppBottomSheet`:
      gold primary "See Quizoo Pro" (pops the sheet, then
      `context.push(AppRoutes.paywall, extra: source)`), ghost "Not now".
      Nothing in `core/` imports `features/subscription/`.
- [ ] **5.5 `go_pro_card.dart`** — `GoProCard({required VoidCallback
      onTap, required VoidCallback onDismiss})`: gold gradient card
      (`AppGradients.linear(AppGradients.bannerAngle, [proGoldFrom,
      proGoldTo])`, `AppColors.onGold` text), crown glyph, title, one line
      of copy, a small ✕ with its own 44-pt hit area.
- [ ] **5.6 `ad_break.dart`** — a top-level function
      `Future<void> runAdBreak(BuildContext context, AdPlacement
      placement, {bool isCelebration = false})`: awaits
      `AdsCubit.showInterstitialIfDue`. To know whether an ad was actually
      shown, change that method's return type to `Future<bool>` (true when
      an interstitial was displayed). When true, record it in
      `ProPromoStore`; when the count reaches 3, the offer has not been
      shown, and `SubscriptionCubit` says Pro is available, show
      `ProUpsellSheet` once and mark it shown. Checks `context.mounted`
      after every await. `ProPromoStore` is provided at the root as a
      `RepositoryProvider` (add to Step 3.11).
- [ ] **5.7 `ad_label.dart`** — add a trailing "Remove ads" text link
      (`quizoo.g`, `labelSmall`) in a `Row` with the existing label,
      shown only when Pro is available; it pushes the paywall with
      `PaywallSource.adLabel`. Keep at least `AppSpacing.md` between the
      link and the ad itself (accidental-click policy, plan 022).

### Phase 6 — Benefits in existing features

- [ ] **6.1 Ad-free.** Nothing more than 3.9/3.11: every slot widget and
      the three break points already go through `AdsCubit`. Replace the
      three direct `showInterstitialIfDue` calls with `runAdBreak`:
      `level_complete_screen.dart` (`_leave`, `:121-136`),
      `duel_result_screen.dart`, `daily_result_screen.dart` — same
      arguments, same `mounted` handling.
- [ ] **6.2 All levels unlocked — client.**
      - `lib/core/models/level.dart`: add `LevelStatus.open` ("playable,
        but not the next step") and update its doc comment. Regenerate.
        Fix every exhaustive `switch` the analyzer flags
        (`level_node.dart`, `serpentine_path.dart`, tests).
      - `CatalogApi._levelFor`: compute `current` as the **lowest
        uncleared level number** (pass it in from `_levelsFor`), not
        `levelsCleared + 1`.
      - `LevelMap` (`features/catalog/domain/level_map.dart`): add
        `LevelMap withAllLevelsOpen()` returning a copy where every
        `locked` level becomes `open`.
      - `LevelMapCubit.load` gains `required bool isPro` and applies
        `withAllLevelsOpen()` when true. `LevelMapScreen` passes
        `context.read<SubscriptionCubit>().state.isPro` in both `load`
        call sites and adds a `BlocListener<SubscriptionCubit, …>`
        (`listenWhen` on `isPro`) that reloads, so the map opens up the
        moment the player returns from the paywall.
      - `LevelNode`: an `open` node is tappable and drawn as an outlined
        grape node with its number and no padlock (tokens only);
        semantics label from l10n. `SerpentinePath`: add
        `ValueChanged<Level>? onLockedTap` and call it for locked nodes
        (LevelNode must stop swallowing the tap when a handler is
        given); the status caption for `open` is the new l10n string.
      - `_LevelMapLoadedState`: `onLockedTap` opens `ProUpsellSheet`
        (`🔓`, source `lockedLevel`, message naming the level to clear
        first: `map.currentLevel.number`). When Pro is unavailable, pass
        null so locked nodes stay inert as today.
      - `LevelMapCubit`/play error path: if `start_level_attempt` returns
        `level_locked` (a stale client), the existing play error state
        renders; add the code to whatever user-facing copy map exists for
        `QuizPlayFailed`, falling back to the generic message.
- [ ] **6.3 Revive and power-ups.**
      - `QuizRun`: add `@Default(false) bool freeReviveUsed`. Regenerate.
      - `QuizPlayCubit.startLevel`: add `required ProPerks perks`; use
        `perks.livesPerLevel` and `PowerUpInventory(fiftyFifty:
        perks.fiftyFifty, addTime: perks.addTime)`. `startDaily` keeps
        `const ProPerks.free()` values (the dock is hidden there). Remove
        the `MockPlayer` import if it becomes unused in this file.
      - `usePowerUp`: guard so each power-up type fires **at most once per
        question** (a second 50:50 on the same question would have nothing
        sensible left to remove). Track the types used on the current
        question in the in-progress state or a private field reset in
        `_beginQuestion`; the dock tile for a type already used this
        question renders disabled.
      - New `void useFreeRevive({required bool isPro})`: only from
        `QuizPlayOutOfLives`, only when `isPro && !run.freeReviveUsed`;
        sets `freeReviveUsed: true` on the run and reuses `_grantHearts
        (…, hearts: 1)`.
      - `quiz_play_screen.dart`: pass
        `context.read<SubscriptionCubit>().state.perks` where `startLevel`
        is called.
      - `OutOfLivesDialog`: read `SubscriptionCubit`. Pro with the revive
        unused → first action `ChunkyButton.gold("Use free revive")`,
        then the watch-ad button as `ChunkyButton.secondary`, then "Back
        to map". Otherwise today's two buttons, plus — when Pro is
        available and the player is free — a centred text link under
        them that pushes the paywall with `PaywallSource.outOfLives`. On
        return, if the player is now Pro the dialog rebuilds and offers
        the revive (the clock is already stopped in this state).
      - `LevelBriefSheet` (`:175-194`): read the counts from
        `SubscriptionCubit.state.perks` instead of `MockPlayer`; add a
        small 👑 next to a doubled count.
- [ ] **6.4 Answer review** (`features/quiz_result/`).
      - `answer_review_screen.dart`: `AnswerReviewScreen({required QuizRun?
        run})`. Pure presentation of an in-memory run (no Cubit: there is
        no loading, error or business decision). `SimpleTopBar` + a list
        of `ReviewQuestionCard`s, one per `run.answers` entry: question
        number, text, the four options with the correct one marked ✓ on
        mint and a wrong pick marked ✕ on raspberry (colour **and** glyph,
        per the bible), "You didn't answer" for a timeout, and the
        explanation. Wrap question content in the existing
        `ContentLanguageScope` so Urdu/Arabic questions render RTL (as the
        play surface does since commit `206c9c0`). A null `run` (dev
        route) renders an empty state.
      - `LevelCompleteScreen`: add `ChunkyButton.line(l10n.resultReview)`
        as the last action. Pro → `context.push(AppRoutes.answerReviewPath
        (run.levelId), extra: run)`; free → `ProUpsellSheet` (`📖`, source
        `answerReview`); hidden when Pro is unavailable and the player is
        free. It is **not** routed through `_leave` (no ad break: the
        player is not leaving the run).
      - `LevelFailedScreen`: **Pro players only** get the same button,
        above "Back to map". A free player sees exactly today's screen —
        no button, no sheet, no link (bible S-22).
- [ ] **6.5 Exclusive avatars** (`features/auth/`).
      `AvatarOption` gains `@Default(false) bool isPro`; `AvatarsApi` maps
      `row['is_pro']`. `AvatarPickerSheet`: free avatars first, then a
      "Quizoo Pro" sub-header and the Pro ones wearing a small crown; a
      free player tapping one gets `ProUpsellSheet` (`🦄`, source
      `proAvatar`) and the sheet stays open; a Pro player selects it
      normally. `EditProfileScreen` / `ProfileCreationScreen`: map the
      server's `pro_avatar_required` code to a clear snackbar (defence in
      depth).
- [ ] **6.6 Streak shield** (`features/daily/`). `_StreakCard`
      (`daily_screen.dart:323-380`): when Pro, replace the freeze
      explainer's second sentence with the new "Refills to 2 every month
      with Pro" line and add a small 👑. No data change — `freezesLeft`
      already comes from `profiles.streak_freezes`.
- [ ] **6.7 Badge — own identity.** Home `PlayerTopBar`: add `required
      bool isPro`; wrap the avatar in `ProAvatarCrown` and use `ProName`.
      `_HomeTopBar` passes `SubscriptionCubit.state.isPro`. Profile
      `_ProfileHeader`: `ProfileSummary` gains `@Default(false) bool
      isPro` (from `profiles.is_pro`, already selected by
      `ProfileApi._fetchSummary`'s `select()`); for the player's own
      profile OR it with `SubscriptionCubit.state.isPro` so the badge
      appears immediately after purchase.
- [ ] **6.8 Badge — other players.**
      - Leaderboards: `LeaderboardEntry`, `LeagueStanding`, `Friend` gain
        `@Default(false) bool isPro`. `LeaderboardApi._profilesFor` adds
        `is_pro` to its select and returns it; replace the positional
        record with a small private class or a named record
        (`({String name, String avatar, String? location, bool isPro})`)
        and update its call sites. `ListRowTile` (core) gains
        `bool isPro = false`, applying `ProAvatarCrown` to its leading
        plate and `ProTick` after its title. `Podium`, `PinnedSelfRow`,
        `FriendRow`, `leaderboard_screen.dart:252`,
        `category_leaderboard_screen.dart:195`,
        `league_promotion_screen.dart:201` pass it through.
      - Duels: `DuelPlayer` gains `@Default(false) bool isPro` (JSON key
        `isPro`, matching 2.5). Apply `ProAvatarCrown` / `ProName` in
        `challenge_card.dart` (`_Avatar`, `_NameAndRating`),
        `duel_player_label.dart`, `vs_header.dart`,
        `match_intro_view.dart`, `incoming_request_banner.dart`,
        `duel_round_view.dart`, `duel_result_screen.dart`. On the arena
        surface the crown disc keeps a 1px dark outline so it reads on
        the gradient. The requester model (`IncomingJoinRequest`) gets the
        same field if it does not reuse `DuelPlayer`.
      - Regenerate freezed/json for every changed model.
- [ ] **6.9 Entry rows and card.**
      - Home (`home_screen.dart`, `_HomeContentView`, the `leading` list
        at `:418`): insert `GoProCard` after the top banner when
        `SubscriptionCubit` state is `SubscriptionFree(isAvailable: true,
        showHomePromo: true)`; `onDismiss` →
        `SubscriptionCubit.dismissHomePromo()`. Not in the offline view.
      - Profile (`_ProfileLoadedView`, `isOwnProfile` only): a membership
        row as the first list item — free: gold-accent `ListRowTile`
        "Go Pro" → paywall (`profile`); Pro: "Quizoo Pro · Active" →
        `AppRoutes.proMembership`. Hidden when Pro is unavailable and the
        player is free.
      - Settings (`settings_screen.dart`, Account group, above
        Notifications): `SettingsRow(title: l10n.proSettingsRow, …)` with
        the same routing, and `SettingsRow(title: l10n.proRestore, …)`
        that pushes the paywall/membership screen (restore lives there,
        so there is one restore code path). Both hidden when unavailable.
      - Dev screen index (`kScreenIndex` is the bible's 54 only): leave
        it; optionally add three rows to Settings' DEVELOPER group for the
        new screens.

### Phase 7 — Tests

Follow the existing conventions; details under "Testing strategy".

- [ ] **7.1** Harness first: `pump_screen.dart` gains
      `SubscriptionCubit? subscription` (default: a fake in
      `SubscriptionFree(isAvailable: false, showHomePromo: false)`, so
      every existing screen test renders exactly as before) and provides
      a `SubscriptionRepository` over a fake `PurchasesService` plus a
      `ProPromoStore`. Whole-app tests pass a fake through
      `QuizooApp(subscriptionCubit: …)`.
- [ ] **7.2** New and extended test files as listed.

### Phase 8 — Docs and hand-off

- [ ] **8.1** `.claude/docs/backend/03-store-iap-push-setup.md`: replace
      §1–§2 (coin packs, `verify-purchase`) with the Quizoo Pro product
      table, the RevenueCat app ids, the webhook, and the two secrets.
      `.claude/docs/backend/02-firebase-project-setup.md` §3: add
      `pro_enabled`. `.claude/docs/backend/04-flutter-app-configuration.md`:
      a "RevenueCat" section (where keys live, the `RC_USE_REAL_STORE`
      flag, sandbox testing). `MOCKED_FEATURES.md`: note legal URLs /
      Test Store keys still pending, if they are.
- [ ] **8.2** `dart format .`, `dart analyze` (zero warnings),
      `flutter test`. Finish with the "To verify:" list below.

## Data model / API changes

**Store products** (identifiers are final; never rename after release):

| Plan | App Store product id | Play Store identifier | RevenueCat package |
|---|---|---|---|
| Monthly | `quizoo_pro_monthly` (group "Quizoo Pro") | `quizoo_pro:monthly` (subscription `quizoo_pro`, base plan `monthly`) | `$rc_monthly` |
| Yearly | `quizoo_pro_yearly` (group "Quizoo Pro") | `quizoo_pro:yearly` (base plan `yearly`) | `$rc_annual` |
| Lifetime | `quizoo_pro_lifetime` (non-consumable) | `quizoo_pro_lifetime` (one-time product) | `$rc_lifetime` |

All unlock the one entitlement `quizoo_pro`. In the App Store group, rank
yearly above monthly so upgrades and downgrades behave correctly. Play's
subscription must be **backwards-compatible off / base-plan based**
(RevenueCat SDK 10 uses Billing Library 6+).

**Database** (migration `20261002090000_quizoo_pro_subscriptions.sql`):

| Object | Change |
|---|---|
| `profiles.is_pro` | new `boolean not null default false`, public read, server write |
| `pro_subscriptions` | new table, own-row select, service-role write |
| `revenuecat_events` | new table, no client access (idempotency + audit) |
| `avatar_options.is_pro` | new column + up to 12 Pro rows |
| `_is_pro(uuid)`, `_apply_pro_status(…)` | new functions, not client-callable |
| `start_level_attempt` | raises `level_locked` for a free player out of order |
| `_duel_player_json`, `_duel_challenge_card`, `_duel_challenge_history_card`, `_duel_requester_json` | add `isPro` |
| `_enforce_pro_avatar` + trigger on `profiles` | raises `pro_avatar_required` |
| cron `pro-streak-freeze-refill`, `pro-expiry-sweep` | new jobs |

**Edge Functions:** `revenuecat-webhook` (no JWT; bearer secret) and
`sync-pro-status` (user JWT). Secrets: `REVENUECAT_SECRET_KEY`,
`REVENUECAT_WEBHOOK_SECRET`.

**Remote Config:** `pro_enabled` (bool, default `true`) — master switch for
every Pro entry point and for SDK start-up. Existing Pro players keep their
perks from the cache while it is off.

**Local storage** (`shared_preferences`): `subscription.isPro`,
`subscription.homePromoDismissedAt`, `subscription.interstitialsSeen`,
`subscription.adFreeOfferShown`.

**Error codes surfaced to the app:** `level_locked`, `pro_avatar_required`.

## Dependencies

- **Add** `purchases_flutter` (RevenueCat SDK; 10.14.0 current on
  2026-10-01) — purchases, entitlements, offerings, restore.
- **Remove** `in_app_purchase` — declared but unused; RevenueCat brings its
  own billing clients, and keeping both invites conflicting Play Billing
  versions.
- Not added: `purchases_ui_flutter` (the app draws its own paywall).

## Testing strategy

Conventions as found: `bloc_test` for Cubits; hand-written completer-backed
**fakes** for SDK seams (`FakePurchasesService implements
PurchasesService`, in `test/support/`); mocktail `Mock implements` for API
classes (`ProStatusApi`); `pumpApp` / `pumpScreen` for widgets. Every fake
completes immediately unless a test drives it. No test may construct
`RevenueCatPurchasesService`.

- `test/core/subscription/subscription_repository_test.dart` — caches
  `isPro` on each snapshot; `purchase` success triggers a server sync and
  survives the sync failing; `switchUser` with and without
  `carryPurchases`; SDK failure → `ApiException`.
- `test/core/subscription/pro_promo_store_test.dart` — 7-day dismissal
  window with an injected clock; counters.
- `test/core/subscription/pro_perks_test.dart` — free vs Pro numbers.
- `test/app/subscription_cubit_test.dart` — initial state from the cache
  (free and Pro); `initialize` success → Pro with membership; failure and
  null key → stays cached / unavailable; a `changes` event flips the
  state; a user-id change calls `switchUser` with the right
  `carryPurchases`; `dismissHomePromo`.
- `test/app/ads_cubit_test.dart` (extend) — `setAdFree(true)` disables
  every placement and interstitials; turning it off restores them; ad-free
  before `initialize` skips the preload.
- `test/features/subscription/paywall_cubit_test.dart` — initial; load
  success (yearly preselected, savings percent correct, null when a price
  is missing); load failure → `PaywallUnavailable`; purchase success →
  `PaywallPurchased`; cancelled → `PaywallReady`, no notice; pending and
  failed notices; restore with and without Pro.
- `test/features/subscription/paywall_screen_test.dart` — one test per
  state branch, both themes, Urdu locale; the disclosure line changes with
  the selected plan; trial label only when the offer has a trial; controls
  inert while busy.
- `test/features/subscription/pro_membership_screen_test.dart` and
  `pro_welcome_screen_test.dart` — renewing / ending / lifetime / billing
  issue; guest vs signed-in actions.
- `test/core/widgets/pro_widgets_test.dart` — crown and tick render only
  when Pro; `ProName` truncates a long name and keeps the tick; RTL
  placement; `ProUpsellSheet` navigates with the given source.
- Extend: `catalog_cubit_test.dart` (Pro → no locked levels; `current` is
  the lowest uncleared with out-of-order clears);
  `level_brief_sheet_test.dart` (doubled counts for Pro);
  `quiz_play_cubit_test.dart` (Pro inventory; one use per type per
  question; `useFreeRevive` once only, never for a free player);
  `quiz_play_screen_test.dart` (dialog variants: Pro revive, free link,
  unavailable); `level_complete_screen_test.dart` (review button routes
  for Pro, sheet for free); `result_screen_test.dart` (**Level Failed
  shows no Pro offer to a free player** — regression guard for the bible
  rule); `home_screen_test.dart` (card shown, dismissed, hidden for Pro
  and offline); `profile_screen_test.dart`, `home_top_bar_test.dart`,
  `pinned_self_row_test.dart`, `challenge_card_test.dart`,
  `duel_result_screen_test.dart` (badge present for Pro identities);
  avatar picker (Pro section, locked tap); `router_test.dart` (new
  routes resolve).
- New `test/features/quiz_result/answer_review_screen_test.dart` —
  correct, wrong and timed-out rows; null run.
- Database: the SQL checks in Step 2.8. Edge Functions: `deno test` for
  `_shared/revenuecat.ts`'s pure mapping (subscriber JSON → status), with
  fixture payloads for monthly, yearly-in-trial, lifetime, expired,
  billing issue, and an anonymous id.

## Edge cases & error handling

- **Offline at launch:** the cached flag decides; RevenueCat's SDK also
  serves cached customer info. Perks keep working; the paywall shows its
  unavailable state.
- **Purchase succeeds but the server is slow:** the device is Pro at once;
  `sync-pro-status` runs right after; the webhook is the backstop. Until
  one lands, starting a far-ahead level can return `level_locked` — the
  play error state shows and a retry works. Other players see the badge a
  few seconds later.
- **User cancels the store sheet:** silent return to the paywall.
- **Pending purchase** (Play slow payment, Ask to Buy): a notice explains
  it will unlock when approved; the SDK's update listener flips the state
  later.
- **Billing issue / grace period:** RevenueCat keeps the entitlement
  active during the store's grace period; the membership screen shows the
  notice; the server's 3-day tolerance covers the same window.
- **Refund or expiry:** an `EXPIRATION` / `CANCELLATION` webhook re-syncs;
  the daily sweep catches a missed one. Assumption 9 defines what remains.
- **Guest buys, then signs in with Google/Apple (new uid):** the Cubit
  logs in to RevenueCat with the new id and syncs purchases; the
  entitlement transfers; the `TRANSFER` webhook updates both profiles.
- **Signed-in Pro player signs out:** the fresh guest id is not Pro; ads
  return; Pro is back after signing in again.
- **Same store account, second Quizoo account:** restoring transfers Pro
  to whichever account restored last (RevenueCat's default). Documented in
  the membership screen's restore helper text.
- **Reinstall:** "Restore purchases" on the paywall; Apple requires this
  control to exist.
- **Lifetime plus an active subscription:** the entitlement stays active
  through lifetime; the membership screen shows "Lifetime member" and
  still links to store management so the player can cancel the
  subscription.
- **`pro_enabled = false`:** no entry points, no SDK calls; cached Pro
  players keep perks.
- **Unsupported platform (web/desktop folders exist):** `apiKey` is null →
  `SubscriptionFree(isAvailable: false)`; no plugin calls.
- **Webhook replay / out of order:** `revenuecat_events` de-duplicates;
  every sync reads RevenueCat's current truth, so order does not matter.
- **Webhook for an unknown or anonymous RevenueCat id:** ignored.
- **Secrets not yet set:** both functions fail closed.
- **Pro player with out-of-order clears:** the map's "current" node is the
  lowest uncleared level; mastery still needs level 30's first clear
  (`quiz_result_repository.dart:42-57`), so a Pro player can reach Topic
  Mastered by clearing only level 30. Accepted (it is the hardest level);
  revisit with Assumption 3 if it matters.
- **Stale "next level" labels** (Assumption 12).
- **A second power-up of the same type on one question:** blocked (6.3).
- **RTL (Urdu UI):** the crown sits at the top-**end** corner; the tick
  follows the name; plan cards and the paywall mirror.
- **Theme:** Pro screens use their fixed wash in both themes; badges use
  themed gold.
- **Double taps on Continue:** `isBusy` makes the button inert.
- **Paywall opened by an already-Pro player** (deep link, stale card):
  redirects to the membership screen.

## Acceptance criteria

- [ ] RevenueCat has App Store and Play Store apps for `com.quizoo.play`,
      six real products with the identifiers above, all attached to
      `quizoo_pro` and to the `default` offering's three packages, and a
      webhook pointing at `revenuecat-webhook`.
- [ ] A free player can open the paywall from every chosen entry point,
      sees eight clearly worded benefits and three plans with real store
      prices, and can buy, cancel out, or restore.
- [ ] After a purchase the player lands on the welcome screen and, without
      restarting: ad slots and interstitials are gone, the rewarded heart
      ad still works, every level in every topic is playable, the level
      brief shows 2× power-ups, the out-of-lives dialog offers one free
      revive per level, Pro avatars are selectable, "Review answers"
      opens, and their own avatar and name carry the crown and tick.
- [ ] Other players see the crown and tick on a Pro player in the global,
      country, friends and category leaderboards, the league screen, the
      friends list, the public profile, and every duel surface.
- [ ] A free player's client cannot start a locked level even by calling
      the RPC directly (`level_locked`), cannot set a Pro avatar
      (`pro_avatar_required`), and cannot write `profiles.is_pro`.
- [ ] A Pro player's streak freezes are topped up to 2 on becoming Pro and
      on the 1st of each month.
- [ ] A guest can buy; signing in afterwards keeps Pro on the account.
- [ ] A Pro player opening the paywall sees the membership screen with the
      right plan, date line and a working "Manage subscription" link.
- [ ] Level Failed shows no Pro offer to a free player; nothing on the
      question surface mentions Pro; the paywall never opens on its own
      except the single post-interstitial sheet.
- [ ] When a subscription ends, ads, locks and per-level perks return
      within the tolerance window and the badge disappears for everyone;
      cleared levels and a chosen Pro avatar remain.
- [ ] `pro_enabled = false` removes every entry point on the next launch.
- [ ] No hardcoded colours, text styles, spacing or route strings were
      added to feature files; `grep -rn "appl_\|goog_\|test_" lib` finds
      RevenueCat keys only in `core/subscription/revenuecat_config.dart`.
- [ ] All new Cubits and repositories have the tests listed; the existing
      suite passes; `dart analyze` reports zero warnings.

## Risks & rollout notes

**Owner checklist (cannot be done from code or the MCP):**
1. RevenueCat dashboard → iOS app: upload the **App Store Connect API
   key** and the **In-App Purchase key** (`.p8`, key id, issuer id).
2. RevenueCat dashboard → Android app: upload the **Play service-account
   JSON** (with the financial-data and order-management permissions
   RevenueCat lists), and enable Real-time Developer Notifications.
3. Decide prices and the trial; create the products or hand the numbers to
   the executing agent (Open question 2). Fill in the App Store
   subscription group's localizations and the review screenshot; **the
   first subscription must be submitted together with an app version.**
4. RevenueCat dashboard → the webhook: set the **Authorization header** to
   `Bearer <random secret>`; create a **secret API key** (v1). Then
   `supabase secrets set REVENUECAT_WEBHOOK_SECRET=… REVENUECAT_SECRET_KEY=…`
   (or Dashboard → Edge Functions → Secrets). Send a test event and confirm
   a row in `revenuecat_events`.
5. RevenueCat → Project settings: confirm restore behaviour is **"Transfer
   to new App User ID"**.
6. Xcode: confirm the **In-App Purchase** capability on the Runner target;
   add sandbox testers in App Store Connect. Play Console: add license
   testers and publish at least an internal-testing build (products are
   not purchasable until one exists).
7. Publish **Terms of Use** and **Privacy Policy** pages and put their
   URLs in `revenuecat_config.dart`; add the Terms link to the App Store
   description (Apple requires it for auto-renewing subscriptions).
8. Update App Store "App Privacy" and Play "Data safety" for purchase
   history, and the store listings to mention Quizoo Pro.
9. Firebase Remote Config: add `pro_enabled`.
10. Complete the paid-apps agreements, tax and banking in both consoles —
    products cannot be sold without them.

**Risks:**
- **App Review.** The usual rejections are a missing restore button,
  missing price/period disclosure, missing Terms/Privacy links, and
  benefits that are not actually delivered. All four are acceptance
  criteria. Provide a reviewer note that purchases work for guests.
- **The server lock is a behaviour change for everyone.** If the rule in
  2.3 is wrong, free players cannot start levels. It is verified in 2.8,
  and rolling back is re-applying the previous `start_level_attempt` body
  (keep it in the migration's rollback note).
- **Ad revenue vs subscription revenue.** Every Pro player stops seeing
  ads. Watch ARPDAU for both cohorts for a few weeks before adding more
  entry points.
- **Free-player goodwill.** Locks were always there, but the upsell is
  new. Keep the sheet to one line and one button, and do not add
  auto-opening paywalls without data.
- **Shipping Test Store keys.** A release build selects the platform key
  by `kReleaseMode`; an empty platform key must leave Pro unavailable
  rather than fall back to the Test Store key. Add an assertion test.
- **Rollback.** `pro_enabled = false` hides the feature without a release.
  The database changes are additive; the level lock is the only one worth
  reverting quickly.

**Rollout order:** Phase 2 (database + functions) → secrets and webhook →
Phase 1.4–1.6 once credentials validate → app release behind
`pro_enabled`, tested in sandbox on both stores → turn on.

**Further suggestions (not in this plan; each is a separate decision):**
- **Launch offer:** a discounted first year for early adopters, set up as
  a store introductory offer — the paywall already renders intro pricing.
- **Regional pricing:** set lower price tiers for Pakistan and India in
  both consoles; this audience is price-sensitive and the stores support
  per-territory prices without code.
- **Win-back and trial-expiry pushes** through RevenueCat + FCM, once real
  push opt-in exists (it is still mocked).
- **RevenueCat Experiments** to A/B yearly-first vs monthly-first and
  trial vs no trial, once there is traffic.
- **Paywall source in analytics:** log the `PaywallSource` on view and
  purchase to learn which entry point converts.
- **More Pro value over time**, from the research: Pro-only topics (the
  `is_locked` flag on categories/subcategories already exists with UI),
  an untimed practice mode, a daily-challenge archive, profile themes, a
  Pro-tinted challenge card in the duel arena, advanced stats, 5 lives.
- **A "Pro for a day" reward** (RevenueCat promotional entitlement via
  `grant-customer-entitlement`) for a 30-day streak, as a taste of Pro.
- **Real Delete Account** must also handle an active subscription (tell
  the player to cancel in the store) when that mock is replaced.

**To verify (developer, on a device — the agent must not run the app):**
- Debug build (Test Store): open the paywall from each entry point —
  locked level, Home card, You tab row, Settings, out-of-lives link, ad
  label, avatar picker, "Review answers" — and check the copy reads
  clearly in English and Urdu, light and dark.
- Buy yearly: welcome screen appears; go back and confirm ads are gone on
  Home, Ranks, Daily, Level Map and after results; the out-of-lives
  rewarded ad still plays.
- Level Map: every node is tappable; start level 25 of an untouched topic;
  the brief shows 2× 50:50 and 2× +5s; lose all lives and use the free
  revive once; the second time only the ad is offered.
- Finish a level: "Review answers" shows every question with the right
  answer and explanation, including an Urdu topic (RTL).
- Edit profile: pick a Pro avatar; check your crown and tick on Home, the
  You tab, the leaderboard self row, and — from a second device — in the
  leaderboard, a duel challenge card, the match intro and the duel result.
- Daily tab: freezes show 2 and the Pro refill line.
- Open `/pro` again: the membership screen shows the plan and date;
  "Manage subscription" opens the store page.
- As a guest: buy, then sign in with Google — Pro is still active and the
  first device id is no longer Pro.
- Sign out: ads return; sign in: Pro returns. Reinstall, tap "Restore
  purchases": Pro returns.
- Let the Test Store subscription expire (or revoke it in RevenueCat):
  locks, ads and the single power-ups return; the badge disappears on the
  second device; cleared levels and the Pro avatar remain.
- Free player: Level Failed shows no Pro mention; a locked level shows the
  small sheet, not the paywall directly.
- Sandbox on both real stores (`--dart-define=RC_USE_REAL_STORE=true`):
  real localized prices appear, the trial label matches the store offer,
  and a purchase reaches Supabase (`pro_subscriptions` row, `is_pro`
  true).
