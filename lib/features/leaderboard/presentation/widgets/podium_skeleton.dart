import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/podium.dart';

/// [Podium]'s shimmer stand-in — same three plinth heights, same avatar
/// size, same column rhythm — shown immediately (see
/// [LeaderboardRowSkeleton]'s doc comment on why zero-delay matters here).
class PodiumSkeleton extends StatelessWidget {
  const PodiumSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PlaceSkeleton(plinthHeight: Podium.secondPlinth)),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(child: _PlaceSkeleton(plinthHeight: Podium.firstPlinth)),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(child: _PlaceSkeleton(plinthHeight: Podium.thirdPlinth)),
        ],
      ),
    );
  }
}

class _PlaceSkeleton extends StatelessWidget {
  const _PlaceSkeleton({required this.plinthHeight});

  final double plinthHeight;

  static const double avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBox(
          width: avatarSize.w,
          height: avatarSize.w,
          borderRadius: BorderRadius.circular(avatarSize.w),
          appearAfter: Duration.zero,
        ),
        SizedBox(height: 6.h),
        SkeletonBox(width: 44.w, height: 11.h, appearAfter: Duration.zero),
        SizedBox(height: 4.h),
        SkeletonBox(width: 30.w, height: 9.h, appearAfter: Duration.zero),
        SizedBox(height: AppSpacing.sm.h),
        SkeletonBox(
          width: double.infinity,
          height: plinthHeight.h,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.tile.r),
          ),
          appearAfter: Duration.zero,
        ),
      ],
    );
  }
}
