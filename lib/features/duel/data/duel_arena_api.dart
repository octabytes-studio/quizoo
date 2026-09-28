import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_rpc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Duel Arena's endpoints (plan 017, Phase 3): the lobby snapshot, topic
/// list, challenge create/cancel, presence, and the join-request handshake —
/// plus the two Realtime topics the arena listens to.
///
/// Returns raw JSON; `DuelArenaRepository` is the only place it becomes
/// domain models (CLAUDE.md §9).
class DuelArenaApi {
  DuelArenaApi(this._client, this._realtime);

  final SupabaseClient _client;
  final DuelRealtime _realtime;

  Future<Map<String, dynamic>> fetchLobby(String languageCode) =>
      _client.rpcObject('get_duel_lobby', {'p_language_code': languageCode});

  Future<List<dynamic>> fetchTopics(String languageCode) =>
      _client.rpcList('list_duel_topics', {'p_language_code': languageCode});

  Future<Map<String, dynamic>> createChallenge(String subcategoryId) => _client
      .rpcObject('create_duel_challenge', {'p_subcategory_id': subcategoryId});

  Future<void> cancelChallenge(String challengeId) =>
      _client.rpcVoid('cancel_duel_challenge', {'p_challenge_id': challengeId});

  Future<Map<String, dynamic>> setPresence({required bool present}) =>
      _client.rpcObject('set_duel_lobby_presence', {'p_present': present});

  Future<Map<String, dynamic>> requestJoin(String challengeId) =>
      _client.rpcObject('request_duel_join', {'p_challenge_id': challengeId});

  Future<void> withdrawJoin(String requestId) =>
      _client.rpcVoid('withdraw_duel_join', {'p_request_id': requestId});

  Future<Map<String, dynamic>> respondJoin(
    String requestId, {
    required bool accept,
  }) => _client.rpcObject('respond_duel_join', {
    'p_request_id': requestId,
    'p_accept': accept,
  });

  /// The arena feed for [languageCode]; tracks the viewer's presence when
  /// [trackPresence] so the "N in the arena" pill can count heads.
  Stream<DuelBroadcast> lobbyStream(
    String languageCode, {
    bool trackPresence = true,
  }) => _realtime.watch(
    DuelRealtime.lobby(languageCode),
    events: DuelRealtime.lobbyEvents,
    trackPresence: trackPresence,
  );

  /// The viewer's own inbox — incoming requests, request status changes and
  /// `duel_start`. Empty with no session.
  Stream<DuelBroadcast> inboxStream() {
    final userId = _realtime.currentUserId;
    if (userId == null) return const Stream.empty();
    return _realtime.watch(
      DuelRealtime.inbox(userId),
      events: DuelRealtime.inboxEvents,
    );
  }
}
