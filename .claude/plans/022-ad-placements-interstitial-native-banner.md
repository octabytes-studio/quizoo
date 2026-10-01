# Ad Placements — Interstitial, Native & Banner (AdMob)

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-10-01): "Optimised placements of interstitial, native and banner ads
> (different sizes) … not annoying for the users … enough ads … generous
> revenue … use of AdMob should be optimal."
> Status: Implemented 2026-10-01 (Flutter side). Owner console checklist and real AdMob ids still open.

## How to use this plan

This plan is self-contained: executing it needs no prior conversation. Read it
in full before you start. It was written against `main` @ `0961774`. Code may
have moved on since, so spot-check the files and symbols it references before
changing anything. **There is no database migration** — everything is
Flutter-side plus AdMob / Firebase console configuration that only the owner
can do (listed under "Risks & rollout notes").

`CLAUDE.md` §13 applies: never run the app to verify. Static checks and tests
only; finish with a "To verify:" list for the developer.

## Objective

Quizoo earns ad revenue today from exactly one place: a rewarded ad on the
out-of-lives dialog. This plan adds the three passive/interruptive formats the
owner asked for — **interstitial**, **native** and **banner (two sizes)** — at
the points in the app's real flows where they earn the most without getting in
the player's way. It also adds what AdMob needs for those ads to fill and pay
properly: consent (UMP), preloading, frequency pacing, per-placement ad units,
and remote kill switches so pacing can be tuned without a release.

The governing rule is **ads appear only at natural pauses and never on the
play surface**. Every placement below was chosen from the actual screen code,
and every screen that was rejected is listed with the reason.

## Scope

**In scope:**
- A shared ads layer in `lib/core/ads/` (services behind seams, config,
  pacing, placement ids, ad unit ids) and an app-root `AdsCubit`.
- Four shared ad widgets in `lib/core/widgets/`: anchored adaptive banner,
  300×250 medium rectangle, small native tile, medium native card.
- **Interstitial** at three "run finished, player is leaving" break points
  (level complete, duel result, daily result), paced and capped.
- **Banner (anchored adaptive)** on Level Map, Category Detail, Stats,
  Achievements.
- **Banner (medium rectangle 300×250)** on the Daily tab.
- **Native (small template)** in the Home feed, the Ranks roster, and the
  Level Complete and Duel Result bodies.
- **Native (medium template)** on the Daily Result body.
- UMP consent gathering at launch, plus an "Ad privacy choices" entry in
  Privacy settings when Google requires one.
- Remote Config keys (with in-app defaults) for every pacing number and a
  per-placement kill switch.
- Moving the existing rewarded ad's unit id into the shared id table and
  making it share the full-screen cooldown.
- Unit, bloc and widget tests per `CLAUDE.md` §11; test-harness updates so
  existing screen tests keep passing.

**Out of scope:**
- App-open ads (not requested; also collides with Splash's ≤1.2 s contract).
- Rewarded-interstitial ads, mediation / bidding networks.
- A "Remove ads" purchase (the Shop was deleted by plan 013). `AdsCubit` is
  the single switch a future IAP would flip.
- Server-side reward verification, custom analytics events.
- Replacing the **test** AdMob App IDs / ad unit IDs with real ones — the
  real values come from the owner's AdMob account (see Open questions). The
  code is structured so that is a constants-only change.
- Any ad on the play surface, on celebration screens, or on Level Failed.

## Research findings

### What exists today

- `pubspec.yaml`: `google_mobile_ads: ^9.1.0` (9.1.0 resolved),
  `firebase_remote_config`, `firebase_analytics`, `shared_preferences`,
  `flutter_bloc`, `freezed`. **No new package is needed.** The UMP consent
  API (`ConsentInformation`, `ConsentForm.loadAndShowConsentFormIfRequired`,
  `ConsentForm.showPrivacyOptionsForm`, `canRequestAds()`,
  `getPrivacyOptionsRequirementStatus()`) and native templates
  (`NativeTemplateStyle`, `TemplateType.small|medium`) ship inside it.
- `lib/main.dart:21` awaits `MobileAds.instance.initialize()` as the first
  thing after binding init — before any consent, and blocking startup.
  Remote Config defaults are set at `lib/main.dart:81-89`;
  `fetchAndActivate()` is un-awaited (`:90`).
- The only ad code: `lib/features/quiz_play/data/rewarded_ad_service.dart`
  (abstract seam), `admob_rewarded_ad_service.dart` (hardcoded Google test
  unit ids via `dart:io` `Platform`), `presentation/bloc/heart_ad_cubit.dart`
  + `heart_ad_state.dart` (sealed states), used by
  `presentation/widgets/out_of_lives_dialog.dart` and created at
  `quiz_play_screen.dart:298-300`. Test: `test/features/quiz_play/
  heart_ad_cubit_test.dart` uses a **completer-backed fake** of the seam, not
  a mocktail mock. **Mirror this seam + fake pattern for every new ad
  service.**
- Native config already present: `ios/Runner/Info.plist`
  (`GADApplicationIdentifier` = Google **test** id,
  `NSUserTrackingUsageDescription`, a `SKAdNetworkItems` list);
  `android/app/src/main/AndroidManifest.xml:52-54` (`APPLICATION_ID` = Google
  **test** id). Android `minSdk` 23, iOS deployment target 15.0.
- App-wide Cubits live in `lib/app/` as `<name>_cubit.dart` +
  `<name>_state.dart` (`connectivity_cubit.dart`, `theme_cubit.dart`, …) and
  are provided in `lib/app/app.dart:160-169`. Session-lifetime services are
  `RepositoryProvider`s at `app.dart:139-159`. `QuizooApp` takes an optional
  `router` for tests.
- Shared cross-feature widgets live in `lib/core/widgets/`
  (`result_wash.dart`, `list_row_tile.dart`, …). Colours come from
  `context.quizoo` (`s0 s1 s2 s3 tx tx2 tx3 ln p …`), spacing from
  `AppSpacing` (`xs 4, sm 8, md 12, base 16, lg 20, xl 24, xxl 32,
  screenMargin`), radii from `AppRadius` (`card 20`, `listRow 16`).
- Tests: `test/support/pump_app.dart` (theme + ScreenUtil + l10n at 390×844)
  and `test/support/pump_screen.dart` (adds the app-root providers and a
  catch-all router). Fakes for API classes are `class FakeX extends Mock
  implements X {}`. Several whole-app tests pump `QuizooApp` directly
  (`test/app/app_test.dart`, `router_test.dart`, `localization_test.dart`,
  `test/integration/core_loop_test.dart`).
- l10n: `lib/l10n/app_en.arb` (template) and `app_ur.arb`; generated
  `app_localizations*.dart` are committed; `untranslated_messages.json`
  tracks Urdu gaps.

### The app's flows (where pauses really are)

```
Splash (≤1.2 s) → [first launch: Onboarding → Language] → Shell
Shell tabs: Home · Ranks · (FAB → Duel Arena) · Daily · You

Solo loop:  Home / Search / Category Detail → Level Map → Level Brief sheet
            → Countdown → Questions → [Out of lives dialog: rewarded ad]
            → Level Complete | Level Failed
            → (Topic Mastered → Badge Unlocked×n → Save-progress sheet)
            → Next level | Replay | back to Level Map
Daily loop: Daily tab → Daily play (same arena) → Daily Result → Daily tab
Duel loop:  Arena → Matchmaking → Live duel | Bot duel → Duel Result
            → Rematch | Find new opponent | close
```

Facts that drive the placement decisions:

- A level is 10 / 15 / 20 questions at 20 / 15 / 10 s each (ladder tiers in
  `test/support/pump_screen.dart:160-185`, mirroring live config), so a level
  lasts roughly 1.5–3.5 minutes. One interstitial per level would be far too
  often; one every second finished run lands at about one per 4–6 minutes of
  play.
- `LevelCompleteScreen` (`lib/features/quiz_result/presentation/screens/
  level_complete_screen.dart`) runs a 2.6 s payout, then a chain of pushes
  (mastery, badges, save-progress). Its exits are all explicit buttons:
  "Next level" / "Replay" (`context.pushReplacement(AppRoutes.countdownPath
  (...))`, lines 126-156), "Back to map" and ✕ (`_close`, line 102). The game
  clock only starts inside the pushed play route, so an ad shown **before**
  the push costs the player nothing.
- `LevelFailedScreen`'s own doc comment (`level_failed_screen.dart:21-22`):
  "**No ad and no offer, of any kind.** This screen never sells anything."
- The Level Map (`catalog/presentation/screens/level_map_screen.dart`) is the
  hub the player returns to between every level; it reloads itself on
  `didPopNext` (lines 116-124), going `Loading → Loaded` again.
- Live duels are server-refereed and clock-synced; a rematch handshake has a
  server-side window (`duel_result_screen.dart:104-137`). **Nothing
  full-screen may be shown on the way into a live duel or a live rematch.**
- Home (`home/presentation/screens/home_screen.dart:462-478`) is a
  `ListView.builder` of leading rows + category sections — a natural feed.
- Ranks (`leaderboard_screen.dart:188-207`) renders podium + a `Column` of
  rows, with a pinned self row and the tab bar beneath.
- The tab bar's centre FAB overhangs the bar by 24 (`app_tab_bar.dart:34-37`),
  so a persistent banner directly above the tab bar would sit against
  navigation controls.
- Result screens share `core/widgets/result_wash.dart`: a scrolling body and
  a separate pinned action column — the body can hold an ad without touching
  the buttons.

### Rules from the design bible (`.claude/docs/quizoo-design-bible.html`)

- Anti-pillar: "No interstitial ad between every question." "No dark-pattern
  purchase prompts on a loss screen."
- S-22: "We never show an ad or an offer on this screen."
- §22 package table: "Ads / IAP — `google_mobile_ads`, `in_app_purchase` —
  **Rewarded only**; validate server-side." (Conflicts with this spec — see
  Assumption 1.)
