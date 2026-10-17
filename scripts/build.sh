#!/usr/bin/env bash
#
# Build signed, obfuscated release artifacts (APK / App Bundle / IPA) for Quizoo.
#
# Usage:
#   scripts/build.sh <target> [options]
#
# Targets:
#   apk         Signed Android APK (build/app/outputs/flutter-apk/)
#   appbundle   Signed Android App Bundle for Play Store (build/app/outputs/bundle/)
#   ipa         Signed iOS IPA for App Store / ad-hoc distribution (build/ios/ipa/) — macOS only
#   all         apk + appbundle, and ipa if running on macOS
#
# Options:
#   --mode <release|profile>       Build mode (default: release)
#   --no-obfuscate                 Disable code obfuscation / symbol splitting
#   --dart-define-file <path>      Dart define file (default: dart_define.json, if present)
#   --clean                        Run `flutter clean` before building
#   --export-method <method>       iOS export method: app-store | ad-hoc | development | enterprise
#                                   (default: app-store)
#   --team-id <id>                 iOS Development Team ID (default: read from Runner.xcodeproj)
#   --export-options-plist <path>  Use your own ExportOptions.plist instead of a generated one
#   -h, --help                     Show this help
#
# Examples:
#   scripts/build.sh apk
#   scripts/build.sh appbundle --clean
#   scripts/build.sh ipa --export-method ad-hoc
#   scripts/build.sh all
#
# Notes:
#   - Android release signing reads android/key.properties (see
#     android/key.properties.example). Without it, Gradle falls back to the debug
#     key and Play Store will reject the upload — the script warns before building.
#   - Obfuscated builds write debug symbols to build/symbols/<target>/<version>/.
#     Keep these; you need the matching set to symbolicate a crash for a given
#     release build (Crashlytics/Sentry `--split-debug-info`).
#   - iOS builds must run on macOS with Xcode installed.
#   - Ads: release/profile artifacts always force SHOW_TEST_ADS=false, so a
#     signed build can never ship Google's test ad units regardless of what
#     the dart-define file says (see lib/core/ads/ad_unit_ids.dart).

set -eo pipefail
# Note: deliberately no `set -u` — macOS ships bash 3.2, where expanding an empty
# array (e.g. "${arr[@]}" when arr has zero elements) is treated as an unbound
# variable and aborts the script. bash 3.2 also lacks `mapfile`/`readarray`, so
# multi-line command output is captured below with a plain `while read` loop.

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MODE="release"
OBFUSCATE=true
DART_DEFINE_FILE="dart_define.json"
CLEAN=false
EXPORT_METHOD="app-store"
TEAM_ID=""
EXPORT_OPTIONS_PLIST=""

usage() {
  sed -n '2,41p' "$0" | sed 's/^# \{0,1\}//'
}

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m warning:\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

[[ $# -eq 0 ]] && { usage; exit 1; }

TARGET="$1"; shift

if [[ "$TARGET" == "-h" || "$TARGET" == "--help" ]]; then
  usage; exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"; shift 2 ;;
    --no-obfuscate)
      OBFUSCATE=false; shift ;;
    --dart-define-file)
      DART_DEFINE_FILE="$2"; shift 2 ;;
    --clean)
      CLEAN=true; shift ;;
    --export-method)
      EXPORT_METHOD="$2"; shift 2 ;;
    --team-id)
      TEAM_ID="$2"; shift 2 ;;
    --export-options-plist)
      EXPORT_OPTIONS_PLIST="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      die "Unknown option: $1 (see --help)" ;;
  esac
done

[[ "$MODE" == "release" || "$MODE" == "profile" ]] || die "--mode must be 'release' or 'profile', got '$MODE'"

VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/version:\s*//' | tr -d '[:space:]')"
[[ -n "$VERSION" ]] || die "Could not read version from pubspec.yaml"

DART_DEFINE_ARGS=()
if [[ -f "$DART_DEFINE_FILE" ]]; then
  DART_DEFINE_ARGS+=(--dart-define-from-file="$DART_DEFINE_FILE")
else
  warn "$DART_DEFINE_FILE not found — building without --dart-define-from-file."
