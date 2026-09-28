import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_arena_api.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/domain/lobby_event.dart';
import 'package:quizoo/features/duel/domain/outgoing_join_request.dart';

class _MockDuelArenaApi extends Mock implements DuelArenaApi {}

// ---------------------------------------------------------------- fixtures
// Shapes copied from plan 017's SQL contracts (Phase 3 + "Broadcast events").

/// Round-trips through JSON so nested maps/lists are exactly what
/// `supabase.rpc` / Realtime hand the API: `Map<String, dynamic>` and
/// `List<dynamic>`.
Map<String, dynamic> _wire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

const _serverNow = '2026-09-27T12:00:05.100000+00:00';

/// `_duel_player_json(me, null)`.
const Map<String, Object?> _mePlayerJson = {
  'id': 'u-me',
  'name': 'Zara',
  'isGuest': false,
  'guestTag': null,
  'avatar': '🦊',
  'elo': 1240,
  'league': 'silver',
  'topicLevel': 0,
  'isBot': false,
};

const _mePlayer = DuelPlayer(
  id: 'u-me',
  name: 'Zara',
  avatarEmoji: '🦊',
  elo: 1240,
  league: 'silver',
);

/// `_duel_challenge_card(c).creator` — no `isBot` key.
const Map<String, Object?> _creatorJson = {
  'id': 'u-omar',
  'name': 'Omar',
  'isGuest': false,
  'guestTag': null,
  'avatar': '🐯',
  'elo': 1310,
  'league': 'gold',
  'topicLevel': 7,
};

const _creator = DuelPlayer(
  id: 'u-omar',
  name: 'Omar',
  avatarEmoji: '🐯',
  elo: 1310,
  league: 'gold',
  topicLevel: 7,
);

/// `_duel_challenge_card(c).topic` — no `categoryId` or counts.
const Map<String, Object?> _cardTopicJson = {
  'id': 'sub-cricket',
  'name': 'Cricket',
  'emoji': '🏏',
  'plateColor': '#E4F7F1',
  'categoryName': 'Sports',
  'categoryEmoji': '⚽',
};

const _cardTopic = DuelTopic(
  id: 'sub-cricket',
  name: 'Cricket',
  emoji: '🏏',
  plateColor: '#E4F7F1',
  categoryName: 'Sports',
  categoryEmoji: '⚽',
);

/// `_duel_challenge_card(c)` for an open, live challenge.
const Map<String, Object?> _openCardJson = {
  'id': 'c-open',
  'status': 'open',
  'creatorPresent': true,
  'createdAt': '2026-09-27T11:58:00.123456+00:00',
  'expiresAt': '2026-09-27T12:03:00.123456+00:00',
  'creator': _creatorJson,
  'topic': _cardTopicJson,
  'opponentName': null,
  'opponentGuestTag': null,
  'duelId': null,
};

final _openCard = DuelChallenge(
  id: 'c-open',
  status: ChallengeStatus.open,
  creatorPresent: true,
  createdAt: DateTime.utc(2026, 9, 27, 11, 58, 0, 123, 456),
  expiresAt: DateTime.utc(2026, 9, 27, 12, 3, 0, 123, 456),
  creator: _creator,
  topic: _cardTopic,
);

/// A matched ("In progress") card against a guest.
const Map<String, Object?> _matchedCardJson = {
  'id': 'c-matched',
  'status': 'matched',
  'creatorPresent': false,
  'createdAt': '2026-09-27T11:57:00.000000+00:00',
  'expiresAt': '2026-09-27T12:02:00.000000+00:00',
  'creator': {
    'id': 'u-lina',
    'name': null,
    'isGuest': false,
    'guestTag': '0042',
    'avatar': '🐨',
    'elo': 990,
    'league': 'bronze',
    'topicLevel': 0,
  },
  'topic': _cardTopicJson,
  'opponentName': null,
  'opponentGuestTag': '4821',
  'duelId': 'd-running',
};

final _matchedCard = DuelChallenge(
  id: 'c-matched',
  status: ChallengeStatus.matched,
  creatorPresent: false,
  createdAt: DateTime.utc(2026, 9, 27, 11, 57),
  expiresAt: DateTime.utc(2026, 9, 27, 12, 2),
  creator: const DuelPlayer(
    id: 'u-lina',
    name: null,
    guestTag: '0042',
    avatarEmoji: '🐨',
    elo: 990,
  ),
  topic: _cardTopic,
  opponentGuestTag: '4821',
  duelId: 'd-running',
);

