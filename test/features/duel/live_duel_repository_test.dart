import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/live_duel_api.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';
import 'package:quizoo/features/duel/domain/duel_room_event.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/duel/domain/duel_side.dart';
import 'package:quizoo/features/duel/domain/duel_side_result.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/live_duel_outcome.dart';
import 'package:quizoo/features/duel/domain/live_duel_round_state.dart';
import 'package:quizoo/features/duel/domain/live_duel_snapshot.dart';

class _MockLiveDuelApi extends Mock implements LiveDuelApi {}

// ---------------------------------------------------------------- fixtures
// Shapes copied from plan 017's Phase 5 RPCs and the room broadcast table.

/// Round-trips through JSON so nested maps/lists are exactly what
/// `supabase.rpc` / Realtime hand the API.
Map<String, dynamic> _wire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

const _serverNow = '2026-09-27T12:00:05.100000+00:00';

/// `_duel_player_json(me, duel.subcategory_id)`, ELO = `p2_elo_before`.
const Map<String, Object?> _meJson = {
  'id': 'u-me',
  'name': 'Zara',
  'isGuest': false,
  'guestTag': null,
  'avatar': '🦊',
  'elo': 1240,
  'league': 'silver',
  'topicLevel': 5,
  'isBot': false,
};

const _me = DuelPlayer(
  id: 'u-me',
  name: 'Zara',
  avatarEmoji: '🦊',
  elo: 1240,
  league: 'silver',
  topicLevel: 5,
);

/// A guest opponent.
const Map<String, Object?> _opponentJson = {
  'id': 'u-opp',
  'name': null,
  'isGuest': true,
  'guestTag': '4821',
  'avatar': '🐼',
  'elo': 1310,
  'league': 'gold',
  'topicLevel': 1,
  'isBot': false,
};

const _opponent = DuelPlayer(
  id: 'u-opp',
  name: null,
  isGuest: true,
  guestTag: '4821',
  avatarEmoji: '🐼',
  elo: 1310,
  league: 'gold',
  topicLevel: 1,
);

const Map<String, Object?> _topicJson = {
  'id': 'sub-cricket',
  'name': 'Cricket',
  'emoji': '🏏',
  'plateColor': '#E4F7F1',
  'categoryId': 'cat-sports',
  'categoryName': 'Sports',
  'categoryEmoji': '⚽',
};

const _topic = DuelTopic(
  id: 'sub-cricket',
  name: 'Cricket',
  emoji: '🏏',
  plateColor: '#E4F7F1',
  categoryId: 'cat-sports',
  categoryName: 'Sports',
  categoryEmoji: '⚽',
);

const Map<String, Object?> _questionJson = {
  'prompt': 'Who won the 1992 Cricket World Cup?',
  'options': ['Australia', 'Pakistan', 'England', 'India'],
  'kind': 'image',
  'mediaUrl': 'https://cdn.example.test/q/1992.webp',
};

const _question = DuelQuestion(
  text: 'Who won the 1992 Cricket World Cup?',
  options: ['Australia', 'Pakistan', 'England', 'India'],
  kind: 'image',
  mediaUrl: 'https://cdn.example.test/q/1992.webp',
);

/// `get_duel_state` history — perspective-mapped (me/opponent).
const List<Map<String, Object?>> _historyJson = [
  {
    'round': 1,
    'outcome': 'me',
    'correctIndex': 1,
    'myChoice': 1,
    'opponentChoice': 3,
    'myMs': 2400,
    'opponentMs': 5600,
  },
  {
    'round': 2,
    'outcome': 'opponent',
    'correctIndex': 0,
    'myChoice': 0,
    'opponentChoice': 0,
    'myMs': 4700,
    'opponentMs': 3200,
  },
  {
    // I timed out; they answered wrong.
    'round': 3,
    'outcome': 'draw',
    'correctIndex': 2,
    'myChoice': null,
    'opponentChoice': 1,
    'myMs': null,
    'opponentMs': 8000,
  },
];

