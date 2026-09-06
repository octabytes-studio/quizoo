import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/category_accuracy.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/domain/stats_summary.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quizoo/features/profile/presentation/bloc/stats_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  const summary = ProfileSummary(
    username: 'waleed_pk',
    avatarEmoji: '🐼',
    cityLabel: '🇵🇰 Islamabad',
    joinedLabel: 'Joined Mar 2026',
    leagueEmoji: '🥇',
    leagueName: 'Gold League',
    dayStreak: 12,
    playerLevel: 12,
    rankTitle: 'Curious Mind',
    xpIntoLevel: 1240,
    xpToNextLevel: 1500,
    totalPoints: 18400,
    totalLevels: 247,
    accuracyPercent: 71,
    badgeCount: 5,
    recentBadges: [],
    bestCategories: [],
  );

  group('ProfileCubit', () {
    late _MockProfileRepository repository;

    setUp(() => repository = _MockProfileRepository());

    test('starts in its initial state', () {
      expect(ProfileCubit(repository).state, isA<ProfileInitial>());
    });

    blocTest<ProfileCubit, ProfileState>(
      'success path: loads the profile summary',
      setUp: () {
        when(() => repository.fetchSummary()).thenAnswer((_) async => summary);
      },
      build: () => ProfileCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
          (state) => state.summary,
          'summary',
          summary,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchSummary(),
        ).thenThrow(const ApiException.network());
      },
      build: () => ProfileCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<ProfileLoading>(), isA<ProfileError>()],
    );
  });

  group('StatsCubit', () {
    late _MockProfileRepository repository;

    const stats = StatsSummary(
      pointsPerDayPercents: [30, 58, 44, 82, 66, 100, 52],
      todayIndex: 5,
      categoryAccuracies: [
        CategoryAccuracy(
          categoryName: 'Sports',
          emoji: '⚽',
          accuracyPercent: 84,
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
    );

    setUp(() => repository = _MockProfileRepository());

    test('starts in its initial state', () {
      expect(StatsCubit(repository).state, isA<StatsInitial>());
    });

    blocTest<StatsCubit, StatsState>(
      'success path: loads the stats summary',
      setUp: () {
        when(() => repository.fetchStats()).thenAnswer((_) async => stats);
      },
      build: () => StatsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<StatsLoading>(),
        isA<StatsLoaded>().having((state) => state.stats, 'stats', stats),
      ],
    );

    blocTest<StatsCubit, StatsState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchStats(),
        ).thenThrow(const ApiException.network());
      },
      build: () => StatsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<StatsLoading>(), isA<StatsError>()],
    );

    test('the weakest category is computed, not hardcoded', () {
      expect(stats.weakest.categoryName, 'Maths');

      const reordered = StatsSummary(
        pointsPerDayPercents: [30, 58, 44, 82, 66, 100, 52],
        todayIndex: 5,
        categoryAccuracies: [
          CategoryAccuracy(
            categoryName: 'Maths',
            emoji: '🔢',
            accuracyPercent: 90,
          ),
          CategoryAccuracy(
            categoryName: 'IQ',
            emoji: '🧠',
            accuracyPercent: 40,
          ),
        ],
        fastestAverageSeconds: 1.2,
        fastestSubcategoryName: 'Flags of the World',
        fastestLevelNumber: 8,
        fastestPercentileLabel: 'Top 1%',
      );
      expect(reordered.weakest.categoryName, 'IQ');
    });
  });
}
