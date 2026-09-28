import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quizoo/features/duel/data/duel_arena_api.dart';
import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_rpc.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_snapshot.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/domain/lobby_event.dart';
import 'package:quizoo/features/duel/domain/outgoing_join_request.dart';

/// The only thing that talks to [DuelArenaApi], and the only place its JSON
/// becomes domain models (CLAUDE.md §9).
///
/// Every response's `serverNow` is folded into the shared [ServerClock], and
/// the lobby + inbox broadcasts are merged into one [LobbyEvent] stream.
class DuelArenaRepository {
  DuelArenaRepository(this._api, this._clock);

  final DuelArenaApi _api;
  final ServerClock _clock;

  Future<DuelLobbySnapshot> fetchLobby(String languageCode) async {
    final json = await _clock.timed(() => _api.fetchLobby(languageCode));
    return decodeDuelJson(() => DuelLobbySnapshot.fromJson(json));
  }

  /// Topics with enough live questions in [languageCode], activity first
  /// within each category (server-ordered).
  Future<List<DuelTopic>> fetchTopics(String languageCode) async {
    final rows = await _api.fetchTopics(languageCode);
    return decodeDuelJson(
      () => [
        for (final row in rows)
          DuelTopic.fromJson(Map<String, dynamic>.from(row as Map)),
      ],
    );
  }

  /// Posts a challenge in [subcategoryId]. The server writes the cool-off in
  /// the same transaction, so [cooldownEndsAt] is authoritative.
  Future<({DuelChallenge challenge, DateTime? cooldownEndsAt})> createChallenge(
    String subcategoryId,
  ) async {
    final json = await _clock.timed(() => _api.createChallenge(subcategoryId));
    return decodeDuelJson(
      () => (
        challenge: DuelChallenge.fromJson(
          Map<String, dynamic>.from(json['challenge'] as Map),
        ),
        cooldownEndsAt: _dateOrNull(json['cooldownEndsAt']),
      ),
    );
  }

  Future<void> cancelChallenge(String challengeId) =>
      _api.cancelChallenge(challengeId);

  /// Tells the server whether the viewer is on the arena screen — which is
  /// what keeps their own challenge "Live" rather than "Away" (plan 017,
  /// Decision 2) and their outgoing requests alive.
  Future<void> setPresence({required bool present}) async {
    await _clock.timed(() => _api.setPresence(present: present));
  }

  Future<OutgoingJoinRequest> requestJoin(String challengeId) async {
    final json = await _clock.timed(() => _api.requestJoin(challengeId));
    return decodeDuelJson(() => OutgoingJoinRequest.fromJson(json));
  }

  Future<void> withdrawJoin(String requestId) => _api.withdrawJoin(requestId);

  /// Accepts or declines the presented request. Returns the new duel's id on
  /// an accept, null on a decline.
  ///
  /// An accept without a duel id is a malformed response (a parsing
  /// `ApiException`), never a silent "declined".
  Future<String?> respondJoin(String requestId, {required bool accept}) async {
    final json = await _clock.timed(
      () => _api.respondJoin(requestId, accept: accept),
    );
    return decodeDuelJson(
      () => json['accepted'] == true ? json['duelId'] as String : null,
    );
  }

  /// Every server-pushed arena change: the [languageCode] lobby feed merged
  /// with the viewer's inbox.
  ///
  /// [LobbyChannelStatusChanged] reports the two channels combined — live
  /// only while both are — so a drop on either followed by a recovery tells
  /// the arena to re-fetch its snapshot.
  Stream<LobbyEvent> events(String languageCode, {bool trackPresence = true}) {
    late final StreamController<LobbyEvent> controller;
    final subscriptions = <StreamSubscription<DuelBroadcast>>[];
    var lobbyLive = false;
    var inboxLive = false;
    bool? lastCombined;

    void onStatus() {
      final combined = lobbyLive && inboxLive;
      if (combined == lastCombined) return;
      lastCombined = combined;
      controller.add(LobbyChannelStatusChanged(isLive: combined));
    }

    controller = StreamController<LobbyEvent>(
      onListen: () {
        subscriptions
          ..add(
            _api.lobbyStream(languageCode, trackPresence: trackPresence).listen(
              (broadcast) {
                switch (broadcast) {
                  case BroadcastStatus(:final isLive):
                    lobbyLive = isLive;
                    onStatus();
                  case BroadcastPresence(:final userIds):
                    controller.add(LobbyPresenceChanged(userIds.length));
                  case BroadcastMessage():
                    final event = _decodeLobbyMessage(broadcast);
                    if (event != null) controller.add(event);
                }
              },
            ),
          )
          ..add(
            _api.inboxStream().listen((broadcast) {
              switch (broadcast) {
                case BroadcastStatus(:final isLive):
                  inboxLive = isLive;
                  onStatus();
                case BroadcastPresence():
                  break;
                case BroadcastMessage():
                  final event = _decodeLobbyMessage(broadcast);
                  if (event != null) controller.add(event);
              }
            }),
          );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Decodes one lobby/inbox broadcast, or null (logged in debug) for an
  /// unknown or malformed one — a newer server must never crash an older
  /// client.
  static LobbyEvent? _decodeLobbyMessage(BroadcastMessage message) {
    final payload = message.payload;
    try {
      return switch (message.event) {
        DuelRealtime.challengeUpsert => ChallengeUpserted(
          DuelChallenge.fromJson(payload),
        ),
        DuelRealtime.challengeRemove => ChallengeRemoved(
          payload['id'] as String,
        ),
        DuelRealtime.joinRequest => IncomingRequestPresented(
          IncomingJoinRequest.fromJson(payload),
        ),
        DuelRealtime.joinRequestCleared => IncomingRequestCleared(
          requestId: payload['requestId'] as String,
          reason: payload['reason'] as String? ?? '',
        ),
        DuelRealtime.joinRequestStatus => OutgoingRequestChanged(
          OutgoingJoinRequest.fromJson(payload),
        ),
        DuelRealtime.duelStart => DuelStarted(payload['duelId'] as String),
        _ => _ignored(message, 'unknown event'),
      };
    } on Object catch (error) {
      return _ignored(message, '$error');
    }
  }

  static LobbyEvent? _ignored(BroadcastMessage message, String why) {
    if (kDebugMode) {
      debugPrint('DuelArenaRepository: ignored ${message.event} ($why)');
    }
    return null;
  }

  static DateTime? _dateOrNull(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
