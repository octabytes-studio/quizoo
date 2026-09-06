import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/profile/domain/category_accuracy.dart';

/// One row of S-35's "Accuracy by category" — a thin progress bar, colour-
/// coded per the bible's own rule: ≥70% mint, <50% raspberry, otherwise the
/// neutral fill.
class CategoryAccuracyRow extends StatelessWidget {
  const CategoryAccuracyRow({required this.accuracy, super.key});

  final CategoryAccuracy accuracy;

  static const int okThreshold = 70;
  static const int badThreshold = 50;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final percent = accuracy.accuracyPercent;

    final barColor = percent >= okThreshold
        ? quizoo.ok
        : percent < badThreshold
        ? quizoo.bad
        : quizoo.g;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${accuracy.emoji} ${accuracy.categoryName}',
              style: textTheme.bodyLarge!.copyWith(fontSize: 12.sp),
            ),
            Text(
              '$percent%',
              style: textTheme.bodyLarge!.copyWith(fontSize: 12.sp),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: SizedBox(
            height: 5.h,
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              backgroundColor: quizoo.s3,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}
