import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
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

    testWidgets(
      'a guest becoming signed in reloads, so a fresh sign-up reflects '
      'here without an app restart',
      (tester) async {
        final api = _FakeAuthApi();
        when(
          () => api.authStateChanges,
        ).thenAnswer((_) => const Stream.empty());
        SharedPreferences.setMockInitialValues({});
        final session = SessionCubit(
          AuthRepository(api, await SharedPreferences.getInstance()),
        );

        await tester.pumpScreen(const ProfileScreen(), session: session);
        await tester.pump(const Duration(seconds: 2));

        // `ProfileCubit` is provided inside `ProfileScreen`, below its own
        // element, so it's read off a descendant — `EmptyStateView` is
        // `_ProfileSignInRequired`'s own content, well below the provider.
        // The guest fetch has already failed unauthorized and settled by
        // now.
        final cubit = tester
            .element(find.byType(EmptyStateView))
            .read<ProfileCubit>();
        expect(cubit.state, isA<ProfileError>());

        // `ProfileApi`'s "not signed in" failure throws before any real
        // network wait, so a reload's `ProfileLoading` resolves back to a
        // structurally-identical `ProfileError` within the same pump — too
        // fast to observe as a rendered frame or a distinct `==` value.
        // Identity survives that: a fresh `load()` always constructs a new
        // `ApiException`/`ProfileError`, so a *different* object proves the
        // listener actually reloaded rather than the screen just keeping
        // its stale pre-signup state.
        final beforeState = cubit.state;

        session.emit(
          const SessionSignedIn(
            AuthUser(
              id: 'user_google',
              displayName: 'Waleed',
              provider: AuthProvider.google,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        expect(identical(cubit.state, beforeState), isFalse);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpScreen(
        const ProfileScreen(),
        brightness: Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      "tapping the header's own avatar opens Edit Profile (plan 019)",
      (tester) async {
        await tester.pumpScreen(const ProfileScreen());
        await tester.pump(const Duration(seconds: 2));

        // The header's own 🐼 avatar glyph is unique on this screen (the
        // sign-in-required state's `EmptyStateView` uses 🔐).
        await tester.tap(
          find.ancestor(
            of: find.text('🐼'),
            matching: find.byType(GestureDetector),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('pushed:/you/edit-profile'), findsOneWidget);
      },
    );

    testWidgets("the settings gear's Semantics button/label survive the plated "
        'visual change (plan 019)', (tester) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pump(const Duration(seconds: 2));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileScreen)),
      );
      await tester.tap(find.bySemanticsLabel(l10n.profileSettings));
      await tester.pumpAndSettle();

      expect(find.text('pushed:/settings'), findsOneWidget);
    });
  });
}
