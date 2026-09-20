import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/quiz_play/data/question_audio_cache_service.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/data/sound_effects_service.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';

part 'quiz_play_state.dart';

/// The single owner of a level: question index, clock, streak, hearts,
/// power-ups and score.
///
/// §25 of the bible: *"One QuizBloc owns the entire level… It emits a single
/// immutable QuizState — the UI never computes score."* Everything below
/// follows from that, including three details that are easy to get subtly
/// wrong and are therefore real invariants here rather than visual effects:
///
/// * **The clock does not start until "GO" has left the screen.** The first
///   question's ticker is started by [_beginQuestion], which the countdown
///   only reaches after its final beat.
/// * **A timeout costs a heart, exactly like a wrong answer.** [_resolveWrong]
///   and [_resolveTimeout] both decrement `heartsRemaining` (and both skip a
///   daily run's decorative hearts) — the clock running out is not a free
///   pass.
/// * **Pausing freezes the clock the instant the sheet begins animating**,
///   not when it lands — so [pause] stops the ticker synchronously, before
///   the sheet's entrance is even scheduled.
///
/// **A flagged deviation from §25's literal wording.** The bible says "the
/// timer is a `Ticker` in the bloc, not a `Timer.periodic` in the widget", and
/// gives two reasons: it must survive rebuilds and it must pause exactly with
/// the sheet. Both are properties of living *in the bloc*, which this does —
/// and the clock below is a `Timer` rather than a `Ticker` for two reasons of
/// its own:
///
/// * A `Ticker` needs `SchedulerBinding.instance`, which a pure-Dart Cubit
///   test has no reason to stand up. It would make the whole feature's
///   `bloc_test` suite (CLAUDE.md §11) depend on a widget binding and on
///   pumped frames to advance a second.
/// * Frame alignment buys nothing here anyway, because this Cubit deliberately
///   emits only when the **displayed second** changes. The ring's smooth sweep
///   is interpolated in `TimerRing`, which is where per-frame work belongs and
///   where §25 also puts it ("repaints via `CustomPainter` with
///   `RepaintBoundary`").
///
/// The spirit of the rule — one owner, survives rebuilds, pauses exactly — is
/// kept in full.
class QuizPlayCubit extends Cubit<QuizPlayState> {
  QuizPlayCubit(
    this._repository,
    this._settingsRepository,
    this._contentLanguageRepository,
    this._ttsService,
    this._soundEffects,
    this._audioCacheService, {
    this._dailyRepository,
  }) : super(const QuizPlayPreparing());

  final QuizPlayRepository _repository;
  final SettingsRepository _settingsRepository;
  final ContentLanguageRepository _contentLanguageRepository;
  final TtsService _ttsService;
  final SoundEffectsService _soundEffects;
  final QuestionAudioCacheService _audioCacheService;

  /// Only required by [startDaily] — scores a finished daily run via
  /// `play_daily_challenge`. Null for a level run, which never touches it.
  final DailyRepository? _dailyRepository;

  /// Set by [startDaily]; [_submitDaily] needs it to call back into the same
  /// language's challenge.
  String _dailyLanguageCode = 'en';

  /// How long a verdict banner stays up before advancing on its own (S-12).
  static const Duration autoAdvance = Duration(milliseconds: 2500);

  /// One second per countdown beat (S-10).
  static const Duration countdownBeat = Duration(seconds: 1);

  /// How often the clock is sampled. Fine enough that a whole second is
  /// never missed, coarse enough to cost nothing.
  static const Duration clockResolution = Duration(milliseconds: 100);

  /// The staggered fade+slide reveal's total window (§4.2: ~70-90ms per
  /// option) before the clock starts.
  static const Duration revealDuration = Duration(milliseconds: 450);

  /// How many upcoming questions' narration this Cubit tries to keep
  /// cached ahead of the current one (spec: "maintain 5 questions cached
  /// ahead").
  static const int audioPrefetchWindow = 5;

