import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/safety_repository.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/player_actions_sheet.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

class _MockSafetyRepository extends Mock implements SafetyRepository {}

/// Pumps a host whose button opens [PlayerActionsSheet] with the fake
/// repository injected through `PlayerActionsSheet`'s test seam — the same
/// `AppBottomSheet.show` production uses.
Future<void> pumpActions(
  WidgetTester tester,
  SafetyRepository repository, {
  bool isBlocked = false,
}) async {
  await tester.pumpScreen(
    Builder(
      builder: (context) => TextButton(
        onPressed: () => AppBottomSheet.show<bool>(
          context,
          builder: (_) => PlayerActionsSheet(
            playerId: 'user_a',
            playerName: 'Ali',
            isBlocked: isBlocked,
            safetyRepository: repository,
          ),
        ),
        child: const Text('open actions'),
      ),
    ),
  );

  await tester.tap(find.text('open actions'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockSafetyRepository repository;

  setUp(() {
    repository = _MockSafetyRepository();
  });

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(PlayerActionsSheet)));

  testWidgets('the sheet opens on the actions, and reporting swaps in the '
      'reason list with a gated submit', (tester) async {
    await pumpActions(tester, repository);

    final l10n = l10nOf(tester);
    expect(find.text(l10n.safetyReportPlayer), findsOneWidget);
    expect(find.text(l10n.safetyReasonHarassment), findsNothing);

    await tester.tap(find.text(l10n.safetyReportPlayer));
    await tester.pumpAndSettle();

    expect(find.text(l10n.safetyReasonHarassment), findsOneWidget);
    final submit = find.widgetWithText(ChunkyButton, l10n.safetyReportSubmit);
    expect(tester.widget<ChunkyButton>(submit).onPressed, isNull);

    await tester.tap(find.text(l10n.safetyReasonHarassment));
    await tester.pump();
    expect(tester.widget<ChunkyButton>(submit).onPressed, isNotNull);
  });

  testWidgets('submitting a report calls the repository with the stable '
      'reason code and closes the sheet', (tester) async {
    when(
      () => repository.reportPlayer(
        playerId: any(named: 'playerId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});

    await pumpActions(tester, repository);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.safetyReportPlayer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.safetyReasonHarassment));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ChunkyButton, l10n.safetyReportSubmit),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.reportPlayer(
        playerId: 'user_a',
        reason: 'harassment',
        note: null,
      ),
    ).called(1);
    expect(find.text(l10n.safetyReportSent), findsOneWidget);
  });

  testWidgets('blocking calls the repository and confirms with the blocked '
      'copy', (tester) async {
    when(() => repository.block('user_a')).thenAnswer((_) async {});

    await pumpActions(tester, repository);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.safetyBlockPlayer), findsOneWidget);
    await tester.tap(find.text(l10n.safetyBlockPlayer));
    await tester.pumpAndSettle();

    verify(() => repository.block('user_a')).called(1);
    expect(find.text(l10n.safetyBlocked), findsOneWidget);
  });

  testWidgets('a blocked player shows the unblock action instead', (
    tester,
  ) async {
    await pumpActions(tester, repository, isBlocked: true);

    final l10n = l10nOf(tester);
    expect(find.text(l10n.safetyUnblockPlayer), findsOneWidget);
    expect(find.text(l10n.safetyBlockPlayer), findsNothing);
  });

  testWidgets('unblocking calls the repository and confirms', (tester) async {
    when(() => repository.unblock('user_a')).thenAnswer((_) async {});

    await pumpActions(tester, repository, isBlocked: true);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.safetyUnblockPlayer));
    await tester.pumpAndSettle();

    verify(() => repository.unblock('user_a')).called(1);
    expect(find.text(l10n.safetyUnblocked), findsOneWidget);
  });

  testWidgets('a failed report shows the error and keeps the sheet open on '
      'the reason list', (tester) async {
    when(
      () => repository.reportPlayer(
        playerId: any(named: 'playerId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenThrow(const ApiException.network());

    await pumpActions(tester, repository);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.safetyReportPlayer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.safetyReasonCheating));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ChunkyButton, l10n.safetyReportSubmit),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.safetyActionFailed, skipOffstage: false),
      findsOneWidget,
    );
    // Still open on the reason list, so a retry is one tap.
    expect(find.text(l10n.safetyReasonCheating), findsOneWidget);
  });
}
