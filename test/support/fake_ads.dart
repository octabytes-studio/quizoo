import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';

/// A stand-in for the app-root [AdsCubit] that never touches the ad SDK, UMP
/// or Remote Config.
///
/// Starts in [AdsDisabled] by default, so a screen test renders exactly as it
/// did before ads existed. [FakeAdsCubit.ready] turns every placement on.
///
/// A fake rather than a mocktail `Mock`: [showInterstitialIfDue] has to be
/// awaited by the screen under test, and [interstitialGate] lets a test hold
/// that future open to assert that navigation waits for it.
class FakeAdsCubit extends Cubit<AdsState> implements AdsCubit {
  FakeAdsCubit([super.initialState = const AdsDisabled()]);

  FakeAdsCubit.ready({
    AdsConfig config = const AdsConfig(),
    bool privacyOptionsRequired = false,
  }) : super(
         AdsReady(
           config: config,
           privacyOptionsRequired: privacyOptionsRequired,
         ),
       );

  /// Every [showInterstitialIfDue] call, in order.
  final List<({AdPlacement placement, bool isCelebration})> breaks = [];

  /// When set, [showInterstitialIfDue] completes only once this does — the
  /// stand-in for an interstitial that is on screen.
  Completer<void>? interstitialGate;

  int fullScreenAdsNoted = 0;
  int privacyOptionsShown = 0;

  /// Whether the fake "shows" an interstitial. A test that wants `runAdBreak`
  /// to count one sets this true (the default), or false to model a break
  /// where the pacing said no.
  bool showsInterstitial = true;

  /// Set by [setAdFree]; mirrors `AdsCubit`'s behaviour so an ad-free
  /// player's screen renders with no slots at all (plan 023).
  @override
  bool isAdFree = false;

  @override
  Future<void> initialize() async {}

  @override
  void setAdFree(bool value) {
    isAdFree = value;
    final current = state;
    if (current is AdsReady) {
      emit(
        AdsReady(
          config: current.config,
          privacyOptionsRequired: current.privacyOptionsRequired,
          isAdFree: value,
        ),
      );
    }
  }

  @override
  bool isPlacementEnabled(AdPlacement placement) => switch (state) {
    AdsReady(:final config, :final isAdFree) =>
      !isAdFree && !config.disabledPlacements.contains(placement.id),
    AdsInitial() || AdsDisabled() => false,
  };

  @override
  Future<bool> showInterstitialIfDue(
    AdPlacement placement, {
    bool isCelebration = false,
  }) async {
    breaks.add((placement: placement, isCelebration: isCelebration));
    await interstitialGate?.future;
    if (!showsInterstitial || isAdFree) return false;
    return true;
  }

  @override
  void noteFullScreenAdShown() => fullScreenAdsNoted++;

  @override
  Future<void> showPrivacyOptions() async => privacyOptionsShown++;
}

/// A loaded ad with no platform view behind it — `InlineAdView` renders it as
/// an empty box of this size.
class FakeLoadedInlineAd implements LoadedInlineAd {
  FakeLoadedInlineAd({this.width = double.infinity, this.height = 100});

  @override
  final double width;

  @override
  final double height;

  bool isDisposed = false;

  @override
  void dispose() => isDisposed = true;
}

/// A stand-in for the AdMob-backed [InlineAdService].
///
/// By default every load fails at once (no fill), and nothing is left
/// pending — so `pumpAndSettle` never hangs on it. Set [fills] to have loads
/// succeed, or [loadGate] to hold one open.
class FakeInlineAdService implements InlineAdService {
  FakeInlineAdService({this.fills = false, this.anchoredHeight = 60});

  /// Whether a load returns an ad.
  bool fills;

  /// The adaptive height reported for an anchored banner; null means the
  /// SDK could not size it.
  double? anchoredHeight;

  /// When set, [load] completes only once this does.
  Completer<void>? loadGate;

  final List<InlineAdRequest> requests = [];
  final List<FakeLoadedInlineAd> loaded = [];

  @override
  Future<double?> reservedHeight(InlineAdRequest request) async =>
      request.fixedHeight ?? anchoredHeight;

  @override
  Future<LoadedInlineAd?> load(InlineAdRequest request) async {
    requests.add(request);
    await loadGate?.future;
    if (!fills) return null;
    final ad = FakeLoadedInlineAd(
      width: switch (request) {
        AnchoredBannerRequest(:final widthDp) => widthDp.toDouble(),
        RectangleBannerRequest() => 300,
        NativeAdRequest() => double.infinity,
      },
      height: request.fixedHeight ?? anchoredHeight ?? 0,
    );
    loaded.add(ad);
    return ad;
  }
}
