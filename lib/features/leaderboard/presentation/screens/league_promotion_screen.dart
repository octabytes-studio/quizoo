import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_badge.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_api.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/league_standing.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/league_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-26 — the weekly league promotion interstitial.
///
/// Belongs narratively to the result flow but structurally to leagues (a
/// league is a distinct system from a leaderboard — see the plan's Research
/// findings) — this plan is responsible only for the screen and route
/// existing, exactly as it is for S-23; nothing in `quiz_result` pushes here
/// yet.
class LeaguePromotionScreen extends StatelessWidget {
  const LeaguePromotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeagueCubit>(
      create: (_) =>
          LeagueCubit(LeaderboardRepository(LeaderboardApi(supabase)))..load(),
      child: const _LeaguePromotionView(),
    );
  }
}

class _LeaguePromotionView extends StatelessWidget {
  const _LeaguePromotionView();

  void _continue(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.ranks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.linear(
              AppGradients.washAngle,
              [const Color(0xFFFFC61A), quizoo.s0],
              stops: const [0, 0.44],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.w),
                  child: Column(
                    children: [
                      Text(
                        l10n.leaguePromotionEyebrow,
                        style: textTheme.labelSmall!.copyWith(
                          color: const Color(0xFF6A4A00),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: AppSpacing.base.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: 0.45,
                            child: Column(
                              children: [
                                Text('🥈', style: AppTypography.glyph(40.sp)),
                                Text(
                                  l10n.leaguePromotionPreviousLeague,
                                  style: textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: AppSpacing.md.w),
                          Text(
                            '→',
                            style: textTheme.titleLarge!.copyWith(
                              color: const Color(0xFF6A4A00),
                            ),
                          ),
                          SizedBox(width: AppSpacing.md.w),
                          Column(
                            children: [
                              Text('🥇', style: AppTypography.glyph(66.sp)),
                              Text(
                                l10n.leaguePromotionNewLeague,
                                style: textTheme.labelSmall!.copyWith(
                                  color: const Color(0xFF6A4A00),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.base.h),
                      Text(
                        l10n.leaguePromotionHeadline,
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium!.copyWith(
                          fontSize: 27.sp,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Text(
                        l10n.leaguePromotionExplainer,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium!.copyWith(
                          fontSize: 13.5.sp,
                          color: quizoo.tx2,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg.h - 2.h),
                      BlocBuilder<LeagueCubit, LeagueState>(
                        builder: (context, state) => switch (state) {
                          LeagueLoaded(:final neighbors) => _StandingsCard(
                            neighbors: neighbors,
                          ),
                          _ => SizedBox(height: 120.h),
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin.w,
                    0,
                    AppSpacing.screenMargin.w,
                    AppSpacing.sm.h + 2.h,
                  ),
                  child: ChunkyButton.gold(
                    label: l10n.leaguePromotionCta,
                    onPressed: () => _continue(context),
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

class _StandingsCard extends StatelessWidget {
  const _StandingsCard({required this.neighbors});

  final List<LeagueStanding> neighbors;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    // Plan 023: own row, so the local entitlement is OR'd in — see `proBadge`.
    final localIsPro = context.select<SubscriptionCubit, bool>(
      (cubit) => cubit.state.isPro,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 15.w,
        vertical: AppSpacing.md.h + 1.h,
      ),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: quizoo.ln),
        boxShadow: quizoo.shadow,
      ),
      child: Column(
        children: [
          for (final standing in neighbors)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: ListRowTile(
                variant: standing.isSelf
                    ? ListRowVariant.self
                    : ListRowVariant.player,
                title: standing.name,
                leadingEmoji: standing.avatarEmoji,
                isPro: proBadge(
                  serverIsPro: standing.isPro,
                  isSelf: standing.isSelf,
                  localIsPro: localIsPro,
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24.w,
                      child: Text(
                        '${standing.rank}',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Text(
                      '${standing.points}',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
