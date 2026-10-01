import 'package:flutter/material.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/inline_ad_slot.dart';

/// An adaptive banner anchored to the bottom edge of a screen — built for
/// `Scaffold.bottomNavigationBar`.
///
/// The strip keeps its height whether or not an ad arrives, so the content
/// above it (the Level Map's Play button, say) never moves under the
/// player's thumb. A hairline and its own surface colour keep the ad visibly
/// apart from app chrome.
///
/// Pass [isVisible] `false` while the screen has no real content (an error or
/// empty state) — policy keeps ads off those. Either way the widget takes up
/// the bottom safe-area inset, because a `Scaffold` hands that inset to its
/// `bottomNavigationBar` instead of its body.
class AnchoredBannerAd extends StatelessWidget {
  const AnchoredBannerAd({
    required this.placement,
    super.key,
    this.isVisible = true,
  });

  final AdPlacement placement;
  final bool isVisible;

  static const Widget _inset = SafeArea(top: false, child: SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return _inset;
    final quizoo = context.quizoo;

    return InlineAdSlot(
      placement: placement,
      keepsSpaceOnFailure: true,
      placeholder: _inset,
      requestBuilder: (context, constraints) => AnchoredBannerRequest(
        placement: placement,
        widthDp: constraints.maxWidth.truncate(),
      ),
      frameBuilder: (context, ad) => DecoratedBox(
        decoration: BoxDecoration(
          color: quizoo.s1,
          border: Border(top: BorderSide(color: quizoo.ln)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Center(heightFactor: 1, child: ad),
          ),
        ),
      ),
    );
  }
}
