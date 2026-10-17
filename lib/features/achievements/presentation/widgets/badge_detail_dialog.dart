import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-34 — the badge detail dialog.
///
/// The locked variant is bible-specified: what the badge is, how close the
/// player is, and the single next action. **The unlocked variant is this
/// plan's own extrapolation** (Assumption 2) — the bible only shows the
/// locked frame — so it keeps the same name/description/reward chips and
/// swaps the progress card for an "unlocked {date}" line and a single
/// "Close" action.
class BadgeDetailDialog extends StatelessWidget {
  const BadgeDetailDialog({required this.progress, super.key});

  final BadgeProgress progress;

  static Future<void> show(BuildContext context, BadgeProgress progress) {
    final quizoo = context.quizoo;
    return showDialog<void>(
      context: context,
      barrierColor: quizoo.ov,
      builder: (_) => BadgeDetailDialog(progress: progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final badge = progress.badge;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w + 2.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          22.w,
          AppSpacing.xl.h,
          22.w,
          AppSpacing.lg.h,
        ),
        decoration: BoxDecoration(
          color: quizoo.s1,
          borderRadius: AppRadius.dialogAll,
          boxShadow: quizoo.shadowLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 84.w,
                height: 84.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.tileFromHex(
                    badge.gradientFrom,
                    badge.gradientTo,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.dialogIcon.r),
                ),
                child: Text(badge.emoji, style: AppTypography.glyph(42.sp)),
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge,
            ),
            SizedBox(height: 6.h),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            SizedBox(height: AppSpacing.base.h),
            if (badge.isLocked)
              _ProgressCard(progress: progress)
            else
              _UnlockedLine(unlockedAt: badge.unlockedAt),
            SizedBox(height: AppSpacing.base.h),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm.w,
              runSpacing: AppSpacing.xs.h,
              children: [
                AppChip.status(
                  label: l10n.badgeDetailRarity(badge.rarityPercent),
                  leading: '🏆',
                ),
                if (progress.rewardCoins != null)
                  AppChip.status(
                    label: l10n.badgeDetailReward(progress.rewardCoins!),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.base.h + 2.h),
            // Plan 025: the CTA appears only when the server supplied the
            // full route (category + subcategory + display name) — no
            // fixture fallback, and nothing for a topic it cannot address.
            if (badge.isLocked &&
                progress.nextCategoryId != null &&
                progress.nextSubcategoryId != null &&
                progress.nextSubcategoryName != null) ...[
              ChunkyButton(
                label: l10n.badgeDetailPlay(progress.nextSubcategoryName!),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    AppRoutes.levelMapPath(
                      progress.nextCategoryId!,
                      progress.nextSubcategoryId!,
                    ),
                  );
                },
              ),
              SizedBox(height: 9.h),
            ],
            ChunkyButton.line(
              label: l10n.commonClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final BadgeProgress progress;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: quizoo.s2,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  progress.closestGroupLabel ?? '',
                  style: textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Text(
                progress.closestFractionLabel ?? '',
                style: textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs.h + 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: SizedBox(
              height: 6.h,
              child: LinearProgressIndicator(
                value: (progress.closestProgress ?? 0).clamp(0, 1),
                backgroundColor: quizoo.s3,
                valueColor: AlwaysStoppedAnimation<Color>(quizoo.g),
              ),
            ),
          ),
          if (progress.nextActionLabel != null) ...[
            SizedBox(height: AppSpacing.sm.h + 1.h),
            Text(
              progress.nextActionLabel!,
              style: textTheme.bodyMedium!.copyWith(
                fontSize: 11.5.sp,
                color: quizoo.tx2,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlockedLine extends StatelessWidget {
  const _UnlockedLine({required this.unlockedAt});

  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final date = unlockedAt;

    return Center(
      child: Text(
        date == null
            ? ''
            : l10n.badgeDetailUnlockedOn(
                DateFormat.yMMMd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(date),
              ),
        style: textTheme.labelMedium!.copyWith(color: quizoo.ok),
      ),
    );
  }
}
