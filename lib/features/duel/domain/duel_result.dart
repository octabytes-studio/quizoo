import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

part 'duel_result.freezed.dart';
part 'duel_result.g.dart';

/// How a duel ended, from the player's perspective.
enum DuelEndReason { completed, opponentForfeited, youForfeited }

/// S-41 — the whole of a finished duel, victory or defeat rendered from the
/// same model (plan 004, Research findings: "one screen with two states").
///
/// Plan 017 adds the real [me] (no more mock avatar), the live-duel fields
/// ([duelId], [isBot] false, [isRanked], [endReason]) and the [topic], so
/// "Rematch"/"Find a new opponent" can stay in the same topic.
@freezed
abstract class DuelResult with _$DuelResult {
  const factory DuelResult({
    required DuelPlayer me,
    required DuelPlayer opponent,
    required int playerRoundsWon,
    required int opponentRoundsWon,
    required double playerAverageAnswerSeconds,
    required double opponentAverageAnswerSeconds,
    required int eloBefore,
    required int eloAfter,
    required int rewardCoins,
    @Default([]) List<String> newlyEarnedBadgeIds,
    String? duelId,
    @Default(true) bool isBot,
    DuelTopic? topic,
    @Default(true) bool isRanked,
    @Default(0) int xpEarned,
    @Default(DuelEndReason.completed) DuelEndReason endReason,
  }) = _DuelResult;

  const DuelResult._();

  factory DuelResult.fromJson(Map<String, dynamic> json) =>
      _$DuelResultFromJson(json);

  bool get isVictory => playerRoundsWon > opponentRoundsWon;

  bool get isDraw => playerRoundsWon == opponentRoundsWon;

  int get eloDelta => eloAfter - eloBefore;
}
