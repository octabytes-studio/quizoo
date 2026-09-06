import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The `.chart` bar chart — S-28's 5-bucket "today's distribution" and
/// S-35's 7-bar "points per day" both render this one shape with different
/// bucket labels and highlight rules, which is what moved it here from
/// `features/daily` (CLAUDE.md §2: reused across features).
class DistributionChart extends StatelessWidget {
  const DistributionChart({
    required this.barPercents,
    required this.labels,
    super.key,
    this.highlightedIndex,
    this.height = 84,
  });

  /// 0…100, one per bar.
  final List<int> barPercents;

  /// One label per bar, printed underneath.
  final List<String> labels;

  /// The bar drawn in mango with a mango label. Null draws every bar in the
  /// same neutral colour (S-35's weekly chart still highlights "today").
  final int? highlightedIndex;

  final double height;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: height.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, percent) in barPercents.indexed) ...[
            if (index > 0) SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: _Bar(
                percent: percent,
                label: labels[index],
                isHighlighted: index == highlightedIndex,
                quizoo: quizoo,
                textTheme: textTheme,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.percent,
    required this.label,
    required this.isHighlighted,
    required this.quizoo,
    required this.textTheme,
  });

  final int percent;
  final String label;
  final bool isHighlighted;
  final QuizooColors quizoo;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: (percent / 100).clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isHighlighted ? quizoo.p : quizoo.s3,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            color: isHighlighted ? quizoo.p : quizoo.tx3,
            fontWeight: isHighlighted ? FontWeight.w800 : null,
          ),
        ),
      ],
    );
  }
}
