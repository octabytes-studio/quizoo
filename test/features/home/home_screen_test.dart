import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/widgets/category_tile.dart';
import 'package:quizoo/core/widgets/currency_pill.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/home/presentation/widgets/continue_row.dart';
import 'package:quizoo/features/home/presentation/widgets/home_banner.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';

void main() {
  useMockApiFailureRate();

  SessionCubit signedInSession() =>
      SessionCubit(AuthRepository(AuthApi()))..emit(
        const SessionSignedIn(
          AuthUser(
            id: 'user_google',
            displayName: 'Waleed',
            provider: AuthProvider.google,
          ),
        ),
      );

  group('HomeScreen', () {
    testWidgets('loading branch renders before any content exists', (
      tester,
    ) async {
      await tester.pumpScreen(const HomeScreen());
      // The first frame, before the cached read resolves.
      await tester.pump();

      // No content, no error — and deliberately no skeleton yet either: a
      // `SkeletonBox` waits out `AppMotion.skeletonDelay` first, because
      // anything faster just flashes (§06).
      expect(find.byType(CategoryTile), findsNothing);
      expect(find.byType(ErrorStateView), findsNothing);
      expect(tester.takeException(), isNull);

      // Let the in-flight load settle so the test does not end holding a
      // pending timer.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('guest branch: informational card, no wallet, no continue', (
      tester,
    ) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pump(const Duration(seconds: 2));

      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeWelcome), findsOneWidget);
      expect(find.text(l10n.homePlayingAsGuest), findsOneWidget);
      expect(find.byType(SaveProgressCard), findsOneWidget);

      // A guest has earned nothing and started nothing.
      expect(find.byType(CurrencyPill), findsNothing);
      expect(find.byType(ContinueRow), findsNothing);
      expect(find.byType(DailyChallengeBanner), findsNothing);

      expect(find.byType(CategoryTile), findsWidgets);
    });

    testWidgets('signed-in branch: wallet, daily banner and continue rail', (
      tester,
    ) async {
      await tester.pumpScreen(const HomeScreen(), session: signedInSession());
      await tester.pump(const Duration(seconds: 2));

      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeGreeting('Waleed')), findsOneWidget);
      // Coin and life pills.
      expect(find.byType(CurrencyPill), findsNWidgets(2));
      // The bible's order: daily banner first, then Continue.
      expect(find.byType(DailyChallengeBanner), findsOneWidget);
      expect(find.byType(ContinueRow), findsOneWidget);
      expect(find.byType(SaveProgressCard), findsNothing);
    });

    testWidgets('error branch offers a way out rather than a dead end', (
      tester,
    ) async {
      MockApi.failureRateOverride = 1;
      addTearDown(() => MockApi.failureRateOverride = 0);

      await tester.pumpScreen(const HomeScreen());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ErrorStateView), findsOneWidget);
      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
      expect(find.text(l10n.commonRetry), findsOneWidget);
    });

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpScreen(
        const HomeScreen(),
        session: signedInSession(),
        brightness: Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
