import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_typography.dart';

/// `.stars` — the three stars on S-21.
///
/// They land one at a time with `pop`, at 0, 200 and 400 ms — the sequencing
/// the bible specifies, which is what makes the third star's absence feel
/// earned rather than simply missing.
class StarsRow extends StatelessWidget {
  const StarsRow({required this.stars, super.key, this.total = 3});

  final int stars;
  final int total;

  /// The stagger between stars.
  static const Duration stagger = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < total; index++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: _Star(isEarned: index < stars, index: index),
            ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.isEarned, required this.index});

  final bool isEarned;
  final int index;

  @override
  Widget build(BuildContext context) {
    final star = Text(
      '⭐',
      style: AppTypography.glyph(38.sp).copyWith(
        shadows: isEarned
            ? [
                BoxShadow(
                  color: const Color(0xFFFFC61A).withValues(alpha: 0.5),
                  offset: Offset(0, 4.h),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
    );

    // An unearned star is greyed and dimmed rather than removed, so the row
    // always shows what was available.
    final rendered = isEarned
        ? star
        : Opacity(
            opacity: 0.35,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0, //
                0, 0, 0, 1, 0, //
              ]),
              child: star,
            ),
          );

    if (!isEarned) return rendered;

    return rendered.animate().scale(
      delay: StarsRow.stagger * index,
      duration: AppMotion.durationOf(context, AppMotion.pop),
      curve: AppMotion.curveOf(context, AppMotion.popCurve),
      begin: const Offset(0.3, 0.3),
      end: const Offset(1, 1),
    );
  }
}
