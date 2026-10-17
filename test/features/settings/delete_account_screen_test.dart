import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quizoo/features/settings/presentation/screens/delete_account_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// A complete, loaded S-32 summary — the shape the screen renders once
/// `ProfileCubit` has real numbers to quote in `deleteAccountBody`.
const _summary = ProfileSummary(
  username: 'Waleed',
  avatarEmoji: '🐼',
  cityLabel: '🇵🇰 Islamabad',
  joinedLabel: 'Joined Mar 2026',
  leagueEmoji: '🏅',
  leagueName: 'Gold',
  dayStreak: 12,
  playerLevel: 7,
  rankTitle: 'Curious Mind',
  xpIntoLevel: 120,
  xpToNextLevel: 500,
  totalPoints: 12400,
  totalLevels: 42,
  accuracyPercent: 78,
  badgeCount: 5,
  recentBadges: [],
  bestCategories: [],
);

void main() {
  late _MockAuthRepository authRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
  });

  SessionCubit session({bool signedIn = true}) {
    final cubit = SessionCubit(authRepository);
    if (signedIn) {
      cubit.emit(
        const SessionSignedIn(
          AuthUser(
            id: 'user_google',
            displayName: 'Waleed',
            provider: AuthProvider.google,
          ),
        ),
      );
    }
    return cubit;
  }

  ProfileCubit loadedProfile() =>
      ProfileCubit(_MockProfileRepository())
        ..emit(const ProfileLoaded(_summary));

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DeleteAccountScreen)));

  ChunkyButton dangerButton(WidgetTester tester, AppLocalizations l10n) =>
      tester.widget<ChunkyButton>(
        find.widgetWithText(ChunkyButton, l10n.deleteAccountDelete),
      );

  group('DeleteAccountScreen', () {
    testWidgets('a guest sees the informational guard, never the destructive '
        'flow', (tester) async {
      await tester.pumpScreen(
        const DeleteAccountScreen(),
        session: session(signedIn: false),
      );
      await tester.pump();

      final l10n = l10nOf(tester);
      expect(find.text(l10n.deleteAccountGuestTitle), findsOneWidget);
      expect(find.text(l10n.deleteAccountGuestBody), findsOneWidget);
      expect(find.text(l10n.deleteAccountDelete), findsNothing);
    });

    testWidgets('the typed username gates the Delete permanently button', (
      tester,
    ) async {
      await tester.pumpScreen(
        DeleteAccountScreen(profileCubit: loadedProfile()),
        session: session(),
      );
      await tester.pump();

      final l10n = l10nOf(tester);
      expect(dangerButton(tester, l10n).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Waleed');
      await tester.pump();
      expect(dangerButton(tester, l10n).onPressed, isNotNull);
    });

    testWidgets('a successful deletion shows the real "Account deleted" '
        'snackbar and drops the session to guest', (tester) async {
      when(() => authRepository.deleteAccount()).thenAnswer((_) async {});
      final sessionCubit = session();

      await tester.pumpScreen(
        DeleteAccountScreen(profileCubit: loadedProfile()),
        session: sessionCubit,
      );
      await tester.pump();

      final l10n = l10nOf(tester);
      await tester.enterText(find.byType(TextField), 'Waleed');
      await tester.pump();
      await tester.tap(find.text(l10n.deleteAccountDelete));
      await tester.pumpAndSettle();

      expect(find.text(l10n.deleteAccountDone), findsOneWidget);
      expect(sessionCubit.state, isA<SessionGuest>());
    });

    testWidgets('a failed deletion shows the error and leaves the screen '
        '(and the account) open', (tester) async {
      when(
        () => authRepository.deleteAccount(),
      ).thenThrow(const ApiException.network());
      final sessionCubit = session();

      await tester.pumpScreen(
        DeleteAccountScreen(profileCubit: loadedProfile()),
        session: sessionCubit,
      );
      await tester.pump();

      final l10n = l10nOf(tester);
      await tester.enterText(find.byType(TextField), 'Waleed');
      await tester.pump();
      await tester.tap(find.text(l10n.deleteAccountDelete));
      await tester.pumpAndSettle();

      expect(find.text(l10n.deleteAccountError), findsOneWidget);
      expect(find.text(l10n.deleteAccountDelete), findsOneWidget);
      expect(sessionCubit.state, isA<SessionSignedIn>());
    });
  });
}
