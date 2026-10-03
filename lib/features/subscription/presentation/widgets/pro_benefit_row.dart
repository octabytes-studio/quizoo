import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/features/subscription/domain/pro_benefit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One benefit on the paywall and the membership screen (plan 023).
///
/// An emoji plate, a short title and exactly one sentence of plain copy —
/// a new player should understand it without knowing the app's vocabulary.
/// Titles and copy come from l10n through an exhaustive [switch], so a new
/// [ProBenefit] fails to compile until it is worded in both languages.
class ProBenefitRow extends StatelessWidget {
  const ProBenefitRow({
    required this.benefit,
    super.key,
    this.showGoldCheck = false,
  });

  final ProBenefit benefit;

  /// True on the membership screen: the row is a receipt, so a gold check
  /// replaces the plate.
  final bool showGoldCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final title = switch (benefit) {
      ProBenefit.badge => l10n.proBenefitBadgeTitle,
      ProBenefit.allLevels => l10n.proBenefitAllLevelsTitle,
      ProBenefit.noAds => l10n.proBenefitNoAdsTitle,
      ProBenefit.freeRevive => l10n.proBenefitFreeReviveTitle,
      ProBenefit.doublePowerUps => l10n.proBenefitDoublePowerUpsTitle,
      ProBenefit.streakShield => l10n.proBenefitStreakShieldTitle,
      ProBenefit.avatars => l10n.proBenefitAvatarsTitle,
      ProBenefit.answerReview => l10n.proBenefitAnswerReviewTitle,
    };
    final body = switch (benefit) {
      ProBenefit.badge => l10n.proBenefitBadgeBody,
      ProBenefit.allLevels => l10n.proBenefitAllLevelsBody,
      ProBenefit.noAds => l10n.proBenefitNoAdsBody,
      ProBenefit.freeRevive => l10n.proBenefitFreeReviveBody,
      ProBenefit.doublePowerUps => l10n.proBenefitDoublePowerUpsBody,
      ProBenefit.streakShield => l10n.proBenefitStreakShieldBody,
      ProBenefit.avatars => l10n.proBenefitAvatarsBody,
      ProBenefit.answerReview => l10n.proBenefitAnswerReviewBody,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: showGoldCheck
                ? null
                : BoxDecoration(
                    color: AppColors.proCardBorder,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
            child: showGoldCheck
                ? Icon(
                    Icons.check_circle_rounded,
                    size: 24.sp,
                    color: AppColors.proGoldFrom,
                  )
                : Text(
                    benefit.emoji,
                    style: TextStyle(fontSize: 18.sp, height: 1),
                  ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall!.copyWith(color: Colors.white),
                ),
                SizedBox(height: 2.h),
                Text(
                  body,
                  style: textTheme.labelSmall!.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
