import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/player_currency.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home's real endpoints, over Postgrest.
class HomeApi {
  HomeApi(this._client);

  final SupabaseClient _client;

  /// The taxonomy, wallet and in-progress level.
  ///
  /// [isSignedIn] decides the two things that actually differ between S-04
  /// and S-05: whether the wallet/daily/continue slots are populated at all
  /// — kept exactly as `HomeCubit` already passes it (`session is
  /// SessionSignedIn`), so a guest's real anonymous wallet stays hidden the
  /// same way the mock's did, and Home's layout does not change.
  ///
  /// [languageCode] only matters inside the `isSignedIn` branch, to pick the
  /// caller's own language's row out of `daily_challenges` — since that
  /// table now carries one row per (date, language) rather than one global
  /// row per date (plan 007's daily-rollover fix), an unfiltered lookup by
  /// date alone would match more than one row. [search] calls this with
  /// `isSignedIn: false`, so its `languageCode` is never actually read.
  Future<HomeContent> fetchCachedHome({
    required bool isSignedIn,
    required String languageCode,
  }) async {
    try {
      final categoryRows = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .eq('language_code', languageCode)
          .order('sort_order');

      final categoryIds = [for (final row in categoryRows) row['id'] as String];

      // Subcategories have no language column of their own — they inherit it
      // purely via `category_id → categories.language_code` — so constraining
      // by the already-filtered parent categories is the only correct filter
      // (plan 008, Design overview). An empty `categoryIds` trivially has zero
      // subcategories, and `inFilter` with an empty list behaves
      // inconsistently across Postgrest versions, so that case skips the
      // query entirely rather than relying on it.
      final subcategoryRows = categoryIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('subcategories')
                .select()
                .eq('is_active', true)
                .inFilter('category_id', categoryIds)
                .order('sort_order');

      final subcategoryIds = [
        for (final row in subcategoryRows) row['id'] as String,
      ];

      final names = await _taxonomyNames(
        entityIds: [...categoryIds, ...subcategoryIds],
        locale: languageCode,
      );

      final progress = isSignedIn
          ? await _levelsClearedBySubcategory(subcategoryIds)
          : const <String, int>{};

      final categories = [
        for (final row in categoryRows)
          _categoryFromRow(
            row,
            name: names[row['id']] ?? row['slug'] as String,
          ),
      ];
      final subcategories = [
        for (final row in subcategoryRows)
          _subcategoryFromRow(
            row,
            name: names[row['id']] ?? row['slug'] as String,
            levelsCleared: progress[row['id']] ?? 0,
          ),
      ];

      PlayerCurrency? currency;
      DailyChallengePreview? daily;
      ContinueEntry? continueEntry;

      if (isSignedIn) {
        final userId = _client.auth.currentUser!.id;

        final profileRow = await _client
            .from('profiles')
            .select('coins, gems, hearts, max_hearts, hearts_updated_at')
            .eq('id', userId)
            .single();
        currency = _currencyFromRow(profileRow);

        final today = DateTime.now().toUtc();
        final todayDate =
            '${today.year.toString().padLeft(4, '0')}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
        final dailyRow = await _client
            .from('daily_challenges')
            .select('question_ids')
            .eq('challenge_date', todayDate)
            .eq('language_code', languageCode)
            .maybeSingle();
        if (dailyRow != null) {
          final tomorrow = DateTime.utc(today.year, today.month, today.day + 1);
          daily = DailyChallengePreview(
            questionCount: (dailyRow['question_ids'] as List).length,
            minutesRemaining: tomorrow.difference(today).inMinutes,
          );
        }

        final continueRow = await _client
            .from('level_progress')
            .select('subcategory_id, level, best_score')
            .eq('user_id', userId)
            .filter('completed_at', 'is', null)
            .order('last_played_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (continueRow != null) {
          final subcategory = subcategories
              .where((s) => s.id == continueRow['subcategory_id'])
              .firstOrNull;
          if (subcategory != null) {
            continueEntry = ContinueEntry(
              subcategoryId: subcategory.id,
              subcategoryName: subcategory.name,
              emoji: subcategory.emoji,
              plateColor: subcategory.plateColor,
              levelNumber: continueRow['level'] as int,
              points: continueRow['best_score'] as int? ?? 0,
            );
          }
        }
      }

      return HomeContent(
        categories: categories,
        subcategories: subcategories,
        currency: currency,
        daily: daily,
        continueEntry: continueEntry,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  /// The merchandised rail, which arrives after the first paint.
  Future<List<PopularQuiz>> fetchPopularRail() async {
    try {
      final rows = await _client
          .from('featured_quizzes')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      final now = DateTime.now().toUtc();
      return [
        for (final row in rows)
          if (row['ends_at'] == null ||
              DateTime.parse(row['ends_at'] as String).isAfter(now))
            PopularQuiz(
              id: row['id'] as String,
              subcategoryId: row['subcategory_id'] as String,
              title: row['title'] as String,
              emoji: row['emoji'] as String,
              colorFrom: row['color_from'] as String,
              colorTo: row['color_to'] as String,
              playedCount: row['played_count'] as int? ?? 0,
              isHot: row['is_hot'] as bool? ?? false,
            ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Everything Search filters over — the taxonomy, not a server query. The
  /// mock literally reuses the popular rail for this; kept identical.
  Future<List<PopularQuiz>> fetchTrendingSearches() => fetchPopularRail();

  // ------------------------------------------------------------- internals

  /// A single-locale lookup: a category or subcategory never has a
  /// `taxonomy_i18n` row in a locale other than its own `language_code`, now
  /// that each entity belongs to exactly one language (matches
  /// `CatalogApi._taxonomyNames`).
  Future<Map<String, String>> _taxonomyNames({
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

  Future<Map<String, int>> _levelsClearedBySubcategory(
    List<String> subcategoryIds,
  ) async {
    if (subcategoryIds.isEmpty) return const {};
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const {};

    final rows = await _client
        .from('level_progress')
        .select('subcategory_id')
        .eq('user_id', userId)
        .not('completed_at', 'is', null)
        .inFilter('subcategory_id', subcategoryIds);

    final counts = <String, int>{};
    for (final row in rows) {
      final id = row['subcategory_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
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
    isNew: false,
    isLocked: false,
  );

  static Subcategory _subcategoryFromRow(
    Map<String, dynamic> row, {
    required String name,
    required int levelsCleared,
  }) => Subcategory(
    id: row['id'] as String,
    categoryId: row['category_id'] as String,
    name: name,
    emoji: row['emoji'] as String,
    groupName: row['group_name'] as String? ?? '',
    plateColor: row['plate_color'] as String,
    questionCount: row['question_count'] as int? ?? 0,
    levelsCleared: levelsCleared,
    isNew: row['is_new'] as bool? ?? false,
    isLocked: row['is_locked'] as bool? ?? false,
  );

  static PlayerCurrency _currencyFromRow(Map<String, dynamic> row) {
    final heartsUpdatedAt = DateTime.parse(row['hearts_updated_at'] as String);
    final hearts = row['hearts'] as int;
    final maxHearts = row['max_hearts'] as int;
    return PlayerCurrency(
      coins: row['coins'] as int,
      gems: row['gems'] as int,
      hearts: hearts,
      maxHearts: maxHearts,
      // Lazily-settled server value: the next heart arrives 20 minutes after
      // the last spend, per `_settle_hearts` in the functions migration.
      heartRefillAt: hearts >= maxHearts
          ? null
          : heartsUpdatedAt.add(const Duration(minutes: 20)),
    );
  }
}