  Timer? _clockTimer;
  Timer? _autoAdvanceTimer;
  Timer? _countdownTimer;
  Timer? _revealTimer;

  /// Whether [_soundEffects] currently has the tick loop playing — tracked
  /// separately from [_clockTimer] so [_stopClock] only calls
  /// `stopTicking()` when there is actually something to stop, and so
  /// [toggleQuestionAudio] can bring the tick in or out of sync with a mute
  /// mid-question without touching the clock itself.
  bool _isTicking = false;

  List<Question> _questions = const [];
  int _questionIndex = 0;

  /// Read from `AppSettings.soundOn` at [startLevel] and kept in sync by
  /// [toggleQuestionAudio] — the HUD speaker icon's persisted preference.
  ///
  /// Settings screen labels this same preference "Sound effects" (S-42), so
  /// it gates [_soundEffects] too, not just question narration: one flag,
  /// one meaning, rather than a second toggle nobody asked for.
  bool _audioOn = true;

  /// False when [startLevel] found no voice pack for the active language —
  /// falls back to silent mode for the whole run rather than retrying every
  /// question (spec §4.1).
  bool _ttsAvailable = true;

  /// The current question's full allowance, which grows when +15s is spent.
  Duration _questionBudget = Duration.zero;

  /// How much of [_questionBudget] this question has burned so far.
  ///
  /// Accumulated from the clock's own ticks rather than read off a
  /// `Stopwatch`, for two reasons: it makes pausing trivially exact (stop
  /// ticking and the number simply stops moving, with no bookkeeping to get
  /// wrong), and it is deterministic under `fake_async`, so the clock's
  /// behaviour is unit-testable without a widget binding or a real 20-second
  /// wait. The cost is that a badly janked frame under-counts by a tick,
  /// which at this resolution is at most 100 ms in the player's favour.
  Duration _elapsed = Duration.zero;

  /// Loads the level and runs the countdown.
  ///
  /// The questions are normally already in hand: S-09's brief sheet prefetched
  /// them into the repository, so this resolves from cache with no network.
  Future<void> startLevel({
    required String levelId,
    required String categoryId,
    required String subcategoryName,
    String languageCode = 'en',
  }) async {
    final (subcategoryId, levelNumber) = MockCatalog.parseLevelId(levelId);
    emit(const QuizPlayPreparing());

    try {
      _questions = await _repository.questionsFor(
        levelId: levelId,
        subcategoryId: subcategoryId,
        levelNumber: levelNumber,
        languageCode: languageCode,
      );
    } on ApiException catch (error) {
      if (!isClosed) emit(QuizPlayFailed(error));
      return;
    }
    if (isClosed) return;

    if (_questions.isEmpty) {
      emit(
        const QuizPlayFailed(
          ApiException(
            'This level has no questions yet',
            kind: ApiErrorKind.notFound,
            code: 'ERR_CONTENT_404',
          ),
        ),
      );
      return;
    }

    final attemptId = _repository.attemptIdFor(
      levelId,
      languageCode: languageCode,
    );
    if (attemptId == null) {
      if (!isClosed) {
        emit(
          const QuizPlayFailed(
            ApiException('Missing attempt id', kind: ApiErrorKind.unknown),
          ),
        );
      }
      return;
    }

    _audioOn = _settingsRepository.current.soundOn;
    if (_audioOn) {
      final voiceId = await _contentLanguageRepository.voiceIdFor(languageCode);
      if (isClosed) return;
      _ttsAvailable = await _ttsService.setLanguage(
        languageCode,
        voiceId: voiceId,
      );
    } else {
      _ttsAvailable = false;
    }
    if (isClosed) return;

    if (_ttsAvailable) unawaited(_prefetchWindow(0));

    _questionIndex = 0;
    final run = QuizRun(
      attemptId: attemptId,
      levelId: levelId,
      subcategoryId: subcategoryId,
      subcategoryName: subcategoryName,
      categoryId: categoryId,
      levelNumber: levelNumber,
      // Server-authoritative, from the same start_level_attempt response
      // that dealt these questions — never re-derived from a client-side
      // ladder (plan 007, Design overview).
      secondsPerQuestion:
          _repository.secondsPerQuestionFor(
            levelId,
            languageCode: languageCode,
          ) ??
          0,
      questionCount: _questions.length,
      heartsRemaining: MockPlayer.livesPerLevel,
      isBoss:
          _repository.isBossFor(levelId, languageCode: languageCode) ?? false,
      powerUps: const PowerUpInventory(fiftyFifty: 1, addTime: 1),
      startedAt: DateTime.now(),
    );

    emit(QuizPlayCountdown(run: run, beat: 3));
    _scheduleNextBeat();
  }

