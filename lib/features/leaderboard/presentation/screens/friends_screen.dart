import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_api.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/presentation/bloc/friends_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/friend_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-31 — friend requests and the friends list.
///
/// The friend system itself is not implemented (see `MOCKED_FEATURES.md`):
/// this screen is an unreachable design screen, and every affordance that
/// once promised it with a mock snackbar has been removed (plan 025) — what
/// remains (requests, accept/decline) is real. It is kept out of release
/// navigation by having no push site, not by a debug gate.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendsCubit>(
      create: (_) =>
          FriendsCubit(LeaderboardRepository(LeaderboardApi(supabase)))..load(),
      child: const _FriendsView(),
    );
  }
}

class _FriendsView extends StatelessWidget {
  const _FriendsView();

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
            BlocBuilder<FriendsCubit, FriendsState>(
              builder: (context, state) => SimpleTopBar(
                title: l10n.friendsTitle,
                subtitle: state is FriendsLoaded
                    ? l10n.friendsSubtitle(
                        state.accepted.length,
                        state.requests.length,
                      )
                    : null,
              ),
            ),
            Expanded(
              child: BlocBuilder<FriendsCubit, FriendsState>(
                builder: (context, state) => switch (state) {
                  FriendsInitial() ||
                  FriendsLoading() => const _FriendsSkeleton(),
                  FriendsError(:final error) => _FriendsError(
                    error: error.code,
                  ),
                  FriendsLoaded() => _FriendsContent(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsContent extends StatelessWidget {
  const _FriendsContent({required this.state});

  final FriendsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FriendsCubit>();

    if (state.friends.isEmpty) {
      return EmptyStateView(
        emoji: '🧑‍🤝‍🧑',
        title: l10n.friendsEmptyTitle,
        message: l10n.friendsEmptyBody,
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      children: [
        if (state.requests.isNotEmpty) ...[
          SizedBox(height: AppSpacing.base.h),
          Text(
            l10n.friendsRequestsHeading(state.requests.length),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SizedBox(height: AppSpacing.sm.h),
          for (final friend in state.requests)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: FriendRow(
                friend: friend,
                onAccept: () => cubit.respondToRequest(friend.id, accept: true),
                onDecline: () =>
                    cubit.respondToRequest(friend.id, accept: false),
              ),
            ),
        ],
        if (state.accepted.isNotEmpty) ...[
          SizedBox(height: AppSpacing.base.h),
          Text(
            l10n.friendsListHeading,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SizedBox(height: AppSpacing.sm.h),
          for (final friend in state.accepted)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: FriendRow(friend: friend),
            ),
        ],
        SizedBox(height: AppSpacing.xl.h),
      ],
    );
  }
}

class _FriendsSkeleton extends StatelessWidget {
  const _FriendsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        children: [
          SkeletonBox(height: 68.h),
          SizedBox(height: AppSpacing.lg.h),
          SkeletonBox(height: 60.h),
          SizedBox(height: AppSpacing.sm.h),
          SkeletonBox(height: 60.h),
        ],
      ),
    );
  }
}

class _FriendsError extends StatelessWidget {
  const _FriendsError({required this.error});

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
          onPressed: () => context.read<FriendsCubit>().load(),
        ),
      ),
    );
  }
}
