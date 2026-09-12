import 'dart:math';

import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real daily-challenge endpoints, over Postgrest and the
/// `play_daily_challenge` RPC (functions migration).
///
/// [play] still synthesizes a plausible answer pattern rather than routing
/// through a real ten-question play surface (plan 006, Assumption #1(b)) —
/// there is no daily-play screen in the routed screens list yet, and adding
/// one is out of this plan's "no new screens" scope. The RPC itself is real:
/// it independently derives `streak_days`/coin payout from whatever pattern
/// it is handed, exactly as it would for a genuine answer log.
class DailyApi {
  DailyApi(this._client);

  final SupabaseClient _client;

  static const List<String> _weekdayLabels = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S', //
  ];

  Future<DailyChallenge> fetchToday({required String languageCode}) async {
    try {
      final today = _todayUtc();
      final row = await _client
          .from('daily_challenges')
          .select()
          .eq('challenge_date', today)
          .eq('language_code', languageCode)
          .maybeSingle();
      if (row == null) {
        throw const ApiException(
          'No daily challenge today',
          kind: ApiErrorKind.notFound,
          code: 'ERR_CONTENT_404',
        );
      }

      final attempts = await _client
          .from('daily_attempts')
          .select('correct_count, total_count')
          .eq('challenge_date', today)
          .eq('language_code', languageCode);

      final playedTodayCount = attempts.length;
      final averageCorrect = playedTodayCount == 0
          ? 0
          : (attempts.fold<int>(
                      0,
                      (sum, row) => sum + (row['correct_count'] as int),
                    ) /
                    playedTodayCount)
                .round();
      final averageOutOf = row['question_ids'] == null
          ? 10
          : (row['question_ids'] as List).length;

      final now = DateTime.now().toUtc();
      final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);

      return DailyChallenge(
        title: row['title'] as String,
        questionCount: (row['question_ids'] as List).length,
        categoryCount: (row['question_ids'] as List).length,
        secondsPerQuestion: row['seconds_per_question'] as int,
        coinReward: row['coin_reward'] as int,
        xpReward: row['xp_reward'] as int,
        timeRemainingMinutes: tomorrow.difference(now).inMinutes,
        playedTodayCount: playedTodayCount,
        averageCorrect: averageCorrect,
        averageOutOf: averageOutOf,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  Future<StreakStatus> fetchStreak() async {
    try {
      final userId = _requireUserId();
      final profileRow = await _client
          .from('profiles')
          .select('streak_days, streak_freezes')
          .eq('id', userId)
          .single();
      final streakDays = profileRow['streak_days'] as int;

      final milestoneRows = await _client
          .from('streak_milestones')
          .select()
          .gt('days', streakDays)
          .order('days')
          .limit(2);

      final now = DateTime.now().toUtc();
      final monday = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final weekDates = [
        for (var offset = 0; offset < 7; offset++)
          monday.add(Duration(days: offset)),
      ];
      final attemptRows = await _client
          .from('daily_attempts')
          .select('challenge_date')
          .eq('user_id', userId)
          .gte('challenge_date', _dateString(monday))
          .lte('challenge_date', _dateString(weekDates.last));
      final playedDates = {
        for (final row in attemptRows) row['challenge_date'] as String,
      };

      final days = [
        for (final (index, date) in weekDates.indexed)
          StreakDay(
            label: _weekdayLabels[index],
            mark: index == 6
                ? StreakDayMark.reward
                : playedDates.contains(_dateString(date))
                ? StreakDayMark.done
                : date.isAtSameMomentAs(
                    DateTime.utc(now.year, now.month, now.day),
                  )
                ? StreakDayMark.today
                : StreakDayMark.future,
          ),
      ];

      return StreakStatus(
        currentStreak: streakDays,
        freezesLeft: profileRow['streak_freezes'] as int,
        days: days,
        milestones: [
          for (final row in milestoneRows)
            Milestone(
              title: '${row['days']}-day streak',
              daysAway: (row['days'] as int) - streakDays,
              rewardLabel: row['reward_label'] as String,
            ),
        ],
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<DailyPlayOutcome> play({required String languageCode}) async {
    try {
      final today = await fetchToday(languageCode: languageCode);
      final random = Random();
      // A plausible "did fine" spread rather than a uniform 0..10 — the
      // bible's own S-28 frame lands on 8/10 (plan 006, Assumption #1(b): no
      // real ten-question play surface exists yet to generate a genuine
      // pattern from).
      final correct = 6 + random.nextInt(5);
      final pattern = <bool>[
        for (var index = 0; index < today.questionCount; index++)
          index < correct,
      ]..shuffle(random);

      final response = await _client.rpc<Map<String, dynamic>>(
        'play_daily_challenge',
        params: {'p_answer_pattern': pattern, 'p_language_code': languageCode},
      );

      final distribution = response['distribution'] as Map<String, dynamic>?;
      final counts = [
        for (var bucket = 0; bucket < 5; bucket++)
          (distribution?['$bucket'] as int?) ?? 0,
      ];
      final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);

      return DailyPlayOutcome(
        correctCount: response['correctCount'] as int,
        answerPattern: pattern,
        coinsEarned: response['coinsEarned'] as int,
        streakNow: response['streakNow'] as int,
        distributionPercents: [
          for (final count in counts)
            maxCount == 0 ? 0 : ((count / maxCount) * 100).round(),
        ],
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ApiException(
        'Not signed in',
        kind: ApiErrorKind.unauthorized,
      );
    }
    return userId;
  }

  static String _todayUtc() => _dateString(DateTime.now().toUtc());

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// What playing today's challenge produced — the raw material
/// [DailyRepository.playToday] turns into a [DailyResult].
class DailyPlayOutcome {
  const DailyPlayOutcome({
    required this.correctCount,
    required this.answerPattern,
    required this.coinsEarned,
    required this.streakNow,
    required this.distributionPercents,
  });

  final int correctCount;
  final List<bool> answerPattern;
  final int coinsEarned;
  final int streakNow;

  /// Five bucket heights, 0…100 — a genuinely global stat now, computed
  /// server-side from `daily_challenges.score_histogram`.
  final List<int> distributionPercents;
}
