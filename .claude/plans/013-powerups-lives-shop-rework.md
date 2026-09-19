# Power-ups, Lives & Shop Rework

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-09-19). The user is redesigning three connected systems at once: (1)
> retiring the Shop entirely, (2) cutting the in-level power-up dock from
> three infinite-use power-ups to two single-use ones, and (3/4) removing the
> paid "refill hearts" option and its false "lives refill every 30 minutes"
> copy from the out-of-lives dialog, replacing the free option with a real
> AdMob rewarded-video ad instead of today's mocked `Timer`.
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full. Code may have moved on since it was
written (dated 2026-09-19), so spot-check the referenced files and line
numbers still match before you begin — especially `quiz_play_cubit.dart`,
which is dense and has been touched by several prior plans (002, 004, 007).

This plan deliberately bundles all four of the user's decisions into one
document rather than splitting into `013a`/`013b`/etc: they are one coherent
change to the same three files (`QuizPlayCubit`, `QuizPlayState`,
`PowerUpDock`/`OutOfLivesDialog`) and touch the same `PowerUp` model, so
sequencing them separately would mean editing `quiz_play_cubit.dart` twice
for no benefit. Execute the phases below in order — later phases assume
earlier ones are done.

## Objective

1. Delete the Shop feature and every entry point into it. Nothing in the app
   can be purchased with coins or gems anymore.
2. Every level starts the player with exactly two power-ups — 50:50 and
   +5s (renamed down from +15s) — each usable at most once per level. The
   Skip power-up is removed from play entirely.
3. When hearts hit zero mid-level, the out-of-lives dialog offers exactly
   two choices: watch a real AdMob rewarded ad for one heart, or return to
   the level map. The paid coin-refill option is deleted.
4. The dialog's copy no longer claims lives regenerate on a timer — hearts
   are simply reset to 3 every time a level is started, and the dialog says
   that plainly.
5. AdMob is wired up for real (both platforms) for the first time in this
   app — today's `google_mobile_ads` dependency and native App IDs are
   present but never actually called from Dart. This plan makes the
   heart-for-ad flow the app's first genuine ad SDK integration.

## Scope

**In scope:**
- Deleting `lib/features/shop/` and `test/features/shop/` in full.
- Removing the Shop's two routes (`AppRoutes.shop`, `AppRoutes.rewardedAd`)
  and their `ScreenRef` entries from `lib/core/router/app_routes.dart`, and
  the corresponding `GoRoute`s from `lib/app/router.dart`.
- Removing `PowerUp.skip` and `PowerUp.freeze` from
  `lib/core/models/power_up.dart` (and regenerating its `.freezed.dart`/
  `.g.dart`), since Skip is explicitly cut and Freeze was shop-exclusive
  (duel-only cosmetic, never spent anywhere — see Research finding 4).
- Changing `PowerUpInventory.addTimeSeconds` from 15 to 5.
- Reworking how `QuizPlayCubit` allocates power-ups: granted once at
  `startLevel`/`startDaily` (one 50:50, one +5s) as part of `QuizRun`, spent
  from that same pool across the whole level, never reset per question.
- Updating `PowerUpDock`, `PowerUpTile`, `LevelBriefSheet`'s power-up
  preview row, and `FeedbackBanner` to match (drop the Skip tile, drop the
  shop-upsell "➕" tile, drop `SkippedFeedback`).
- Removing `AnswerOutcome.skipped` from `quiz_run.dart` and its one
  backend-facing branch in `quiz_result_api.dart` — confirmed safe to
  delete now rather than leave as dead code (user decision; see Assumptions).
- Removing `QuizPlayCubit.refillHeartsWithCoins`, `QuizPlayOutOfLives.coins`/
  `.heartRefillAt`/`.canAffordRefill`, `MockPlayer.refillCost`, and the
  "Refill 5 ❤️" button from `OutOfLivesDialog`.
- Rewriting `outOfLivesBody`'s copy (English + Urdu `.arb`) to state hearts
  reset to 3 next level, not "refill every 30 minutes".
- A real AdMob rewarded-ad integration: `MobileAds.instance.initialize()` at
  app boot, a `RewardedAdService` seam (mirroring this feature's existing
  `TtsService`/`SoundEffectsService` seams) with an AdMob-backed
  implementation, and a new small `HeartAdCubit` that owns the
  load→ready→playing→succeeded/failed state machine for the out-of-lives
  dialog's "watch ad" button — replacing `QuizPlayCubit`'s mocked
  `watchAdForHeart`/`_adTimer`/`adDuration`.
- Native AdMob setup completeness on both platforms: confirming/adding the
  Android `INTERNET` permission, and adding iOS's `SKAdNetworkItems` +
  `NSUserTrackingUsageDescription` to `Info.plist` (Google's own AdMob
  Flutter setup guide lists both as required steps; today's `Info.plist` has
  neither — see Research finding 6).
- Test coverage: updating `quiz_play_cubit_test.dart` for the new power-up
  allocation and the new `grantHeartFromAd()` method, deleting the
  Skip-related test lines, and a new `heart_ad_cubit_test.dart` following
  this project's existing fake-collaborator `bloc_test` convention (see
  Research finding 8).
- l10n cleanup: removing every `shop*`/`rewardedAd*` (coins-flavored)
  `.arb` key that only the deleted Shop feature used, and
  `levelBriefShop`/`quizPowerUpSkip`/`shopPowerUp*` keys.

