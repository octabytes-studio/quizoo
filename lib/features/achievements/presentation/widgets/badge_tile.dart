import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';

/// One cell of S-33's grid.
///
/// Unlocked: a full-colour gradient plate. Locked: the *same* plate in
/// greyscale at ~40% opacity — the bible's explicit "you cannot want what
/// you cannot see" rule, which is why a locked badge stays visible rather
/// than being hidden from the grid entirely.
class BadgeTile extends StatelessWidget {
  const BadgeTile({required this.progress, super.key, this.onTap});

  final BadgeProgress progress;
  final VoidCallback? onTap;

  static const double plateSize = 72;

  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final badge = progress.badge;

    Widget plate = Container(
      width: plateSize.w,
      height: plateSize.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.tileFromHex(
          badge.gradientFrom,
          badge.gradientTo,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Text(badge.emoji, style: AppTypography.glyph(34.sp)),
    );

    if (badge.isLocked) {
      plate = Opacity(
        opacity: 0.4,
        child: ColorFiltered(colorFilter: _grayscale, child: plate),
      );
    }

    return Semantics(
      button: true,
      label: badge.isLocked ? '${badge.name}, locked' : badge.name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            plate,
            SizedBox(height: 6.h),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium!.copyWith(
                fontSize: 10.5.sp,
                color: badge.isLocked ? quizoo.tx3 : quizoo.tx2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
