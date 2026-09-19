import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';

/// A shimmer placeholder shaped exactly like [ListRowTile]'s player
/// variant — same padding, border, avatar circle and text-line rhythm — so
/// the loading state doesn't jump when the real rows arrive.
///
/// [appearAfter] defaults to zero here (unlike [SkeletonBox]'s own default)
/// because a leaderboard fetch is several sequential round trips chained
/// together; on a fast connection it can still resolve inside
/// [SkeletonBox]'s usual 300ms grace window, which would mean the shimmer
/// never gets a single visible frame.
class LeaderboardRowSkeleton extends StatelessWidget {
  const LeaderboardRowSkeleton({
    super.key,
    this.showSecondaryTrailingLine = true,
    this.appearAfter = Duration.zero,
  });

  /// Off for the category board, whose rows only ever show one trailing
  /// value line (see [ListRowTile.trailingLabel] usage there).
  final bool showSecondaryTrailingLine;

  final Duration appearAfter;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: BorderRadius.circular(AppRadius.listRow.r),
        border: Border.all(color: quizoo.ln),
      ),
      child: Row(
        children: [
          SkeletonBox(
            width: ListRowTile.avatarSize.w,
            height: ListRowTile.avatarSize.w,
            borderRadius: BorderRadius.circular(ListRowTile.avatarSize.w),
            appearAfter: appearAfter,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(
                  width: 96.w,
                  height: 12.h,
                  appearAfter: appearAfter,
                ),
                SizedBox(height: 6.h),
                SkeletonBox(width: 64.w, height: 9.h, appearAfter: appearAfter),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 36.w, height: 12.h, appearAfter: appearAfter),
              if (showSecondaryTrailingLine) ...[
                SizedBox(height: 5.h),
                SkeletonBox(width: 22.w, height: 8.h, appearAfter: appearAfter),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
