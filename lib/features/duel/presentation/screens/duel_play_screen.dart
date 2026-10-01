import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_audio.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/presentation/screens/bot_duel_args.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_play_cubit.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_error_view.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_round_view.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';

/// S-40 (bot variant) — the labelled practice-bot duel's play surface.
///
/// [args] is nullable so the route stays reachable for design review; with
/// no topic to draw questions from, a direct visit shows the error state.
class DuelPlayScreen extends StatelessWidget {
  const DuelPlayScreen({super.key, this.args});

  final BotDuelArgs? args;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.read<ContentLanguageCubit>().state.code;
    final resolved = args;
    return BlocProvider<DuelPlayCubit>(
      create: (context) {
        final cubit = DuelPlayCubit(
          DuelRepository(DuelApi(supabase)),
          // No audio players for the design-review route with nothing to
          // play.
          audio: resolved == null
              ? null
              : DuelAudio.device(
                  settings: context.read<SettingsRepository>(),
                  languages: context.read<ContentLanguageRepository>(),
                ),
        );
        if (resolved == null) {
          cubit.failWithoutTopic();
        } else {
          cubit.start(
            resolved.opponent,
            me: resolved.me,
            topic: resolved.topic,
            languageCode: languageCode,
          );
        }
        return cubit;
      },
      child: _DuelPlayView(duelId: resolved?.opponent.id ?? 'bot'),
    );
  }
}

class _DuelPlayView extends StatelessWidget {
  const _DuelPlayView({required this.duelId});

  final String duelId;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final languageCode = context.read<ContentLanguageCubit>().state.code;

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
          final isDanger = state is DuelPlayRound && state.isDanger;
          return Scaffold(
            body: AnimatedContainer(
              duration: AppMotion.durationOf(context, AppMotion.slide),
              // Play mode's S-14 danger wash for the last seconds.
              decoration: BoxDecoration(
                gradient: isDanger ? arena.danger : arena.lite,
              ),
              child: SafeArea(
                child: switch (state) {
                  DuelPlayLoading() => const _Spinner(),
                  DuelPlayFailed(:final error) => DuelErrorView(
                    errorCode: error.code,
                  ),
                  DuelPlayEnded() => const _Spinner(),
                  final DuelPlayRound round => DuelRoundView(
                    languageCode: languageCode,
                    me: round.me,
                    opponent: round.opponent,
                    myScore: round.playerRoundsWon,
                    opponentScore: round.opponentRoundsWon,
                    roundNumber: round.roundNumber,
                    totalRounds: round.totalRounds,
                    question: round.question,
                    secondsRemaining: round.secondsRemaining,
                    secondsTotal: round.secondsTotal,
                    myChoice: round.playerAnswerIndex,
                    mySeconds: round.playerAnswerSeconds,
                    opponentLocked: round.opponentHasAnswered,
                    opponentSeconds: round.opponentAnswerSecondsElapsed,
                    isRevealed: round.isRevealed,
                    correctIndex: round.revealedCorrectIndex,
                    opponentChoice: round.revealedOpponentAnswerIndex,
                    onAnswer: context.read<DuelPlayCubit>().answer,
                    isAudioOn: round.isAudioOn,
                    onToggleAudio: context.read<DuelPlayCubit>().toggleAudio,
                    isDanger: round.isDanger,
                  ),
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
