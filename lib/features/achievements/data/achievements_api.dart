import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:quizoo/l10n/app_localizations_en.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real achievements catalogue, over `achievements` left-joined
/// `user_achievements`.
///
/// Every locked badge gets a real "closest progress" hint (plan 014, Phase
/// 5): a dispatch over `criteria->>'type'` resolves each one, either by
/// reading the running counter `_evaluate_achievements` (functions
/// migration) already maintains in `user_achievements.progress` while a
/// badge is locked, or via a small live aggregate query for the handful of
/// criteria that are pure aggregates rather than stateful counters
/// (`category_three_star_sweep`, `category_coverage`,
/// `subcategory_level20_count`, `daily_streak`).
class AchievementsApi {
  AchievementsApi(this._client);

  final SupabaseClient _client;

  /// `nextActionLabel` copy is data-dependent (varies per badge, not per
  /// widget tree location), so it's resolved here rather than in a widget —
  /// this data layer has no `BuildContext` to hand to `AppLocalizations.of`,
  /// so the English delegate is used directly. Urdu ships as a deliberate
  /// proof-of-concept subset (l10n.yaml) that doesn't cover these keys
  /// either, so this matches what a context-based lookup would resolve to
  /// today regardless.
  static final AppLocalizationsEn _l10n = AppLocalizationsEn();

