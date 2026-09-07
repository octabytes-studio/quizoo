part of 'notifications_cubit.dart';

/// S-44's states (CLAUDE.md §3).
sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => const [];
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.notifications);

  final List<AppNotification> notifications;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  @override
  List<Object?> get props => [notifications];
}

final class NotificationsError extends NotificationsState {
  const NotificationsError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
