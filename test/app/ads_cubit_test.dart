import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/core/ads/ad_consent_service.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/ads_config_repository.dart';
import 'package:quizoo/core/ads/ads_pacing_store.dart';
import 'package:quizoo/core/ads/interstitial_ad_service.dart';
import 'package:quizoo/core/ads/interstitial_pacer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAdsConfigRepository extends Mock implements AdsConfigRepository {}

/// Fakes rather than mocktail `Mock`s for the two ad seams, as in
/// `heart_ad_cubit_test.dart`: `show()` is completer-driven so a test can
/// hold an interstitial "on screen".
class _FakeConsentService implements AdConsentService {
  bool canRequestAds = true;
  bool privacyOptionsRequired = false;
  bool throws = false;
  int privacyOptionsShown = 0;

  @override
  Future<bool> gather() async {
    if (throws) throw StateError('consent unavailable');
    return canRequestAds;
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async => privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() async => privacyOptionsShown++;
}

class _FakeInterstitialAdService implements InterstitialAdService {
  @override
  bool isReady = true;

  /// What [show] resolves to, unless [showGate] is holding it open.
  bool showResult = true;
  Completer<bool>? showGate;

  int preloadCount = 0;
  int showCount = 0;
  int disposeCount = 0;

  @override
  Future<void> preload() async => preloadCount++;

  @override
  Future<bool> show() {
    showCount++;
    return showGate?.future ?? Future.value(showResult);
  }

  @override
  Future<void> dispose() async => disposeCount++;
}

void main() {
  late _FakeConsentService consent;
  late _FakeInterstitialAdService interstitial;
  late FakeAdsConfigRepository config;
  late int sdkInitCount;
  late DateTime clock;
  late SharedPreferences preferences;

  /// No grace and no cadence, so the first break is already due.
  const eager = AdsConfig(
    interstitialGraceBreaks: 0,
    interstitialEveryNBreaks: 1,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    consent = _FakeConsentService();
    interstitial = _FakeInterstitialAdService();
    config = FakeAdsConfigRepository();
    sdkInitCount = 0;
    clock = DateTime(2026, 10, 1, 12);
    when(() => config.read()).thenReturn(const AdsConfig());
  });

  AdsCubit build({bool isSupportedPlatform = true}) => AdsCubit(
    consent: consent,
    config: config,
    interstitial: interstitial,
    pacer: InterstitialPacer(AdsPacingStore(preferences), now: () => clock),
    initializeSdk: () async => sdkInitCount++,
    isSupportedPlatform: isSupportedPlatform,
  );

  /// A Cubit already in `AdsReady` with [using] as its config.
  Future<AdsCubit> ready([AdsConfig using = eager]) async {
    when(() => config.read()).thenReturn(using);
    final cubit = build();
    await cubit.initialize();
    return cubit;
  }

  group('AdsCubit.initialize', () {
    test('starts in AdsInitial, with nothing requested', () async {
      final cubit = build();

      expect(cubit.state, const AdsInitial());
      expect(sdkInitCount, 0);
      expect(interstitial.preloadCount, 0);
      expect(
        AdPlacement.values.any(cubit.isPlacementEnabled),
        isFalse,
        reason: 'no placement is on before consent',
      );
      await cubit.close();
    });

    blocTest<AdsCubit, AdsState>(
      'consent granted: starts the SDK, preloads, and is ready',
      setUp: () => consent.privacyOptionsRequired = true,
      build: build,
      act: (cubit) => cubit.initialize(),
      expect: () => const [
        AdsReady(config: AdsConfig(), privacyOptionsRequired: true),
      ],
      verify: (_) {
        expect(sdkInitCount, 1);
        expect(interstitial.preloadCount, 1);
      },
    );

    blocTest<AdsCubit, AdsState>(
      'consent denied: disabled, and the SDK is never started',
      setUp: () => consent.canRequestAds = false,
      build: build,
      act: (cubit) => cubit.initialize(),
      expect: () => const [AdsDisabled()],
      verify: (_) {
        expect(sdkInitCount, 0);
        expect(interstitial.preloadCount, 0);
      },
    );

    blocTest<AdsCubit, AdsState>(
      'the remote master switch off: disabled',
      setUp: () =>
          when(() => config.read()).thenReturn(const AdsConfig(enabled: false)),
      build: build,
      act: (cubit) => cubit.initialize(),
      expect: () => const [AdsDisabled()],
      verify: (_) => expect(sdkInitCount, 0),
    );

    blocTest<AdsCubit, AdsState>(
      'an unsupported platform: disabled without touching any service',
      build: () => build(isSupportedPlatform: false),
      act: (cubit) => cubit.initialize(),
      expect: () => const [AdsDisabled()],
      verify: (_) => verifyNever(() => config.read()),
    );

    blocTest<AdsCubit, AdsState>(
      'a throwing service: disabled, never an error',
      setUp: () => consent.throws = true,
      build: build,
      act: (cubit) => cubit.initialize(),
      expect: () => const [AdsDisabled()],
    );
  });

  group('AdsCubit.isPlacementEnabled', () {
    test('honours the kill list', () async {
      final cubit = await ready(
        const AdsConfig(disabledPlacements: {'home_feed_native'}),
      );

      expect(cubit.isPlacementEnabled(AdPlacement.homeFeedNative), isFalse);
      expect(cubit.isPlacementEnabled(AdPlacement.ranksFeedNative), isTrue);
      await cubit.close();
    });
  });

