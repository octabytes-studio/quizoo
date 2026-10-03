# 04 — Flutter app configuration

Where the credentials and config from docs 01-03 actually land in the
`quizoo` Flutter project. Do this once the Supabase and Firebase projects
exist. This doc only wires up configuration and tooling — it does not touch
`lib/`; that's plan 005's job.

## 1. Add the packages

Design bible §25's package shortlist, added to `pubspec.yaml`'s
`dependencies:` block (versions: use whatever `flutter pub add` resolves at
the time — don't pin to what's written here):

```bash
flutter pub add supabase_flutter
flutter pub add firebase_core firebase_messaging firebase_crashlytics firebase_analytics firebase_remote_config
flutter pub add google_mobile_ads in_app_purchase
flutter pub add drift sqlite3_flutter_libs   # or `isar` — see plan 005's Assumptions
flutter pub add rive confetti
flutter pub add path_provider                # drift needs a filesystem path
flutter pub add dev:build_runner dev:drift_dev   # if drift
```

Do **not** add `dio` unless plan 005 decides an Edge Function needs a raw
HTTP call `supabase_flutter`'s client can't make — `supabase_flutter`
already wraps Postgrest, Auth, Realtime, Storage and Functions invocation in
one client, which covers everything `CLAUDE.md §9`'s `ApiClient` concept
needs.

## 2. Generate Firebase config with FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This walks you through selecting platforms (iOS/Android/Web) and writes
`lib/firebase_options.dart` — generated code, do not hand-edit it. It also
places `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist` for you, so you don't need to manually
copy the files downloaded in doc 02 §2 unless `flutterfire configure` fails
partway and you need to place one by hand:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist` (add it to the Xcode project via
  Xcode itself — File → Add Files to "Runner" — so it's included in the
  build, not just present on disk)

## 3. Supabase URL + anon key — how they reach the app

**Do not hardcode these in `lib/`.** Use `--dart-define` (or a
`--dart-define-from-file`, cleaner once you have more than two values) so
the same code works against staging and prod without a code change:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Read them in `main.dart` with `String.fromEnvironment`:

```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

For day-to-day local development, create a `dart_define.json` (already
covered by this repo's `.gitignore` — verify it is; if not, add it before
committing anything) so you're not retyping the flags:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon-key>"
}
```

```bash
flutter run --dart-define-from-file=dart_define.json
```

If you're running staging + prod Supabase projects (doc 01 §7), keep two
files (`dart_define.staging.json`, `dart_define.prod.json`) and point CI at
the right one per build flavor.

## 4. Platform-specific redirect / URL scheme setup

**OAuth (Google/Apple sign-in) needs a deep link back into the app.**

- **iOS** — `ios/Runner/Info.plist`: add a `CFBundleURLTypes` entry with a
  scheme matching your bundle ID (reverse-DNS form, e.g.
  `com.yourcompany.quizoo`). Supabase's redirect URL becomes
  `com.yourcompany.quizoo://login-callback`.
- **Android** — `android/app/src/main/AndroidManifest.xml`: add an
  `intent-filter` on the launcher activity for the same custom scheme.
- Register that exact redirect URL in **Supabase dashboard → Authentication
  → URL Configuration → Redirect URLs**, or the OAuth flow will complete on
  Apple/Google's side and then fail to hand control back to the app.

## 5. Android minSdkVersion

