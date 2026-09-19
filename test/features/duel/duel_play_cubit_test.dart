import 'dart:async';
import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_play_cubit.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';

class _MockDuelRepository extends Mock implements DuelRepository {}

void main() {
  late _MockDuelRepository repository;

  final questions = List.generate(5, (_) => MockQuestions.football.first);

  // Bronze — a ~9s average answer time, which leaves a wide, easy-to-assert
  // window between the player answering and the bot answering.
  const slowBot = DuelOpponent(
    id: 'bot_slow',
    name: 'Fox',
    avatarEmoji: '🦊',
    elo: 400,
  );
  // Platinum — a ~2.5s average, so a full 5-round duel finishes fast in a
  // test that just lets every round's clock run out.
  const fastBot = DuelOpponent(
    id: 'bot_fast',
    name: 'Owl',
    avatarEmoji: '🦉',
    elo: 2200,
  );

  setUp(() {
    repository = _MockDuelRepository();
  });

  void stubQuestions() {
    when(
      () => repository.fetchRoundQuestions(
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => questions);
    // `_finish()` calls this for real now (plan 006 Phase 5); unstubbed here
    // since these tests assert on the client-computed elo/coins fallback,
    // not a specific server response.
    when(
      () => repository.submitBotDuel(
        opponentElo: any(named: 'opponentElo'),
        playerRoundsWon: any(named: 'playerRoundsWon'),
        opponentRoundsWon: any(named: 'opponentRoundsWon'),
        rounds: any(named: 'rounds'),
      ),
    ).thenThrow(const ApiException.network());
  }

  group('DuelPlayCubit', () {
    test('starts in the loading state', () {
      expect(DuelPlayCubit(repository).state, isA<DuelPlayLoading>());
    });

    blocTest<DuelPlayCubit, DuelPlayState>(
      'failure path: a failed fetch ends in DuelPlayFailed',
      setUp: () => when(
        () => repository.fetchRoundQuestions(
          languageCode: any(named: 'languageCode'),
        ),
      ).thenThrow(const ApiException.network()),
      build: () => DuelPlayCubit(repository),
      act: (cubit) => cubit.start(slowBot, languageCode: 'en'),
      expect: () => [isA<DuelPlayLoading>(), isA<DuelPlayFailed>()],
    );

    test('the withheld-correctness rule holds for every state emitted during '
        'the first round, and the round does eventually resolve', () {
      // Checked against every state the Cubit ever emits for round 1,
      // rather than at one hand-picked instant — the scripted bot's timing
      // has jitter, so asserting at a fixed elapsed duration would be
      // asserting about *when* the round resolves, which is not the rule
      // under test, and would make this test timing-flaky.
      stubQuestions();
      fakeAsync((async) {
        final cubit = DuelPlayCubit(repository, random: Random(1));
        final seenRound1 = <DuelPlayRound>[];
        final subscription = cubit.stream.listen((state) {
          if (state is DuelPlayRound && state.roundNumber == 1) {
            seenRound1.add(state);
          }
        });

        unawaited(cubit.start(slowBot, languageCode: 'en'));
        async.flushMicrotasks();

        // The player locks in an answer almost immediately.
        cubit.answer(0);
        expect((cubit.state as DuelPlayRound).playerAnswerIndex, 0);

        // Bronze averages ~9s with ±40% jitter (5.4–12.6s worst case) — 13s
        // safely covers round 1 resolving.
        async.elapse(const Duration(seconds: 13));

        for (final round in seenRound1) {
          if (!round.isRevealed) {
            expect(
              round.revealedOpponentAnswerIndex,
              isNull,
              reason: 'the opponent\'s answer leaked onto an unrevealed state',
            );
          }
        }
        // Not vacuous: the round really did resolve and really did carry
        // the opponent's answer once it was safe to.
        expect(
          seenRound1.any(
            (round) =>
                round.isRevealed && round.revealedOpponentAnswerIndex != null,
          ),
          isTrue,
          reason: 'round 1 never actually resolved during this test',
        );

        unawaited(subscription.cancel());
        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('a round can also resolve opponent-first, with the same rule', () {
      stubQuestions();
      fakeAsync((async) {
        // Platinum answers fast, so it very likely answers before a player
        // who never taps until well into the round.
        final cubit = DuelPlayCubit(repository, random: Random(2));
        unawaited(cubit.start(fastBot, languageCode: 'en'));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 4));
        final round = cubit.state as DuelPlayRound;
        expect(round.opponentHasAnswered, isTrue);
        expect(round.playerHasAnswered, isFalse);
        // Withheld the other way round too: the bot went first, but nothing
        // reveals until the player also answers.
        expect(round.isRevealed, isFalse);
        expect(round.revealedOpponentAnswerIndex, isNull);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('a timeout with nothing selected still resolves the round', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = DuelPlayCubit(repository, random: Random(3));
        unawaited(cubit.start(fastBot, languageCode: 'en'));
        async.flushMicrotasks();

        // Never taps an option — the full round clock runs out.
        async.elapse(const Duration(seconds: 16));
        final round = cubit.state as DuelPlayRound;
        expect(round.playerHasAnswered, isTrue);
        expect(round.playerAnswerIndex, isNull);
        expect(round.isRevealed, isTrue);
        expect(round.history.single.playerCorrect, isFalse);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('completes all 5 rounds and ends on DuelPlayEnded', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = DuelPlayCubit(repository, random: Random(4));
        unawaited(cubit.start(fastBot, languageCode: 'en'));
        async.flushMicrotasks();

        // Every round's 15s clock runs out, plus the ~1.8s reveal pause,
        // five times over, with slack.
        async.elapse(const Duration(seconds: 95));

        expect(cubit.state, isA<DuelPlayEnded>());
        final result = (cubit.state as DuelPlayEnded).result;
        expect(
          result.playerRoundsWon + result.opponentRoundsWon,
          lessThanOrEqualTo(5),
        );
        // The player never answered a single round in this test, so they
        // cannot have won any of them.
        expect(result.playerRoundsWon, 0);
        expect(result.isVictory, isFalse);
        expect(result.rewardCoins, DuelPlayCubit.rewardCoinsDefeat);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('a second answer from the player is ignored once locked in', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = DuelPlayCubit(repository, random: Random(5));
        unawaited(cubit.start(slowBot, languageCode: 'en'));
        async.flushMicrotasks();

        cubit.answer(0);
        cubit.answer(2);
        final round = cubit.state as DuelPlayRound;
        expect(round.playerAnswerIndex, 0);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test(
      'newly-earned badge ids from submitBotDuel pass through unchanged '
      'onto the emitted DuelResult',
      () {
        when(
          () => repository.fetchRoundQuestions(
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => questions);
        when(
          () => repository.submitBotDuel(
            opponentElo: any(named: 'opponentElo'),
            playerRoundsWon: any(named: 'playerRoundsWon'),
            opponentRoundsWon: any(named: 'opponentRoundsWon'),
            rounds: any(named: 'rounds'),
          ),
        ).thenAnswer(
          (_) async => const BotDuelRecord(
            eloBefore: 1200,
            eloAfter: 1218,
            coinsEarned: 200,
            newlyEarnedBadgeIds: ['badge_duelist'],
          ),
        );

        fakeAsync((async) {
          final cubit = DuelPlayCubit(repository, random: Random(4));
          unawaited(cubit.start(fastBot, languageCode: 'en'));
          async.flushMicrotasks();

          async.elapse(const Duration(seconds: 95));

          final result = (cubit.state as DuelPlayEnded).result;
          expect(result.newlyEarnedBadgeIds, ['badge_duelist']);

          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      },
    );
  });
}
