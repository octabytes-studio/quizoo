import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/subscription/pro_perks.dart';

void main() {
  group('ProPerks', () {
    test('a free player gets one of each power-up and no revive', () {
      const perks = ProPerks.free();
      expect(perks.fiftyFifty, 1);
      expect(perks.addTime, 1);
      expect(perks.freeRevives, 0);
      expect(perks.livesPerLevel, 3);
    });

    test('a Pro member gets doubled power-ups and one free revive', () {
      const perks = ProPerks.pro();
      expect(perks.fiftyFifty, 2);
      expect(perks.addTime, 2);
      expect(perks.freeRevives, 1);
      // The extra life comes from the revive, not a bigger starting stack.
      expect(perks.livesPerLevel, 3);
    });

    test('ProPerks.of picks the right one', () {
      expect(ProPerks.of(isPro: false), const ProPerks.free());
      expect(ProPerks.of(isPro: true), const ProPerks.pro());
    });

    test('the two never share values, so a copy-paste bug is visible', () {
      expect(ProPerks.of(isPro: true) == ProPerks.of(isPro: false), isFalse);
    });
  });
}