`google_mobile_ads`, `firebase_messaging` and recent `supabase_flutter`
releases typically require `minSdkVersion 23` or higher. Check
`android/app/build.gradle.kts` against whatever the packages you just added
report as their minimum (`flutter pub outdated` / the package's own
`pubspec.yaml` won't show this — check the error `flutter run` gives you the
first time you build, or each package's install docs) and raise it if
needed.

## 6. iOS minimum deployment target

Similarly, check `ios/Podfile`'s `platform :ios, 'X.X'` line against what
the newly added packages require (usually iOS 13+; Firebase and some ad SDKs
have moved to 15+ in recent releases) and raise it if `pod install` or the
Xcode build complains.

## 7. AdMob (plan 022)

The app shows a rewarded ad (out-of-lives dialog), interstitials at three
"run finished" break points, adaptive banners, a 300×250 rectangle and native
ads. Everything ships on **Google's public test ids** until the steps below
are done — test ads always fill and never earn.

**Where the ids live**

| What | Where |
|---|---|
| Ad unit ids (six per platform) | `lib/core/ads/ad_unit_ids.dart` — the only Dart file with an ad unit id |
| iOS App ID | `ios/Runner/Info.plist` → `GADApplicationIdentifier` |
| Android App ID | `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID` |

**Ad units to create** (once per platform):

| Unit name | Format | Constant in `AdUnitIds` | Used by |
|---|---|---|---|
| `interstitial_break` | Interstitial | `interstitial` | Level Complete, Duel Result, Daily Result exits |
| `banner_anchored` | Banner (adaptive) | `anchoredBanner` | Level Map, Category Detail, Stats, Achievements |
| `banner_rectangle` | Banner (300×250) | `rectangleBanner` | Daily tab |
| `native_feed` | Native advanced | `nativeFeed` | Home feed, Ranks list |
| `native_result` | Native advanced | `nativeResult` | Level Complete, Duel Result, Daily Result |
| `rewarded_heart` | Rewarded | `rewardedHeart` | Out-of-lives dialog |

**Console checklist** (none of this can be done from code):

1. AdMob: create the iOS and Android apps and the twelve ad units; paste the
   ids into the three places above.
2. AdMob → Privacy & messaging: publish a **European regulations (GDPR)**
   message, a **US states** message if targeting the US, and an **IDFA
   explainer** for iOS. Without published messages the consent form never
   appears (and the ATT prompt is never triggered).
3. AdMob → Blocking controls: block sensitive categories (gambling, dating,
   alcohol, …). The app itself requests a max ad content rating of **PG**
   (`_initializeAdsSdk` in `lib/app/app.dart`).
4. AdMob → `interstitial_break`: add a frequency cap as a server-side
   backstop (e.g. 1 impression per 2 minutes per user).
5. AdMob → `banner_anchored`: leave refresh at Google-optimised or 60 s —
   never under 30 s.
6. Link the AdMob apps to the Firebase project.
7. Host an `app-ads.txt` on the developer website named in both store
   listings.
8. Play Console: declare the advertising ID and update Data safety. App Store
   Connect: update the App Privacy answers for advertising data.
9. Compare `SKAdNetworkItems` in `Info.plist` with Google's current list.
10. Firebase Remote Config: add the ten `ads_*` keys (doc 02 §3).

**Kill switches:** `ads_enabled=false` turns off every interstitial, banner
and native ad on the next launch; `ads_disabled_placements` turns off single
placements. Neither affects the rewarded heart ad.

## 8. RevenueCat (plan 023)

Quizoo Pro's purchases go through the RevenueCat SDK
(`purchases_flutter`). No native setup is required beyond what the SDK
pulls in itself; the app's own configuration is three concerns.

**Where the keys live.** Exactly one file may contain a RevenueCat key:
`lib/core/subscription/revenuecat_config.dart`. They are **public** SDK
keys by design (they ship in the bundle and identify the app to
RevenueCat) — the secret REST key and the webhook bearer secret live only
as Supabase Edge Function secrets (doc 03 §2). The grep that proves this:

```bash
grep -rn "appl_\|goog_\|test_" lib   # must match only revenuecat_config.dart
```

**Which key, when.** `RevenueCatConfig.apiKeyFor(platform, useRealStore:
…)` picks it:

| | Debug | Release |
|---|---|---|
| iOS / macOS | Test Store key | `appl_…` |
| Android | Test Store key | `goog_…` |
| Web / desktop | none — Pro is unavailable | none |

Debug builds default to RevenueCat's **Test Store** so the paywall is
exercisable with no store setup at all. `--dart-define=RC_USE_REAL_STORE=true`
opts a debug build into the real sandbox stores. A release build **never**
falls back to the Test Store key: an empty platform key must leave Pro
unavailable.

```bash
# sandbox testing on a real store
flutter run --dart-define=RC_USE_REAL_STORE=true
```

**Master switch.** Remote Config's `pro_enabled` (doc 02 §3) hides every
paywall entry point and stops the SDK starting. Members keep their perks
from the local cache while it is off.

**Sandbox testing notes.** Apple sandbox subscriptions renew on an
accelerated clock (a monthly sub lapses in minutes); Google's license
testers need an internal-testing build at minimum. A purchase made while
signed in as a guest is attached to a device identity — the plan's
"Identity" section covers how it transfers on sign-in.

## 9. Verify before handing off to plan 005/006

Once steps 1-6 are done:

```bash
flutter pub get
flutter analyze          # should still be zero warnings per CLAUDE.md §8
flutter run --dart-define-from-file=dart_define.json
```

The app should launch exactly as it does today — nothing in `lib/` has
changed yet, only tooling and config. If it doesn't launch cleanly, resolve
that before starting plan 005; a broken build makes every step in that plan
harder to verify independently.
