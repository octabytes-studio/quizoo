import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// S-32's 4-up stat strip — points / levels / accuracy / badges, each in an
/// equal column separated by hairlines.
class StatStrip extends StatelessWidget {
  const StatStrip({required this.stats, super.key});

  /// Exactly four `(value, label)` pairs, in display order.
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: quizoo.ln),
        boxShadow: quizoo.shadow,
      ),
      child: Row(
        children: [
          for (final (index, stat) in stats.indexed) ...[
            if (index > 0)
              SizedBox(
                width: 1.w,
                child: ColoredBox(color: quizoo.ln),
              ),
            Expanded(
              child: _Stat(value: stat.$1, label: stat.$2),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(value, style: textTheme.displayMedium!.copyWith(fontSize: 20.sp)),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}
