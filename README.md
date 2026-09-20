# quizoo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Building release artifacts

`scripts/build.sh` produces signed, obfuscated APK / App Bundle / IPA builds in one
command — it runs `flutter pub get`, applies `--obfuscate --split-debug-info`, and
passes through `--dart-define-from-file=dart_define.json`.

**One-time setup:**

- Android: copy `android/key.properties.example` to `android/key.properties` and fill
  in your upload keystore details (see the comments in that file for how to generate
  one). Without it, builds fall back to debug signing and the script warns you.
- iOS: build on macOS with Xcode signed in to a team that can build `Runner`
  (Automatic signing is already configured). No extra setup needed for App Store
  exports; see `scripts/build.sh --help` for ad-hoc/development/enterprise exports.

**Sample commands:**

```sh
# Signed, obfuscated Android APK
scripts/build.sh apk

# Signed, obfuscated Android App Bundle (Play Store)
scripts/build.sh appbundle

# Signed, obfuscated iOS IPA (App Store export) — macOS only
scripts/build.sh ipa

# All platforms in one go (apk + appbundle, plus ipa on macOS)
scripts/build.sh all

# Clean build, profile mode instead of release
scripts/build.sh apk --mode profile --clean

# Ad-hoc iOS distribution build
scripts/build.sh ipa --export-method ad-hoc

# Skip obfuscation (e.g. for a quick local test build)
scripts/build.sh apk --no-obfuscate
```

Obfuscated builds write debug symbols to `build/symbols/<platform>/<version>/`
(gitignored). Keep the symbols for each release you ship — you need the matching set
to de-obfuscate a stack trace from that build (e.g. with Firebase Crashlytics or
Sentry).

Full option list: `scripts/build.sh --help`.
