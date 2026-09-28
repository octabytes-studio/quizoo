import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_rpc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A live duel's endpoints (plan 017, Phase 5) — state snapshot, readiness,
/// per-round question delivery, answers, timeouts, heartbeats, leaving and
/// the rematch handshake — plus its room channel and the player's inbox.
class LiveDuelApi {
  LiveDuelApi(this._client, this._realtime);

  final SupabaseClient _client;
  final DuelRealtime _realtime;

  String? get currentUserId => _realtime.currentUserId;

  Future<Map<String, dynamic>> fetchState(String duelId) =>
      _client.rpcObject('get_duel_state', {'p_duel_id': duelId});

  Future<Map<String, dynamic>> markReady(String duelId) =>
      _client.rpcObject('mark_duel_ready', {'p_duel_id': duelId});

  Future<Map<String, dynamic>> fetchRound(String duelId, int round) => _client
      .rpcObject('get_duel_round', {'p_duel_id': duelId, 'p_round': round});

  Future<Map<String, dynamic>> submitAnswer(
    String duelId, {
    required int round,
    required int? choice,
    required int clientMs,
  }) => _client.rpcObject('submit_duel_answer', {
    'p_duel_id': duelId,
    'p_round': round,
    'p_choice': choice,
    'p_client_ms': clientMs,
  });

  Future<Map<String, dynamic>> claimTimeout(String duelId, int round) =>
      _client.rpcObject('claim_duel_round_timeout', {
        'p_duel_id': duelId,
        'p_round': round,
      });

  Future<Map<String, dynamic>> heartbeat(String duelId) =>
      _client.rpcObject('duel_heartbeat', {'p_duel_id': duelId});

  Future<void> leave(String duelId) =>
      _client.rpcVoid('leave_duel', {'p_duel_id': duelId});

  Future<Map<String, dynamic>> requestRematch(String duelId) =>
      _client.rpcObject('request_duel_rematch', {'p_duel_id': duelId});

  Future<void> declineRematch(String duelId) =>
      _client.rpcVoid('decline_duel_rematch', {'p_duel_id': duelId});

  /// The duel's room — tracks the player's presence so the opponent can see
  /// a "reconnecting…" hint when it drops.
  Stream<DuelBroadcast> roomStream(String duelId) => _realtime.watch(
    DuelRealtime.room(duelId),
    events: DuelRealtime.roomEvents,
    trackPresence: true,
  );

  Stream<DuelBroadcast> inboxStream() {
    final userId = _realtime.currentUserId;
    if (userId == null) return const Stream.empty();
    return _realtime.watch(
      DuelRealtime.inbox(userId),
      events: const [DuelRealtime.duelStart],
    );
  }
}
