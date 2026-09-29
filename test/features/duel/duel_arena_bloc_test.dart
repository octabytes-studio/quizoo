import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_me.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_snapshot.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/domain/lobby_event.dart';
import 'package:quizoo/features/duel/domain/outgoing_join_request.dart';
import 'package:quizoo/features/duel/presentation/bloc/arena_notice.dart';
import 'package:quizoo/features/duel/presentation/bloc/challenge_card_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/composer_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_arena_bloc.dart';
import 'package:quizoo/features/duel/presentation/bloc/fairness.dart';

class _MockDuelArenaRepository extends Mock implements DuelArenaRepository {}

final DateTime start = DateTime.utc(2026, 9, 27, 12);

const DuelTopic football = DuelTopic(
  id: 'topic-football',
  name: 'Football',
  emoji: '⚽',
  plateColor: '#DDF1FF',
  categoryName: 'Sports',
  categoryEmoji: '🏅',
);

DuelPlayer player(String id, {int elo = 1200, bool isGuest = false}) =>
    DuelPlayer(
      id: id,
      name: isGuest ? null : 'Player $id',
      avatarEmoji: '🦊',
      elo: elo,
      isGuest: isGuest,
      guestTag: isGuest ? '4821' : null,
    );

final DuelPlayer me = player('me');

DuelChallenge challenge(
  String id, {
  DuelPlayer? creator,
  Duration createdAgo = Duration.zero,
  ChallengeStatus status = ChallengeStatus.open,
  bool creatorPresent = true,
}) {
  final createdAt = start.subtract(createdAgo);
  return DuelChallenge(
    id: id,
    status: status,
    creatorPresent: creatorPresent,
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(minutes: 5)),
    creator: creator ?? player('creator-$id'),
    topic: football,
  );
}

DuelLobbySnapshot snapshot({
  List<DuelChallenge> challenges = const [],
  List<DuelChallenge> recentlyEnded = const [],
  bool isGuest = false,
  DateTime? cooldownEndsAt,
  IncomingJoinRequest? incoming,
}) => DuelLobbySnapshot(
  serverNow: start,
  config: const DuelConfig(),
  me: DuelLobbyMe(
    player: isGuest ? player('me', isGuest: true) : me,
    isGuest: isGuest,
    cooldownEndsAt: cooldownEndsAt,
  ),
  challenges: challenges,
  recentlyEnded: recentlyEnded,
  incoming: incoming,
);

