import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_room_event.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_rematch_cubit.dart';

class _MockLiveDuelRepository extends Mock implements LiveDuelRepository {}

void main() {
  late _MockLiveDuelRepository repository;
  late StreamController<DuelRoomEvent> room;
  late StreamController<String> starts;

  const duelId = 'duel_1';
  const newDuelId = 'duel_2';
  const window = Duration(seconds: 30);
  const opponent = DuelPlayer(
    id: 'user_danish',
    name: 'Danish',
    avatarEmoji: '🐯',
    elo: 1380,
  );

  DuelRematchCubit build() => DuelRematchCubit(
    repository,
    duelId: duelId,
    opponent: opponent,
    window: window,
  );

  void stubRequest(RematchStatus status, [String? id]) {
    when(
      () => repository.requestRematch(duelId),
    ).thenAnswer((_) async => (status: status, duelId: id));
  }

  setUp(() {
    repository = _MockLiveDuelRepository();
    room = StreamController<DuelRoomEvent>.broadcast();
    starts = StreamController<String>.broadcast();
    when(() => repository.roomEvents(duelId)).thenAnswer((_) => room.stream);
    when(() => repository.duelStarts()).thenAnswer((_) => starts.stream);
    when(() => repository.declineRematch(duelId)).thenAnswer((_) async {});
  });

  tearDown(() async {
    await room.close();
    await starts.close();
  });

  group('DuelRematchCubit', () {
    test('starts idle, listening to the room and the inbox', () async {
      final cubit = build();

      expect(cubit.state, const RematchIdle());
      verify(() => repository.roomEvents(duelId)).called(1);
      verify(() => repository.duelStarts()).called(1);

      await cubit.close();
    });

    blocTest<DuelRematchCubit, DuelRematchState>(
      'success path: asking first waits for the opponent',
      setUp: () => stubRequest(RematchStatus.requested),
      build: build,
      act: (cubit) => cubit.request(),
      expect: () => const [RematchWaiting()],
      verify: (_) => verify(() => repository.requestRematch(duelId)).called(1),
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'asking after the opponent already asked starts the rematch at once',
      setUp: () => stubRequest(RematchStatus.started, newDuelId),
      build: build,
      act: (cubit) => cubit.request(),
      expect: () => const [RematchStarting(newDuelId)],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'a second tap while waiting does not ask again',
      setUp: () => stubRequest(RematchStatus.requested),
      build: build,
      act: (cubit) async {
        await cubit.request();
        await cubit.request();
      },
      expect: () => const [RematchWaiting()],
      verify: (_) => verify(() => repository.requestRematch(duelId)).called(1),
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      "the opponent's request becomes an offer",
      build: build,
      act: (_) => room.add(
        RematchUpdate(
          status: RematchStatus.requested,
          requestedBy: opponent.id,
        ),
      ),
      expect: () => const [RematchOffered()],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      "this player's own request echoed back by the room is not an offer",
      build: build,
      act: (_) => room.add(
        const RematchUpdate(
          status: RematchStatus.requested,
          requestedBy: 'user_me',
        ),
      ),
      expect: () => const <DuelRematchState>[],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'accepting an offer starts the rematch',
      setUp: () => stubRequest(RematchStatus.started, newDuelId),
      build: build,
      act: (cubit) async {
        room.add(
          RematchUpdate(
            status: RematchStatus.requested,
            requestedBy: opponent.id,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await cubit.accept();
      },
      expect: () => const [RematchOffered(), RematchStarting(newDuelId)],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      "the room's started event moves to the new duel",
      setUp: () => stubRequest(RematchStatus.requested),
      build: build,
      act: (cubit) async {
        await cubit.request();
        room.add(
          const RematchUpdate(status: RematchStatus.started, duelId: newDuelId),
        );
      },
      expect: () => const [RematchWaiting(), RematchStarting(newDuelId)],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      "the inbox's duel_start moves to the new duel",
      build: build,
      act: (_) => starts.add(newDuelId),
      expect: () => const [RematchStarting(newDuelId)],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'a decline by the opponent makes the rematch unavailable',
      build: build,
      act: (_) => room.add(
        RematchUpdate(status: RematchStatus.declined, requestedBy: opponent.id),
      ),
      expect: () => const [RematchUnavailable()],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'room events other than rematch updates are ignored',
      build: build,
      act: (_) {
        room
          ..add(const RoomChannelStatusChanged(isLive: false))
          ..add(const OpponentPresenceChanged(online: false));
      },
      expect: () => const <DuelRematchState>[],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'failure path: the server refusing (rematch_unavailable) ends it',
      setUp: () => when(() => repository.requestRematch(duelId)).thenThrow(
        const ApiException('rematch_unavailable', code: 'rematch_unavailable'),
      ),
      build: build,
      act: (cubit) => cubit.request(),
      expect: () => const [RematchUnavailable()],
    );

    blocTest<DuelRematchCubit, DuelRematchState>(
      'failure path: a network failure also ends it',
      setUp: () => when(
        () => repository.requestRematch(duelId),
      ).thenThrow(const ApiException.network()),
      build: build,
      act: (cubit) => cubit.request(),
      expect: () => const [RematchUnavailable()],
    );

    test('the window closing makes the rematch unavailable', () {
      fakeAsync((async) {
        final cubit = build();

        async.elapse(window - const Duration(seconds: 1));
        expect(cubit.state, const RematchIdle());

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state, const RematchUnavailable());

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('the window closing never undoes a started rematch', () {
      fakeAsync((async) {
        final cubit = build();

        starts.add(newDuelId);
        async.flushMicrotasks();
        async.elapse(window * 2);

        expect(cubit.state, const RematchStarting(newDuelId));

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('closing declines, so the opponent sees this player left', () async {
      final cubit = build();

      await cubit.close();

      verify(() => repository.declineRematch(duelId)).called(1);
    });

    test('closing after the rematch started does not decline', () async {
      final cubit = build();
      starts.add(newDuelId);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, const RematchStarting(newDuelId));

      await cubit.close();

      verifyNever(() => repository.declineRematch(any()));
    });

    test('a failing decline on close is swallowed', () async {
      when(
        () => repository.declineRematch(duelId),
      ).thenAnswer((_) async => throw const ApiException.network());
      final cubit = build();

      await cubit.close();
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.declineRematch(duelId)).called(1);
    });
  });
}
