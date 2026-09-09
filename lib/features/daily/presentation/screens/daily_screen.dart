import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/daily/data/daily_api.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';
import 'package:quizoo/features/daily/presentation/bloc/daily_cubit.dart';
import 'package:quizoo/features/daily/presentation/widgets/milestone_row.dart';
import 'package:quizoo/features/daily/presentation/widgets/streak_week_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-27 — the Daily tab.
class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailyCubit>(
      create: (_) => DailyCubit(DailyRepository(DailyApi(supabase)))..load(),
      child: const _DailyView(),
    );
  }
}

class _DailyView extends StatelessWidget {
  const _DailyView();

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BlocBuilder<DailyCubit, DailyState>(
              buildWhen: (previous, current) =>
                  current is DailyLoaded || previous is! DailyLoaded,
              builder: (context, state) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin.w,
                  vertical: AppSpacing.sm.h,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.dailyTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            DateFormat(
                              'EEEE, d MMMM',
                              Localizations.localeOf(context).toLanguageTag(),
                            ).format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: quizoo.tx2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (state case DailyLoaded(:final streak))
                      AppChip.status(
                        label: l10n.dailyStreakChip(streak.currentStreak),
                        leading: '🔥',
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<DailyCubit, DailyState>(
                builder: (context, state) => switch (state) {
                  DailyInitial() || DailyLoading() => const _DailySkeleton(),
                  DailyError(:final error) => _DailyError(error: error),
                  DailyLoaded() => _DailyContent(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyContent extends StatelessWidget {
  const _DailyContent({required this.state});

  final DailyLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.xl.h),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: _TodayChallengeCard(challenge: state.challenge),
        ),
        SizedBox(height: AppSpacing.xl.h),
        SectionHeader(
          title: l10n.dailyYourStreak,
          actionLabel: l10n.dailyRules,
          onActionPressed: () => AppSnackbar.show(
            context,
            title: l10n.dailyRulesUnavailable,
            intent: SnackbarIntent.info,
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: _StreakCard(streak: state.streak),
        ),
        SizedBox(height: AppSpacing.xl.h),
        SectionHeader(title: l10n.dailyMilestones),
        SizedBox(height: AppSpacing.sm.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Column(
            children: [
              for (final milestone in state.streak.milestones)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: MilestoneRow(milestone: milestone),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayChallengeCard extends StatelessWidget {
  const _TodayChallengeCard({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardAll,
        boxShadow: quizoo.shadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.base.w + 2.w),
              decoration: BoxDecoration(
                gradient: AppGradients.linear(140, const [
                  Color(0xFFFF8A24),
                  Color(0xFFFF3D6E),
                ]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dailyTodaysChallenge,
                    style: textTheme.labelSmall!.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    challenge.title,
                    style: textTheme.displayMedium!.copyWith(
                      fontSize: 24.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    l10n.dailyQuestionsMeta(
                      challenge.questionCount,
                      challenge.categoryCount,
                      challenge.secondsPerQuestion,
                    ),
                    style: textTheme.bodyMedium!.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Wrap(
                    spacing: AppSpacing.sm.w,
                    runSpacing: AppSpacing.xs.h,
                    children: [
                      _RewardChip(label: '🪙 ${challenge.coinReward}'),
                      _RewardChip(label: '⚡ ${challenge.xpReward} XP'),
                      _RewardChip(
                        label:
                            '⏳ ${l10n.dailyTimeRemaining(challenge.timeRemaining.inHours, challenge.timeRemaining.inMinutes.remainder(60))}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.base.w - 1.w),
              color: quizoo.s1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.dailyPlayedToday(
                          AppFormat.number(
                            challenge.playedTodayCount,
                            localeName,
                          ),
                        ),
                        style: textTheme.labelSmall,
                      ),
                      Text(
                        l10n.dailyAverage(
                          challenge.averageCorrect,
                          challenge.averageOutOf,
                        ),
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  ChunkyButton(
                    label: l10n.dailyPlayNow,
                    onPressed: () => context.push(AppRoutes.dailyResult),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final StreakStatus streak;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
          StreakWeekRow(days: streak.days),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
            child: Divider(height: 1, color: quizoo.ln),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🛡️', style: AppTypography.glyph(22.sp)),
              SizedBox(width: AppSpacing.sm.w + 2.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      color: quizoo.tx2,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: l10n.dailyFreezesLeft(streak.freezesLeft),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: quizoo.tx,
                        ),
                      ),
                      TextSpan(text: ' ${l10n.dailyFreezeExplainer}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailySkeleton extends StatelessWidget {
  const _DailySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.base.h),
          SkeletonBox(height: 168.h),
          SizedBox(height: AppSpacing.xl.h),
          SkeletonBox(width: 120.w, height: 20.h),
          SizedBox(height: AppSpacing.md.h),
          SkeletonBox(height: 140.h),
        ],
      ),
    );
  }
}

class _DailyError extends StatelessWidget {
  const _DailyError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: l10n.contentErrorBody,
        action: ChunkyButton(
          label: l10n.commonRetry,
          onPressed: () => context.read<DailyCubit>().load(),
        ),
      ),
    );
  }
}
