import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.catline` — the tappable header above a Home category section, and the
/// only place count vs. See-all is decided (plan 009).
///
/// The whole row is the tap target, not just the trailing pill: it is the
/// guaranteed route to a category's own screen (S-07), so it has to work
/// even for the common case of ten or fewer topics, where no pill renders
/// at all.
class CategorySectionHeader extends StatelessWidget {
  const CategorySectionHeader({
    required this.name,
    required this.emoji,
    required this.topicCount,
    super.key,
    this.plateColor,
    this.showSeeAll = false,
    this.onTap,
  });

  final String name;
  final String emoji;

  /// Tint behind the medallion, as `#RRGGBB`. Defaults to the sunken surface.
  final String? plateColor;

  final int topicCount;

  /// True once [topicCount] exceeds [seeAllThreshold] — computed by the
  /// caller from the grouped topic list (or the backend's own flag, once one
  /// exists), never inline here.
  final bool showSeeAll;

  final VoidCallback? onTap;

  /// The bible's own "more than ten subcategories" rule (§07). Named so a
  /// future change to the threshold is a one-line edit, not a search for a
  /// stray `10`.
  static const int seeAllThreshold = 10;

  /// `.catline .med` — 30.
  static const double medallionSize = 30;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Row(
        children: [
          Container(
            width: medallionSize.w,
            height: medallionSize.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: plateColor != null
                  ? AppGradients.hex(plateColor!, fallback: quizoo.s3)
                  : quizoo.s3,
              borderRadius: BorderRadius.circular(AppRadius.medallion.r),
            ),
            child: Text(emoji, style: AppTypography.glyph(16.sp)),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          if (showSeeAll)
            Container(
              height: 26.h,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
              decoration: BoxDecoration(
                color: quizoo.s1,
                borderRadius: AppRadius.pillAll,
                border: Border.all(color: quizoo.ln),
                boxShadow: quizoo.shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).homeSeeAllCount(topicCount),
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      color: quizoo.tx2,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 14.sp, color: quizoo.tx3),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).homeTopicCount(topicCount),
                  style: textTheme.labelSmall!.copyWith(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    color: quizoo.tx3,
                  ),
                ),
                Icon(Icons.chevron_right, size: 14.sp, color: quizoo.tx3),
              ],
            ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label: AppLocalizations.of(
        context,
      ).homeCategorySectionLabel(name, topicCount),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: row,
      ),
    );
  }
}
