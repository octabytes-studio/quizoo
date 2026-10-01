/// How long a loaded ad may be kept before it is thrown away and replaced.
///
/// AdMob expires a loaded ad after an hour; five minutes of margin means the
/// app never tries to show one the network has already written off.
const Duration adFreshnessWindow = Duration(minutes: 55);

/// The AdMob format a placement is filled with.
enum AdFormat {
  interstitial,
  anchoredBanner,
  mediumRectangle,
  nativeSmall,
  nativeMedium,
}

/// Every place in the app an interstitial, banner or native ad may appear.
///
/// [id] is the stable string the `ads_disabled_placements` Remote Config key
/// lists to switch a placement off without a release — never rename one.
///
/// A screen that is not named here is deliberately ad-free (the play surface,
/// Level Failed, celebration screens, forms, settings): adding a placement is
/// a product decision, not a code tidy-up.
enum AdPlacement {
  levelCompleteBreak('level_complete_break', AdFormat.interstitial),
  duelResultBreak('duel_result_break', AdFormat.interstitial),
  dailyResultBreak('daily_result_break', AdFormat.interstitial),
  levelMapBanner('level_map_banner', AdFormat.anchoredBanner),
  categoryDetailBanner('category_detail_banner', AdFormat.anchoredBanner),
  statsBanner('stats_banner', AdFormat.anchoredBanner),
  achievementsBanner('achievements_banner', AdFormat.anchoredBanner),
  dailyTabRectangle('daily_tab_rectangle', AdFormat.mediumRectangle),
  homeFeedNative('home_feed_native', AdFormat.nativeSmall),
  ranksFeedNative('ranks_feed_native', AdFormat.nativeSmall),
  levelCompleteNative('level_complete_native', AdFormat.nativeSmall),
  duelResultNative('duel_result_native', AdFormat.nativeSmall),
  dailyResultNative('daily_result_native', AdFormat.nativeMedium);

  const AdPlacement(this.id, this.format);

  final String id;
  final AdFormat format;
}
