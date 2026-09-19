import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/segmented_tabs.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_api.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_scope.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/leaderboard_row_skeleton.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/pinned_self_row.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/podium.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/podium_skeleton.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-29 — the global/country/friends leaderboard.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeaderboardCubit>(
      create: (_) =>
          LeaderboardCubit(LeaderboardRepository(LeaderboardApi(supabase)))
            ..load(),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<LeaderboardCubit>();

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin.w,
                vertical: AppSpacing.sm.h,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.leaderboardTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _SearchButton(
                    onTap: () => AppSnackbar.show(
                      context,
                      title: l10n.commonMockFeature,
                      intent: SnackbarIntent.info,
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<LeaderboardCubit, LeaderboardState>(
              buildWhen: (previous, current) => current is LeaderboardLoaded,
              builder: (context, state) {
                final scope = state is LeaderboardLoaded
                    ? state.scope
                    : LeaderboardScope.global;
                final period = state is LeaderboardLoaded
                    ? state.period
                    : LeaderboardPeriod.week;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenMargin.w,
                      ),
                      child: SegmentedTabs(
                        labels: [
                          l10n.leaderboardScopeGlobal,
                          l10n.leaderboardScopeCountry,
                          l10n.leaderboardScopeFriends,
                        ],
                        selectedIndex: scope.index,
                        onChanged: (index) =>
                            cubit.changeScope(LeaderboardScope.values[index]),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    SizedBox(
                      height: AppChip.categoryHeight.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenMargin.w,
                        ),
                        itemCount: LeaderboardPeriod.values.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(width: AppSpacing.sm.w),
                        itemBuilder: (context, index) {
                          final value = LeaderboardPeriod.values[index];
                          return AppChip(
                            label: _periodLabel(l10n, value),
                            isSelected: value == period,
                            onTap: () => cubit.changePeriod(value),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
                builder: (context, state) => switch (state) {
                  LeaderboardInitial() ||
                  LeaderboardLoading() => const _LeaderboardSkeleton(),
                  LeaderboardError(:final error) => _LeaderboardError(
                    error: error.code,
                  ),
                  LeaderboardLoaded() => _LeaderboardRoster(state: state),
                },
              ),
            ),
            BlocBuilder<SessionCubit, SessionState>(
              builder: (context, session) =>
                  BlocBuilder<LeaderboardCubit, LeaderboardState>(
                    buildWhen: (previous, current) =>
                        current is LeaderboardLoaded,
                    builder: (context, lbState) {
                      if (lbState is! LeaderboardLoaded) {
                        return const SizedBox.shrink();
                      }
                      final isGuest = session is SessionGuest;
                      return PinnedSelfRow(
                        isGuest: isGuest,
                        entry: isGuest ? null : lbState.selfEntry,
                        onSignInTap: isGuest
                            ? () => context.push(AppRoutes.saveProgress)
                            : null,
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static String _periodLabel(AppLocalizations l10n, LeaderboardPeriod period) =>
      switch (period) {
        LeaderboardPeriod.week => l10n.leaderboardPeriodWeek,
        LeaderboardPeriod.month => l10n.leaderboardPeriodMonth,
        LeaderboardPeriod.allTime => l10n.leaderboardPeriodAllTime,
      };
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).homeSeeAll,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38.w,
          height: 38.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: quizoo.ln),
          ),
          child: const Text('🔍'),
        ),
      ),
    );
  }
}

class _LeaderboardRoster extends StatelessWidget {
  const _LeaderboardRoster({required this.state});

  final LeaderboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final podium = state.podium;
    final rows = state.remainingRows;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    if (state.roster.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyStateView(
        emoji: '🏆',
        title: l10n.leaderboardEmptyTitle,
        message: l10n.leaderboardEmptyBody,
        action: ChunkyButton(
          label: l10n.leaderboardEmptyCta,
          onPressed: () => context.go(AppRoutes.home),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(top: AppSpacing.md.h, bottom: AppSpacing.md.h),
      children: [
        if (podium.length == 3)
          Podium(first: podium[0], second: podium[1], third: podium[2]),
        SizedBox(height: AppSpacing.lg.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Column(
            children: [
              for (final entry in rows)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: _LeaderboardRow(entry: entry, localeName: localeName),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.localeName});

  final LeaderboardEntry entry;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final delta = entry.rankDelta;
    final deltaColor = delta == null || delta == 0
        ? quizoo.tx3
        : delta > 0
        ? quizoo.ok
        : quizoo.bad;
    final deltaLabel = delta == null || delta == 0
        ? '—'
        : delta > 0
        ? '▲ $delta'
        : '▼ ${delta.abs()}';

    return ListRowTile(
      variant: ListRowVariant.player,
      title: entry.name,
      subtitle: entry.locationLabel,
      leadingEmoji: entry.avatarEmoji,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppFormat.number(entry.score, localeName),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w800,
              color: quizoo.tx,
            ),
          ),
          Text(
            deltaLabel,
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(color: deltaColor),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: AppSpacing.md.h, bottom: AppSpacing.md.h),
      children: [
        const PodiumSkeleton(),
        SizedBox(height: AppSpacing.lg.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Column(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: const LeaderboardRowSkeleton(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError({required this.error});

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
          onPressed: () => context.read<LeaderboardCubit>().load(),
        ),
      ),
    );
  }
}
