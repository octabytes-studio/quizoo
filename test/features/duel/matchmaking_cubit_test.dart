import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/data/matchmaking_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/matchmaking_ticket.dart';
import 'package:quizoo/features/duel/presentation/bloc/matchmaking_cubit.dart';

class _MockMatchmakingRepository extends Mock
    implements MatchmakingRepository {}

class _MockDuelRepository extends Mock implements DuelRepository {}

void main() {
  final start = DateTime.utc(2026, 9, 27, 12);

  const topic = DuelTopic(
    id: 'sub_football',
    name: 'Football',
    emoji: '⚽',
    plateColor: '#FF8A24',
    categoryName: 'Sports',
    categoryEmoji: '🏅',
  );
  const me = DuelPlayer(
    id: 'user_me',
    name: 'Waleed',
    avatarEmoji: '🐼',
    elo: 1240,
    league: 'silver',
  );
  const bot = DuelPlayer(
    id: 'bot_fox',
    name: 'Fox',
    avatarEmoji: '🦊',
    elo: 1230,
    isBot: true,
  );

  MatchmakingQueued queued({
    DateTime? queuedAt,
    int bandMin = 1140,
    int bandMax = 1340,
    bool botAvailable = false,
    DateTime? botAvailableAt,
  }) => MatchmakingQueued(
    queuedAt: queuedAt ?? start,
    bandMin: bandMin,
    bandMax: bandMax,
    elo: me.elo,
    botAvailable: botAvailable,
    botAvailableAt: botAvailableAt,
    me: me,
    topic: topic,
    serverNow: start,
  );

  const notInQueue = ApiException(
    'not_in_queue',
    kind: ApiErrorKind.server,
    code: 'not_in_queue',
  );

  late _MockMatchmakingRepository repository;
  late _MockDuelRepository botRepository;
  late StreamController<String> duelStarts;

  setUp(() {
    repository = _MockMatchmakingRepository();
    botRepository = _MockDuelRepository();
    duelStarts = StreamController<String>.broadcast();
    when(() => repository.duelStarts()).thenAnswer((_) => duelStarts.stream);
    when(() => repository.leave()).thenAnswer((_) async {});
    when(() => repository.join(any())).thenAnswer((_) async => queued());
    when(() => repository.heartbeat()).thenAnswer((_) async => queued());
    when(
      () => botRepository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
    ).thenAnswer((_) async => bot);
  });

  tearDown(() => duelStarts.close());

  MatchmakingCubit buildCubit(
    ServerClock clock, {
    DuelConfig config = DuelConfig.fallback,
  }) => MatchmakingCubit(
    repository,
    botRepository,
    clock,
    topic: topic,
    config: config,
  );

  /// Runs [body] under fake time with a clock that follows it, and closes
  /// the Cubit afterwards so no ticker outlives the test.
  void runFake(
    void Function(FakeAsync async, MatchmakingCubit cubit) body, {
    DuelConfig config = DuelConfig.fallback,
  }) {
    fakeAsync((async) {
      final cubit = buildCubit(
        ServerClock(localNow: () => start.add(async.elapsed)),
        config: config,
      );
      body(async, cubit);
      unawaited(cubit.close());
      async.flushMicrotasks();
    });
  }

  group('MatchmakingCubit', () {
    test('starts in MatchmakingJoining', () {
      final cubit = buildCubit(ServerClock(localNow: () => start));
      expect(cubit.state, const MatchmakingJoining());
    });

    blocTest<MatchmakingCubit, MatchmakingState>(
      'success path: a queued ticket from join → Searching',
      build: () => buildCubit(ServerClock(localNow: () => start)),
      act: (cubit) => cubit.start(),
      expect: () => [
        const MatchmakingSearching(
          me: me,
          topic: topic,
          elapsedSeconds: 0,
          bandMin: 1140,
          bandMax: 1340,
          secondsToNextWiden: 5,
          botAvailable: false,
        ),
      ],
      verify: (_) => verify(() => repository.join(topic.id)).called(1),
    );

    blocTest<MatchmakingCubit, MatchmakingState>(
      'failure path: join throwing → Failed with the server code',
      setUp: () => when(() => repository.join(any())).thenThrow(
        const ApiException(
          'topic_unavailable',
          kind: ApiErrorKind.server,
          code: 'topic_unavailable',
        ),
      ),
      build: () => buildCubit(ServerClock(localNow: () => start)),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<MatchmakingFailed>().having(
          (state) => state.error.code,
          'code',
          'topic_unavailable',
        ),
      ],
    );

    blocTest<MatchmakingCubit, MatchmakingState>(
      'join answering matched goes straight to Found',
      setUp: () => when(
        () => repository.join(any()),
      ).thenAnswer((_) async => const MatchmakingMatched('duel_1')),
      build: () => buildCubit(ServerClock(localNow: () => start)),
      act: (cubit) => cubit.start(),
      expect: () => [const MatchmakingFound('duel_1')],
    );

    test('ticks elapsed time and the widen countdown, and heartbeats bring '
        'the widened band', () {
      when(
        () => repository.heartbeat(),
      ).thenAnswer((_) async => queued(bandMin: 1090, bandMax: 1390));
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 7));

        final state = cubit.state as MatchmakingSearching;
        expect(state.elapsedSeconds, 7);
        expect(state.secondsToNextWiden, 3);
        expect(state.bandMin, 1090);
        expect(state.bandMax, 1390);
        // Heartbeats every `mmHeartbeatSeconds` (3): at 3 s and 6 s.
        verify(() => repository.heartbeat()).called(2);
      });
    });

    test('a heartbeat answering matched → Found, and the ticker stops', () {
      when(
        () => repository.heartbeat(),
      ).thenAnswer((_) async => const MatchmakingMatched('duel_hb'));
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 3));

        expect(cubit.state, const MatchmakingFound('duel_hb'));

        async.elapse(const Duration(seconds: 10));
        verify(() => repository.heartbeat()).called(1);
      });
    });

    test('a duel_start on the inbox → Found immediately, before the next '
        'heartbeat', () {
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 1));

        duelStarts.add('duel_inbox');
        async.flushMicrotasks();

        expect(cubit.state, const MatchmakingFound('duel_inbox'));
        verifyNever(() => repository.heartbeat());
      });
    });

    test('at 30 s the server flag surfaces the bot offer', () {
      runFake((async, cubit) {
        when(() => repository.heartbeat()).thenAnswer(
          (_) async => queued(
            botAvailable: async.elapsed >= const Duration(seconds: 30),
          ),
        );
        unawaited(cubit.start());

        async.elapse(const Duration(seconds: 29));
        var state = cubit.state as MatchmakingSearching;
        expect(state.botAvailable, isFalse);
        expect(state.showBotOffer, isFalse);

        async.elapse(const Duration(seconds: 1));
        state = cubit.state as MatchmakingSearching;
        expect(state.elapsedSeconds, 30);
        expect(state.botAvailable, isTrue);
        expect(state.showBotOffer, isTrue);
      });
    });

    test("the server's botAvailableAt surfaces the offer between "
        'heartbeats', () {
      when(() => repository.join(any())).thenAnswer(
        (_) async =>
            queued(botAvailableAt: start.add(const Duration(seconds: 30))),
      );
      when(() => repository.heartbeat()).thenAnswer(
        (_) async =>
            queued(botAvailableAt: start.add(const Duration(seconds: 30))),
      );
      // Heartbeats at 7, 14, 21, 28, 35 s — none lands on 30 s.
      runFake(config: const DuelConfig(mmHeartbeatSeconds: 7), (async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 29));
        expect((cubit.state as MatchmakingSearching).showBotOffer, isFalse);

        async.elapse(const Duration(seconds: 1));
        expect((cubit.state as MatchmakingSearching).showBotOffer, isTrue);
      });
    });

    test('keepSearching hides the offer for another botAfterSeconds', () {
      // Queued 30 s ago, so the offer is already up.
      final longAgo = start.subtract(const Duration(seconds: 30));
      when(
        () => repository.join(any()),
      ).thenAnswer((_) async => queued(queuedAt: longAgo, botAvailable: true));
      when(
        () => repository.heartbeat(),
      ).thenAnswer((_) async => queued(queuedAt: longAgo, botAvailable: true));
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.flushMicrotasks();
        expect((cubit.state as MatchmakingSearching).showBotOffer, isTrue);

        cubit.keepSearching();
        var state = cubit.state as MatchmakingSearching;
        expect(state.showBotOffer, isFalse);
        expect(state.botOfferSnoozedUntil, 60);

        async.elapse(const Duration(seconds: 29));
        expect((cubit.state as MatchmakingSearching).showBotOffer, isFalse);

        async.elapse(const Duration(seconds: 1));
        state = cubit.state as MatchmakingSearching;
        expect(state.elapsedSeconds, 60);
        expect(state.showBotOffer, isTrue);
        // The search never stopped underneath.
        verify(() => repository.heartbeat()).called(10);
      });
    });

    test('playBot leaves the queue, then fetches a bot → BotReady with an '
        'explicitly-labelled bot', () {
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 2));

        unawaited(cubit.playBot());
        async.flushMicrotasks();

        final state = cubit.state as MatchmakingBotReady;
        expect(state.opponent.isBot, isTrue);
        expect(state.opponent.id, bot.id);
        expect(state.me, me);
        expect(state.topic, topic);
        verifyInOrder([
          () => repository.leave(),
          () => botRepository.fetchBotOpponent(playerElo: me.elo),
        ]);

        // Already out of the queue: closing must not leave a second time
        // (the one leave above is already verified, so any further call
        // would show up here), and no heartbeat may run after the bot was
        // taken.
        async.elapse(const Duration(seconds: 10));
        unawaited(cubit.close());
        async.flushMicrotasks();
        verifyNever(() => repository.leave());
        verifyNever(() => repository.heartbeat());
      });
    });

    test('playBot failing stays searching and re-joins the queue it left', () {
      when(
        () =>
            botRepository.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).thenThrow(const ApiException.network());
      when(() => repository.heartbeat()).thenThrow(notInQueue);
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.flushMicrotasks();

        unawaited(cubit.playBot());
        async.flushMicrotasks();

        final state = cubit.state as MatchmakingSearching;
        expect(state.isStartingBot, isFalse);

        // The next tick's heartbeat finds no queue row and re-joins.
        async.elapse(const Duration(seconds: 1));
        verify(() => repository.join(topic.id)).called(2);
        expect(cubit.state, isA<MatchmakingSearching>());
      });
    });

    test('a heartbeat not_in_queue re-joins once', () {
      var heartbeats = 0;
      when(() => repository.heartbeat()).thenAnswer((_) async {
        heartbeats++;
        if (heartbeats == 1) throw notInQueue;
        return queued();
      });
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 3));

        verify(() => repository.join(topic.id)).called(2);
        expect(cubit.state, isA<MatchmakingSearching>());

        async.elapse(const Duration(seconds: 3));
        expect(cubit.state, isA<MatchmakingSearching>());
      });
    });

    test('not_in_queue again before any heartbeat succeeds → Failed', () {
      when(() => repository.heartbeat()).thenThrow(notInQueue);
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 3));
        expect(cubit.state, isA<MatchmakingSearching>());

        async.elapse(const Duration(seconds: 3));
        expect(
          cubit.state,
          isA<MatchmakingFailed>().having(
            (state) => state.error.code,
            'code',
            'not_in_queue',
          ),
        );
        // Exactly one re-join was tried.
        verify(() => repository.join(topic.id)).called(2);
      });
    });

    test('a network heartbeat error keeps searching and retries on the next '
        'tick', () {
      var heartbeats = 0;
      when(() => repository.heartbeat()).thenAnswer((_) async {
        heartbeats++;
        if (heartbeats == 1) throw const ApiException.network();
        return queued(bandMin: 1090, bandMax: 1390);
      });
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 3));
        expect(cubit.state, isA<MatchmakingSearching>());
        expect(heartbeats, 1);

        async.elapse(const Duration(seconds: 1));
        expect(heartbeats, 2);
        expect((cubit.state as MatchmakingSearching).bandMin, 1090);
      });
    });

    test('retrying from Failed joins again', () {
      var joins = 0;
      when(() => repository.join(any())).thenAnswer((_) async {
        joins++;
        if (joins == 1) throw const ApiException.network();
        return queued();
      });
      runFake((async, cubit) {
        unawaited(cubit.start());
        async.flushMicrotasks();
        expect(cubit.state, isA<MatchmakingFailed>());

        unawaited(cubit.start());
        async.flushMicrotasks();
        expect(cubit.state, isA<MatchmakingSearching>());
      });
    });

    test('close leaves the queue', () {
      fakeAsync((async) {
        final cubit = buildCubit(
          ServerClock(localNow: () => start.add(async.elapsed)),
        );
        unawaited(cubit.start());
        async.elapse(const Duration(seconds: 2));

        unawaited(cubit.close());
        async.flushMicrotasks();

        verify(() => repository.leave()).called(1);
        async.elapse(const Duration(seconds: 10));
        verifyNever(() => repository.heartbeat());
      });
    });

    test('close after Found does not leave — the server already removed the '
        'queue row', () {
      fakeAsync((async) {
        final cubit = buildCubit(
          ServerClock(localNow: () => start.add(async.elapsed)),
        );
        unawaited(cubit.start());
        async.flushMicrotasks();
        duelStarts.add('duel_found');
        async.flushMicrotasks();

        unawaited(cubit.close());
        async.flushMicrotasks();

        verifyNever(() => repository.leave());
      });
    });

    test('cancel stops the search and leaves exactly once', () {
      fakeAsync((async) {
        final cubit = buildCubit(
          ServerClock(localNow: () => start.add(async.elapsed)),
        );
        unawaited(cubit.start());
        async.flushMicrotasks();

        unawaited(cubit.cancel());
        async.elapse(const Duration(seconds: 10));
        unawaited(cubit.close());
        async.flushMicrotasks();

        verify(() => repository.leave()).called(1);
        verifyNever(() => repository.heartbeat());
      });
    });
  });
}
