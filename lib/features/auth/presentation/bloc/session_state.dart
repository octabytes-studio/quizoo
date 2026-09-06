part of 'session_cubit.dart';

/// Who the app thinks is playing, as a sealed hierarchy so every consumer
/// switches exhaustively (CLAUDE.md §3).
///
/// [SessionGuest] is not an error or an empty state — it is the app's normal,
/// fully-featured mode. Everything is playable from it.
sealed class SessionState extends Equatable {
  const SessionState();

  /// The signed-in player, or null while they are still a guest.
  ///
  /// Offered so a widget that only needs "is there a name to greet" does not
  /// have to switch over every variant.
  AuthUser? get user => switch (this) {
    SessionSignedIn(:final user) => user,
    _ => null,
  };

  @override
  List<Object?> get props => const [];
}

/// Nobody has signed in. The default, and never a dead end.
final class SessionGuest extends SessionState {
  const SessionGuest();
}

/// A mocked sign-in is in flight, so S-24's buttons show they were heard.
final class SessionAuthenticating extends SessionState {
  const SessionAuthenticating();
}

/// A player with an account.
final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user);

  @override
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// The mocked sign-in failed. The player stays playable — the sheet shows the
/// error and leaves "keep playing as guest" in place.
final class SessionFailure extends SessionState {
  const SessionFailure(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
