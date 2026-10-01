import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/settings/presentation/screens/privacy_settings_screen.dart';

import '../../support/fake_ads.dart';
import '../../support/pump_screen.dart';

void main() {
  group('PrivacySettingsScreen "Ad privacy choices" (plan 022)', () {
    testWidgets('is offered when Google requires it, and opens the form', (
      tester,
    ) async {
      final ads = FakeAdsCubit.ready(privacyOptionsRequired: true);
      await tester.pumpScreen(const PrivacySettingsScreen(), ads: ads);

      await tester.tap(find.text('Ad privacy choices'));
      await tester.pump();

      expect(ads.privacyOptionsShown, 1);
    });

    testWidgets('is absent when Google does not require it', (tester) async {
      await tester.pumpScreen(
        const PrivacySettingsScreen(),
        ads: FakeAdsCubit.ready(),
      );

      expect(find.text('Ad privacy choices'), findsNothing);
    });

    testWidgets('is absent while ads are disabled', (tester) async {
      await tester.pumpScreen(const PrivacySettingsScreen());

      expect(find.text('Ad privacy choices'), findsNothing);
    });
  });
}
