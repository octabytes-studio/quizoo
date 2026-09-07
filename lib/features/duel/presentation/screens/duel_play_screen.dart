import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_play_cubit.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_status_chip.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/timer_ring.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The `extra` a duel route is pushed with.
class DuelPlayArgs {
  const DuelPlayArgs({required this.opponent});

  final DuelOpponent opponent;
}

/// S-40 — the duel's play surface.
///
/// [opponent] is nullable so the route stays reachable for design review with
/// no prior matchmaking step (plan 004's convention for every reserved
/// overlay path) — a direct visit deals a fresh bot rather than failing.
class DuelPlayScreen extends StatelessWidget {
  const DuelPlayScreen({required this.duelId, super.key, this.opponent});

  final String duelId;
  final DuelOpponent? opponent;

  static const int _playerElo = 1240;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DuelPlayCubit>(
      create: (_) {
        final cubit = DuelPlayCubit(DuelRepository(DuelApi()));
        final resolvedOpponent =
            opponent ??
            const DuelOpponent(
              id: 'bot_review',
              name: 'Fennec',
              avatarEmoji: '🦊',
              elo: _playerElo,
            );
        cubit.start(resolvedOpponent);
        return cubit;
      },
      child: _DuelPlayView(duelId: duelId),
    );
  }
}

class _DuelPlayView extends StatelessWidget {
  const _DuelPlayView({required this.duelId});

  final String duelId;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: BlocConsumer<DuelPlayCubit, DuelPlayState>(
        listener: (context, state) {
          if (state is DuelPlayEnded) {
            context.pushReplacement(
              AppRoutes.duelResultPath(duelId),
              extra: state.result,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: arena.lite),
              child: SafeArea(
                child: switch (state) {
                  DuelPlayLoading() => const _Spinner(),
                  DuelPlayFailed(:final error) => _DuelError(
                    errorCode: error.code,
                  ),
                  DuelPlayEnded() => const _Spinner(),
                  final DuelPlayRound round => _RoundView(round: round),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Center(
      child: SizedBox.square(
        dimension: 32.w,
        child: CircularProgressIndicator(color: arena.onArena, strokeWidth: 3),
      ),
    );
  }
}

class _DuelError extends StatelessWidget {
  const _DuelError({required this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '⚔️',
        message: l10n.contentErrorBody,
        errorCode: errorCode,
        action: ChunkyButton.ghost(
          label: l10n.commonBack,
          onPressed: context.pop,
        ),
      ),
    );
  }
}

class _RoundView extends StatelessWidget {
  const _RoundView({required this.round});

  final DuelPlayRound round;

  AnswerOptionState _optionState(Question question, int index) {
    if (!round.isRevealed) {
      return round.playerAnswerIndex == index
          ? AnswerOptionState.selected
          : AnswerOptionState.rest;
    }
    if (index == question.correctIndex) return AnswerOptionState.correct;
    if (round.playerAnswerIndex == index) return AnswerOptionState.wrong;
    return AnswerOptionState.eliminated;
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<DuelPlayCubit>();
    final keys = Question.latinKeys;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.sm.h,
            AppSpacing.screenMargin.w,
            0,
          ),
          child: VsHeader(
            leftAvatarEmoji: MockPlayer.avatarEmoji,
            leftCaption: '${round.playerRoundsWon}',
            rightAvatarEmoji: round.opponent.avatarEmoji,
            rightCaption: '${round.opponentRoundsWon}',
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        TimerRing(
          secondsRemaining: round.secondsRemaining,
          secondsTotal: round.secondsTotal,
          color: quizoo.gold,
          diameter: TimerRing.defaultDiameter,
          isPulsing: false,
        ),
        Text(
          l10n.duelRoundLabel(round.roundNumber, round.totalRounds),
          style: textTheme.labelSmall!.copyWith(color: arena.metaText),
        ),
        SizedBox(height: AppSpacing.base.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DuelStatusChip(
              emoji: MockPlayer.avatarEmoji,
              label: round.playerHasAnswered
                  ? l10n.duelAnsweredIn(
                      round.secondsTotal - round.secondsRemaining,
                    )
                  : l10n.duelThinking,
            ),
            SizedBox(width: AppSpacing.sm.w),
            DuelStatusChip(
              emoji: round.opponent.avatarEmoji,
              label: round.opponentHasAnswered
                  ? l10n.duelAnsweredIn(round.opponentAnswerSecondsElapsed ?? 0)
                  : l10n.duelThinking,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.base.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
            decoration: BoxDecoration(
              color: arena.questionCard,
              border: Border.all(color: arena.questionCardBorder),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Text(
              round.question.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineSmall!.copyWith(color: arena.onArena),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, AppSpacing.xl.h),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < round.question.options.length;
                  index++
                )
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnswerOption(
                          label: round.question.options[index],
                          optionKey: keys[index % keys.length],
                          state: _optionState(round.question, index),
                          onPressed: round.playerHasAnswered
                              ? null
                              : () => cubit.answer(index),
                        ),
                        // The hourglass — the player's own choice is safe to
                        // show; correctness is not (see `DuelPlayCubit`'s
                        // withheld-correctness rule).
                        if (!round.isRevealed &&
                            round.playerAnswerIndex == index)
                          Positioned(
                            right: 10.w,
                            top: 10.h,
                            child: Text('⏳', style: TextStyle(fontSize: 16.sp)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
