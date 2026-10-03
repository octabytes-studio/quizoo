import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/domain/category_detail.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Browse's real endpoints, over Postgrest.
///
/// `MockCatalog.levelId`/`parseLevelId` are kept — they are pure functions of
/// a level number, not fixture data, and the schema deliberately has no
/// `levels` table because of it. Band/seconds/boss come from the injected
/// [LadderConfigRepository] (fetched from `difficulty_tiers`/`app_settings`)
/// rather than a hardcoded mirror of the old SQL ladder functions.
class CatalogApi {
  CatalogApi(this._client, this._ladderConfig);

  final SupabaseClient _client;
  final LadderConfigRepository _ladderConfig;

  Future<CategoryDetail> fetchCategory(
    String categoryId, {
    required String locale,
  }) async {
    try {
      await _ladderConfig.ensureLoaded();
      final categoryRow = await _client
          .from('categories')
          .select()
          .eq('id', categoryId)
          .eq('language_code', locale)
          .maybeSingle();
      if (categoryRow == null) throw _contentNotFound('No such category');

      final subcategoryRows = await _client
          .from('subcategories')
          .select()
          .eq('category_id', categoryId)
          .order('sort_order');

      final subcategoryIds = [
        for (final row in subcategoryRows) row['id'] as String,
      ];
      final names = await _taxonomyNames(
        entityType: 'category',
        entityIds: [categoryId, ...subcategoryIds],
        locale: locale,
      );
      final progressByTopic = await _levelProgressBySubcategory(subcategoryIds);

      final category = _categoryFromRow(
        categoryRow,
        name: names[categoryId] ?? categoryRow['slug'] as String,
      );
      final topics = [
        for (final row in subcategoryRows)
          _subcategoryFromRow(
            row,
            name: names[row['id']] ?? row['slug'] as String,
            progress: progressByTopic[row['id']] ?? const _TopicProgress(),
          ),
      ];

      return CategoryDetail(
        category: category,
        topics: topics,
        playerCount: categoryRow['player_count'] as int? ?? 0,
        starsEarned: topics.fold(0, (sum, topic) => sum + topic.starsEarned),
        levelsCleared: topics.fold(
          0,
          (sum, topic) => sum + topic.levelsCleared,
        ),
        resumeTopic: resumeTopic(topics),
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  /// Plan 009, assumption 5: the topic with the most levels cleared among
  /// those with at least one, ties broken by list (`sort_order`) position.
  /// Null when nothing in the category has been started, which is what
  /// keeps S-07's resume card absent rather than an empty shell.
  ///
  /// Public and static, like [CatalogRepository.sorted]: a pure function of
  /// already-fetched topics, so it is unit-tested directly rather than
  /// through a mocked Supabase round trip.
  static Subcategory? resumeTopic(List<Subcategory> topics) {
    Subcategory? resume;
    for (final topic in topics) {
      if (topic.levelsCleared == 0) continue;
      if (resume == null || topic.levelsCleared > resume.levelsCleared) {
        resume = topic;
      }
    }
    return resume;
  }

  Future<LevelMap> fetchLevelMap({
    required String categoryId,
    required String subcategoryId,
    required String locale,
  }) async {
    try {
      await _ladderConfig.ensureLoaded();
      final categoryRow = await _client
          .from('categories')
          .select()
          .eq('id', categoryId)
          .eq('language_code', locale)
          .maybeSingle();
      final subcategoryRow = await _client
          .from('subcategories')
          .select()
          .eq('id', subcategoryId)
          .maybeSingle();
      if (categoryRow == null || subcategoryRow == null) {
        throw _contentNotFound('No such topic');
      }

      final names = await _taxonomyNames(
        entityType: 'category',
        entityIds: [categoryId, subcategoryId],
        locale: locale,
      );
      final progress = await _levelProgressBySubcategory([subcategoryId]);
      final category = _categoryFromRow(
        categoryRow,
        name: names[categoryId] ?? categoryRow['slug'] as String,
      );
      final subcategory = _subcategoryFromRow(
        subcategoryRow,
        name: names[subcategoryId] ?? subcategoryRow['slug'] as String,
        progress: progress[subcategoryId] ?? const _TopicProgress(),
      );

      final rank = await _rankFor(subcategoryId);

      return LevelMap(
        category: category,
        subcategory: subcategory,
        levels: _levelsFor(subcategory, progress[subcategoryId]?.perLevel),
        rank: rank,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  Future<Level> fetchLevel({
    required String subcategoryId,
    required int levelNumber,
  }) async {
    try {
      await _ladderConfig.ensureLoaded();
      final subcategoryRow = await _client
          .from('subcategories')
          .select()
          .eq('id', subcategoryId)
          .maybeSingle();
      if (subcategoryRow == null) throw _contentNotFound('No such topic');

      final progress = await _levelProgressBySubcategory([subcategoryId]);
      final subcategory = _subcategoryFromRow(
        subcategoryRow,
        name: subcategoryRow['slug'] as String,
        progress: progress[subcategoryId] ?? const _TopicProgress(),
      );
      return _levelsFor(
        subcategory,
        progress[subcategoryId]?.perLevel,
      ).firstWhere((level) => level.number == levelNumber);
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

  /// A single-locale lookup: a category or subcategory never has a
  /// `taxonomy_i18n` row in a locale other than its own `language_code`, now
  /// that each entity belongs to exactly one language.
  Future<Map<String, String>> _taxonomyNames({
    required String entityType,
    required List<String> entityIds,
    required String locale,
  }) async {
    if (entityIds.isEmpty) return const {};
    final rows = await _client
        .from('taxonomy_i18n')
        .select('entity_id, name')
        .inFilter('entity_id', entityIds)
        .eq('locale', locale);

    return {
      for (final row in rows) row['entity_id'] as String: row['name'] as String,
    };
  }

  /// One row per player per level in [subcategoryIds] — small enough (at
  /// most 30 rows per topic for the one player asking) to aggregate in Dart
  /// rather than a second round trip per topic.
  Future<Map<String, _TopicProgress>> _levelProgressBySubcategory(
    List<String> subcategoryIds,
  ) async {
    if (subcategoryIds.isEmpty) return const {};
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const {};

    final rows = await _client
        .from('level_progress')
        .select('subcategory_id, level, best_score, stars, completed_at')
        .eq('user_id', userId)
        .inFilter('subcategory_id', subcategoryIds);

    final byTopic = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      (byTopic[row['subcategory_id'] as String] ??= []).add(row);
    }

    return {
      for (final entry in byTopic.entries)
        entry.key: _TopicProgress.from(entry.value),
    };
  }

  /// `count(*) + 1` of players whose best single-level score in this topic
  /// beats the caller's own — 0 for a guest/player with nothing cleared yet
  /// (matching the mock's `levelsCleared == 0 ? 0 : ...`).
  Future<int> _rankFor(String subcategoryId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final rows = await _client
        .from('level_progress')
        .select('user_id, best_score')
        .eq('subcategory_id', subcategoryId);

    final bestByUser = <String, int>{};
    for (final row in rows) {
      final uid = row['user_id'] as String;
      final score = row['best_score'] as int;
      bestByUser[uid] = score > (bestByUser[uid] ?? 0)
          ? score
          : bestByUser[uid] ?? 0;
    }
    final myBest = bestByUser[userId] ?? 0;
    if (myBest == 0) return 0;

    final ahead = bestByUser.values.where((score) => score > myBest).length;
    return ahead + 1;
  }

  static Category _categoryFromRow(
    Map<String, dynamic> row, {
    required String name,
  }) => Category(
    id: row['id'] as String,
    name: name,
    emoji: row['emoji'] as String,
    colorFrom: row['color_from'] as String,
    colorTo: row['color_to'] as String,
    order: row['sort_order'] as int,
    subcategoryCount: row['subcategory_count'] as int? ?? 0,
    questionCount: row['question_count'] as int? ?? 0,
  );

  Subcategory _subcategoryFromRow(
    Map<String, dynamic> row, {
    required String name,
    required _TopicProgress progress,
  }) => Subcategory(
    id: row['id'] as String,
    categoryId: row['category_id'] as String,
    name: name,
    emoji: row['emoji'] as String,
    groupName: row['group_name'] as String? ?? '',
    plateColor: row['plate_color'] as String,
    questionCount: row['question_count'] as int? ?? 0,
    levelsCleared: progress.levelsCleared,
    levelCount: _ladderConfig.totalLevels,
    bestScore: progress.bestScore,
    starsEarned: progress.starsEarned,
    isNew: row['is_new'] as bool? ?? false,
    isLocked: row['is_locked'] as bool? ?? false,
  );

  List<Level> _levelsFor(
    Subcategory subcategory,
    Map<int, ({int bestScore, int stars})>? perLevel,
  ) {
    // The "current" node is the lowest level not yet cleared, not
    // `levelsCleared + 1` (plan 023, 6.2): `levelsCleared` is a *count*, so
    // once clears can be non-contiguous it can name an already-cleared level.
    final lowestUncleared = _lowestUncleared(subcategory, perLevel);
    return [
      for (var number = 1; number <= subcategory.levelCount; number++)
        _levelFor(subcategory, number, perLevel?[number], lowestUncleared),
    ];
  }

  /// The smallest level number with no completed `level_progress` row, or
  /// null when every level is cleared.
  int? _lowestUncleared(
    Subcategory subcategory,
    Map<int, ({int bestScore, int stars})>? perLevel,
  ) {
    for (var number = 1; number <= subcategory.levelCount; number++) {
      if (perLevel?[number] == null) return number;
    }
    return null;
  }

  Level _levelFor(
    Subcategory subcategory,
    int number,
    ({int bestScore, int stars})? cleared,
    int? lowestUncleared,
  ) {
    final isCleared = cleared != null;
    final isCurrent = !isCleared && number == lowestUncleared;
    return Level(
      id: MockCatalog.levelId(subcategory.id, number),
      subcategoryId: subcategory.id,
      number: number,
      difficultyBand: bandForTierCode(_ladderConfig.tierFor(number).code),
      secondsPerQuestion: _ladderConfig.secondsFor(number),
      questionCount: _ladderConfig.questionsFor(number),
      status: isCleared
          ? LevelStatus.done
          : isCurrent
          ? LevelStatus.current
          : LevelStatus.locked,
      isBoss: _ladderConfig.isBoss(number),
      starsEarned: cleared?.stars ?? 0,
      bestScore: cleared?.bestScore ?? 0,
    );
  }
}

/// One topic's aggregated `level_progress` — how many levels are cleared, the
/// best single-level score, total stars, and per-level detail for the level
/// map.
class _TopicProgress {
  const _TopicProgress({
    this.levelsCleared = 0,
    this.bestScore = 0,
    this.starsEarned = 0,
    this.perLevel = const {},
  });

  factory _TopicProgress.from(List<Map<String, dynamic>> rows) {
    var cleared = 0;
    var bestScore = 0;
    var stars = 0;
    final perLevel = <int, ({int bestScore, int stars})>{};

    for (final row in rows) {
      final level = row['level'] as int;
      final rowBestScore = row['best_score'] as int? ?? 0;
      final rowStars = row['stars'] as int? ?? 0;
      final isComplete = row['completed_at'] != null;

      if (isComplete) {
        cleared++;
        perLevel[level] = (bestScore: rowBestScore, stars: rowStars);
      }
      if (rowBestScore > bestScore) bestScore = rowBestScore;
      stars += rowStars;
    }

    return _TopicProgress(
      levelsCleared: cleared,
      bestScore: bestScore,
      starsEarned: stars,
      perLevel: perLevel,
    );
  }

  final int levelsCleared;
  final int bestScore;
  final int starsEarned;
  final Map<int, ({int bestScore, int stars})> perLevel;
}
