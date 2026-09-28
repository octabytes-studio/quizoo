import 'package:equatable/equatable.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/domain/outgoing_join_request.dart';

/// A server-pushed change to the Duel Arena — one Realtime broadcast on the
/// lobby or the player's own inbox channel, already decoded by
/// `DuelArenaRepository` (plan 017, "Snapshot + deltas").
sealed class LobbyEvent extends Equatable {
  const LobbyEvent();

  @override
  List<Object?> get props => const [];
}

/// A challenge appeared, or changed (Away/Live, matched → "In progress").
final class ChallengeUpserted extends LobbyEvent {
  const ChallengeUpserted(this.challenge);

  final DuelChallenge challenge;

  @override
  List<Object?> get props => [challenge];
}

/// A challenge was cancelled, expired or finished, and deleted server-side.
final class ChallengeRemoved extends LobbyEvent {
  const ChallengeRemoved(this.challengeId);

  final String challengeId;

  @override
  List<Object?> get props => [challengeId];
}

/// Someone's request reached the head of the viewer's own challenge queue.
final class IncomingRequestPresented extends LobbyEvent {
  const IncomingRequestPresented(this.request);

  final IncomingJoinRequest request;

  @override
  List<Object?> get props => [request];
}

/// The presented request is gone — withdrawn, expired, or the requester left.
final class IncomingRequestCleared extends LobbyEvent {
  const IncomingRequestCleared({required this.requestId, required this.reason});

  final String requestId;
  final String reason;

  @override
  List<Object?> get props => [requestId, reason];
}

/// One of the viewer's own outgoing requests changed status.
final class OutgoingRequestChanged extends LobbyEvent {
  const OutgoingRequestChanged(this.request);

  final OutgoingJoinRequest request;

  @override
  List<Object?> get props => [request];
}

/// The server created a duel with the viewer in it (accept, pairing or
/// rematch) — time to open it.
final class DuelStarted extends LobbyEvent {
  const DuelStarted(this.duelId);

  final String duelId;

  @override
  List<Object?> get props => [duelId];
}

/// The lobby/inbox channel subscribed (`true`) or dropped (`false`). A drop
/// followed by a re-subscribe means messages may have been missed, so the
/// arena re-fetches its snapshot.
final class LobbyChannelStatusChanged extends LobbyEvent {
  const LobbyChannelStatusChanged({required this.isLive});

  final bool isLive;

  @override
  List<Object?> get props => [isLive];
}

/// How many players are on the arena screen right now (Realtime Presence).
final class LobbyPresenceChanged extends LobbyEvent {
  const LobbyPresenceChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}