  /// Loads today's real daily-challenge questions and runs the countdown —
  /// the daily challenge plays through this exact same arena rather than a
  /// separate screen (design decision: one play surface, not two). Hearts
  /// never deplete and there is no power-up dock for a [QuizRun.isDaily] run
  /// (see [_resolveWrong], [usePowerUp]); the run ends by scoring with the
  /// server instead of routing to a level-complete/failed screen (see
  /// [_finish], [_submitDaily]).
  Future<void> startDaily({required String languageCode}) async {
    _dailyLanguageCode = languageCode;
    emit(const QuizPlayPreparing());

    final DailyQuestionSession session;
    try {
      session = await _repository.questionsForDaily(languageCode: languageCode);
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(_dailyErrorState(error));
      return;
    }
    if (isClosed) return;

    if (session.questions.isEmpty) {
      emit(
        const QuizPlayFailed(
          ApiException(
            'No daily challenge today',
            kind: ApiErrorKind.notFound,
            code: 'ERR_CONTENT_404',
          ),
        ),
      );
      return;
    }

    _questions = session.questions;

    _audioOn = _settingsRepository.current.soundOn;
    if (_audioOn) {
      final voiceId = await _contentLanguageRepository.voiceIdFor(languageCode);
      if (isClosed) return;
      _ttsAvailable = await _ttsService.setLanguage(
        languageCode,
        voiceId: voiceId,
      );
    } else {
      _ttsAvailable = false;
    }
    if (isClosed) return;

    if (_ttsAvailable) unawaited(_prefetchWindow(0));

    _questionIndex = 0;
    final run = QuizRun(
      attemptId: 'daily',
      levelId: 'daily',
      subcategoryId: '',
      subcategoryName: '',
      categoryId: '',
      levelNumber: 0,
      secondsPerQuestion: session.secondsPerQuestion,
      questionCount: _questions.length,
      // Decorative only for a daily run — see _resolveWrong, which never
      // decrements this.
      heartsRemaining: MockPlayer.livesPerLevel,
      // Granted for symmetry with a level run, though the dock never renders
      // for `isDaily` (see quiz_play_screen.dart's guard) so it's inert here.
      powerUps: const PowerUpInventory(fiftyFifty: 1, addTime: 1),
      isDaily: true,
      startedAt: DateTime.now(),
    );

    emit(QuizPlayCountdown(run: run, beat: 3));
    _scheduleNextBeat();
  }

  QuizPlayState _dailyErrorState(ApiException error) =>
      error.code == 'already_played_today'
      ? const QuizPlayDailyAlreadyPlayed()
      : QuizPlayFailed(error);

  // --------------------------------------------------------------- countdown

