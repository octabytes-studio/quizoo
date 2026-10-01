import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/content_language_scope.dart';

import '../../support/pump_app.dart';

void main() {
  group('ContentLanguageScope', () {
    Future<void> pumpScope(
      WidgetTester tester, {
      required String languageCode,
      required Locale uiLocale,
    }) => tester.pumpApp(
      ContentLanguageScope(
        languageCode: languageCode,
        child: AnswerOption(
          label: 'option',
          optionKey: 'A',
          state: AnswerOptionState.rest,
          onPressed: () {},
        ),
      ),
      locale: uiLocale,
    );

    TextDirection directionInside(WidgetTester tester) =>
        Directionality.of(tester.element(find.byType(AnswerOption)));

    String? bodyFamilyInside(WidgetTester tester) => Theme.of(
      tester.element(find.byType(AnswerOption)),
    ).textTheme.bodyLarge!.fontFamily;

    testWidgets('lays an Urdu question out RTL in Nastaliq under an English '
        'UI', (tester) async {
      await pumpScope(tester, languageCode: 'ur', uiLocale: const Locale('en'));

      expect(directionInside(tester), TextDirection.rtl);
      expect(bodyFamilyInside(tester), AppTypography.urdu);
    });

    testWidgets('lays an Arabic question out RTL', (tester) async {
      await pumpScope(tester, languageCode: 'ar', uiLocale: const Locale('en'));

      expect(directionInside(tester), TextDirection.rtl);
    });

    testWidgets('keeps an English question LTR in Latin type under an Urdu '
        'UI', (tester) async {
      await pumpScope(tester, languageCode: 'en', uiLocale: const Locale('ur'));

      expect(directionInside(tester), TextDirection.ltr);
      expect(bodyFamilyInside(tester), AppTypography.body);
    });

    testWidgets('leaves an LTR question under an English UI as it was', (
      tester,
    ) async {
      await pumpScope(tester, languageCode: 'hi', uiLocale: const Locale('en'));

      expect(directionInside(tester), TextDirection.ltr);
      expect(bodyFamilyInside(tester), AppTypography.body);
    });
  });
}
