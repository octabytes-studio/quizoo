import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/subscription/pro_offer.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One purchasable plan on the paywall (plan 023).
///
/// Radio-style: a gold border and a check on the selected card. The price
/// text is whatever the store reported — [ProOffer.priceLabel], and
/// [ProOffer.perMonthLabel] for yearly — never a number this app invented
/// (Assumption 6).
class ProPlanCard extends StatelessWidget {
  const ProPlanCard({
    required this.offer,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.savingsPercent,
  });

  final ProOffer offer;
  final bool isSelected;
  final VoidCallback onTap;

  /// The "Save N%" pill, when the paywall could compute one. Yearly only.
  final int? savingsPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final gold = AppColors.proGoldFrom;

    final title = switch (offer.plan) {
      ProPlan.monthly => l10n.proPlanMonthly,
      ProPlan.yearly => l10n.proPlanYearly,
      ProPlan.lifetime => l10n.proPlanLifetime,
    };
    final priceLine = switch (offer.plan) {
      ProPlan.monthly => l10n.proPricePerMonth(offer.priceLabel),
      ProPlan.yearly => l10n.proPricePerYear(offer.priceLabel),
      ProPlan.lifetime => l10n.proPriceOnce(offer.priceLabel),
    };

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $priceLine',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              color: AppColors.proCard,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              border: Border.all(
                color: isSelected ? gold : AppColors.proCardBorder,
                width: isSelected ? 2.w : 1.w,
              ),
            ),
            child: Row(
              children: [
                // Radio-style selection indicator.
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? gold : AppColors.proCardBorder,
                      width: 2.w,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? Icon(Icons.check_rounded, size: 14.sp, color: gold)
                      : null,
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: textTheme.titleSmall!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (offer.plan == ProPlan.yearly) ...[
                            SizedBox(width: AppSpacing.sm.w),
                            _Pill(text: l10n.proBestValue, color: gold),
                          ],
                          if (savingsPercent != null) ...[
                            SizedBox(width: AppSpacing.xs.w),
                            _Pill(
                              text: l10n.proSavePercent(savingsPercent!),
                              color: AppColors.proGoldTo,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        [
                          priceLine,
                          if (offer.perMonthLabel != null)
                            l10n.proPerMonthLabel(offer.perMonthLabel!),
                        ].join(' · '),
                        style: textTheme.labelSmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: AppColors.onGold,
          fontWeight: FontWeight.w800,
          fontSize: 9.sp,
        ),
      ),
    );
  }
}
