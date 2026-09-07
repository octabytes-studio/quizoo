import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/shop/domain/coin_pack.dart';

/// One tile in S-36's 3-up coin-pack grid.
///
/// The middle, most-favourable pack gets a 2px mango border and sits
/// slightly proud of its neighbours — the bible's own "middle-highlighted"
/// framing for the $4.99 pack.
class CoinPackTile extends StatelessWidget {
  const CoinPackTile({required this.pack, required this.onTap, super.key});

  final CoinPack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${pack.coins} coins, ${pack.priceLabel}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: AppRadius.tileAll,
            border: Border.all(
              color: pack.isHighlighted ? quizoo.p : quizoo.ln,
              width: pack.isHighlighted ? 2 : 1,
            ),
            boxShadow: pack.isHighlighted ? quizoo.shadow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pack.bonusPercent > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs.w + 2.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: quizoo.okBg,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    '+${pack.bonusPercent}%',
                    style: textTheme.labelSmall!.copyWith(color: quizoo.ok),
                  ),
                )
              else
                SizedBox(height: 15.h),
              SizedBox(height: AppSpacing.xs.h),
              Text('🪙', style: AppTypography.glyph(26.sp)),
              SizedBox(height: 4.h),
              Text(
                '${pack.coins}',
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: quizoo.tx,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                pack.priceLabel,
                style: textTheme.labelSmall!.copyWith(color: quizoo.tx2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
