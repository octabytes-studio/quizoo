import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/ad_unit_ids.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/theme/app_radius.dart';

/// A loaded AdMob banner or native ad — [ad] is what `AdWidget` renders.
class AdMobLoadedInlineAd implements LoadedInlineAd {
  AdMobLoadedInlineAd({
    required this.ad,
    required this.width,
    required this.height,
  });

  final AdWithView ad;

  @override
  final double width;

  @override
  final double height;

  @override
  void dispose() => unawaited(ad.dispose());
}

/// The real AdMob-backed [InlineAdService].
class AdMobInlineAdService implements InlineAdService {
  @override
  Future<double?> reservedHeight(InlineAdRequest request) async {
    switch (request) {
      case AnchoredBannerRequest(:final widthDp):
        return (await _anchoredSize(widthDp))?.height.toDouble();
      case RectangleBannerRequest() || NativeAdRequest():
        return request.fixedHeight;
    }
  }

  @override
  Future<LoadedInlineAd?> load(InlineAdRequest request) async {
    switch (request) {
      case AnchoredBannerRequest(:final widthDp):
        final size = await _anchoredSize(widthDp);
        if (size == null) return null;
        return _loadBanner(AdUnitIds.anchoredBanner, size);
      case RectangleBannerRequest():
        return _loadBanner(AdUnitIds.rectangleBanner, AdSize.mediumRectangle);
      case NativeAdRequest():
        return _loadNative(request);
    }
  }

  Future<AdSize?> _anchoredSize(int widthDp) async {
    try {
      return await AdSize.getLargeAnchoredAdaptiveBannerAdSize(widthDp);
    } catch (_) {
      return null;
    }
  }

  Future<LoadedInlineAd?> _loadBanner(String adUnitId, AdSize size) {
    final completer = Completer<LoadedInlineAd?>();
    final banner = BannerAd(
      size: size,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (completer.isCompleted) return;
          completer.complete(
            AdMobLoadedInlineAd(
              ad: ad as AdWithView,
              width: size.width.toDouble(),
              height: size.height.toDouble(),
            ),
          );
        },
        onAdFailedToLoad: (ad, error) {
          unawaited(ad.dispose());
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return _dispatch(banner, completer);
  }

  Future<LoadedInlineAd?> _loadNative(NativeAdRequest request) {
    final completer = Completer<LoadedInlineAd?>();
    final palette = request.palette;
    final height = request.fixedHeight;
    final native = NativeAd(
      adUnitId: _nativeAdUnitId(request.placement),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (completer.isCompleted) return;
          completer.complete(
            AdMobLoadedInlineAd(
              ad: ad as AdWithView,
              // A template fills whatever width its slot gives it.
              width: double.infinity,
              height: height,
            ),
          );
        },
        onAdFailedToLoad: (ad, error) {
          unawaited(ad.dispose());
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: switch (request.size) {
          NativeAdSize.small => TemplateType.small,
          NativeAdSize.medium => TemplateType.medium,
        },
        mainBackgroundColor: palette.background,
        cornerRadius: AppRadius.listRow,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: palette.ctaText,
          backgroundColor: palette.ctaBackground,
          style: NativeTemplateFontStyle.bold,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: palette.text,
          backgroundColor: palette.background,
          style: NativeTemplateFontStyle.bold,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: palette.secondaryText,
          backgroundColor: palette.background,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: palette.secondaryText,
          backgroundColor: palette.background,
        ),
      ),
    );
    return _dispatch(native, completer);
  }

  /// Sends the load request; the listener completes [completer] later, from
  /// a separate native callback.
  Future<LoadedInlineAd?> _dispatch(
    AdWithView ad,
    Completer<LoadedInlineAd?> completer,
  ) async {
    try {
      await ad.load();
    } catch (_) {
      unawaited(ad.dispose());
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  /// Feed slots and result-screen slots report to separate ad units, so
  /// AdMob can show fill and eCPM per surface.
  String _nativeAdUnitId(AdPlacement placement) => switch (placement) {
    AdPlacement.homeFeedNative ||
    AdPlacement.ranksFeedNative => AdUnitIds.nativeFeed,
    AdPlacement.levelCompleteNative ||
    AdPlacement.duelResultNative ||
    AdPlacement.dailyResultNative => AdUnitIds.nativeResult,
    AdPlacement.levelCompleteBreak ||
    AdPlacement.duelResultBreak ||
    AdPlacement.dailyResultBreak ||
    AdPlacement.levelMapBanner ||
    AdPlacement.categoryDetailBanner ||
    AdPlacement.statsBanner ||
    AdPlacement.achievementsBanner ||
    AdPlacement.dailyTabRectangle => throw ArgumentError.value(
      placement,
      'placement',
      'is not a native placement',
    ),
  };
}
