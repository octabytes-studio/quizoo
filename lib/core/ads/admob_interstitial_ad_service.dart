import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/ad_unit_ids.dart';
import 'package:quizoo/core/ads/interstitial_ad_service.dart';

/// The real AdMob-backed [InterstitialAdService].
///
/// Holds at most one loaded ad. After it is dismissed (or fails to show) the
/// next one is preloaded straight away, so a break never has to wait for the
/// network.
class AdMobInterstitialAdService implements InterstitialAdService {
  AdMobInterstitialAdService({required this._isMuted, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Read just before showing, so the app's own sound toggle is respected.
  final bool Function() _isMuted;
  final DateTime Function() _now;

  InterstitialAd? _ad;
  DateTime? _loadedAt;
  bool _isLoading = false;

  @override
  bool get isReady {
    final loadedAt = _loadedAt;
    return _ad != null &&
        loadedAt != null &&
        _now().difference(loadedAt) < adFreshnessWindow;
  }

  @override
  Future<void> preload() async {
    if (_isLoading || isReady) return;
    _discard();
    _isLoading = true;
    try {
      // Only dispatches the load request — the callbacks fire later, from a
      // separate native callback.
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loadedAt = _now();
            _isLoading = false;
          },
          onAdFailedToLoad: (error) => _isLoading = false,
        ),
      );
    } catch (_) {
      _isLoading = false;
    }
  }

  @override
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null || !isReady) return false;
    _ad = null;
    _loadedAt = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        unawaited(preload());
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(true);
        unawaited(preload());
      },
    );

    try {
      await MobileAds.instance.setAppMuted(_isMuted());
      await ad.show();
      return await completer.future;
    } catch (_) {
      ad.dispose();
      unawaited(preload());
      return false;
    }
  }

  @override
  Future<void> dispose() async => _discard();

  void _discard() {
    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
  }
}
