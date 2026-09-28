part of 'live_duel_bloc.dart';

/// S-40 (live) states (CLAUDE.md §3).
sealed class LiveDuelState extends Equatable {
  const LiveDuelState();

  @override
  List<Object?> get props => const [];
}

/// Loading the duel's snapshot.
final class LiveDuelConnecting extends LiveDuelState {
  const LiveDuelConnecting();
}

/// The VS intro — before round 1 starts. [startsAt] is null while the
/// opponent has not loaded yet ("Waiting for {name}…"), then round 1's
/// server start time, which the 3-2-1 counts down to.
final class LiveDuelIntro extends LiveDuelState {
  const LiveDuelIntro({
    required this.me,
    required this.opponent,
    required this.topic,
    required this.isRanked,
    required this.now,
    this.startsAt,
  });

  final DuelPlayer me;
  final DuelPlayer opponent;
  final DuelTopic topic;
  final bool isRanked;
  final DateTime? startsAt;

  /// The server-clock instant this state was built at.
  final DateTime now;

  /// Whole seconds left before round 1 (ceil'd), or null while waiting for
  /// the opponent.
  int? get secondsToStart {
    final start = startsAt;
    if (start == null) return null;
    final remainingMs = start.difference(now).inMilliseconds;
    return remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
  }

  @override
  List<Object?> get props => [me, opponent, topic, isRanked, startsAt, now];
}

/// Marks "leave this field as it is" in [LiveDuelRound.copyWith], so a
/// nullable field can also be set back to null.
const Object _keep = Object();

/// A live round.
///
/// **The withheld-correctness invariant**: [correctIndex] and
/// [opponentChoice] are null on every instance emitted before the round's
/// `round_result` arrives. The server guarantees it (neither is on the
/// client before then — `DuelQuestion` has no correct index), and this state
/// mirrors it: `LiveDuelBloc` only ever sets them from a `RoundResolved`.
final class LiveDuelRound extends LiveDuelState {
  const LiveDuelRound({
    required this.me,
    required this.opponent,
    required this.topic,
    required this.isRanked,
    required this.roundNumber,
    required this.totalRounds,
    required this.secondsRemaining,
    required this.secondsTotal,
    required this.myScore,
    required this.opponentScore,
    required this.history,
    this.question,
    this.myChoice,
    this.mySeconds,
    this.myLocked = false,
    this.opponentLocked = false,
    this.opponentSeconds,
    this.isRevealed = false,
    this.correctIndex,
    this.opponentChoice,
    this.opponentOnline = true,
    this.opponentOfflineSince,
    this.opponentReconnectSeconds,
    this.nextRoundAt,
    this.isAudioOn = false,
  });

  /// The last this-many seconds of an unanswered question wash the arena
  /// red and pulse the ring — play mode's S-14 danger state.
  static const int dangerThresholdSeconds = 5;

  final DuelPlayer me;
  final DuelPlayer opponent;
  final DuelTopic topic;
  final bool isRanked;

  /// 1-based.
  final int roundNumber;
  final int totalRounds;

  /// Null until the round's start, while it is being fetched ("Get ready…").
  final DuelQuestion? question;
  final int secondsRemaining;
  final int secondsTotal;

  /// The player's own pick — null on a timeout.
  final int? myChoice;

  /// How long the player took, once locked.
  final int? mySeconds;
  final bool myLocked;

  final bool opponentLocked;

  /// Timing only — never the opponent's choice (that is [opponentChoice],
  /// after the reveal).
  final int? opponentSeconds;

  /// True once `round_result` arrived and the colours may show.
  final bool isRevealed;

  /// Null until [isRevealed].
  final int? correctIndex;

  /// Null until [isRevealed] (and on the opponent's timeout).
  final int? opponentChoice;

  final int myScore;
  final int opponentScore;

  /// Every round resolved so far.
  final List<DuelRoundRecord> history;

  /// The opponent's Realtime Presence — a UI hint only.
  final bool opponentOnline;
  final DateTime? opponentOfflineSince;

  /// Whole seconds since [opponentOfflineSince], for the "reconnecting…" chip.
  final int? opponentReconnectSeconds;

  /// When the following round starts, once the server has scheduled it —
  /// the reveal stays up until then.
  final DateTime? nextRoundAt;

