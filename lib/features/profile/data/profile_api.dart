import 'package:quizoo/core/mock/mock_badges.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/features/profile/domain/category_accuracy.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/domain/stats_summary.dart';

/// The mocked profile and stats endpoints.
class ProfileApi extends MockApi {
  ProfileApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// The bible's own worked example counts a larger real badge catalogue
  /// than this fixture enumerates ("14 of 48 unlocked"); this reads the
  /// *actual* unlocked count from [MockBadges] instead of quoting that
  /// mismatched literal number.
  Future<ProfileSummary> fetchSummary() => respond(() {
    final football = MockCatalog.subcategoryById(MockCatalog.footballId);
    final seerah = MockCatalog.subcategoryById('sub_seerah');

    return ProfileSummary(
      username: 'waleed_pk',
      avatarEmoji: MockPlayer.avatarEmoji,
      cityLabel: '🇵🇰 Islamabad',
      joinedLabel: 'Joined Mar 2026',
      leagueEmoji: '🥇',
      leagueName: 'Gold League',
      dayStreak: MockPlayer.dayStreak,
      playerLevel: MockPlayer.playerLevel,
      rankTitle: MockPlayer.rankTitle,
      xpIntoLevel: MockPlayer.xpIntoLevel,
      xpToNextLevel: MockPlayer.xpToNextLevel,
      totalPoints: 18400,
      totalLevels: 247,
      accuracyPercent: 71,
      badgeCount: MockBadges.unlocked.length,
      recentBadges: MockBadges.unlocked.take(3).toList(),
      bestCategories: [
        BestCategoryEntry(
          subcategoryId: football.id,
          name: football.name,
          emoji: football.emoji,
          plateColor: football.plateColor,
          levelsCleared: 12,
          levelCount: football.levelCount,
          starsEarned: 28,
          accuracyPercent: 84,
        ),
        BestCategoryEntry(
          subcategoryId: seerah.id,
          name: 'Islam',
          emoji: '🕌',
          plateColor: seerah.plateColor,
          levelsCleared: 11,
          levelCount: seerah.levelCount,
          starsEarned: 26,
          accuracyPercent: 79,
        ),
      ],
    );
  });

  Future<StatsSummary> fetchStats() => respond(
    () => const StatsSummary(
      pointsPerDayPercents: [30, 58, 44, 82, 66, 100, 52],
      todayIndex: 5,
      categoryAccuracies: [
        CategoryAccuracy(
          categoryName: 'Sports',
          emoji: '⚽',
          accuracyPercent: 84,
        ),
        CategoryAccuracy(
          categoryName: 'Religion',
          emoji: '🕌',
          accuracyPercent: 79,
        ),
        CategoryAccuracy(
          categoryName: 'IQ & Logic',
          emoji: '🧠',
          accuracyPercent: 66,
        ),
        CategoryAccuracy(
          categoryName: 'Maths',
          emoji: '🔢',
          accuracyPercent: 48,
        ),
      ],
      fastestAverageSeconds: 1.2,
      fastestSubcategoryName: 'Flags of the World',
      fastestLevelNumber: 8,
      fastestPercentileLabel: 'Top 1%',
    ),
  );
}
