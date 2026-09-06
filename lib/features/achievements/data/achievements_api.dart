import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_badges.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';

/// The extra, achievements-specific payload for one badge id: its filter
/// category, and — for a locked badge — its closest-progress path.
class _Extra {
  const _Extra({
    required this.category,
    this.closestGroupLabel,
    this.closestFractionLabel,
    this.closestProgress,
    this.nextActionLabel,
    this.nextSubcategoryId,
    this.rewardCoins,
  });

  final BadgeCategory category;
  final String? closestGroupLabel;
  final String? closestFractionLabel;
  final double? closestProgress;
  final String? nextActionLabel;
  final String? nextSubcategoryId;
  final int? rewardCoins;
}

/// The mocked achievements catalogue.
///
/// Wraps [MockBadges] — shared with `features/profile` — with the
/// achievements-specific filter category and, for locked badges, the closest
/// qualifying path S-34 renders.
class AchievementsApi extends MockApi {
  AchievementsApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  static const Map<String, _Extra> _extras = {
    'badge_sharpshooter': _Extra(category: BadgeCategory.skill),
    'badge_night_owl': _Extra(category: BadgeCategory.streak),
    'badge_quick_draw': _Extra(category: BadgeCategory.skill),
    'badge_week_warrior': _Extra(category: BadgeCategory.streak),
    'badge_big_brain': _Extra(category: BadgeCategory.skill),
    'badge_category_king': _Extra(
      category: BadgeCategory.rare,
      closestGroupLabel: 'SPORTS · CLOSEST',
      closestFractionLabel: '3 / 8 TOPICS',
      closestProgress: 0.37,
      nextActionLabel: "Next up: Hockey — you're on Level 2 of 20.",
      nextSubcategoryId: 'sub_hockey',
      rewardCoins: 2000,
    ),
    'badge_centurion': _Extra(
      category: BadgeCategory.skill,
      closestGroupLabel: 'STREAK · CLOSEST',
      closestFractionLabel: '62 / 100 CORRECT',
      closestProgress: 0.62,
      nextActionLabel: 'Next up: keep your answer streak alive.',
      nextSubcategoryId: MockCatalog.footballId,
      rewardCoins: 1500,
    ),
    'badge_globetrotter': _Extra(
      category: BadgeCategory.social,
      closestGroupLabel: 'CATEGORIES · CLOSEST',
      closestFractionLabel: '4 / 14 CATEGORIES',
      closestProgress: 0.29,
      nextActionLabel: 'Next up: try Seerah.',
      nextSubcategoryId: 'sub_seerah',
      rewardCoins: 1200,
    ),
    'badge_duelist': _Extra(
      category: BadgeCategory.social,
      closestGroupLabel: 'DUELS · CLOSEST',
      closestFractionLabel: '2 / 10 WINS',
      closestProgress: 0.2,
      nextActionLabel: 'Next up: win a duel.',
      nextSubcategoryId: MockCatalog.footballId,
      rewardCoins: 1000,
    ),
    'badge_scholar': _Extra(
      category: BadgeCategory.skill,
      closestGroupLabel: 'MASTERY · CLOSEST',
      closestFractionLabel: '1 / 5 MAXED',
      closestProgress: 0.2,
      nextActionLabel: "Next up: Football — you're on Level 12 of 20.",
      nextSubcategoryId: MockCatalog.footballId,
      rewardCoins: 1800,
    ),
    'badge_rocket': _Extra(
      category: BadgeCategory.skill,
      closestGroupLabel: 'SPEED · CLOSEST',
      closestFractionLabel: '0 / 1 SUB-2S RUN',
      closestProgress: 0.4,
      nextActionLabel: 'Next up: answer 20 questions under 2s each.',
      nextSubcategoryId: MockCatalog.footballId,
      rewardCoins: 1000,
    ),
    'badge_flawless': _Extra(
      category: BadgeCategory.rare,
      closestGroupLabel: 'PERFECT · CLOSEST',
      closestFractionLabel: '4 / 7 DAYS',
      closestProgress: 0.57,
      nextActionLabel: "Next up: keep today's run perfect.",
      nextSubcategoryId: MockCatalog.footballId,
      rewardCoins: 2500,
    ),
  };

  static List<BadgeProgress> get _all => [
    for (final badge in MockBadges.all)
      if (_extras[badge.id] case final extra?)
        BadgeProgress(
          badge: badge,
          category: extra.category,
          closestGroupLabel: extra.closestGroupLabel,
          closestFractionLabel: extra.closestFractionLabel,
          closestProgress: extra.closestProgress,
          nextActionLabel: extra.nextActionLabel,
          nextSubcategoryId: extra.nextSubcategoryId,
          rewardCoins: extra.rewardCoins,
        ),
  ];

  Future<List<BadgeProgress>> fetchAll() => respond(() => _all);

  Future<BadgeProgress> fetchById(String badgeId) => respond(
    () => _all.firstWhere(
      (progress) => progress.badge.id == badgeId,
      orElse: () => _all.first,
    ),
  );
}
