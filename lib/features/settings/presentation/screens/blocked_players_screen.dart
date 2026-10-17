import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/safety/blocked_players_cubit.dart';
import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:quizoo/core/safety/safety_api.dart';
import 'package:quizoo/core/safety/safety_repository.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Privacy → Blocked players (plan 025): the list of players the viewer has
/// blocked, each with its one action — unblock, which restores them to
/// leaderboards and matchmaking.
class BlockedPlayersScreen extends StatelessWidget {
  const BlockedPlayersScreen({super.key, @visibleForTesting this.cubit});

  /// Test seam: drives the screen from a given Cubit instead of building one
  /// against the real backend.
  final BlockedPlayersCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final injected = cubit;
    if (injected != null) {
      return BlocProvider<BlockedPlayersCubit>.value(
        value: injected,
        child: const _BlockedPlayersView(),
      );
    }
    return BlocProvider<BlockedPlayersCubit>(
      create: (_) =>
          BlockedPlayersCubit(SafetyRepository(SafetyApi(supabase)))..load(),
      child: const _BlockedPlayersView(),
    );
  }
}

class _BlockedPlayersView extends StatelessWidget {
  const _BlockedPlayersView();

  Future<void> _unblock(BuildContext context, BlockedPlayer player) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BlockedPlayersCubit>();
    await cubit.unblock(player.id);
    if (!context.mounted) return;
    final failed = cubit.state is BlockedPlayersError;
    AppSnackbar.show(
      context,
      title: failed ? l10n.safetyActionFailed : l10n.safetyUnblocked,
      intent: failed ? SnackbarIntent.error : SnackbarIntent.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimpleTopBar(title: l10n.safetyBlockedPlayersTitle),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin.w,
              ),
              child: Text(
                l10n.safetyBlockedPlayersHelper,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Expanded(
              child: BlocBuilder<BlockedPlayersCubit, BlockedPlayersState>(
                builder: (context, state) => switch (state) {
                  BlockedPlayersInitial() || BlockedPlayersLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  BlockedPlayersError(:final error) => Center(
                    child: ErrorStateView(
                      title: l10n.contentErrorTitle,
                      emoji: '🛰️',
                      message: l10n.contentErrorBody,
                      errorCode: error.code,
                      action: ChunkyButton(
                        label: l10n.commonRetry,
                        onPressed: () =>
                            context.read<BlockedPlayersCubit>().load(),
                      ),
                    ),
                  ),
                  BlockedPlayersLoaded(:final players) when players.isEmpty =>
                    EmptyStateView(
                      emoji: '🛡️',
                      title: l10n.safetyBlockedPlayersEmptyTitle,
                      message: l10n.safetyBlockedPlayersEmptyBody,
                    ),
                  BlockedPlayersLoaded(:final players) => ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenMargin.w,
                      AppSpacing.base.h,
                      AppSpacing.screenMargin.w,
                      AppSpacing.xl.h,
                    ),
                    children: [
                      for (final player in players)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                          child: ListRowTile(
                            variant: ListRowVariant.player,
                            title: player.name,
                            subtitle: l10n.safetyBlockedOn(
                              DateFormat.yMMMd(
                                localeName,
                              ).format(player.blockedAt),
                            ),
                            leadingEmoji: player.avatarEmoji,
                            trailing: ChunkyButton.line(
                              label: l10n.safetyUnblockPlayer,
                              isSmall: true,
                              onPressed: () => _unblock(context, player),
                            ),
                          ),
                        ),
                    ],
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
