import 'dart:async';

import 'package:quizoo/core/format/country_directory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/orphaned_profile_recovery.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:url_launcher/url_launcher.dart' show closeInAppWebView;

/// The real identity endpoint, over `supabase_flutter`'s Auth + Postgrest.
///
/// Every guest already carries a real anonymous Supabase session (see
/// `main.dart`'s startup bootstrap) — `auth.uid()` never changes across
/// "signing in", vendor and email routes both **upgrade the existing
/// anonymous user in place** rather than creating a new one, which is what
/// carries a guest's progress over with zero migration (plan 005,
/// Assumption #4).
class AuthApi {
  AuthApi(this._client);

  final SupabaseClient _client;

  static const String _oauthRedirect = 'com.quizoo.play://login-callback';

  /// Lets [SessionCubit] react to an OAuth deep link landing back in the app
  /// — [signInWithVendor] can only *launch* the browser, since a real
  /// provider's sign-in completes out of process.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// The signed-in player, if the current session is a real (non-anonymous)
  /// account with a completed profile — null for a guest or a signed-out
  /// caller. Used to restore `SessionSignedIn` across a cold start, since a
  /// real Supabase session persists where the mock's never did.
  Future<AuthUser?> restoreSignedInUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null || authUser.isAnonymous) return null;
    try {
      return await _fetchCurrentAuthUser();
    } catch (error) {
      // The account behind this persisted session was deleted server-side —
      // recover a fresh anonymous session and report back as a guest rather
      // than surfacing a content error for an identity that no longer
      // exists.
      if (await recoverFromOrphanedProfile(_client, error)) return null;
      throw ApiException.fromSupabase(error);
    }
  }

  /// Launches the vendor's OAuth flow. Resolves once the browser has been
  /// handed off to, not once the player is actually signed in — that arrives
  /// later via [authStateChanges].
  Future<void> signInWithVendor(AuthProvider provider) async {
    final oauthProvider = switch (provider) {
      AuthProvider.google => OAuthProvider.google,
      AuthProvider.apple => OAuthProvider.apple,
      AuthProvider.email => throw ArgumentError('email is not a vendor'),
    };
    try {
      await _client.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: _oauthRedirect,
      );
    } on PlatformException catch (error) {
      // `url_launcher`'s SFSafariViewController reports
      // `didCompleteInitialLoad(didLoadSuccessfully: false)` — and this
      // "Error while launching..." exception — for any URL that redirects on
      // its very first hop, which every OAuth `/authorize` endpoint does
      // (Supabase 302s straight to the vendor). The browser sheet is
      // presented and working regardless; [authStateChanges] is the real
      // source of truth for whether the sign-in itself succeeds or fails, so
      // this specific false negative shouldn't fail the flow before the
      // player has even seen the vendor's sign-in screen.
      if (error.code != 'Error') throw ApiException.fromSupabase(error);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Dismisses the in-app browser sheet [signInWithVendor] opened.
  ///
  /// The OAuth provider redirects to [_oauthRedirect], which the OS hands
  /// straight to the app via its URL scheme — but that never tells the
  /// `SFSafariViewController`/Custom Tab itself to close, so it's left
  /// stranded on screen (covering the app) until this is called. Safe to
  /// call even if no such browser is currently open.
  Future<void> closeVendorSignInBrowser() => closeInAppWebView();

  /// The email route has nothing to "start" against a real backend — the
  /// guest's existing anonymous session is what [createProfile] upgrades,
  /// and the email address itself is only collected there (S-25's own email
  /// field), not before. This just hands back the current session shaped the
  /// way S-25 expects (no username yet).
  Future<AuthUser> startEmailSignIn() async {
    try {
      return await _fetchCurrentAuthUser();
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Completes S-25: attaches a real email to the guest's anonymous account
  /// and fills in the profile.
  ///
  /// The email attach (`updateUser`) sends Supabase's own confirmation link
  /// to [email] — the "magic link" plan 005's Assumption #3 calls for — but
  /// is not awaited to completion here: the player is treated as signed in
  /// the moment their profile is saved (matching the mock's instant "Profile
  /// created" UX), and the confirmation completes silently in the background
  /// whenever they tap the link. `auth.uid()` never changes either way.
  Future<AuthUser> createProfile({
    required String username,
    required String email,
    required String avatarEmoji,
    required String countryCode,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const ApiException(
        'Not signed in',
        kind: ApiErrorKind.unauthorized,
      );
    }
    try {
      unawaited(_client.auth.updateUser(UserAttributes(email: email)));

      await _client
          .from('profiles')
          .update({
            'username': username,
            'avatar_key': avatarEmoji,
            'country_code': countryCode,
          })
          .eq('id', authUser.id);

      return AuthUser(
        id: authUser.id,
        displayName: username,
        provider: AuthProvider.email,
        avatarEmoji: avatarEmoji,
        email: email,
        countryName: CountryDirectory.nameFor(countryCode),
        countryFlag: CountryDirectory.flagFor(countryCode),
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Ends the current real session and re-establishes a fresh anonymous one,
  /// so the device drops back to a fully-functional guest — exactly what a
  /// cold start already does in `main.dart` — rather than being left with no
  /// session at all, which would break every RLS-gated call this app makes.
  ///
  /// [SupabaseClient.auth.signOut] invalidates the account's session token
  /// server-side, not just on-device, which is what actually revokes it.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
    try {
      await _client.auth.signInAnonymously();
    } on AuthException {
      // Same fallback as main.dart's bootstrap: continuing without a session
      // is no worse than a dead network at cold start, and the real sign-out
      // above already succeeded — this must not be reported as a failure.
    } catch (_) {
      // ignore
    }
  }

  /// The live availability check on S-25's username field.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final row = await _client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      return row == null;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<AuthUser> _fetchCurrentAuthUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const ApiException(
        'Not signed in',
        kind: ApiErrorKind.unauthorized,
      );
    }
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .single();
    return _toAuthUser(row, authUser: authUser);
  }

  static AuthUser _toAuthUser(
    Map<String, dynamic> row, {
    required User authUser,
  }) {
    final username = row['username'] as String?;
    final countryCode = row['country_code'] as String?;
    final suggestedDisplayName = username == null
        ? (authUser.userMetadata?['full_name'] as String? ??
              authUser.userMetadata?['name'] as String?)
        : null;
    return AuthUser(
      id: authUser.id,
      displayName: username ?? '',
      provider: _providerFrom(authUser),
      avatarEmoji: row['avatar_key'] as String? ?? '🐼',
      email: authUser.email,
      countryName: countryCode == null
          ? null
          : CountryDirectory.nameFor(countryCode),
      countryFlag: countryCode == null
          ? null
          : CountryDirectory.flagFor(countryCode),
      isProfileComplete: username != null,
      suggestedDisplayName: suggestedDisplayName,
    );
  }

  static AuthProvider _providerFrom(User authUser) =>
      switch (authUser.appMetadata['provider'] as String?) {
        'google' => AuthProvider.google,
        'apple' => AuthProvider.apple,
        _ => AuthProvider.email,
      };
}
