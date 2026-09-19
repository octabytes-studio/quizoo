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

  /// Scores the player's real answer pattern and turns the outcome into the
  /// [DailyResult] S-28 renders. `play_daily_challenge` (functions
  /// migration) is the authoritative source for coins/streak/distribution —
  /// this never recomputes them client-side.
  Future<DailyResult> playToday({
    required String languageCode,
    required List<bool> answerPattern,
  }) async {
    final outcome = await _api.play(
      languageCode: languageCode,
      answerPattern: answerPattern,
    );

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
