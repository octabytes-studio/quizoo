import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_scope.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/category_leaderboard_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/leaderboard_cubit.dart';

class _MockLeaderboardRepository extends Mock
    implements LeaderboardRepository {}

void main() {
  const roster = [
    LeaderboardEntry(
      rank: 1,
      playerId: 'p1',
      name: 'Danish M.',
      avatarEmoji: '🐯',
      score: 168000,
    ),
    LeaderboardEntry(
      rank: 2,
      playerId: 'p2',
      name: 'Ayesha K.',
      avatarEmoji: '🦊',
      score: 142000,
    ),
    LeaderboardEntry(
      rank: 3,
      playerId: 'p3',
      name: 'Zara N.',
      avatarEmoji: '🐨',
      score: 131000,
    ),
  ];
  const self = LeaderboardEntry(
    rank: 412,
    playerId: 'self',
    name: 'You',
    avatarEmoji: '🐼',
    score: 18420,
    isSelf: true,
    topPercent: 3,
  );

  group('LeaderboardCubit', () {
    late _MockLeaderboardRepository repository;

    setUpAll(() {
      registerFallbackValue(LeaderboardScope.global);
      registerFallbackValue(LeaderboardPeriod.week);
    });

    setUp(() => repository = _MockLeaderboardRepository());

    test('starts in its initial state', () {
      expect(LeaderboardCubit(repository).state, isA<LeaderboardInitial>());
    });

    blocTest<LeaderboardCubit, LeaderboardState>(
      'success path: loads the roster and the pinned self row',
      setUp: () {
        when(
          () => repository.fetchRoster(
            scope: any(named: 'scope'),
            period: any(named: 'period'),
          ),
        ).thenAnswer((_) async => roster);
        when(
          () => repository.fetchSelfEntry(
            scope: any(named: 'scope'),
            period: any(named: 'period'),
          ),
        ).thenAnswer((_) async => self);
      },
      build: () => LeaderboardCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<LeaderboardLoading>(),
        isA<LeaderboardLoaded>()
            .having((state) => state.roster, 'roster', roster)
            .having((state) => state.selfEntry, 'self', self)
            .having((state) => state.podium, 'podium', hasLength(3)),
      ],
    );

    blocTest<LeaderboardCubit, LeaderboardState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchRoster(
            scope: any(named: 'scope'),
            period: any(named: 'period'),
          ),
        ).thenThrow(const ApiException.network());
      },
      build: () => LeaderboardCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<LeaderboardLoading>(), isA<LeaderboardError>()],
    );

    blocTest<LeaderboardCubit, LeaderboardState>(
      'changing scope re-fetches with the new scope and the current period',
      setUp: () {
        when(
          () => repository.fetchRoster(
            scope: any(named: 'scope'),
            period: any(named: 'period'),
          ),
        ).thenAnswer((_) async => roster);
        when(
          () => repository.fetchSelfEntry(
            scope: any(named: 'scope'),
            period: any(named: 'period'),
          ),
        ).thenAnswer((_) async => self);
      },
      build: () => LeaderboardCubit(repository),
      act: (cubit) async {
        await cubit.load();
        cubit.changeScope(LeaderboardScope.friends);
      },
      verify: (_) {
        verify(
          () => repository.fetchRoster(
            scope: LeaderboardScope.friends,
            period: LeaderboardPeriod.week,
          ),
        ).called(1);
      },
    );
  });

  group('CategoryLeaderboardCubit', () {
    late _MockLeaderboardRepository repository;

    setUp(() => repository = _MockLeaderboardRepository());

    test('starts in its initial state', () {
      expect(
        CategoryLeaderboardCubit(repository).state,
        isA<CategoryLeaderboardInitial>(),
      );
    });

    blocTest<CategoryLeaderboardCubit, CategoryLeaderboardState>(
      'success path: loads the roster and the header stats',
      setUp: () {
        when(
          () => repository.fetchCategoryRoster(any()),
        ).thenAnswer((_) async => roster);
        when(
          () => repository.fetchCategoryHeader(any()),
        ).thenAnswer((_) async => (12, 1240, 'Pakistan'));
      },
      build: () => CategoryLeaderboardCubit(repository),
      act: (cubit) => cubit.load('sub_football'),
      expect: () => [
        isA<CategoryLeaderboardLoading>(),
        isA<CategoryLeaderboardLoaded>()
            .having((state) => state.roster, 'roster', roster)
            .having((state) => state.selfRank, 'selfRank', 12)
            .having((state) => state.pointsFromTop, 'pointsFromTop', 1240),
      ],
    );

    blocTest<CategoryLeaderboardCubit, CategoryLeaderboardState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchCategoryRoster(any()),
        ).thenThrow(const ApiException.network());
      },
      build: () => CategoryLeaderboardCubit(repository),
      act: (cubit) => cubit.load('sub_football'),
      expect: () => [
        isA<CategoryLeaderboardLoading>(),
        isA<CategoryLeaderboardError>(),
      ],
    );
  });
}
