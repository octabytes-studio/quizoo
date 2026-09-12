import 'package:quizoo/features/daily/data/daily_api.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';

/// The only thing that talks to [DailyApi].
class DailyRepository {
  DailyRepository(this._api);

  final DailyApi _api;

  Future<DailyChallenge> fetchToday({required String languageCode}) =>
      _api.fetchToday(languageCode: languageCode);

  Future<StreakStatus> fetchStreak() => _api.fetchStreak();

  /// Plays today's challenge and turns the outcome into the [DailyResult]
  /// S-28 renders. `play_daily_challenge` (functions migration) is the
  /// authoritative source for coins/streak/distribution now — this no longer
  /// recomputes them client-side the way the mock's fixed `coinReward`/
  /// `mockDistributionPercents` did.
  Future<DailyResult> playToday({required String languageCode}) async {
    final outcome = await _api.play(languageCode: languageCode);

    return DailyResult(
      correctCount: outcome.correctCount,
      totalCount: outcome.answerPattern.length,
      betterThanPercent: DailyResult.betterThanPercentFor(
        outcome.correctCount,
        outcome.distributionPercents,
      ),
      distributionPercents: outcome.distributionPercents,
      highlightedBucketIndex: DailyResult.bucketIndexFor(outcome.correctCount),
      coinsEarned: outcome.coinsEarned,
      streakNow: outcome.streakNow,
      answerPattern: outcome.answerPattern,
    );
  }
}