fi
# Never ship test ads. This script only builds release/profile artifacts, so
# force the real AdMob units regardless of what the define file says.
# --dart-define overrides --dart-define-from-file, so this wins over
# "SHOW_TEST_ADS": true in dart_define.json (see lib/core/ads/ad_unit_ids.dart).
DART_DEFINE_ARGS+=(--dart-define=SHOW_TEST_ADS=false)
# The Settings footer's version string is sourced from pubspec.yaml at build
# time (plan 025) — `--dart-define` wins over the define file, so a release
# build can never show a stale version (see lib/core/app_version.dart).
DART_DEFINE_ARGS+=(--dart-define=APP_VERSION="$VERSION")

# Sets the global OBF_ARGS array. $1 = platform subdir name for the symbols output
# (android / ios). Bash 3.2 (macOS's default /bin/bash) has no `mapfile`, so this
# builds the array directly rather than via command substitution.
collect_obfuscate_args() {
  OBF_ARGS=()
  local symbols_dir="build/symbols/$1/$VERSION"
  if [[ "$OBFUSCATE" == true ]]; then
    mkdir -p "$symbols_dir"
    OBF_ARGS=(--obfuscate "--split-debug-info=$symbols_dir")
  fi
}

run_flutter() {
  log "flutter $*"
  flutter "$@"
}

pre_flight() {
  command -v flutter >/dev/null 2>&1 || die "flutter is not on PATH"
  [[ "$CLEAN" == true ]] && run_flutter clean
  run_flutter pub get
}

build_apk() {
  if [[ ! -f android/key.properties ]]; then
    warn "android/key.properties not found — the APK will be signed with the debug key" \
         "and cannot be distributed via Play Store. See android/key.properties.example."
  fi
  collect_obfuscate_args android
  local -a args=(build apk --"$MODE")
  args+=("${OBF_ARGS[@]}" "${DART_DEFINE_ARGS[@]}")
  run_flutter "${args[@]}"
  log "APK output: build/app/outputs/flutter-apk/"
}

build_appbundle() {
  if [[ ! -f android/key.properties ]]; then
    warn "android/key.properties not found — the App Bundle will be signed with the debug key" \
         "and Play Store will reject the upload. See android/key.properties.example."
  fi
  collect_obfuscate_args android
  local -a args=(build appbundle --"$MODE")
  args+=("${OBF_ARGS[@]}" "${DART_DEFINE_ARGS[@]}")
  run_flutter "${args[@]}"
  log "App Bundle output: build/app/outputs/bundle/"
}

resolve_team_id() {
  [[ -n "$TEAM_ID" ]] && return
  TEAM_ID="$(grep -m1 'DEVELOPMENT_TEAM' ios/Runner.xcodeproj/project.pbxproj | sed 's/[^=]*=\s*//;s/;.*//' | tr -d '[:space:]')"
  [[ -n "$TEAM_ID" ]] || die "Could not determine iOS Development Team ID. Pass --team-id <id>."
}

build_ipa() {
  [[ "$(uname -s)" == "Darwin" ]] || die "iOS builds require macOS + Xcode."

  local plist="$EXPORT_OPTIONS_PLIST"
  if [[ -z "$plist" ]]; then
    resolve_team_id
    plist="build/ios/ExportOptions.plist"
    mkdir -p "$(dirname "$plist")"
    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>${EXPORT_METHOD}</string>
	<key>teamID</key>
	<string>${TEAM_ID}</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
PLIST
    log "Generated $plist (method=$EXPORT_METHOD, teamID=$TEAM_ID)"
  fi

  collect_obfuscate_args ios
  local -a args=(build ipa --"$MODE" --export-options-plist="$plist")
  args+=("${OBF_ARGS[@]}" "${DART_DEFINE_ARGS[@]}")
  run_flutter "${args[@]}"
  log "IPA output: build/ios/ipa/"
}

pre_flight

case "$TARGET" in
  apk)       build_apk ;;
  appbundle) build_appbundle ;;
  ipa)       build_ipa ;;
  all)
    build_apk
    build_appbundle
    if [[ "$(uname -s)" == "Darwin" ]]; then
      build_ipa
    else
      warn "Skipping ipa build: not running on macOS."
    fi
    ;;
  -h|--help) usage; exit 0 ;;
  *) die "Unknown target: $TARGET (expected apk | appbundle | ipa | all)" ;;
esac

log "Done."
