import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/ads_pacing_store.dart';

/// Decides whether an interstitial may be shown at a break point — the whole
/// "not annoying" contract in one place.
///
/// A break is a moment the player leaves a finished run by tapping a button.
/// In order, a break shows nothing when it falls inside the post-install
/// grace period, when the run just earned a celebration, when too few breaks
/// have passed since the last ad, when the session cap is reached, when a
/// full-screen ad (interstitial *or* rewarded) was on screen too recently, or
/// when no ad is loaded. Only an ad that was actually shown resets the
/// cadence, so a skipped break stays owed to the next one.
class InterstitialPacer {
  InterstitialPacer(this._store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AdsPacingStore _store;
  final DateTime Function() _now;

  int _breaksSinceLastShown = 0;
  int _shownThisSession = 0;
  DateTime? _lastFullScreenAdAt;

  /// Records one eligible break and says whether to show an interstitial now.
  bool registerBreak(
    AdsConfig config, {
    required bool isCelebration,
    required bool isAdReady,
  }) {
    _store.recordBreak();
    if (_store.lifetimeBreaks <= config.interstitialGraceBreaks) return false;

    _breaksSinceLastShown++;
    if (isCelebration) return false;
    if (_breaksSinceLastShown < config.interstitialEveryNBreaks) return false;
    if (_shownThisSession >= config.interstitialSessionCap) return false;

    final last = _lastFullScreenAdAt;
    if (last != null &&
        _now().difference(last).inSeconds < config.interstitialMinGapSeconds) {
      return false;
    }
    return isAdReady;
  }

  /// An interstitial was shown: counts toward the session cap, and starts the
  /// cadence and the cooldown again.
  void noteInterstitialShown() {
    _shownThisSession++;
    noteFullScreenAdShown();
  }

  /// Any full-screen ad was shown — the rewarded heart ad calls this too, so
  /// a player who just watched one is not shown an interstitial moments later.
  void noteFullScreenAdShown() {
    _breaksSinceLastShown = 0;
    _lastFullScreenAdAt = _now();
  }
}
