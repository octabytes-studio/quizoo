import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizoo/core/ads/ad_unit_ids.dart';
import 'package:quizoo/features/quiz_play/data/rewarded_ad_service.dart';

/// The real AdMob-backed [RewardedAdService] — this app's first genuine ad
/// SDK integration. Its ad unit id comes from [AdUnitIds], which currently
/// holds Google's public **test** ids, matching the test App IDs configured
/// natively on both platforms.
class AdMobRewardedAdService implements RewardedAdService {
  RewardedAd? _ad;

  @override
  Future<bool> load() async {
    final completer = Completer<bool>();
    try {
      // Only dispatches the load request — `onAdLoaded`/`onAdFailedToLoad`
      // fire later, from a separate native callback, which is what the
      // completer above actually waits on.
      await RewardedAd.load(
        adUnitId: AdUnitIds.rewardedHeart,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  @override
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) return false;

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete(earned);
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
      return await completer.future;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _ad?.dispose();
    _ad = null;
  }
}
