import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/achievements/data/achievements_repository.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:quizoo/features/achievements/presentation/bloc/achievements_cubit.dart';
import 'package:quizoo/features/achievements/presentation/bloc/badge_unlocked_cubit.dart';

class _MockAchievementsRepository extends Mock
    implements AchievementsRepository {}

void main() {
  const unlocked = BadgeProgress(
    category: BadgeCategory.skill,
    badge: AppBadge(
      id: 'badge_sharpshooter',
      name: 'Sharpshooter',
      emoji: '🎯',
      description: 'Finish a level with 20/20 correct answers.',
      gradientFrom: '#FFD84D',
      gradientTo: '#F0A500',
      isLocked: false,
    ),
  );
  const locked = BadgeProgress(
    category: BadgeCategory.rare,
    badge: AppBadge(
      id: 'badge_category_king',
      name: 'Category King',
      emoji: '👑',
      description: 'Reach Level 20 in every subcategory of a category.',
      gradientFrom: '#7B4DFF',
      gradientTo: '#2BB3FF',
    ),
  );
  const lockedWithHint = BadgeProgress(
    category: BadgeCategory.skill,
    badge: AppBadge(
      id: 'badge_on_fire',
      name: 'On Fire',
      emoji: '🔥',
      description: 'Answer 10 questions correctly in a row within one level.',
      gradientFrom: '#FF6B4D',
      gradientTo: '#FF3D00',
    ),
    closestGroupLabel: 'STREAK · CLOSEST',
    closestFractionLabel: '7 / 10 STREAK',
    closestProgress: 0.7,
    nextActionLabel: 'Keep answering correctly in a row without missing one.',
  );
  const all = [unlocked, locked, lockedWithHint];

  group('AchievementsCubit', () {
    late _MockAchievementsRepository repository;

    setUp(() => repository = _MockAchievementsRepository());

    test('starts in its initial state', () {
      expect(AchievementsCubit(repository).state, isA<AchievementsInitial>());
    });

    blocTest<AchievementsCubit, AchievementsState>(
      'success path: loads the full badge set',
      setUp: () {
        when(() => repository.fetchAll()).thenAnswer((_) async => all);
      },
      build: () => AchievementsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AchievementsLoading>(),
        isA<AchievementsLoaded>()
            .having((state) => state.all, 'all', all)
            .having((state) => state.unlockedCount, 'unlockedCount', 1),
      ],
    );

    blocTest<AchievementsCubit, AchievementsState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchAll(),
        ).thenThrow(const ApiException.network());
      },
      build: () => AchievementsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<AchievementsLoading>(), isA<AchievementsError>()],
    );

    blocTest<AchievementsCubit, AchievementsState>(
      'a locked badge other than category_king still carries a real '
      'closest-progress hint (plan 014, Phase 5)',
      setUp: () {
        when(() => repository.fetchAll()).thenAnswer((_) async => all);
      },
      build: () => AchievementsCubit(repository),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final state = cubit.state as AchievementsLoaded;
        final onFire = state.all.firstWhere(
          (progress) => progress.badge.id == 'badge_on_fire',
        );
        expect(onFire.closestGroupLabel, 'STREAK · CLOSEST');
        expect(onFire.closestFractionLabel, '7 / 10 STREAK');
        expect(onFire.closestProgress, 0.7);
        expect(onFire.nextActionLabel, isNotNull);
      },
    );

    blocTest<AchievementsCubit, AchievementsState>(
      'a filter narrows the visible grid to its own category',
      setUp: () {
        when(() => repository.fetchAll()).thenAnswer((_) async => all);
      },
      build: () => AchievementsCubit(repository),
      act: (cubit) async {
        await cubit.load();
        cubit.selectFilter(BadgeCategory.rare);
      },
      verify: (cubit) {
        final state = cubit.state as AchievementsLoaded;
        expect(state.visible, [locked]);
      },
    );
  });

  group('BadgeUnlockedCubit', () {
    late _MockAchievementsRepository repository;

    setUp(() => repository = _MockAchievementsRepository());

    test('starts by loading', () {
      expect(BadgeUnlockedCubit(repository).state, isA<BadgeUnlockedLoading>());
    });

    blocTest<BadgeUnlockedCubit, BadgeUnlockedState>(
      'success path: loads the celebrated badge',
      setUp: () {
        when(
          () => repository.fetchById('badge_sharpshooter'),
        ).thenAnswer((_) async => unlocked);
      },
      build: () => BadgeUnlockedCubit(repository),
      act: (cubit) => cubit.load('badge_sharpshooter'),
      expect: () => [
        isA<BadgeUnlockedLoading>(),
        isA<BadgeUnlockedLoaded>().having(
          (state) => state.progress,
          'progress',
          unlocked,
        ),
      ],
    );

    blocTest<BadgeUnlockedCubit, BadgeUnlockedState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchById(any()),
        ).thenThrow(const ApiException.network());
      },
      build: () => BadgeUnlockedCubit(repository),
      act: (cubit) => cubit.load('badge_sharpshooter'),
      expect: () => [isA<BadgeUnlockedLoading>(), isA<BadgeUnlockedError>()],
    );
  });
}
