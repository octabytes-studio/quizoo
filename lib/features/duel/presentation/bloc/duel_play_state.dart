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
/// **[revealedOpponentAnswerIndex] is the withheld-correctness rule made
/// concrete**: it is `null` on every instance of this state until
/// [isRevealed] flips true, which `DuelPlayCubit` only ever does once both
/// [playerHasAnswered] and [opponentHasAnswered] are true. There is
/// deliberately no other field carrying the opponent's chosen index — a
/// widget has no way to read it early because the data is not there to read.
final class DuelPlayRound extends DuelPlayState {
  const DuelPlayRound({
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
  });

  final DuelOpponent opponent;

  /// 1-based.
  final int roundNumber;
  final int totalRounds;
  final Question question;
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

  int get playerRoundsWon =>
      history.where((round) => round.outcome == RoundOutcome.playerWon).length;

  int get opponentRoundsWon => history
      .where((round) => round.outcome == RoundOutcome.opponentWon)
      .length;

  DuelPlayRound copyWith({
    int? secondsRemaining,
    int? playerAnswerIndex,
    bool? playerHasAnswered,
    bool? opponentHasAnswered,
    int? opponentAnswerSecondsElapsed,
    bool? isRevealed,
    int? revealedOpponentAnswerIndex,
    List<DuelRoundRecord>? history,
  }) => DuelPlayRound(
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
  );

  @override
  List<Object?> get props => [
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
  ];
}

/// The duel is over.
final class DuelPlayEnded extends DuelPlayState {
  const DuelPlayEnded(this.result);

  final DuelResult result;

  @override
  List<Object?> get props => [result];
}
