import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-32's "Recent badges" rail — view-only, so it's shared verbatim between
/// [ProfileScreen] and Edit Profile rather than duplicated.
class BadgesRail extends StatelessWidget {
  const BadgesRail({
    required this.badges,
    required this.badgeCount,
    required this.onSeeAll,
    super.key,
  });

  final List<AppBadge> badges;
  final int badgeCount;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.profileRecentBadges,
          actionLabel: l10n.profileAllBadges(badgeCount),
          onActionPressed: onSeeAll,
        ),
        SizedBox(height: AppSpacing.md.h),
        SizedBox(
          height: 96.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return SizedBox(
                width: 78.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78.w,
                      height: 78.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.tileFromHex(
                          badge.gradientFrom,
                          badge.gradientTo,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppRadius.card.r + 4,
                        ),
                      ),
                      child: Text(
                        badge.emoji,
                        style: AppTypography.glyph(36.sp),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      badge.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
