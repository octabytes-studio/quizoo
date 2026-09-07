import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// S-44's five row kinds. Only [duelChallenge] embeds its own action — every
/// other kind is purely informational (plan 004, Research findings).
enum NotificationKind {
  duelChallenge,
  streakEnding,
  leagueRankDrop,
  newContent,
  rewardClaimed,
}

/// One row of S-44's list.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationKind kind,
    required String title,
    required String body,
    required String timeLabel,
    @Default(false) bool isRead,

    /// Set only on [NotificationKind.duelChallenge] — the friend whose
    /// "Accept" pill starts the duel.
    String? challengerName,
    String? challengerAvatarEmoji,
    int? challengerElo,
  }) = _AppNotification;

  const AppNotification._();

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  bool get isActionable => kind == NotificationKind.duelChallenge;
}
