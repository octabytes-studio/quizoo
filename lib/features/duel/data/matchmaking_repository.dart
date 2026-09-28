import 'dart:async';

import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_rpc.dart';
import 'package:quizoo/features/duel/data/matchmaking_api.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/matchmaking_ticket.dart';

/// The only thing that talks to [MatchmakingApi]; turns its tickets into
/// [MatchmakingTicket]s and keeps the shared [ServerClock] in sync.
class MatchmakingRepository {
  MatchmakingRepository(this._api, this._clock);

  final MatchmakingApi _api;
  final ServerClock _clock;

  /// Queues for [subcategoryId] (and immediately tries to pair).
  Future<MatchmakingTicket> join(String subcategoryId) async {
    final json = await _clock.timed(() => _api.join(subcategoryId));
    return decodeDuelJson(() => ticketFromJson(json));
  }

  /// Keeps the queue row alive and retries pairing with the widened band.
  /// Throws `ApiException.code == 'not_in_queue'` once the row is gone.
  Future<MatchmakingTicket> heartbeat() async {
    final json = await _clock.timed(_api.heartbeat);
    return decodeDuelJson(() => ticketFromJson(json));
  }

  Future<void> leave() => _api.leave();

  /// Duel ids from the inbox's `duel_start` — a pairing lands here before
  /// the next heartbeat would report it.
  Stream<String> duelStarts() => _api.inboxStream().transform(
    StreamTransformer.fromHandlers(
      handleData: (broadcast, sink) {
        if (broadcast is BroadcastMessage &&
            broadcast.event == DuelRealtime.duelStart &&
            broadcast.payload['duelId'] is String) {
          sink.add(broadcast.payload['duelId'] as String);
        }
      },
    ),
  );

  /// Decodes `_duel_mm_ticket`'s JSON.
  static MatchmakingTicket ticketFromJson(Map<String, dynamic> json) {
    if (json['status'] == 'matched') {
      return MatchmakingMatched(json['duelId'] as String);
    }
    final band = Map<String, dynamic>.from(json['band'] as Map);
    final botAvailableAt = json['botAvailableAt'];
    return MatchmakingQueued(
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      bandMin: (band['min'] as num).toInt(),
      bandMax: (band['max'] as num).toInt(),
      elo: (json['elo'] as num).toInt(),
      botAvailable: json['botAvailable'] as bool? ?? false,
      botAvailableAt: botAvailableAt is String
          ? DateTime.parse(botAvailableAt)
          : null,
      me: DuelPlayer.fromJson(Map<String, dynamic>.from(json['me'] as Map)),
      topic: DuelTopic.fromJson(
        Map<String, dynamic>.from(json['topic'] as Map),
      ),
      serverNow: DateTime.parse(json['serverNow'] as String),
    );
  }
}
