import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/subscription/pro_badge.dart';

void main() {
  group('proBadge', () {
    test('the server flag alone is enough for anyone', () {
      expect(
        proBadge(serverIsPro: true, isSelf: false, localIsPro: false),
        isTrue,
      );
    });

    test(
      'without the server flag, only your own identity gets the local one',
      () {
        expect(
          proBadge(serverIsPro: false, isSelf: true, localIsPro: true),
          isTrue,
        );
        expect(
          proBadge(serverIsPro: false, isSelf: false, localIsPro: true),
          isFalse,
          reason: 'another player must never borrow this device\'s entitlement',
        );
      },
    );

    test('a free player on every identity stays badgeless', () {
      expect(
        proBadge(serverIsPro: false, isSelf: true, localIsPro: false),
        isFalse,
      );
      expect(
        proBadge(serverIsPro: false, isSelf: false, localIsPro: false),
        isFalse,
      );
    });

    test('a lapsed member with a stale server flag still shows it', () {
      // The server is the truth for other players; the client cannot tell
      // the difference and must not hide a badge the server still has on.
      expect(
        proBadge(serverIsPro: true, isSelf: true, localIsPro: false),
        isTrue,
      );
    });
  });
}
