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
@freezed
abstract class DuelRoundRecord with _$DuelRoundRecord {
  const factory DuelRoundRecord({
    required int roundNumber,
    required bool playerCorrect,
    required bool opponentCorrect,
    required int playerAnswerSeconds,
    required int opponentAnswerSeconds,
    required RoundOutcome outcome,
  }) = _DuelRoundRecord;

  factory DuelRoundRecord.fromJson(Map<String, dynamic> json) =>
      _$DuelRoundRecordFromJson(json);
}
