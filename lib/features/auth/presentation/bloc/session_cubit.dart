import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

part 'session_state.dart';

/// Who is playing.
///
/// This is the second Cubit that genuinely belongs at the app root, next to
/// `ThemeCubit` — CLAUDE.md §3 names "auth session" as its own example of the
/// exception. Home switches its whole layout on it (S-04 vs S-05), the result
/// chain asks it whether to offer an account, and plans 003 and 004 read it
/// for the profile tab and the leaderboard's own row.
///
/// **A real backend makes vendor sign-in inherently asynchronous** in a way
/// the mock never was: `signInWithVendor` only launches the OAuth browser —
/// the actual sign-in completes later, out of process, via a deep link. This
/// Cubit listens for that completion on [AuthRepository.authStateChanges]
/// rather than awaiting a return value, which is the one real behavioral
/// addition plan 005 makes here (its Research findings call this Cubit a
/// "zero changes" case for the general shape; the OAuth completion path is
/// the exception that shape didn't have to account for in the mock).
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionGuest()) {
    _authStateSubscription = _repository.authStateChanges.listen(
      _onAuthStateChange,
    );
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _authStateSubscription;

  bool get isGuest => state is SessionGuest;

  /// Restores `SessionSignedIn` across a cold start, since a real Supabase
  /// session persists where the mock's never did. Call once from the app
  /// root at startup.
  Future<void> restore() async {
    try {
      final user = await _repository.restoreSignedInUser();
      if (user != null && !isClosed) emit(SessionSignedIn(user));
    } on ApiException {
      // No restorable session is not an error — stay a guest.
    }
  }

  void _onAuthStateChange(AuthState data) {
    if (isClosed || state is! SessionAuthenticating) return;
    if (data.event != AuthChangeEvent.signedIn) return;
    final user = data.session?.user;
    if (user == null || user.isAnonymous) return;
    unawaited(_completeVendorSignIn());
  }

  Future<void> _completeVendorSignIn() async {
    try {
      final user = await _repository.restoreSignedInUser();
      if (user != null && !isClosed) emit(SessionSignedIn(user));
    } on ApiException catch (error) {
      if (!isClosed) emit(SessionFailure(error));
    }
  }

  /// Launches a vendor's OAuth flow. Resolution of the actual sign-in arrives
  /// later, through [_onAuthStateChange] once the deep link lands.
  Future<void> signInWithVendor(AuthProvider provider) async {
    emit(const SessionAuthenticating());
    try {
      await _repository.signInWithVendor(provider);
    } on ApiException catch (error) {
      emit(SessionFailure(error));
    }
  }

  /// Starts the email route. Resolves to an account with no profile yet, so
  /// the caller pushes S-25 rather than treating this as a finished sign-in.
  Future<void> startEmailSignIn() async {
    emit(const SessionAuthenticating());
    try {
      emit(SessionSignedIn(await _repository.startEmailSignIn()));
    } on ApiException catch (error) {
      emit(SessionFailure(error));
    }
  }

  Future<void> createProfile({
    required String username,
    required String email,
    required String avatarEmoji,
    required String countryName,
    required String countryFlag,
  }) async {
    emit(const SessionAuthenticating());
    try {
      emit(
        SessionSignedIn(
          await _repository.createProfile(
            username: username,
            email: email,
            avatarEmoji: avatarEmoji,
            countryName: countryName,
            countryFlag: countryFlag,
          ),
        ),
      );
    } on ApiException catch (error) {
      emit(SessionFailure(error));
    }
  }

  /// Drops back to guest. A failed sign-in ends here too, because the bible
  /// is explicit that nothing about play is ever gated on an account.
  void continueAsGuest() => emit(const SessionGuest());

  @override
  Future<void> close() {
    unawaited(_authStateSubscription?.cancel());
    return super.close();
  }
}
