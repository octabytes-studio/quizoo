import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/shell/presentation/screens/app_shell_screen.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';

import '../../support/pump_app.dart';

void main() {
  /// The real shell over four trivial tab pages, plus a stand-in arena.
  ///
  /// Deliberately not the whole `QuizooApp`: that would build the real Duel
  /// Arena on the FAB tap, which opens Realtime channels against the test
  /// suite's placeholder Supabase host. What this suite checks is the shell's
  /// own wiring — which route the FAB pushes.
  Future<GoRouter> pumpShell(WidgetTester tester) async {
    StatefulShellBranch branch(String path) => StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => Center(child: Text('tab:$path')),
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShellScreen(navigationShell: navigationShell),
          branches: [
            branch(AppRoutes.home),
            branch(AppRoutes.ranks),
            branch(AppRoutes.daily),
            branch(AppRoutes.you),
          ],
        ),
        GoRoute(
          path: AppRoutes.duelArena,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('arena'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpApp(Router.withConfig(config: router));
    await tester.pumpAndSettle();
    return router;
  }

  group('AppShellScreen', () {
    testWidgets('renders the tab bar with the ⚔️ FAB and no play sheet', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(find.byType(AppTabBar), findsOneWidget);
      expect(find.text('⚔️'), findsOneWidget);
      expect(find.text('tab:${AppRoutes.home}'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('tapping the FAB pushes AppRoutes.duelArena', (tester) async {
      final router = await pumpShell(tester);

      await tester.tap(find.text('⚔️'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.duelArena);
      expect(find.text('arena'), findsOneWidget);
      // Pushed over the shell, never a sheet.
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the Daily tab is still a tab', (tester) async {
      final router = await pumpShell(tester);

      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.daily);
      expect(find.text('tab:${AppRoutes.daily}'), findsOneWidget);
    });
  });
}