- Performance budget forbids `BackdropFilter` on the play surface; the arena
  is deliberately invariant.

### `CLAUDE.md` rules that shape the design

- §1/§3: decisions live in Cubits; Cubits are pure Dart with constructor-
  injected dependencies; sealed states; exhaustive `switch`; no `setState`
  for network-backed data; navigation never inside a `BlocBuilder` builder.
- §2: code reused by 3+ features goes in `core/`; shared widgets in
  `core/widgets/`; one public class per file.
- §3: app-root `BlocProvider` only for genuinely app-wide state.
- §5/§6: tokens only; `flutter_screenutil` for sizing; no
  `MediaQuery.of(context).size`; `LayoutBuilder` for layout maths.
- §8: package imports across features/core; `dart format`; zero analyzer
  warnings; no `// ignore:`.
- §10: shared files (`app/router.dart`, `core/theme/*`) are added to, not
  restructured. This plan does not touch the router or theme files.
- §11: `bloc_test` for every Cubit (initial + success + failure); repository
  tests with mocktail; widget tests per state branch.

## Assumptions & open questions

**Assumptions**

1. **The spec overrides the bible's "Rewarded only".** The owner explicitly
   asked for interstitial, native and banner ads, so that line of §22 is
   treated as superseded. The bible's *behavioural* rules are kept in full:
   no ad of any kind on the play surface, none on Level Failed, none on
   celebration screens.
2. **Editing several features' screens is allowed here.** `CLAUDE.md` §10
   says a new feature must not modify another feature's files. This task *is*
   "place ads in existing screens", so each placement is a small additive
   edit in that feature's own `presentation/` file; all shared logic lives in
   `core/`. No feature imports another feature.
3. **Ad containers use unscaled dp, not `.w`/`.h`.** AdMob sizes are fixed by
   the SDK (300×250, the adaptive banner's computed height, native template
   minimums). Scaling them with screenutil would clip or letterbox the
   platform view. The constants live in one file (`core/ads/ad_dimensions
   .dart`) with a comment saying why; padding *around* ads still uses
   `AppSpacing` + screenutil. This is a stated exception to §6.
4. **Adaptive banner width comes from `LayoutBuilder`**, not the
   `MediaQuery` call Google's sample uses (§6).
5. **The slot Cubit lives in `core/ads/`.** `core/` has no Cubit today; the
   per-slot `InlineAdCubit` is shared by seven features, so it cannot live in
   one of them. `AdsCubit` follows the existing `lib/app/*_cubit.dart`
   convention.
6. **Ad unit ids are code constants in one file, not `--dart-define`s**
   (owner decision, 2026-10-01). Every ad unit id for every ad type lives in
   `lib/core/ads/ad_unit_ids.dart` — **already created** — and every ad
   class reads its id from there; no other file may contain an ad unit id.
   The file currently holds Google's public test ids for all formats; the
   owner will replace the constants with real ids later. There is no
   debug/release switching and no "empty id" state.
7. **Native ads use `NativeTemplateStyle`** (Dart-only) rather than custom
   `NativeAdFactory` classes in Kotlin/Swift — no native code to maintain,
   and colours still come from the app's tokens.
8. **Remote Config values are read once at ads start-up.** Because
   `fetchAndActivate()` is un-awaited, a console change takes effect on the
   launch after it is fetched. That is acceptable for pacing knobs.
9. **`DuelResultScreen._close` on a live result may show an interstitial**
   because the player is leaving; rematch paths never do.

**Open questions (need the owner)**

1. **Real AdMob ids.** Two App IDs (iOS, Android) and twelve ad unit ids (six
   per platform, table under "Data model / API changes"). Until supplied, the
   app keeps running on Google's test ids — safe to develop against, earns
   nothing. Must be resolved before release.
2. **Audience and ad content rating.** The catalogue includes an Islam
   category and Urdu/Hindi content. Recommended: max ad content rating **PG**
   in code (Step 2.3) and, in the AdMob console, block the sensitive
   categories (gambling, dating, alcohol, and similar). If the store listing
   targets children under 13 at all, Families-policy settings are also
   required — the owner must confirm the target age band.
3. **Result-screen native ad.** Recommended on (it is the one screen every
   run passes through), but it sits under a celebration. It has its own kill
   switch (`level_complete_native`); confirm the default should be on.
4. **Interstitial after a failed level.** Deliberately off, per the bible.
   Failed runs neither show an ad nor count toward the next one. Revisit only
   if revenue data argues for it.
5. **A developer website for `app-ads.txt`** (see rollout notes).

## Design overview

### Placement map

