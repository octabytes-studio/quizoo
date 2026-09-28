import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_rpc.dart';
import 'package:quizoo/features/duel/data/live_duel_api.dart';
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

/// The only thing that talks to [LiveDuelApi]. Maps the server's
/// perspective snapshot and seat-keyed room broadcasts to domain types, and
/// keeps the shared [ServerClock] in sync from every response.
class LiveDuelRepository {
  LiveDuelRepository(this._api, this._clock);

  final LiveDuelApi _api;
  final ServerClock _clock;

  /// The signed-in player's id — what `answer_locked.userId` is compared to.
  String? get currentUserId => _api.currentUserId;

  Future<LiveDuelSnapshot> fetchState(String duelId) async {
    final json = await _clock.timed(() => _api.fetchState(duelId));
    return decodeDuelJson(() => snapshotFromJson(json));
  }

  /// Marks this player ready; the server starts round 1 once both are.
  Future<LiveDuelStatus> markReady(String duelId) async {
    final json = await _clock.timed(() => _api.markReady(duelId));
    return decodeDuelJson(
      () => LiveDuelStatus.values.byName(json['status'] as String),
    );
  }

  /// The round's question — refused by the server (`too_early`) until just
  /// before the round's start (plan 017, A2).
  Future<
    ({int round, DateTime startsAt, DateTime deadline, DuelQuestion question})
  >
  fetchRound(String duelId, int round) async {
    final json = await _clock.timed(() => _api.fetchRound(duelId, round));
    return decodeDuelJson(
      () => (
        round: (json['round'] as num).toInt(),
        startsAt: DateTime.parse(json['startsAt'] as String),
        deadline: DateTime.parse(json['deadline'] as String),
        question: DuelQuestion.fromJson(
          Map<String, dynamic>.from(json['question'] as Map),
        ),
      ),
    );
  }

  /// Locks this player's answer. A null [choice] is a timeout. [clientMs] is
  /// the player's own time from question display; the server bounds it
  /// (plan 017, A3).
  Future<void> submitAnswer(
    String duelId, {
    required int round,
    required int? choice,
    required int clientMs,
  }) async {
    await _clock.timed(
      () => _api.submitAnswer(
        duelId,
        round: round,
        choice: choice,
        clientMs: clientMs,
      ),
    );
  }

  /// Asks the server to resolve a round whose deadline has passed.
  Future<void> claimTimeout(String duelId, int round) async {
    await _clock.timed(() => _api.claimTimeout(duelId, round));
  }

  /// Keeps this player's seat alive; returns how long ago the opponent was
  /// last seen, when the server knows.
  Future<int?> heartbeat(String duelId) async {
    final json = await _clock.timed(() => _api.heartbeat(duelId));
    return decodeDuelJson(() => (json['opponentSeenAgoMs'] as num?)?.toInt());
  }

  /// Leaves — abandons a duel that has not started, forfeits one that has.
  Future<void> leave(String duelId) => _api.leave(duelId);

  /// Asks for (or, when the opponent already asked, starts) a rematch.
  Future<({RematchStatus status, String? duelId})> requestRematch(
    String duelId,
  ) async {
    final json = await _clock.timed(() => _api.requestRematch(duelId));
    return decodeDuelJson(
      () => (
        status: RematchStatus.values.byName(json['status'] as String),
        duelId: json['duelId'] as String?,
      ),
    );
  }

  Future<void> declineRematch(String duelId) => _api.declineRematch(duelId);

  /// The duel room's events. With [opponentId], Presence changes become
  /// [OpponentPresenceChanged] (emitted only when the answer flips).
  Stream<DuelRoomEvent> roomEvents(String duelId, {String? opponentId}) {
    bool? lastOnline;
    return _api
        .roomStream(duelId)
        .transform(
          StreamTransformer<DuelBroadcast, DuelRoomEvent>.fromHandlers(
            handleData: (broadcast, sink) {
              switch (broadcast) {
                case BroadcastStatus(:final isLive):
                  sink.add(RoomChannelStatusChanged(isLive: isLive));
                case BroadcastPresence(:final userIds):
                  if (opponentId == null) return;
                  final online = userIds.contains(opponentId);
                  if (online == lastOnline) return;
                  lastOnline = online;
                  sink.add(OpponentPresenceChanged(online: online));
                case BroadcastMessage():
                  final event = _decodeRoomMessage(broadcast);
                  if (event != null) sink.add(event);
              }
            },
          ),
        );
  }

  /// Duel ids from the inbox's `duel_start` — how a started rematch arrives.
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

  // ------------------------------------------------------------- decoding

