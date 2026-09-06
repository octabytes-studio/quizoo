import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/onboarding/domain/onboarding_slide.dart';

/// One card of the S-02 carousel: a 190px gradient disc holding a large
/// emoji, a display heading, and a line of body copy.
class OnboardingSlideCard extends StatelessWidget {
  const OnboardingSlideCard({
    required this.slide,
    required this.title,
    required this.body,
    super.key,
  });

  final OnboardingSlide slide;
  final String title;
  final String body;

  /// The disc behind the emoji.
  static const double discSize = 190;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final glowColor = AppGradients.hex(slide.gradientTo);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: discSize.w,
            height: discSize.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.tileFromHex(
                slide.gradientFrom,
                slide.gradientTo,
              ),
              boxShadow: [
                // `0 14px 40px -14px <accent>` — a coloured glow, not a shadow.
                BoxShadow(
                  color: glowColor,
                  offset: Offset(0, 14.h),
                  blurRadius: 40,
                  spreadRadius: -14,
                ),
              ],
            ),
            child: Text(slide.emoji, style: AppTypography.glyph(86.sp)),
          ),
          SizedBox(height: 22.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(fontSize: 27.sp),
          ),
          SizedBox(height: AppSpacing.xs.h + 2.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(
              fontSize: 13.5.sp,
              height: 1.55,
              color: quizoo.tx2,
            ),
          ),
        ],
      ),
    );
  }
}
