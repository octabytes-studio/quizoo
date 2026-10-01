import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/ads_config_api.dart';

/// Turns the ads Remote Config keys into an [AdsConfig].
///
/// Never throws and never returns nonsense: a value the console got wrong
/// (negative, or a cadence below one) falls back to that field's default, and
/// a Remote Config that cannot be read at all yields `const AdsConfig()`.
class AdsConfigRepository {
  AdsConfigRepository(this._api);

  final AdsConfigApi _api;

  static const enabledKey = 'ads_enabled';
  static const disabledPlacementsKey = 'ads_disabled_placements';
  static const graceBreaksKey = 'ads_interstitial_grace_breaks';
  static const everyNBreaksKey = 'ads_interstitial_every_n_breaks';
  static const minGapSecondsKey = 'ads_interstitial_min_gap_seconds';
  static const sessionCapKey = 'ads_interstitial_session_cap';
  static const homeFirstSectionKey = 'ads_home_native_first_section';
  static const homeEverySectionsKey = 'ads_home_native_every_sections';
  static const homeMaxKey = 'ads_home_native_max';
  static const ranksAfterRowKey = 'ads_ranks_native_after_row';

  AdsConfig read() {
    const defaults = AdsConfig();
    try {
      return AdsConfig(
        enabled: _api.getBool(enabledKey),
        disabledPlacements: _api
            .getString(disabledPlacementsKey)
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet(),
        interstitialGraceBreaks: _atLeast(
          0,
          graceBreaksKey,
          defaults.interstitialGraceBreaks,
        ),
        interstitialEveryNBreaks: _atLeast(
          1,
          everyNBreaksKey,
          defaults.interstitialEveryNBreaks,
        ),
        interstitialMinGapSeconds: _atLeast(
          0,
          minGapSecondsKey,
          defaults.interstitialMinGapSeconds,
        ),
        interstitialSessionCap: _atLeast(
          0,
          sessionCapKey,
          defaults.interstitialSessionCap,
        ),
        homeNativeFirstSection: _atLeast(
          0,
          homeFirstSectionKey,
          defaults.homeNativeFirstSection,
        ),
        homeNativeEverySections: _atLeast(
          1,
          homeEverySectionsKey,
          defaults.homeNativeEverySections,
        ),
        homeNativeMax: _atLeast(0, homeMaxKey, defaults.homeNativeMax),
        ranksNativeAfterRow: _atLeast(
          0,
          ranksAfterRowKey,
          defaults.ranksNativeAfterRow,
        ),
      );
    } catch (_) {
      return defaults;
    }
  }

  /// The value at [key], or [fallback] when it is below [minimum].
  int _atLeast(int minimum, String key, int fallback) {
    final value = _api.getInt(key);
    return value < minimum ? fallback : value;
  }
}
