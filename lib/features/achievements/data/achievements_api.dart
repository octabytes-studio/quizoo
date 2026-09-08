import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real achievements catalogue, over `achievements` left-joined
/// `user_achievements`.
///
/// The mock's per-badge "closest progress" `_extras` map (twelve bespoke
/// entries) is only partly ported: plan 006's Design overview itself admits
/// each locked badge's "how close" line needs its own query shape, and
/// resolving all twelve is implementation work the plan explicitly leaves
/// open rather than fully specifying. This rewrite computes it for
/// `badge_category_king` (the one the plan works through as its example) and
/// leaves the rest null — a locked badge simply renders without a closest-
/// progress line rather than a fabricated one, which every field here being
/// nullable already supports. Revisit per-badge as product priority dictates.
class AchievementsApi {
  AchievementsApi(this._client);

  final SupabaseClient _client;

  Future<List<BadgeProgress>> fetchAll() async {
    try {
      final userId = _client.auth.currentUser?.id;
      final rows = await _client.from('achievements').select().order('id');
      final unlockedRows = userId == null
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('user_achievements')
                .select('achievement_id, unlocked_at')
                .eq('user_id', userId);
      final unlockedAt = {
        for (final row in unlockedRows)
          row['achievement_id'] as String: row['unlocked_at'] == null
              ? null
              : DateTime.parse(row['unlocked_at'] as String),
      };

      final categoryKing = await _categoryKingProgress(userId);

      return [
        for (final row in rows)
          _progressFromRow(
            row,
            unlockedAt: unlockedAt[row['id']],
            closest: row['id'] == 'badge_category_king' ? categoryKing : null,
          ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<BadgeProgress> fetchById(String badgeId) async {
    try {
      final all = await fetchAll();
      return all.firstWhere(
        (progress) => progress.badge.id == badgeId,
        orElse: () => all.first,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  BadgeProgress _progressFromRow(
    Map<String, dynamic> row, {
    required DateTime? unlockedAt,
    _ClosestProgress? closest,
  }) => BadgeProgress(
    badge: AppBadge(
      id: row['id'] as String,
      name: row['name'] as String,
      emoji: row['emoji'] as String,
      description: row['description'] as String,
      gradientFrom: row['gradient_from'] as String,
      gradientTo: row['gradient_to'] as String,
      isLocked: unlockedAt == null,
      rarityPercent: (row['rarity_percent'] as num).toDouble(),
      unlockedAt: unlockedAt,
    ),
    category: BadgeCategory.values.firstWhere(
      (value) => value.name == row['category'],
      orElse: () => BadgeCategory.skill,
    ),
    closestGroupLabel: closest?.groupLabel,
    closestFractionLabel: closest?.fractionLabel,
    closestProgress: closest?.progress,
    nextActionLabel: closest?.nextActionLabel,
    nextSubcategoryId: closest?.nextSubcategoryId,
    rewardCoins: row['coin_reward'] as int? ?? 0,
  );

  /// The player's best-progressed category's "3-star every topic" tally —
  /// the one closest-progress branch this plan resolves (Design overview's
  /// worked example), picking whichever category the player has cleared the
  /// most 3-star topics in as the "closest" one, matching the mock's own
  /// fixed choice of Sports/Football in spirit.
  Future<_ClosestProgress?> _categoryKingProgress(String? userId) async {
    if (userId == null) return null;
    try {
      final threeStarRows = await _client
          .from('level_progress')
          .select('subcategory_id, subcategories!inner(category_id)')
          .eq('user_id', userId)
          .eq('level', 20)
          .eq('stars', 3);

      final byCategory = <String, int>{};
      for (final row in threeStarRows) {
        final categoryId =
            (row['subcategories'] as Map<String, dynamic>)['category_id']
                as String;
        byCategory[categoryId] = (byCategory[categoryId] ?? 0) + 1;
      }
      if (byCategory.isEmpty) return null;

      final bestCategoryId = byCategory.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      final subcategoryRows = await _client
          .from('subcategories')
          .select('id, slug')
          .eq('category_id', bestCategoryId);
      final total = subcategoryRows.length;
      final done = byCategory[bestCategoryId]!;
      if (total == 0) return null;

      final categoryRow = await _client
          .from('categories')
          .select('slug')
          .eq('id', bestCategoryId)
          .maybeSingle();

      return _ClosestProgress(
        groupLabel:
            '${(categoryRow?['slug'] as String? ?? '').toUpperCase()}'
            ' · CLOSEST',
        fractionLabel: '$done / $total TOPICS',
        progress: done / total,
        nextActionLabel: 'Keep clearing topics in this category with 3 stars.',
        nextSubcategoryId: subcategoryRows.isEmpty
            ? null
            : subcategoryRows.first['id'] as String,
      );
    } catch (_) {
      // The closest-progress line is a nice-to-have, not load-bearing —
      // a failure here should not take down the whole achievements grid.
      return null;
    }
  }
}

class _ClosestProgress {
  const _ClosestProgress({
    required this.groupLabel,
    required this.fractionLabel,
    required this.progress,
    required this.nextActionLabel,
    required this.nextSubcategoryId,
  });

  final String groupLabel;
  final String fractionLabel;
  final double progress;
  final String nextActionLabel;
  final String? nextSubcategoryId;
}