| # | Screen (file) | Format | Where exactly | Why here |
|---|---|---|---|---|
| I1 | Level Complete (`quiz_result/.../level_complete_screen.dart`) | Interstitial | After the player taps Next level / Replay / Back to map / ✕, before navigating | The textbook "between levels" break; clock has not started |
| I2 | Duel Result (`duel/.../duel_result_screen.dart`) | Interstitial | On ✕ and on "Find new opponent" (after the topic is known, before pushing matchmaking) | Match is over; nothing is time-critical yet |
| I3 | Daily Result (`daily/.../daily_result_screen.dart`) | Interstitial | On ✕ / "Back to daily" | Once a day, run is over |
| B1 | Level Map (`catalog/.../level_map_screen.dart`) | Anchored adaptive banner | Bottom edge, under the Play button, height reserved from first frame | Most-revisited screen in the solo loop |
| B2 | Category Detail (`catalog/.../category_detail_screen.dart`) | Anchored adaptive banner | Bottom edge | Browsing screen, long dwell, no bottom controls |
| B3 | Stats (`profile/.../stats_screen.dart`) | Anchored adaptive banner | Bottom edge | Reading screen, no bottom controls |
| B4 | Achievements (`achievements/.../achievements_screen.dart`) | Anchored adaptive banner | Bottom edge | Same |
| M1 | Daily tab (`daily/.../daily_screen.dart`) | Medium rectangle 300×250 | In the list, after the streak card, before Milestones | Visited daily; static content with dwell; MREC pays best of the banner sizes |
| N1 | Home (`home/.../home_screen.dart`) | Native small | A feed row after the 2nd category section, then every 5 sections, max 2 | Feed-shaped screen; native blends with the section rhythm |
| N2 | Ranks (`leaderboard/.../leaderboard_screen.dart`) | Native small | A row after the 5th non-podium row | List-shaped; away from the pinned self row and tab bar |
| N3 | Level Complete | Native small | In the scroll body under `ScoreBreakdownCard` | Every completed run passes through; separated from the pinned buttons |
| N4 | Duel Result | Native small | In the scroll body under the stats card | Same |
| N5 | Daily Result | Native medium | In the scroll body under the distribution card | Longest dwell of the result screens (chart, share) |

That is 3 interstitial break points, 4 adaptive banners, 1 medium rectangle
and 5 native slots — two banner sizes and two native sizes.

**Deliberately ad-free** (do not add ads here, even later, without a new
decision):

| Screen | Reason |
|---|---|
| Countdown, questions, feedback, pause sheet, quit dialog | Bible anti-pillar; timed input; accidental-click risk |
| Out-of-lives dialog | Already has the opt-in rewarded ad; nothing else |
| Level Failed | Bible: never an ad or offer |
| Topic Mastered, Badge Unlocked, League Promotion | Celebration moments |
| Level Brief sheet | Ad would sit next to "Start" during a short prefetch wait |
| Duel Arena, Matchmaking, Live/Bot duel | Real-time, clock-synced, invariant arena surface |
| Splash, Onboarding, Language picker, Profile creation, Save-progress sheet | First impressions / forms; policy discourages ads on non-content screens |
| Settings and its sub-screens, Delete account, Force update, Notification permission | Utility / dead-end screens |
| Search | Keyboard covers the lower half; results are transient |
| Shell-wide banner above the tab bar | Would sit against the overhanging FAB and tab targets |
| Profile (You tab), Friends, Category leaderboard, Edit profile | Identity / social / has a bottom CTA; revisit as "phase 2" candidates once data exists |
| Any loading, error, empty or offline state | Policy: ads only next to real content |

### Interstitial pacing (the "not annoying" contract)

All numbers are Remote Config keys with these defaults:

- **Grace:** the first 2 eligible breaks after install never show one.
- **Cadence:** then at most one every 2 eligible breaks.
- **Cooldown:** at least 120 s since the last full-screen ad of any kind —
  the rewarded heart ad counts.
- **Session cap:** at most 8 per app process.
- **Celebration skip:** a break is not eligible if the run just unlocked
  mastery, earned a badge, or is about to offer the save-progress sheet. The
  break still counts toward cadence.
- **Never wait:** if no ad is loaded at the break, navigation proceeds
  instantly and the break stays "owed" to the next one.
- **Never on system back.** Only on the explicit buttons listed in I1–I3.
- One interstitial is preloaded after consent, reloaded after each show, and
  discarded/reloaded if older than 55 minutes (AdMob expires them at 1 hour).

Set a matching frequency cap on the interstitial ad unit in the AdMob console
as a server-side backstop (rollout notes).

### Architecture

```
lib/app/
  ads_cubit.dart, ads_state.dart          app-root: consent/init + pacing
lib/core/ads/
  ad_placement.dart                       enum of placement ids + format
  ad_unit_ids.dart                        test/real ids per platform
  ad_dimensions.dart                      unscaled SDK sizes (Assumption 3)
  ads_config.dart                         freezed AdsConfig (domain model)
  ads_config_api.dart                     thin wrapper over FirebaseRemoteConfig
  ads_config_repository.dart              api → AdsConfig, with safe defaults
  ads_pacing_store.dart                   SharedPreferences: lifetime break count
  interstitial_pacer.dart                 pure-Dart decision logic
  ad_consent_service.dart                 abstract seam
  ump_ad_consent_service.dart             UMP implementation
  interstitial_ad_service.dart            abstract seam
  admob_interstitial_ad_service.dart      AdMob implementation
  inline_ad_service.dart                  abstract seam + LoadedInlineAd + InlineAdRequest
  admob_inline_ad_service.dart            banner/native loading
  inline_ad_cubit.dart, inline_ad_state.dart   one per mounted slot
  inline_ad_layout.dart                   pure helper: where feed ads go
lib/core/widgets/
  inline_ad_slot.dart                     shared host (provider + switch + frame)
  inline_ad_view.dart                     LoadedInlineAd → AdWidget
  anchored_banner_ad.dart                 AnchoredBannerAd
  medium_rectangle_ad.dart                MediumRectangleAd
  native_ad_tile.dart                     NativeAdTile  (small template)
  native_ad_card.dart                     NativeAdCard  (medium template)
```

Flow of control:

