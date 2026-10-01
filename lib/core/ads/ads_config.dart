import 'package:freezed_annotation/freezed_annotation.dart';

part 'ads_config.freezed.dart';

/// Every remotely tunable number behind the interstitial, banner and native
/// ads — pacing, feed positions, and the kill switches.
///
/// The defaults here are the shipping values: they apply whenever Remote
/// Config has nothing (first launch, offline, a bad value), and they match
/// the defaults `main.dart` registers.
@freezed
abstract class AdsConfig with _$AdsConfig {
  const factory AdsConfig({
    /// Master switch for every interstitial, banner and native ad.
    @Default(true) bool enabled,

    /// `AdPlacement.id`s that are switched off.
    @Default(<String>{}) Set<String> disabledPlacements,

    /// Eligible breaks after install that never show an interstitial.
    @Default(2) int interstitialGraceBreaks,

    /// At most one interstitial per this many eligible breaks.
    @Default(2) int interstitialEveryNBreaks,

    /// Minimum seconds since the last full-screen ad of any kind.
    @Default(120) int interstitialMinGapSeconds,

    /// Most interstitials shown in one app process.
    @Default(8) int interstitialSessionCap,

    /// Home's first native row comes after this many category sections.
    @Default(2) int homeNativeFirstSection,

    /// Then one more per this many sections.
    @Default(5) int homeNativeEverySections,

    /// Most native rows on Home.
    @Default(2) int homeNativeMax,

    /// Ranks' native row comes after this many list rows.
    @Default(5) int ranksNativeAfterRow,
  }) = _AdsConfig;
}
