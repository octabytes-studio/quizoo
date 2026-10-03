import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The gold gradient promo card on Home (plan 023).
///
/// Dismissible for seven days via the ✕ — never a permanent wall. Hidden
/// entirely for a member and when Pro is unavailable; the caller decides
/// that (it has the `SubscriptionCubit`), this widget only draws.
///
/// The ✕ gets its own 44pt hit area so it is a real target rather than a
/// glyph to hunt for.
class GoProCard extends StatelessWidget {
  const GoProCard({required this.onTap, required this.onDismiss, super.key});

  /// Opens the paywall.
  final VoidCallback onTap;

  /// Hides the card for the next seven days.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.linear(AppGradients.bannerAngle, [
          AppColors.proGoldFrom,
          AppColors.proGoldTo,
        ]),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.proGoldTo.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.w,
              AppSpacing.base.h,
              AppSpacing.sm.w,
              AppSpacing.lg.h,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('👑', style: TextStyle(fontSize: 28.sp, height: 1.15)),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.proGoPro,
                        style: textTheme.titleMedium!.copyWith(
                          color: AppColors.onGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs.h),
                      Text(
                        l10n.proGoProCardBody,
                        style: textTheme.labelSmall!.copyWith(
                          color: AppColors.onGold.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // 44pt hit area without 44pt of visual weight.
                SizedBox(
                  width: 44.w,
                  height: 44.h,
                  child: IconButton(
                    onPressed: onDismiss,
                    tooltip: l10n.proNotNow,
                    icon: Icon(Icons.close_rounded, size: 20.sp),
                    color: AppColors.onGold,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
