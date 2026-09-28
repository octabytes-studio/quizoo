part of 'duel_play_cubit.dart';

/// S-40's states (CLAUDE.md §3).
sealed class DuelPlayState extends Equatable {
  const DuelPlayState();

  @override
  List<Object?> get props => const [];
}

/// Loading the opponent's questions.
final class DuelPlayLoading extends DuelPlayState {
  const DuelPlayLoading();
}

final class DuelPlayFailed extends DuelPlayState {
  const DuelPlayFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}

/// A live round.
///
/// **[revealedOpponentAnswerIndex] and [revealedCorrectIndex] are the
/// withheld-correctness rule made concrete**: both are `null` on every
/// instance of this state until [isRevealed] flips true, which
/// `DuelPlayCubit` only ever does once both [playerHasAnswered] and
/// [opponentHasAnswered] are true. There is deliberately no other field
/// carrying either — [question] is a [DuelQuestion], which has no correct
/// index — so a widget has no way to read the verdict early because the data
/// is not there to read.
final class DuelPlayRound extends DuelPlayState {
  const DuelPlayRound({
    required this.me,
    required this.opponent,
    required this.roundNumber,
    required this.totalRounds,
    required this.question,
    required this.secondsRemaining,
    required this.secondsTotal,
    required this.history,
    this.playerAnswerIndex,
    this.playerHasAnswered = false,
    this.opponentHasAnswered = false,
    this.opponentAnswerSecondsElapsed,
    this.isRevealed = false,
    this.revealedOpponentAnswerIndex,
    this.revealedCorrectIndex,
    this.isAudioOn = false,
  });

  /// The last this-many seconds of an unanswered question wash the arena
  /// red and pulse the ring — play mode's S-14 danger state.
  static const int dangerThresholdSeconds = 5;

  final DuelPlayer me;
  final DuelPlayer opponent;

  /// 1-based.
  final int roundNumber;
  final int totalRounds;
  final DuelQuestion question;
  final int secondsRemaining;
  final int secondsTotal;

  /// Every round resolved so far this duel.
  final List<DuelRoundRecord> history;

  /// The player's own chosen option — safe to show immediately (an hourglass
  /// on it, per S-40), since it is the player's own choice, not a verdict.
  final int? playerAnswerIndex;
  final bool playerHasAnswered;
  final bool opponentHasAnswered;

  /// How long the opponent took to answer — safe to show as soon as it
  /// answers, since *timing* is not the correctness the withheld rule
  /// protects. `null` until [opponentHasAnswered].
  final int? opponentAnswerSecondsElapsed;

  /// True once both sides have answered and the round's colours may show.
  final bool isRevealed;

  /// The opponent's real answer — `null` until [isRevealed].
  final int? revealedOpponentAnswerIndex;

  /// The correct option — `null` until [isRevealed].
  final int? revealedCorrectIndex;

  /// The speaker toggle — question read-aloud and sound effects.
  final bool isAudioOn;

  /// The player is still answering and the clock is in its last seconds.
  bool get isDanger =>
      !playerHasAnswered &&
      !isRevealed &&
      secondsRemaining <= dangerThresholdSeconds;

  /// How long the player took, once locked in (the clock stops on a lock;
  /// a timeout counts the whole round).
  int? get playerAnswerSeconds =>
      playerHasAnswered ? secondsTotal - secondsRemaining : null;

  /// The player's points — one per correct answer.
  int get playerRoundsWon =>
      history.where((round) => round.playerCorrect).length;

  /// The bot's points — one per correct answer.
  int get opponentRoundsWon =>
      history.where((round) => round.opponentCorrect).length;

  DuelPlayRound copyWith({
    int? secondsRemaining,
    int? playerAnswerIndex,
    bool? playerHasAnswered,
    bool? opponentHasAnswered,
    int? opponentAnswerSecondsElapsed,
    bool? isRevealed,
    int? revealedOpponentAnswerIndex,
    int? revealedCorrectIndex,
    List<DuelRoundRecord>? history,
    bool? isAudioOn,
  }) => DuelPlayRound(
    me: me,
    opponent: opponent,
    roundNumber: roundNumber,
    totalRounds: totalRounds,
    question: question,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    secondsTotal: secondsTotal,
    history: history ?? this.history,
    playerAnswerIndex: playerAnswerIndex ?? this.playerAnswerIndex,
    playerHasAnswered: playerHasAnswered ?? this.playerHasAnswered,
    opponentHasAnswered: opponentHasAnswered ?? this.opponentHasAnswered,
    opponentAnswerSecondsElapsed:
        opponentAnswerSecondsElapsed ?? this.opponentAnswerSecondsElapsed,
    isRevealed: isRevealed ?? this.isRevealed,
    revealedOpponentAnswerIndex:
        revealedOpponentAnswerIndex ?? this.revealedOpponentAnswerIndex,
    revealedCorrectIndex: revealedCorrectIndex ?? this.revealedCorrectIndex,
    isAudioOn: isAudioOn ?? this.isAudioOn,
  );

  @override
  List<Object?> get props => [
    me,
    opponent,
    roundNumber,
    totalRounds,
    question,
    secondsRemaining,
    secondsTotal,
    history,
    playerAnswerIndex,
    playerHasAnswered,
    opponentHasAnswered,
    opponentAnswerSecondsElapsed,
    isRevealed,
    revealedOpponentAnswerIndex,
    revealedCorrectIndex,
    isAudioOn,
  ];
}

/// The duel is over.
final class DuelPlayEnded extends DuelPlayState {
  const DuelPlayEnded(this.result);

  final DuelResult result;

  @override
  List<Object?> get props => [result];
}
