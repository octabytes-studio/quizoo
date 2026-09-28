import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';

part 'live_duel_round_state.freezed.dart';
part 'live_duel_round_state.g.dart';

/// The current round of a live duel from the player's perspective
/// (`get_duel_state.round`).
///
/// [question] is only present once the round's start time is near — the
/// server withholds it earlier (plan 017, A2). Opponent data is limited to
/// "has locked" and timing; their choice never appears here.
@freezed
abstract class LiveDuelRoundState with _$LiveDuelRoundState {
  const factory LiveDuelRoundState({
    required int number,
    DateTime? startsAt,
    DateTime? deadline,
    @Default(false) bool myLocked,
    int? myChoice,
    int? myMs,
    @Default(false) bool opponentLocked,
    int? opponentMs,
    DuelQuestion? question,
  }) = _LiveDuelRoundState;

  factory LiveDuelRoundState.fromJson(Map<String, dynamic> json) =>
      _$LiveDuelRoundStateFromJson(json);
}
