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

## 7. Verify before handing off to plan 005/006

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