**Out of scope:**
- The Home top bar's separate wallet-level hearts system
  (`profiles.hearts`/`max_hearts`/`hearts_updated_at`, a real 20-minute
  server-side regen via `home_api.dart` and Postgres's `_settle_hearts`).
  This is a **different, already-real** hearts economy from the per-level
  `QuizRun.heartsRemaining` this plan touches — see Research finding 3. The
  user's complaint about "refill every 30 minutes" is specifically about the
  out-of-lives dialog's copy, not this system, and nothing here changes it.
- Any change to how coins/gems are earned (daily challenge, duel payouts) —
  only how they're **spent** disappears, because the Shop was the only place
  that spent them. See Assumptions below.
- `PowerUp.freeze`'s duel angle in general — `features/duel` never consumed
  it even before this plan (confirmed via grep), so nothing in `duel` needs
  touching.
- Replacing Google's public **test** AdMob App IDs already in
  `AndroidManifest.xml`/`Info.plist` with production IDs — out of scope per
  existing project convention (already tracked as a pre-release TODO; see
  Research finding 6). This plan adds a **test rewarded ad unit ID** on top
  of those, consistent with the App IDs already there.
- `in_app_purchase` (coin packs / remove-ads) — already fully unimplemented
  (`_mockPurchase` no-ops) and now moot once the Shop screen that hosted
  them is deleted.
- Backend/Postgres changes of any kind — removing `AnswerOutcome.skipped`
  (now in scope, see below) is a pure client-side deletion: its only
  backend-facing use is one branch of a `switch` with an existing wildcard
  fallback (`_ => 'answered'`), so no RPC/migration change is needed.

## Research findings

1. **The in-level power-up dock resets every question, not once per level —
   confirmed bug, and this plan is what fixes it.** `QuizPlayCubit._beginQuestion`
   (`lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart:373-377`)
   re-emits `PowerUpInventory(fiftyFifty: MockPlayer.fiftyFiftyCount,
   addTime: MockPlayer.addTimeCount, skip: MockPlayer.skipCount)` on **every
   single question**, so today a player effectively has unlimited power-up
   uses per level. `MOCKED_FEATURES.md` (repo root) already flags this at
   line 25 as a known mock-phase gap. This plan's Phase 2 fixes it by moving
   the initial grant into `QuizRun` (created once in `startLevel`) and
   threading `powerUps` through `AnsweredQuestion`-style state instead of
   re-seeding it in `_beginQuestion`.

2. **`PowerUp` is a shared `core/` enum, promoted there in plan 004
   specifically because Shop needed it too** (`lib/core/models/power_up.dart:8-12`,
   its own doc comment). With Shop deleted, `quiz_play` becomes the only
   consumer of `PowerUp`/`PowerUpInventory` — CLAUDE.md §2's "reused by 3+
   features" bar is no longer met, but this plan does **not** move it back
   down into `features/quiz_play/domain/`, per CLAUDE.md §10 ("shared,
   frequently-touched files... should only be added to... a restructuring
   is a separate, explicit task"). Leaving it in `core/models/` and simply
   trimming its two now-dead enum values is the smaller, in-scope change.

3. **There are two separate hearts systems in this codebase, and the spec's
   items 3/4 are about only one of them.**
   - **Per-level hearts** (`QuizRun.heartsRemaining`, default 3): reset to
     `MockPlayer.livesPerLevel` (= 3) at the top of every `startLevel`/
     `startDaily` call (`quiz_play_cubit.dart:238,311`), decremented on a
     wrong answer, and the trigger for `QuizPlayOutOfLives`
     (`quiz_play_cubit.dart:628-639`). **This is the system the spec's items
     3 and 4 are about** — the user confirms "3 hearts in each level, this
     is right" and wants the dialog's copy to say hearts reset per level,
     not regenerate on a clock.
   - **Wallet hearts** (`profiles.hearts`/`max_hearts`/`hearts_updated_at`,
     read by `home_api.dart:104,328-340`): a real, Postgres-backed, 20-minute
     auto-regen system (`_settle_hearts`, referenced in `main.dart`'s Remote
     Config default `heart_refill_minutes: 20`) shown as a pill in the Home
     top bar (`home_top_bar.dart:133`). This is a genuinely different,
     already-correct feature and is untouched by this plan.
   - The per-level dialog's `heartRefillAt` field
     (`quiz_play_state.dart:309`) is unrelated to the wallet system above —
     it's fed by `MockPlayer.currency.heartRefillAt` (always ~28 minutes out,
     `mock_player.dart:33`) purely to drive the now-deleted "Refill 5 ❤️"
     button's clock display. Deleting the refill button removes the need for
     this field entirely.

4. **`PowerUp.freeze` is genuinely dead once Shop is deleted.**
   `power_up.dart:14-20`'s own doc comment already says Freeze is
   "shop-only for now" with "no solo-play mechanic" and duel networking
   explicitly out of scope. A repo-wide grep for `PowerUp.freeze` outside
   `core/models/` and `features/shop/` returns nothing. Safe to delete
   alongside `PowerUp.skip`.

5. **AdMob is a listed dependency and has native App IDs configured, but is
   never actually called from Dart anywhere in the app** — confirmed by
   `grep -rn "package:google_mobile_ads" lib` returning zero results and
   `MOCKED_FEATURES.md`'s own audit (lines 26, 41) explicitly stating both
   of the app's two "watch an ad" flows (`quiz_play`'s heart-for-ad and
   Shop's coin-for-ad) are a bare `Timer`, "no ad SDK is involved". This
   plan is the first real use of the `google_mobile_ads: ^9.1.0` pubspec
   dependency.
   - `pubspec.yaml:46` already has `google_mobile_ads: ^9.1.0`.
   - `android/app/src/main/AndroidManifest.xml:41-43` already has
     `com.google.android.gms.ads.APPLICATION_ID` set to
     `ca-app-pub-3940256099942544~3347511713` — **this is Google's public
     sample/test AdMob App ID**, not a real one (tracked separately per this
     project's own memory as a pre-release TODO — out of scope here).
   - `ios/Runner/Info.plist:28-29` already has `GADApplicationIdentifier` set
     to `ca-app-pub-3940256099942544~1458002511` — the iOS equivalent test
     App ID.
   - **Interpreting "text ads" in the spec**: AdMob has no ad format called
     "text ads" (its formats are Banner/Interstitial/Rewarded/Rewarded
     Interstitial/Native/App Open). Given the surrounding sentence is
     entirely about "watch an ad for 1 heart" — a rewarded-video flow — and
     the App IDs already in place are Google's own public **test** values,
     this plan reads "text ads" as a typo for **"test ads"**: Google's
     public test rewarded ad unit IDs, matching the test App IDs already
     committed. **Confirmed with the user** — this reading is correct.

6. **AdMob's own Flutter setup guide lists two native steps this repo is
   still missing**, found by inspecting both native config files in full:
   - Android: no explicit `<uses-permission
     android:name="android.permission.INTERNET"/>` in
     `AndroidManifest.xml` (Flutter's own template usually merges this in
     for you, but Google's AdMob quickstart calls it out explicitly as
     required, and it costs nothing to be explicit here).
   - iOS: no `SKAdNetworkItems` array and no
     `NSUserTrackingUsageDescription` key in `Info.plist`. Both are
     Google's documented required/recommended entries for `google_mobile_ads`
     on iOS. Without `NSUserTrackingUsageDescription`, iOS won't show the
     ATT prompt and fill rates degrade but ads (including test ads) still
     load — so this doesn't block the feature working, but "implement the
     functionality fully" (the user's own words) means completing this
     alongside the code change rather than leaving it as a silent gap.

7. **The Shop's existing `RewardedAdCubit`/`RewardedAdDialog` pair
   (`lib/features/shop/presentation/bloc/rewarded_ad_cubit.dart`,
   `.../widgets/rewarded_ad_dialog.dart`) is the pattern to mirror, not
   reuse.** It's a small, dedicated Cubit (`Ready → Playing → Succeeded /
   Failed`, with `retry()` bouncing `Failed` back to `Ready` so the button
   is "never a dead button" — its own doc comment) that the dialog widget
   `BlocProvider`s locally, reporting success back up to the owning Cubit
   (`ShopCubit.creditRewardedAd`) via a callback rather than the two Cubits
   sharing state. This plan's `HeartAdCubit` (Phase 4) copies this exact
   shape but swaps the `Timer`+`Random` for a real `RewardedAdService` call,
   and drops the coin-specific fields (`coinsBefore`/`rewardCoins`/
   `freeAdsLeft`/`freeAdsPerDay`) since the reward here is always exactly
   one heart. The old file is deleted with the rest of `features/shop/`.

8. **Testing conventions confirmed from `quiz_play_cubit_test.dart` and
   `shop/rewarded_ad_cubit_test.dart`**: Cubit dependencies that wrap a
   plugin/SDK are given a hand-written *fake* implementing the abstract
   service interface (not a `mocktail` `Mock`) whenever the test needs to
   control async completion timing precisely (`_FakeTtsService.complete()`
   at `quiz_play_cubit_test.dart:33-59` is the exact pattern — a `Mock`
   can't express "the plugin's completion callback fires now"). The new
   `RewardedAdService` gets the same treatment: a `_FakeRewardedAdService`
   with completer-backed `load()`/`show()` that tests drive manually. Every
   Cubit test file uses `package:bloc_test/bloc_test.dart`'s `blocTest`
   with `build`/`act`/`expect`, matching CLAUDE.md §11.

9. **`AnswerOutcome.skipped`** (`quiz_run.dart:13`) is only ever *written*
   client-side, in `quiz_result_api.dart:28`, when submitting a finished run
   to `submit_level_attempt`. Nothing in the client reads `.skipped` back,
   and that `switch` already has a wildcard fallback (`_ => 'answered'`),
   so removing this one branch is a clean deletion with no exhaustiveness
   fallout. Once `PowerUp.skip` is removed, no code path can produce this
   outcome anymore — **confirmed with the user: delete the enum value and
   its mapping now** rather than leave it as dead code (see Phase 2).

10. **Level-map / catalog code has zero other `PowerUp`/Shop coupling.**
    `level_brief_sheet.dart` (`features/catalog/presentation/widgets/`) is
    the only file outside `quiz_play`/`shop`/`core/models` that references
    `PowerUp` names or `MockPlayer`'s power-up counts, and only for its
    preview row — confirmed via `grep -rn "PowerUp\." lib/features` finding
    no hits outside `shop`, `quiz_play_cubit.dart`, and `power_up_dock.dart`.

## Assumptions & open questions

All four items below were open questions in the first draft of this plan;
each has since been confirmed directly with the user, so none of them block
implementation.

- **"Text ads" means "test ads" — confirmed.** The spec's "use text ads"
  is Google's public test rewarded ad unit IDs, not a distinct AdMob ad
  format. Phase 4 proceeds exactly as designed (a `RewardedAd`, not a
  `NativeAd`).
- **Coins/gems having no spend destination once the Shop is deleted is
  acceptable — confirmed.** They're still earned (daily challenge, duel
  payouts) and still shown in the Home top bar; purchasing simply goes
  away with the Shop, with no replacement spend surface added by this plan.
  Not something this plan needs to resolve further.
- **Out-of-lives dialog copy is left to the implementer — confirmed.** The
  only hard constraint is: no claim that hearts regenerate on a timer, and
  it should communicate that a fresh level start grants 3 hearts again. See
  Phase 3's l10n step for the exact placeholder-free key shape; wording
  itself is a product-voice call for whoever writes the `.arb` strings.
- **`AnswerOutcome.skipped` is deleted, not kept — confirmed.** The user
  opted to remove it now rather than leave it as dead code, since its only
  backend-facing use falls through an existing wildcard (`_ => 'answered'`)
  with no exhaustiveness or migration impact. See Phase 2's added steps.
- **The +5s power-up keeps the name `addTime` / `PowerUp.addTime`** rather
  than being renamed in code — only `PowerUpInventory.addTimeSeconds`'s
  *value* changes (15 → 5). Renaming the enum value itself would be a
  larger, purely-cosmetic diff across every file in the "Research findings"
  grep above for no behavioral benefit.
- **`HeartAdCubit` shows the ad on demand (load-on-dialog-open), not
  preloaded earlier in the level.** The spec doesn't ask for a pre-warmed ad
  the moment the level starts, and preloading earlier would mean holding a
  loaded `RewardedAd` in memory for a run that may never go out of lives.
  On-demand load when `QuizPlayOutOfLives` is first reached is the smaller,
  correct-by-default choice; if load latency turns out to feel slow in
  testing, that's a follow-up tuning task, not a blocker for this plan.

## Design overview

### Power-up allocation moves into `QuizRun`

`QuizRun` (`lib/features/quiz_play/domain/quiz_run.dart`) gains a
`@Default(PowerUpInventory()) PowerUpInventory powerUps` field, granted once
in `startLevel`/`startDaily` as
`const PowerUpInventory(fiftyFifty: 1, addTime: 1)` (Daily still gets the
grant for symmetry, but recall the dock is already hidden for `isDaily` runs
per existing behavior — see `PowerUpDock` guard in `quiz_play_screen.dart:540`
— so it's inert there, same as today's `heartsRemaining` being "decorative
only" for Daily per the existing doc comment at `quiz_play_cubit.dart:252`).

`QuizPlayInProgress.powerUps` (today re-seeded per question) becomes derived
from `run.powerUps` instead: `_beginQuestion` stops constructing a fresh
`PowerUpInventory` and instead reads `run.powerUps` directly. `usePowerUp`
already calls `current.powerUps.spend(powerUp)` and writes the result back
onto `run.copyWith(usedPowerUp: true)` in the `PowerUp.fiftyFifty` branch —
that write needs to additionally carry the spent inventory onto `run`
(`run.copyWith(usedPowerUp: true, powerUps: spent)`) so it survives into the
next question's `_beginQuestion` instead of being thrown away. Same for the
`PowerUp.addTime` branch.

### Out-of-lives dialog sheds the paid path

`QuizPlayOutOfLives` drops to:

```dart
final class QuizPlayOutOfLives extends QuizPlayState {
  const QuizPlayOutOfLives({required this.underlying});
  final QuizPlayInProgress underlying;
  @override
  List<Object?> get props => [underlying];
}
```

`QuizPlayCubit.watchAdForHeart()`/`refillHeartsWithCoins()` are deleted.
`_resolveWrong` (which currently constructs `QuizPlayOutOfLives(underlying:
resolved, coins: ..., heartRefillAt: ...)`) simplifies to
`emit(QuizPlayOutOfLives(underlying: resolved))`. A new, simple
`grantHeartFromAd()` method replaces the old async `watchAdForHeart`:

```dart
void grantHeartFromAd() {
  final current = state;
  if (current is! QuizPlayOutOfLives) return;
  _grantHearts(current.underlying, hearts: 1);
}
```

The async "is the ad currently playing" state (`isWatchingAd` today) moves
into the new `HeartAdCubit` below — `QuizPlayCubit` itself no longer needs to
know an ad is in flight, matching how `ShopCubit` never knew about
`RewardedAdCubit`'s `Playing` state either.

### `HeartAdCubit` — the real AdMob integration

New files under `lib/features/quiz_play/`:

- `data/rewarded_ad_service.dart` — the seam, mirroring `data/tts_service.dart`:
  ```dart
  abstract class RewardedAdService {
    /// Loads a rewarded ad. Returns true once it's ready to [show].
    Future<bool> load();
    /// Shows the ad already loaded by [load]. Returns true iff the user
    /// watched to completion and earned the reward.
    Future<bool> show();
    Future<void> dispose();
  }
  ```
- `data/admob_rewarded_ad_service.dart` — the concrete AdMob implementation:
  wraps `RewardedAd.load(adUnitId: _adUnitId, request: const AdRequest(),
  rewardedAdLoadCallback: RewardedAdLoadCallback(onAdLoaded: ..., onAdFailedToLoad: ...))`
  in a `Completer<bool>` for `load()`; `show()` calls
  `_ad!.show(onUserEarnedReward: (_, __) => earned = true)` with a
  `FullScreenContentCallback` whose `onAdDismissedFullScreenContent`/
  `onAdFailedToShowFullScreenContent` complete a second `Completer<bool>`
  with `earned`'s final value, then dispose the spent `RewardedAd` and null
  it out. `_adUnitId` is chosen by `Platform.isAndroid` /
  `Platform.isIOS` between Google's two public test rewarded ad unit IDs
  (`ca-app-pub-3940256099942544/5224354917` Android,
  `ca-app-pub-3940256099942544/1712485313` iOS — Google's documented public
  test values, matching the test App IDs already in this repo's native
  config; see Scope's out-of-scope note on swapping to production IDs).
- `presentation/bloc/heart_ad_cubit.dart` + `heart_ad_state.dart` — mirrors
  `shop`'s `RewardedAdCubit`/`RewardedAdState` shape exactly, minus the
  coin-specific fields:
  ```dart
  sealed class HeartAdState extends Equatable {
    const HeartAdState();
  }
  final class HeartAdLoading extends HeartAdState { const HeartAdLoading(); }
  final class HeartAdReady extends HeartAdState { const HeartAdReady(); }
  final class HeartAdPlaying extends HeartAdState { const HeartAdPlaying(); }
  final class HeartAdSucceeded extends HeartAdState { const HeartAdSucceeded(); }
  final class HeartAdFailed extends HeartAdState { const HeartAdFailed(); }
  ```
  `HeartAdCubit(this._service) : super(const HeartAdLoading())` kicks off
  `_load()` in its constructor (`unawaited(_load())`), which calls
  `_service.load()` and emits `HeartAdReady`/`HeartAdFailed` on the result.
  `watch()` (only valid from `HeartAdReady`) emits `HeartAdPlaying`, calls
  `_service.show()`, and emits `HeartAdSucceeded`/`HeartAdFailed`. `retry()`
  (only valid from `HeartAdFailed`) re-emits `HeartAdLoading` and calls
  `_load()` again — the "never a dead button" contract from the Shop's
  version (Research finding 7), now covering both load-failure and
  show-failure with one retry path.

### `OutOfLivesDialog` wiring

`quiz_play_screen.dart`'s `QuizPlayOutOfLives` branch changes from directly
building `OutOfLivesDialog` to wrapping it in a `BlocProvider<HeartAdCubit>`
(created with `AdMobRewardedAdService()`), exactly like
`RewardedAdDialog.show` wraps `RewardedAdCubit` today. `OutOfLivesDialog`
itself becomes a `BlocConsumer<HeartAdCubit, HeartAdState>`: the "Watch ad"
button's label/enabled-state switches on `HeartAdState` (loading = disabled
"Loading…", ready = tappable, playing = disabled "Playing ad…"), a listener
shows an `AppSnackbar` error + calls `retry()` on `HeartAdFailed`, and calls
`context.read<QuizPlayCubit>().grantHeartFromAd()` + pops the dialog on
`HeartAdSucceeded`. The "Refill" `ChunkyButton` and its `onRefill` callback
are deleted outright; "Back to level map" is unchanged.

### Native AdMob setup

- `lib/main.dart`: add `await MobileAds.instance.initialize();` alongside
  the existing `Firebase.initializeApp`/Remote Config block, before
  `runApp`.
- `android/app/src/main/AndroidManifest.xml`: add
  `<uses-permission android:name="android.permission.INTERNET"/>` as a
  top-level `<manifest>` child (before `<application>`).
- `ios/Runner/Info.plist`: add `NSUserTrackingUsageDescription` (a short,
  honest string — e.g. "This identifier will be used to deliver
  personalized ads to you.") and a `SKAdNetworkItems` array containing
  Google's documented AdMob SKAdNetwork identifiers (the standard list
  Google publishes for `google_mobile_ads` — copy verbatim from Google's
  current AdMob iOS setup page at implementation time, since Google adds
  new ad-network IDs to this list periodically and a plan written today
  shouldn't hardcode a list that may already be stale).

## Implementation steps

### Phase 1 — Delete the Shop feature

- [ ] Delete `lib/features/shop/` (all of `data/`, `domain/`,
      `presentation/`) and `test/features/shop/` in full.
- [ ] `lib/core/router/app_routes.dart`: remove the `shop`/`rewardedAd`
      path constants (lines ~150-152), the `s36`/`s37` aliases (lines
      ~251-252), and their two `ScreenRef(...)` entries (lines ~386-387).
- [ ] `lib/app/router.dart`: remove the `import
      'package:quizoo/features/shop/presentation/screens/shop_screen.dart';`
      and the two `GoRoute`s for `AppRoutes.shop`/`AppRoutes.rewardedAd`
      (lines ~276-288).
- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`:
      remove `PowerUpDock`'s `onBuy: () => context.push(AppRoutes.shop)`
      argument (see Phase 2 for the dock's new zero-inventory behavior that
      replaces it).
- [ ] `lib/core/widgets/power_up_tile.dart`: remove the `onBuy` callback
      entirely — a tile at zero count is dimmed and inert (no tap target),
      since there's nowhere left for a tap to route to. Update its doc
      comment (currently: "a tile the player has none of drops to 40% and
      opens the shop instead of firing").
- [ ] `lib/features/quiz_play/presentation/widgets/power_up_dock.dart`:
      drop the now-unused `onBuy` parameter and its pass-through to
      `PowerUpTile`.
- [ ] `lib/features/catalog/presentation/widgets/level_brief_sheet.dart`:
      remove the fourth `_BriefPowerUp` tile (the dimmed "➕ SHOP" one at
      lines 203-208) from the power-up preview row.
- [ ] l10n: remove every `shop*` and `rewardedAd*` key from
      `lib/l10n/app_en.arb` and `lib/l10n/app_ur.arb` (≈50 keys total —
      `shopTitle` through `rewardedAdSuccessTitle` and its neighbors), plus
      `levelBriefShop`. Run `flutter gen-l10n` (per `l10n.yaml`) to
      regenerate `app_localizations*.dart` afterward rather than hand-editing
      the generated files.

### Phase 2 — Two single-use power-ups, no Skip

- [ ] `lib/core/models/power_up.dart`: remove `PowerUp.skip` and
      `PowerUp.freeze` from the enum; remove their corresponding branches
      from `PowerUpPricing.emoji`/`.costCoins`/`.costGems` and
      `PowerUpInventory.countOf`/`.spend`/`.grant`; remove the `skip`/
      `freeze` fields from the `@freezed` `PowerUpInventory` class; change
      `addTimeSeconds` from `15` to `5`. Regenerate
      `power_up.freezed.dart`/`power_up.g.dart` via `dart run build_runner
      build --delete-conflicting-outputs`.
- [ ] `lib/core/mock/mock_player.dart`: remove `skipCount` (and consider
      whether `fiftyFiftyCount`/`addTimeCount` are still needed anywhere —
      see next step; if the only remaining reader is `LevelBriefSheet`'s
      preview row, keep them there as "what a fresh level grants", now both
      hardcoded to their real value of 1 rather than 3/1).
- [ ] `lib/features/quiz_play/domain/quiz_run.dart`: add
      `@Default(PowerUpInventory()) PowerUpInventory powerUps` to `QuizRun`.
      Regenerate `quiz_run.freezed.dart`/`quiz_run.g.dart`.
- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart`:
  - In `startLevel` and `startDaily`, construct the `QuizRun` with
    `powerUps: const PowerUpInventory(fiftyFifty: 1, addTime: 1)`.
  - In `_beginQuestion`, change `QuizPlayInProgress(... powerUps: const
    PowerUpInventory(...) ...)` to `powerUps: run.powerUps` — no longer
    re-seeded from `MockPlayer` per question.
  - In `usePowerUp`'s `PowerUp.fiftyFifty` and `PowerUp.addTime` branches,
    change `run.copyWith(usedPowerUp: true)` to
    `run.copyWith(usedPowerUp: true, powerUps: spent)` so the spend
    persists onto the run itself, not just the transient
    `QuizPlayInProgress.powerUps`.
  - Delete the entire `case PowerUp.skip:` branch and the now-unreachable
    `case PowerUp.freeze:` branch (the switch becomes exhaustive over just
    `fiftyFifty`/`addTime`).
  - Change the `addTime` branch's `Duration(seconds:
    PowerUpInventory.addTimeSeconds)` — no code change needed here since it
    already reads the constant, but confirm the +5s value flows through
    correctly (it will, once Phase 2's constant change lands).
- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_state.dart`:
      delete `SkippedFeedback` and its reference in
      `QuestionFeedback`'s sealed hierarchy.
- [ ] `lib/features/quiz_play/presentation/widgets/power_up_dock.dart`:
      remove the `(PowerUp.skip, '⏭️', l10n.quizPowerUpSkip)` tuple from
      `tiles`.
- [ ] `lib/features/quiz_play/presentation/widgets/feedback_banner.dart`:
      remove the `SkippedFeedback()` branch from the `switch (feedback)`
      that builds `(emoji, title, trailing)`, and the
      `case SkippedFeedback():` no-op branch in the body-suffix switch.
- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`:
      remove the `state.feedback is! SkippedFeedback` guard at line ~557
      (find the current equivalent condition once `SkippedFeedback` no
      longer exists — the surrounding logic that decided when the arena
      shows a shake-on-wrong animation needs its condition re-checked
      against the remaining `QuestionFeedback` subtypes).
- [ ] `lib/features/catalog/presentation/widgets/level_brief_sheet.dart`:
      remove the Skip `_BriefPowerUp` tile (lines 197-201); the row now
      shows exactly two tiles (50:50, +5s).
- [ ] l10n: remove `quizPowerUpSkip` and `shopPowerUpSkipBody` (the latter
      already removed in Phase 1 with the rest of `shop*`). Update
      `quizPowerUpAddTime`'s body copy anywhere it says "15 seconds" (check
      `levelBriefPowerUps`/any description strings) to say "5 seconds".
- [ ] `lib/features/quiz_play/domain/quiz_run.dart`: remove `skipped` from
      the `AnswerOutcome` enum (line 13), leaving `{ correct, wrong,
      timedOut }`. Regenerate `quiz_run.g.dart` (its `_$AnswerOutcomeEnumMap`
      drops the `'skipped'` entry automatically).
- [ ] `lib/features/quiz_result/data/quiz_result_api.dart`: remove the
      `AnswerOutcome.skipped => 'skipped',` branch (line 28) from the
      `action` switch — the existing `_ => 'answered'` wildcard already
      covers every remaining case, so no other change is needed here.

### Phase 3 — Out-of-lives dialog: drop the refill, fix the copy

- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_state.dart`:
      simplify `QuizPlayOutOfLives` to just `{required this.underlying}`,
      dropping `coins`, `heartRefillAt`, `isWatchingAd`, and the
      `canAffordRefill` getter (see Design overview for the exact shape).
- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart`:
  - In `_resolveWrong`, simplify the `QuizPlayOutOfLives(...)` construction
    to `QuizPlayOutOfLives(underlying: resolved)`.
  - Delete `watchAdForHeart()`, `refillHeartsWithCoins()`, `_adTimer`, and
    `adDuration`.
  - Add `grantHeartFromAd()` per the Design overview snippet.
  - Remove `_adTimer?.cancel()` from `_finish()` and `close()` (no longer
    exists after the above deletion).
- [ ] `lib/core/mock/mock_player.dart`: remove `refillCost`. Leave
      `currency` (still used by `home_screen.dart` for the unrelated wallet
      system per Research finding 3).
- [ ] `lib/features/quiz_play/presentation/widgets/out_of_lives_dialog.dart`:
      remove `onRefill`, the "Refill" `ChunkyButton`, and the
      `state.canAffordRefill`/`MockPlayer.refillCost` reads. Update the
      class doc comment (currently describes the three-option layout).
      Message body switches from `l10n.outOfLivesBody(AppFormat.clock(...))`
      to a plain `l10n.outOfLivesBody` with no placeholder (see next step).
- [ ] l10n (`app_en.arb`/`app_ur.arb`): rewrite `outOfLivesBody` to drop the
      `{time}` placeholder and the "refill every 30 minutes" claim — e.g.
      `"Watch an ad for one more heart, or come back with 3 fresh hearts
      next time you start this level."` (exact copy is a product-voice call
      for whoever implements this — the constraint is just: no timer/clock
      claim). Delete `outOfLivesRefill` and `outOfLivesNotEnoughCoins`
      entirely (their only reader is the deleted Refill button). Update the
      `@outOfLivesBody` metadata's `description`/`placeholders` to match the
      new no-placeholder signature. Run `flutter gen-l10n` afterward.
- [ ] `lib/core/format/app_format.dart`: check whether `AppFormat.clock` has
      any remaining callers after this change (Research: today its only
      caller is `out_of_lives_dialog.dart`). If none remain, delete it;
      otherwise leave it.

### Phase 4 — Real AdMob rewarded-ad integration

- [ ] `lib/main.dart`: add `import
      'package:google_mobile_ads/google_mobile_ads.dart';` and `await
      MobileAds.instance.initialize();`, placed after
      `WidgetsFlutterBinding.ensureInitialized()` (order relative to the
      Supabase/Firebase calls doesn't matter functionally, but grouping it
      with the other SDK-init calls near `Firebase.initializeApp` keeps
      `main()` readable).
- [ ] `android/app/src/main/AndroidManifest.xml`: add
      `<uses-permission android:name="android.permission.INTERNET"/>` as a
      direct child of `<manifest>`, before `<application>`.
- [ ] `ios/Runner/Info.plist`: add `NSUserTrackingUsageDescription` and
      `SKAdNetworkItems` per the Design overview's native-setup section.
- [ ] Create `lib/features/quiz_play/data/rewarded_ad_service.dart` (the
      abstract seam) per the Design overview's exact interface.
- [ ] Create `lib/features/quiz_play/data/admob_rewarded_ad_service.dart`
      (the concrete AdMob-backed implementation) per the Design overview.
      Use `dart:io`'s `Platform.isAndroid`/`Platform.isIOS` to select the
      platform-specific test rewarded ad unit ID.
- [ ] Create `lib/features/quiz_play/presentation/bloc/heart_ad_state.dart`
      + `heart_ad_cubit.dart` per the Design overview's exact state shape
      and transitions (mirroring `shop`'s deleted `rewarded_ad_cubit.dart`
      structurally).
- [ ] `lib/features/quiz_play/presentation/widgets/out_of_lives_dialog.dart`:
      convert to a `BlocConsumer<HeartAdCubit, HeartAdState>` for the "Watch
      ad" button's label/enabled state (`HeartAdLoading`/`HeartAdReady`/
      `HeartAdPlaying` per Design overview), with a listener that shows an
      `AppSnackbar` (reusing `rewardedAdFailedTitle`/`rewardedAdFailedBody`
      wording style from the now-deleted shop feature, added back as
      `outOfLives`-scoped keys since the old ones were deleted in Phase 1 —
      or simply reuse generic `commonError`-style copy if one already
      exists; check `app_en.arb` for an existing generic ad-failure string
      before adding a new one) and calls `retry()` on `HeartAdFailed`, and
      that calls `QuizPlayCubit.grantHeartFromAd()` + pops the dialog on
      `HeartAdSucceeded`.
- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`:
      wrap the `OutOfLivesDialog` in a `BlocProvider<HeartAdCubit>(create:
      (_) => HeartAdCubit(AdMobRewardedAdService()))` at the `QuizPlayOutOfLives`
      branch (see Design overview's "OutOfLivesDialog wiring").

### Phase 5 — Tests

- [ ] `test/features/quiz_play/quiz_play_cubit_test.dart`:
  - Update the existing 50:50 test (`expect(state.powerUps.fiftyFifty, 2)`
    after one use — line ~796) to expect `0` (starting from 1, not 3).
  - Add/update a test asserting `run.powerUps` carries the spend across a
    `next()` transition into the following question (the bug Research
    finding 1 identifies) — i.e., use 50:50 on question 1, advance, assert
    `state.powerUps.fiftyFifty == 0` on question 2 too, not reset to 1.
  - Update or remove any assertion depending on `PowerUp.skip`/`SkippedFeedback`.
  - Add a test for `grantHeartFromAd()`: from a `QuizPlayOutOfLives` state,
    calling it transitions back to `QuizPlayInProgress` with
    `heartsRemaining == 1` and resumes the auto-advance timer (mirroring
    the existing `_grantHearts` test coverage for the deleted
    `refillHeartsWithCoins`/`watchAdForHeart`, if any existed — confirm by
    reading the current file's out-of-lives test block before editing).
  - Remove any assertions on `QuizPlayOutOfLives.coins`/`.heartRefillAt`/
    `.canAffordRefill`.
- [ ] `test/features/quiz_play/quiz_play_cubit_daily_test.dart`: check for
      power-up-related assertions (Daily's run also now carries a
      `powerUps` field with a real default) — update construction sites if
      the test asserts on `QuizRun`'s full field set.
- [ ] `test/features/quiz_play/quiz_play_screen_test.dart`: the existing
      `'S-19 out of lives: the free option is offered first'` test
      (line ~320) already only checks for `outOfLivesWatchAd`/
      `outOfLivesBackToMap` text, not the removed Refill button — confirm
      it still passes as-is, and add a new widget test asserting the
      Refill button/text is now absent (`find.text(l10n.outOfLivesRefill)`
      no longer compiles once the key is deleted, so this becomes a
      structural `findsNothing` check on the button count instead, e.g.
      `expect(find.byType(ChunkyButton), findsNWidgets(2))` inside the
      dialog).
- [ ] New `test/features/quiz_play/heart_ad_cubit_test.dart`: following the
      `_FakeTtsService`-style fake convention (Research finding 8), write a
      `_FakeRewardedAdService` with completer-controlled `load()`/`show()`,
      and `blocTest` coverage for: initial `HeartAdLoading` → `HeartAdReady`
      on load success; `HeartAdLoading` → `HeartAdFailed` on load failure;
      `HeartAdReady` → `HeartAdPlaying` → `HeartAdSucceeded` on a successful
      watch; `HeartAdReady` → `HeartAdPlaying` → `HeartAdFailed` on a failed
      watch; and `retry()` bouncing `HeartAdFailed` back through
      `HeartAdLoading` to a fresh `load()` call.
- [ ] Delete `test/features/shop/` (done in Phase 1, listed here as a
      reminder to run the full suite afterward and confirm nothing else
      references it).
- [ ] After all `.arb`/model changes: run `flutter gen-l10n`, `dart run
      build_runner build --delete-conflicting-outputs`, `dart format .`,
      and `dart analyze` (CLAUDE.md §8 — zero warnings before calling this
      done), then the full `flutter test` suite.

## Data model / API changes

No Supabase/Postgres schema changes. `QuizRun.powerUps` and the trimmed
`PowerUpInventory` are client-side domain model changes only — `QuizRun` is
never persisted to the backend as JSON (it's handed to `QuizResultCubit`
via the route's `extra`, per its own doc comment in `quiz_run.dart:64-65`),
so no migration is needed. Removing `AnswerOutcome.skipped` and its one
backend-facing branch in `quiz_result_api.dart` is likewise a pure
client-side deletion — `submit_level_attempt` never receives the literal
`'skipped'` string from the client after this change, but the RPC itself is
untouched (its remaining accepted actions — `'timedOut'`/`'answered'` — are
unaffected), so no Postgres migration is needed here either.

## Dependencies

No new pubspec dependencies — `google_mobile_ads: ^9.1.0` is already present
and unused; this plan is what starts using it. No dependency removed either:
`in_app_purchase` stays in `pubspec.yaml` even though its only caller
(`shop_screen.dart`'s `_mockPurchase`) is deleted, since it's not imported
by name anywhere the way `google_mobile_ads` needed a first real caller —
confirm with a grep before removing it in a future cleanup if desired, but
that's not part of this spec's four decisions.

## Testing strategy

Matches this project's existing conventions throughout (CLAUDE.md §11):
`bloc_test` for every Cubit change (`QuizPlayCubit`'s existing suite,
`HeartAdCubit`'s new one), hand-written fakes over `mocktail` `Mock`s for
any collaborator whose async completion timing the test needs to control
precisely, and widget tests for the two screens with materially changed
conditional rendering (`OutOfLivesDialog`'s two-vs-three-button layout,
`PowerUpDock`'s two-vs-three-tile row). See Phase 5 above for the exact
test list.

## Edge cases & error handling

- **Ad fails to load when the player first goes out of lives.** `HeartAdCubit`
  starts in `HeartAdLoading` and moves to `HeartAdFailed` directly (never
  reaches `HeartAdReady`) — the dialog's "Watch ad" button must render a
  disabled/failed state correctly from this path too, not only from a
  failure *after* a successful load. Covered in Phase 5's test list.
- **Player backgrounds the app mid-ad, then returns.** Out of scope for this
  plan to handle specially — `google_mobile_ads`'s `RewardedAd.show()`
  already resolves via `onAdDismissedFullScreenContent` regardless of how
  the ad's fullscreen view was dismissed (including by the OS backgrounding
  the app), so the existing `FullScreenContentCallback` wiring handles this
  correctly with no extra code.
- **Player uses 50:50 then quits mid-level and restarts the same level.**
  `startLevel` always re-grants a fresh `PowerUpInventory(fiftyFifty: 1,
  addTime: 1)`, so a restart (via `onRestart` in `quiz_play_screen.dart`,
  which calls `context.pushReplacement(AppRoutes.quizPlayPath(...))`,
  re-invoking `QuizPlayCubit.startLevel`) correctly resets both power-ups —
  no special-casing needed, this falls out of the existing restart flow.
- **A player with zero of both power-ups reaches a question — dock still
  renders, just fully dimmed.** Matches today's existing zero-count visual
  (40% opacity per `power_up_tile.dart`'s doc comment) minus the tap
  affordance that used to open the Shop.
- **`grantHeartFromAd()` called when not in `QuizPlayOutOfLives`.** Guarded
  by the existing `if (current is! QuizPlayOutOfLives) return;` pattern this
  Cubit already uses everywhere else — no new failure mode introduced.

## Acceptance criteria

- [ ] `AppRoutes.shop`/`AppRoutes.rewardedAd` no longer exist; navigating to
      `/shop` or `/shop/rewarded-ad` is a 404/unknown-route, not a screen.
- [ ] No file in `lib/` imports anything from `features/shop/` (deleted).
- [ ] Starting any level shows exactly two power-up tiles (50:50, +5s) in
      the level brief and in the play surface's dock — no Skip tile, no
      "➕ Shop" tile.
- [ ] Using 50:50 (or +5s) once in a level leaves it at zero for the rest of
      that level, across multiple questions — not reset on the next
      question.
- [ ] The +5s power-up adds exactly 5 seconds to the clock, not 15.
- [ ] Restarting a level (after quitting or finishing) grants a fresh one of
      each power-up again.
- [ ] Hitting zero hearts mid-level shows a dialog with exactly two
      actions: "Watch an ad for 1 ❤️" and "Back to level map" — no refill
      button, no coin cost shown anywhere in the dialog.
- [ ] The out-of-lives dialog's body text makes no claim about hearts
      regenerating on a timer.
- [ ] Tapping "Watch an ad for 1 ❤️" triggers a real AdMob rewarded ad
      (Google's public test rewarded ad unit, backed by the test App IDs
      already configured) on both Android and iOS — not a `Timer`-based
      mock — and completing it grants exactly one heart and resumes the run.
- [ ] A failed ad load/show leaves the "Watch ad" button recoverable via a
      visible retry path, never permanently disabled.
- [ ] `dart analyze` reports zero warnings; `flutter test` passes in full.

## Risks & rollout notes

- **This is a real ad SDK integration for the first time in this app** —
  unlike every other "mocked" system flagged in `MOCKED_FEATURES.md`, a bug
  here surfaces as an actual AdMob network call failing, not a fixture
  glitch. Test on real Android and iOS devices/simulators before considering
  this done, per this project's CLAUDE.md §UI-testing convention ("start the
  dev server and use the feature... before reporting complete" — the mobile
  equivalent is running the app on both platforms, not just `flutter test`).
- **iOS ATT prompt timing**: adding `NSUserTrackingUsageDescription` means
  iOS *may* show the system tracking-permission prompt around the time ads
  first load, depending on `google_mobile_ads`'s internal ATT-handling
  version behavior. Confirm this doesn't surprise-prompt the player at an
  odd moment (e.g., mid-countdown) — if it does, the fix is requesting ATT
  explicitly and earlier (e.g., on first Home load) rather than leaving it
  to the ad SDK's default timing, but that's a follow-up if observed, not
  pre-emptively built here.
- **No staged rollout mechanism exists in this app** (no feature flags
  system found) — this ships as a single release. Given it deletes a whole
  feature (Shop) and changes a core gameplay loop (power-ups, hearts), this
  is the kind of change worth a manual pre-release smoke test of every
  level-start/level-fail/level-restart path, not just the new/changed unit
  tests.
