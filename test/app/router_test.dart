import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/app.dart';

import '../support/pump_app.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/dev/presentation/screens/placeholder_screen.dart';
import 'package:quizoo/features/catalog/presentation/screens/level_map_screen.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/quiz_play_screen.dart';
import 'package:quizoo/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:quizoo/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:quizoo/features/dev/presentation/screens/screen_index_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:quizoo/features/profile/presentation/screens/profile_screen.dart';
import 'package:quizoo/features/shell/presentation/screens/app_shell_screen.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';
import 'package:quizoo/l10n/app_localizations.dart';

void main() {
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

  Future<GoRouter> pumpAppAt(WidgetTester tester, String location) async {
    final router = AppRouter.create()..go(location);
    await tester.pumpWidget(QuizooApp(router: router));
    await tester.pumpAndSettle();
    return router;
  }

  group('AppRoutes', () {
    test('reserves all 54 screen IDs', () {
      expect(kScreenIndex, hasLength(54));

      final ids = kScreenIndex.map((screen) => screen.id).toSet();
      expect(ids, hasLength(54));
      for (var number = 1; number <= 54; number++) {
        expect(ids, contains('S-${number.toString().padLeft(2, '0')}'));
      }
    });

    test('every screen resolves to a route the router can match', () {
      final router = AppRouter.create();

      for (final screen in kScreenIndex) {
        final location = ScreenIndexScreen.resolve(screen.path);
        final match = router.configuration.findMatch(Uri.parse(location));

        expect(
          match.routes,
          isNotEmpty,
          reason: '${screen.id} (${screen.name}) has no route at $location',
        );
      }
    });

    test('only the documented state aliases share a path', () {
      final byPath = <String, List<String>>{};
      for (final screen in kScreenIndex) {
        byPath.putIfAbsent(screen.path, () => []).add(screen.id);
      }

      for (final entry in byPath.entries.where((e) => e.value.length > 1)) {
        // The first ID on a shared path is the destination; the rest must be
        // declared states of it, not accidental duplicates.
        final owner = entry.value.first;
        for (final id in entry.value.skip(1)) {
          expect(
            AppRoutes.stateAliases[id],
            owner,
            reason: '$id shares ${entry.key} but is not a declared state',
          );
        }
      }
    });
  });

  group('router skeleton', () {
    testWidgets('boots on the splash route and hands off to onboarding', (
      tester,
    ) async {
      await tester.pumpWidget(const QuizooApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      // §01's contract: splash never holds longer than 1200 ms, and on a
      // first launch it hands off to onboarding rather than Home.
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('a shell tab renders inside the shell with the tab bar', (
      tester,
    ) async {
      await pumpAppAt(tester, AppRoutes.home);

      expect(find.byType(AppShellScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the tab bar leaves the shell body room to lay out in', (
      tester,
    ) async {
      await pumpAppAt(tester, AppRoutes.home);

      // A regression guard: the centre FAB used to stretch the bar to the
      // full viewport height, which left every tab's body at zero and was
      // invisible while the bodies were all placeholders built from Spacers.
      final barHeight = tester.getSize(find.byType(AppTabBar)).height;
      expect(barHeight, lessThan(Breakpoints.designHeight / 4));
      expect(
        tester.getSize(find.byType(HomeScreen)).height,
        greaterThan(Breakpoints.designHeight / 2),
      );
    });

    testWidgets('switching tabs keeps the shell and changes the body', (
      tester,
    ) async {
      await pumpAppAt(tester, AppRoutes.home);

      final l10n = AppLocalizations.of(tester.element(find.byType(AppTabBar)));

      // Scoped to the tab bar itself — the leaderboard's own pinned self-row
      // and Ranks/You tab labels can otherwise collide on the same text.
      Finder tabLabel(String label) => find.descendant(
        of: find.byType(AppTabBar),
        matching: find.text(label),
      );

      await tester.tap(tabLabel(l10n.tabRanks));
      await tester.pumpAndSettle();
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsOneWidget);

      await tester.tap(tabLabel(l10n.tabYou));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('a pushed route covers the tab bar', (tester) async {
      await pumpAppAt(tester, AppRoutes.quizPlayPath('demo'));

      expect(find.byType(QuizPlayScreen), findsOneWidget);
      // The play surface is pushed onto the root navigator, so the shell's
      // tab bar is not on screen (§02).
      expect(find.byType(AppTabBar), findsNothing);
    });

    testWidgets('a dynamic segment reaches its screen', (tester) async {
      await pumpAppAt(
        tester,
        AppRoutes.levelMapPath(MockCatalog.sportsId, MockCatalog.footballId),
      );

      expect(find.byType(LevelMapScreen), findsOneWidget);
      // The topic names itself twice, as the bible's frame does: once in the
      // top bar and once on the header stat card.
      expect(find.text('Football'), findsWidgets);
    });

    testWidgets('the debug index lists every screen and navigates', (
      tester,
    ) async {
      await pumpAppAt(tester, AppRoutes.screenIndex);

      expect(find.byType(ScreenIndexScreen), findsOneWidget);
      expect(find.textContaining('S-01'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('S-36'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('S-36'));
      await tester.pumpAndSettle();

      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
    });
  });

  group('arena screens', () {
    testWidgets('paint the same background in light and dark', (tester) async {
      List<Color> arenaColors() {
        final decorated = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(PlaceholderScreen),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final gradient =
            (decorated.decoration as BoxDecoration).gradient! as LinearGradient;
        return gradient.colors;
      }

      final router = AppRouter.create()..go(AppRoutes.duelPlayPath('demo'));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: QuizooApp(router: router),
        ),
      );
      await tester.pumpAndSettle();
      final light = arenaColors();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: QuizooApp(router: router),
        ),
      );
      await tester.pumpAndSettle();
      final dark = arenaColors();

      // The arena must not repaint on brightness — the easy mistake to make
      // backwards, hence a regression test rather than a comment.
      expect(light, dark);
      expect(light.first, const Color(0xFF2A1B5E));
    });
  });
}
