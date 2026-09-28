import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/settings/data/notifications_api.dart';
import 'package:quizoo/features/settings/data/notifications_repository.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';
import 'package:quizoo/features/settings/presentation/bloc/notifications_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-44 — Notifications.
///
/// A duel-challenge notification's "Accept" opens the Duel Arena, where live
/// challenges are accepted: direct friend challenges are out of scope for
/// real duels (plan 017, which replaced the fake opponent this used to
/// build from duel internals).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => NotificationsCubit(
        NotificationsRepository(NotificationsApi(supabase)),
      )..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  void _accept(BuildContext context, AppNotification notification) {
    context.read<NotificationsCubit>().acceptChallenge(notification.id);
    // Friend challenges are out of scope for real duels (plan 017) — the
    // arena is where live challenges are accepted.
    context.push(AppRoutes.duelArena);
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
            BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) => SimpleTopBar(
                title: l10n.notificationsTitle,
                trailing: state is NotificationsLoaded && state.unreadCount > 0
                    ? GestureDetector(
                        onTap: () =>
                            context.read<NotificationsCubit>().markAllRead(),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          l10n.notificationsMarkAllRead,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: quizoo.g,
                              ),
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) => switch (state) {
                  NotificationsInitial() ||
                  NotificationsLoading() => const _NotificationsSkeleton(),
                  NotificationsError(:final error) => _NotificationsError(
                    error: error.code,
                  ),
                  NotificationsLoaded() => _NotificationsList(
                    state: state,
                    onAccept: (notification) => _accept(context, notification),
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

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.state, required this.onAccept});

  final NotificationsLoaded state;
  final ValueChanged<AppNotification> onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.notifications.isEmpty) {
      return Center(
        child: Text(
          l10n.notificationsEmpty,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      itemCount: state.notifications.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm.h),
      itemBuilder: (context, index) => _NotificationRow(
        notification: state.notifications[index],
        onAccept: () => onAccept(state.notifications[index]),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onAccept});

  final AppNotification notification;
  final VoidCallback onAccept;

  static String _emojiFor(NotificationKind kind) => switch (kind) {
    NotificationKind.duelChallenge => '⚔️',
    NotificationKind.streakEnding => '🔥',
    NotificationKind.leagueRankDrop => '📉',
    NotificationKind.newContent => '🆕',
    NotificationKind.rewardClaimed => '🎁',
  };

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w - 2.w),
      decoration: BoxDecoration(
        color: notification.isRead
            ? quizoo.s1
            : quizoo.g.withValues(alpha: 0.08),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: quizoo.ln),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_emojiFor(notification.kind), style: AppTypography.glyph(24.sp)),
          SizedBox(width: AppSpacing.md.w - 1.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification.title,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  notification.body,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 12.sp,
                    color: quizoo.tx2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(notification.timeLabel, style: textTheme.labelSmall),
                if (notification.isActionable) ...[
                  SizedBox(height: AppSpacing.sm.h),
                  ChunkyButton(
                    label: l10n.notificationsAccept,
                    isSmall: true,
                    onPressed: onAccept,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        children: [
          SkeletonBox(height: 84.h),
          SizedBox(height: AppSpacing.sm.h),
          SkeletonBox(height: 68.h),
          SizedBox(height: AppSpacing.sm.h),
          SkeletonBox(height: 68.h),
        ],
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.error});

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
          onPressed: () => context.read<NotificationsCubit>().load(),
        ),
      ),
    );
  }
}
