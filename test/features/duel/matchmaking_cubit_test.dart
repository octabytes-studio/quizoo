import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/presentation/bloc/matchmaking_cubit.dart';

class _MockDuelRepository extends Mock implements DuelRepository {}

void main() {
  late _MockDuelRepository repository;

  const bot = DuelOpponent(
    id: 'bot_1',
    name: 'Fox',
    avatarEmoji: '🦊',
    elo: 1200,
  );

  setUp(() {
    repository = _MockDuelRepository();
    when(
      () => repository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
    ).thenAnswer((_) async => bot);
  });

  group('MatchmakingCubit', () {
    test('starts searching from zero', () {
      final cubit = MatchmakingCubit(repository, playerElo: 1240);
      expect(
        cubit.state,
        const MatchmakingSearching(elapsedSeconds: 0, widenings: 0),
      );
    });

    test(
      'success path: auto-offers an explicitly-labelled bot at the timeout',
      () {
        fakeAsync((async) {
          final cubit = MatchmakingCubit(repository, playerElo: 1240)..start();

          async.elapse(const Duration(seconds: 20));
          async.flushMicrotasks();

          expect(cubit.state, isA<MatchmakingFound>());
          // §14: "never a secret bot" — the offer is always explicitly one.
          expect((cubit.state as MatchmakingFound).opponent.isBot, isTrue);

          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      },
    );

    test('widens the ELO band every 6 seconds while searching', () {
      fakeAsync((async) {
        final cubit = MatchmakingCubit(repository, playerElo: 1240)..start();

        async.elapse(const Duration(seconds: 7));
        final state = cubit.state as MatchmakingSearching;
        expect(state.elapsedSeconds, 7);
        expect(state.widenings, 1);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('"play a bot instead" ends the search immediately, not only at the '
        '20s timeout', () {
      fakeAsync((async) {
        final cubit = MatchmakingCubit(repository, playerElo: 1240)..start();

        // The button is offered from frame one (plan 004's Research
        // findings) — three seconds in is long before the timeout.
        async.elapse(const Duration(seconds: 3));
        unawaited(cubit.playBotInstead());
        async.flushMicrotasks();

        expect(cubit.state, isA<MatchmakingFound>());

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test(
      'failure path: a connection hiccup leaves the player still searching',
      () {
        when(
          () => repository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
        ).thenThrow(const ApiException.network());

        fakeAsync((async) {
          final cubit = MatchmakingCubit(repository, playerElo: 1240)..start();

          unawaited(cubit.playBotInstead());
          async.flushMicrotasks();

          // Never a crash, and never silently stuck on a screen with nothing
          // to tap — the ticker is still running underneath.
          expect(cubit.state, isA<MatchmakingSearching>());

          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      },
    );
  });
}
