import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/ads_pacing_store.dart';
import 'package:quizoo/core/ads/interstitial_pacer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AdsPacingStore store;
  late DateTime clock;
  late InterstitialPacer pacer;

  const config = AdsConfig();

  /// A pacer whose install is already past the grace period.
  Future<void> build({int lifetimeBreaks = 0}) async {
    SharedPreferences.setMockInitialValues({
      'ads.lifetimeBreaks': lifetimeBreaks,
    });
    store = AdsPacingStore(await SharedPreferences.getInstance());
    clock = DateTime(2026, 10, 1, 12);
    pacer = InterstitialPacer(store, now: () => clock);
  }

  bool atBreak({
    AdsConfig using = config,
    bool isCelebration = false,
    bool isAdReady = true,
  }) => pacer.registerBreak(
    using,
    isCelebration: isCelebration,
    isAdReady: isAdReady,
  );

  void advance(Duration by) => clock = clock.add(by);

  group('InterstitialPacer', () {
    test('grace: the first breaks after install never show one', () async {
      await build();

      expect(atBreak(), isFalse);
      expect(atBreak(), isFalse);
      expect(store.lifetimeBreaks, 2);
    });

    test('cadence: after grace, one per two eligible breaks', () async {
      await build();
      atBreak();
      atBreak();

      expect(atBreak(), isFalse, reason: 'first eligible break');
      expect(atBreak(), isTrue, reason: 'second eligible break');
      pacer.noteInterstitialShown();
      advance(const Duration(minutes: 5));

      expect(atBreak(), isFalse);
      expect(atBreak(), isTrue);
    });

    test('grace is counted across launches, not per process', () async {
      await build(lifetimeBreaks: 10);

      expect(atBreak(), isFalse);
      expect(atBreak(), isTrue);
    });

    test('cooldown: nothing within the minimum gap of the last ad', () async {
      await build(lifetimeBreaks: 10);
      atBreak();
      expect(atBreak(), isTrue);
      pacer.noteInterstitialShown();

      advance(const Duration(seconds: 60));
      atBreak();
      expect(atBreak(), isFalse, reason: 'due by cadence, but only 60s on');

      advance(const Duration(seconds: 60));
      expect(atBreak(), isTrue, reason: 'still owed once the gap has passed');
    });

    test('a rewarded ad restarts the cooldown and the cadence', () async {
      await build(lifetimeBreaks: 10);
      atBreak();
      pacer.noteFullScreenAdShown();

      expect(atBreak(), isFalse, reason: 'cadence was reset');
      expect(atBreak(), isFalse, reason: 'inside the cooldown');

      advance(const Duration(seconds: 120));
      expect(atBreak(), isTrue);
    });

    test('session cap: no more than the cap in one process', () async {
      await build(lifetimeBreaks: 10);
      const capped = AdsConfig(
        interstitialEveryNBreaks: 1,
        interstitialMinGapSeconds: 0,
        interstitialSessionCap: 2,
      );

      expect(atBreak(using: capped), isTrue);
      pacer.noteInterstitialShown();
      expect(atBreak(using: capped), isTrue);
      pacer.noteInterstitialShown();
      expect(atBreak(using: capped), isFalse);
    });

    test('a rewarded ad does not use up the session cap', () async {
      await build(lifetimeBreaks: 10);
      const capped = AdsConfig(
        interstitialEveryNBreaks: 1,
        interstitialMinGapSeconds: 0,
        interstitialSessionCap: 1,
      );
      pacer.noteFullScreenAdShown();

      expect(atBreak(using: capped), isTrue);
    });

    test(
      'a celebration never shows, but still counts toward cadence',
      () async {
        await build(lifetimeBreaks: 10);

        expect(atBreak(isCelebration: true), isFalse);
        expect(
          atBreak(isCelebration: true),
          isFalse,
          reason: 'due, but skipped',
        );
        expect(atBreak(), isTrue, reason: 'the skipped break stayed owed');
      },
    );

    test('no ad ready: the break stays owed to the next one', () async {
      await build(lifetimeBreaks: 10);
      atBreak();

      expect(atBreak(isAdReady: false), isFalse);
      expect(atBreak(), isTrue);
    });
  });
}