  group('AdsCubit.showInterstitialIfDue', () {
    test('shows on the due break and not before', () async {
      final cubit = await ready(const AdsConfig());

      // Default config: two grace breaks, then one per two eligible breaks.
      for (var i = 0; i < 3; i++) {
        await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      }
      expect(interstitial.showCount, 0);

      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 1);
      await cubit.close();
    });

    test('completes only once the ad is dismissed', () async {
      final cubit = await ready();
      interstitial.showGate = Completer<bool>();
      var isDone = false;

      final shown = cubit
          .showInterstitialIfDue(AdPlacement.dailyResultBreak)
          .then((_) => isDone = true);
      await Future<void>.delayed(Duration.zero);
      expect(isDone, isFalse);

      interstitial.showGate!.complete(true);
      await shown;
      expect(isDone, isTrue);
      await cubit.close();
    });

    test('a shown ad starts the cooldown', () async {
      final cubit = await ready();

      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 1);

      clock = clock.add(const Duration(seconds: 120));
      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 2);
      await cubit.close();
    });

    test('an ad that failed to show leaves the break owed', () async {
      final cubit = await ready();
      interstitial.showResult = false;
      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);

      interstitial.showResult = true;
      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);

      expect(interstitial.showCount, 2, reason: 'no cooldown was started');
      await cubit.close();
    });

    test('a celebration never shows one', () async {
      final cubit = await ready();

      await cubit.showInterstitialIfDue(
        AdPlacement.levelCompleteBreak,
        isCelebration: true,
      );

      expect(interstitial.showCount, 0);
      await cubit.close();
    });

    test('a rewarded ad holds off the next interstitial', () async {
      final cubit = await ready();
      cubit.noteFullScreenAdShown();

      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 0);

      clock = clock.add(const Duration(seconds: 120));
      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 1);
      await cubit.close();
    });

    test('with no ad loaded it returns at once and fetches one', () async {
      final cubit = await ready();
      interstitial.isReady = false;
      final preloadsBefore = interstitial.preloadCount;

      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);

      expect(interstitial.showCount, 0);
      expect(interstitial.preloadCount, preloadsBefore + 1);
      await cubit.close();
    });

    test('a disabled placement never shows and is not counted', () async {
      final cubit = await ready(
        eager.copyWith(disabledPlacements: {'duel_result_break'}),
      );

      await cubit.showInterstitialIfDue(AdPlacement.duelResultBreak);
      expect(interstitial.showCount, 0);

      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 1);
      await cubit.close();
    });

    test('does nothing when ads are disabled', () async {
      consent.canRequestAds = false;
      final cubit = build();
      await cubit.initialize();

      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);

      expect(interstitial.showCount, 0);
      await cubit.close();
    });
  });

  // Plan 023: the "Remove ads" switch a Quizoo Pro purchase flips.
  group('AdsCubit.setAdFree (plan 023)', () {
    test('disables every placement and every interstitial', () async {
      final cubit = await ready(const AdsConfig());

      expect(cubit.isPlacementEnabled(AdPlacement.homeFeedNative), isTrue);

      cubit.setAdFree(true);
      expect(cubit.isAdFree, isTrue);
      expect(
        cubit.state,
        isA<AdsReady>().having((s) => s.isAdFree, 'isAdFree', isTrue),
      );
      for (final placement in AdPlacement.values) {
        expect(cubit.isPlacementEnabled(placement), isFalse);
      }

      // A break is registered but nothing shows.
      await cubit.showInterstitialIfDue(AdPlacement.levelCompleteBreak);
      expect(interstitial.showCount, 0);
      await cubit.close();
    });

    test('turning it back on restores placements and preloads an ad', () async {
      final cubit = await ready(const AdsConfig());
      final preloadsBefore = interstitial.preloadCount;

      cubit.setAdFree(true);
      cubit.setAdFree(false);
      expect(cubit.isAdFree, isFalse);
      expect(cubit.isPlacementEnabled(AdPlacement.homeFeedNative), isTrue);
      expect(interstitial.preloadCount, preloadsBefore + 1);
      await cubit.close();
    });

    test('ad-free before initialize skips the preload', () async {
      when(() => config.read()).thenReturn(const AdsConfig());
      final cubit = build();
      cubit.setAdFree(true);
      await cubit.initialize();

      expect(interstitial.preloadCount, 0);
      expect(
        cubit.state,
        isA<AdsReady>().having((s) => s.isAdFree, 'isAdFree', isTrue),
      );
      await cubit.close();
    });

    test('an idempotent setAdFree does not re-emit', () async {
      final cubit = await ready(const AdsConfig());
      var emissions = 0;
      final sub = cubit.stream.listen((_) => emissions++);

      cubit.setAdFree(true);
      cubit.setAdFree(true);
      await pumpEventQueue();
      expect(emissions, 1);
      await sub.cancel();
      await cubit.close();
    });
  });

  test('showPrivacyOptions re-opens the consent form', () async {
    final cubit = await ready();

    await cubit.showPrivacyOptions();

    expect(consent.privacyOptionsShown, 1);
    await cubit.close();
  });
}
