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
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/data/duel_audio.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/live_duel_api.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/presentation/bloc/live_duel_bloc.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_error_view.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_round_view.dart';
import 'package:quizoo/features/duel/presentation/widgets/match_intro_view.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-40 — a live, server-refereed duel against a real player (plan 017,
/// Phase 10): the VS intro, ten synced questions (each read aloud, with play
/// mode's sound and visual effects), then the result.
///
/// Leaving is always a confirmed choice — the ✕ and the system back gesture
/// both route to "Leave the duel?", because leaving a started duel forfeits
/// it.
class LiveDuelScreen extends StatelessWidget {
  const LiveDuelScreen({
    required this.duelId,
    super.key,
    @visibleForTesting this.bloc,
  });

  final String duelId;

  /// Replaces the Bloc the screen builds for itself (widget tests).
  final LiveDuelBloc? bloc;

  @override
  Widget build(BuildContext context) {
    final injected = bloc;
    final view = _LiveDuelView(duelId: duelId);
    if (injected != null) {
      return BlocProvider<LiveDuelBloc>.value(value: injected, child: view);
    }
    return BlocProvider<LiveDuelBloc>(
      create: (context) {
        final clock = context.read<ServerClock>();
        return LiveDuelBloc(
          LiveDuelRepository(
            LiveDuelApi(supabase, context.read<DuelRealtime>()),
            clock,
          ),
          clock,
          duelId: duelId,
          audio: DuelAudio.device(
            settings: context.read<SettingsRepository>(),
            languages: context.read<ContentLanguageRepository>(),
          ),
          languageCode: context.read<ContentLanguageCubit>().state.code,
        )..add(const LiveDuelStarted());
      },
      child: view,
    );
  }
}

class _LiveDuelView extends StatefulWidget {
  const _LiveDuelView({required this.duelId});

  final String duelId;

  @override
  State<_LiveDuelView> createState() => _LiveDuelViewState();
}

class _LiveDuelViewState extends State<_LiveDuelView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Broadcasts may have been missed while backgrounded.
    if (state == AppLifecycleState.resumed) {
      context.read<LiveDuelBloc>().add(const LiveDuelResumed());
    }
  }

  void _leaveScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// The ✕ / back gesture: a duel in play asks first; anything else (still
  /// connecting, failed) just leaves.
  Future<void> _onQuitRequested() async {
    final bloc = context.read<LiveDuelBloc>();
    final current = bloc.state;
    if (current is! LiveDuelIntro && current is! LiveDuelRound) {
      _leaveScreen();
      return;
    }
    final confirmed = await AppDialog.show<bool>(
      context,
      builder: (dialogContext) => _QuitDuelDialog(
        onStay: () => Navigator.of(dialogContext).pop(false),
        onLeave: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed == true && !bloc.isClosed) {
      bloc.add(const LiveDuelQuitConfirmed());
    }
  }

  void _onStateChanged(BuildContext context, LiveDuelState state) {
    if (state is LiveDuelEnded) {
      context.pushReplacement(
        AppRoutes.duelResultPath(widget.duelId),
        extra: state.result,
      );
    } else if (state is LiveDuelAbandoned) {
      if (!state.byMe) {
        AppSnackbar.show(
          context,
          title: AppLocalizations.of(context).duelNoticeOpponentNoShow,
          intent: SnackbarIntent.info,
        );
      }
      _leaveScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final bloc = context.read<LiveDuelBloc>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onQuitRequested();
        },
        child: BlocConsumer<LiveDuelBloc, LiveDuelState>(
          listenWhen: (previous, current) =>
              current is LiveDuelEnded || current is LiveDuelAbandoned,
          listener: _onStateChanged,
          builder: (context, state) {
            final isDanger = state is LiveDuelRound && state.isDanger;
            return Scaffold(
              body: AnimatedContainer(
                duration: AppMotion.durationOf(context, AppMotion.slide),
                // Play mode's S-14: the arena washes red for the last
                // seconds of an unanswered question.
                decoration: BoxDecoration(
                  gradient: isDanger ? arena.danger : arena.lite,
                ),
                child: SafeArea(
                  child: switch (state) {
                    LiveDuelConnecting() => const _Spinner(),
                    final LiveDuelIntro intro => MatchIntroView(
                      me: intro.me,
                      opponent: intro.opponent,
                      topic: intro.topic,
                      isRanked: intro.isRanked,
                      secondsToStart: intro.secondsToStart,
                      onQuit: _onQuitRequested,
                    ),
                    final LiveDuelRound round => DuelRoundView(
                      me: round.me,
                      opponent: round.opponent,
                      myScore: round.myScore,
                      opponentScore: round.opponentScore,
                      roundNumber: round.roundNumber,
                      totalRounds: round.totalRounds,
                      question: round.question,
                      secondsRemaining: round.secondsRemaining,
                      secondsTotal: round.secondsTotal,
                      myChoice: round.myChoice,
                      mySeconds: round.myLocked ? round.mySeconds : null,
                      opponentLocked: round.opponentLocked,
                      opponentSeconds: round.opponentSeconds,
                      isRevealed: round.isRevealed,
                      correctIndex: round.correctIndex,
                      opponentChoice: round.opponentChoice,
                      opponentOnline: round.opponentOnline,
                      opponentReconnectSeconds: round.opponentReconnectSeconds,
                      onAnswer: (index) =>
                          bloc.add(LiveDuelAnswerSelected(index)),
                      onQuit: _onQuitRequested,
                      isAudioOn: round.isAudioOn,
                      onToggleAudio: () =>
                          bloc.add(const LiveDuelAudioToggled()),
                      isDanger: round.isDanger,
                    ),
                    LiveDuelEnded() => const _Spinner(),
                    LiveDuelAbandoned() => const _Spinner(),
                    LiveDuelFailed(:final error) => DuelErrorView(
                      errorCode: error.code,
                    ),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 32.w,
        child: CircularProgressIndicator(
          color: context.arena.onArena,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

/// "Leave the duel? Leaving forfeits the remaining rounds." — staying is
/// first and dominant, leaving second and never pre-focused.
class _QuitDuelDialog extends StatelessWidget {
  const _QuitDuelDialog({required this.onStay, required this.onLeave});

  final VoidCallback onStay;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppDialog(
      emoji: '🏳️',
      iconPlateColor: context.quizoo.badBg,
      title: l10n.duelQuitTitle,
      message: l10n.duelQuitBody,
      actions: [
        ChunkyButton.ghost(label: l10n.duelQuitStay, onPressed: onStay),
        ChunkyButton.danger(label: l10n.duelQuitConfirm, onPressed: onLeave),
      ],
    );
  }
}
