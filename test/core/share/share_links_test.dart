import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/share/share_links.dart';
import 'package:quizoo/l10n/app_localizations_en.dart';

void main() {
  group('ShareLinks URIs', () {
    test('whatsAppUri targets wa.me with the text as a query parameter', () {
      final uri = ShareLinks.whatsAppUri('Level 6 done — 1840 points! 🎉');

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.queryParameters['text'], 'Level 6 done — 1840 points! 🎉');
    });

    test('xUri targets x.com\'s intent/post endpoint', () {
      final uri = ShareLinks.xUri('Level 6 done');

      expect(uri.scheme, 'https');
      expect(uri.host, 'x.com');
      expect(uri.path, '/intent/post');
      expect(uri.queryParameters['text'], 'Level 6 done');
    });
  });

  group('share-text builders', () {
    // The generated English delegate, used directly — no widget tree needed
    // for pure string formatting.
    final l10n = AppLocalizationsEn();

    test('shareResultText names the topic, level and score, no answers', () {
      final text = l10n.shareResultText(6, 'Football', 1840);

      expect(text, contains('Football'));
      expect(text, contains('6'));
      expect(text, contains('1840'));
    });

    test('shareDailyText carries the tally and the streak', () {
      final text = l10n.shareDailyText(9, 10, 12);

      expect(text, contains('9/10'));
      expect(text, contains('12'));
    });

    test('shareBadgeText names the badge', () {
      expect(l10n.shareBadgeText('Perfect Week'), contains('Perfect Week'));
    });

    test('shareMasteryText names the topic', () {
      expect(l10n.shareMasteryText('Football'), contains('Football'));
    });
  });
}
