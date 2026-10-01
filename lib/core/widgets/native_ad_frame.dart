import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/ads/ad_dimensions.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/ad_label.dart';
import 'package:quizoo/core/widgets/inline_ad_slot.dart';

/// The chrome shared by `NativeAdTile` and `NativeAdCard`: an
/// "Advertisement" caption over a bordered, rounded surface painted from the
/// app's own tokens, so a native template sits in the page like one of its
/// cards.
///
/// Google's own "Ad" badge and AdChoices icon are drawn inside the template —
/// nothing here may cover them.
class NativeAdFrame extends StatelessWidget {
  const NativeAdFrame({
    required this.placement,
    required this.size,
    required this.radius,
    required this.padding,
    super.key,
  });

  final AdPlacement placement;
  final NativeAdSize size;

  /// Corner radius of the surface, already screen-scaled.
  final double radius;

  /// Space around the slot; it collapses together with the ad.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return InlineAdSlot(
      placement: placement,
      keepsSpaceOnFailure: false,
      requestBuilder: (context, constraints) => NativeAdRequest(
        placement: placement,
        size: size,
        palette: NativeAdPalette(
          background: quizoo.s1,
          text: quizoo.tx,
          secondaryText: quizoo.tx2,
          ctaBackground: quizoo.p,
          ctaText: Colors.white,
        ),
      ),
      frameBuilder: (context, ad) => Padding(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AdDimensions.nativeMaxWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AdLabel(),
                SizedBox(height: AppSpacing.xs.h),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: quizoo.s1,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: quizoo.ln),
                  ),
                  child: ad,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