- **`AdsCubit`** (app root — every tab and seven features read it, so it
  meets §3's bar the same way `ConnectivityCubit` does). States:
  `AdsInitial` → `AdsReady(config, privacyOptionsRequired)` or
  `AdsDisabled`. `initialize()` gathers consent, initialises the SDK, reads
  config, preloads the interstitial; it **never throws** (any failure,
  unsupported platform, or `ads_enabled=false` → `AdsDisabled`).
  `showInterstitialIfDue(placement, {isCelebration})` asks the pacer, shows,
  and completes when the ad is dismissed (or immediately if nothing shows).
  `noteFullScreenAdShown()` lets the rewarded heart ad feed the cooldown.
  `isPlacementEnabled(placement)` is what the slot widgets select on.
- **`InterstitialPacer`** holds the counters and answers one question —
  pure Dart, injected clock, fully unit-tested.
- **`InlineAdCubit`** (one per mounted slot, created by the slot widget's
  own `BlocProvider`, per §3 "as close as possible"). States:
  `InlineAdLoading(reservedHeight)`, `InlineAdLoaded(ad)`,
  `InlineAdUnavailable(reservedHeight)`. Disposes the SDK ad in `close()`.
- **Slot widgets** are composition only: read `AdsCubit`, and if the
  placement is on, host an `InlineAdCubit` and `switch` over its state.

### Layout-stability rules (protect against accidental clicks)

- **Anchored banners reserve their height from the first frame** once the
  adaptive size is known, and keep it if the load fails. The Level Map's
  Play button must never move because an ad arrived.
- **In-content slots** (MREC, native) reserve their known height while
  loading and collapse to zero (with `AnimatedSize`,
  `AppMotion.durationOf`) only if the load fails.
- Every slot keeps at least `AppSpacing.md` between the ad and any tappable
  control, and anchored banners draw a 1 px `quizoo.ln` top hairline on a
  `quizoo.s1` strip so the ad is visibly separate from app chrome.
- MREC and native slots carry a small "Advertisement" label
  (`textTheme.labelSmall`, `quizoo.tx3`) above the ad. (Native templates
  also render Google's own "Ad" badge and AdChoices icon — do not cover
  them.)

## Implementation steps

### Phase 1 — Core ads layer (no UI yet)

- [x] **1.1 `lib/core/ads/ad_placement.dart`.** An enhanced enum
      `AdPlacement` with a stable string `id` (used by the Remote Config kill
      list) and an `AdFormat` (`interstitial`, `anchoredBanner`,
      `mediumRectangle`, `nativeSmall`, `nativeMedium`). Values and ids:
      `levelCompleteBreak('level_complete_break')`,
      `duelResultBreak('duel_result_break')`,
      `dailyResultBreak('daily_result_break')`,
      `levelMapBanner('level_map_banner')`,
      `categoryDetailBanner('category_detail_banner')`,
      `statsBanner('stats_banner')`,
      `achievementsBanner('achievements_banner')`,
      `dailyTabRectangle('daily_tab_rectangle')`,
      `homeFeedNative('home_feed_native')`,
      `ranksFeedNative('ranks_feed_native')`,
      `levelCompleteNative('level_complete_native')`,
      `duelResultNative('duel_result_native')`,
      `dailyResultNative('daily_result_native')`.
- [x] **1.2 `lib/core/ads/ad_unit_ids.dart` — DONE (2026-10-01).** The
      single home of every ad unit id. `abstract final class AdUnitIds` with
      one platform-switched getter per ad unit (`defaultTargetPlatform`, not
      `dart:io`): `anchoredBanner`, `rectangleBanner`, `interstitial`,
      `nativeFeed`, `nativeResult`, `rewardedHeart`. All twelve constants are
      Google's public test ids, checked against Google's "Enable test ads"
      pages on 2026-10-01:

      | Getter | Android test id | iOS test id |
      |---|---|---|
      | `anchoredBanner` | `ca-app-pub-3940256099942544/9214589741` | `…/2435281174` |
      | `rectangleBanner` | `…/6300978111` | `…/2934735716` |
      | `interstitial` | `…/1033173712` | `…/4411468910` |
      | `nativeFeed`, `nativeResult` | `…/2247696110` | `…/3986624511` |
      | `rewardedHeart` | `…/5224354917` | `…/1712485313` |

      **Rule for the rest of this plan:** each ad class takes its id from
      this file and nowhere else — `AdMobInterstitialAdService` uses
      `AdUnitIds.interstitial`; `AdMobInlineAdService` uses `anchoredBanner`
      for `AnchoredBannerRequest`, `rectangleBanner` for
      `RectangleBannerRequest`, and for `NativeAdRequest` `nativeFeed`
      (Home, Ranks) or `nativeResult` (the three result screens), chosen by
      an exhaustive `switch` on `request.placement`. Do not add
      debug/release branching or nullable ids. Going live is the owner
      editing these constants (Open question 1).
- [x] **1.3 `lib/core/ads/ad_dimensions.dart`.** Unscaled constants:
      `rectangleWidth 300`, `rectangleHeight 250`, `nativeSmallHeight 100`,
      `nativeMediumHeight 340`, `nativeMaxWidth 400`. Doc comment: SDK-defined
      dp, deliberately not screenutil-scaled (Assumption 3). The two native
      heights must satisfy Google's template minimums (small ≥ 90 high,
      medium ≥ 320 high, both ≥ 320 wide) — re-check against the installed
      package's native-template docs.
- [x] **1.4 `lib/core/ads/ads_config.dart`** — `@freezed AdsConfig` with
      defaults: `enabled true`, `disabledPlacements <String>{}`,
      `interstitialGraceBreaks 2`, `interstitialEveryNBreaks 2`,
      `interstitialMinGapSeconds 120`, `interstitialSessionCap 8`,
      `homeNativeFirstSection 2`, `homeNativeEverySections 5`,
      `homeNativeMax 2`, `ranksNativeAfterRow 5`. No `fromJson` needed.
      Run `dart run build_runner build --delete-conflicting-outputs`.
- [x] **1.5 `lib/core/ads/ads_config_api.dart`** — `AdsConfigApi(
      FirebaseRemoteConfig)` exposing `bool getBool(String)`,
      `int getInt(String)`, `String getString(String)`. Nothing else touches
      Remote Config for ads.
      **`ads_config_repository.dart`** — `AdsConfigRepository(AdsConfigApi)`
      with `AdsConfig read()`: maps the keys in "Data model / API changes",
      clamps nonsense (negative numbers, `everyN < 1` → default), splits
      `ads_disabled_placements` on commas, and returns `const AdsConfig()` if
      the api throws.
- [x] **1.6 `lib/core/ads/ads_pacing_store.dart`** — `AdsPacingStore(
      SharedPreferences)`: `int get lifetimeBreaks` /
      `void recordBreak()` on key `ads.lifetimeBreaks` (same style as
      `SettingsRepository`).
- [x] **1.7 `lib/core/ads/interstitial_pacer.dart`** — pure Dart:

      ```dart
      class InterstitialPacer {
        InterstitialPacer(this._store, {DateTime Function()? now});
        /// Records one eligible break and says whether to show now.
        bool registerBreak(AdsConfig config, {required bool isCelebration,
                                              required bool isAdReady});
        void noteFullScreenAdShown();   // interstitial or rewarded
      }
      ```

      Logic, in order: record the break in the store; return false if
      lifetime breaks ≤ grace; increment `breaksSinceLastShown`; return false
      if celebration, if `breaksSinceLastShown < everyN`, if the session
      count has hit the cap, if the last full-screen ad was under
      `minGapSeconds` ago, or if `!isAdReady`. Only `noteFullScreenAdShown()`
      resets `breaksSinceLastShown` and stamps the time — so a skipped break
      stays owed.
- [x] **1.8 Consent seam.** `ad_consent_service.dart`:

      ```dart
      abstract class AdConsentService {
        /// Updates consent info and shows Google's form if one is required.
        /// Returns whether ads may be requested. Never throws.
        Future<bool> gather();
        Future<bool> isPrivacyOptionsRequired();
        /// Re-opens Google's privacy options form. Never throws.
        Future<void> showPrivacyOptions();
      }
      ```

      `ump_ad_consent_service.dart`: `ConsentInformation.instance
      .requestConsentInfoUpdate(ConsentRequestParameters(), onSuccess,
      onFailure)` wrapped in a `Completer`; on success
      `ConsentForm.loadAndShowConsentFormIfRequired(...)`; then
      `canRequestAds()`. On an update failure fall back to `canRequestAds()`
      (consent from a previous session still counts). Verify exact callback
      signatures in `google_mobile_ads-9.1.0/lib/src/ump/`.
- [x] **1.9 Interstitial seam.** `interstitial_ad_service.dart`:
      `Future<void> preload()`, `bool get isReady` (false when missing or
      older than 55 min), `Future<bool> show()` (completes when dismissed;
      false if it failed to show), `Future<void> dispose()`.
      `admob_interstitial_ad_service.dart` mirrors
      `AdMobRewardedAdService`'s completer structure with
      `InterstitialAd.load` + `FullScreenContentCallback`; ignores a second
      `preload()` while one is in flight; after dismissal or show-failure it
      disposes the ad and calls `preload()` again. Before showing, call
      `MobileAds.instance.setAppMuted(...)` from a `bool Function() isMuted`
      constructor argument so the app's sound toggle is respected.
