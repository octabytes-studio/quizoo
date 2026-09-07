import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';

/// The mocked notifications endpoint.
///
/// A fixed list of five rows matching the bible's own S-44 examples (plan
/// 004, Research findings) — held as mutable instance state so
/// [markAllRead]/[acceptChallenge] can mutate it in place, exactly like
/// `AuthRepository`'s in-memory flags.
class NotificationsApi extends MockApi {
  NotificationsApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  final List<AppNotification> _rows = [
    const AppNotification(
      id: 'notif_duel_challenge',
      kind: NotificationKind.duelChallenge,
      title: 'Danish M. challenged you to a duel',
      body: 'Best of 5 · winner takes 200 🪙',
      timeLabel: '2m ago',
      challengerName: 'Danish M.',
      challengerAvatarEmoji: '🦁',
      challengerElo: 1310,
    ),
    const AppNotification(
      id: 'notif_streak_ending',
      kind: NotificationKind.streakEnding,
      title: 'Your 12-day streak ends in 3 hours',
      body: 'Play one level to keep it alive.',
      timeLabel: '1h ago',
    ),
    const AppNotification(
      id: 'notif_league_drop',
      kind: NotificationKind.leagueRankDrop,
      title: "You've dropped to 8th in Gold League",
      body: 'The top 5 get promoted this week.',
      timeLabel: '5h ago',
      isRead: true,
    ),
    const AppNotification(
      id: 'notif_new_content',
      kind: NotificationKind.newContent,
      title: 'Basketball is now live',
      body: '20 new levels just landed in Sports.',
      timeLabel: 'Yesterday',
      isRead: true,
    ),
    const AppNotification(
      id: 'notif_reward_claimed',
      kind: NotificationKind.rewardClaimed,
      title: 'Reward claimed: 14-day streak',
      body: "You earned 1,000 🪙 — they're in your wallet.",
      timeLabel: '2 days ago',
      isRead: true,
    ),
  ];

  Future<List<AppNotification>> fetchAll() =>
      respond(() => List.unmodifiable(_rows));

  List<AppNotification> markAllRead() {
    for (var index = 0; index < _rows.length; index++) {
      _rows[index] = _rows[index].copyWith(isRead: true);
    }
    return List.unmodifiable(_rows);
  }

  /// Accepting resolves the challenge — it leaves the list rather than
  /// lingering as an already-actioned row.
  List<AppNotification> acceptChallenge(String id) {
    _rows.removeWhere((notification) => notification.id == id);
    return List.unmodifiable(_rows);
  }
}
