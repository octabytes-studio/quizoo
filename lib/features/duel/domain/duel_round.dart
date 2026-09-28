import 'package:freezed_annotation/freezed_annotation.dart';

part 'duel_round.freezed.dart';
part 'duel_round.g.dart';

/// Who took a resolved round.
///
/// [draw] is real and reachable: both sides can answer wrong the same round,
/// and best-of-5's round tally then does not have to sum to 5 — which is
/// exactly why `DuelResult.isVictory` compares rounds won rather than
/// assuming they are complementary.
enum RoundOutcome { playerWon, opponentWon, draw }

/// One resolved round of a duel — only ever built **after** both sides have
/// answered, which is what makes it safe for the result screen and the
/// mid-duel history to read without re-deriving the withheld-correctness
/// rule themselves.
///
/// [correctIndex], [playerChoice] and [opponentChoice] are filled for live
/// duels (from `round_result`), so the history can show them; the bot duel
/// leaves them null.
@freezed
abstract class DuelRoundRecord with _$DuelRoundRecord {
  const factory DuelRoundRecord({
    required int roundNumber,
    required bool playerCorrect,
    required bool opponentCorrect,
    required int playerAnswerSeconds,
    required int opponentAnswerSeconds,
    required RoundOutcome outcome,
    int? correctIndex,
    int? playerChoice,
    int? opponentChoice,
  }) = _DuelRoundRecord;

  const DuelRoundRecord._();

  /// A live-duel round from the player's perspective, as `round_result` /
  /// `get_duel_state.history` describe it. A null choice or time is a
  /// timeout, which counts as the full [roundSeconds].
  factory DuelRoundRecord.live({
    required int roundNumber,
    required RoundOutcome outcome,
    required int correctIndex,
    required int roundSeconds,
    int? playerChoice,
    int? opponentChoice,
    int? playerMs,
    int? opponentMs,
  }) => DuelRoundRecord(
    roundNumber: roundNumber,
    playerCorrect: playerChoice != null && playerChoice == correctIndex,
    opponentCorrect: opponentChoice != null && opponentChoice == correctIndex,
    playerAnswerSeconds: _secondsFor(playerMs, roundSeconds),
    opponentAnswerSeconds: _secondsFor(opponentMs, roundSeconds),
    outcome: outcome,
    correctIndex: correctIndex,
    playerChoice: playerChoice,
    opponentChoice: opponentChoice,
  );

  factory DuelRoundRecord.fromJson(Map<String, dynamic> json) =>
      _$DuelRoundRecordFromJson(json);

  static int _secondsFor(int? ms, int roundSeconds) =>
      ms == null ? roundSeconds : (ms / 1000).round();
}
