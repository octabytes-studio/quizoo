import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/models/player_currency.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';

import '../../support/pump_app.dart';

void main() {
  group('PlayerTopBar', () {
    testWidgets('tapping the avatar invokes onAvatarTap (plan 019)', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpApp(
        PlayerTopBar(
          name: 'Waleed',
          avatarEmoji: '🐼',
          currency: const PlayerCurrency(),
          dayStreak: 3,
          playerLevel: 4,
          onSearchPressed: () {},
          onAvatarTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('🐼'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