  void _scheduleNextBeat() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer(countdownBeat, () {
      final current = state;
      if (current is! QuizPlayCountdown) return;
      if (current.isGo) {
        // "GO" has now left the screen — and only now does the clock start.
        _beginQuestion(current.run);
        return;
      }
      emit(QuizPlayCountdown(run: current.run, beat: current.beat - 1));
      _scheduleNextBeat();
    });
  }

  /// Skips straight to the first question, which S-10 allows by tap.
  void skipCountdown() {
    final current = state;
    if (current is! QuizPlayCountdown) return;
    _countdownTimer?.cancel();
    _beginQuestion(current.run);
  }

  // ---------------------------------------------------------------- questions

  void _beginQuestion(QuizRun run) {
    _stopClock();
    _revealTimer?.cancel();
    _elapsed = Duration.zero;
    _questionBudget = Duration(seconds: run.secondsPerQuestion);

    if (_ttsAvailable) unawaited(_prefetchWindow(_questionIndex + 1));

    final question = _questions[_questionIndex];
    final speaksThisQuestion =
        _audioOn &&
        _ttsAvailable &&
        !question.ttsExcluded &&
        question.audioUrl != null;
    final beganAt = _questionIndex;

    emit(
      QuizPlayInProgress(
        run: run,
        question: question,
        secondsRemaining: run.secondsPerQuestion,
        powerUps: run.powerUps,
        phase: speaksThisQuestion
            ? QuestionPhase.speaking
            : QuestionPhase.answering,
        isAudioOn: _audioOn,
      ),
    );

    if (speaksThisQuestion) {
      _ttsService.onComplete(() => _onSpeechComplete(beganAt));
      unawaited(_ttsService.speak(question.audioUrl!));
    } else {
      _startClock();
    }
  }

  /// Kicks off caching for up to [audioPrefetchWindow] questions starting
  /// at [fromIndex], skipping any that don't need audio at all
  /// (`ttsExcluded`, or no `audioUrl` yet). Best-effort and fire-and-forget
  /// at every call site — a slow or failed prefetch never blocks gameplay
  /// (spec §Design overview).
  Future<void> _prefetchWindow(int fromIndex) async {
    if (fromIndex >= _questions.length) return;
    final end = (fromIndex + audioPrefetchWindow).clamp(0, _questions.length);
    final urls = [
      for (var i = fromIndex; i < end; i++)
        if (!_questions[i].ttsExcluded && _questions[i].audioUrl != null)
          _questions[i].audioUrl!,
    ];
    if (urls.isEmpty) return;
    await _audioCacheService.prefetch(urls);
  }

  /// TTS finished (or was cancelled). [questionIndex] guards against a stale
  /// callback firing after `next()`/`skipCountdown()`/`_finish()` already
  /// moved on to a different question — the same defensive pattern
  /// [_countdownTimer]'s own callback already uses.
  void _onSpeechComplete(int questionIndex) {
    if (isClosed || questionIndex != _questionIndex) return;
    final current = state;
    if (current is! QuizPlayInProgress ||
        current.phase != QuestionPhase.speaking) {
      return;
    }
    emit(current.copyWith(phase: QuestionPhase.revealing));

    _revealTimer?.cancel();
    _revealTimer = Timer(revealDuration, () {
      if (isClosed || questionIndex != _questionIndex) return;
      final revealing = state;
      if (revealing is! QuizPlayInProgress ||
          revealing.phase != QuestionPhase.revealing) {
        return;
      }
      emit(revealing.copyWith(phase: QuestionPhase.answering));
      _startClock();
    });
  }

  /// The HUD speaker icon: toggles and persists `AppSettings.soundOn` for
  /// future levels, and — if the current question is still being read aloud
  /// — stops it and reveals immediately rather than waiting for a
  /// completion callback that will never fire (spec §4.2, point 4).
  void toggleQuestionAudio() {
    final current = state;
    if (current is! QuizPlayInProgress) return;

    final audioOn = !_audioOn;
    _settingsRepository.update(
      _settingsRepository.current.copyWith(soundOn: audioOn),
    );
    _audioOn = audioOn;

    if (current.phase == QuestionPhase.speaking && !audioOn) {
      _revealTimer?.cancel();
      unawaited(_ttsService.stop());
      emit(
        current.copyWith(isAudioOn: audioOn, phase: QuestionPhase.answering),
      );
      _startClock();
      return;
    }

    emit(current.copyWith(isAudioOn: audioOn));
    // The clock may already be answering-and-ticking; bring the tick in or
    // out of sync with the toggle immediately rather than leaving it to
    // whatever it was doing until the next question — muting mid-question
    // should actually mute, not just paint the speaker icon.
    if (current.isAwaitingAnswer && current.phase == QuestionPhase.answering) {
      if (audioOn && !_isTicking) {
        unawaited(_soundEffects.startTicking());
        _isTicking = true;
      } else if (!audioOn && _isTicking) {
        unawaited(_soundEffects.stopTicking());
        _isTicking = false;
      }
    }
  }

  /// Resumes the clock from wherever [_elapsed] currently stands.
  void _startClock() {
    _stopClock();
    if (_audioOn) {
      unawaited(_soundEffects.startTicking());
      _isTicking = true;
    }
    _clockTimer = Timer.periodic(clockResolution, (_) {
      _elapsed += clockResolution;
      _onTick();
    });
  }

  /// Freezes the clock. [_elapsed] is left where it is, which is what makes
  /// resuming continue rather than restart.
  ///
  /// Stops the tick only if [_isTicking] says one is actually playing —
  /// this runs on every defensive "cancel whatever's running" call site, not
  /// just the ones that end a live question, so a raw call count would be
  /// meaningless otherwise.
  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
    if (_isTicking) {
      unawaited(_soundEffects.stopTicking());
      _isTicking = false;
    }
  }

  /// Sampled ten times a second, but only *emits* when the displayed second
  /// changes.
  ///
  /// The ring itself interpolates between those whole seconds in the widget,
  /// which keeps the sweep smooth without pushing ten states a second through
  /// the Cubit.
  void _onTick() {
    final current = state;
    if (current is! QuizPlayInProgress || !current.isAwaitingAnswer) return;

    final remaining = _questionBudget - _elapsed;
    final seconds = remaining.inMilliseconds <= 0
        ? 0
        : (remaining.inMilliseconds / 1000).ceil();

    if (seconds == current.secondsRemaining) return;

    if (seconds <= 0) {
      _resolveTimeout(current);
      return;
    }
    emit(current.copyWith(secondsRemaining: seconds));
  }

  /// The player picked an option.
  void answer(int optionIndex) {
    final current = state;
    if (current is! QuizPlayInProgress || !current.isAwaitingAnswer) return;
    // Not tappable until the reveal has finished — the clock hasn't even
    // started yet during `speaking`/`revealing`.
    if (current.phase != QuestionPhase.answering) return;
    if (current.eliminatedIndexes.contains(optionIndex)) return;

    _stopClock();
    final isCorrect = optionIndex == current.question.correctIndex;
    if (isCorrect) {
      _resolveCorrect(current, optionIndex);
    } else {
      _resolveWrong(current, optionIndex);
    }
  }

  void _resolveCorrect(QuizPlayInProgress current, int optionIndex) {
    final run = current.run;
    // The multiplier counts the streak *before* this answer, matching the
    // bible's worked example: a 5-answer streak scores at ×1.5.
    final streakMultiplier = Scoring.streakMultiplier(run.currentStreak);
    final points = Scoring.questionScore(
      levelNumber: run.levelNumber,
      secondsLeft: current.secondsRemaining,
      secondsTotal: run.secondsPerQuestion,
      streak: run.currentStreak,
    );
    final streak = run.currentStreak + 1;

    final next = run.copyWith(
      answers: [
        ...run.answers,
        AnsweredQuestion(
          question: current.question,
          outcome: AnswerOutcome.correct,
          chosenIndex: optionIndex,
          secondsLeft: current.secondsRemaining,
          pointsEarned: points,
        ),
      ],
      score: run.score + points,
      currentStreak: streak,
      longestStreak: streak > run.longestStreak ? streak : run.longestStreak,
    );

    if (_audioOn) unawaited(_soundEffects.playCorrect());
    emit(
      current.copyWith(
        run: next,
        selectedIndex: optionIndex,
        feedback: CorrectFeedback(
          chosenIndex: optionIndex,
          pointsEarned: points,
          speedBonus: Scoring.speedBonus(
            secondsLeft: current.secondsRemaining,
            secondsTotal: run.secondsPerQuestion,
          ),
          difficultyMultiplier: Scoring.difficultyMultiplier(run.levelNumber),
          streakMultiplier: streakMultiplier,
        ),
      ),
    );
    _scheduleAutoAdvance();
  }

  void _resolveWrong(QuizPlayInProgress current, int optionIndex) {
    final run = current.run;
    // A daily run's hearts are decorative only — a wrong answer never costs
    // one and can never trigger the out-of-lives wall (this fix's whole
    // point: the daily challenge always plays all ten questions).
    final hearts = run.isDaily ? run.heartsRemaining : run.heartsRemaining - 1;
    final next = run.copyWith(
      answers: [
        ...run.answers,
        AnsweredQuestion(
          question: current.question,
          outcome: AnswerOutcome.wrong,
          chosenIndex: optionIndex,
          secondsLeft: current.secondsRemaining,
        ),
      ],
      currentStreak: 0,
      heartsRemaining: hearts,
    );

    final resolved = current.copyWith(
      run: next,
      selectedIndex: optionIndex,
      feedback: WrongFeedback(
        chosenIndex: optionIndex,
        heartsRemaining: hearts,
        brokeStreak: run.currentStreak > 0,
      ),
    );

    if (_audioOn) unawaited(_soundEffects.playWrong());

    // Hearts hit zero: S-19 offers a way back rather than ending the run —
    // but only when there is a run left to come back to. On the level's
    // final question there is nothing left to spend a rescued heart on, so
    // the wall would just be blocking the way to a result the player already
    // earned by reaching the last question.
    if (!run.isDaily &&
        hearts <= 0 &&
        next.answers.length < next.questionCount) {
      emit(QuizPlayOutOfLives(underlying: resolved));
      return;
    }

    emit(resolved);
    _scheduleAutoAdvance();
  }

  /// The clock ran out with nothing selected. Costs a heart exactly like a
  /// wrong answer — see [_resolveWrong], whose daily/out-of-lives handling
  /// this mirrors.
  void _resolveTimeout(QuizPlayInProgress current) {
    _stopClock();
    final run = current.run;
    final hearts = run.isDaily ? run.heartsRemaining : run.heartsRemaining - 1;
    final next = run.copyWith(
      answers: [
        ...run.answers,
        AnsweredQuestion(
          question: current.question,
          outcome: AnswerOutcome.timedOut,
        ),
      ],
      currentStreak: 0,
      heartsRemaining: hearts,
    );

    final resolved = current.copyWith(
      run: next,
      secondsRemaining: 0,
      feedback: TimeoutFeedback(
        heartsRemaining: hearts,
        brokeStreak: run.currentStreak > 0,
      ),
    );

    // See _resolveWrong: no wall on the final question, since there is
    // nothing left to spend a rescued heart on.
    if (!run.isDaily &&
        hearts <= 0 &&
        next.answers.length < next.questionCount) {
      emit(QuizPlayOutOfLives(underlying: resolved));
      return;
    }

    emit(resolved);
    _scheduleAutoAdvance();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(autoAdvance, next);
  }

  /// Moves to the next question, or ends the run after the twentieth.
  void next() {
    _autoAdvanceTimer?.cancel();
    final current = state.playing;
    if (current == null || current.isAwaitingAnswer) return;

    if (_questionIndex >= _questions.length - 1) {
      _finish(current.run, RunEnding.finished);
      return;
    }
    _questionIndex++;
    if (_audioOn) unawaited(_soundEffects.playNextQuestion());
    _beginQuestion(current.run);
  }

  // ---------------------------------------------------------------- power-ups

  /// Fires a power-up. A player with none of it does nothing here — a zero
  /// tile has no tap target, which is the widget's job to enforce.
  void usePowerUp(PowerUp powerUp) {
    final current = state;
    if (current is! QuizPlayInProgress || !current.isAwaitingAnswer) return;
    // No power-up dock on a daily run (§ startDaily) — a no-op here is a
    // defensive backstop, not the mechanism that hides it.
    if (current.run.isDaily) return;
    if (current.phase != QuestionPhase.answering) return;
    if (!current.powerUps.has(powerUp)) return;

    final spent = current.powerUps.spend(powerUp);
    // Any power-up forfeits the clean-run bonus (§19). The spend persists
    // onto `run` itself, not just this question's transient state, so it
    // survives into the next question's `_beginQuestion`.
    final run = current.run.copyWith(usedPowerUp: true, powerUps: spent);

    switch (powerUp) {
      case PowerUp.fiftyFifty:
        emit(
          current.copyWith(
            run: run,
            powerUps: spent,
            eliminatedIndexes: _twoWrongOptions(current.question),
          ),
        );
      case PowerUp.addTime:
        _questionBudget += const Duration(
          seconds: PowerUpInventory.addTimeSeconds,
        );
        emit(
          current.copyWith(
            run: run,
            powerUps: spent,
            secondsRemaining:
                current.secondsRemaining + PowerUpInventory.addTimeSeconds,
          ),
        );
    }
  }

  /// The two wrong options 50:50 removes — the first two that are not the
  /// answer, so the result is deterministic and a test can assert it.
  static Set<int> _twoWrongOptions(Question question) => {
    for (var index = 0; index < question.options.length; index++)
      if (index != question.correctIndex) index,
  }.take(2).toSet();

  // ------------------------------------------------------------------ pausing

  /// Freezes the clock and opens S-17.
  ///
  /// The stop happens **before** the emit that presents the sheet, which is
  /// the bible's "the timer freezes the instant the sheet begins its
  /// animation, not when it lands".
  void pause() {
    final current = state;
    if (current is! QuizPlayInProgress) return;
    _stopClock();
    _autoAdvanceTimer?.cancel();
    emit(QuizPlayPaused(underlying: _forceAnswering(current)));
  }

  /// If a question is still speaking/revealing when the player pauses or
  /// requests to quit, jumps it straight to `answering` — resuming a
  /// half-spoken TTS utterance isn't worth the complexity, and this keeps
  /// [resume]/[cancelQuit]'s existing "start the clock if awaiting an
  /// answer" logic correct for every underlying state, not just the ones
  /// that happened to already be answering.
  QuizPlayInProgress _forceAnswering(QuizPlayInProgress current) {
    if (current.phase == QuestionPhase.answering) return current;
    _revealTimer?.cancel();
    unawaited(_ttsService.stop());
    return current.copyWith(phase: QuestionPhase.answering);
  }

  void resume() {
    final current = state;
    if (current is! QuizPlayPaused) return;
    emit(current.underlying);
    if (current.underlying.isAwaitingAnswer) {
      _startClock();
    } else {
      _scheduleAutoAdvance();
    }
  }

  void toggleSound() {
    final current = state;
    if (current is! QuizPlayPaused) return;
    emit(
      QuizPlayPaused(
        underlying: current.underlying,
        isSoundOn: !current.isSoundOn,
        isHapticsOn: current.isHapticsOn,
      ),
    );
  }

  void toggleHaptics() {
    final current = state;
    if (current is! QuizPlayPaused) return;
    emit(
      QuizPlayPaused(
        underlying: current.underlying,
        isSoundOn: current.isSoundOn,
        isHapticsOn: !current.isHapticsOn,
      ),
    );
  }

  // ----------------------------------------------------------------- quitting

  /// Opens S-18. The clock freezes while the player decides.
  void requestQuit() {
    final current = state;
    final playing = current.playing;
    if (playing == null || current is QuizPlayQuitting) return;
    _stopClock();
    _autoAdvanceTimer?.cancel();
    emit(QuizPlayQuitting(_forceAnswering(playing)));
  }

  /// S-18's "Keep playing" — the dominant, first-listed action.
  void cancelQuit() {
    final current = state;
    if (current is! QuizPlayQuitting) return;
    emit(current.underlying);
    if (current.underlying.isAwaitingAnswer) {
      _startClock();
    } else {
      _scheduleAutoAdvance();
    }
  }

  /// Leaves the level. Recorded as [RunEnding.quit], deliberately distinct
  /// from running out of hearts so the result screen's copy can differ.
  void confirmQuit() {
    final run = state.run;
    if (run == null) return;
    _finish(run, RunEnding.quit);
  }

  // ------------------------------------------------------------- out of lives

  /// S-19's free option: a completed rewarded ad grants one heart.
  ///
  /// The ad itself is owned by `HeartAdCubit`/`RewardedAdService` — this
  /// Cubit never knows an ad is in flight, only the outcome, called by the
  /// dialog once `HeartAdCubit` reaches `HeartAdSucceeded`.
  void grantHeartFromAd() {
    final current = state;
    if (current is! QuizPlayOutOfLives) return;
    _grantHearts(current.underlying, hearts: 1);
  }

  /// S-19's second action: leave without watching an ad.
  ///
  /// Recorded as [RunEnding.outOfHearts], **not** as a quit. The player did
  /// not choose to walk away from a healthy run — they hit the wall. S-22's
  /// copy differs between the two, so conflating them would put "you ran out
  /// of hearts" on a run someone quit, or the reverse.
  void abandonRun() {
    final run = state.run;
    if (run == null) return;
    _finish(run, RunEnding.outOfHearts);
  }

  /// Puts the player back in the run with [hearts] in hand and lets the
  /// verdict banner advance as it would have.
  void _grantHearts(QuizPlayInProgress underlying, {required int hearts}) {
    emit(
      underlying.copyWith(
        run: underlying.run.copyWith(heartsRemaining: hearts),
      ),
    );
    _scheduleAutoAdvance();
  }

  // ------------------------------------------------------------------ ending

  void _finish(QuizRun run, RunEnding ending) {
    _stopClock();
    _autoAdvanceTimer?.cancel();
    _countdownTimer?.cancel();
    _revealTimer?.cancel();
    unawaited(_ttsService.stop());

    final finishedRun = run.copyWith(
      ending: ending,
      finishedAt: DateTime.now(),
    );

    if (run.isDaily) {
      unawaited(_submitDaily(finishedRun));
      return;
    }

    // A replay should re-deal the level rather than reuse this run's cache.
    _repository.forget(run.levelId);
    emit(QuizPlayEnded(finishedRun));
  }

  /// Scores a finished daily run against `play_daily_challenge`, which is
  /// the authoritative source for coins/streak/distribution — this never
  /// recomputes them client-side. [run]'s answers (right/wrong/timeout/
  /// skip) collapse to the boolean pattern the RPC expects; a question
  /// never reached (a quit before the tenth) simply isn't in the pattern,
  /// same as the RPC's own `array_length` scoring already handles.
  Future<void> _submitDaily(QuizRun run) async {
    final dailyRepository = _dailyRepository;
    if (dailyRepository == null) {
      if (!isClosed) {
        emit(
          const QuizPlayFailed(
            ApiException(
              'Missing daily repository',
              kind: ApiErrorKind.unknown,
            ),
          ),
        );
      }
      return;
    }

    emit(QuizPlaySubmittingDaily(run));
    try {
      final pattern = [for (final answer in run.answers) answer.isCorrect];
      final result = await dailyRepository.playToday(
        languageCode: _dailyLanguageCode,
        answerPattern: pattern,
      );
      if (isClosed) return;
      emit(QuizPlayDailyFinished(result));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(_dailyErrorState(error));
    }
  }

  @override
  Future<void> close() {
    _stopClock();
    _autoAdvanceTimer?.cancel();
    _countdownTimer?.cancel();
    _revealTimer?.cancel();
    unawaited(_ttsService.stop());
    unawaited(_ttsService.dispose());
    unawaited(_soundEffects.dispose());
    return super.close();
  }
}