/// What `DuelRoundRecord.live` must build from [_historyJson] with a 12 s
/// round.
const _history = [
  DuelRoundRecord(
    roundNumber: 1,
    playerCorrect: true,
    opponentCorrect: false,
    playerAnswerSeconds: 2,
    opponentAnswerSeconds: 6,
    outcome: RoundOutcome.playerWon,
    correctIndex: 1,
    playerChoice: 1,
    opponentChoice: 3,
  ),
  DuelRoundRecord(
    roundNumber: 2,
    playerCorrect: true,
    opponentCorrect: true,
    playerAnswerSeconds: 5,
    opponentAnswerSeconds: 3,
    outcome: RoundOutcome.opponentWon,
    correctIndex: 0,
    playerChoice: 0,
    opponentChoice: 0,
  ),
  DuelRoundRecord(
    roundNumber: 3,
    playerCorrect: false,
    opponentCorrect: false,
    playerAnswerSeconds: 12,
    opponentAnswerSeconds: 8,
    outcome: RoundOutcome.draw,
    correctIndex: 2,
    opponentChoice: 1,
  ),
];

/// `get_duel_state` mid-duel: round 4 is open, I have locked, they have not.
const Map<String, Object?> _activeStateJson = {
  'serverNow': _serverNow,
  'duelId': 'd-live',
  'status': 'active',
  'mySide': 'p2',
  'isRanked': true,
  'origin': 'challenge',
  'topic': _topicJson,
  'me': _meJson,
  'opponent': _opponentJson,
  'config': {'rounds': 5, 'roundSeconds': 12, 'revealSeconds': 3},
  'currentRound': 4,
  'round': {
    'number': 4,
    'startsAt': '2026-09-27T12:00:02.000000+00:00',
    'deadline': '2026-09-27T12:00:14.750000+00:00',
    'myLocked': true,
    'myChoice': 2,
    'myMs': 3100,
    'opponentLocked': false,
    'opponentMs': null,
    'question': _questionJson,
  },
  'history': _historyJson,
  'myScore': 1,
  'opponentScore': 1,
  'result': null,
};

Matcher _isParsingError() => throwsA(
  isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.parsing),
);

// ------------------------------------------------------------------- tests

