import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/report_question_sheet.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/countdown_screen.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/feedback_banner.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/out_of_lives_dialog.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/pause_sheet.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/power_up_dock.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/question_media_plate.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/quiz_hud.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/quit_confirmation_dialog.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/timer_ring.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Which overlay a deep link should open on arrival.
///
/// S-17, S-18 and S-19 are states of the play surface, not destinations, but
/// each has a reserved path so it stays reachable for design review. This is
/// how those paths resolve to the state they name.
enum QuizPlayEntry { play, paused, quitting, outOfLives }

/// S-10 through S-19 — the play surface.
///
/// One screen for the whole level, because the countdown, every question
/// state and all three overlays are states of one [QuizPlayCubit], and
/// splitting them across routes is what would let the clock and the UI drift
/// apart.
///
/// The arena is painted from [ArenaColors] and never branches on
/// `Theme.of(context).brightness`: the play surface looks the same in light
/// and dark, which is §09's one deliberate commitment.
class QuizPlayScreen extends StatelessWidget {
  const QuizPlayScreen({
    required this.levelId,
    super.key,
    this.entry = QuizPlayEntry.play,
  });

  final String levelId;
  final QuizPlayEntry entry;

  @override
  Widget build(BuildContext context) {
    final (subcategoryId, _) = MockCatalog.parseLevelId(levelId);
    final subcategory = MockCatalog.subcategories
        .where((candidate) => candidate.id == subcategoryId)
        .firstOrNull;

    return BlocProvider<QuizPlayCubit>(
      create: (_) =>
          QuizPlayCubit(context.read<QuizPlayRepository>())..startLevel(
            levelId: levelId,
            categoryId: subcategory?.categoryId ?? '',
            subcategoryName: subcategory?.name ?? '',
            languageCode: Localizations.localeOf(context).languageCode,
          ),
      child: _QuizPlayView(entry: entry),
    );
  }
}

class _QuizPlayView extends StatefulWidget {
  const _QuizPlayView({required this.entry});

  final QuizPlayEntry entry;

  @override
  State<_QuizPlayView> createState() => _QuizPlayViewState();
}

class _QuizPlayViewState extends State<_QuizPlayView> {
  AppLifecycleListener? _lifecycleListener;
  bool _hasAppliedEntry = false;

  @override
  void initState() {
    super.initState();
    // **The pause trigger.** The bible's HUD shows no pause affordance
    // (plan 002, Assumption 2), so rather than invent chrome the design does
    // not have, pause is reached the two ways the platform already offers:
    // a back gesture (the `PopScope` below) and the app being backgrounded.
    _lifecycleListener = AppLifecycleListener(
      onInactive: () => context.read<QuizPlayCubit>().pause(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  /// Opens whichever overlay a deep link asked for, once the run is live.
  void _applyEntry(QuizPlayCubit cubit, QuizPlayState state) {
    if (_hasAppliedEntry || state is! QuizPlayCountdown) return;
    _hasAppliedEntry = true;
    switch (widget.entry) {
      case QuizPlayEntry.play:
        break;
      case QuizPlayEntry.paused:
        cubit
          ..skipCountdown()
          ..pause();
      case QuizPlayEntry.quitting:
        cubit
          ..skipCountdown()
          ..requestQuit();
      case QuizPlayEntry.outOfLives:
        cubit.skipCountdown();
        // Three wrong answers is the only honest way to reach S-19: the
        // dialog quotes the run's real numbers, so it needs a real run.
        for (var attempt = 0; attempt < 3; attempt++) {
          final playing = cubit.state.playing;
          if (playing == null) break;
          cubit.answer(
            (playing.question.correctIndex + 1) %
                playing.question.options.length,
          );
          if (cubit.state is QuizPlayInProgress) cubit.next();
        }
    }
  }

  void _onRunEnded(BuildContext context, QuizRun run) {
    final route = run.isComplete
        ? AppRoutes.levelCompletePath(run.levelId)
        : AppRoutes.levelFailedPath(run.levelId);
    context.pushReplacement(route, extra: run);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The arena is dark in both themes, so its status-bar icons are always
      // light — never derived from the app's brightness.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: BlocConsumer<QuizPlayCubit, QuizPlayState>(
        listener: (context, state) {
          _applyEntry(context.read<QuizPlayCubit>(), state);
          // Navigation belongs in the listener, never in the builder
          // (CLAUDE.md §3).
          if (state is QuizPlayEnded) _onRunEnded(context, state.run);
        },
        builder: (context, state) {
          final cubit = context.read<QuizPlayCubit>();
          return PopScope(
            // A back gesture pauses rather than leaving — losing a level to a
            // stray swipe would be the cruellest bug on this screen.
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              switch (state) {
                case QuizPlayInProgress():
                  cubit.pause();
                case QuizPlayPaused():
                  cubit.resume();
                case QuizPlayQuitting():
                  cubit.cancelQuit();
                case QuizPlayPreparing() || QuizPlayFailed():
                  context.pop();
                case _:
                  break;
              }
            },
            child: _ArenaScaffold(state: state),
          );
        },
      ),
    );
  }
}

