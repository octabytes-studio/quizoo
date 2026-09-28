import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/matchmaking_api.dart';
import 'package:quizoo/features/duel/data/matchmaking_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/matchmaking_ticket.dart';

class _MockMatchmakingApi extends Mock implements MatchmakingApi {}

// ---------------------------------------------------------------- fixtures
// Shapes copied from plan 017's `_duel_mm_ticket` (Phase 4).

/// Round-trips through JSON so nested maps are exactly what `supabase.rpc`
/// hands the API.
Map<String, dynamic> _wire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

const _serverNow = '2026-09-27T12:00:05.100000+00:00';

/// `_duel_player_json(me, subcategory)`.
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

/// `_duel_topic_json(subcategory)`.
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

Map<String, Object?> _queuedJson({
  bool botAvailable = false,
  int bandMin = 1140,
  int bandMax = 1340,
}) => {
  'status': 'queued',
  'queuedAt': '2026-09-27T11:59:50.250000+00:00',
  'band': {'min': bandMin, 'max': bandMax},
  'elo': 1240,
  'botAvailable': botAvailable,
  'botAvailableAt': '2026-09-27T12:00:20.250000+00:00',
  'me': _meJson,
  'topic': _topicJson,
  'serverNow': _serverNow,
};

MatchmakingQueued _queued({
  bool botAvailable = false,
  int bandMin = 1140,
  int bandMax = 1340,
}) => MatchmakingQueued(
  queuedAt: DateTime.utc(2026, 9, 27, 11, 59, 50, 250),
  bandMin: bandMin,
  bandMax: bandMax,
  elo: 1240,
  botAvailable: botAvailable,
  botAvailableAt: DateTime.utc(2026, 9, 27, 12, 0, 20, 250),
  me: _me,
  topic: _topic,
  serverNow: DateTime.utc(2026, 9, 27, 12, 0, 5, 100),
);

const Map<String, Object?> _matchedJson = {
  'status': 'matched',
  'duelId': 'd-paired',
};

Matcher _isParsingError() => throwsA(
  isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.parsing),
);

// ------------------------------------------------------------------- tests

