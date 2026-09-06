import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';

/// S-27's seven day-circles — done in mint, today in mango, a plain number for
/// the rest, and a lemon-gradient gift on the reward day.
class StreakWeekRow extends StatelessWidget {
  const StreakWeekRow({required this.days, super.key});

  final List<StreakDay> days;

  /// `.node`-style circle, 36×36 with a 13pt corner — this widget's own
  /// one-off shape, not one of `AppRadius`'s named tokens.
  static const double circleSize = 36;
  static const double circleRadius = 13;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in days) Expanded(child: _StreakDayCircle(day: day)),
      ],
    );
  }
}

class _StreakDayCircle extends StatelessWidget {
  const _StreakDayCircle({required this.day});

  final StreakDay day;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    final (
      Widget glyph,
      Color? background,
      Gradient? gradient,
      Color labelColor,
    ) = switch (day.mark) {
      StreakDayMark.done => (
        Text('✓', style: AppTypography.glyph(16.sp, color: Colors.white)),
        quizoo.ok,
        null,
        quizoo.tx3,
      ),
      StreakDayMark.today => (
        Text('🔥', style: AppTypography.glyph(16.sp)),
        quizoo.p,
        null,
        quizoo.p,
      ),
      StreakDayMark.future => (
        Text(
          day.label,
          style: textTheme.bodyLarge!.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: quizoo.tx2,
          ),
        ),
        quizoo.s3,
        null,
        quizoo.tx3,
      ),
      StreakDayMark.reward => (
        Text('🎁', style: AppTypography.glyph(15.sp)),
        null,
        AppGradients.tile(AppColors.coinDiscFrom, AppColors.coinDiscTo),
        quizoo.tx3,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: StreakWeekRow.circleSize.w,
          height: StreakWeekRow.circleSize.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            gradient: gradient,
            borderRadius: BorderRadius.circular(StreakWeekRow.circleRadius.r),
          ),
          child: glyph,
        ),
        SizedBox(height: 5.h),
        Text(
          day.label,
          style: textTheme.labelSmall!.copyWith(color: labelColor),
        ),
      ],
    );
  }
}
