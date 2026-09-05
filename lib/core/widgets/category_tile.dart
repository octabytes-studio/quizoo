import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// A cell in Home's 3-up subcategory grid.
///
/// Shows the topic, how far the player has got, and a mint progress bar —
/// or a lock scrim when the topic is not open yet.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.name,
    required this.emoji,
    super.key,
    this.caption,
    this.plateColor,
    this.progress,
    this.isLocked = false,
    this.onTap,
  });

  final String name;
  final String emoji;

  /// "Lv 7/20", "New", "Locked".
  final String? caption;

  /// Tint behind the emoji plate. Defaults to the sunken surface.
  final Color? plateColor;

  /// 0…1. Null hides the bar entirely — a never-played topic has no bar.
  final double? progress;

  final bool isLocked;
  final VoidCallback? onTap;

  /// `.tile .av` — the emoji plate.
  static const double plateSize = 52;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    Widget tile = Container(
      padding: EdgeInsets.fromLTRB(8.w, 11.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: quizoo.ln),
        boxShadow: quizoo.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: plateSize.w,
            height: plateSize.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: plateColor ?? quizoo.s3,
              borderRadius: BorderRadius.circular(AppRadius.emojiPlate.r),
            ),
            child: Text(emoji, style: AppTypography.glyph(27.sp)),
          ),
          SizedBox(height: 7.h),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge!.copyWith(
              fontSize: 11.8.sp,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.118,
              color: quizoo.tx,
            ),
          ),
          if (caption != null)
            Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall!.copyWith(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          if (progress != null)
            Padding(
              padding: EdgeInsets.only(top: 7.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2.r),
                child: SizedBox(
                  height: 4.h,
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0, 1),
                    backgroundColor: quizoo.s3,
                    valueColor: AlwaysStoppedAnimation<Color>(quizoo.ok),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (isLocked) {
      // `.tile .lockx` — the tile stays legible under a 74% surface scrim.
      tile = Stack(
        children: [
          tile,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: quizoo.s1.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(AppRadius.tile.r),
              ),
              child: Center(
                child: Text('🔒', style: AppTypography.glyph(22.sp)),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return tile;

    return Semantics(
      button: true,
      enabled: !isLocked,
      label: caption == null ? name : '$name, $caption',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: tile,
      ),
    );
  }
}
