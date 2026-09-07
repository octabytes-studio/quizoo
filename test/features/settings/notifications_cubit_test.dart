import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/settings/data/notifications_repository.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';
import 'package:quizoo/features/settings/presentation/bloc/notifications_cubit.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late _MockNotificationsRepository repository;

  const unread = AppNotification(
    id: 'n1',
    kind: NotificationKind.streakEnding,
    title: 'Streak ending',
    body: 'Play a level',
    timeLabel: '1h ago',
  );
  const challenge = AppNotification(
    id: 'n2',
    kind: NotificationKind.duelChallenge,
    title: 'Danish challenged you',
    body: 'Best of 5',
    timeLabel: '2m ago',
    challengerName: 'Danish',
    challengerAvatarEmoji: '🦁',
    challengerElo: 1300,
  );

  setUp(() {
    repository = _MockNotificationsRepository();
  });

  group('NotificationsCubit', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'success path: loads the fixed list',
      setUp: () => when(
        () => repository.fetchAll(),
      ).thenAnswer((_) async => const [unread, challenge]),
      build: () => NotificationsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>()
            .having((state) => state.notifications, 'notifications', [
              unread,
              challenge,
            ])
            .having((state) => state.unreadCount, 'unreadCount', 2),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'failure path: a failed fetch ends in NotificationsError',
      setUp: () => when(
        () => repository.fetchAll(),
      ).thenThrow(const ApiException.network()),
      build: () => NotificationsCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<NotificationsLoading>(), isA<NotificationsError>()],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'marking all read clears every row\'s unread flag',
      setUp: () {
        when(
          () => repository.fetchAll(),
        ).thenAnswer((_) async => const [unread]);
        when(
          () => repository.markAllRead(),
        ).thenReturn([unread.copyWith(isRead: true)]);
      },
      build: () => NotificationsCubit(repository),
      act: (cubit) async {
        await cubit.load();
        cubit.markAllRead();
      },
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>(),
        isA<NotificationsLoaded>().having(
          (state) => state.unreadCount,
          'unreadCount',
          0,
        ),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'accepting a duel challenge resolves it off the list, in place — '
      'never a second screen to manage the list from',
      setUp: () {
        when(
          () => repository.fetchAll(),
        ).thenAnswer((_) async => const [unread, challenge]);
        when(() => repository.acceptChallenge('n2')).thenReturn([unread]);
      },
      build: () => NotificationsCubit(repository),
      act: (cubit) async {
        await cubit.load();
        cubit.acceptChallenge('n2');
      },
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>(),
        isA<NotificationsLoaded>().having(
          (state) => state.notifications,
          'notifications',
          [unread],
        ),
      ],
    );
  });
}
