import 'package:quizoo/features/daily/data/daily_api.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';

/// The only thing that talks to [DailyApi].
class DailyRepository {
  DailyRepository(this._api);

  final DailyApi _api;

  Future<DailyChallenge> fetchToday() => _api.fetchToday();

  Future<StreakStatus> fetchStreak() => _api.fetchStreak();

  /// Plays today's challenge and turns the raw outcome into the [DailyResult]
  /// S-28 renders — bucket highlight, "better than X%" and the new streak all
  /// derived from the score rather than re-typed as separate mock numbers.
  Future<DailyResult> playToday() async {
    final outcome = await _api.play();
    final streak = await _api.fetchStreak();

    return DailyResult(
      correctCount: outcome.correctCount,
      totalCount: outcome.answerPattern.length,
      betterThanPercent: DailyResult.betterThanPercentFor(outcome.correctCount),
      distributionPercents: DailyResult.mockDistributionPercents,
      highlightedBucketIndex: DailyResult.bucketIndexFor(outcome.correctCount),
      coinsEarned: outcome.correctCount > 0 ? 300 : 0,
      streakNow: outcome.correctCount > 0
          ? streak.currentStreak + 1
          : streak.currentStreak,
      answerPattern: outcome.answerPattern,
    );
  }
}
