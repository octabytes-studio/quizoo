import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/auth/presentation/widgets/profile_field.dart';

import '../../support/pump_app.dart';

void main() {
  group('ProfileField.enabled', () {
    testWidgets('disabled renders a non-interactive TextField and never '
        'invokes onBlur', (tester) async {
      final controller = TextEditingController(text: 'waleed_pk');
      var blurCount = 0;

      await tester.pumpApp(
        ProfileField(
          label: 'USERNAME',
          controller: controller,
          enabled: false,
          onBlur: () => blurCount++,
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Attempting to focus a disabled field never arms the blur callback.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump();
      expect(blurCount, 0);
    });

    testWidgets('enabled (default) renders an interactive TextField', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'waleed_pk');

      await tester.pumpApp(
        ProfileField(label: 'USERNAME', controller: controller, onBlur: () {}),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isTrue);
    });
  });
}