/// The arena background and whatever is on it.
class _ArenaScaffold extends StatelessWidget {
  const _ArenaScaffold({required this.state});

  final QuizPlayState state;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    // Bound to a local so the `is` checks below promote — a public widget
    // field never does.
    final state = this.state;
    final playing = state.playing;
    final isDanger = playing?.isDanger ?? false;

    return Scaffold(
      body: AnimatedContainer(
        duration: AppMotion.durationOf(context, AppMotion.slide),
        decoration: BoxDecoration(
          // S-14: the arena washes crimson for the last five seconds.
          gradient: isDanger ? arena.danger : arena.base,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _ArenaBody(state: state)),
              if (state is QuizPlayPaused)
                _Overlay(
                  dimOpacity: 0.5,
                  child: PauseSheet(
                    isSoundOn: state.isSoundOn,
                    isHapticsOn: state.isHapticsOn,
                    onResume: context.read<QuizPlayCubit>().resume,
                    onToggleSound: context.read<QuizPlayCubit>().toggleSound,
                    onToggleHaptics: context
                        .read<QuizPlayCubit>()
                        .toggleHaptics,
                    onRestart: () => context.pushReplacement(
                      AppRoutes.quizPlayPath(state.underlying.run.levelId),
                    ),
                    onQuit: context.read<QuizPlayCubit>().requestQuit,
                  ),
                ),
              if (state is QuizPlayQuitting)
                _Overlay(
                  dimOpacity: 0.4,
                  alignment: Alignment.center,
                  child: QuitConfirmationDialog(
                    run: state.underlying.run,
                    onKeepPlaying: context.read<QuizPlayCubit>().cancelQuit,
                    onQuit: context.read<QuizPlayCubit>().confirmQuit,
                  ),
                ),
              if (state is QuizPlayOutOfLives)
                _Overlay(
                  dimOpacity: 0.35,
                  alignment: Alignment.center,
                  child: OutOfLivesDialog(
                    state: state,

                    onWatchAd: context.read<QuizPlayCubit>().watchAdForHeart,
                    onRefill: context
                        .read<QuizPlayCubit>()
                        .refillHeartsWithCoins,
                    onBackToMap: context.read<QuizPlayCubit>().abandonRun,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArenaBody extends StatelessWidget {
  const _ArenaBody({required this.state});

  final QuizPlayState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuizPlayCubit>();

    return switch (state) {
      QuizPlayPreparing() => const _ArenaSpinner(),
      QuizPlayFailed(:final error) => _ArenaError(errorCode: error.code),
      final QuizPlayCountdown countdown => CountdownView(
        state: countdown,
        onSkip: cubit.skipCountdown,
      ),
      // The run has ended and the listener is already navigating; holding the
      // last frame avoids a flash of empty arena on the way out.
      QuizPlayEnded() => const _ArenaSpinner(),
      _ => _QuestionView(state: state.playing!),
    };
  }
}

/// S-11 through S-16 — the question itself.
class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.state});

  final QuizPlayInProgress state;

  /// S-51 — reached from the HUD's "⋯", never a second tap away.
  void _openReportSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = state.question;
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => ReportQuestionSheet(
        title: l10n.reportQuestionTitle,
        message: l10n.reportQuestionMeta(question.text),
        reasons: [
          l10n.reportReasonWrong,
          l10n.reportReasonUnclear,
          l10n.reportReasonTranslation,
          l10n.reportReasonOffensive,
          l10n.reportReasonImage,
        ],
        submitLabel: l10n.reportQuestionSubmit,
        onSubmit: (_) {
          Navigator.of(sheetContext).pop();
          AppSnackbar.show(
            context,
            title: l10n.reportQuestionSent,
            intent: SnackbarIntent.success,
          );
        },
      ),
    );
  }

  AnswerOptionState _optionState(int index) {
    if (state.eliminatedIndexes.contains(index)) {
      return AnswerOptionState.eliminated;
    }
    return switch (state.feedback) {
      NoFeedback() =>
        state.selectedIndex == index
            ? AnswerOptionState.selected
            : AnswerOptionState.rest,
      SkippedFeedback() => AnswerOptionState.rest,
      // Right or wrong, the correct option always lights mint. The bible is
      // explicit: always show the right answer.
      _ when index == state.question.correctIndex => AnswerOptionState.correct,
      WrongFeedback(:final chosenIndex) when index == chosenIndex =>
        AnswerOptionState.wrong,
      _ => AnswerOptionState.eliminated,
    };
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final quizoo = context.quizoo;
    final cubit = context.read<QuizPlayCubit>();
    final textTheme = Theme.of(context).textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final keys = isRtl ? Question.urduKeys : Question.latinKeys;

    final hasImage = state.question.hasImage;
    final ringColor = switch (state.feedback) {
      CorrectFeedback() => quizoo.ok,
      WrongFeedback() || TimeoutFeedback() => quizoo.bad,
      _ when state.isDanger => quizoo.bad,
      _ => quizoo.gold,
    };

    final body = Column(
      children: [
        QuizHud(
          run: state.run,
          onQuitPressed: cubit.requestQuit,
          onReportPressed: () => _openReportSheet(context),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: hasImage ? 10.h : 12.h),
          child: Center(
            child: TimerRing(
              secondsRemaining: state.secondsRemaining,
              secondsTotal: state.run.secondsPerQuestion,
              color: ringColor,
              // The plate takes the room the full-size ring would need.
              diameter: hasImage
                  ? TimerRing.imageDiameter
                  : TimerRing.defaultDiameter,
              isPulsing: state.isDanger,
            ),
          ),
        ),
        QuestionMediaPlate(question: state.question),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, hasImage ? 12.h : 0, 18.w, 0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
            decoration: BoxDecoration(
              color: arena.questionCard,
              border: Border.all(
                color: state.isDanger
                    ? quizoo.bad.withValues(alpha: 0.5)
                    : arena.questionCardBorder,
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Text(
              state.question.text,
              // Up to three lines, then it truncates rather than pushing the
              // options off the screen.
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineSmall!.copyWith(color: arena.onArena),
            ),
          ),
        ),
        // The options take whatever room the header leaves and scroll inside
        // it, so a long question or a long answer can never push the power-up
        // dock off the bottom of the arena — `.pups` is `margin-top:auto`.
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < state.question.options.length;
                  index++
                )
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: AnswerOption(
                      label: state.question.options[index],
                      optionKey: keys[index % keys.length],
                      state: _optionState(index),
                      onPressed: state.isAwaitingAnswer
                          ? () => cubit.answer(index)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The dock is hidden while a verdict banner is up, which is what the
        // bible's S-12 and S-13 frames show.
        if (state.isAwaitingAnswer)
          PowerUpDock(
            inventory: state.powerUps,
            isDanger: state.isDanger,
            onUse: cubit.usePowerUp,
            onBuy: () => context.push(AppRoutes.shop),
          ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(
          child: _ShakeOnWrong(feedback: state.feedback, child: body),
        ),
        if (!state.isAwaitingAnswer && state.feedback is! SkippedFeedback)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FeedbackBanner(state: state, onNextPressed: cubit.next),
          ),
      ],
    );
  }
}

