import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_api.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/category_leaderboard_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/leaderboard_row_skeleton.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-30 — a single subcategory's own leaderboard.
///
/// The route's `categoryId` path parameter (reserved by plan 001's router)
/// actually names a *subcategory* here — Football, not Sports — matching the
/// bible's own frame; renaming the shared route constant is out of this
/// plan's scope (CLAUDE.md §10: shared router files are only added to).
class CategoryLeaderboardScreen extends StatelessWidget {
  const CategoryLeaderboardScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoryLeaderboardCubit>(
      create: (_) => CategoryLeaderboardCubit(
        LeaderboardRepository(LeaderboardApi(supabase)),
      )..load(categoryId),
      child: _CategoryLeaderboardView(subcategoryId: categoryId),
    );
  }
}

class _CategoryLeaderboardView extends StatelessWidget {
  const _CategoryLeaderboardView({required this.subcategoryId});

  final String subcategoryId;

  Subcategory get _subcategory {
    try {
      return MockCatalog.subcategoryById(subcategoryId);
    } on StateError {
      return MockCatalog.subcategoryById(MockCatalog.footballId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final subcategory = _subcategory;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimpleTopBar(
              title: subcategory.name,
              subtitle: l10n.categoryLeaderboardSubtitle,
            ),
            Expanded(
              child:
                  BlocBuilder<
                    CategoryLeaderboardCubit,
                    CategoryLeaderboardState
                  >(
                    builder: (context, state) => switch (state) {
                      CategoryLeaderboardInitial() ||
                      CategoryLeaderboardLoading() => const _CategorySkeleton(),
                      CategoryLeaderboardError(:final error) => _CategoryError(
                        error: error.code,
                      ),
                      CategoryLeaderboardLoaded() => _CategoryLoaded(
                        state: state,
                        subcategory: subcategory,
                      ),
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLoaded extends StatelessWidget {
  const _CategoryLoaded({required this.state, required this.subcategory});

  final CategoryLeaderboardLoaded state;
  final Subcategory subcategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final category = MockCatalog.categoryById(subcategory.categoryId);
    final nextLevel = subcategory.levelsCleared + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            0,
            AppSpacing.screenMargin.w,
            AppSpacing.base.h,
          ),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.base.w - 2.w),
            decoration: BoxDecoration(
              gradient: AppGradients.tileFromHex(
                category.colorFrom,
                category.colorTo,
              ),
              borderRadius: AppRadius.cardAll,
            ),
            child: Row(
              children: [
                Text('🏅', style: AppTypography.glyph(32.sp)),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.selfRank == 0
                            ? l10n.categoryLeaderboardUnranked
                            : l10n.categoryLeaderboardRank(
                                state.selfRank,
                                state.countryName,
                              ),
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontSize: 16.sp, color: Colors.white),
                      ),
                      Text(
                        state.selfRank == 0
                            ? l10n.categoryLeaderboardUnrankedBody
                            : l10n.categoryLeaderboardGap(
                                AppFormat.number(
                                  state.pointsFromTop,
                                  localeName,
                                ),
                              ),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 11.5.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: state.roster.isEmpty
              ? EmptyStateView(
                  emoji: '🏆',
                  title: l10n.categoryLeaderboardEmptyTitle,
                  message: l10n.categoryLeaderboardEmptyBody,
                )
              : ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin.w,
                  ),
                  children: [
                    for (final entry in state.roster)
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                        child: ListRowTile(
                          variant: ListRowVariant.player,
                          title: entry.name,
                          subtitle: entry.levelsLabel,
                          leadingEmoji: entry.avatarEmoji,
                          trailingValue: AppFormat.number(
                            entry.score,
                            localeName,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            0,
            AppSpacing.screenMargin.w,
            AppSpacing.sm.h,
          ),
          child: ChunkyButton(
            label: l10n.categoryLeaderboardPlay(subcategory.name, nextLevel),
            onPressed: () => context.push(
              AppRoutes.countdownPath(
                MockCatalog.levelId(subcategory.id, nextLevel),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      children: [
        SizedBox(height: AppSpacing.md.h),
        SkeletonBox(
          height: 76.h,
          borderRadius: AppRadius.cardAll,
          appearAfter: Duration.zero,
        ),
        SizedBox(height: AppSpacing.lg.h),
        for (var i = 0; i < 6; i++)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
            child: const LeaderboardRowSkeleton(
              showSecondaryTrailingLine: false,
            ),
          ),
      ],
    );
  }
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.error});

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
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}