- [x] **1.10 Inline seam.** `inline_ad_service.dart`:

      ```dart
      abstract class LoadedInlineAd {
        double get height;      // dp
        double get width;       // dp
        void dispose();
      }

      sealed class InlineAdRequest { AdPlacement get placement; }
      final class AnchoredBannerRequest extends InlineAdRequest { int widthDp; }
      final class RectangleBannerRequest extends InlineAdRequest {}
      final class NativeAdRequest extends InlineAdRequest {
        NativeAdSize size;          // small | medium
        NativeAdPalette palette;    // background, text, secondaryText,
      }                             // ctaBackground, ctaText (dart:ui Color)

      abstract class InlineAdService {
        /// Height to reserve before the ad loads; null if it can't be sized.
        Future<double?> reservedHeight(InlineAdRequest request);
        /// Null when the load fails.
        Future<LoadedInlineAd?> load(InlineAdRequest request);
      }
      ```

      `admob_inline_ad_service.dart`: `AdMobLoadedInlineAd implements
      LoadedInlineAd` and exposes `AdWithView ad`. Anchored: resolve the
      adaptive size for `widthDp` (the 9.1.0 source marks
      `AdSize.getAnchoredAdaptiveBannerAdSize` `@Deprecated` in favour of
      `getLargeAnchoredAdaptiveBannerAdSizeWithOrientation` — use whichever
      non-deprecated call the installed package exposes), then
      `BannerAd(size:, adUnitId:, request: const AdRequest(), listener:)
      .load()`. Rectangle: `AdSize.mediumRectangle`. Native: `NativeAd(
      adUnitId:, request:, listener:, nativeTemplateStyle:
      NativeTemplateStyle(templateType: small|medium, mainBackgroundColor:,
      cornerRadius: AppRadius.listRow, callToActionTextStyle:,
      primaryTextStyle:, secondaryTextStyle:, tertiaryTextStyle:))`. Always
      dispose the SDK ad in `onAdFailedToLoad`.
- [x] **1.11 `inline_ad_cubit.dart` + `inline_ad_state.dart`** —
      `InlineAdCubit(InlineAdService)`; initial state
      `InlineAdLoading(reservedHeight: 0)`; `load(request)` emits
      `InlineAdLoading(reservedHeight)` then `InlineAdLoaded(ad)` or
      `InlineAdUnavailable(reservedHeight)`; guards `isClosed` after each
      await and disposes an ad that arrives after close;
      `refreshIfStale()` reloads when the loaded ad is over 55 min old;
      `close()` disposes the ad. States are a `sealed class` with `Equatable`
      like `HeartAdState`.
- [x] **1.12 `inline_ad_layout.dart`** — pure function:

      ```dart
      /// Feed rows for [itemCount] content items with ads interleaved:
      /// each entry is a content index, or null for an ad row.
      List<int?> interleaveAdRows({required int itemCount,
        required int firstAfter, required int every, required int max});
      ```

      No ad row after the last content item; `max <= 0` or
      `itemCount <= firstAfter` → content only.
- [x] **1.13 `lib/app/ads_state.dart` + `ads_cubit.dart`.**

      ```dart
      sealed class AdsState extends Equatable {}
      final class AdsInitial extends AdsState {}
      final class AdsDisabled extends AdsState {}
      final class AdsReady extends AdsState {
        final AdsConfig config; final bool privacyOptionsRequired;
      }

      class AdsCubit extends Cubit<AdsState> {
        AdsCubit({required AdConsentService consent,
                  required AdsConfigRepository config,
                  required InterstitialAdService interstitial,
                  required InterstitialPacer pacer,
                  required Future<void> Function() initializeSdk,
                  required bool isSupportedPlatform});
        Future<void> initialize();
        bool isPlacementEnabled(AdPlacement placement);
        Future<void> showInterstitialIfDue(AdPlacement placement,
            {bool isCelebration = false});
        void noteFullScreenAdShown();
        Future<void> showPrivacyOptions();
      }
      ```

      `initialize()`: unsupported platform or `!config.enabled` →
      `AdsDisabled`; `consent.gather()` false → `AdsDisabled`; then
      `initializeSdk()` (sets `RequestConfiguration(maxAdContentRating:
      MaxAdContentRating.pg)` and calls `MobileAds.instance.initialize()`),
      `interstitial.preload()`, emit `AdsReady`. Whole body in try/catch →
      `AdsDisabled`. `isPlacementEnabled` is true only in `AdsReady` and when
      the id is not in `disabledPlacements`.
      `showInterstitialIfDue` returns immediately unless the placement is
      enabled and `pacer.registerBreak(...)` says yes; then
      `await interstitial.show()` and `pacer.noteFullScreenAdShown()`.

### Phase 2 — App wiring

- [x] **2.1 `lib/main.dart`.** Delete `await MobileAds.instance.initialize();`
      (line 21) and its import — the SDK is now initialised by `AdsCubit`
      after consent, off the startup path. Add the ads keys and defaults from
      "Data model / API changes" to the `setDefaults` map (lines 81-89).
- [x] **2.2 `lib/app/app.dart`.** Add an optional `AdsCubit? adsCubit`
      constructor parameter (tests inject one, exactly like `router`). In
      `_QuizooAppState` build the real graph as `late final` fields:
      `AdMobInlineAdService`, `AdMobInterstitialAdService(isMuted: () =>
      !_settingsRepository.current.soundOn)`, `UmpAdConsentService`,
      `AdsConfigRepository(AdsConfigApi(FirebaseRemoteConfig.instance))`,
      `InterstitialPacer(AdsPacingStore(widget.preferences))`, and the
      `AdsCubit` (`isSupportedPlatform: !kIsWeb && (android || iOS)`). Add
      `RepositoryProvider<InlineAdService>.value` to the repository list and
      `BlocProvider<AdsCubit>.value` to the bloc list. In `initState`, when no
      cubit was injected, `unawaited(_adsCubit.initialize())`. Close the
      cubit in `dispose` only if this state created it. Extend the class doc
      comment with why `AdsCubit` earns the root (same style as the existing
      paragraphs).
- [x] **2.3 Rewarded ad joins the shared layer.**
      **Already done (2026-10-01):**
      `features/quiz_play/data/admob_rewarded_ad_service.dart` now reads
      `AdUnitIds.rewardedHeart`; its private `_adUnitId` and `dart:io` import
      are gone. **Still to do:**
      `features/quiz_play/presentation/widgets/out_of_lives_dialog.dart`: in
      the existing listener, on `HeartAdPlaying` call
      `context.read<AdsCubit>().noteFullScreenAdShown()` so a player who just
      watched a rewarded ad is not shown an interstitial moments later.

### Phase 3 — Shared ad widgets (`lib/core/widgets/`)

- [x] **3.1 `inline_ad_view.dart`** — `InlineAdView({required LoadedInlineAd
      ad})`: a `SizedBox(width: ad.width, height: ad.height)` holding
      `AdWidget(ad: ad.ad)` when `ad is AdMobLoadedInlineAd`, otherwise an
      empty box of that size (what tests render).
