import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The player-safety endpoints (plan 025): the viewer's block list and the
/// report/block writes.
///
/// RLS keeps this narrow: `user_blocks` only ever exposes rows where the
/// caller is the blocker (so "my block list" needs no client-side filter),
/// and `user_reports` is write-once for the reporter — the claimed player can
/// never read it.
class SafetyApi {
  SafetyApi(this._client);

  final SupabaseClient _client;

  static const String _blocksTable = 'user_blocks';
  static const String _reportsTable = 'user_reports';

  /// The viewer's own blocked ids — what leaderboard filtering needs.
  Future<Set<String>> blockedIds() async {
    try {
      final rows = await _client.from(_blocksTable).select('blocked_id');
      return {for (final row in rows) row['blocked_id'] as String};
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Privacy → Blocked players: names and avatars for the management list.
  Future<List<BlockedPlayer>> blockedPlayers() async {
    try {
      final rows = await _client
          .from(_blocksTable)
          .select('blocked_id, created_at')
          .order('created_at', ascending: false);
      if (rows.isEmpty) return const [];

      final profiles = await _client
          .from('profiles')
          .select('id, username, avatar_key')
          .inFilter('id', [
            for (final row in rows) row['blocked_id'] as String,
          ]);
      final byId = {for (final row in profiles) row['id'] as String: row};

      return [
        for (final row in rows)
          BlockedPlayer(
            id: row['blocked_id'] as String,
            name: byId[row['blocked_id']]?['username'] as String? ?? '—',
            avatarEmoji:
                byId[row['blocked_id']]?['avatar_key'] as String? ?? '🐼',
            blockedAt: DateTime.parse(row['created_at'] as String),
          ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Idempotent: blocking an already-blocked player is a no-op rather than
  /// an error (the pair is the primary key).
  Future<void> block(String playerId) async {
    final userId = _requireUserId();
    try {
      await _client
          .from(_blocksTable)
          .upsert(
            {'blocker_id': userId, 'blocked_id': playerId},
            onConflict: 'blocker_id,blocked_id',
            ignoreDuplicates: true,
          );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<void> unblock(String playerId) async {
    final userId = _requireUserId();
    try {
      await _client
          .from(_blocksTable)
          .delete()
          .eq('blocker_id', userId)
          .eq('blocked_id', playerId);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Files a player report. [reason] is a [PlayerReportReason.code]-style
  /// stable string; [note] is reserved for a future free-text addition.
  Future<void> reportPlayer({
    required String playerId,
    required String reason,
    String? note,
  }) async {
    final userId = _requireUserId();
    try {
      await _client.from(_reportsTable).insert({
        'reporter_id': userId,
        'reported_id': playerId,
        'reason': reason,
        'note': ?note,
      });
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ApiException(
        'Not signed in',
        kind: ApiErrorKind.unauthorized,
      );
    }
    return userId;
  }
}
