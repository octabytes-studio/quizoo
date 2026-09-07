import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/settings/presentation/screens/delete_account_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';

void main() {
  useMockApiFailureRate();

  Future<AppLocalizations> pump(WidgetTester tester) async {
    await tester.pumpScreen(const DeleteAccountScreen());
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(DeleteAccountScreen)),
    );
  }

  ChunkyButton deleteButton(WidgetTester tester, AppLocalizations l10n) =>
      tester.widget<ChunkyButton>(
        find.widgetWithText(ChunkyButton, l10n.deleteAccountDelete),
      );

  group(
    'S-52 Delete permanently — enabled only on an exact username match',
    () {
      testWidgets('starts disabled with nothing typed', (tester) async {
        final l10n = await pump(tester);
        expect(deleteButton(tester, l10n).onPressed, isNull);
      });

      testWidgets('stays disabled on a wrong-case near miss', (tester) async {
        final l10n = await pump(tester);

        // `ProfileApi`'s fixture username is `waleed_pk`.
        await tester.enterText(find.byType(TextField), 'Waleed_PK');
        await tester.pumpAndSettle();

        expect(deleteButton(tester, l10n).onPressed, isNull);
      });

      testWidgets('stays disabled on a partial/trimmed near miss', (
        tester,
      ) async {
        final l10n = await pump(tester);

        await tester.enterText(find.byType(TextField), 'waleed_p');
        await tester.pumpAndSettle();

        expect(deleteButton(tester, l10n).onPressed, isNull);
      });

      testWidgets('enables only once the typed text matches exactly', (
        tester,
      ) async {
        final l10n = await pump(tester);

        await tester.enterText(find.byType(TextField), 'waleed_pk');
        await tester.pumpAndSettle();

        expect(deleteButton(tester, l10n).onPressed, isNotNull);
      });
    },
  );
}
