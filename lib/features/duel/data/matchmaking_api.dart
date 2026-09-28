import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_rpc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick match's endpoints (plan 017, Phase 4): join, heartbeat (which also
/// retries pairing with the widened band), leave — plus the inbox, whose
/// `duel_start` announces a pairing before the next heartbeat would.
class MatchmakingApi {
  MatchmakingApi(this._client, this._realtime);

  final SupabaseClient _client;
  final DuelRealtime _realtime;

  Future<Map<String, dynamic>> join(String subcategoryId) => _client.rpcObject(
    'join_matchmaking',
    {'p_subcategory_id': subcategoryId},
  );

  Future<Map<String, dynamic>> heartbeat() =>
      _client.rpcObject('matchmaking_heartbeat');

  Future<void> leave() => _client.rpcVoid('leave_matchmaking');

  Stream<DuelBroadcast> inboxStream() {
    final userId = _realtime.currentUserId;
    if (userId == null) return const Stream.empty();
    return _realtime.watch(
      DuelRealtime.inbox(userId),
      events: const [DuelRealtime.duelStart],
    );
  }
}
