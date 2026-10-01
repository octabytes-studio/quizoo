import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/anchored_banner_ad.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/achievements/data/achievements_api.dart';
import 'package:quizoo/features/achievements/data/achievements_repository.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:quizoo/features/achievements/presentation/bloc/achievements_cubit.dart';
import 'package:quizoo/features/achievements/presentation/widgets/badge_detail_dialog.dart';
import 'package:quizoo/features/achievements/presentation/widgets/badge_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-33 — the achievements grid.
///
/// [initialBadgeId] is set only when the route was reached at S-34's own
/// path (`/you/achievements/:badgeId`) — a dialog has no screen of its own,
/// so, exactly as S-09's level-brief sheet opens the level map underneath
/// it, this opens the grid with that badge's detail dialog already
/// presented.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, this.initialBadgeId});

  final String? initialBadgeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AchievementsCubit>(
      create: (_) =>
          AchievementsCubit(AchievementsRepository(AchievementsApi(supabase)))
            ..load(),
      child: _AchievementsView(initialBadgeId: initialBadgeId),
    );
  }
}

class _AchievementsView extends StatefulWidget {
  const _AchievementsView({this.initialBadgeId});

  final String? initialBadgeId;

  @override
  State<_AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<_AchievementsView> {
  bool _hasShownInitialBadge = false;

  void _maybeShowInitialBadge(BuildContext context, AchievementsState state) {
    final badgeId = widget.initialBadgeId;
    if (badgeId == null ||
        _hasShownInitialBadge ||
        state is! AchievementsLoaded) {
      return;
    }
    final match = state.all.where((progress) => progress.badge.id == badgeId);
    if (match.isEmpty) return;
    _hasShownInitialBadge = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BadgeDetailDialog.show(context, match.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocConsumer<AchievementsCubit, AchievementsState>(
              listener: _maybeShowInitialBadge,
              builder: (context, state) => SimpleTopBar(
                title: l10n.achievementsTitle,
                subtitle: state is AchievementsLoaded
                    ? l10n.achievementsUnlockedCount(
                        state.unlockedCount,
                        state.all.length,
                      )
                    : null,
              ),
            ),
            Expanded(
              child: BlocBuilder<AchievementsCubit, AchievementsState>(
                builder: (context, state) => switch (state) {
                  AchievementsInitial() ||
                  AchievementsLoading() => const _AchievementsSkeleton(),
                  AchievementsError(:final error) => _AchievementsError(
                    error: error.code,
                  ),
                  AchievementsLoaded() => _AchievementsLoadedView(state: state),
                },
              ),
            ),
          ],
        ),
      ),
      // Only beside real content (plan 022, B4).
      bottomNavigationBar: BlocBuilder<AchievementsCubit, AchievementsState>(
        builder: (context, state) => AnchoredBannerAd(
          placement: AdPlacement.achievementsBanner,
          isVisible: switch (state) {
            AchievementsLoaded() => true,
            AchievementsInitial() ||
            AchievementsLoading() ||
            AchievementsError() => false,
          },
        ),
      ),
    );
  }
}

class _AchievementsLoadedView extends StatelessWidget {
  const _AchievementsLoadedView({required this.state});

  final AchievementsLoaded state;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AchievementsCubit>();
    final progressValue = state.all.isEmpty
        ? 0.0
        : state.unlockedCount / state.all.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: SizedBox(
              height: 6.h,
              child: LinearProgressIndicator(
                value: progressValue.clamp(0, 1),
                backgroundColor: quizoo.s3,
                valueColor: AlwaysStoppedAnimation<Color>(quizoo.g),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.base.h),
        SizedBox(
          height: AppChip.categoryHeight.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            itemCount: BadgeCategory.values.length + 1,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm.w),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AppChip(
                  label: l10n.achievementsFilterAll,
                  isSelected: state.filter == null,
                  onTap: () => cubit.selectFilter(null),
                );
              }
              final filter = BadgeCategory.values[index - 1];
              return AppChip(
                label: _filterLabel(l10n, filter),
                isSelected: state.filter == filter,
                onTap: () => cubit.selectFilter(filter),
              );
            },
          ),
        ),
        SizedBox(height: AppSpacing.base.h),
        Expanded(
          child: state.visible.isEmpty
              ? EmptyStateView(
                  emoji: '🏅',
                  title: l10n.achievementsEmptyTitle,
                  message: l10n.achievementsEmptyBody,
                )
              : GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin.w,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: AppSpacing.sm.w,
                    mainAxisSpacing: AppSpacing.md.h,
                    mainAxisExtent: 100.h,
                  ),
                  itemCount: state.visible.length,
                  itemBuilder: (context, index) {
                    final progress = state.visible[index];
                    return BadgeTile(
                      progress: progress,
                      onTap: () => BadgeDetailDialog.show(context, progress),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _filterLabel(AppLocalizations l10n, BadgeCategory filter) =>
      switch (filter) {
        BadgeCategory.skill => l10n.achievementsFilterSkill,
        BadgeCategory.streak => l10n.achievementsFilterStreak,
        BadgeCategory.social => l10n.achievementsFilterSocial,
        BadgeCategory.rare => l10n.achievementsFilterRare,
      };
}

class _AchievementsSkeleton extends StatelessWidget {
  const _AchievementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        children: [
          SkeletonBox(height: 6.h),
          SizedBox(height: AppSpacing.xl.h),
          SkeletonBox(height: 200.h),
        ],
      ),
    );
  }
}

class _AchievementsError extends StatelessWidget {
  const _AchievementsError({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: l10n.contentErrorBody,
        errorCode: error,
        action: ChunkyButton(
          label: l10n.commonRetry,
          onPressed: () => context.read<AchievementsCubit>().load(),
        ),
      ),
    );
  }
}