/// `_duel_request_status_payload` — queued, second in line.
const Map<String, Object?> _queuedRequestJson = {
  'requestId': 'r-queued',
  'challengeId': 'c-open',
  'status': 'queued',
  'position': 2,
  'expiresAt': null,
  'retryAfter': null,
  'reason': null,
};

const _queuedRequest = OutgoingJoinRequest(
  requestId: 'r-queued',
  challengeId: 'c-open',
  status: JoinRequestStatus.queued,
  position: 2,
);

/// A terminal row still inside its retry cool-down.
const Map<String, Object?> _declinedRequestJson = {
  'requestId': 'r-declined',
  'challengeId': 'c-other',
  'status': 'declined',
  'position': null,
  'expiresAt': '2026-09-27T11:59:50.000000+00:00',
  'retryAfter': '2026-09-27T12:00:10.500000+00:00',
  'reason': 'declined',
};

final _declinedRequest = OutgoingJoinRequest(
  requestId: 'r-declined',
  challengeId: 'c-other',
  status: JoinRequestStatus.declined,
  expiresAt: DateTime.utc(2026, 9, 27, 11, 59, 50),
  retryAfter: DateTime.utc(2026, 9, 27, 12, 0, 10, 500),
  reason: 'declined',
);

/// `join_request` payload / `get_duel_lobby.incoming` — from a guest.
const Map<String, Object?> _incomingJson = {
  'requestId': 'r-in',
  'challengeId': 'c-mine',
  'requester': {
    'id': 'u-guest',
    'name': null,
    'isGuest': true,
    'guestTag': '4821',
    'avatar': '🐼',
    'elo': 1000,
    'league': 'bronze',
    'topicLevel': 2,
  },
  'expiresAt': '2026-09-27T12:00:09.000000+00:00',
  'queuedCount': 3,
};

final _incoming = IncomingJoinRequest(
  requestId: 'r-in',
  challengeId: 'c-mine',
  requester: const DuelPlayer(
    id: 'u-guest',
    name: null,
    isGuest: true,
    guestTag: '4821',
    avatarEmoji: '🐼',
    elo: 1000,
    topicLevel: 2,
  ),
  expiresAt: DateTime.utc(2026, 9, 27, 12, 0, 9),
  queuedCount: 3,
);

/// `get_duel_lobby` for a signed-in player with an open challenge.
const Map<String, Object?> _lobbyJson = {
  'serverNow': _serverNow,
  'config': {
    'challengeTtlSeconds': 240,
    'cooldownSeconds': 90,
    'joinWindowSeconds': 6,
    'lobbyHeartbeatSeconds': 12,
    'mmHeartbeatSeconds': 4,
    'botAfterSeconds': 25,
    'bandStepSeconds': 7,
    'rounds': 7,
    'roundSeconds': 12,
    'revealSeconds': 3,
    'introSeconds': 4,
    'duelHeartbeatSeconds': 6,
    'rematchWindowSeconds': 45,
    'presenceEnabled': false,
    'winCoins': 250,
  },
  'me': {
    'player': _mePlayerJson,
    'isGuest': false,
    'activeDuelId': null,
    'openChallengeId': 'c-mine',
    'cooldownEndsAt': '2026-09-27T12:01:30.000000+00:00',
    'challengesLeftToday': 58,
  },
  'challenges': [_matchedCardJson, _openCardJson],
  'myRequests': [_queuedRequestJson, _declinedRequestJson],
  'incoming': _incomingJson,
};

/// `list_duel_topics` row: `_duel_topic_json || {activity}`.
const Map<String, Object?> _topicRowJson = {
  'id': 'sub-cricket',
  'name': 'Cricket',
  'emoji': '🏏',
  'plateColor': '#E4F7F1',
  'categoryId': 'cat-sports',
  'categoryName': 'Sports',
  'categoryEmoji': '⚽',
  'myTopicLevel': 4,
  'openChallenges': 2,
  'searching': 1,
  'liveQuestionCount': 120,
};

// ------------------------------------------------------------------- tests