void main() {
  final start = DateTime.utc(2026, 9, 27, 12);

  late _MockLiveDuelApi api;
  late DateTime local;
  late ServerClock clock;
  late LiveDuelRepository repository;

  setUp(() {
    api = _MockLiveDuelApi();
    local = start;
    clock = ServerClock(localNow: () => local);
    repository = LiveDuelRepository(api, clock);
  });

  /// An API answer that takes 200 ms of local time: with [_serverNow] at
  /// start + 5.1 s the clock offset becomes exactly 5 s.
  Future<Map<String, dynamic>> answer(Map<String, Object?> json) async {
    local = local.add(const Duration(milliseconds: 200));
    return _wire(json);
  }

  test('currentUserId comes from the API', () {
    when(() => api.currentUserId).thenReturn('u-me');

    expect(repository.currentUserId, 'u-me');
  });

  group('fetchState', () {
    test('decodes the perspective-mapped snapshot of a live duel', () async {
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer(_activeStateJson));

      final snapshot = await repository.fetchState('d-live');

      verify(() => api.fetchState('d-live')).called(1);
      expect(
        snapshot,
        LiveDuelSnapshot(
          serverNow: DateTime.utc(2026, 9, 27, 12, 0, 5, 100),
          duelId: 'd-live',
          status: LiveDuelStatus.active,
          mySide: DuelSide.p2,
          isRanked: true,
          origin: 'challenge',
          topic: _topic,
          me: _me,
          opponent: _opponent,
          config: const DuelConfig(
            rounds: 5,
            roundSeconds: 12,
            revealSeconds: 3,
          ),
          currentRound: 4,
          round: LiveDuelRoundState(
            number: 4,
            startsAt: DateTime.utc(2026, 9, 27, 12, 0, 2),
            deadline: DateTime.utc(2026, 9, 27, 12, 0, 14, 750),
            myLocked: true,
            myChoice: 2,
            myMs: 3100,
            question: _question,
          ),
          history: _history,
          myScore: 1,
          opponentScore: 1,
        ),
      );
      expect(snapshot.isLive, isTrue);
    });

    test('maps history through DuelRoundRecord.live', () async {
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer(_activeStateJson));

      final snapshot = await repository.fetchState('d-live');

      expect(snapshot.history, [
        for (final (i, entry) in _historyJson.indexed)
          DuelRoundRecord.live(
            roundNumber: i + 1,
            outcome: [
              RoundOutcome.playerWon,
              RoundOutcome.opponentWon,
              RoundOutcome.draw,
            ][i],
            correctIndex: entry['correctIndex']! as int,
            roundSeconds: 12,
            playerChoice: entry['myChoice'] as int?,
            opponentChoice: entry['opponentChoice'] as int?,
            playerMs: entry['myMs'] as int?,
            opponentMs: entry['opponentMs'] as int?,
          ),
      ]);
    });

    test('feeds serverNow into the ServerClock', () async {
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer(_activeStateJson));

      await repository.fetchState('d-live');

      expect(clock.offset, const Duration(seconds: 5));
    });

    test('a round whose question is still withheld has none', () async {
      final round = Map<String, Object?>.of(
        _activeStateJson['round']! as Map<String, Object?>,
      )..['question'] = null;
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer({..._activeStateJson, 'round': round}));

      final snapshot = await repository.fetchState('d-live');

      expect(snapshot.round?.number, 4);
      expect(snapshot.round?.question, isNull);
    });

    test('a pending duel has no round, no history and zero scores', () async {
      when(() => api.fetchState(any())).thenAnswer(
        (_) => answer({
          ..._activeStateJson,
          'status': 'pending',
          'mySide': 'p1',
          'origin': 'matchmaking',
          'currentRound': 0,
          'round': null,
          'history': <Object?>[],
          'myScore': 0,
          'opponentScore': 0,
        }),
      );

      final snapshot = await repository.fetchState('d-live');

      expect(snapshot.status, LiveDuelStatus.pending);
      expect(snapshot.mySide, DuelSide.p1);
      expect(snapshot.origin, 'matchmaking');
      expect(snapshot.currentRound, 0);
      expect(snapshot.round, isNull);
      expect(snapshot.history, isEmpty);
      expect(snapshot.result, isNull);
      expect(snapshot.isLive, isTrue);
    });

    test('a missing config falls back to the server defaults', () async {
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer({..._activeStateJson}..remove('config')));

      final snapshot = await repository.fetchState('d-live');

      expect(snapshot.config, DuelConfig.fallback);
      // Round 3's timeout then counts as the default 15 s round.
      expect(snapshot.history[2].playerAnswerSeconds, 15);
    });

    test('a finished duel carries its settlement', () async {
      when(() => api.fetchState(any())).thenAnswer(
        (_) => answer({
          ..._activeStateJson,
          'status': 'complete',
          'currentRound': 3,
          'round': null,
          'myScore': 3,
          'opponentScore': 1,
          'result': {
            'reason': 'forfeit',
            'won': true,
            'draw': false,
            'eloBefore': 1240,
            'eloAfter': 1256,
            'coins': 200,
            'xp': 50,
            'badgeIds': ['badge_duelist'],
            'opponentForfeited': true,
            'youForfeited': false,
            'myAvgMs': 3100.5,
            'opponentAvgMs': 5200,
          },
        }),
      );

      final snapshot = await repository.fetchState('d-live');

      expect(snapshot.status, LiveDuelStatus.complete);
      expect(snapshot.isLive, isFalse);
      expect(
        snapshot.result,
        const LiveDuelOutcome(
          reason: 'forfeit',
          won: true,
          eloBefore: 1240,
          eloAfter: 1256,
          coins: 200,
          xp: 50,
          badgeIds: ['badge_duelist'],
          opponentForfeited: true,
          myAvgMs: 3100.5,
          opponentAvgMs: 5200,
        ),
      );
    });

    test('an unknown status is a parsing ApiException', () async {
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer({..._activeStateJson, 'status': 'paused'}));

      await expectLater(repository.fetchState('d-live'), _isParsingError());
    });

    test('a missing player is a parsing ApiException', () async {
      when(
        () => api.fetchState(any()),
      ).thenAnswer((_) => answer({..._activeStateJson}..remove('opponent')));

      await expectLater(repository.fetchState('d-live'), _isParsingError());
    });
  });

  group('markReady', () {
    test('returns the duel status and syncs the clock', () async {
      when(() => api.markReady(any())).thenAnswer(
        (_) => answer({'serverNow': _serverNow, 'status': 'active'}),
      );

      final status = await repository.markReady('d-live');

      verify(() => api.markReady('d-live')).called(1);
      expect(status, LiveDuelStatus.active);
      expect(clock.offset, const Duration(seconds: 5));
    });

    test('pending while the opponent is not ready yet', () async {
      when(() => api.markReady(any())).thenAnswer(
        (_) => answer({'serverNow': _serverNow, 'status': 'pending'}),
      );

      expect(await repository.markReady('d-live'), LiveDuelStatus.pending);
    });

    test('an unknown status is a parsing ApiException', () async {
      when(() => api.markReady(any())).thenAnswer(
        (_) => answer({'serverNow': _serverNow, 'status': 'warming_up'}),
      );

      await expectLater(repository.markReady('d-live'), _isParsingError());
    });
  });

  group('fetchRound', () {
    test('decodes the round and its question, and syncs the clock', () async {
      when(() => api.fetchRound(any(), any())).thenAnswer(
        (_) => answer({
          'round': 3,
          'startsAt': '2026-09-27T12:00:05.400000+00:00',
          'deadline': '2026-09-27T12:00:20.650000+00:00',
          'question': {
            'prompt': 'How many balls are in an over?',
            'options': ['4', '5', '6', '8'],
            'kind': 'text',
            'mediaUrl': null,
          },
          'serverNow': _serverNow,
        }),
      );

      final round = await repository.fetchRound('d-live', 3);

      verify(() => api.fetchRound('d-live', 3)).called(1);
      expect(round.round, 3);
      expect(round.startsAt, DateTime.utc(2026, 9, 27, 12, 0, 5, 400));
      expect(round.deadline, DateTime.utc(2026, 9, 27, 12, 0, 20, 650));
      expect(
        round.question,
        const DuelQuestion(
          text: 'How many balls are in an over?',
          options: ['4', '5', '6', '8'],
        ),
      );
      expect(clock.offset, const Duration(seconds: 5));
    });

    test('a round without its question is a parsing ApiException', () async {
      when(() => api.fetchRound(any(), any())).thenAnswer(
        (_) => answer({
          'round': 3,
          'startsAt': '2026-09-27T12:00:05.400000+00:00',
          'deadline': '2026-09-27T12:00:20.650000+00:00',
          'serverNow': _serverNow,
        }),
      );

      await expectLater(repository.fetchRound('d-live', 3), _isParsingError());
    });
  });

  group('submitAnswer', () {
    test('forwards round, choice and client time', () async {
      when(
        () => api.submitAnswer(
          any(),
          round: any(named: 'round'),
          choice: any(named: 'choice'),
          clientMs: any(named: 'clientMs'),
        ),
      ).thenAnswer((_) => answer({'accepted': true}));

      await repository.submitAnswer(
        'd-live',
        round: 2,
        choice: 1,
        clientMs: 3120,
      );

      verify(
        () => api.submitAnswer('d-live', round: 2, choice: 1, clientMs: 3120),
      ).called(1);
    });

    test('a null choice (timeout) is forwarded as null', () async {
      when(
        () => api.submitAnswer(
          any(),
          round: any(named: 'round'),
          choice: any(named: 'choice'),
          clientMs: any(named: 'clientMs'),
        ),
      ).thenAnswer((_) => answer({'accepted': true}));

      await repository.submitAnswer(
        'd-live',
        round: 5,
        choice: null,
        clientMs: 15000,
      );

      verify(
        () =>
            api.submitAnswer('d-live', round: 5, choice: null, clientMs: 15000),
      ).called(1);
    });
  });

  group('claimTimeout', () {
    test('forwards the duel and round', () async {
      when(
        () => api.claimTimeout(any(), any()),
      ).thenAnswer((_) => answer({'resolved': true}));

      await repository.claimTimeout('d-live', 4);

      verify(() => api.claimTimeout('d-live', 4)).called(1);
    });
  });

  group('heartbeat', () {
    test('returns how long ago the opponent was seen', () async {
      when(() => api.heartbeat(any())).thenAnswer(
        (_) => answer({'serverNow': _serverNow, 'opponentSeenAgoMs': 1800}),
      );

      expect(await repository.heartbeat('d-live'), 1800);
      verify(() => api.heartbeat('d-live')).called(1);
      expect(clock.offset, const Duration(seconds: 5));
    });

    test('null when the server does not know', () async {
      when(() => api.heartbeat(any())).thenAnswer(
        (_) => answer({'serverNow': _serverNow, 'opponentSeenAgoMs': null}),
      );

      expect(await repository.heartbeat('d-live'), isNull);
    });

    test('a non-numeric value is a parsing ApiException', () async {
      when(() => api.heartbeat(any())).thenAnswer(
        (_) => answer({'serverNow': _serverNow, 'opponentSeenAgoMs': 'soon'}),
      );

      await expectLater(repository.heartbeat('d-live'), _isParsingError());
    });
  });

  group('leave / declineRematch', () {
    test('leave forwards the duel id', () async {
      when(() => api.leave(any())).thenAnswer((_) async {});

      await repository.leave('d-live');

      verify(() => api.leave('d-live')).called(1);
    });

    test('declineRematch forwards the duel id', () async {
      when(() => api.declineRematch(any())).thenAnswer((_) async {});

      await repository.declineRematch('d-live');

      verify(() => api.declineRematch('d-live')).called(1);
    });
  });

  group('requestRematch', () {
    test('requested: waiting on the opponent, no duel yet', () async {
      when(
        () => api.requestRematch(any()),
      ).thenAnswer((_) => answer({'status': 'requested'}));

      final rematch = await repository.requestRematch('d-live');

      verify(() => api.requestRematch('d-live')).called(1);
      expect(rematch.status, RematchStatus.requested);
      expect(rematch.duelId, isNull);
    });

    test('started: the opponent had already asked', () async {
      when(
        () => api.requestRematch(any()),
      ).thenAnswer((_) => answer({'status': 'started', 'duelId': 'd-next'}));

      final rematch = await repository.requestRematch('d-live');

      expect(rematch.status, RematchStatus.started);
      expect(rematch.duelId, 'd-next');
    });

    test('an unknown status is a parsing ApiException', () async {
      when(
        () => api.requestRematch(any()),
      ).thenAnswer((_) => answer({'status': 'maybe'}));

      await expectLater(repository.requestRematch('d-live'), _isParsingError());
    });
  });

  group('raised identifiers propagate unchanged', () {
    final cases = <(String, String, Future<void> Function(LiveDuelRepository))>[
      ('fetchState', 'duel_not_found', (r) => r.fetchState('d-x')),
      ('fetchState', 'not_a_participant', (r) => r.fetchState('d-x')),
      ('markReady', 'duel_not_found', (r) => r.markReady('d-x')),
      ('markReady', 'not_a_participant', (r) => r.markReady('d-x')),
      ('fetchRound', 'too_early', (r) => r.fetchRound('d-x', 2)),
      ('fetchRound', 'round_closed', (r) => r.fetchRound('d-x', 2)),
      (
        'submitAnswer',
        'already_answered',
        (r) => r.submitAnswer('d-x', round: 1, choice: 0, clientMs: 900),
      ),
      (
        'submitAnswer',
        'round_closed',
        (r) => r.submitAnswer('d-x', round: 1, choice: 0, clientMs: 900),
      ),
      (
        'submitAnswer',
        'invalid_choice',
        (r) => r.submitAnswer('d-x', round: 1, choice: 9, clientMs: 900),
      ),
      ('claimTimeout', 'too_early', (r) => r.claimTimeout('d-x', 1)),
      ('requestRematch', 'rematch_unavailable', (r) => r.requestRematch('d-x')),
    ];

    for (final (method, code, call) in cases) {
      test('$method → ApiException($code)', () async {
        final error = ApiException(code, kind: ApiErrorKind.server, code: code);
        Future<Never> fail(Invocation _) async => throw error;
        when(() => api.fetchState(any())).thenAnswer(fail);
        when(() => api.markReady(any())).thenAnswer(fail);
        when(() => api.fetchRound(any(), any())).thenAnswer(fail);
        when(
          () => api.submitAnswer(
            any(),
            round: any(named: 'round'),
            choice: any(named: 'choice'),
            clientMs: any(named: 'clientMs'),
          ),
        ).thenAnswer(fail);
        when(() => api.claimTimeout(any(), any())).thenAnswer(fail);
        when(() => api.requestRematch(any())).thenAnswer(fail);

        await expectLater(call(repository), throwsA(same(error)));
        expect(clock.offset, Duration.zero);
      });
    }
  });

  group('roomEvents', () {
    late StreamController<DuelBroadcast> room;

    setUp(() {
      room = StreamController<DuelBroadcast>();
      when(() => api.roomStream(any())).thenAnswer((_) => room.stream);
    });

    /// Listens to the room and returns everything it emitted.
    List<DuelRoomEvent> listen({String? opponentId}) {
      final events = <DuelRoomEvent>[];
      final subscription = repository
          .roomEvents('d-live', opponentId: opponentId)
          .listen(events.add);
      addTearDown(subscription.cancel);
      return events;
    }

    BroadcastMessage message(String event, Map<String, Object?> payload) =>
        BroadcastMessage(
          event: event,
          payload: _wire({...payload, 'serverNow': _serverNow}),
        );

    test('listens to the duel\'s room', () async {
      listen();
      await pumpEventQueue();

      verify(() => api.roomStream('d-live')).called(1);
    });

    test('round_start → RoundScheduled (no question)', () async {
      final events = listen();

      room.add(
        message('round_start', {
          'round': 2,
          'startsAt': '2026-09-27T12:00:08.000000+00:00',
          'deadline': '2026-09-27T12:00:23.750000+00:00',
          'roundSeconds': 15,
          'totalRounds': 5,
        }),
      );
      await pumpEventQueue();

      expect(events, [
        RoundScheduled(
          round: 2,
          startsAt: DateTime.utc(2026, 9, 27, 12, 0, 8),
          deadline: DateTime.utc(2026, 9, 27, 12, 0, 23, 750),
          roundSeconds: 15,
          totalRounds: 5,
        ),
      ]);
    });

    test('answer_locked → AnswerLocked, a timeout with a null ms', () async {
      final events = listen();

      room
        ..add(
          message('answer_locked', {'userId': 'u-opp', 'round': 2, 'ms': 3100}),
        )
        ..add(
          message('answer_locked', {'userId': 'u-me', 'round': 2, 'ms': null}),
        );
      await pumpEventQueue();

      expect(events, const [
        AnswerLocked(userId: 'u-opp', round: 2, ms: 3100),
        AnswerLocked(userId: 'u-me', round: 2),
      ]);
    });

    test('round_result → RoundResolved in seat terms', () async {
      final events = listen();

      room
        ..add(
          message('round_result', {
            'round': 2,
            'outcome': 'p2',
            'correctIndex': 1,
            'p1Choice': 3,
            'p2Choice': 1,
            'p1Ms': 5600,
            'p2Ms': 2400,
            'p1Rounds': 0,
            'p2Rounds': 2,
          }),
        )
        ..add(
          message('round_result', {
            'round': 3,
            'outcome': 'draw',
            'correctIndex': 0,
            'p1Choice': null,
            'p2Choice': null,
            'p1Ms': null,
            'p2Ms': null,
            'p1Rounds': 0,
            'p2Rounds': 2,
          }),
        );
      await pumpEventQueue();

      expect(events, const [
        RoundResolved(
          round: 2,
          outcome: RoundSideOutcome.p2,
          correctIndex: 1,
          p1Choice: 3,
          p2Choice: 1,
          p1Ms: 5600,
          p2Ms: 2400,
          p1Rounds: 0,
          p2Rounds: 2,
        ),
        RoundResolved(
          round: 3,
          outcome: RoundSideOutcome.draw,
          correctIndex: 0,
          p1Rounds: 0,
          p2Rounds: 2,
        ),
      ]);
      final resolved = events.first as RoundResolved;
      expect(resolved.choiceOf(DuelSide.p2), 1);
      expect(resolved.msOf(DuelSide.p1), 5600);
      expect(resolved.roundsOf(DuelSide.p2), 2);
    });

    test('duel_end (completed) → DuelFinished with both settlements', () async {
      final events = listen();

      room.add(
        message('duel_end', {
          'reason': 'completed',
          'winnerId': 'u-me',
          'isRanked': true,
          'forfeitedBy': null,
          'p1Rounds': 1,
          'p2Rounds': 3,
          'p1AvgMs': 5200.5,
          'p2AvgMs': 3100,
          'p1': {
            'eloBefore': 1310,
            'eloAfter': 1294,
            'coins': 50,
            'xp': 20,
            'badgeIds': <String>[],
          },
          'p2': {
            'eloBefore': 1240,
            'eloAfter': 1256,
            'coins': 200,
            'xp': 50,
            'badgeIds': ['badge_duelist'],
          },
        }),
      );
      await pumpEventQueue();

      expect(events, const [
        DuelFinished(
          reason: 'completed',
          winnerId: 'u-me',
          isRanked: true,
          p1Rounds: 1,
          p2Rounds: 3,
          p1AvgMs: 5200.5,
          p2AvgMs: 3100,
          p1: DuelSideResult(
            eloBefore: 1310,
            eloAfter: 1294,
            coins: 50,
            xp: 20,
          ),
          p2: DuelSideResult(
            eloBefore: 1240,
            eloAfter: 1256,
            coins: 200,
            xp: 50,
            badgeIds: ['badge_duelist'],
          ),
        ),
      ]);
      final finished = events.single as DuelFinished;
      expect(finished.isAbandoned, isFalse);
      expect(finished.resultOf(DuelSide.p2)?.eloAfter, 1256);
      expect(finished.avgMsOf(DuelSide.p1), 5200.5);
    });

    test('duel_end (forfeit) carries who forfeited', () async {
      final events = listen();

      room.add(
        message('duel_end', {
          'reason': 'forfeit',
          'winnerId': 'u-me',
          'isRanked': false,
          'forfeitedBy': 'u-opp',
          'p1Rounds': 1,
          'p2Rounds': 4,
          'p1AvgMs': null,
          'p2AvgMs': 2900,
          'p1': {
            'eloBefore': 1310,
            'eloAfter': 1310,
            'coins': 0,
            'xp': 0,
            'badgeIds': <String>[],
          },
          'p2': {
            'eloBefore': 1240,
            'eloAfter': 1240,
            'coins': 200,
            'xp': 50,
            'badgeIds': <String>[],
          },
        }),
      );
      await pumpEventQueue();

      final finished = events.single as DuelFinished;
      expect(finished.reason, 'forfeit');
      expect(finished.forfeitedBy, 'u-opp');
      expect(finished.isRanked, isFalse);
      expect(finished.p1AvgMs, isNull);
    });

    test('duel_end (abandoned) → DuelFinished with no settlement', () async {
      final events = listen();

      room.add(
        message('duel_end', {'reason': 'abandoned', 'cause': 'no_show'}),
      );
      await pumpEventQueue();

      expect(events, const [
        DuelFinished(
          reason: 'abandoned',
          cause: 'no_show',
          isRanked: false,
          p1Rounds: 0,
          p2Rounds: 0,
        ),
      ]);
      expect((events.single as DuelFinished).isAbandoned, isTrue);
    });

    test('rematch → RematchUpdate (requestedBy, by, duelId)', () async {
      final events = listen();

      room
        ..add(
          message('rematch', {'status': 'requested', 'requestedBy': 'u-opp'}),
        )
        ..add(message('rematch', {'status': 'declined', 'by': 'u-opp'}))
        ..add(message('rematch', {'status': 'started', 'duelId': 'd-next'}));
      await pumpEventQueue();

      expect(events, const [
        RematchUpdate(status: RematchStatus.requested, requestedBy: 'u-opp'),
        RematchUpdate(status: RematchStatus.declined, requestedBy: 'u-opp'),
        RematchUpdate(status: RematchStatus.started, duelId: 'd-next'),
      ]);
    });

    test('unknown and malformed broadcasts are ignored, the stream goes '
        'on', () async {
      final events = listen();

      room
        ..add(message('confetti', {'round': 1}))
        ..add(message('round_start', {'round': 2, 'roundSeconds': 15}))
        ..add(
          message('round_result', {
            'round': 2,
            'outcome': 'p3',
            'correctIndex': 1,
            'p1Rounds': 0,
            'p2Rounds': 1,
          }),
        )
        ..add(message('rematch', {'status': 'maybe'}))
        ..add(message('answer_locked', {'round': 2, 'ms': 100}))
        ..add(message('duel_end', {'winnerId': 'u-me'}))
        ..add(message('answer_locked', {'userId': 'u-opp', 'round': 2}));
      await pumpEventQueue();

      expect(events, const [AnswerLocked(userId: 'u-opp', round: 2)]);
    });

    test('channel status → RoomChannelStatusChanged, every time', () async {
      final events = listen();

      room
        ..add(const BroadcastStatus(isLive: true))
        ..add(const BroadcastStatus(isLive: false))
        ..add(const BroadcastStatus(isLive: true));
      await pumpEventQueue();

      expect(events, const [
        RoomChannelStatusChanged(isLive: true),
        RoomChannelStatusChanged(isLive: false),
        RoomChannelStatusChanged(isLive: true),
      ]);
    });

    test('presence → OpponentPresenceChanged only when it flips', () async {
      final events = listen(opponentId: 'u-opp');

      room
        ..add(const BroadcastPresence({'u-me'}))
        ..add(const BroadcastPresence({'u-me'}))
        ..add(const BroadcastPresence({'u-me', 'u-opp'}))
        ..add(const BroadcastPresence({'u-opp', 'u-me', 'u-spectator'}))
        ..add(const BroadcastPresence({'u-opp'}))
        ..add(const BroadcastPresence({}))
        ..add(const BroadcastPresence({'u-me', 'u-opp'}));
      await pumpEventQueue();

      expect(events, const [
        OpponentPresenceChanged(online: false),
        OpponentPresenceChanged(online: true),
        OpponentPresenceChanged(online: false),
        OpponentPresenceChanged(online: true),
      ]);
    });

    test('without an opponent id, presence emits nothing', () async {
      final events = listen();

      room
        ..add(const BroadcastPresence({'u-me', 'u-opp'}))
        ..add(const BroadcastPresence({'u-me'}));
      await pumpEventQueue();

      expect(events, isEmpty);
    });
  });

  group('duelStarts', () {
    test('emits the duel id of each inbox duel_start', () async {
      final inbox = StreamController<DuelBroadcast>();
      when(() => api.inboxStream()).thenAnswer((_) => inbox.stream);
      final ids = <String>[];
      final subscription = repository.duelStarts().listen(ids.add);
      addTearDown(subscription.cancel);

      inbox
        ..add(const BroadcastStatus(isLive: true))
        ..add(
          BroadcastMessage(
            event: 'duel_start',
            payload: _wire({
              'duelId': 'd-next',
              'origin': 'rematch',
              'serverNow': _serverNow,
            }),
          ),
        )
        ..add(
          BroadcastMessage(event: 'duel_start', payload: _wire({'duelId': 7})),
        );
      await pumpEventQueue();

      expect(ids, ['d-next']);
    });
  });
}
