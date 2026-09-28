import 'package:equatable/equatable.dart';
import 'package:quizoo/features/duel/domain/duel_side.dart';
import 'package:quizoo/features/duel/domain/duel_side_result.dart';

/// Who took a round, in seat terms (`round_result.outcome`).
enum RoundSideOutcome { p1, p2, draw }

/// Where a rematch handshake stands (`rematch.status`).
enum RematchStatus { requested, declined, started }

/// A server-pushed event in one live duel's room channel (`duel:<id>`),
/// already decoded by `LiveDuelRepository` (plan 017, "Live duel protocol").
///
/// Payloads stay in seat terms (`p1`/`p2`); `LiveDuelBloc` maps them to
/// me/opponent with its own [DuelSide].
sealed class DuelRoomEvent extends Equatable {
  const DuelRoomEvent();

  @override
  List<Object?> get props => const [];
}

/// A round was scheduled. Carries **no question** (plan 017, A2) — the client
/// fetches it with `get_duel_round` at [startsAt].
final class RoundScheduled extends DuelRoomEvent {
  const RoundScheduled({
    required this.round,
    required this.startsAt,
    required this.deadline,
    required this.roundSeconds,
    required this.totalRounds,
  });

  final int round;
  final DateTime startsAt;
  final DateTime deadline;
  final int roundSeconds;
  final int totalRounds;

  @override
  List<Object?> get props => [
    round,
    startsAt,
    deadline,
    roundSeconds,
    totalRounds,
  ];
}

/// A player locked an answer. Never carries the choice — only timing.
final class AnswerLocked extends DuelRoomEvent {
  const AnswerLocked({required this.userId, required this.round, this.ms});

  final String userId;
  final int round;

  /// The server's effective answer time, or null for a timeout.
  final int? ms;

  @override
  List<Object?> get props => [userId, round, ms];
}

/// A round was resolved — the first moment either client learns the correct
/// answer or the opponent's choice (the withheld-correctness rule).
final class RoundResolved extends DuelRoomEvent {
  const RoundResolved({
    required this.round,
    required this.outcome,
    required this.correctIndex,
    required this.p1Rounds,
    required this.p2Rounds,
    this.p1Choice,
    this.p2Choice,
    this.p1Ms,
    this.p2Ms,
  });

  final int round;
  final RoundSideOutcome outcome;
  final int correctIndex;
  final int? p1Choice;
  final int? p2Choice;
  final int? p1Ms;
  final int? p2Ms;
  final int p1Rounds;
  final int p2Rounds;

  int? choiceOf(DuelSide side) => side == DuelSide.p1 ? p1Choice : p2Choice;

  int? msOf(DuelSide side) => side == DuelSide.p1 ? p1Ms : p2Ms;

  int roundsOf(DuelSide side) => side == DuelSide.p1 ? p1Rounds : p2Rounds;

  @override
  List<Object?> get props => [
    round,
    outcome,
    correctIndex,
    p1Choice,
    p2Choice,
    p1Ms,
    p2Ms,
    p1Rounds,
    p2Rounds,
  ];
}

/// The duel ended — completed, forfeited, or abandoned before it began.
///
/// [reason] is `'completed'`, `'forfeit'` or `'abandoned'`; [cause] explains
/// an abandonment (`'no_show'`, `'left_before_start'`, …). [p1]/[p2] are null
/// for an abandoned duel, which settles nothing.
final class DuelFinished extends DuelRoomEvent {
  const DuelFinished({
    required this.reason,
    required this.isRanked,
    required this.p1Rounds,
    required this.p2Rounds,
    this.cause,
    this.winnerId,
    this.forfeitedBy,
    this.p1AvgMs,
    this.p2AvgMs,
    this.p1,
    this.p2,
  });

  final String reason;
  final String? cause;
  final String? winnerId;
  final bool isRanked;
  final String? forfeitedBy;
  final int p1Rounds;
  final int p2Rounds;
  final double? p1AvgMs;
  final double? p2AvgMs;
  final DuelSideResult? p1;
  final DuelSideResult? p2;

  bool get isAbandoned => reason == 'abandoned';

  DuelSideResult? resultOf(DuelSide side) => side == DuelSide.p1 ? p1 : p2;

  int roundsOf(DuelSide side) => side == DuelSide.p1 ? p1Rounds : p2Rounds;

  double? avgMsOf(DuelSide side) => side == DuelSide.p1 ? p1AvgMs : p2AvgMs;

  @override
  List<Object?> get props => [
    reason,
    cause,
    winnerId,
    isRanked,
    forfeitedBy,
    p1Rounds,
    p2Rounds,
    p1AvgMs,
    p2AvgMs,
    p1,
    p2,
  ];
}

/// The rematch handshake on the result screen moved.
final class RematchUpdate extends DuelRoomEvent {
  const RematchUpdate({required this.status, this.requestedBy, this.duelId});

  final RematchStatus status;

  /// Who asked (`requested`) or who declined (`declined`).
  final String? requestedBy;

  /// The new duel's id (`started`).
  final String? duelId;

  @override
  List<Object?> get props => [status, requestedBy, duelId];
}

/// The room channel subscribed (`true`) or dropped (`false`).
final class RoomChannelStatusChanged extends DuelRoomEvent {
  const RoomChannelStatusChanged({required this.isLive});

  final bool isLive;

  @override
  List<Object?> get props => [isLive];
}

/// The opponent's Realtime Presence in the room appeared or vanished — a UI
/// hint only ("reconnecting…"); the server decides forfeits on heartbeats.
final class OpponentPresenceChanged extends DuelRoomEvent {
  const OpponentPresenceChanged({required this.online});

  final bool online;

  @override
  List<Object?> get props => [online];
}