void main() {
  late _MockDuelArenaRepository repository;
  late StreamController<LobbyEvent> events;

  setUp(() {
    repository = _MockDuelArenaRepository();
    events = StreamController<LobbyEvent>.broadcast();
    when(
      () => repository.fetchLobby(any()),
    ).thenAnswer((_) async => snapshot(challenges: [challenge('c1')]));
    when(
      () =>
          repository.events(any(), trackPresence: any(named: 'trackPresence')),
    ).thenAnswer((_) => events.stream);
    when(
      () => repository.setPresence(present: any(named: 'present')),
    ).thenAnswer((_) async {});
  });

  tearDown(() => events.close());

  /// A clock frozen at [start], for the tests that don't move time.
  ServerClock frozenClock() => ServerClock(localNow: () => start);

  DuelArenaBloc buildBloc({ServerClock? clock}) =>
      DuelArenaBloc(repository, clock ?? frozenClock(), languageCode: 'en');

  DuelArenaReady readyOf(DuelArenaBloc bloc) => bloc.state as DuelArenaReady;

  group('DuelArenaBloc', () {
    test('starts loading', () {
      final bloc = buildBloc();
      expect(bloc.state, const DuelArenaLoading());
      unawaited(bloc.close());
    });

    blocTest<DuelArenaBloc, DuelArenaState>(
      'success path: opening loads the snapshot, listens, and goes present',
      build: buildBloc,
      act: (bloc) => bloc.add(const ArenaOpened()),
      expect: () => [
        isA<DuelArenaReady>()
            .having((s) => s.challenges.map((c) => c.id), 'challenges', ['c1'])
            .having((s) => s.now, 'now', start)
            .having((s) => s.isLive, 'isLive', isTrue),
      ],
      verify: (_) {
        verify(() => repository.fetchLobby('en')).called(1);
        verify(() => repository.events('en', trackPresence: true)).called(1);
        verify(() => repository.setPresence(present: true)).called(1);
      },
    );

    blocTest<DuelArenaBloc, DuelArenaState>(
      'failure path: a snapshot error lands on Failed',
      setUp: () => when(
        () => repository.fetchLobby(any()),
      ).thenThrow(const ApiException.network()),
      build: buildBloc,
      act: (bloc) => bloc.add(const ArenaOpened()),
      expect: () => [isA<DuelArenaFailed>()],
      verify: (_) => verifyNever(
        () => repository.events(
          any(),
          trackPresence: any(named: 'trackPresence'),
        ),
      ),
    );

    blocTest<DuelArenaBloc, DuelArenaState>(
      'retry after a failure loads again',
      build: buildBloc,
      seed: () => const DuelArenaFailed(ApiException.network()),
      act: (bloc) => bloc.add(const ArenaRetryRequested()),
      expect: () => [const DuelArenaLoading(), isA<DuelArenaReady>()],
    );

    test(
      'challenge upsert/remove events update the feed, oldest first',
      () async {
        final bloc = buildBloc()..add(const ArenaOpened());
        await pumpEventQueue();

        events.add(
          ChallengeUpserted(
            challenge('c0', createdAgo: const Duration(minutes: 1)),
          ),
        );
        await pumpEventQueue();
        expect(readyOf(bloc).challenges.map((c) => c.id), ['c0', 'c1']);

        // An update (the creator stepped away) replaces the card in place.
        events.add(ChallengeUpserted(challenge('c1', creatorPresent: false)));
        await pumpEventQueue();
        final ready = readyOf(bloc);
        expect(ready.challenges.map((c) => c.id), ['c0', 'c1']);
        expect(
          ready.cardStateFor(ready.challenges.last),
          const ChallengeCardAway(),
        );

        events.add(const ChallengeRemoved('c0'));
        await pumpEventQueue();
        final afterRemove = readyOf(bloc);
        expect(afterRemove.challenges.map((c) => c.id), ['c1']);
        // Optimistic: it lingers as history, reason unknown until the next
        // snapshot fetch.
        expect(afterRemove.recentlyEnded.map((c) => c.id), ['c0']);
        expect(
          afterRemove.cardStateFor(afterRemove.recentlyEnded.single),
          const ChallengeCardEnded(),
        );

        await bloc.close();
      },
    );

    test('snapshot fetch/refresh carries recentlyEnded through', () async {
      final ended = challenge(
        'old',
        status: ChallengeStatus.ended,
      ).copyWith(endReason: 'expired');
      when(
        () => repository.fetchLobby(any()),
      ).thenAnswer((_) async => snapshot(recentlyEnded: [ended]));

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();

      expect(readyOf(bloc).recentlyEnded.map((c) => c.id), ['old']);
      expect(
        readyOf(bloc).cardStateFor(ended),
        const ChallengeCardEnded(endReason: 'expired'),
      );

      await bloc.close();
    });

    test('create → a cooldown notice on challenge_cooldown', () async {
      when(() => repository.fetchLobby(any())).thenAnswer(
        (_) async =>
            snapshot(cooldownEndsAt: start.add(const Duration(seconds: 90))),
      );
      when(() => repository.createChallenge(any())).thenThrow(
        const ApiException('challenge_cooldown', code: 'challenge_cooldown'),
      );

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();
      bloc.add(const ChallengeCreateRequested(football));
      await pumpEventQueue();

      final ready = readyOf(bloc);
      expect(ready.notice, const CooldownNotice(Duration(seconds: 90)));
      expect(ready.noticeSeq, 1);
      expect(ready.isBusy, isFalse);
      expect(
        ready.composerState,
        ComposerCooldown(start.add(const Duration(seconds: 90))),
      );

      bloc.add(const NoticeConsumed());
      await pumpEventQueue();
      expect(readyOf(bloc).notice, isNull);

      await bloc.close();
    });

    test('create success adds the own card and the cool-off', () async {
      final own = challenge('mine', creator: me);
      when(() => repository.createChallenge(any())).thenAnswer(
        (_) async => (
          challenge: own,
          cooldownEndsAt: start.add(const Duration(minutes: 2)),
        ),
      );

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();
      bloc.add(const ChallengeCreateRequested(football));
      await pumpEventQueue();

      final ready = readyOf(bloc);
      verify(() => repository.createChallenge(football.id)).called(1);
      expect(ready.challenges.map((c) => c.id), contains('mine'));
      expect(ready.cardStateFor(own), const ChallengeCardOwn());
      expect(ready.composerState, ComposerOwnOpen(own));

      await bloc.close();
    });

    test('a guest create → SignInRequiredNotice without any RPC', () async {
      when(
        () => repository.fetchLobby(any()),
      ).thenAnswer((_) async => snapshot(isGuest: true));

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();
      expect(readyOf(bloc).composerState, const ComposerSignIn());

      bloc.add(const ChallengeCreateRequested(football));
      await pumpEventQueue();

      expect(readyOf(bloc).notice, const SignInRequiredNotice());
      verifyNever(() => repository.createChallenge(any()));

      await bloc.close();
    });

    test('a guest join → SignInRequiredNotice (the sign-in sheet) without any '
        'RPC, and the card stays joinable', () async {
      when(() => repository.fetchLobby(any())).thenAnswer(
        (_) async => snapshot(isGuest: true, challenges: [challenge('c1')]),
      );

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();
      bloc.add(const JoinRequested('c1'));
      await pumpEventQueue();

      final ready = readyOf(bloc);
      expect(ready.notice, const SignInRequiredNotice());
      expect(ready.outgoing, isEmpty);
      expect(
        ready.cardStateFor(ready.challenges.single),
        const ChallengeCardOpen(),
      );
      verifyNever(() => repository.requestJoin(any()));

      await bloc.close();
    });

    test(
      'the server refusing a guest join also asks them to sign in',
      () async {
        when(() => repository.requestJoin('c1')).thenThrow(
          const ApiException('guest_cannot_join', code: 'guest_cannot_join'),
        );

        final bloc = buildBloc()..add(const ArenaOpened());
        await pumpEventQueue();
        bloc.add(const JoinRequested('c1'));
        await pumpEventQueue();

        expect(readyOf(bloc).notice, const SignInRequiredNotice());
        expect(readyOf(bloc).outgoing, isEmpty);

        await bloc.close();
      },
    );

    test(
      'join → queued → pending → declined → Cooling, then Open after retryAfter',
      () {
        fakeAsync((async) {
          final clock = ServerClock(localNow: () => start.add(async.elapsed));
          when(() => repository.requestJoin('c1')).thenAnswer(
            (_) async => const OutgoingJoinRequest(
              requestId: 'r1',
              challengeId: 'c1',
              status: JoinRequestStatus.queued,
              position: 2,
            ),
          );

          final bloc = buildBloc(clock: clock)..add(const ArenaOpened());
          async.flushMicrotasks();
          DuelChallenge card() => readyOf(bloc).challenges.single;
          ChallengeCardState cardState() => readyOf(bloc).cardStateFor(card());

          expect(cardState(), const ChallengeCardOpen());

          bloc.add(const JoinRequested('c1'));
          async.flushMicrotasks();
          expect(cardState(), const ChallengeCardQueued(position: 2));

          final decideBy = start.add(const Duration(seconds: 5));
          events.add(
            OutgoingRequestChanged(
              OutgoingJoinRequest(
                requestId: 'r1',
                challengeId: 'c1',
                status: JoinRequestStatus.pending,
                expiresAt: decideBy,
              ),
            ),
          );
          async.flushMicrotasks();
          expect(cardState(), ChallengeCardPending(expiresAt: decideBy));

          final retryAt = start.add(const Duration(seconds: 15));
          events.add(
            OutgoingRequestChanged(
              OutgoingJoinRequest(
                requestId: 'r1',
                challengeId: 'c1',
                status: JoinRequestStatus.declined,
                retryAfter: retryAt,
                reason: 'declined',
              ),
            ),
          );
          async.flushMicrotasks();
          expect(
            cardState(),
            ChallengeCardCooling(retryAt: retryAt, justResolved: true),
          );
          expect(readyOf(bloc).notice, isA<DeclinedNotice>());

          // "Not this time" gives way to the retry countdown…
          async.elapse(const Duration(seconds: 3));
          expect(cardState(), ChallengeCardCooling(retryAt: retryAt));

          // …and the card is joinable again once retryAfter passes.
          async.elapse(const Duration(seconds: 13));
          expect(cardState(), const ChallengeCardOpen());
          expect(readyOf(bloc).outgoing, isEmpty);

          unawaited(bloc.close());
          async.flushMicrotasks();
        });
      },
    );

    test('a failed join removes the optimistic entry and explains', () async {
      when(
        () => repository.requestJoin('c1'),
      ).thenThrow(const ApiException('creator_away', code: 'creator_away'));

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();
      bloc.add(const JoinRequested('c1'));
      await pumpEventQueue();

      final ready = readyOf(bloc);
      expect(ready.outgoing, isEmpty);
      expect(ready.notice, isA<CreatorAwayNotice>());

      await bloc.close();
    });

    test('incoming presented → accept → startDuelId', () async {
      final own = challenge('mine', creator: me);
      when(
        () => repository.fetchLobby(any()),
      ).thenAnswer((_) async => snapshot(challenges: [own]));
      when(
        () => repository.respondJoin('req-1', accept: true),
      ).thenAnswer((_) async => 'duel-9');

      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();

      events.add(
        IncomingRequestPresented(
          IncomingJoinRequest(
            requestId: 'req-1',
            challengeId: 'mine',
            requester: player('rival'),
            expiresAt: start.add(const Duration(seconds: 5)),
          ),
        ),
      );
      await pumpEventQueue();
      expect(readyOf(bloc).incoming?.requestId, 'req-1');

      bloc.add(const IncomingAccepted());
      await pumpEventQueue();

      final ready = readyOf(bloc);
      expect(ready.startDuelId, 'duel-9');
      expect(ready.incoming, isNull);
      expect(ready.isBusy, isFalse);

      await bloc.close();
    });

    test('an incoming timeout calls respondJoin(false) exactly once', () {
      fakeAsync((async) {
        final clock = ServerClock(localNow: () => start.add(async.elapsed));
        final own = challenge('mine', creator: me);
        when(
          () => repository.fetchLobby(any()),
        ).thenAnswer((_) async => snapshot(challenges: [own]));
        when(
          () => repository.respondJoin(any(), accept: any(named: 'accept')),
        ).thenAnswer((_) async => null);

        final bloc = buildBloc(clock: clock)..add(const ArenaOpened());
        async.flushMicrotasks();
        events.add(
          IncomingRequestPresented(
            IncomingJoinRequest(
              requestId: 'req-1',
              challengeId: 'mine',
              requester: player('rival'),
              expiresAt: start.add(const Duration(seconds: 5)),
            ),
          ),
        );
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 4));
        verifyNever(
          () => repository.respondJoin(any(), accept: any(named: 'accept')),
        );

        // Several ticks past the deadline still answer only once.
        async.elapse(const Duration(seconds: 5));
        verify(() => repository.respondJoin('req-1', accept: false)).called(1);
        expect(readyOf(bloc).incoming, isNull);

        unawaited(bloc.close());
        async.flushMicrotasks();
      });
    });

    test(
      'visibility false → setPresence(false) and local requests cleared',
      () async {
        when(() => repository.requestJoin('c1')).thenAnswer(
          (_) async => const OutgoingJoinRequest(
            requestId: 'r1',
            challengeId: 'c1',
            status: JoinRequestStatus.queued,
          ),
        );

        final bloc = buildBloc()..add(const ArenaOpened());
        await pumpEventQueue();
        bloc.add(const JoinRequested('c1'));
        await pumpEventQueue();
        expect(readyOf(bloc).outgoing, isNotEmpty);

        bloc.add(const ArenaVisibilityChanged(visible: false));
        await pumpEventQueue();

        verify(() => repository.setPresence(present: false)).called(1);
        expect(readyOf(bloc).outgoing, isEmpty);

        // Coming back re-announces presence and re-fetches the snapshot.
        bloc.add(const ArenaVisibilityChanged(visible: true));
        await pumpEventQueue();
        verify(() => repository.setPresence(present: true)).called(2);
        verify(() => repository.fetchLobby('en')).called(2);

        await bloc.close();
      },
    );

    test('channel re-live after a drop → snapshot refetched', () async {
      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();

      // Joining: false, then true once both channels are up — not a
      // reconnect, so no refetch and no "Reconnecting…".
      events.add(const LobbyChannelStatusChanged(isLive: false));
      await pumpEventQueue();
      expect(readyOf(bloc).isLive, isTrue);
      events.add(const LobbyChannelStatusChanged(isLive: true));
      await pumpEventQueue();
      verify(() => repository.fetchLobby('en')).called(1);

      events.add(const LobbyChannelStatusChanged(isLive: false));
      await pumpEventQueue();
      expect(readyOf(bloc).isLive, isFalse);

      events.add(const LobbyChannelStatusChanged(isLive: true));
      await pumpEventQueue();
      expect(readyOf(bloc).isLive, isTrue);
      verify(() => repository.fetchLobby('en')).called(1);

      await bloc.close();
    });

    test('a duel start while visible sets startDuelId', () async {
      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();

      events.add(const DuelStarted('duel-1'));
      await pumpEventQueue();
      expect(readyOf(bloc).startDuelId, 'duel-1');

      await bloc.close();
    });

    test('close() fire-and-forgets setPresence(false)', () async {
      final bloc = buildBloc()..add(const ArenaOpened());
      await pumpEventQueue();
      await bloc.close();
      await pumpEventQueue();
      verify(() => repository.setPresence(present: false)).called(1);
    });
  });

  group('DuelArenaReady derived getters', () {
    DuelArenaReady ready({
      List<DuelChallenge> challenges = const [],
      List<DuelChallenge> recentlyEnded = const [],
      DuelLobbyMe? lobbyMe,
      String? activeDuelId,
    }) => DuelArenaReady(
      config: const DuelConfig(),
      me: lobbyMe ?? DuelLobbyMe(player: me),
      challenges: challenges,
      recentlyEnded: recentlyEnded,
      now: start,
      activeDuelId: activeDuelId,
    );

    test('fairness follows the ELO gap thresholds', () {
      final state = ready();
      Fairness gap(int delta) => state.fairnessFor(
        challenge('x', creator: player('x', elo: 1200 + delta)),
      );

      expect(gap(0), Fairness.even);
      expect(gap(100), Fairness.even);
      expect(gap(-100), Fairness.even);
      expect(gap(120), Fairness.even);
      expect(gap(150), Fairness.tough);
      expect(gap(400), Fairness.tough);
      expect(gap(-150), Fairness.favourable);
      expect(gap(-400), Fairness.favourable);
    });

    test('card state: own, in progress, away, open', () {
      final state = ready();
      expect(
        state.cardStateFor(challenge('a', creator: me, creatorPresent: false)),
        const ChallengeCardOwn(paused: true),
      );
      expect(
        state.cardStateFor(
          challenge(
            'b',
            status: ChallengeStatus.matched,
          ).copyWith(opponentGuestTag: '0042'),
        ),
        const ChallengeCardInProgress(opponentGuestTag: '0042'),
      );
      expect(
        state.cardStateFor(challenge('c', creatorPresent: false)),
        const ChallengeCardAway(),
      );
      expect(state.cardStateFor(challenge('d')), const ChallengeCardOpen());
      expect(
        state.cardStateFor(
          challenge(
            'e',
            status: ChallengeStatus.ended,
          ).copyWith(endReason: 'cancelled'),
        ),
        const ChallengeCardEnded(endReason: 'cancelled'),
      );
    });

    test('feedItems merges challenges and recentlyEnded, oldest first', () {
      final live = challenge('live', createdAgo: const Duration(minutes: 1));
      final ended = challenge(
        'ended',
        createdAgo: const Duration(minutes: 5),
        status: ChallengeStatus.ended,
      );
      final state = ready(challenges: [live], recentlyEnded: [ended]);

      expect(state.feedItems.map((c) => c.id), ['ended', 'live']);
      // No recentlyEnded: just the live list, unchanged.
      expect(ready(challenges: [live]).feedItems, [live]);
    });

    test('composer: in duel, sign in, own open, cool-off, create', () {
      final own = challenge('mine', creator: me);
      expect(
        ready(activeDuelId: 'd1').composerState,
        const ComposerInDuel('d1'),
      );
      expect(
        ready(
          lobbyMe: DuelLobbyMe(
            player: player('me', isGuest: true),
            isGuest: true,
          ),
        ).composerState,
        const ComposerSignIn(),
      );
      expect(ready(challenges: [own]).composerState, ComposerOwnOpen(own));
      final until = start.add(const Duration(seconds: 30));
      expect(
        ready(
          lobbyMe: DuelLobbyMe(player: me, cooldownEndsAt: until),
        ).composerState,
        ComposerCooldown(until),
      );
      expect(
        ready(
          lobbyMe: DuelLobbyMe(
            player: me,
            cooldownEndsAt: start.subtract(const Duration(seconds: 1)),
          ),
        ).composerState,
        const ComposerCreate(),
      );
    });
  });
}