void main() {
  final start = DateTime.utc(2026, 9, 27, 12);

  late _MockDuelArenaApi api;
  late DateTime local;
  late ServerClock clock;
  late DuelArenaRepository repository;

  setUp(() {
    api = _MockDuelArenaApi();
    local = start;
    clock = ServerClock(localNow: () => local);
    repository = DuelArenaRepository(api, clock);
  });

  /// An API answer that takes 200 ms of local time: with [_serverNow] at
  /// start + 5.1 s the clock offset becomes exactly 5 s.
  Future<Map<String, dynamic>> answer(Map<String, Object?> json) async {
    local = local.add(const Duration(milliseconds: 200));
    return _wire(json);
  }

  group('fetchLobby', () {
    test('decodes the whole snapshot', () async {
      when(() => api.fetchLobby(any())).thenAnswer((_) => answer(_lobbyJson));

      final lobby = await repository.fetchLobby('en');

      verify(() => api.fetchLobby('en')).called(1);
      expect(lobby.serverNow, DateTime.utc(2026, 9, 27, 12, 0, 5, 100));
      expect(
        lobby.config,
        const DuelConfig(
          challengeTtlSeconds: 240,
          cooldownSeconds: 90,
          joinWindowSeconds: 6,
          lobbyHeartbeatSeconds: 12,
          mmHeartbeatSeconds: 4,
          botAfterSeconds: 25,
          bandStepSeconds: 7,
          rounds: 7,
          roundSeconds: 12,
          revealSeconds: 3,
          introSeconds: 4,
          duelHeartbeatSeconds: 6,
          rematchWindowSeconds: 45,
          presenceEnabled: false,
          winCoins: 250,
        ),
      );
      expect(lobby.me.player, _mePlayer);
      expect(lobby.me.isGuest, isFalse);
      expect(lobby.me.activeDuelId, isNull);
      expect(lobby.me.openChallengeId, 'c-mine');
      expect(lobby.me.cooldownEndsAt, DateTime.utc(2026, 9, 27, 12, 1, 30));
      expect(lobby.me.challengesLeftToday, 58);
      expect(lobby.challenges, [_matchedCard, _openCard]);
      expect(lobby.myRequests, [_queuedRequest, _declinedRequest]);
      expect(lobby.myRequests.first.isActive, isTrue);
      expect(lobby.myRequests.last.isActive, isFalse);
      expect(lobby.incoming, _incoming);
    });

    test('decodes a guest viewer with an empty arena', () async {
      when(() => api.fetchLobby(any())).thenAnswer(
        (_) => answer({
          'serverNow': _serverNow,
          'config': (_lobbyJson['config'])!,
          'me': {
            'player': {
              'id': 'u-guest',
              'name': null,
              'isGuest': true,
              'guestTag': '4821',
              'avatar': '🐼',
              'elo': 1000,
              'league': 'bronze',
              'topicLevel': 0,
              'isBot': false,
            },
            'isGuest': true,
            'activeDuelId': 'd-live',
            'openChallengeId': null,
            'cooldownEndsAt': null,
            'challengesLeftToday': 0,
          },
          'challenges': <Object?>[],
          'myRequests': <Object?>[],
          'incoming': null,
        }),
      );

      final lobby = await repository.fetchLobby('ur');

      expect(lobby.me.isGuest, isTrue);
      expect(lobby.me.player.isGuest, isTrue);
      expect(lobby.me.player.name, isNull);
      expect(lobby.me.player.guestTag, '4821');
      expect(lobby.me.activeDuelId, 'd-live');
      expect(lobby.me.cooldownEndsAt, isNull);
      expect(lobby.challenges, isEmpty);
      expect(lobby.myRequests, isEmpty);
      expect(lobby.incoming, isNull);
    });

    test('feeds serverNow into the ServerClock, half-RTT corrected', () async {
      when(() => api.fetchLobby(any())).thenAnswer((_) => answer(_lobbyJson));

      await repository.fetchLobby('en');

      expect(clock.offset, const Duration(seconds: 5));
      expect(clock.now(), DateTime.utc(2026, 9, 27, 12, 0, 5, 200));
    });

    test('the API\'s ApiException propagates unchanged', () async {
      const error = ApiException(
        'not_authenticated',
        kind: ApiErrorKind.server,
        code: 'not_authenticated',
      );
      when(() => api.fetchLobby(any())).thenAnswer((_) async => throw error);

      await expectLater(repository.fetchLobby('en'), throwsA(same(error)));
      expect(clock.offset, Duration.zero);
    });

    test('a malformed snapshot is a parsing ApiException', () async {
      final broken = Map<String, Object?>.of(_lobbyJson)..remove('me');
      when(() => api.fetchLobby(any())).thenAnswer((_) => answer(broken));

      await expectLater(
        repository.fetchLobby('en'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.parsing,
          ),
        ),
      );
    });

    test('a card with an unknown status is a parsing ApiException', () async {
      final broken = Map<String, Object?>.of(_lobbyJson)
        ..['challenges'] = [
          {..._openCardJson, 'status': 'archived'},
        ];
      when(() => api.fetchLobby(any())).thenAnswer((_) => answer(broken));

      await expectLater(
        repository.fetchLobby('en'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.parsing,
          ),
        ),
      );
    });
  });

  group('fetchTopics', () {
    test('decodes each row, activity counts included', () async {
      when(() => api.fetchTopics(any())).thenAnswer(
        (_) async =>
            jsonDecode(
                  jsonEncode([
                    _topicRowJson,
                    {
                      ..._topicRowJson,
                      'id': 'sub-f1',
                      'name': 'Formula 1',
                      'emoji': '🏎️',
                      'myTopicLevel': 0,
                      'openChallenges': 0,
                      'searching': 0,
                    },
                  ]),
                )
                as List<dynamic>,
      );

      final topics = await repository.fetchTopics('en');

      verify(() => api.fetchTopics('en')).called(1);
      expect(topics, const [
        DuelTopic(
          id: 'sub-cricket',
          name: 'Cricket',
          emoji: '🏏',
          plateColor: '#E4F7F1',
          categoryId: 'cat-sports',
          categoryName: 'Sports',
          categoryEmoji: '⚽',
          myTopicLevel: 4,
          openChallenges: 2,
          searching: 1,
        ),
        DuelTopic(
          id: 'sub-f1',
          name: 'Formula 1',
          emoji: '🏎️',
          plateColor: '#E4F7F1',
          categoryId: 'cat-sports',
          categoryName: 'Sports',
          categoryEmoji: '⚽',
        ),
      ]);
      expect(topics.first.hasActivity, isTrue);
      expect(topics.last.hasActivity, isFalse);
    });

    test('an empty list is no topics', () async {
      when(() => api.fetchTopics(any())).thenAnswer((_) async => const []);

      expect(await repository.fetchTopics('fr'), isEmpty);
    });

    test('a malformed row is a parsing ApiException', () async {
      when(() => api.fetchTopics(any())).thenAnswer(
        (_) async => [
          {'id': 'sub-x', 'emoji': '❓'},
        ],
      );

      await expectLater(
        repository.fetchTopics('en'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.parsing,
          ),
        ),
      );
    });
  });

  group('createChallenge', () {
    test('returns the card and the authoritative cool-off end', () async {
      when(() => api.createChallenge(any())).thenAnswer(
        (_) => answer({
          'challenge': _openCardJson,
          'cooldownEndsAt': '2026-09-27T12:02:05.100000+00:00',
          'serverNow': _serverNow,
        }),
      );

      final created = await repository.createChallenge('sub-cricket');

      verify(() => api.createChallenge('sub-cricket')).called(1);
      expect(created.challenge, _openCard);
      expect(created.cooldownEndsAt, DateTime.utc(2026, 9, 27, 12, 2, 5, 100));
      expect(clock.offset, const Duration(seconds: 5));
    });

    test('a null cooldownEndsAt decodes to null', () async {
      when(() => api.createChallenge(any())).thenAnswer(
        (_) => answer({
          'challenge': _openCardJson,
          'cooldownEndsAt': null,
          'serverNow': _serverNow,
        }),
      );

      final created = await repository.createChallenge('sub-cricket');

      expect(created.cooldownEndsAt, isNull);
    });

    for (final code in const [
      'challenge_cooldown',
      'guest_cannot_create',
      'already_in_duel',
      'challenge_already_open',
      'challenge_daily_cap',
      'topic_unavailable',
    ]) {
      test('ApiException($code) propagates unchanged', () async {
        final error = ApiException(code, kind: ApiErrorKind.server, code: code);
        when(
          () => api.createChallenge(any()),
        ).thenAnswer((_) async => throw error);

        await expectLater(
          repository.createChallenge('sub-cricket'),
          throwsA(same(error)),
        );
      });
    }

    test('a response without the card is a parsing ApiException', () async {
      when(() => api.createChallenge(any())).thenAnswer(
        (_) => answer({'cooldownEndsAt': null, 'serverNow': _serverNow}),
      );

      await expectLater(
        repository.createChallenge('sub-cricket'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.parsing)
              .having((e) => e.code, 'code', 'ERR_PARSE'),
        ),
      );
    });
  });

  group('cancelChallenge', () {
    test('forwards the challenge id', () async {
      when(() => api.cancelChallenge(any())).thenAnswer((_) async {});

      await repository.cancelChallenge('c-mine');

      verify(() => api.cancelChallenge('c-mine')).called(1);
    });

    test('ApiException(challenge_not_found) propagates unchanged', () async {
      const error = ApiException(
        'challenge_not_found',
        code: 'challenge_not_found',
      );
      when(
        () => api.cancelChallenge(any()),
      ).thenAnswer((_) async => throw error);

      await expectLater(
        repository.cancelChallenge('c-gone'),
        throwsA(same(error)),
      );
    });
  });

  group('setPresence', () {
    test('forwards the flag and syncs the clock', () async {
      when(
        () => api.setPresence(present: any(named: 'present')),
      ).thenAnswer((_) => answer({'serverNow': _serverNow}));

      await repository.setPresence(present: true);
      expect(clock.offset, const Duration(seconds: 5));

      await repository.setPresence(present: false);

      verifyInOrder([
        () => api.setPresence(present: true),
        () => api.setPresence(present: false),
      ]);
    });
  });

  group('requestJoin', () {
    test('decodes a request presented straight away (pending)', () async {
      when(() => api.requestJoin(any())).thenAnswer(
        (_) => answer({
          'requestId': 'r-new',
          'challengeId': 'c-open',
          'status': 'pending',
          'position': null,
          'expiresAt': '2026-09-27T12:00:10.100000+00:00',
          'retryAfter': null,
          'reason': null,
        }),
      );

      final request = await repository.requestJoin('c-open');

      verify(() => api.requestJoin('c-open')).called(1);
      expect(
        request,
        OutgoingJoinRequest(
          requestId: 'r-new',
          challengeId: 'c-open',
          status: JoinRequestStatus.pending,
          expiresAt: DateTime.utc(2026, 9, 27, 12, 0, 10, 100),
        ),
      );
      expect(request.isActive, isTrue);
    });

    test('decodes a queued request with its position', () async {
      when(
        () => api.requestJoin(any()),
      ).thenAnswer((_) => answer(_queuedRequestJson));

      expect(await repository.requestJoin('c-open'), _queuedRequest);
    });

    test('an unknown status degrades to unavailable', () async {
      when(
        () => api.requestJoin(any()),
      ).thenAnswer((_) => answer({..._queuedRequestJson, 'status': 'frozen'}));

      final request = await repository.requestJoin('c-open');

      expect(request.status, JoinRequestStatus.unavailable);
      expect(request.isActive, isFalse);
    });

    for (final code in const [
      'challenge_unavailable',
      'own_challenge',
      'creator_away',
      'already_in_duel',
      'already_requested',
      'retry_later',
      'too_many_requests',
      'rate_limited',
      'challenge_busy',
    ]) {
      test('ApiException($code) propagates unchanged', () async {
        final error = ApiException(code, code: code);
        when(() => api.requestJoin(any())).thenAnswer((_) async => throw error);

        await expectLater(
          repository.requestJoin('c-open'),
          throwsA(same(error)),
        );
      });
    }

    test('a response without a request id is a parsing ApiException', () async {
      when(() => api.requestJoin(any())).thenAnswer(
        (_) => answer({'challengeId': 'c-open', 'status': 'queued'}),
      );

      await expectLater(
        repository.requestJoin('c-open'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.parsing,
          ),
        ),
      );
    });
  });

  group('withdrawJoin', () {
    test('forwards the request id', () async {
      when(() => api.withdrawJoin(any())).thenAnswer((_) async {});

      await repository.withdrawJoin('r-queued');

      verify(() => api.withdrawJoin('r-queued')).called(1);
    });

    test('ApiException(request_not_found) propagates unchanged', () async {
      const error = ApiException(
        'request_not_found',
        code: 'request_not_found',
      );
      when(() => api.withdrawJoin(any())).thenAnswer((_) async => throw error);

      await expectLater(
        repository.withdrawJoin('r-gone'),
        throwsA(same(error)),
      );
    });
  });

  group('respondJoin', () {
    test('an accept returns the new duel id', () async {
      when(
        () => api.respondJoin(any(), accept: any(named: 'accept')),
      ).thenAnswer((_) => answer({'accepted': true, 'duelId': 'd-new'}));

      final duelId = await repository.respondJoin('r-in', accept: true);

      verify(() => api.respondJoin('r-in', accept: true)).called(1);
      expect(duelId, 'd-new');
    });

    test('a decline returns null', () async {
      when(
        () => api.respondJoin(any(), accept: any(named: 'accept')),
      ).thenAnswer((_) => answer({'accepted': false}));

      final duelId = await repository.respondJoin('r-in', accept: false);

      verify(() => api.respondJoin('r-in', accept: false)).called(1);
      expect(duelId, isNull);
    });

    test('an accept without a duel id is a parsing ApiException', () async {
      when(
        () => api.respondJoin(any(), accept: any(named: 'accept')),
      ).thenAnswer((_) => answer({'accepted': true}));

      await expectLater(
        repository.respondJoin('r-in', accept: true),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.parsing,
          ),
        ),
      );
    });

    for (final code in const [
      'request_not_found',
      'request_expired',
      'requester_busy',
      'already_in_duel',
      'topic_unavailable',
    ]) {
      test('ApiException($code) propagates unchanged', () async {
        final error = ApiException(code, code: code);
        when(
          () => api.respondJoin(any(), accept: any(named: 'accept')),
        ).thenAnswer((_) async => throw error);

        await expectLater(
          repository.respondJoin('r-in', accept: true),
          throwsA(same(error)),
        );
      });
    }
  });

  group('events', () {
    late StreamController<DuelBroadcast> lobby;
    late StreamController<DuelBroadcast> inbox;

    setUp(() {
      lobby = StreamController<DuelBroadcast>();
      inbox = StreamController<DuelBroadcast>();
      when(
        () =>
            api.lobbyStream(any(), trackPresence: any(named: 'trackPresence')),
      ).thenAnswer((_) => lobby.stream);
      when(() => api.inboxStream()).thenAnswer((_) => inbox.stream);
    });

    /// Listens to `events('en')` and returns everything it emitted.
    List<LobbyEvent> listen({bool trackPresence = true}) {
      final events = <LobbyEvent>[];
      final subscription = repository
          .events('en', trackPresence: trackPresence)
          .listen(events.add);
      addTearDown(subscription.cancel);
      return events;
    }

    BroadcastMessage message(String event, Map<String, Object?> payload) =>
        BroadcastMessage(
          event: event,
          payload: _wire({...payload, 'serverNow': _serverNow}),
        );

    test('subscribes to the lobby of the language and the inbox', () async {
      listen(trackPresence: false);
      await pumpEventQueue();

      verify(() => api.lobbyStream('en', trackPresence: false)).called(1);
      verify(() => api.inboxStream()).called(1);
    });

    test('lobby broadcasts decode to challenge events', () async {
      final events = listen();

      lobby
        ..add(message('challenge_upsert', _openCardJson))
        ..add(message('challenge_upsert', _matchedCardJson))
        ..add(message('challenge_remove', {'id': 'c-open'}));
      await pumpEventQueue();

      expect(events, [
        ChallengeUpserted(_openCard),
        ChallengeUpserted(_matchedCard),
        const ChallengeRemoved('c-open'),
      ]);
    });

    test('inbox broadcasts decode to request and duel events', () async {
      final events = listen();

      inbox
        ..add(message('join_request', _incomingJson))
        ..add(
          message('join_request_cleared', {
            'requestId': 'r-in',
            'reason': 'withdrawn',
          }),
        )
        ..add(message('join_request_status', _declinedRequestJson))
        ..add(
          message('duel_start', {'duelId': 'd-new', 'origin': 'challenge'}),
        );
      await pumpEventQueue();

      expect(events, [
        IncomingRequestPresented(_incoming),
        const IncomingRequestCleared(requestId: 'r-in', reason: 'withdrawn'),
        OutgoingRequestChanged(_declinedRequest),
        const DuelStarted('d-new'),
      ]);
    });

    test(
      'a cleared request without a reason decodes to an empty one',
      () async {
        final events = listen();

        inbox.add(message('join_request_cleared', {'requestId': 'r-in'}));
        await pumpEventQueue();

        expect(events, [
          const IncomingRequestCleared(requestId: 'r-in', reason: ''),
        ]);
      },
    );

    test(
      'unknown and malformed broadcasts are ignored, the stream goes on',
      () async {
        final events = listen();

        lobby
          ..add(message('challenge_teleport', {'id': 'c-open'}))
          ..add(message('challenge_upsert', {'id': 'c-broken'}))
          ..add(message('challenge_remove', {'id': 42}));
        inbox
          ..add(message('join_request', {'requestId': 'r-broken'}))
          ..add(message('duel_start', {'origin': 'challenge'}))
          ..add(message('confetti', {}));
        await pumpEventQueue();
        lobby.add(message('challenge_remove', {'id': 'c-open'}));
        await pumpEventQueue();

        expect(events, [const ChallengeRemoved('c-open')]);
      },
    );

    test(
      'lobby presence becomes a head count; inbox presence is ignored',
      () async {
        final events = listen();

        lobby
          ..add(const BroadcastPresence({'u-me', 'u-omar', 'u-guest'}))
          ..add(const BroadcastPresence({'u-me'}));
        inbox.add(const BroadcastPresence({'u-me', 'u-someone'}));
        await pumpEventQueue();

        expect(events, const [
          LobbyPresenceChanged(3),
          LobbyPresenceChanged(1),
        ]);
      },
    );

    group('channel status', () {
      test('is live only once both channels are, and emits only on '
          'change', () async {
        final events = listen();

        lobby.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        // First known state: lobby up, inbox not yet — not live.
        expect(events, const [LobbyChannelStatusChanged(isLive: false)]);

        inbox.add(const BroadcastStatus(isLive: false));
        await pumpEventQueue();
        expect(events, hasLength(1), reason: 'still not live — no change');

        inbox.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        expect(events, const [
          LobbyChannelStatusChanged(isLive: false),
          LobbyChannelStatusChanged(isLive: true),
        ]);

        lobby.add(const BroadcastStatus(isLive: true));
        inbox.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        expect(events, hasLength(2), reason: 'still live — no change');
      });

      test('a drop on either channel, then its recovery, is false then '
          'true', () async {
        final events = listen();

        lobby.add(const BroadcastStatus(isLive: true));
        inbox.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        events.clear();

        inbox.add(const BroadcastStatus(isLive: false));
        await pumpEventQueue();
        inbox.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        lobby.add(const BroadcastStatus(isLive: false));
        await pumpEventQueue();
        // The inbox dropping while the lobby is already down changes nothing.
        inbox.add(const BroadcastStatus(isLive: false));
        await pumpEventQueue();
        inbox.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        lobby.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();

        expect(events, const [
          LobbyChannelStatusChanged(isLive: false),
          LobbyChannelStatusChanged(isLive: true),
          LobbyChannelStatusChanged(isLive: false),
          LobbyChannelStatusChanged(isLive: true),
        ]);
      });

      test('both channels already live (replayed) is one live event', () async {
        final events = listen();

        inbox.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();
        lobby.add(const BroadcastStatus(isLive: true));
        await pumpEventQueue();

        expect(events, const [
          LobbyChannelStatusChanged(isLive: false),
          LobbyChannelStatusChanged(isLive: true),
        ]);
      });
    });

    test('cancelling the events stream cancels both channel '
        'subscriptions', () async {
      final subscription = repository.events('en').listen((_) {});
      await pumpEventQueue();
      expect(lobby.hasListener, isTrue);
      expect(inbox.hasListener, isTrue);

      await subscription.cancel();

      expect(lobby.hasListener, isFalse);
      expect(inbox.hasListener, isFalse);
    });

    test('broadcasts never touch the ServerClock', () async {
      listen();

      lobby.add(message('challenge_upsert', _openCardJson));
      await pumpEventQueue();

      expect(clock.offset, Duration.zero);
    });
  });
}
