import 'package:equatable/equatable.dart';

/// How one challenge card renders for the viewer — derived in
/// `DuelArenaReady.cardStateFor`, never in a widget (plan 017, "Challenge
/// card states").
sealed class ChallengeCardState extends Equatable {
  const ChallengeCardState();

  @override
  List<Object?> get props => const [];
}

/// Joinable: the creator is on the arena and the viewer has no request in.
final class ChallengeCardOpen extends ChallengeCardState {
  const ChallengeCardOpen();
}

/// The viewer's request is queued behind others.
///
/// [position] is the server's 1-based place in line, or null while the
/// request is still in flight (the optimistic entry).
final class ChallengeCardQueued extends ChallengeCardState {
  const ChallengeCardQueued({this.position});

  final int? position;

  @override
  List<Object?> get props => [position];
}

/// The creator is deciding on the viewer's request until [expiresAt]
/// (server time).
final class ChallengeCardPending extends ChallengeCardState {
  const ChallengeCardPending({required this.expiresAt});

  final DateTime expiresAt;

  @override
  List<Object?> get props => [expiresAt];
}

/// The viewer's request was declined or lapsed; another is allowed at
/// [retryAt]. [justResolved] is true for the first couple of seconds, while
/// the card still says "Not this time".
final class ChallengeCardCooling extends ChallengeCardState {
  const ChallengeCardCooling({
    required this.retryAt,
    this.justResolved = false,
  });

  final DateTime retryAt;
  final bool justResolved;

  @override
  List<Object?> get props => [retryAt, justResolved];
}

/// The creator is off the arena, so the challenge is paused (Decision 2).
final class ChallengeCardAway extends ChallengeCardState {
  const ChallengeCardAway();
}

/// The challenge is being played. The opponent is named by [opponentName],
/// or as "Guest {opponentGuestTag}".
final class ChallengeCardInProgress extends ChallengeCardState {
  const ChallengeCardInProgress({this.opponentName, this.opponentGuestTag});

  final String? opponentName;
  final String? opponentGuestTag;

  @override
  List<Object?> get props => [opponentName, opponentGuestTag];
}

/// The viewer's own challenge; [paused] while they are away from the arena.
final class ChallengeCardOwn extends ChallengeCardState {
  const ChallengeCardOwn({this.paused = false});

  final bool paused;

  @override
  List<Object?> get props => [paused];
}
