import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';

part 'session_state.dart';

/// Who is playing.
///
/// This is the second Cubit that genuinely belongs at the app root, next to
/// `ThemeCubit` — CLAUDE.md §3 names "auth session" as its own example of the
/// exception. Home switches its whole layout on it (S-04 vs S-05), the result
/// chain asks it whether to offer an account, and plans 003 and 004 read it
/// for the profile tab and the leaderboard's own row.
///
/// Sign-in is mocked: no token, no network account, no vendor SDK. Tapping a
/// button flips this Cubit and nothing else (plan 002, Scope).
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionGuest());

  final AuthRepository _repository;

  bool get isGuest => state is SessionGuest;

  Future<void> signInWithVendor(AuthProvider provider) async {
    emit(const SessionAuthenticating());
    try {
      emit(SessionSignedIn(await _repository.signInWithVendor(provider)));
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
}
