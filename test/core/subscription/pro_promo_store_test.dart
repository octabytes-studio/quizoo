import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';

import '../../support/fake_purchases.dart';

void main() {
  group('ProPromoStore', () {
    test('the Home card shows until it is dismissed', () {
      final store = ProPromoStore(MemoryPreferences());
      expect(store.shouldShowHomeCard, isTrue);
    });

    test('a dismissal hides the card for seven days', () {
      var now = DateTime(2026, 10, 1);
      final store = ProPromoStore(MemoryPreferences(), clock: () => now);

      store.dismissHomeCard();
      expect(store.shouldShowHomeCard, isFalse);

      now = now.add(const Duration(days: 6));
      expect(
        store.shouldShowHomeCard,
        isFalse,
        reason: 'still inside the week',
      );

      now = now.add(const Duration(days: 2));
      expect(store.shouldShowHomeCard, isTrue, reason: 'the window has passed');
    });

    test('interstitials counted from zero', () {
      final store = ProPromoStore(MemoryPreferences());
      expect(store.interstitialsSeen, 0);
      store.noteInterstitialSeen();
      store.noteInterstitialSeen();
      expect(store.interstitialsSeen, 2);
    });

    test('the ad-free offer is shown once ever', () {
      final store = ProPromoStore(MemoryPreferences());
      expect(store.adFreeOfferShown, isFalse);
      store.markAdFreeOfferShown();
      expect(store.adFreeOfferShown, isTrue);
    });

    test('a second store instance on the same preferences sees the writes', () {
      final preferences = MemoryPreferences();
      ProPromoStore(preferences).markAdFreeOfferShown();
      expect(ProPromoStore(preferences).adFreeOfferShown, isTrue);
    });
  });
}