void main() {
  final start = DateTime.utc(2026, 9, 27, 12);

  late _MockMatchmakingApi api;
  late DateTime local;
  late ServerClock clock;
  late MatchmakingRepository repository;

  setUp(() {
    api = _MockMatchmakingApi();
    local = start;
    clock = ServerClock(localNow: () => local);
    repository = MatchmakingRepository(api, clock);
  });

  /// An API answer that takes 200 ms of local time: with [_serverNow] at
  /// start + 5.1 s the clock offset becomes exactly 5 s.
  Future<Map<String, dynamic>> answer(Map<String, Object?> json) async {
    local = local.add(const Duration(milliseconds: 200));
    return _wire(json);
  }

  group('join', () {
    test('a queued ticket decodes band, bot offer, me and topic', () async {
      when(() => api.join(any())).thenAnswer((_) => answer(_queuedJson()));

      final ticket = await repository.join('sub-cricket');

      verify(() => api.join('sub-cricket')).called(1);
      expect(ticket, _queued());
    });

    test('feeds serverNow into the ServerClock', () async {
      when(() => api.join(any())).thenAnswer((_) => answer(_queuedJson()));

      await repository.join('sub-cricket');

      expect(clock.offset, const Duration(seconds: 5));
    });

    test('a matched ticket carries the duel id', () async {
      when(() => api.join(any())).thenAnswer((_) => answer(_matchedJson));

      final ticket = await repository.join('sub-cricket');

      expect(ticket, const MatchmakingMatched('d-paired'));
      // `_duel_mm_ticket`'s matched shape has no serverNow.
      expect(clock.offset, Duration.zero);
    });

    test('a null botAvailableAt decodes to null', () async {
      when(
        () => api.join(any()),
      ).thenAnswer((_) => answer({..._queuedJson(), 'botAvailableAt': null}));

      final ticket = await repository.join('sub-cricket');

      expect((ticket as MatchmakingQueued).botAvailableAt, isNull);
    });

    for (final code in const [
      'already_in_duel',
      'topic_unavailable',
      'rate_limited',
    ]) {
      test('ApiException($code) propagates unchanged', () async {
        final error = ApiException(code, code: code);
        when(() => api.join(any())).thenAnswer((_) async => throw error);

        await expectLater(repository.join('sub-cricket'), throwsA(same(error)));
        expect(clock.offset, Duration.zero);
      });
    }

    test(
      'a queued ticket without its band is a parsing ApiException',
      () async {
        when(
          () => api.join(any()),
        ).thenAnswer((_) => answer({..._queuedJson()}..remove('band')));

        await expectLater(repository.join('sub-cricket'), _isParsingError());
      },
    );

    test(
      'a matched ticket without a duel id is a parsing ApiException',
      () async {
        when(
          () => api.join(any()),
        ).thenAnswer((_) => answer({'status': 'matched'}));

        await expectLater(repository.join('sub-cricket'), _isParsingError());
      },
    );
  });

  group('heartbeat', () {
    test('returns the widened band and the bot offer', () async {
      when(() => api.heartbeat()).thenAnswer(
        (_) => answer(
          _queuedJson(botAvailable: true, bandMin: 940, bandMax: 1540),
        ),
      );

      final ticket = await repository.heartbeat();

      verify(() => api.heartbeat()).called(1);
      expect(ticket, _queued(botAvailable: true, bandMin: 940, bandMax: 1540));
      expect(clock.offset, const Duration(seconds: 5));
    });

    test('returns the matched ticket once paired', () async {
      when(() => api.heartbeat()).thenAnswer((_) => answer(_matchedJson));

      expect(
        await repository.heartbeat(),
        const MatchmakingMatched('d-paired'),
      );
    });

    test('ApiException(not_in_queue) propagates unchanged', () async {
      const error = ApiException('not_in_queue', code: 'not_in_queue');
      when(() => api.heartbeat()).thenAnswer((_) async => throw error);

      await expectLater(repository.heartbeat(), throwsA(same(error)));
    });
  });

  group('leave', () {
    test('forwards to the API', () async {
      when(() => api.leave()).thenAnswer((_) async {});

      await repository.leave();

      verify(() => api.leave()).called(1);
    });

    test('an ApiException propagates unchanged', () async {
      const error = ApiException.network();
      when(() => api.leave()).thenAnswer((_) async => throw error);

      await expectLater(repository.leave(), throwsA(same(error)));
    });
  });

  group('duelStarts', () {
    late StreamController<DuelBroadcast> inbox;

    setUp(() {
      inbox = StreamController<DuelBroadcast>();
      when(() => api.inboxStream()).thenAnswer((_) => inbox.stream);
    });

    test('emits the duel id of each duel_start, ignoring everything '
        'else', () async {
      final ids = <String>[];
      final subscription = repository.duelStarts().listen(ids.add);
      addTearDown(subscription.cancel);

      inbox
        ..add(const BroadcastStatus(isLive: true))
        ..add(const BroadcastPresence({'u-me'}))
        ..add(
          BroadcastMessage(
            event: 'duel_start',
            payload: _wire({
              'duelId': 'd-paired',
              'origin': 'matchmaking',
              'serverNow': _serverNow,
            }),
          ),
        )
        ..add(
          BroadcastMessage(
            event: 'join_request_status',
            payload: _wire({'requestId': 'r-1', 'duelId': 'd-wrong'}),
          ),
        )
        ..add(
          BroadcastMessage(
            event: 'duel_start',
            payload: _wire({'origin': 'matchmaking'}),
          ),
        )
        ..add(
          BroadcastMessage(
            event: 'duel_start',
            payload: _wire({'duelId': 'd-rematch', 'origin': 'rematch'}),
          ),
        );
      await pumpEventQueue();

      verify(() => api.inboxStream()).called(1);
      expect(ids, ['d-paired', 'd-rematch']);
    });
  });
}
