import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/presentation/bloc/matchmaking_cubit.dart';
import 'package:quizoo/features/duel/presentation/screens/duel_play_screen.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-39 — matchmaking.
///
/// "Cancel — play a bot instead" is on screen from frame one, not only after
/// the ~20s auto-offer (plan 004, Research findings' flagged reading of the
/// bible's own mockup).
class MatchmakingScreen extends StatelessWidget {
  const MatchmakingScreen({super.key});

  static const int _playerElo = 1240;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakingCubit>(
      create: (_) => MatchmakingCubit(
        DuelRepository(DuelApi(supabase)),
        playerElo: _playerElo,
      )..start(),
      child: const _MatchmakingView(),
    );
  }
}

class _MatchmakingView extends StatelessWidget {
  const _MatchmakingView();

  void _onFound(BuildContext context, DuelOpponent opponent) {
    context.pushReplacement(
      AppRoutes.duelPlayPath(opponent.id),
      extra: DuelPlayArgs(opponent: opponent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: BlocConsumer<MatchmakingCubit, MatchmakingState>(
        listener: (context, state) {
          if (state is MatchmakingFound) _onFound(context, state.opponent);
        },
        builder: (context, state) {
          return Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: arena.base),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        l10n.duelMatchmakingTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium!.copyWith(
                          fontSize: 24.sp,
                          color: arena.onArena,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl.h),
                      VsHeader(
                        leftAvatarEmoji: MockPlayer.avatarEmoji,
                        leftCaption: l10n.duelEloLabel(
                          MatchmakingScreen._playerElo,
                        ),
                        rightCaption: l10n.duelSearchingCaption,
                      ),
                      SizedBox(height: AppSpacing.xl.h),
                      SizedBox(
                        width: 32.w,
                        height: 32.w,
                        child: CircularProgressIndicator(
                          color: arena.onArena,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: AppSpacing.base.h),
                      if (state is MatchmakingSearching)
                        Text(
                          l10n.duelSearchingStatus(
                            state.elapsedSeconds,
                            MatchmakingCubit.widenInterval.inSeconds -
                                (state.elapsedSeconds %
                                    MatchmakingCubit.widenInterval.inSeconds),
                          ),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium!.copyWith(
                            color: arena.metaText,
                          ),
                        ),
                      const Spacer(),
                      ChunkyButton.line(
                        label: l10n.duelCancelPlayBot,
                        onPressed: () =>
                            context.read<MatchmakingCubit>().playBotInstead(),
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
