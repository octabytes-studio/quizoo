import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/bot_rematch_cubit.dart';

class _MockDuelRepository extends Mock implements DuelRepository {}

void main() {
  late _MockDuelRepository repository;

  const me = DuelPlayer(id: 'me', name: 'Ayesha', avatarEmoji: '🐼', elo: 1200);
  const oldBot = DuelPlayer(
    id: 'bot_1',
    name: 'Fennec',
    avatarEmoji: '🦊',
    elo: 1240,
    isBot: true,
  );
  const newBot = DuelPlayer(
    id: 'bot_2',
    name: 'Athena',
    avatarEmoji: '🦉',
    elo: 1230,
    isBot: true,
  );
  const topic = DuelTopic(
    id: 'sub_football',
    name: 'Football',
    emoji: '⚽',
    plateColor: '#12C79B',
    categoryName: 'Sports',
    categoryEmoji: '🏅',
  );
  const previous = DuelResult(
    me: me,
    opponent: oldBot,
    playerRoundsWon: 3,
    opponentRoundsWon: 2,
    playerAverageAnswerSeconds: 4.2,
    opponentAverageAnswerSeconds: 5.6,
    eloBefore: 1200,
    eloAfter: 1209,
    rewardCoins: 100,
    topic: topic,
  );

  BotRematchCubit build() => BotRematchCubit(repository, previous: previous);

  setUp(() => repository = _MockDuelRepository());

  group('BotRematchCubit', () {
    test('starts idle', () {
      expect(build().state, const BotRematchIdle());
    });

    blocTest<BotRematchCubit, BotRematchState>(
      'success path: deals a new bot near the ELO the last duel left',
      setUp: () => when(
        () => repository.fetchBotOpponent(playerElo: 1209),
      ).thenAnswer((_) async => newBot),
      build: build,
      act: (cubit) => cubit.rematch(topic),
      expect: () => [
        const BotRematchLoading(),
        BotRematchFound(
          me: me.copyWith(elo: 1209),
          opponent: newBot,
          topic: topic,
        ),
      ],
      verify: (_) =>
          verify(() => repository.fetchBotOpponent(playerElo: 1209)).called(1),
    );

    blocTest<BotRematchCubit, BotRematchState>(
      'failure path: a failed deal surfaces and leaves Rematch tappable',
      setUp: () => when(
        () => repository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).thenThrow(const ApiException.network()),
      build: build,
      act: (cubit) => cubit.rematch(topic),
      expect: () => const [
        BotRematchLoading(),
        BotRematchFailed(ApiException.network()),
      ],
    );

    blocTest<BotRematchCubit, BotRematchState>(
      'a retry after a failure deals again',
      setUp: () {
        var calls = 0;
        when(
          () => repository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
        ).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw const ApiException.network();
          return newBot;
        });
      },
      build: build,
      act: (cubit) async {
        await cubit.rematch(topic);
        await cubit.rematch(topic);
      },
      expect: () => [
        const BotRematchLoading(),
        const BotRematchFailed(ApiException.network()),
        const BotRematchLoading(),
        BotRematchFound(
          me: me.copyWith(elo: 1209),
          opponent: newBot,
          topic: topic,
        ),
      ],
    );

    blocTest<BotRematchCubit, BotRematchState>(
      'a second tap once a bot is dealt does not deal another',
      setUp: () => when(
        () => repository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).thenAnswer((_) async => newBot),
      build: build,
      act: (cubit) async {
        await cubit.rematch(topic);
        await cubit.rematch(topic);
      },
      expect: () => [
        const BotRematchLoading(),
        BotRematchFound(
          me: me.copyWith(elo: 1209),
          opponent: newBot,
          topic: topic,
        ),
      ],
      verify: (_) => verify(
        () => repository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).called(1),
    );
  });
}
