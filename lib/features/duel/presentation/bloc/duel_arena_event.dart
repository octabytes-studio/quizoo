part of 'duel_arena_bloc.dart';

/// Everything that can move the Duel Arena (plan 017, Phase 8). A full Bloc
/// rather than a Cubit because one state machine is fed by the player, the
/// server's broadcasts and two timers (CLAUDE.md §3).
sealed class DuelArenaEvent extends Equatable {
  const DuelArenaEvent();

  @override
  List<Object?> get props => const [];
}

/// The arena screen opened: load the snapshot and start listening.
final class ArenaOpened extends DuelArenaEvent {
  const ArenaOpened();
}

/// The arena became the visible, foreground route ([visible]) or stopped
/// being it — another route pushed on top, or the app backgrounded.
final class ArenaVisibilityChanged extends DuelArenaEvent {
  const ArenaVisibilityChanged({required this.visible});

  final bool visible;

  @override
  List<Object?> get props => [visible];
}

/// A decoded Realtime broadcast.
final class ArenaServerEvent extends DuelArenaEvent {
  const ArenaServerEvent(this.event);

  final LobbyEvent event;

  @override
  List<Object?> get props => [event];
}

/// The 1-second ticker that drives every countdown on the arena.
final class ArenaTicked extends DuelArenaEvent {
  const ArenaTicked();
}

/// Retry after the snapshot failed to load.
final class ArenaRetryRequested extends DuelArenaEvent {
  const ArenaRetryRequested();
}

/// Post a challenge in [topic] (picked in the topic sheet).
final class ChallengeCreateRequested extends DuelArenaEvent {
  const ChallengeCreateRequested(this.topic);

  final DuelTopic topic;

  @override
  List<Object?> get props => [topic];
}

/// Cancel the viewer's own open challenge.
final class ChallengeCancelRequested extends DuelArenaEvent {
  const ChallengeCancelRequested();
}

/// Ask to join someone else's challenge.
final class JoinRequested extends DuelArenaEvent {
  const JoinRequested(this.challengeId);

  final String challengeId;

  @override
  List<Object?> get props => [challengeId];
}

/// Withdraw the viewer's request on [challengeId].
final class JoinWithdrawn extends DuelArenaEvent {
  const JoinWithdrawn(this.challengeId);

  final String challengeId;

  @override
  List<Object?> get props => [challengeId];
}

/// Accept the presented incoming request.
final class IncomingAccepted extends DuelArenaEvent {
  const IncomingAccepted();
}

/// Decline the presented incoming request.
final class IncomingDeclined extends DuelArenaEvent {
  const IncomingDeclined();
}

/// The presented request's 5-second window ran out (dispatched by the Bloc's
/// own ticker, once per request).
final class IncomingTimedOut extends DuelArenaEvent {
  const IncomingTimedOut();
}

/// The screen showed the current notice.
final class NoticeConsumed extends DuelArenaEvent {
  const NoticeConsumed();
}
