# 02 — Firebase project setup

Firebase's role here is **client-only services** — FCM, Crashlytics,
Analytics, Remote Config (design bible §22). Do not enable Firestore or
Firebase Authentication for this project; Supabase owns the database and
auth.

## 1. Create the project

1. [console.firebase.google.com](https://console.firebase.google.com) →
   **Add project** → name it `quizoo` (or `quizoo-staging` / `quizoo-prod` to
   match your Supabase split — see doc 01 §7).
2. Google Analytics: leave it **on** (it's how Analytics in §22's package
   shortlist gets wired up — same project, no separate setup).

## 2. Register the apps

Flutter builds for iOS, Android and (optionally) Web each need their own
Firebase "app" registration inside this one project.

**Android:**
1. **Add app → Android**.
2. Package name: match `applicationId` in
   `android/app/build.gradle.kts` (or `build.gradle`) — check what's there
   now rather than guessing; the design bible doesn't specify one.
3. Download `google-services.json` — doc 04 says exactly where it goes.
4. Add your **SHA-1** (and SHA-256, for App Links) signing fingerprint —
   same command as doc 01's Google Sign-In step:
   `cd android && ./gradlew signingReport`.

**iOS:**
1. **Add app → iOS**.
2. Bundle ID: match `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project
   (`ios/Runner.xcodeproj`) — again, check the actual value.
3. Download `GoogleService-Info.plist` — doc 04 says where it goes.

**Web** (only if the project ever ships a web build — `web/` exists in the
repo, so register it even if Flutter Web isn't an active target yet):
1. **Add app → Web**.
2. Copy the resulting `firebaseConfig` object — doc 04 covers passing it to
   `Firebase.initializeApp` on web.

## 3. Enable the four services

- **Cloud Messaging (FCM)** — no separate "enable" step; it activates the
  moment an app is registered above. You'll need an **APNs key** for iOS
  push to actually deliver — that's covered in doc 03 (it's issued from App
  Store Connect, not Firebase).
- **Crashlytics** — **Release & Monitor → Crashlytics → Enable Crashlytics**.
  Non-negotiable for a Flutter app with this much custom animation (§22).
- **Analytics** — already on from project creation (step 1).
- **Remote Config** — **Release & Monitor → Remote Config → Create
  configuration**. This is where the economy's tunable numbers live per
  §22: coin payouts per level/duel, timer seconds per difficulty band
  (though the current formula is computed client-side from the level number
  — see `scoring.dart` — Remote Config would let you override it without a
  release if you ever need to), and the save-progress-sheet timing rule.
  Seed it with parameters matching the current hardcoded values so nothing
  changes behavior on day one:

  | Key | Value | Matches |
  |---|---|---|
  | `daily_challenge_coin_reward` | `300` | `daily_challenges.coin_reward` |
  | `daily_challenge_xp_reward` | `500` | `daily_challenges.xp_reward` |
  | `heart_refill_minutes` | `20` | `_settle_hearts()`'s `v_refill_minutes` |
  | `duel_winner_coins` | `200` | `resolve_duel()`'s payout |
  | `duel_loser_coins` | `40` | `resolve_duel()`'s payout |
  | `coin_pack_ids` | `["pack_small","pack_medium","pack_large"]` | `CoinPack` catalog — see doc 03 |
  | `save_progress_prompt_enabled` | `true` | S-24 gating |
  | `ads_enabled` | `true` | Master switch for interstitial / banner / native ads (plan 022). The rewarded heart ad is unaffected |
  | `ads_disabled_placements` | `""` | Comma-separated `AdPlacement.id`s to switch off (e.g. `ranks_feed_native,level_complete_native`) — ids in `lib/core/ads/ad_placement.dart` |
  | `ads_interstitial_grace_breaks` | `2` | Breaks after install with no interstitial |
  | `ads_interstitial_every_n_breaks` | `2` | At most one interstitial per N eligible breaks |
  | `ads_interstitial_min_gap_seconds` | `120` | Cooldown since any full-screen ad, rewarded included |
  | `ads_interstitial_session_cap` | `8` | Max interstitials per app process |
  | `ads_home_native_first_section` | `2` | First Home native ad after this many category sections |
  | `ads_home_native_every_sections` | `5` | Then one per this many sections |
  | `ads_home_native_max` | `2` | Max native rows on Home |
  | `ads_ranks_native_after_row` | `5` | Ranks native ad after this many list rows |

  The ten `ads_*` keys are read once, when ads start up at launch, so a
  console change takes effect on the launch after it has been fetched. The
  same defaults are registered in `lib/main.dart` and in `AdsConfig`
  (`lib/core/ads/ads_config.dart`); keep the three in step.

  Keeping these in Remote Config rather than hardcoding them a second time
  in the Flutter app is the whole point — a balance change ships without an
  app store review.

## 4. Get your config values

Nothing further to copy out manually — the two config files
(`google-services.json`, `GoogleService-Info.plist`) downloaded in step 2 are
everything the Flutter app needs; `flutterfire configure` (doc 04) will also
generate a `firebase_options.dart` from them automatically.
