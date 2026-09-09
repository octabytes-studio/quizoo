import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether first-run has already happened.
///
/// Backed by `shared_preferences` (plan 005, Assumption #5) — per-device UX
/// state ("has this install seen the onboarding carousel"), not player data,
/// so a returning player never sees onboarding again against a real backend.
class OnboardingRepository {
  OnboardingRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _hasSeenOnboardingKey = 'onboarding.hasSeenOnboarding';
  static const _hasChosenLanguageKey = 'onboarding.hasChosenLanguage';

  bool get hasSeenOnboarding =>
      _preferences.getBool(_hasSeenOnboardingKey) ?? false;

  bool get hasChosenLanguage =>
      _preferences.getBool(_hasChosenLanguageKey) ?? false;

  /// True on the very first launch ever, which is what sends the splash
  /// screen to S-02 rather than straight to Home.
  bool get isFirstLaunch => !hasSeenOnboarding;

  void markOnboardingSeen() {
    unawaited(_preferences.setBool(_hasSeenOnboardingKey, true));
  }

  void markLanguageChosen() {
    unawaited(_preferences.setBool(_hasChosenLanguageKey, true));
  }
}
