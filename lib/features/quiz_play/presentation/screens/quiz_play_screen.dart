import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/content_language/language_direction.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/content_language_scope.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/report_question_sheet.dart';
import 'package:quizoo/features/daily/data/daily_api.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/quiz_play/data/admob_rewarded_ad_service.dart';
import 'package:quizoo/features/quiz_play/data/audioplayers_sound_effects_service.dart';
import 'package:quizoo/features/quiz_play/data/cache_manager_audio_cache_service.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/data/stored_audio_tts_service.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/heart_ad_cubit.dart';
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
import 'package:quizoo/features/settings/data/settings_repository.dart';
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

  /// The daily challenge, playing through this exact same arena rather than
  /// a separate screen (design decision: one play surface, not two).
  const QuizPlayScreen.daily({super.key})
    : levelId = null,
      entry = QuizPlayEntry.play;

  final String? levelId;
  final QuizPlayEntry entry;

  @override
  Widget build(BuildContext context) {
    final audioCacheService = CacheManagerAudioCacheService();
    final levelId = this.levelId;
    final languageCode = context.read<ContentLanguageCubit>().state.code;

    return BlocProvider<QuizPlayCubit>(
      create: (_) {
        final cubit = QuizPlayCubit(
          context.read<QuizPlayRepository>(),
          context.read<SettingsRepository>(),
          StoredAudioTtsService(audioCacheService),
          AudioplayersSoundEffectsService(),
          audioCacheService,
          dailyRepository: DailyRepository(DailyApi(supabase)),
        );
        if (levelId != null) {
          final (subcategoryId, _) = MockCatalog.parseLevelId(levelId);
          final subcategory = MockCatalog.subcategories
              .where((candidate) => candidate.id == subcategoryId)
              .firstOrNull;
          cubit.startLevel(
            levelId: levelId,
            categoryId: subcategory?.categoryId ?? '',
            subcategoryName: subcategory?.name ?? '',
            // Plan 023: the run's hearts and power-ups come from the
            // entitlement, not from a fixed constant.
            perks: context.read<SubscriptionCubit>().state.perks,
            languageCode: languageCode,
          );
        } else {
          cubit.startDaily(languageCode: languageCode);
        }
        return cubit;
      },
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
    // **The pause trigger.** Besides the HUD's own pause button, the run
    // also pauses on a back gesture (the `PopScope` below) and on the app
    // being backgrounded, so nothing is lost to either.
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

  void _onDailyFinished(BuildContext context, DailyResult result) {
    context.pushReplacement(AppRoutes.dailyResult, extra: result);
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
          if (state is QuizPlayDailyFinished) {
            _onDailyFinished(context, state.result);
          }
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
                  child: BlocProvider<HeartAdCubit>(
                    create: (_) => HeartAdCubit(AdMobRewardedAdService()),
                    child: OutOfLivesDialog(
                      state: state,
                      onBackToMap: context.read<QuizPlayCubit>().abandonRun,
                    ),
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
      // last frame avoids a flash of empty arena on the way out. Same for a
      // daily run's two terminal states below.
      QuizPlayEnded() => const _ArenaSpinner(),
      QuizPlaySubmittingDaily() ||
      QuizPlayDailyFinished() => const _ArenaSpinner(),
      QuizPlayDailyAlreadyPlayed() => const _ArenaAlreadyPlayed(),
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
    // The question and its options follow the language the question is in,
    // not the UI locale — the run was fetched in exactly this language.
    final languageCode = context.read<ContentLanguageCubit>().state.code;
    final isRtl = textDirectionFor(languageCode) == TextDirection.rtl;
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
          isAudioOn: state.isAudioOn,
          onPausePressed: cubit.pause,
          onReportPressed: () => _openReportSheet(context),
          onToggleAudioPressed: cubit.toggleQuestionAudio,
        ),
        // §05's `slide` token: "Question card exits left / next enters
        // right." Keyed on the question's id, so a tick-driven rebuild
        // (same question, new `secondsRemaining`) never replays it — only an
        // actual advance does.
        Expanded(
          child: PageTransitionSwitcher(
            duration: AppMotion.durationOf(context, AppMotion.slide),
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
                SharedAxisTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Colors.transparent,
                  child: child,
                ),
            child: Column(
              key: ValueKey(state.question.id),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: hasImage ? 10.h : 12.h),
                  child: Center(
                    child: TimerRing(
                      secondsRemaining: state.secondsRemaining,
                      secondsTotal: state.run.secondsPerQuestion,
                      color: ringColor,
                      // The plate takes the room the full-size ring would
                      // need.
                      diameter: hasImage
                          ? TimerRing.imageDiameter
                          : TimerRing.defaultDiameter,
                      isPulsing: state.isDanger,
                    ),
                  ),
                ),
                QuestionMediaPlate(question: state.question),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18.w,
                    hasImage ? 12.h : 0,
                    18.w,
                    0,
                  ),
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
                    child: ContentLanguageScope(
                      languageCode: languageCode,
                      // Read inside the scope, so an RTL question gets the
                      // Nastaliq question style rather than the UI's.
                      child: Builder(
                        builder: (context) => Text(
                          state.question.text,
                          // The full question always renders — the options
                          // below live in their own `Expanded` scroll view,
                          // so a long question shrinking that space never
                          // overflows the arena.
                          style: Theme.of(context).textTheme.headlineSmall!
                              .copyWith(color: arena.onArena),
                        ),
                      ),
                    ),
                  ),
                ),
                // The options take whatever room the header leaves and
                // scroll inside it, so a long question or a long answer can
                // never push the power-up dock off the bottom of the arena —
                // `.pups` is `margin-top:auto`.
                //
                // Hidden entirely during `speaking` (TTS is still reading
                // the question), staggered in during `revealing`, plain once
                // `answering` — audio off/`ttsExcluded` skips straight to
                // `answering`, so this renders exactly as it always did
                // (CLAUDE.md-flagged regression guard, plan 007 Acceptance
                // criteria).
                if (state.phase != QuestionPhase.speaking)
                  Expanded(
                    child: ContentLanguageScope(
                      languageCode: languageCode,
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
                                child: _RevealingOption(
                                  index: index,
                                  isRevealing:
                                      state.phase == QuestionPhase.revealing,
                                  child: AnswerOption(
                                    label: state.question.options[index],
                                    optionKey: keys[index % keys.length],
                                    state: _optionState(index),
                                    onPressed:
                                        state.isAwaitingAnswer &&
                                            state.phase ==
                                                QuestionPhase.answering
                                        ? () => cubit.answer(index)
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
        ),
        // The dock is hidden while a verdict banner is up, which is what the
        // bible's S-12 and S-13 frames show — and always hidden on a daily
        // run, which has no power-up economy (§ QuizPlayCubit.startDaily).
        if (!state.run.isDaily &&
            state.isAwaitingAnswer &&
            state.phase == QuestionPhase.answering)
          PowerUpDock(
            inventory: state.powerUps,
            isDanger: state.isDanger,
            onUse: cubit.usePowerUp,
          ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(
          child: _ShakeOnWrong(feedback: state.feedback, child: body),
        ),
        if (!state.isAwaitingAnswer)
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

/// A daily run's tenth answer landed, but `play_daily_challenge` says the
/// player already has a `daily_attempts` row for today — a race (a second
/// tab, a double tap on "Play now") rather than the normal path, since the
/// initial `startDaily` fetch already checks this before showing a single
/// question.
class _ArenaAlreadyPlayed extends StatelessWidget {
  const _ArenaAlreadyPlayed();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.dailyPlayAlreadyPlayedTitle,
        emoji: '✅',
        message: l10n.dailyPlayAlreadyPlayedBody,
        action: ChunkyButton.ghost(
          label: l10n.commonBack,
          onPressed: context.pop,
        ),
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

    // Plan 023: `level_locked` means the client's map was stale (a free
    // player starting a level they cannot play) — say so rather than
    // offering the generic "could not load" copy. Anything else falls back
    // to that message as before.
    final message = switch (errorCode) {
      'level_locked' => l10n.playErrorLevelLocked,
      _ => l10n.contentErrorBody,
    };

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: message,
        errorCode: errorCode,
        action: ChunkyButton.ghost(
          label: l10n.commonBack,
          onPressed: context.pop,
        ),
      ),
    );
  }
}

/// One option's staggered fade+slide entrance during [QuestionPhase.revealing]
/// (spec §4.2: ~70-90ms per option). Renders [child] plain once the reveal
/// has finished, so a later rebuild (e.g. every clock tick in `answering`)
/// never replays the entrance.
class _RevealingOption extends StatelessWidget {
  const _RevealingOption({
    required this.index,
    required this.isRevealing,
    required this.child,
  });

  final int index;
  final bool isRevealing;
  final Widget child;

  static const Duration _staggerStep = Duration(milliseconds: 80);
  static const Duration _entranceDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    if (!isRevealing) return child;

    final duration = AppMotion.durationOf(context, _entranceDuration);
    return child
        .animate(delay: _staggerStep * index)
        .fadeIn(duration: duration)
        .slideY(begin: 0.15, end: 0, duration: duration, curve: Curves.easeOut);
  }
}
