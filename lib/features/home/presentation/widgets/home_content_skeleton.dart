import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/category_section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/core/widgets/subcategory_card.dart';
import 'package:quizoo/features/home/presentation/widgets/popular_quiz_card.dart';

/// S-45 — Home's loading skeleton, shape-matched to the loaded body (plan
/// 021).
///
/// Covers the body only: the top bar and the language row are real chrome
/// and "are *never* skeletons" (bible S-45). Mirrors `_HomeContentView`
/// piece by piece — the Popular header, separate popular cards bleeding off
/// the rail, the banner block, then two category sections with medallion,
/// title, hairline and bleeding subcategory cards.
class HomeContentSkeleton extends StatelessWidget {
  const HomeContentSkeleton({super.key});

  /// Bible S-45's banner block.
  static const double bannerHeight = 62;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBox(width: 150.w, height: 16.h),
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        const _SkeletonRail(
          itemWidth: PopularQuizCard.width,
          itemHeight: PopularQuizCard.height,
          radius: AppRadius.card,
        ),
        SizedBox(height: AppSpacing.lg.h - 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: SkeletonBox(
            height: bannerHeight.h,
            borderRadius: BorderRadius.circular(AppRadius.card.r),
          ),
        ),
        const _SkeletonCategorySection(isFirst: true),
        const _SkeletonCategorySection(isFirst: false),
      ],
    );
  }
}

/// A fixed three-card rail whose third card bleeds off-screen, exactly like
/// the real rails.
class _SkeletonRail extends StatelessWidget {
  const _SkeletonRail({
    required this.itemWidth,
    required this.itemHeight,
    required this.radius,
  });

  /// Unscaled design-size values — scaled here.
  final double itemWidth;
  final double itemHeight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
        itemCount: 3,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
        itemBuilder: (_, _) => SkeletonBox(
          width: itemWidth.w,
          height: itemHeight.h,
          borderRadius: BorderRadius.circular(radius.r),
        ),
      ),
    );
  }
}

/// Mirrors `_CategorySection`'s spacing: the top gap, the `.hr` hairline for
/// every section but the first, the `.catline` header row, then the rail.
class _SkeletonCategorySection extends StatelessWidget {
  const _SkeletonCategorySection({required this.isFirst});

  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final medallion = CategorySectionHeader.medallionSize.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isFirst ? AppSpacing.lg.h - 2.h : AppSpacing.md.h),
        if (!isFirst) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            child: ColoredBox(
              color: quizoo.ln,
              child: SizedBox(height: 1.h, width: double.infinity),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Row(
            children: [
              SkeletonBox(
                width: medallion,
                height: medallion,
                borderRadius: BorderRadius.circular(AppRadius.medallion.r),
              ),
              SizedBox(width: AppSpacing.sm.w),
              SkeletonBox(width: 120.w, height: 16.h),
              const Spacer(),
              SkeletonBox(width: 56.w, height: 12.h),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        const _SkeletonRail(
          itemWidth: SubcategoryCard.railWidth,
          itemHeight: SubcategoryCard.railHeight,
          radius: AppRadius.tile,
        ),
      ],
    );
  }
}
