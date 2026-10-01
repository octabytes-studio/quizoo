import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/widgets/native_ad_frame.dart';

/// A small native ad, shaped like one of the app's list rows — for feeds
/// (Home, Ranks) and the shorter result screens.
class NativeAdTile extends StatelessWidget {
  const NativeAdTile({
    required this.placement,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final AdPlacement placement;

  /// Space around the slot; it collapses together with the ad.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return NativeAdFrame(
      placement: placement,
      size: NativeAdSize.small,
      radius: AppRadius.listRow.r,
      padding: padding,
    );
  }
}
