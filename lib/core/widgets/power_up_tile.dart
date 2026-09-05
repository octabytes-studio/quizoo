import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// A tile in the play surface's power-up dock (§06).
///
/// 56×52, always visible during a level. The count badge is mango; a tile the
/// player has none of drops to 40% and opens the shop instead of firing.
class PowerUpTile extends StatelessWidget {
  const PowerUpTile({
    required this.emoji,
    required this.label,
    required this.count,
    required this.onUse,
    required this.onBuy,
    super.key,
  });

  final String emoji;

  /// "50:50", "+15s", "SKIP".
  final String label;

  /// How many the player holds. Zero dims the tile and routes taps to [onBuy].
  final int count;

  /// Fired when the player has at least one.
  final VoidCallback onUse;

  /// Fired when the player has none — opens the shop.
  final VoidCallback onBuy;

  /// `.pup` — 56×52.
  static const double width = 56;
  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final isAvailable = count > 0;

    final tile = Container(
      width: width.w,
      height: height.h,
      decoration: BoxDecoration(
        color: arena.powerUpTile,
        borderRadius: BorderRadius.circular(AppRadius.powerUp.r),
        border: Border.all(color: arena.powerUpBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: AppTypography.glyph(19.sp)),
          SizedBox(height: 1.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall!.copyWith(
              // The bible's `.pup span` is 8.5px — below the "never below
              // 10.5px" floor stated in §04. The CSS wins here because the
              // user asked for pixel parity with the document; the label is
              // decorative anyway (the emoji and the count carry the meaning,
              // and the semantics below spell it out for a screen reader).
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: arena.onArena.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: '$label power-up',
      value: isAvailable ? '$count left' : 'None left, tap to buy',
      child: GestureDetector(
        onTap: isAvailable ? onUse : onBuy,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width.w,
          height: height.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(opacity: isAvailable ? 1 : 0.4, child: tile),
              if (isAvailable)
                Positioned(
                  top: -5.h,
                  right: -4.w,
                  child: Container(
                    width: 17.w,
                    height: 17.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: quizoo.p,
                    ),
                    child: Text(
                      '$count',
                      style: textTheme.labelSmall!.copyWith(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