/// S-13's 6px / 120ms screen shake.
///
/// Disabled under reduced motion, which the bible calls out explicitly — and
/// which comes for free from [AppMotion.durationOf] collapsing to zero.
class _ShakeOnWrong extends StatelessWidget {
  const _ShakeOnWrong({required this.feedback, required this.child});

  final QuestionFeedback feedback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (feedback is! WrongFeedback) return child;

    return child
        .animate(key: const ValueKey('shake'))
        .shakeX(
          duration: AppMotion.durationOf(
            context,
            const Duration(milliseconds: 120),
          ),
          amount: 6,
        );
  }
}

/// The scrim, blur and content of an overlay sitting on the arena.
class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.child,
    required this.dimOpacity,
    this.alignment = Alignment.bottomCenter,
  });

  final Widget child;
  final double dimOpacity;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Positioned.fill(
      child: ColoredBox(
        // §25's performance budget forbids a `BackdropFilter` on the play
        // surface, so the "blurred" look behind these overlays is a
        // translucent scrim — exactly as the bible specifies.
        color: quizoo.ov.withValues(alpha: dimOpacity),
        child: SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: alignment == Alignment.center
                    ? AppSpacing.xl.w + 2.w
                    : 0,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArenaSpinner extends StatelessWidget {
  const _ArenaSpinner();

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

class _ArenaError extends StatelessWidget {
  const _ArenaError({required this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
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
