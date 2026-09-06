/// Remembers whether first-run has already happened.
///
/// **In-memory only, deliberately** (plan 002, Assumption 3). The bible's rule
/// is that onboarding and the language picker are shown *once, ever*; real
/// cross-session persistence needs `shared_preferences`, which is not part of
/// this design-with-mock-data phase. So a cold start replays onboarding.
///
/// That is a known, accepted gap rather than a bug, and it is why this class
/// exists at all: when persistence lands, only this file changes and the
/// splash screen's logic stays exactly as written.
class OnboardingRepository {
  bool _hasSeenOnboarding = false;
  bool _hasChosenLanguage = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;

  bool get hasChosenLanguage => _hasChosenLanguage;

  /// True on the very first launch of a session, which is what sends the
  /// splash screen to S-02 rather than straight to Home.
  bool get isFirstLaunch => !_hasSeenOnboarding;

  void markOnboardingSeen() => _hasSeenOnboarding = true;

  void markLanguageChosen() => _hasChosenLanguage = true;
}
