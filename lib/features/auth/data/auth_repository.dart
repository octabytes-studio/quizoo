import 'dart:async';

import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

/// Turns [AuthApi]'s responses into domain models, and holds the two
/// save-progress-prompt flags in `shared_preferences` (plan 005, Assumption
/// #6) — per-device UX state, not player data, so it lives on the device
/// rather than in a `profiles` column.
class AuthRepository {
  AuthRepository(this._api, this._preferences);

  final AuthApi _api;
  final SharedPreferences _preferences;

  static const _hasCompletedALevelKey = 'auth.hasCompletedALevel';
  static const _hasShownSaveProgressPromptKey =
      'auth.hasShownSaveProgressPrompt';

  /// True once the player has finished any level successfully.
  bool get hasCompletedALevel =>
      _preferences.getBool(_hasCompletedALevelKey) ?? false;

  /// True once S-24 has been shown on this device.
  bool get hasShownSaveProgressPrompt =>
      _preferences.getBool(_hasShownSaveProgressPromptKey) ?? false;

  /// Whether S-24 is allowed to appear right now.
  ///
  /// Every clause is one of the bible's own rules for the single conversion
  /// moment: only after a **successful** level, only for a guest, and at most
  /// once. The "never after a failure" half is enforced by the caller — the
  /// failed-result branch never asks.
  bool shouldOfferSaveProgress({required bool isGuest}) =>
      isGuest && hasCompletedALevel && !hasShownSaveProgressPrompt;

  void markLevelCompleted() =>
      unawaited(_preferences.setBool(_hasCompletedALevelKey, true));

  void markSaveProgressPromptShown() =>
      unawaited(_preferences.setBool(_hasShownSaveProgressPromptKey, true));

  /// So [SessionCubit] can react once a vendor OAuth deep link lands back in
  /// the app — the moment a real sign-in actually completes.
  Stream<AuthState> get authStateChanges => _api.authStateChanges;

  /// Restores `SessionSignedIn` across a cold start, since a real Supabase
  /// session persists where the mock's never did.
  Future<AuthUser?> restoreSignedInUser() => _api.restoreSignedInUser();

  Future<void> signInWithVendor(AuthProvider provider) =>
      _api.signInWithVendor(provider);

  /// So [SessionCubit] can dismiss the vendor's OAuth browser sheet once its
  /// deep link lands (or fails) — it never closes itself.
  Future<void> closeVendorSignInBrowser() => _api.closeVendorSignInBrowser();

  Future<AuthUser> startEmailSignIn() => _api.startEmailSignIn();

  Future<AuthUser> createProfile({
    required String username,
    required String email,
    required String avatarEmoji,
    required String countryCode,
  }) => _api.createProfile(
    username: username,
    email: email,
    avatarEmoji: avatarEmoji,
    countryCode: countryCode,
  );

  Future<bool> isUsernameAvailable(String username) =>
      _api.isUsernameAvailable(username);

  Future<AuthUser> updateProfile({
    required String username,
    required String avatarEmoji,
  }) => _api.updateProfile(username: username, avatarEmoji: avatarEmoji);

  /// Invalidates the current account's session and drops back to a guest.
  Future<void> signOut() => _api.signOut();
}
