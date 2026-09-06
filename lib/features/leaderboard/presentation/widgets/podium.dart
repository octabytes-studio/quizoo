import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';

/// S-29's top-3 podium — the one place in the whole app that uses variable
/// "plinth" heights; everywhere else is a flat row (the bible's own explicit
/// note).
class Podium extends StatelessWidget {
  const Podium({
    required this.first,
    required this.second,
    required this.third,
    super.key,
    this.onTap,
  });

  final LeaderboardEntry first;
  final LeaderboardEntry second;
  final LeaderboardEntry third;

  final ValueChanged<LeaderboardEntry>? onTap;

  static const double firstPlinth = 64;
  static const double secondPlinth = 48;
  static const double thirdPlinth = 36;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPlace(
              entry: second,
              plinthHeight: secondPlinth,
              onTap: onTap,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: _PodiumPlace(
              entry: first,
              plinthHeight: firstPlinth,
              onTap: onTap,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: _PodiumPlace(
              entry: third,
              plinthHeight: thirdPlinth,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.plinthHeight,
    this.onTap,
  });

  final LeaderboardEntry entry;
  final double plinthHeight;
  final ValueChanged<LeaderboardEntry>? onTap;

  static const double avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(entry),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize.w,
            height: avatarSize.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quizoo.s3,
              border: Border.all(color: quizoo.s1, width: 2),
            ),
            child: Text(entry.avatarEmoji, style: AppTypography.glyph(23.sp)),
          ),
          SizedBox(height: 6.h),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge!.copyWith(fontSize: 12.5.sp),
          ),
          Text(
            AppFormat.compact(entry.score, localeName),
            style: textTheme.labelSmall,
          ),
          SizedBox(height: AppSpacing.sm.h),
          Container(
            width: double.infinity,
            height: plinthHeight.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: quizoo.s2,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.tile.r),
              ),
            ),
            child: Text(
              '${entry.rank}',
              style: textTheme.displayMedium!.copyWith(
                fontSize: 20.sp,
                color: quizoo.tx2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
