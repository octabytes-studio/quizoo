import 'dart:math';

import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';

/// The mocked daily-challenge endpoints.
///
/// There is no real daily *play* surface in this plan's scope (only S-27's
/// tab and S-28's result are in scope — see the plan's Scope section), so
/// [play] deals a plausible outcome directly rather than routing through
/// `features/quiz_play`, which knows nothing about the daily challenge.
class DailyApi extends MockApi {
  DailyApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  static const DailyChallenge _today = DailyChallenge(
    title: 'Mixed Bag',
    questionCount: 10,
    categoryCount: 10,
    secondsPerQuestion: 20,
    coinReward: 300,
    xpReward: 500,
    timeRemainingMinutes: 252,
    playedTodayCount: 18402,
    averageCorrect: 6,
    averageOutOf: 10,
  );

  static const StreakStatus _streak = StreakStatus(
    currentStreak: 12,
    freezesLeft: 2,
    days: [
      StreakDay(label: 'M', mark: StreakDayMark.done),
      StreakDay(label: 'T', mark: StreakDayMark.done),
      StreakDay(label: 'W', mark: StreakDayMark.today),
      StreakDay(label: 'T', mark: StreakDayMark.future),
      StreakDay(label: 'F', mark: StreakDayMark.future),
      StreakDay(label: 'S', mark: StreakDayMark.future),
      StreakDay(label: 'S', mark: StreakDayMark.reward),
    ],
    milestones: [
      Milestone(title: '14-day streak', daysAway: 2, rewardLabel: '1,000 🪙'),
      Milestone(
        title: '30-day streak',
        daysAway: 18,
        rewardLabel: '10 💎 + badge',
      ),
    ],
  );

  Future<DailyChallenge> fetchToday() => respond(() => _today);

  Future<StreakStatus> fetchStreak() => respond(() => _streak);

  Future<DailyPlayOutcome> play() => respond(() {
    final random = Random();
    // A plausible "did fine" spread rather than a uniform 0..10 — the bible's
    // own S-28 frame lands on 8/10.
    final correct = 6 + random.nextInt(5);
    final pattern = <bool>[
      for (var index = 0; index < _today.questionCount; index++)
        index < correct,
    ]..shuffle(random);
    return DailyPlayOutcome(correctCount: correct, answerPattern: pattern);
  });
}

/// What playing today's challenge produced — the raw material
/// [DailyRepository.playToday] turns into a [DailyResult].
class DailyPlayOutcome {
  const DailyPlayOutcome({
    required this.correctCount,
    required this.answerPattern,
  });

  final int correctCount;
  final List<bool> answerPattern;
}
