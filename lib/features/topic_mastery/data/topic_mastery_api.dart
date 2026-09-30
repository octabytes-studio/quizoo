import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/models/difficulty_tier.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/topic_mastery/domain/tier_mastery.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Topic Mastered screen's one endpoint (plan 020) — read-only over
/// data `catalog`/`quiz_result` already write: `subcategories`,
/// `taxonomy_i18n`, `level_progress`, `level_attempts.created_at`. There is
/// no new backend for this screen.
///
/// Mirrors [CatalogApi]'s conventions: row → domain mapping happens here,
/// errors go through [ApiException.fromSupabase], and a missing topic throws
/// the same `ERR_CONTENT_404` shape. The taxonomy-name lookup duplicates
/// `CatalogApi._taxonomyNames`'s single-locale query rather than importing
/// across features (plan 008 already accepted this duplication).
class TopicMasteryApi {
  TopicMasteryApi(this._client, this._ladderConfig);

  final SupabaseClient _client;
  final LadderConfigRepository _ladderConfig;

  Future<TopicMastery> fetch({
    required String categoryId,
    required String subcategoryId,
    required String locale,
  }) async {
    try {
      await _ladderConfig.ensureLoaded();

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ApiException(
          'Not signed in',
          kind: ApiErrorKind.unauthorized,
        );
      }

      final subcategoryRow = await _client
          .from('subcategories')
          .select('emoji, plate_color, slug')
          .eq('id', subcategoryId)
          .maybeSingle();
      if (subcategoryRow == null) throw _contentNotFound('No such topic');

      final name = await _topicName(subcategoryId, locale);

      final progressRows = await _client
          .from('level_progress')
          .select('level, stars, best_score, completed_at')
          .eq('user_id', userId)
          .eq('subcategory_id', subcategoryId);

      final firstAttemptRow = await _client
          .from('level_attempts')
          .select('created_at')
          .eq('user_id', userId)
          .eq('subcategory_id', subcategoryId)
          .order('created_at')
          .limit(1)
          .maybeSingle();

      return aggregate(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        topicName: name ?? subcategoryRow['slug'] as String,
        emoji: subcategoryRow['emoji'] as String,
        plateColor: subcategoryRow['plate_color'] as String,
        progressRows: List<Map<String, dynamic>>.from(progressRows),
        startedAtRaw: firstAttemptRow?['created_at'] as String?,
        tiers: _tiersInOrder(),
        levelCount: _ladderConfig.totalLevels,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  // ------------------------------------------------------------- internals

  static ApiException _contentNotFound(String message) => ApiException(
    message,
    kind: ApiErrorKind.notFound,
    code: 'ERR_CONTENT_404',
  );

  Future<String?> _topicName(String subcategoryId, String locale) async {
    final row = await _client
        .from('taxonomy_i18n')
        .select('name')
        .eq('entity_id', subcategoryId)
        .eq('locale', locale)
        .maybeSingle();
    return row?['name'] as String?;
  }

  /// The ladder's tiers, in ladder order, read off the already-loaded
  /// [_ladderConfig] — no direct access to its tier list needed beyond the
  /// public [LadderConfigRepository.tierFor]/`totalLevels` it already
  /// exposes.
  List<DifficultyTier> _tiersInOrder() {
    final seen = <String, DifficultyTier>{};
    for (var level = 1; level <= _ladderConfig.totalLevels; level++) {
      final tier = _ladderConfig.tierFor(level);
      seen.putIfAbsent(tier.code, () => tier);
    }
    return seen.values.toList();
  }

  /// The Dart-side aggregation, factored out as a pure static helper (like
  /// `CatalogApi.resumeTopic`) so it is unit-tested directly without a
  /// Supabase client.
  static TopicMastery aggregate({
    required String categoryId,
    required String subcategoryId,
    required String topicName,
    required String emoji,
    required String plateColor,
    required List<Map<String, dynamic>> progressRows,
    required String? startedAtRaw,
    required List<DifficultyTier> tiers,
    required int levelCount,
  }) {
    var levelsCleared = 0;
    var starsEarned = 0;
    var perfectLevels = 0;
    var totalScore = 0;
    DateTime? masteredAt;
    final starsByLevel = <int, int>{};

    for (final row in progressRows) {
      final level = row['level'] as int;
      final stars = row['stars'] as int? ?? 0;
      final bestScore = row['best_score'] as int? ?? 0;
      final completedAtRaw = row['completed_at'] as String?;

      if (completedAtRaw != null) {
        levelsCleared++;
        starsByLevel[level] = stars;
        if (stars >= 3) perfectLevels++;
        if (level == levelCount) masteredAt = DateTime.parse(completedAtRaw);
      }
      starsEarned += stars;
      totalScore += bestScore;
    }

    final tierMasteries = [
      for (final tier in tiers)
        TierMastery(
          band: bandForTierCode(tier.code),
          starsEarned: [
            for (final entry in starsByLevel.entries)
              if (entry.key >= tier.levelStart && entry.key <= tier.levelEnd)
                entry.value,
          ].fold(0, (sum, stars) => sum + stars),
          starsAvailable: (tier.levelEnd - tier.levelStart + 1) * 3,
          secondsPerQuestion: tier.secondsPerQuestion,
        ),
    ];

    return TopicMastery(
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      topicName: topicName,
      emoji: emoji,
      plateColor: plateColor,
      levelsCleared: levelsCleared,
      levelCount: levelCount,
      starsEarned: starsEarned,
      perfectLevels: perfectLevels,
      totalScore: totalScore,
      tiers: tierMasteries,
      startedAt: startedAtRaw == null ? null : DateTime.parse(startedAtRaw),
      masteredAt: masteredAt,
    );
  }
}
