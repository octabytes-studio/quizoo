import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/blocked_players_cubit.dart';
import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:quizoo/core/safety/safety_repository.dart';

class _MockSafetyRepository extends Mock implements SafetyRepository {}

void main() {
  late _MockSafetyRepository repository;

  final player = BlockedPlayer(
    id: 'user_a',
    name: 'Ali',
    avatarEmoji: '🦊',
    blockedAt: DateTime(2026, 10, 17),
  );

  setUp(() {
    repository = _MockSafetyRepository();
  });

  BlockedPlayersCubit buildCubit() => BlockedPlayersCubit(repository);

  blocTest<BlockedPlayersCubit, BlockedPlayersState>(
    'success path: load emits the blocked list',
    setUp: () {
      when(() => repository.blockedPlayers()).thenAnswer((_) async => [player]);
    },
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<BlockedPlayersLoading>(),
      isA<BlockedPlayersLoaded>().having(
        (state) => state.players.single.name,
        'name',
        'Ali',
      ),
    ],
  );

  blocTest<BlockedPlayersCubit, BlockedPlayersState>(
    'failure path: a failed load emits Error',
    setUp: () {
      when(
        () => repository.blockedPlayers(),
      ).thenThrow(const ApiException.network());
    },
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [isA<BlockedPlayersLoading>(), isA<BlockedPlayersError>()],
  );

  blocTest<BlockedPlayersCubit, BlockedPlayersState>(
    'unblock removes the row by reloading after the delete',
    setUp: () {
      when(() => repository.unblock('user_a')).thenAnswer((_) async {});
      when(() => repository.blockedPlayers()).thenAnswer((_) async => const []);
    },
    build: buildCubit,
    act: (cubit) => cubit.unblock('user_a'),
    expect: () => [isA<BlockedPlayersLoading>(), isA<BlockedPlayersLoaded>()],
    verify: (_) => verify(() => repository.unblock('user_a')).called(1),
  );
}
