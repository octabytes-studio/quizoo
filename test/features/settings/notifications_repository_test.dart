import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/settings/data/notifications_api.dart';
import 'package:quizoo/features/settings/data/notifications_repository.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';

class _MockNotificationsApi extends Mock implements NotificationsApi {}

void main() {
  late _MockNotificationsApi api;
  late NotificationsRepository repository;

  const row = AppNotification(
    id: 'n1',
    kind: NotificationKind.rewardClaimed,
    title: 'Reward claimed',
    body: 'Nice one',
    timeLabel: 'now',
  );

  setUp(() {
    api = _MockNotificationsApi();
    repository = NotificationsRepository(api);
  });

  group('NotificationsRepository', () {
    test('success path: hands back the fetched list unchanged', () async {
      when(() => api.fetchAll()).thenAnswer((_) async => const [row]);

      expect(await repository.fetchAll(), [row]);
    });

    test('failure path: the API\'s ApiException reaches the caller', () async {
      when(() => api.fetchAll()).thenThrow(const ApiException.network());

      expect(repository.fetchAll, throwsA(isA<ApiException>()));
    });

    test('delegates markAllRead and acceptChallenge to the API', () {
      when(() => api.markAllRead()).thenReturn([row]);
      when(() => api.acceptChallenge('n1')).thenReturn(const []);

      expect(repository.markAllRead(), [row]);
      expect(repository.acceptChallenge('n1'), isEmpty);
    });
  });
}
