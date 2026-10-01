import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/ads/ad_dimensions.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/ad_label.dart';
import 'package:quizoo/core/widgets/inline_ad_slot.dart';

/// A 300×250 medium rectangle, centred in its row under an "Advertisement"
/// caption. Reserves its height while loading and folds away — [padding]
/// included — if no ad arrives.
class MediumRectangleAd extends StatelessWidget {
  const MediumRectangleAd({
    required this.placement,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final AdPlacement placement;

  /// Space around the slot; it collapses together with the ad.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InlineAdSlot(
      placement: placement,
      keepsSpaceOnFailure: false,
      requestBuilder: (context, constraints) =>
          RectangleBannerRequest(placement: placement),
      frameBuilder: (context, ad) => Padding(
        padding: padding,
        child: Center(
          child: SizedBox(
            width: AdDimensions.rectangleWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdLabel(),
                SizedBox(height: AppSpacing.xs.h),
                ad,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
