import 'package:flutter/foundation.dart';

/// Every AdMob ad unit id in the app, declared once.
///
/// No other file writes an ad unit id — each ad class reads its id from here,
/// the same way no feature file writes a route path (see `AppRoutes`).
///
/// Both sets live here: the app's **real** ids (AdMob account
/// `ca-app-pub-2195537972404209`) and Google's public **test** ids. Which set
/// a build serves is chosen by [showTestAds] (the `SHOW_TEST_ADS`
/// dart-define), so nothing here changes between a debug run and a release
/// build except the value of that one key.
///
/// The two AdMob *App* IDs are not here: the SDK reads them natively at
/// launch, so they live in `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
/// and `android/app/src/main/AndroidManifest.xml`
/// (`com.google.android.gms.ads.APPLICATION_ID`). They are always the real
/// ones — Google's test *ad units* are valid under a real App ID, so the
/// [showTestAds] switch above is enough and the native files never need to
/// change between test and real runs.
///
/// Two units share one real id because the AdMob account defines a single
/// banner unit and a single native unit: [anchoredBanner] and
/// [rectangleBanner] both map to it, as do [nativeFeed] and [nativeResult].
/// Google's test ids do distinguish the two banner sizes, so they stay
/// separate in the test set.
abstract final class AdUnitIds {
  /// Whether this build serves Google's public test ad units.
  ///
  /// Set with `--dart-define=SHOW_TEST_ADS=true|false` (carried by
  /// `dart_define.json`). `true` forces test ads in every build mode; `false`
  /// forces the real ids in every mode. When the key is absent it defaults to
  /// test ads in debug and profile and the real ids in release
  /// (`!kReleaseMode`), so a bare `flutter run` never serves real impressions.
  ///
  /// `scripts/build.sh` always appends `--dart-define=SHOW_TEST_ADS=false`, so
  /// a release/profile build can never ship test ads even though
  /// `dart_define.json` sets the key to `true`. A release build that bypasses
  /// the script and passes the file directly must set it to `false` itself.
  static const bool showTestAds = bool.fromEnvironment(
    'SHOW_TEST_ADS',
    defaultValue: !kReleaseMode,
  );

  /// True when the real ids should be served.
  static bool get _useReal => !showTestAds;

  // ------------------------------------------------------- Real (production)
  // AdMob account ca-app-pub-2195537972404209.
  static const String _realAndroidBanner =
      'ca-app-pub-2195537972404209/1472124994';
  static const String _realIosBanner = 'ca-app-pub-2195537972404209/8677406609';
  static const String _realAndroidInterstitial =
      'ca-app-pub-2195537972404209/5080197512';
  static const String _realIosInterstitial =
      'ca-app-pub-2195537972404209/2709010039';
  static const String _realAndroidRewardedInterstitial =
      'ca-app-pub-2195537972404209/1140952508';
  static const String _realIosRewardedInterstitial =
      'ca-app-pub-2195537972404209/1395928368';
  static const String _realAndroidRewarded =
      'ca-app-pub-2195537972404209/2391199850';
  static const String _realIosRewarded =
      'ca-app-pub-2195537972404209/6185395627';
  static const String _realAndroidNative =
      'ca-app-pub-2195537972404209/1280553301';
  static const String _realIosNative = 'ca-app-pub-2195537972404209/3008567949';
  static const String _realAndroidAppOpen =
      'ca-app-pub-2195537972404209/7466687706';
  static const String _realIosAppOpen =
      'ca-app-pub-2195537972404209/2246150618';

  // ------------------------------------------- Test (Google's public samples)
  static const String _androidTestAnchoredBanner =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _androidTestRectangleBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidTestInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidTestRewardedInterstitial =
      'ca-app-pub-3940256099942544/5354046379';
  static const String _androidTestRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _androidTestNative =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _androidTestAppOpen =
      'ca-app-pub-3940256099942544/9257395921';

  static const String _iosTestAnchoredBanner =
      'ca-app-pub-3940256099942544/2435281174';
  static const String _iosTestRectangleBanner =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosTestInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosTestRewardedInterstitial =
      'ca-app-pub-3940256099942544/6978759866';
  static const String _iosTestRewarded =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _iosTestNative = 'ca-app-pub-3940256099942544/3986624511';
  static const String _iosTestAppOpen =
      'ca-app-pub-3940256099942544/5575463023';

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Picks the real or test id for this platform from the four candidates.
  static String _pick({
    required String realAndroid,
    required String realIos,
    required String testAndroid,
    required String testIos,
  }) {
    if (_useReal) return _isAndroid ? realAndroid : realIos;
    return _isAndroid ? testAndroid : testIos;
  }

  /// Anchored adaptive banner — the strip pinned to a screen's bottom edge.
  static String get anchoredBanner => _pick(
    realAndroid: _realAndroidBanner,
    realIos: _realIosBanner,
    testAndroid: _androidTestAnchoredBanner,
    testIos: _iosTestAnchoredBanner,
  );

  /// Fixed-size 300×250 medium rectangle banner.
  static String get rectangleBanner => _pick(
    realAndroid: _realAndroidBanner,
    realIos: _realIosBanner,
    testAndroid: _androidTestRectangleBanner,
    testIos: _iosTestRectangleBanner,
  );

  /// Full-screen interstitial shown at a break between runs.
  static String get interstitial => _pick(
    realAndroid: _realAndroidInterstitial,
    realIos: _realIosInterstitial,
    testAndroid: _androidTestInterstitial,
    testIos: _iosTestInterstitial,
  );

  /// Full-screen rewarded interstitial — reserved, no service uses it yet.
  static String get rewardedInterstitial => _pick(
    realAndroid: _realAndroidRewardedInterstitial,
    realIos: _realIosRewardedInterstitial,
    testAndroid: _androidTestRewardedInterstitial,
    testIos: _iosTestRewardedInterstitial,
  );

  /// The rewarded "watch an ad for 1 ❤️" ad (S-19).
  static String get rewardedHeart => _pick(
    realAndroid: _realAndroidRewarded,
    realIos: _realIosRewarded,
    testAndroid: _androidTestRewarded,
    testIos: _iosTestRewarded,
  );

  /// Native ad inside a scrolling feed (Home, Ranks).
  static String get nativeFeed => _pick(
    realAndroid: _realAndroidNative,
    realIos: _realIosNative,
    testAndroid: _androidTestNative,
    testIos: _iosTestNative,
  );

  /// Native ad on a result screen (level complete, duel, daily).
  static String get nativeResult => _pick(
    realAndroid: _realAndroidNative,
    realIos: _realIosNative,
    testAndroid: _androidTestNative,
    testIos: _iosTestNative,
  );

  /// App-open ad — reserved, no service uses it yet.
  static String get appOpen => _pick(
    realAndroid: _realAndroidAppOpen,
    realIos: _realIosAppOpen,
    testAndroid: _androidTestAppOpen,
    testIos: _iosTestAppOpen,
  );
}
