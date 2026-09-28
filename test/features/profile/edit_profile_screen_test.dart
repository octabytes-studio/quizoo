import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

/// `EditProfileScreen` constructs a real `ProfileApi(supabase)` inline, the
/// same DI-less pattern `ProfileScreen`/`HomeScreen` use (see those files'
/// own test suites) — `test/flutter_test_config.dart` never establishes a
/// Supabase session, so `fetchSummary()` always fails `unauthorized` here,
/// landing on the `ProfileError` branch. That exercises the loading/error
/// state switch; the `ProfileLoaded` form (guest vs. signed-in field
/// enablement) has no injection point through the real screen and belongs to
/// a widget test with its own seeded `ProfileCubit`, matching
/// `ProfileScreen`'s identical precedent.
void main() {
  group('EditProfileScreen', () {
    testWidgets('renders the very first frame without throwing', (
      tester,
    ) async {
      await tester.pumpScreen(const EditProfileScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('a failed fetch offers a way out, not a dead end', (
      tester,
    ) async {
      await tester.pumpScreen(const EditProfileScreen());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ErrorStateView), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(EditProfileScreen)),
      );
      expect(find.text(l10n.commonRetry), findsOneWidget);
    });

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpScreen(
        const EditProfileScreen(),
        brightness: Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
