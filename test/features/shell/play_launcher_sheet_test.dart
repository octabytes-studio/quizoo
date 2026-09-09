import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/app.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';
import 'package:quizoo/features/shell/presentation/widgets/play_launcher_sheet.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';

void main() {
  // Home now loads real content, and MockApi fails one request in
  // twenty-five in a debug build on purpose. Pin it so this suite is not
  // intermittently red for reasons it does not test.
  useMockApiFailureRate();

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..physicalSize = const Size(
        Breakpoints.designWidth,
        Breakpoints.designHeight,
      )
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
  });

  Future<GoRouter> pumpShell(WidgetTester tester) async {
    final router = AppRouter.create()..go(AppRoutes.home);
    await tester.pumpWidget(
      QuizooApp(router: router, preferences: await testPreferences()),
    );
    await tester.pumpAndSettle();
    return router;
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(AppTabBar)));

  testWidgets('the FAB opens the play sheet and turns into a close icon', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.byType(PlayLauncherSheet), findsNothing);
    expect(find.text('⚔️'), findsOneWidget);

    await tester.tap(find.text('⚔️'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayLauncherSheet), findsOneWidget);
    // The FAB rotates 45° into a close icon while the sheet is open.
    expect(find.text('✕'), findsOneWidget);

    // The sheet's own duel row also carries a ⚔️, so the FAB's is gone.
    expect(find.text(l10nOf(tester).playSheetTitle), findsOneWidget);
  });

  testWidgets('the FAB restores once the sheet is dismissed', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('⚔️'));
    await tester.pumpAndSettle();
    expect(find.text('✕'), findsOneWidget);

    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();

    expect(find.byType(PlayLauncherSheet), findsNothing);
    expect(find.text('✕'), findsNothing);
  });

  group('each row routes where it should', () {
    Future<void> expectRowNavigatesTo(
      WidgetTester tester,
      String Function(AppLocalizations) rowLabel,
      String expectedLocation, {
      bool settle = true,
    }) async {
      final router = await pumpShell(tester);

      await tester.tap(find.text('⚔️'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(rowLabel(l10nOf(tester))));
      // MatchmakingScreen ticks its own clock once a second for up to 20s
      // (it always auto-offers a bot eventually), which keeps scheduling
      // frames — `pumpAndSettle` would fast-forward straight through the
      // whole search and land one screen further than this test cares
      // about. A single pump is enough to observe the push that follows the
      // tap.
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }

      expect(router.state.uri.toString(), expectedLocation);
    }

    testWidgets('1v1 Duel → matchmaking', (tester) async {
      await expectRowNavigatesTo(
        tester,
        (l10n) => l10n.playSheetDuel,
        AppRoutes.duelMatchmaking,
        settle: false,
      );
    });

    testWidgets('Quick Play → the play surface', (tester) async {
      await expectRowNavigatesTo(
        tester,
        (l10n) => l10n.playSheetQuickPlay,
        AppRoutes.quizPlayPath(PlayLauncherSheet.demoLevelId),
      );
    });

    testWidgets('Daily Challenge → the daily tab', (tester) async {
      await expectRowNavigatesTo(
        tester,
        (l10n) => l10n.playSheetDaily,
        AppRoutes.daily,
      );
    });

    testWidgets('Challenge a friend → friends', (tester) async {
      await expectRowNavigatesTo(
        tester,
        (l10n) => l10n.playSheetFriend,
        AppRoutes.friends,
      );
    });
  });
}
