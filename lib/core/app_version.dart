/// The version string the Settings footer shows.
///
/// Read from `--dart-define=APP_VERSION=...`, which `scripts/build.sh` fills
/// in from the version already read out of `pubspec.yaml` (plan 025) — the
/// build script is the single source of truth for release builds, so no
/// `package_info_plus` dependency is needed. The default keeps IDE and test
/// runs honest and must match `pubspec.yaml` at release time.
const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.1.0 (2)',
);
