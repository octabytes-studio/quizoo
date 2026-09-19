import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';

part 'duel_result.freezed.dart';
part 'duel_result.g.dart';

/// S-41 — the whole of a finished duel, victory or defeat rendered from the
/// same model (plan 004, Research findings: "one screen with two states").
@freezed
abstract class DuelResult with _$DuelResult {
  const factory DuelResult({
    required DuelOpponent opponent,
    required int playerRoundsWon,
    required int opponentRoundsWon,
    required double playerAverageAnswerSeconds,
    required double opponentAverageAnswerSeconds,
    required int eloBefore,
    required int eloAfter,
    required int rewardCoins,
    @Default([]) List<String> newlyEarnedBadgeIds,
  }) = _DuelResult;

  const DuelResult._();

  factory DuelResult.fromJson(Map<String, dynamic> json) =>
      _$DuelResultFromJson(json);

  bool get isVictory => playerRoundsWon > opponentRoundsWon;

  int get eloDelta => eloAfter - eloBefore;
}
