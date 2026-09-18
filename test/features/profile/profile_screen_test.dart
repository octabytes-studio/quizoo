import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/profile/presentation/screens/profile_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_screen.dart';

class _FakeAuthApi extends Mock implements AuthApi {}

/// `ProfileScreen` constructs a real `ProfileApi(supabase)` inline (the same
/// DI-less pattern as `HomeScreen`, see `home_screen_test.dart`). In
/// production every player — guest or signed in — already carries a real
/// (possibly anonymous) Supabase session by the time this screen builds, so
/// `fetchSummary()` succeeds either way. `test/flutter_test_config.dart`
/// never establishes any session at all (no `signInAnonymously()` call, only
/// a placeholder client), so `_client.auth.currentUser` is null here and
/// `fetchSummary()` always fails `unauthorized` — landing on
/// `_ProfileSignInRequired` regardless of `SessionCubit`'s state. That
/// exercises the same sign-in CTA a real "no session at all" device would
/// show; the ordinary guest-with-real-data path (the loaded view's sign-in
/// nudge banner) is presentation-only glue that belongs to a `ProfileCubit`
/// unit test, not a full-screen widget test with no injection point.
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
  group('ProfileScreen', () {
    testWidgets('renders the very first frame without throwing', (
      tester,
    ) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('no-session branch offers a sign-in way out, not a dead end', (
      tester,
    ) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(EmptyStateView), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileScreen)),
      );
      expect(find.text(l10n.profileGuestTitle), findsOneWidget);
      expect(find.text(l10n.profileGuestAction), findsOneWidget);
    });

    testWidgets('the sign-in CTA pushes the save-progress sheet', (
      tester,
    ) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pump(const Duration(seconds: 2));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileScreen)),
      );
      await tester.tap(find.text(l10n.profileGuestAction));
      await tester.pumpAndSettle();

      expect(find.text('pushed:/save-progress'), findsOneWidget);
    });

    testWidgets('renders without throwing regardless of SessionCubit state', (
      tester,
    ) async {
      await tester.pumpScreen(
        const ProfileScreen(),
        session: await signedInSession(),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpScreen(
        const ProfileScreen(),
        brightness: Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
