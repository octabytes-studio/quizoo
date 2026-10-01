import 'package:flutter/foundation.dart';

/// Every AdMob ad unit id in the app, declared once.
///
/// No other file writes an ad unit id — each ad class reads its id from here,
/// the same way no feature file writes a route path (see `AppRoutes`).
///
/// **All values are currently Google's public test ad units**, which always
/// fill and never earn. Before release, replace each constant below with the
/// real ad unit id from admob.google.com — this file is the only Dart file
/// that changes.
///
/// The two AdMob *App* IDs are not here: the SDK reads them natively at
/// launch, so they live in `ios/Runner/Info.plist`
/// (`GADApplicationIdentifier`) and `android/app/src/main/AndroidManifest.xml`
/// (`com.google.android.gms.ads.APPLICATION_ID`) and must be swapped there.
abstract final class AdUnitIds {
  // ------------------------------------------------------------ Android
  static const String _androidAnchoredBanner =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _androidRectangleBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidNativeFeed =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _androidNativeResult =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _androidRewardedHeart =
      'ca-app-pub-3940256099942544/5224354917';

  // ---------------------------------------------------------------- iOS
  static const String _iosAnchoredBanner =
      'ca-app-pub-3940256099942544/2435281174';
  static const String _iosRectangleBanner =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosNativeFeed = 'ca-app-pub-3940256099942544/3986624511';
  static const String _iosNativeResult =
      'ca-app-pub-3940256099942544/3986624511';
  static const String _iosRewardedHeart =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Anchored adaptive banner — the strip pinned to a screen's bottom edge.
  static String get anchoredBanner =>
      _isAndroid ? _androidAnchoredBanner : _iosAnchoredBanner;

  /// Fixed-size 300×250 medium rectangle banner.
  static String get rectangleBanner =>
      _isAndroid ? _androidRectangleBanner : _iosRectangleBanner;

  /// Full-screen interstitial shown at a break between runs.
  static String get interstitial =>
      _isAndroid ? _androidInterstitial : _iosInterstitial;

  /// Native ad inside a scrolling feed (Home, Ranks).
  static String get nativeFeed =>
      _isAndroid ? _androidNativeFeed : _iosNativeFeed;

  /// Native ad on a result screen (level complete, duel, daily).
  static String get nativeResult =>
      _isAndroid ? _androidNativeResult : _iosNativeResult;

  /// S-19's rewarded "watch an ad for 1 ❤️".
  static String get rewardedHeart =>
      _isAndroid ? _androidRewardedHeart : _iosRewardedHeart;
}