- [x] **3.2 `inline_ad_slot.dart`** — `InlineAdSlot({required AdPlacement
      placement, required InlineAdRequest Function(BuildContext,
      BoxConstraints) requestBuilder, required bool keepsSpaceOnFailure,
      required Widget Function(BuildContext, Widget ad) frameBuilder})`.
      Build: `context.select<AdsCubit, bool>((c) =>
      c.isPlacementEnabled(placement))`; if false →
      `const SizedBox.shrink()`. Otherwise `LayoutBuilder` → `BlocProvider<
      InlineAdCubit>` keyed on `Theme.of(context).brightness` (so a theme
      switch reloads a correctly coloured native ad) with
      `create: InlineAdCubit(context.read<InlineAdService>())..load(...)` →
      `BlocBuilder` with an exhaustive `switch`: `InlineAdLoading(h)` →
      framed empty box of height `h`; `InlineAdLoaded(ad)` → framed
      `InlineAdView`; `InlineAdUnavailable(h)` → framed empty box if
      `keepsSpaceOnFailure`, else `SizedBox.shrink()`. Wrap in-content slots
      in `AnimatedSize` using `AppMotion.durationOf(context,
      AppMotion.slide)`. Add an `AppLifecycleListener(onResume: →
      cubit.refreshIfStale())` in a small private `State` (ephemeral
      plumbing, same justification as `_QuizPlayViewState`).
- [x] **3.3 `anchored_banner_ad.dart`** — `AnchoredBannerAd({required
      AdPlacement placement})`: `InlineAdSlot` with an
      `AnchoredBannerRequest(widthDp: constraints.maxWidth.truncate())`,
      `keepsSpaceOnFailure: true`, framed as a full-width `quizoo.s1` strip
      with a 1 px `quizoo.ln` top border, the ad centred, wrapped in
      `SafeArea(top: false)`. Designed for `Scaffold.bottomNavigationBar`.
- [x] **3.4 `medium_rectangle_ad.dart`** — `MediumRectangleAd`: centred
      300×250, `keepsSpaceOnFailure: false`, with the `l10n.adLabel` caption
      above it (`AppSpacing.xs.h` gap).
- [x] **3.5 `native_ad_tile.dart`** — `NativeAdTile` (small template):
      full available width capped at `AdDimensions.nativeMaxWidth`, height
      `nativeSmallHeight`, clipped to `AppRadius.listRow.r`, 1 px `quizoo.ln`
      border, caption above. Palette from tokens: background `quizoo.s1`,
      primary text `quizoo.tx`, secondary `quizoo.tx2`, CTA background
      `quizoo.p`, CTA text white.
- [x] **3.6 `native_ad_card.dart`** — `NativeAdCard` (medium template): same
      as 3.5 with `nativeMediumHeight` and `AppRadius.card.r`.
- [x] **3.7 l10n.** Add to `lib/l10n/app_en.arb` (with `@` descriptions) and
      `app_ur.arb`: `adLabel` = "Advertisement" / "اشتہار";
      `privacyAdChoices` = "Ad privacy choices" / "اشتہارات کی رازداری کے
      اختیارات". Run `flutter gen-l10n` and commit the regenerated files.

### Phase 4 — Banner and native placements

Every slot goes **inside the screen's Loaded branch** (or is gated on it), so
no ad renders beside a skeleton-only, error, empty or offline state.

- [x] **4.1 B1 Level Map** (`catalog/presentation/screens/
      level_map_screen.dart`, `_LevelMapViewState.build`, the `Scaffold` at
      line 130). Add `bottomNavigationBar: BlocBuilder<LevelMapCubit,
      LevelMapState>(buildWhen: …, builder: …)` returning
      `SizedBox.shrink()` for `LevelMapError` / `LevelMapEmpty` and
      `const AnchoredBannerAd(placement: AdPlacement.levelMapBanner)`
      otherwise. Keeping it mounted through `Initial/Loading/Loaded` matters:
      the `didPopNext` reload must not tear the banner down and request a new
      ad on every return. Use an exhaustive `switch` on the state.
- [x] **4.2 B2 Category Detail** (`category_detail_screen.dart`,
      `_CategoryDetailView`, `Scaffold` at line 60): same pattern, banner only
      for `CategoryDetailLoaded`, placement `categoryDetailBanner`.
- [x] **4.3 B3 Stats** (`profile/presentation/screens/stats_screen.dart`,
      `Scaffold` at line 47) and **B4 Achievements**
      (`achievements/presentation/screens/achievements_screen.dart`,
      `Scaffold` at line 76): `bottomNavigationBar` gated on `StatsLoaded` /
      `AchievementsLoaded`.
- [x] **4.4 M1 Daily tab** (`daily/presentation/screens/daily_screen.dart`,
      `_DailyContent`, lines 128-166): insert, after the `_StreakCard`
      padding block and before the `SizedBox` preceding the Milestones
      header, `SizedBox(height: AppSpacing.xl.h)` +
      `const MediumRectangleAd(placement: AdPlacement.dailyTabRectangle)`.
- [x] **4.5 N1 Home** (`home/presentation/screens/home_screen.dart`,
      `_HomeContentView.build`, lines 462-478). Read the three Home numbers
      with `context.select<AdsCubit, …>` (when the state is not `AdsReady`
      or `homeFeedNative` is disabled, use `max: 0`). Build
      `final rows = interleaveAdRows(itemCount: sections.length, …)` and set
      `itemCount: leading.length + rows.length`. In `itemBuilder`, a `null`
      row returns `Padding(horizontal: AppSpacing.screenMargin.w, top:
      AppSpacing.md.h, child: const NativeAdTile(placement:
      AdPlacement.homeFeedNative))`; otherwise build `_CategorySection` with
      `isFirst: contentIndex == 0` (it is currently derived from the list
      index — keep the meaning). Do not add an ad to `_HomeOfflineView`.
- [x] **4.6 N2 Ranks** (`leaderboard/presentation/screens/
      leaderboard_screen.dart`, `_LeaderboardRoster.build`, lines 196-205):
      when `rows.length > config.ranksNativeAfterRow`, insert a
      `NativeAdTile(placement: AdPlacement.ranksFeedNative)` (bottom padding
      `AppSpacing.sm.h`) after that many rows. Nothing in the empty-roster
      branch.
- [x] **4.7 N3 Level Complete** (`level_complete_screen.dart`, the body
      `Column` at lines 160-188): after `ScoreBreakdownCard`, add
      `SizedBox(height: AppSpacing.base.h)` +
      `const NativeAdTile(placement: AdPlacement.levelCompleteNative)`
      before the trailing spacer.
- [x] **4.8 N4 Duel Result** (`duel_result_screen.dart`, `_DuelResultView`
      body, after the stats `Container` ending at line 328): same, placement
      `duelResultNative`.
- [x] **4.9 N5 Daily Result** (`daily_result_screen.dart`,
      `_DailyResultLoadedView` body, after the card ending at line 172):
      `const NativeAdCard(placement: AdPlacement.dailyResultNative)`.

### Phase 5 — Interstitial break points

Pattern for all three: the handler awaits the Cubit, checks `mounted`, then
navigates. A private `bool _isLeaving` (ephemeral UI state — `setState` is
permitted for it) ignores taps while an ad is up.

- [x] **5.1 I1 Level Complete** (`_LevelCompleteScreenState`). Add:

      ```dart
      Future<void> _leave(VoidCallback navigate) async {
        if (_isLeaving) return;
        _isLeaving = true;
        final result = widget.state.result;
        await context.read<AdsCubit>().showInterstitialIfDue(
          AdPlacement.levelCompleteBreak,
          isCelebration: result.unlocksMastery ||
              result.newlyEarnedBadgeIds.isNotEmpty ||
              result.shouldOfferSaveProgress,
        );
        if (!mounted) return;
        _isLeaving = false;
        navigate();
      }
      ```

      Route these through it: `_close` (✕ and "Back to map"), every
      "Next level" `pushReplacement`, every "Replay" `pushReplacement`
      (lines 114-157). **Not** "See your trophy" and **not** share. The
      post-payout chain (`_runChain`) is unchanged.