  /// The speaker toggle — question read-aloud and sound effects.
  final bool isAudioOn;

  /// The player is still answering and the clock is in its last seconds.
  bool get isDanger =>
      question != null &&
      !myLocked &&
      !isRevealed &&
      secondsRemaining <= dangerThresholdSeconds;

  LiveDuelRound copyWith({
    Object? question = _keep,
    int? secondsRemaining,
    Object? myChoice = _keep,
    Object? mySeconds = _keep,
    bool? myLocked,
    bool? opponentLocked,
    Object? opponentSeconds = _keep,
    bool? isRevealed,
    Object? correctIndex = _keep,
    Object? opponentChoice = _keep,
    int? myScore,
    int? opponentScore,
    List<DuelRoundRecord>? history,
    bool? opponentOnline,
    Object? opponentOfflineSince = _keep,
    Object? opponentReconnectSeconds = _keep,
    Object? nextRoundAt = _keep,
    bool? isAudioOn,
  }) => LiveDuelRound(
    me: me,
    opponent: opponent,
    topic: topic,
    isRanked: isRanked,
    roundNumber: roundNumber,
    totalRounds: totalRounds,
    secondsTotal: secondsTotal,
    question: identical(question, _keep)
        ? this.question
        : question as DuelQuestion?,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    myChoice: identical(myChoice, _keep) ? this.myChoice : myChoice as int?,
    mySeconds: identical(mySeconds, _keep) ? this.mySeconds : mySeconds as int?,
    myLocked: myLocked ?? this.myLocked,
    opponentLocked: opponentLocked ?? this.opponentLocked,
    opponentSeconds: identical(opponentSeconds, _keep)
        ? this.opponentSeconds
        : opponentSeconds as int?,
    isRevealed: isRevealed ?? this.isRevealed,
    correctIndex: identical(correctIndex, _keep)
        ? this.correctIndex
        : correctIndex as int?,
    opponentChoice: identical(opponentChoice, _keep)
        ? this.opponentChoice
        : opponentChoice as int?,
    myScore: myScore ?? this.myScore,
    opponentScore: opponentScore ?? this.opponentScore,
    history: history ?? this.history,
    opponentOnline: opponentOnline ?? this.opponentOnline,
    opponentOfflineSince: identical(opponentOfflineSince, _keep)
        ? this.opponentOfflineSince
        : opponentOfflineSince as DateTime?,
    opponentReconnectSeconds: identical(opponentReconnectSeconds, _keep)
        ? this.opponentReconnectSeconds
        : opponentReconnectSeconds as int?,
    nextRoundAt: identical(nextRoundAt, _keep)
        ? this.nextRoundAt
        : nextRoundAt as DateTime?,
    isAudioOn: isAudioOn ?? this.isAudioOn,
  );

  @override
  List<Object?> get props => [
    me,
    opponent,
    topic,
    isRanked,
    roundNumber,
    totalRounds,
    question,
    secondsRemaining,
    secondsTotal,
    myChoice,
    mySeconds,
    myLocked,
    opponentLocked,
    opponentSeconds,
    isRevealed,
    correctIndex,
    opponentChoice,
    myScore,
    opponentScore,
    history,
    opponentOnline,
    opponentOfflineSince,
    opponentReconnectSeconds,
    nextRoundAt,
    isAudioOn,
  ];
}

/// The duel is over and settled — the screen moves on to the result.
final class LiveDuelEnded extends LiveDuelState {
  const LiveDuelEnded(this.result);

  final DuelResult result;

  @override
  List<Object?> get props => [result];
}

/// The duel never started (a no-show, or someone left before round 1) —
/// no ELO, no payout.
///
/// [byMe] is true when this player's own "Leave" caused it, so the screen
/// does not tell them their opponent didn't show up.
final class LiveDuelAbandoned extends LiveDuelState {
  const LiveDuelAbandoned(this.cause, {this.byMe = false});

  final String cause;
  final bool byMe;

  @override
  List<Object?> get props => [cause, byMe];
}

/// The duel could not be loaded (not found, not a participant, offline).
final class LiveDuelFailed extends LiveDuelState {
  const LiveDuelFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.code, error.message];
}
