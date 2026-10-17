import 'package:quizoo/core/format/country_directory.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/models/xp_curve.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/orphaned_profile_recovery.dart';
import 'package:quizoo/features/profile/domain/category_accuracy.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/domain/stats_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real profile and stats endpoints, over Postgrest.
///
/// A brand-new account has zero `level_attempts` — every aggregate below
/// degrades to zero/empty rather than dividing by zero, and [fetchStats]
/// falls back to a single placeholder row so `StatsSummary.weakest` (which
/// `.reduce`s the list) never throws on a fresh account (plan 005 Phase 4's
/// own "check every division-by-zero path" note).
class ProfileApi {
  ProfileApi(this._client);

  final SupabaseClient _client;

  static const Map<String, String> _leagueEmojis = {
    'bronze': '🥉',
    'silver': '🥈',
    'gold': '🥇',
    'platinum': '💎',
    'diamond': '👑',
  };

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<ProfileSummary> fetchSummary() async {
    try {
      return await _fetchSummary();
    } catch (error) {
      // The account behind the current session was deleted server-side
      // (`profiles` row gone, `auth.uid()` still valid) — recover a fresh
      // anonymous session and retry once as a guest, rather than showing a
      // content error for an identity that no longer exists. Checked before
      // any mapping, since [recoverFromOrphanedProfile] needs the raw
      // `PostgrestException`, not the `ApiException` it gets wrapped into
      // below.
      if (await recoverFromOrphanedProfile(_client, error)) {
        return _fetchSummary();
      }
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  Future<ProfileSummary> _fetchSummary() async {
    final userId = _requireUserId();

    final profileRow = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final rankTitleRow = await _client
        .from('rank_titles')
        .select('title')
        .lte('min_level', profileRow['player_level'] as int)
        .gte('max_level', profileRow['player_level'] as int)
        .maybeSingle();

    final scoreRows = await _client
        .from('score_events')
        .select('points')
        .eq('user_id', userId);
    final totalPoints = scoreRows.fold<int>(
      0,
      (sum, row) => sum + (row['points'] as int),
    );

    final finishedAttempts = await _client
        .from('level_attempts')
        .select('correct_count')
        .eq('user_id', userId)
        .eq('ending', 'finished');
    final accuracyPercent = _accuracyFromAttempts(finishedAttempts);

    final clearedRows = await _client
        .from('level_progress')
        .select('subcategory_id, stars, best_score')
        .eq('user_id', userId)
        .not('completed_at', 'is', null);
    final totalLevels = clearedRows.length;

    final achievementRows = await _client
        .from('user_achievements')
        .select('achievement_id, unlocked_at, achievements(*)')
        .eq('user_id', userId)
        .not('unlocked_at', 'is', null)
        .order('unlocked_at', ascending: false);
    final badges = [
      for (final row in achievementRows) _badgeFromJoinedRow(row),
    ];

    final bestCategories = await _bestCategories(userId, clearedRows);

    final countryCode = profileRow['country_code'] as String?;
    final city = profileRow['city'] as String?;
    final createdAt = DateTime.parse(profileRow['created_at'] as String);
    final xpProgress = XpCurve.progressFor(profileRow['xp'] as int? ?? 0);

    return ProfileSummary(
      username: profileRow['username'] as String? ?? '',
      avatarEmoji: profileRow['avatar_key'] as String? ?? '🐼',
      cityLabel: countryCode == null
          ? ''
          : '${CountryDirectory.flagFor(countryCode)} ${city ?? ''}'.trim(),
      joinedLabel:
          'Joined ${_monthNames[createdAt.month - 1]} ${createdAt.year}',
      leagueEmoji: _leagueEmojis[profileRow['league']] ?? '🥉',
      leagueName: '${_capitalize(profileRow['league'] as String)} League',
      dayStreak: profileRow['streak_days'] as int? ?? 0,
      playerLevel: profileRow['player_level'] as int,
      rankTitle: rankTitleRow?['title'] as String? ?? '',
      xpIntoLevel: xpProgress.xpIntoLevel,
      xpToNextLevel: xpProgress.xpToNextLevel,
      totalPoints: totalPoints,
      totalLevels: totalLevels,
      accuracyPercent: accuracyPercent,
      badgeCount: badges.length,
      recentBadges: badges.take(3).toList(),
      bestCategories: bestCategories,
      // `profiles.is_pro` — written only by the server (plan 023).
      isPro: profileRow['is_pro'] as bool? ?? false,
    );
  }

  Future<StatsSummary> fetchStats() async {
    try {
      return await _fetchStats();
    } catch (error) {
      // See fetchSummary's identical branch above.
      if (await recoverFromOrphanedProfile(_client, error)) {
        return _fetchStats();
      }
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  Future<StatsSummary> _fetchStats() async {
    final userId = _requireUserId();
    final now = DateTime.now().toUtc();
    final weekStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final weekRows = await _client
        .from('score_events')
        .select('points, occurred_at')
        .eq('user_id', userId)
        .gte('occurred_at', weekStart.toIso8601String());

    final perDay = List<int>.filled(7, 0);
    for (final row in weekRows) {
      final occurredAt = DateTime.parse(row['occurred_at'] as String).toUtc();
      final dayIndex = occurredAt.weekday - 1;
      perDay[dayIndex] += row['points'] as int;
    }
    final maxDay = perDay.fold<int>(0, (a, b) => a > b ? a : b);
    final pointsPerDayPercents = [
      for (final points in perDay)
        maxDay == 0 ? 0 : ((points / maxDay) * 100).round(),
    ];

    final attemptRows = await _client
        .from('level_attempts')
        .select(
          'subcategory_id, level, correct_count, answers, seconds_per_question',
        )
        .eq('user_id', userId)
        .eq('ending', 'finished');

    final categoryAccuracies = await _categoryAccuracies(attemptRows);
    final fastest = _fastestLevel(attemptRows);
    final fastestSubcategoryName = fastest == null
        ? ''
        : (await _client
                      .from('subcategories')
                      .select('slug')
                      .eq('id', fastest.subcategoryId)
                      .maybeSingle())?['slug']
                  as String? ??
              '';

    return StatsSummary(
      pointsPerDayPercents: pointsPerDayPercents,
      todayIndex: now.weekday - 1,
      categoryAccuracies: categoryAccuracies.isEmpty
          ? [await _placeholderCategoryAccuracy()]
          : categoryAccuracies,
      fastestAverageSeconds: fastest?.averageSeconds ?? 0,
      fastestSubcategoryName: fastestSubcategoryName,
      fastestLevelNumber: fastest?.levelNumber ?? 0,
      // No percentile-ranking infrastructure yet (plan 005, Design
      // overview) — a fixed placeholder until enough `avg_answer_ms` data
      // exists to rank against.
      fastestPercentileLabel: 'Top 10%',
    );
  }

  // ------------------------------------------------------------- internals

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

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  static int _accuracyFromAttempts(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return 0;
    // A finished attempt always answers all twenty questions — the game
    // never lets a player finish without reaching the last one.
    const questionsPerAttempt = 20;
    final correct = rows.fold<int>(
      0,
      (sum, row) => sum + (row['correct_count'] as int? ?? 0),
    );
    return ((correct / (rows.length * questionsPerAttempt)) * 100).round();
  }

  static AppBadge _badgeFromJoinedRow(Map<String, dynamic> row) {
    final achievement = row['achievements'] as Map<String, dynamic>;
    return AppBadge(
      id: achievement['id'] as String,
      name: achievement['name'] as String,
      emoji: achievement['emoji'] as String,
      description: achievement['description'] as String,
      gradientFrom: achievement['gradient_from'] as String,
      gradientTo: achievement['gradient_to'] as String,
      isLocked: false,
      rarityPercent: (achievement['rarity_percent'] as num).toDouble(),
      unlockedAt: DateTime.parse(row['unlocked_at'] as String),
    );
  }

  Future<List<BestCategoryEntry>> _bestCategories(
    String userId,
    List<Map<String, dynamic>> clearedRows,
  ) async {
    final bySubcategory = <String, ({int stars, int cleared, int bestScore})>{};
    for (final row in clearedRows) {
      final id = row['subcategory_id'] as String;
      final current = bySubcategory[id] ?? (stars: 0, cleared: 0, bestScore: 0);
      final score = row['best_score'] as int? ?? 0;
      bySubcategory[id] = (
        stars: current.stars + (row['stars'] as int? ?? 0),
        cleared: current.cleared + 1,
        bestScore: score > current.bestScore ? score : current.bestScore,
      );
    }

    final topIds = bySubcategory.keys.toList()
      ..sort(
        (a, b) => bySubcategory[b]!.stars.compareTo(bySubcategory[a]!.stars),
      );
    final entries = <BestCategoryEntry>[];

    for (final id in topIds.take(2)) {
      final subcategoryRow = await _client
          .from('subcategories')
          .select('slug, emoji, plate_color, category_id')
          .eq('id', id)
          .maybeSingle();
      if (subcategoryRow == null) continue;

      final attempts = await _client
          .from('level_attempts')
          .select('correct_count')
          .eq('user_id', userId)
          .eq('subcategory_id', id)
          .eq('ending', 'finished');

      entries.add(
        BestCategoryEntry(
          subcategoryId: id,
          categoryId: subcategoryRow['category_id'] as String,
          name: subcategoryRow['slug'] as String,
          emoji: subcategoryRow['emoji'] as String,
          plateColor: subcategoryRow['plate_color'] as String,
          levelsCleared: bySubcategory[id]!.cleared,
          levelCount: LadderConfigRepository.fallbackTotalLevels,
          starsEarned: bySubcategory[id]!.stars,
          accuracyPercent: _accuracyFromAttempts(attempts),
        ),
      );
    }
    return entries;
  }

  Future<List<CategoryAccuracy>> _categoryAccuracies(
    List<Map<String, dynamic>> attemptRows,
  ) async {
    if (attemptRows.isEmpty) return const [];

    final subcategoryIds = {
      for (final row in attemptRows) row['subcategory_id'] as String,
    }.toList();
    final subcategoryRows = await _client
        .from('subcategories')
        .select('id, category_id')
        .inFilter('id', subcategoryIds);
    final categoryIdBySubcategory = {
      for (final row in subcategoryRows)
        row['id'] as String: row['category_id'] as String,
    };

    final byCategory = <String, List<Map<String, dynamic>>>{};
    for (final row in attemptRows) {
      final categoryId = categoryIdBySubcategory[row['subcategory_id']];
      if (categoryId == null) continue;
      (byCategory[categoryId] ??= []).add(row);
    }
    if (byCategory.isEmpty) return const [];

    final categoryRows = await _client
        .from('categories')
        .select('id, emoji, slug')
        .inFilter('id', byCategory.keys.toList());
    final namesById = await _taxonomyNames(byCategory.keys.toList());

    return [
      for (final row in categoryRows)
        CategoryAccuracy(
          categoryName: namesById[row['id']] ?? row['slug'] as String,
          emoji: row['emoji'] as String,
          accuracyPercent: _accuracyFromAttempts(byCategory[row['id']]!),
        ),
    ];
  }

  Future<Map<String, String>> _taxonomyNames(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return const {};
    final rows = await _client
        .from('taxonomy_i18n')
        .select('entity_id, name')
        .eq('entity_type', 'category')
        .eq('locale', 'en')
        .inFilter('entity_id', categoryIds);
    return {
      for (final row in rows) row['entity_id'] as String: row['name'] as String,
    };
  }

  Future<CategoryAccuracy> _placeholderCategoryAccuracy() async {
    final row = await _client
        .from('categories')
        .select('emoji, slug')
        .order('sort_order')
        .limit(1)
        .maybeSingle();
    return CategoryAccuracy(
      categoryName: row?['slug'] as String? ?? 'General',
      emoji: row?['emoji'] as String? ?? '🌍',
      accuracyPercent: 0,
    );
  }

  static ({double averageSeconds, String subcategoryId, int levelNumber})?
  _fastestLevel(List<Map<String, dynamic>> attemptRows) {
    ({double averageSeconds, String subcategoryId, int levelNumber})? fastest;

    for (final row in attemptRows) {
      final level = row['level'] as int;
      final secondsPerQuestion =
          (row['seconds_per_question'] as int?) ??
          MockCatalog.secondsFor(level);
      final answers = (row['answers'] as List).cast<Map<String, dynamic>>();
      final answered = [
        for (final answer in answers)
          if (answer['action'] == 'answered') answer,
      ];
      if (answered.isEmpty) continue;

      final totalElapsed = answered.fold<int>(
        0,
        (sum, answer) =>
            sum + (secondsPerQuestion - (answer['secondsLeft'] as int? ?? 0)),
      );
      final average = totalElapsed / answered.length;

      if (fastest == null || average < fastest.averageSeconds) {
        fastest = (
          averageSeconds: average,
          subcategoryId: row['subcategory_id'] as String,
          levelNumber: level,
        );
      }
    }

    return fastest;
  }
}
