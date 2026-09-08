import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real notifications endpoint, over `app_notifications` joined
/// `profiles` (for a duel-challenge row's `challenger_id`).
///
/// [markAllRead]/[acceptChallenge] are `Future`-returning now — a real
/// signature change from the mock's synchronous mutation of an in-memory
/// list, since both are genuine network calls against a real backend (plan
/// 006, Assumption #6).
class NotificationsApi {
  NotificationsApi(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchAll() async {
    try {
      final userId = _requireUserId();
      final rows = await _client
          .from('app_notifications')
          .select('*, profiles!challenger_id(username, avatar_key, elo)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return [for (final row in rows) _fromRow(row)];
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  Future<List<AppNotification>> markAllRead() async {
    try {
      final userId = _requireUserId();
      await _client
          .from('app_notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
      return fetchAll();
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Dismisses the notification. Actually starting the duel it challenged to
  /// is a separate call into `features/duel`'s own flow — this only clears
  /// the notification row, matching the mock's own scope (plan 006, Design
  /// overview).
  Future<List<AppNotification>> acceptChallenge(String id) async {
    try {
      final userId = _requireUserId();
      await _client
          .from('app_notifications')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      return fetchAll();
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

  static AppNotification _fromRow(Map<String, dynamic> row) {
    final challenger = row['profiles'] as Map<String, dynamic>?;
    return AppNotification(
      id: row['id'] as String,
      kind: NotificationKind.values.firstWhere(
        (value) => value.name == row['kind'],
        orElse: () => NotificationKind.newContent,
      ),
      title: row['title'] as String,
      body: row['body'] as String,
      timeLabel: _relativeTime(DateTime.parse(row['created_at'] as String)),
      isRead: row['is_read'] as bool? ?? false,
      challengerName: challenger?['username'] as String?,
      challengerAvatarEmoji: challenger?['avatar_key'] as String?,
      challengerElo: challenger?['elo'] as int?,
    );
  }

  static String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