- [x] **5.2 I2 Duel Result** (`_DuelResultView`). Wrap `_close` and
      `_findNewOpponent` (after the topic is resolved, before
      `pushReplacement(AppRoutes.duelMatchmaking…)`) with
      `showInterstitialIfDue(AdPlacement.duelResultBreak, isCelebration:
      result.newlyEarnedBadgeIds.isNotEmpty)` + `context.mounted` check.
      `_DuelResultView` is stateless — convert it to a `StatefulWidget` only
      if needed for the re-entrancy guard. **Do not touch** the
      `RematchStarting` or `BotRematchFound` listeners (lines 106-110,
      141-147).
- [x] **5.3 I3 Daily Result** (`_DailyResultLoadedView`). Wrap `onClose` and
      the "Back to daily" button (lines 100, 108-111) with
      `AdPlacement.dailyResultBreak`, `isCelebration:
      result.newlyEarnedBadgeIds.isNotEmpty`. Not the share actions.
- [x] **5.4 Leave `LevelFailedScreen` untouched** and add nothing to
      `quiz_play_screen.dart`, the pause sheet, or any duel play screen.

### Phase 6 — Consent entry point

- [x] **6.1** `settings/presentation/screens/privacy_settings_screen.dart`:
      below the two toggles, when `context.select<AdsCubit, bool>` says
      `AdsReady.privacyOptionsRequired`, add a `SettingsRow(title:
      l10n.privacyAdChoices, onTap: () => context.read<AdsCubit>()
      .showPrivacyOptions())` with the usual `AppSpacing.sm.h` gap. Google
      requires this entry point wherever its privacy-options form applies.

### Phase 7 — Tests, docs, cleanup

- [x] **7.1** Test-harness and test files per "Testing strategy".
- [x] **7.2 Docs.** `.claude/docs/backend/02-firebase-project-setup.md` §3:
      add the ads keys to the Remote Config table.
      `.claude/docs/backend/04-flutter-app-configuration.md`: add an "AdMob"
      section (where the App IDs and unit ids live, the console checklist
      from rollout notes). `MOCKED_FEATURES.md`: note the ids are still test
      ids until Open question 1 is closed.
- [x] **7.3** `dart format .`, `dart analyze` (zero warnings), `flutter test`.
      End the hand-off with the "To verify:" list at the bottom of this plan.

## Data model / API changes

No backend or schema changes.

**Remote Config keys** (add to `main.dart` defaults and the console):

| Key | Default | Meaning |
|---|---|---|
| `ads_enabled` | `true` | Master switch for interstitial/banner/native |
| `ads_disabled_placements` | `""` | Comma-separated `AdPlacement.id`s to turn off |
| `ads_interstitial_grace_breaks` | `2` | Breaks after install with no interstitial |
| `ads_interstitial_every_n_breaks` | `2` | Show at most one per N eligible breaks |
| `ads_interstitial_min_gap_seconds` | `120` | Cooldown since any full-screen ad |
| `ads_interstitial_session_cap` | `8` | Max interstitials per app process |
| `ads_home_native_first_section` | `2` | First Home native after this many sections |
| `ads_home_native_every_sections` | `5` | Then one per this many sections |
| `ads_home_native_max` | `2` | Max native rows on Home |
| `ads_ranks_native_after_row` | `5` | Ranks native after this many list rows |

**Ad units to create in AdMob** (six per platform, twelve in total):

| Unit name | Format | Used by |
|---|---|---|
| `interstitial_break` | Interstitial | I1, I2, I3 |
| `banner_anchored` | Banner (adaptive) | B1–B4 |
| `banner_rectangle` | Banner (300×250) | M1 |
| `native_feed` | Native advanced | N1, N2 |
| `native_result` | Native advanced | N3, N4, N5 |
| `rewarded_heart` | Rewarded | Out-of-lives dialog (existing) |

Separate units per placement group give per-surface eCPM/fill reporting in
AdMob, which is what makes later tuning possible.

**Local storage:** one new `shared_preferences` key, `ads.lifetimeBreaks`.

## Dependencies

N/A — no new packages. Uses `google_mobile_ads` (ads + bundled UMP),
`firebase_remote_config`, `shared_preferences`, `flutter_bloc`, `freezed`,
all already in `pubspec.yaml`.

## Testing strategy

Follow the existing conventions: `bloc_test` for Cubits, completer-backed
**fakes** for ad-service seams (as in `heart_ad_cubit_test.dart`), mocktail
`class FakeX extends Mock implements X {}` for API classes, `pumpApp` /
`pumpScreen` for widgets. Mind the saved gotcha: a fake that leaves a timer or
never completes will hang `pumpAndSettle`; every fake here must complete
immediately unless a test drives it.

- **Harness (do this first, or existing tests break):**
  `test/support/pump_screen.dart` — add optional `AdsCubit? ads` and
  `InlineAdService? inlineAds` parameters; default to a `MockCubit`-style fake
  `AdsCubit` in `AdsDisabled` (so every existing screen test renders exactly
  as before) and a fake `InlineAdService` returning `null`. Provide both.
  Whole-app tests (`app_test.dart`, `router_test.dart`,
  `localization_test.dart`, `integration/core_loop_test.dart`) pass a
  disabled fake through `QuizooApp(adsCubit: …)`.
- `test/core/ads/interstitial_pacer_test.dart` — grace, cadence, cooldown
  (injected clock), session cap, celebration skip still counts, not-ready
  stays owed, rewarded resets the cooldown.
- `test/core/ads/ads_config_repository_test.dart` — mocktail `AdsConfigApi`:
  maps values; clamps bad numbers; parses the placement list; returns
  defaults when the api throws.
- `test/core/ads/inline_ad_layout_test.dart` — table of
  (itemCount, first, every, max) → expected rows; never ends on an ad.
- `test/core/ads/inline_ad_cubit_test.dart` — initial state; success
  (`Loading → Loaded`); failure (`Loading → Unavailable`); an ad arriving
  after `close()` is disposed; `refreshIfStale`.
- `test/app/ads_cubit_test.dart` — initial; consent granted → `AdsReady` and
  interstitial preloaded; consent denied → `AdsDisabled`; config off →
  `AdsDisabled`; a throwing service → `AdsDisabled`;
  `showInterstitialIfDue` shows on the due break and not otherwise;
  disabled placement never shows; `isPlacementEnabled` honours the kill
  list.
- `test/core/widgets/ad_widgets_test.dart` — for each of the four widgets:
  renders nothing when ads are disabled; reserves height while loading;
  renders the ad box when loaded; anchored keeps space on failure,
  in-content collapses; both themes via `pumpInBothThemes`.
- Extend existing screen tests with an "ads on" variant using a fake
  `AdsReady` cubit:
  `quiz_result/level_complete_screen_test.dart` (tapping Next level awaits
  `showInterstitialIfDue` with `levelCompleteBreak` then navigates;
  celebration flag set when badges were earned; native tile present),
  `duel/duel_result_screen_test.dart` (close/find-new call it; a rematch
  never does), `home/home_screen_test.dart` (ad rows at the configured
  positions, none offline), `catalog` (banner absent on error/empty),
  `quiz_result/result_screen_test.dart` (**Level Failed has no ad widget and
  never calls `showInterstitialIfDue`** — a regression guard for the bible
  rule), `quiz_play/quiz_play_screen_test.dart` (no ad widgets on the play
  surface).
