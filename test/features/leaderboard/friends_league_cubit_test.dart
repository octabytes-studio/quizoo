import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/friend.dart';
import 'package:quizoo/features/leaderboard/domain/league_standing.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/friends_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/league_cubit.dart';

class _MockLeaderboardRepository extends Mock
    implements LeaderboardRepository {}

void main() {
  const friends = [
    Friend(
      id: 'p_hina',
      name: 'Hina S.',
      avatarEmoji: '🐰',
      status: FriendStatus.pending,
      subtitle: 'Level 22 · Gold League',
    ),
    Friend(
      id: 'p_danish',
      name: 'Danish M.',
      avatarEmoji: '🐯',
      status: FriendStatus.online,
      subtitle: '🟢 Playing Cricket now',
    ),
  ];

  group('FriendsCubit', () {
    late _MockLeaderboardRepository repository;

    setUp(() => repository = _MockLeaderboardRepository());

    test('starts in its initial state', () {
      expect(FriendsCubit(repository).state, isA<FriendsInitial>());
    });

    blocTest<FriendsCubit, FriendsState>(
      'success path: splits requests from accepted friends',
      setUp: () {
        when(() => repository.fetchFriends()).thenAnswer((_) async => friends);
      },
      build: () => FriendsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<FriendsLoading>(),
        isA<FriendsLoaded>()
            .having((state) => state.requests, 'requests', hasLength(1))
            .having((state) => state.accepted, 'accepted', hasLength(1)),
      ],
    );

    blocTest<FriendsCubit, FriendsState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchFriends(),
        ).thenThrow(const ApiException.network());
      },
      build: () => FriendsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<FriendsLoading>(), isA<FriendsError>()],
    );

    blocTest<FriendsCubit, FriendsState>(
      'responding to a request removes it from the list',
      setUp: () {
        when(() => repository.fetchFriends()).thenAnswer((_) async => friends);
      },
      build: () => FriendsCubit(repository),
      act: (cubit) async {
        await cubit.load();
        cubit.respondToRequest('p_hina', accept: true);
      },
      verify: (cubit) {
        final state = cubit.state as FriendsLoaded;
        expect(state.requests, isEmpty);
        expect(state.friends, hasLength(1));
      },
    );
  });

  group('LeagueCubit', () {
    late _MockLeaderboardRepository repository;

    const neighbors = [
      LeagueStanding(
        rank: 28,
        playerId: 'p_ayesha',
        name: 'Ayesha K.',
        avatarEmoji: '🦊',
        points: 9120,
      ),
      LeagueStanding(
        rank: 29,
        playerId: 'self',
        name: 'You',
        avatarEmoji: '🐼',
        points: 8980,
        isSelf: true,
      ),
      LeagueStanding(
        rank: 30,
        playerId: 'p_bilal',
        name: 'Bilal R.',
        avatarEmoji: '🐯',
        points: 8740,
      ),
    ];

    setUp(() => repository = _MockLeaderboardRepository());

    test('starts in its initial state', () {
      expect(LeagueCubit(repository).state, isA<LeagueInitial>());
    });

    blocTest<LeagueCubit, LeagueState>(
      'success path: loads the mini-standings',
      setUp: () {
        when(
          () => repository.fetchLeagueNeighbors(),
        ).thenAnswer((_) async => neighbors);
      },
      build: () => LeagueCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<LeagueLoading>(),
        isA<LeagueLoaded>().having(
          (state) => state.neighbors,
          'neighbors',
          neighbors,
        ),
      ],
    );

    blocTest<LeagueCubit, LeagueState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchLeagueNeighbors(),
        ).thenThrow(const ApiException.network());
      },
      build: () => LeagueCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<LeagueLoading>(), isA<LeagueError>()],
    );
  });
}
