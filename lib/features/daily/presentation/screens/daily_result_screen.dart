import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/distribution_chart.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/result_wash.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/features/daily/data/daily_api.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/daily/presentation/bloc/daily_result_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-28 — the daily challenge's result.
///
/// There is no prior play screen to hand this a run (see [DailyResultCubit]):
/// this screen both plays and scores today's challenge the moment it opens.
class DailyResultScreen extends StatelessWidget {
  const DailyResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailyResultCubit>(
      create: (_) => DailyResultCubit(DailyRepository(DailyApi()))..play(),
      child: BlocBuilder<DailyResultCubit, DailyResultState>(
        builder: (context, state) => switch (state) {
          DailyResultLoading() => const _DailyResultSpinner(),
          DailyResultError(:final error) => _DailyResultError(
            errorCode: error.code,
          ),
          DailyResultLoaded(:final result) => _DailyResultLoadedView(
            result: result,
          ),
        },
      ),
    );
  }
}

class _DailyResultSpinner extends StatelessWidget {
  const _DailyResultSpinner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.quizoo.s0,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DailyResultError extends StatelessWidget {
  const _DailyResultError({required this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.quizoo.s0,
      body: SafeArea(
        child: Center(
          child: ErrorStateView(
            title: l10n.contentErrorTitle,
            emoji: '🎯',
            message: l10n.contentErrorBody,
            errorCode: errorCode,
            action: ChunkyButton.ghost(
              label: l10n.commonBack,
              onPressed: context.pop,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyResultLoadedView extends StatelessWidget {
  const _DailyResultLoadedView({required this.result});

  final DailyResult result;

  void _share(BuildContext context) {
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => ShareSheet(
        title: AppLocalizations.of(sheetContext).dailyResultShareTitle,
        message: AppLocalizations.of(sheetContext).shareSpoilerFree,
        preview: _SharePreview(result: result),
        targets: [
          ShareTarget(
            emoji: '💬',
            label: 'WhatsApp',
            onTap: () => _confirmShared(sheetContext),
          ),
          ShareTarget(
            emoji: '✖️',
            label: 'X',
            onTap: () => _confirmShared(sheetContext),
          ),
          ShareTarget(
            emoji: '🔗',
            label: 'Copy',
            onTap: () => _confirmShared(sheetContext),
          ),
        ],
      ),
    );
  }

  void _confirmShared(BuildContext context) {
    Navigator.of(context).maybePop();
    AppSnackbar.show(
      context,
      title: AppLocalizations.of(context).commonSharedMock,
      intent: SnackbarIntent.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ResultWash(
      accent: quizoo.g,
      onClose: context.pop,
      onShare: () => _share(context),
      actions: [
        ChunkyButton.secondary(
          label: l10n.dailyResultShare,
          onPressed: () => _share(context),
        ),
        SizedBox(height: 9.h),
        ChunkyButton.line(
          label: l10n.dailyResultBackToDaily,
          onPressed: context.pop,
        ),
      ],
      child: Column(
        children: [
          Text('🎯', style: AppTypography.glyph(48.sp)),
          Text(
            l10n.dailyResultScoreLine(result.correctCount, result.totalCount),
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 25.sp,
              color: Colors.white,
            ),
          ),
          Text(
            l10n.dailyResultBetterThan(result.betterThanPercent),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppSpacing.base.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              color: quizoo.s1,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              boxShadow: quizoo.shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dailyResultDistribution, style: textTheme.labelSmall),
                SizedBox(height: AppSpacing.sm.h),
                DistributionChart(
                  barPercents: result.distributionPercents,
                  labels: const ['0-2', '3-4', '5-6', '7-8', '9-10'],
                  highlightedIndex: result.highlightedBucketIndex,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                  child: Divider(height: 1, color: quizoo.ln),
                ),
                Row(
                  children: [
                    _ResultStat(
                      value: '🪙 ${result.coinsEarned}',
                      label: l10n.dailyResultEarned,
                      color: quizoo.gold,
                    ),
                    _ResultStat(
                      value: '🔥 ${result.streakNow}',
                      label: l10n.dailyResultStreakNow,
                      color: quizoo.p,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 19.sp,
              color: color,
            ),
          ),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// The card shared to the OS's share sheet — the spoiler-free emoji grid.
class _SharePreview extends StatelessWidget {
  const _SharePreview({required this.result});

  final DailyResult result;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: quizoo.s2,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: quizoo.ln),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyResultScoreLine(result.correctCount, result.totalCount),
            style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            result.shareGrid,
            style: AppTypography.glyph(18.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}