- No test may touch the real plugin: nothing in tests constructs
  `AdMob*Service` or `Ump*Service`.

## Edge cases & error handling

- **No fill / offline / load error:** slots collapse (or keep reserved space
  for anchored banners); interstitial breaks proceed instantly. No error UI,
  no retry spinners, no snackbars for passive ads.
- **Consent declined or unavailable (EEA/UK/CH):** `AdsDisabled` — no ad
  requests for the new formats. The existing rewarded button still works as
  before (the SDK decides what it may serve).
- **Unsupported platform** (web/desktop folders exist): `AdsDisabled`,
  no plugin calls.
- **Widget unmounted while an interstitial is up:** `mounted` /
  `context.mounted` check before navigating.
- **Double taps on an exit button:** `_isLeaving` guard.
- **Interstitial expiry:** `isReady` false after 55 min → that break is
  skipped and a fresh ad preloads.
- **Theme switch with a native ad on screen:** the slot is keyed on
  brightness and reloads with the right palette.
- **Level Map reload on return from a level:** banner stays mounted across
  `Loading`; no new request, no layout jump.
- **Tabs kept alive in the shell's `IndexedStack`:** each visited tab may
  hold a platform view (Home ≤ 2, Ranks 1, Daily 1). Slots only load when
  built, branches build on first visit, and Home is capped by
  `ads_home_native_max`.
- **Long-lived Home/Ranks/Daily slots:** `refreshIfStale()` on app resume
  replaces ads older than 55 minutes.
- **RTL (Urdu UI):** slot padding uses symmetric values; native templates
  lay themselves out per device locale.
- **Remote Config never fetched:** in-app defaults apply.
- **App muted in settings:** `setAppMuted` before an interstitial.
- **Tests / missing plugin:** `initialize()` swallows everything →
  `AdsDisabled`.

## Acceptance criteria

- [ ] Interstitials can appear only when leaving Level Complete, Duel Result
      (close / find new opponent) or Daily Result via an on-screen button —
      never during questions, on pause/quit, on Level Failed, on celebration
      screens, on app launch, on tab switches, on system back, or on the way
      into a live duel or rematch.
- [ ] With default config: no interstitial on the first two breaks after
      install; thereafter at most one per two eligible breaks, never within
      120 s of another full-screen ad (rewarded included), at most 8 per
      session; a break with a badge/mastery/save-progress offer never shows
      one.
- [ ] A missing or failed ad never delays or blocks navigation.
- [ ] Anchored adaptive banners render on Level Map, Category Detail, Stats
      and Achievements in their loaded states only, and the Level Map's Play
      button does not move when the banner loads.
- [ ] A 300×250 rectangle renders on the Daily tab; native small tiles render
      in the Home feed (configured positions, max 2), the Ranks list, Level
      Complete and Duel Result; a native medium card renders on Daily Result.
- [ ] Native ads use app tokens in both light and dark themes; no hardcoded
      colours, text styles or route strings were added to any feature file.
- [ ] No ad widget exists on any screen in the "Deliberately ad-free" table.
- [ ] Consent is gathered via UMP before any ad request; Privacy settings
      shows "Ad privacy choices" when Google requires it.
- [ ] `MobileAds.instance.initialize()` no longer runs before consent or on
      the startup path in `main.dart`.
- [ ] Setting `ads_enabled=false`, or listing a placement id in
      `ads_disabled_placements`, turns the corresponding ads off on the next
      launch with no code change.
- [ ] `lib/core/ads/ad_unit_ids.dart` is the only file under `lib/`
      containing an ad unit id (`grep -rn "ca-app-pub" lib` matches that file
      alone), and every ad class reads its id from it.
- [ ] All new Cubits/repositories have the tests listed above; the existing
      suite passes unchanged; `dart analyze` reports zero warnings.

## Risks & rollout notes

**Owner checklist (cannot be done from code):**
1. AdMob: create the iOS and Android apps, then the twelve ad units in the
   table above. Put the unit ids in `core/ads/ad_unit_ids.dart`, and replace
   the test App IDs in `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
   and `android/app/src/main/AndroidManifest.xml`
   (`com.google.android.gms.ads.APPLICATION_ID`).
2. AdMob → Privacy & messaging: publish a **European regulations (GDPR)**
   message, a **US states** message if targeting the US, and an **IDFA
   explainer** message for iOS (this is what triggers the ATT prompt;
   `NSUserTrackingUsageDescription` is already in `Info.plist`). Without
   published messages the consent form never appears.
3. AdMob → Blocking controls: block sensitive categories and set the content
   rating to match Open question 2.
4. AdMob → `interstitial_break` unit: add a frequency cap as a server-side
   backstop (for example 1 impression per 2 minutes per user).
5. AdMob → `banner_anchored`: leave automatic refresh at Google-optimised or
   60 s (never under 30 s).
6. Link the AdMob apps to the Firebase project so ad revenue and impressions
   land in Analytics.
7. Host an `app-ads.txt` on the developer website named in both store
   listings.
8. Play Console: declare the advertising ID and update Data safety. App Store
   Connect: update the App Privacy answers for advertising data.
9. Compare `SKAdNetworkItems` in `Info.plist` against Google's current list
   and add any missing ids.
10. Firebase Remote Config: add the ten keys.

**Risks:**
- **Policy.** The main AdMob risks are accidental clicks and ads on
  non-content screens; the layout-stability rules, the loaded-state gating
  and the ad-free table exist to prevent both. Do not relax them for revenue.
- **Shipping test ids.** Nothing in code stops a release build from using
  the test ids in `ad_unit_ids.dart` — it would show test ads and earn
  nothing. Gate release on checklist item 1.
- **Platform-view cost.** Several inline ads alive across tabs can hurt
  low-end Android devices. If frame times regress, lower
  `ads_home_native_max` to 1 or disable `ranks_feed_native` remotely.
- **Retention.** Start with the defaults, watch day-1/day-7 retention and
  session length for two weeks, then tune `every_n_breaks` (1 = more
  revenue, 3 = gentler) and the kill list from Remote Config.
- **Rollback.** `ads_enabled=false` in Remote Config disables everything
  this plan adds without a release; the rewarded heart ad is unaffected.

**Next revenue levers, deliberately deferred:** mediation/bidding (the
largest single uplift once volume exists), a "Remove ads" purchase, app-open
ads, and the phase-2 placements (Profile, Friends, Category leaderboard).

**To verify (developer, on a device — the agent must not run the app):**
- Fresh install: consent form appears where applicable; finish three levels
  and confirm the first interstitial arrives only on the third exit, and only
  after tapping a button.
- Next level after an interstitial: the countdown starts only once the ad is
  closed.
- Lose a level: no ad anywhere on Level Failed.
- Out of lives → watch the rewarded ad → finish the level: no interstitial
  within two minutes.
- Level Map: the Play button stays put while the banner loads; return from a
  level and confirm the banner does not flicker.
- Home, Ranks, Daily, Daily Result, Level Complete, Duel Result: ad slots
  look native to the app in light and dark, labelled "Advertisement", with
  clear space from buttons.
- Duel: rematch (live and bot) never shows an ad; closing the result may.
- Airplane mode: every screen lays out cleanly with no ad gaps (anchored
  banner strip aside) and no delays.
- Settings → Privacy: "Ad privacy choices" opens Google's form (in a region
  where it applies, or with a UMP debug geography).
