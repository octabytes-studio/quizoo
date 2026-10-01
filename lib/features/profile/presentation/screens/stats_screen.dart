import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/anchored_banner_ad.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/distribution_chart.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/profile/data/profile_api.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/stats_summary.dart';
import 'package:quizoo/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:quizoo/features/profile/presentation/widgets/category_accuracy_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-35 — Your stats.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatsCubit>(
      create: (_) =>
          StatsCubit(ProfileRepository(ProfileApi(supabase)))..load(),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

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
            SimpleTopBar(
              title: l10n.statsTitle,
              trailing: GestureDetector(
                onTap: () => AppSnackbar.show(
                  context,
                  title: l10n.commonMockFeature,
                  intent: SnackbarIntent.info,
                ),
                behavior: HitTestBehavior.opaque,
                // S-35's range picker is non-functional mock chrome in this
                // phase — a real recompute is out of scope (plan 003,
                // Assumption 3).
                child: AppChip.status(label: l10n.statsRangeChip),
              ),
            ),
            Expanded(
              child: BlocBuilder<StatsCubit, StatsState>(
                builder: (context, state) => switch (state) {
                  StatsInitial() || StatsLoading() => const _StatsSkeleton(),
                  StatsError(:final error) => _StatsError(error: error.code),
                  StatsLoaded(:final stats) => _StatsContent(stats: stats),
                },
              ),
            ),
          ],
        ),
      ),
      // Only beside real content (plan 022, B3).
      bottomNavigationBar: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) => AnchoredBannerAd(
          placement: AdPlacement.statsBanner,
          isVisible: switch (state) {
            StatsLoaded() => true,
            StatsInitial() || StatsLoading() || StatsError() => false,
          },
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final StatsSummary stats;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final weakest = stats.weakest;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        0,
        AppSpacing.screenMargin.w,
        AppSpacing.xl.h,
      ),
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.base.w - 1.w),
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: quizoo.ln),
            boxShadow: quizoo.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.statsPointsPerDay,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              SizedBox(height: AppSpacing.md.h),
              DistributionChart(
                barPercents: stats.pointsPerDayPercents,
                labels: l10n.statsWeekdayLabels.split(','),
                highlightedIndex: stats.todayIndex,
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl.h),
        SectionHeader(title: l10n.statsAccuracyByCategory),
        SizedBox(height: AppSpacing.md.h),
        for (final accuracy in stats.categoryAccuracies)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md.h - 1.h),
            child: CategoryAccuracyRow(accuracy: accuracy),
          ),
        SizedBox(height: AppSpacing.sm.h),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w - 1.w,
            vertical: AppSpacing.md.h + 1.h,
          ),
          decoration: BoxDecoration(
            color: quizoo.p.withValues(alpha: 0.1),
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: quizoo.p.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡', style: AppTypography.glyph(24.sp)),
              SizedBox(width: AppSpacing.md.w - 1.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      color: quizoo.tx2,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${l10n.statsCoachingIntro(weakest.categoryName)} ',
                      ),
                      TextSpan(
                        text: '${l10n.statsCoachingBold} ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: quizoo.tx,
                        ),
                      ),
                      TextSpan(
                        text: l10n.statsCoachingOutcome(
                          weakest.accuracyPercent + 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl.h),
        SectionHeader(title: l10n.statsFastestAnswers),
        SizedBox(height: AppSpacing.md.h),
        ListRowTile(
          title: l10n.statsFastestAverage(
            stats.fastestAverageSeconds.toStringAsFixed(1),
          ),
          subtitle:
              '${stats.fastestSubcategoryName} · Level ${stats.fastestLevelNumber}',
          leadingEmoji: '⚡',
          trailingValue: stats.fastestPercentileLabel,
        ),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        children: [
          SizedBox(height: AppSpacing.md.h),
          SkeletonBox(height: 140.h),
          SizedBox(height: AppSpacing.xl.h),
          SkeletonBox(height: 100.h),
        ],
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.error});

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
          onPressed: () => context.read<StatsCubit>().load(),
        ),
      ),
    );
  }
}
