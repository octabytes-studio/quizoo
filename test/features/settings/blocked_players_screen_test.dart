import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/blocked_players_cubit.dart';
import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:quizoo/core/safety/safety_repository.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/settings/presentation/screens/blocked_players_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

class _MockSafetyRepository extends Mock implements SafetyRepository {}

void main() {
  late _MockSafetyRepository repository;

  setUp(() {
    repository = _MockSafetyRepository();
  });

  testWidgets('an empty block list shows the explainer, not a dead end', (
    tester,
  ) async {
    when(() => repository.blockedPlayers()).thenAnswer((_) async => const []);

    final cubit = BlockedPlayersCubit(repository);
    await cubit.load();
    await tester.pumpScreen(BlockedPlayersScreen(cubit: cubit));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(BlockedPlayersScreen)),
    );
    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text(l10n.safetyBlockedPlayersEmptyTitle), findsOneWidget);
  });

  testWidgets('each blocked player gets an Unblock action that removes them', (
    tester,
  ) async {
    var unblocked = false;
    when(() => repository.blockedPlayers()).thenAnswer(
      (_) async => unblocked
          ? const []
          : [
              BlockedPlayer(
                id: 'user_a',
                name: 'Ali',
                avatarEmoji: '🦊',
                blockedAt: DateTime(2026, 10, 17),
              ),
            ],
    );
    when(() => repository.unblock('user_a')).thenAnswer((_) async {
      unblocked = true;
    });

    final cubit = BlockedPlayersCubit(repository);
    await cubit.load();
    await tester.pumpScreen(BlockedPlayersScreen(cubit: cubit));
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(BlockedPlayersScreen)),
    );
    expect(find.text('Ali'), findsOneWidget);
    expect(find.byType(ListRowTile), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ChunkyButton, l10n.safetyUnblockPlayer),
    );
    await tester.pumpAndSettle();

    verify(() => repository.unblock('user_a')).called(1);
    expect(find.text('Ali'), findsNothing);
    expect(find.byType(EmptyStateView), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    when(
      () => repository.blockedPlayers(),
    ).thenThrow(const ApiException.network());

    final cubit = BlockedPlayersCubit(repository);
    await cubit.load();
    await tester.pumpScreen(BlockedPlayersScreen(cubit: cubit));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(BlockedPlayersScreen)),
    );
    expect(find.text(l10n.contentErrorTitle), findsOneWidget);
    expect(find.widgetWithText(ChunkyButton, l10n.commonRetry), findsOneWidget);
  });
}