  Future<List<BadgeProgress>> fetchAll() async {
    try {
      final userId = _client.auth.currentUser?.id;
      final rows = await _client
          .from('achievements')
          .select(
            'id, name, emoji, description, gradient_from, gradient_to, '
            'category, rarity_percent, coin_reward, gem_reward, criteria',
          )
          .order('id');
      final unlockedRows = userId == null
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('user_achievements')
                .select('achievement_id, unlocked_at, progress')
                .eq('user_id', userId);
      final unlockedAt = {
        for (final row in unlockedRows)
          row['achievement_id'] as String: row['unlocked_at'] == null
              ? null
              : DateTime.parse(row['unlocked_at'] as String),
      };
      final progressByAchievement = {
        for (final row in unlockedRows)
          row['achievement_id'] as String:
              (row['progress'] as Map<String, dynamic>?) ??
              const <String, dynamic>{},
      };

      return [
        for (final row in rows)
          _progressFromRow(
            row,
            unlockedAt: unlockedAt[row['id']],
            closest: unlockedAt[row['id']] != null || userId == null
                ? null
                : await _closestProgressFor(
                    row,
                    userId,
                    progressByAchievement[row['id']] ?? const {},
                  ),
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

  /// Dispatches a locked badge's `criteria->>'type'` to the resolver that
  /// knows how to compute its "how close" hint. A resolver failure never
  /// takes down the whole grid — the hint is a nice-to-have, not
  /// load-bearing (matches the try/catch already around the category-king
  /// query this plan inherits).
  Future<_ClosestProgress?> _closestProgressFor(
    Map<String, dynamic> row,
    String userId,
    Map<String, dynamic> progress,
  ) async {
    final criteria = row['criteria'] as Map<String, dynamic>;
    try {
      switch (criteria['type'] as String?) {
        case 'level_flawless':
          return await _sharpshooterProgress(userId);
        case 'in_level_streak':
          return _fractionFromProgress(
            progress,
            key: 'best',
            target: (criteria['streak'] as num).toInt(),
            groupLabel: 'STREAK · CLOSEST',
            unitLabel: 'STREAK',
            nextActionLabel: _l10n.achievementHintOnFire,
          );
        case 'boss_clear':
          return _ClosestProgress(
            nextActionLabel: _l10n.achievementHintBossSlayer,
          );
        case 'category_flawless_count':
          return _fractionFromProgress(
            progress,
            key: 'count',
            target: (criteria['count'] as num).toInt(),
            groupLabel: 'FLAWLESS CLEARS · CLOSEST',
            unitLabel: 'FLAWLESS',
            nextActionLabel: _l10n.achievementHintBigBrain,
          );
        case 'category_three_star_sweep':
          return await _categoryKingProgress(userId);
        case 'cross_level_correct_streak':
          return _fractionFromProgress(
            progress,
            key: 'streak',
            target: (criteria['count'] as num).toInt(),
            groupLabel: 'CROSS-LEVEL STREAK · CLOSEST',
            unitLabel: 'CORRECT',
            nextActionLabel: _l10n.achievementHintCenturion,
          );
        case 'perfect_week':
          return _fractionFromProgress(
            progress,
            key: 'streak',
            target: 7,
            groupLabel: 'PERFECT DAYS · CLOSEST',
            unitLabel: 'DAYS',
            nextActionLabel: _l10n.achievementHintFlawless,
          );
        case 'category_coverage':
          return await _globetrotterProgress(userId);
        case 'midnight_streak':
          return _fractionFromProgress(
            progress,
            key: 'nights',
            target: (criteria['nights'] as num).toInt(),
            groupLabel: 'NIGHTS · CLOSEST',
            unitLabel: 'NIGHTS',
            nextActionLabel: _l10n.achievementHintNightOwl,
          );
        case 'avg_answer_seconds_under':
          final seconds = (criteria['seconds'] as num).toDouble();
          return _avgSecondsProgress(
            progress,
            targetSeconds: seconds,
            nextActionLabel: seconds <= 2
                ? _l10n.achievementHintRocket
                : _l10n.achievementHintQuickDraw,
          );
        case 'subcategory_level20_count':
          return await _scholarProgress(
            userId,
            (criteria['count'] as num).toInt(),
          );
        case 'duel_wins':
          return _fractionFromProgress(
            progress,
            key: 'wins',
            target: (criteria['count'] as num).toInt(),
            groupLabel: 'DUEL WINS · CLOSEST',
            unitLabel: 'WINS',
            nextActionLabel: _l10n.achievementHintDuelist,
          );
        case 'daily_streak':
          return await _weekWarriorProgress(
            userId,
            (criteria['days'] as num).toInt(),
          );
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// The generic "value / target" shape shared by every criterion whose
  /// running counter `_evaluate_achievements` already maintains in
  /// `user_achievements.progress` while locked — no extra round trip needed.
  _ClosestProgress? _fractionFromProgress(
    Map<String, dynamic> progress, {
    required String key,
    required int target,
    required String groupLabel,
    required String unitLabel,
    required String nextActionLabel,
  }) {
    final value = (progress[key] as num?)?.toInt() ?? 0;
    if (value <= 0 || target <= 0) return null;
    return _ClosestProgress(
      groupLabel: groupLabel,
      fractionLabel: '$value / $target $unitLabel',
      progress: (value / target).clamp(0, 1).toDouble(),
      nextActionLabel: nextActionLabel,
    );
  }

  /// `badge_sharpshooter`'s progress hint has no natural fraction in its
  /// criteria (no count) — this fills the same shape from the player's best
  /// (not-yet-flawless) finished attempt's own correct/total instead.
  Future<_ClosestProgress?> _sharpshooterProgress(String userId) async {
    final rows = await _client
        .from('level_attempts')
        .select('correct_count, answers')
        .eq('user_id', userId)
        .eq('ending', 'finished')
        .order('correct_count', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final correct = rows.first['correct_count'] as int? ?? 0;
    final total = (rows.first['answers'] as List).length;
    if (total == 0 || correct >= total) return null;
    return _ClosestProgress(
      groupLabel: 'BEST RUN · CLOSEST',
      fractionLabel: '$correct / $total CORRECT',
      progress: correct / total,
      nextActionLabel: _l10n.achievementHintSharpshooter,
    );
  }

  /// `badge_globetrotter`: distinct categories with at least one finished
  /// level attempt, vs. every active category.
  Future<_ClosestProgress?> _globetrotterProgress(String userId) async {
    final attemptRows = await _client
        .from('level_attempts')
        .select('subcategories!inner(category_id)')
        .eq('user_id', userId)
        .eq('ending', 'finished');
    final covered = <String>{
      for (final row in attemptRows)
        (row['subcategories'] as Map<String, dynamic>)['category_id'] as String,
    };
    final categoryRows = await _client
        .from('categories')
        .select('id')
        .eq('is_active', true);
    final total = categoryRows.length;
    if (total == 0 || covered.length >= total) return null;
    return _ClosestProgress(
      groupLabel: 'CATEGORIES · CLOSEST',
      fractionLabel: '${covered.length} / $total CATEGORIES',
      progress: covered.length / total,
      nextActionLabel: _l10n.achievementHintGlobetrotter,
    );
  }

  /// `badge_scholar`: distinct subcategories with a finished level-20
  /// attempt, vs. the criteria count.
  Future<_ClosestProgress?> _scholarProgress(String userId, int target) async {
    final rows = await _client
        .from('level_progress')
        .select('subcategory_id')
        .eq('user_id', userId)
        .eq('level', 20)
        .not('completed_at', 'is', null);
    final done = {
      for (final row in rows) row['subcategory_id'] as String,
    }.length;
    if (done <= 0 || done >= target) return null;
    return _ClosestProgress(
      groupLabel: 'LEVEL 20s · CLOSEST',
      fractionLabel: '$done / $target LEVEL 20s',
      progress: done / target,
      nextActionLabel: _l10n.achievementHintScholar,
    );
  }

  /// `badge_week_warrior`: `profiles.streak_days` vs. the criteria days —
  /// already authoritative, fetched fresh here rather than threaded in.
  Future<_ClosestProgress?> _weekWarriorProgress(
    String userId,
    int target,
  ) async {
    final row = await _client
        .from('profiles')
        .select('streak_days')
        .eq('id', userId)
        .maybeSingle();
    final days = row?['streak_days'] as int? ?? 0;
    if (days <= 0 || days >= target) return null;
    return _ClosestProgress(
      groupLabel: 'DAILY STREAK · CLOSEST',
      fractionLabel: '$days / $target DAYS',
      progress: days / target,
      nextActionLabel: _l10n.achievementHintWeekWarrior,
    );
  }

  /// `badge_quick_draw` / `badge_rocket`: the player's best-ever average
  /// seconds-per-correct-answer (a single finished attempt, per plan 014's
  /// per-badge design) against the criteria's target — lower is closer, so
  /// the bar fills as the average approaches the target from above.
  _ClosestProgress? _avgSecondsProgress(
    Map<String, dynamic> progress, {
    required double targetSeconds,
    required String nextActionLabel,
  }) {
    final best = (progress['bestAvgSeconds'] as num?)?.toDouble();
    if (best == null || best <= targetSeconds) return null;
    return _ClosestProgress(
      groupLabel: 'AVG SPEED · CLOSEST',
      fractionLabel:
          '${best.toStringAsFixed(1)}s · TARGET ${targetSeconds.toStringAsFixed(0)}s',
      progress: (targetSeconds / best).clamp(0, 1).toDouble(),
      nextActionLabel: nextActionLabel,
    );
  }

  /// The player's best-progressed category's "3-star every topic" tally —
  /// the one closest-progress branch this plan resolves via a dedicated
  /// query rather than a stored counter, since the hint needs the player's
  /// *closest, not-yet-swept* category, a different question than the
  /// evaluator's "is any category fully swept" check.
  Future<_ClosestProgress?> _categoryKingProgress(String userId) async {
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
      nextActionLabel: _l10n.achievementHintCategoryKing,
      nextSubcategoryId: subcategoryRows.isEmpty
          ? null
          : subcategoryRows.first['id'] as String,
    );
  }
}

class _ClosestProgress {
  const _ClosestProgress({
    required this.nextActionLabel,
    this.groupLabel,
    this.fractionLabel,
    this.progress,
    this.nextSubcategoryId,
  });

  final String? groupLabel;
  final String? fractionLabel;
  final double? progress;
  final String nextActionLabel;
  final String? nextSubcategoryId;
}
