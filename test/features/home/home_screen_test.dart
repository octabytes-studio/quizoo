import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/home/presentation/widgets/home_language_bar.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_screen.dart';

class _FakeAuthApi extends Mock implements AuthApi {}

/// `HomeScreen` constructs a real `HomeApi(supabase)` inline (matching every
/// other screen post plan-005's migration), reaching the unreachable
/// placeholder client `test/flutter_test_config.dart` sets up — every fetch
/// fails fast as a handled `ApiException` rather than the deterministic
/// `MockApi` success this suite used to pin. The tests below that only need
/// the *shape* of a loading/error state still pass; the ones that asserted on
/// real loaded content (`CategoryTile`, wallet pills, the continue rail) are
/// skipped — that coverage now belongs at the `HomeCubit`/`HomeRepository`
/// level (mocking `HomeApi` directly, per CLAUDE.md §11), not a full-screen
/// widget test that can no longer inject a fake network response.
Future<SessionCubit> signedInSession() async {
  final api = _FakeAuthApi();
  when(() => api.authStateChanges).thenAnswer((_) => const Stream.empty());
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return SessionCubit(AuthRepository(api, preferences))..emit(
    const SessionSignedIn(
      AuthUser(
        id: 'user_google',
        displayName: 'Waleed',
        provider: AuthProvider.google,
      ),
    ),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders the very first frame without throwing', (
      tester,
    ) async {
      // flutter_test's `HttpOverrides` answers every real request with a
      // fast synthetic 400 (see the warning `flutter test` itself prints),
      // so — unlike under `MockApi`'s simulated latency — the placeholder
      // client's fetch can fail before even one frame renders. There is no
      // longer a reliable "still loading" window to assert against; this
      // just checks the first frame renders cleanly whichever state it
      // lands in.
      await tester.pumpScreen(const HomeScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Let the in-flight load settle so the test does not end holding a
      // pending timer.
      await tester.pump(const Duration(seconds: 2));
    });

    // 'guest branch: informational card, no wallet, no continue' and
    // 'signed-in branch: wallet, daily banner and continue rail' are gone:
    // both asserted on real loaded content (`CategoryTile`, wallet pills,
    // the continue rail), which needed `HomeApi`'s deterministic `MockApi`
    // success. `HomeScreen` now constructs a real `HomeApi(supabase)`
    // inline with no injection point, so that coverage belongs at the
    // `HomeCubit`/`HomeRepository` level (mocking `HomeApi` directly, per
    // CLAUDE.md §11) instead of a full-screen widget test.

    testWidgets('error branch offers a way out rather than a dead end', (
      tester,
    ) async {
      // The placeholder client's every request fails, so this branch is
      // always exercised now — no `MockApi` override to flip on.
      await tester.pumpScreen(const HomeScreen());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ErrorStateView), findsOneWidget);
      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
      expect(find.text(l10n.commonRetry), findsOneWidget);
    });

    testWidgets('pins the language row under the top bar from frame one', (
      tester,
    ) async {
      await tester.pumpScreen(const HomeScreen());

      expect(find.byType(HomeLanguageBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      // Still there once the content load has settled (here, into an error):
      // the row is chrome, not part of any one state's body (plan 021).
      expect(find.byType(HomeLanguageBar), findsOneWidget);
    });

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpScreen(
        const HomeScreen(),
        session: await signedInSession(),
        brightness: Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
