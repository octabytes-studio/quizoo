import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizoo/core/ads/admob_inline_ad_service.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';

/// Renders a [LoadedInlineAd] at the size the SDK loaded it at.
///
/// Only a real AdMob ad has a platform view to show; anything else (the fake
/// a widget test supplies) is an empty box of the same size, so layout is
/// exercised without the plugin.
class InlineAdView extends StatelessWidget {
  const InlineAdView({required this.ad, super.key});

  final LoadedInlineAd ad;

  @override
  Widget build(BuildContext context) {
    final ad = this.ad;
    return SizedBox(
      width: ad.width,
      height: ad.height,
      child: ad is AdMobLoadedInlineAd ? AdWidget(ad: ad.ad) : null,
    );
  }
}