  /// Decodes `get_duel_state`'s perspective-mapped JSON.
  static LiveDuelSnapshot snapshotFromJson(Map<String, dynamic> json) {
    final config = json['config'] is Map
        ? DuelConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map))
        : DuelConfig.fallback;
    final round = json['round'];
    final result = json['result'];
    return LiveDuelSnapshot(
      serverNow: DateTime.parse(json['serverNow'] as String),
      duelId: json['duelId'] as String,
      status: LiveDuelStatus.values.byName(json['status'] as String),
      mySide: DuelSide.values.byName(json['mySide'] as String),
      isRanked: json['isRanked'] as bool? ?? true,
      origin: json['origin'] as String? ?? 'matchmaking',
      topic: DuelTopic.fromJson(
        Map<String, dynamic>.from(json['topic'] as Map),
      ),
      me: DuelPlayer.fromJson(Map<String, dynamic>.from(json['me'] as Map)),
      opponent: DuelPlayer.fromJson(
        Map<String, dynamic>.from(json['opponent'] as Map),
      ),
      config: config,
      currentRound: (json['currentRound'] as num?)?.toInt() ?? 0,
      round: round is Map
          ? LiveDuelRoundState.fromJson(Map<String, dynamic>.from(round))
          : null,
      history: [
        for (final entry in json['history'] as List? ?? const [])
          _historyRecord(
            Map<String, dynamic>.from(entry as Map),
            roundSeconds: config.roundSeconds,
          ),
      ],
      myScore: (json['myScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      result: result is Map
          ? LiveDuelOutcome.fromJson(Map<String, dynamic>.from(result))
          : null,
    );
  }

  static DuelRoundRecord _historyRecord(
    Map<String, dynamic> json, {
    required int roundSeconds,
  }) => DuelRoundRecord.live(
    roundNumber: (json['round'] as num).toInt(),
    outcome: switch (json['outcome']) {
      'me' => RoundOutcome.playerWon,
      'opponent' => RoundOutcome.opponentWon,
      _ => RoundOutcome.draw,
    },
    correctIndex: (json['correctIndex'] as num).toInt(),
    roundSeconds: roundSeconds,
    playerChoice: (json['myChoice'] as num?)?.toInt(),
    opponentChoice: (json['opponentChoice'] as num?)?.toInt(),
    playerMs: (json['myMs'] as num?)?.toInt(),
    opponentMs: (json['opponentMs'] as num?)?.toInt(),
  );

  /// Decodes one room broadcast, or null (logged in debug) for an unknown or
  /// malformed one.
  static DuelRoomEvent? _decodeRoomMessage(BroadcastMessage message) {
    final p = message.payload;
    try {
      return switch (message.event) {
        DuelRealtime.roundStart => RoundScheduled(
          round: _int(p['round']),
          startsAt: DateTime.parse(p['startsAt'] as String),
          deadline: DateTime.parse(p['deadline'] as String),
          roundSeconds: _int(p['roundSeconds']),
          totalRounds: _int(p['totalRounds']),
        ),
        DuelRealtime.answerLocked => AnswerLocked(
          userId: p['userId'] as String,
          round: _int(p['round']),
          ms: (p['ms'] as num?)?.toInt(),
        ),
        DuelRealtime.roundResult => RoundResolved(
          round: _int(p['round']),
          outcome: RoundSideOutcome.values.byName(p['outcome'] as String),
          correctIndex: _int(p['correctIndex']),
          p1Choice: (p['p1Choice'] as num?)?.toInt(),
          p2Choice: (p['p2Choice'] as num?)?.toInt(),
          p1Ms: (p['p1Ms'] as num?)?.toInt(),
          p2Ms: (p['p2Ms'] as num?)?.toInt(),
          p1Rounds: _int(p['p1Rounds']),
          p2Rounds: _int(p['p2Rounds']),
        ),
        DuelRealtime.duelEnd => DuelFinished(
          reason: p['reason'] as String,
          cause: p['cause'] as String?,
          winnerId: p['winnerId'] as String?,
          isRanked: p['isRanked'] as bool? ?? false,
          forfeitedBy: p['forfeitedBy'] as String?,
          p1Rounds: (p['p1Rounds'] as num?)?.toInt() ?? 0,
          p2Rounds: (p['p2Rounds'] as num?)?.toInt() ?? 0,
          p1AvgMs: (p['p1AvgMs'] as num?)?.toDouble(),
          p2AvgMs: (p['p2AvgMs'] as num?)?.toDouble(),
          p1: _sideResult(p['p1']),
          p2: _sideResult(p['p2']),
        ),
        DuelRealtime.rematch => RematchUpdate(
          status: RematchStatus.values.byName(p['status'] as String),
          requestedBy: (p['requestedBy'] ?? p['by']) as String?,
          duelId: p['duelId'] as String?,
        ),
        _ => _ignored(message, 'unknown event'),
      };
    } on Object catch (error) {
      return _ignored(message, '$error');
    }
  }

  static int _int(Object? value) => (value! as num).toInt();

  static DuelSideResult? _sideResult(Object? value) => value is Map
      ? DuelSideResult.fromJson(Map<String, dynamic>.from(value))
      : null;

  static DuelRoomEvent? _ignored(BroadcastMessage message, String why) {
    if (kDebugMode) {
      debugPrint('LiveDuelRepository: ignored ${message.event} ($why)');
    }
    return null;
  }
}
