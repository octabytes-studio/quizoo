import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_challenge.freezed.dart';
part 'daily_challenge.g.dart';

/// S-27's "Mixed Bag" card — one challenge a day, identical for every player
/// worldwide, which is what makes [playedTodayCount]/[averageCorrect] a real
/// comparison rather than decoration.
@freezed
abstract class DailyChallenge with _$DailyChallenge {
  const factory DailyChallenge({
    required String title,
    required int questionCount,
    required int categoryCount,
    required int secondsPerQuestion,
    required int coinReward,
    required int xpReward,

    /// Minutes until today's window closes — stored as an int so the model
    /// stays JSON-round-trippable without a custom `Duration` converter.
    required int timeRemainingMinutes,
    required int playedTodayCount,
    required int averageCorrect,
    required int averageOutOf,
  }) = _DailyChallenge;

  const DailyChallenge._();

  factory DailyChallenge.fromJson(Map<String, dynamic> json) =>
      _$DailyChallengeFromJson(json);

  Duration get timeRemaining => Duration(minutes: timeRemainingMinutes);
}
