import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/settings/presentation/screens/force_update_screen.dart';

import '../../support/pump_screen.dart';

void main() {
  testWidgets(
    'S-50 is the one screen in the app that blocks back navigation — no '
    'back button, no system-back, no gesture-dismiss (plan 004, Edge cases)',
    (tester) async {
      await tester.pumpScreen(const ForceUpdateScreen());
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);

      // A system back gesture must not pop this route either.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ForceUpdateScreen), findsOneWidget);
    },
  );
}
