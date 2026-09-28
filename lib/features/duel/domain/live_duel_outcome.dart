import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_duel_outcome.freezed.dart';
part 'live_duel_outcome.g.dart';

/// A finished live duel's settlement from the player's perspective
/// (`get_duel_state.result`) — what a client that missed the `duel_end`
/// broadcast (backgrounded, reconnecting) rebuilds the result screen from.
@freezed
abstract class LiveDuelOutcome with _$LiveDuelOutcome {
  const factory LiveDuelOutcome({
    required String reason,
    @Default(false) bool won,
    @Default(false) bool draw,
    @Default(0) int eloBefore,
    @Default(0) int eloAfter,
    @Default(0) int coins,
    @Default(0) int xp,
    @Default([]) List<String> badgeIds,
    @Default(false) bool opponentForfeited,
    @Default(false) bool youForfeited,
    double? myAvgMs,
    double? opponentAvgMs,
    String? cause,
  }) = _LiveDuelOutcome;

  factory LiveDuelOutcome.fromJson(Map<String, dynamic> json) =>
      _$LiveDuelOutcomeFromJson(json);
}
