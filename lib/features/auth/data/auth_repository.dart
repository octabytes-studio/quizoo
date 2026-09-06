import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';

/// Turns [AuthApi]'s responses into domain models, and holds the two
/// session-lifetime flags that decide whether the app is allowed to ask for
/// an account.
///
/// **Why the flags live here rather than in a Cubit's state**: they outlive
/// any single screen's Cubit — the result screen writes them and the
/// save-progress sheet reads them, on different routes. They are deliberately
/// in-memory only. `shared_preferences` is not part of this phase (plan 002,
/// Assumption 3 and §21 of plan 001), so a cold start forgets that the prompt
/// was ever shown. That is a known, accepted gap against the bible's real
/// "at most once per 24 h" rule, not an oversight.
class AuthRepository {
  AuthRepository(this._api);

  final AuthApi _api;

  bool _hasCompletedALevel = false;
  bool _hasShownSaveProgressPrompt = false;

  /// True once the player has finished any level successfully.
  bool get hasCompletedALevel => _hasCompletedALevel;

  /// True once S-24 has been shown in this session.
  bool get hasShownSaveProgressPrompt => _hasShownSaveProgressPrompt;

  /// Whether S-24 is allowed to appear right now.
  ///
  /// Every clause is one of the bible's own rules for the single conversion
  /// moment: only after a **successful** level, only for a guest, and at most
  /// once. The "never after a failure" half is enforced by the caller — the
  /// failed-result branch never asks.
  bool shouldOfferSaveProgress({required bool isGuest}) =>
      isGuest && _hasCompletedALevel && !_hasShownSaveProgressPrompt;

  void markLevelCompleted() => _hasCompletedALevel = true;

  void markSaveProgressPromptShown() => _hasShownSaveProgressPrompt = true;

  Future<AuthUser> signInWithVendor(AuthProvider provider) =>
      _api.signInWithVendor(provider);

  Future<AuthUser> startEmailSignIn() => _api.startEmailSignIn();

  Future<AuthUser> createProfile({
    required String username,
    required String email,
    required String avatarEmoji,
    required String countryName,
    required String countryFlag,
  }) => _api.createProfile(
    username: username,
    email: email,
    avatarEmoji: avatarEmoji,
    countryName: countryName,
    countryFlag: countryFlag,
  );

  Future<bool> isUsernameAvailable(String username) =>
      _api.isUsernameAvailable(username);
}
