import 'package:quizoo/features/settings/data/notifications_api.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';

/// The only thing that talks to [NotificationsApi].
class NotificationsRepository {
  NotificationsRepository(this._api);

  final NotificationsApi _api;

  Future<List<AppNotification>> fetchAll() => _api.fetchAll();

  List<AppNotification> markAllRead() => _api.markAllRead();

  List<AppNotification> acceptChallenge(String id) => _api.acceptChallenge(id);
}
