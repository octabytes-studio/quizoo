import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_badge.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/native_ad_tile.dart';
import 'package:quizoo/core/widgets/player_actions_sheet.dart';
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
              child: Text(
                l10n.leaderboardTitle,
                style: Theme.of(context).textTheme.titleLarge,
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

class _LeaderboardRoster extends StatelessWidget {
  const _LeaderboardRoster({required this.state});

  final LeaderboardLoaded state;

  /// Plan 025: the shared report/block sheet, then a reload so a block
  /// disappears (or an unblock returns) immediately. Own rows are never
  /// offered this — self-block is meaningless and the DB rejects it.
  Future<void> _openPlayerActions(
    BuildContext context,
    LeaderboardEntry entry,
  ) async {
    if (entry.isSelf) return;
    final changed = await PlayerActionsSheet.show(
      context,
      playerId: entry.playerId,
      playerName: entry.name,
      // Rosters are already filtered by the viewer's block list, so a
      // player visible here is by definition not blocked.
      isBlocked: false,
    );
    if (changed != true || !context.mounted) return;
    context.read<LeaderboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final podium = state.podium;
    final rows = state.remainingRows;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    // The native row sits this many rows down the list — clear of the podium
    // above and the pinned self row below (plan 022, N2). Null: no ad.
    final adAfterRow = context.select<AdsCubit, int?>(
      (cubit) => switch (cubit.state) {
        AdsReady(:final config)
            when cubit.isPlacementEnabled(AdPlacement.ranksFeedNative) &&
                rows.length > config.ranksNativeAfterRow =>
          config.ranksNativeAfterRow,
        AdsInitial() || AdsDisabled() || AdsReady() => null,
      },
    );

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
          Podium(
            first: podium[0],
            second: podium[1],
            third: podium[2],
            onTap: (entry) => _openPlayerActions(context, entry),
          ),
        SizedBox(height: AppSpacing.lg.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Column(
            children: [
              for (final (index, entry) in rows.indexed) ...[
                if (index == adAfterRow)
                  NativeAdTile(
                    placement: AdPlacement.ranksFeedNative,
                    padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  ),
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                  child: _LeaderboardRow(
                    entry: entry,
                    localeName: localeName,
                    onActions: entry.isSelf
                        ? null
                        : () => _openPlayerActions(context, entry),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.localeName,
    this.onActions,
  });

  final LeaderboardEntry entry;
  final String localeName;

  /// Non-null on every row but the viewer's own: shows the small ⋯ that
  /// opens the report/block sheet (plan 025).
  final VoidCallback? onActions;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    // Plan 023: own row, so the local entitlement is OR'd in — see `proBadge`.
    final localIsPro = context.select<SubscriptionCubit, bool>(
      (cubit) => cubit.state.isPro,
    );
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
      rank: entry.rank,
      title: entry.name,
      subtitle: entry.locationLabel,
      leadingEmoji: entry.avatarEmoji,
      isPro: proBadge(
        serverIsPro: entry.isPro,
        isSelf: entry.isSelf,
        localIsPro: localIsPro,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
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
          if (onActions != null) ...[
            SizedBox(width: AppSpacing.sm.w),
            Semantics(
              button: true,
              label: l10n.safetyActionsLabel,
              child: GestureDetector(
                onTap: onActions,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    '⋯',
                    style: AppTypography.glyph(18.sp, color: quizoo.tx3),
                  ),
                ),
              ),
            ),
          ],
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
