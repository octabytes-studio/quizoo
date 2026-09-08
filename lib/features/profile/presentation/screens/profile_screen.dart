import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/profile/data/profile_api.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quizoo/features/profile/presentation/widgets/stat_strip.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-32 — Profile.
///
/// A public profile (reached by tapping another player from a leaderboard or
/// friends row) is "the same layout minus settings and wallet" — the same
/// screen with [isOwnProfile] gating the settings gear, rather than a
/// duplicate screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.isOwnProfile = true});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) =>
          ProfileCubit(ProfileRepository(ProfileApi(supabase)))..load(),
      child: _ProfileView(isOwnProfile: isOwnProfile),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.isOwnProfile});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileInitial() || ProfileLoading() => const _ProfileSkeleton(),
          ProfileError(:final error) => _ProfileError(error: error.code),
          ProfileLoaded(:final summary) => _ProfileLoadedView(
            summary: summary,
            isOwnProfile: isOwnProfile,
          ),
        },
      ),
    );
  }
}

class _ProfileLoadedView extends StatelessWidget {
  const _ProfileLoadedView({required this.summary, required this.isOwnProfile});

  final ProfileSummary summary;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(summary: summary, isOwnProfile: isOwnProfile),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin.w,
              AppSpacing.base.h,
              AppSpacing.screenMargin.w,
              AppSpacing.xl.h,
            ),
            children: [
              StatStrip(
                stats: [
                  (
                    AppFormat.compact(summary.totalPoints, localeName),
                    l10n.profileStatPoints,
                  ),
                  ('${summary.totalLevels}', l10n.profileStatLevels),
                  ('${summary.accuracyPercent}%', l10n.profileStatAccuracy),
                  ('${summary.badgeCount}', l10n.profileStatBadges),
                ],
              ),
              SizedBox(height: AppSpacing.xl.h),
              SectionHeader(
                title: l10n.profileRecentBadges,
                actionLabel: l10n.profileAllBadges(summary.badgeCount),
                onActionPressed: () => context.push(AppRoutes.achievements),
              ),
              SizedBox(height: AppSpacing.md.h),
              SizedBox(
                height: 96.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: summary.recentBadges.length,
                  separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
                  itemBuilder: (context, index) {
                    final badge = summary.recentBadges[index];
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
              SizedBox(height: AppSpacing.xl.h),
              SectionHeader(title: l10n.profileBestCategories),
              SizedBox(height: AppSpacing.md.h),
              for (final entry in summary.bestCategories)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: ListRowTile(
                    title: entry.name,
                    subtitle: l10n.profileBestCategoryMeta(
                      entry.levelsCleared,
                      entry.levelCount,
                      entry.starsEarned,
                    ),
                    leadingEmoji: entry.emoji,
                    leadingPlateColor: AppGradients.hex(entry.plateColor),
                    trailingValue: '${entry.accuracyPercent}%',
                    trailingLabel: l10n.profileAccuracyLabel,
                    onTap: () {
                      final subcategory = MockCatalog.subcategoryById(
                        entry.subcategoryId,
                      );
                      context.push(
                        AppRoutes.levelMapPath(
                          subcategory.categoryId,
                          subcategory.id,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.bleed` — the full-bleed cosmic grape→sky header. The XP bar sits inside
/// this gradient "so progress reads as part of who you are, not a widget"
/// (bible, S-32).
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.summary, required this.isOwnProfile});

  final ProfileSummary summary;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.tile(
            const Color(0xFF7B4DFF),
            const Color(0xFF2BB3FF),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin.w,
              6.h,
              AppSpacing.screenMargin.w,
              AppSpacing.base.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    if (isOwnProfile)
                      Semantics(
                        button: true,
                        label: l10n.profileSettings,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.settings),
                          behavior: HitTestBehavior.opaque,
                          child: Text('⚙️', style: AppTypography.glyph(17.sp)),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 74.w,
                      height: 74.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: Text(
                        summary.avatarEmoji,
                        style: AppTypography.glyph(37.sp),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w + 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            summary.username,
                            style: textTheme.displayMedium!.copyWith(
                              fontSize: 22.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${summary.cityLabel} · ${summary.joinedLabel}',
                            style: textTheme.bodyMedium!.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(height: 7.h),
                          Row(
                            children: [
                              AppChip.status(
                                label:
                                    '${summary.leagueEmoji} ${summary.leagueName}',
                              ),
                              SizedBox(width: AppSpacing.xs.w + 2.w),
                              AppChip.status(label: '🔥 ${summary.dayStreak}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.base.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.profileLevelLine(
                          summary.playerLevel,
                          summary.rankTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Text(
                      '${summary.xpIntoLevel} / ${summary.xpToNextLevel} XP',
                      maxLines: 1,
                      style: textTheme.labelSmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: SizedBox(
                    height: 6.h,
                    child: LinearProgressIndicator(
                      value: summary.xpProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFC61A),
                      ),
                    ),
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

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xl.h),
            SkeletonBox(height: 130.h),
            SizedBox(height: AppSpacing.xl.h),
            SkeletonBox(height: 84.h),
            SizedBox(height: AppSpacing.xl.h),
            SkeletonBox(height: 96.h),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Center(
        child: ErrorStateView(
          title: l10n.contentErrorTitle,
          emoji: '🛰️',
          message: l10n.contentErrorBody,
          errorCode: error,
          action: ChunkyButton(
            label: l10n.commonRetry,
            onPressed: () => context.read<ProfileCubit>().load(),
          ),
        ),
      ),
    );
  }
}
