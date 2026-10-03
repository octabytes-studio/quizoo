import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/subscription/pro_perks.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/data/question_audio_cache_service.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/data/sound_effects_service.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/domain/app_settings.dart';

class _MockQuizPlayRepository extends Mock implements QuizPlayRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockContentLanguageRepository extends Mock
    implements ContentLanguageRepository {}

/// A fake rather than a mocktail `Mock`: the Cubit's phase machine drives
/// this through real completion-callback timing (`complete()`), which a
/// stubbed `Mock` can't express.
class _FakeTtsService implements TtsService {
  bool languageAvailable = true;
  void Function()? _onComplete;

  /// The `audioUrl`s passed to [speak], in call order.
  final List<String> spoken = [];
  int stopCount = 0;

  @override
  Future<bool> setLanguage(String languageCode, {String? voiceId}) async =>
      voiceId != null && languageAvailable;

  @override
  Future<void> speak(String audioUrl) async => spoken.add(audioUrl);

  @override
  Future<void> stop() async => stopCount++;

  @override
  void onComplete(void Function() callback) => _onComplete = callback;

  @override
  Future<void> dispose() async {}

  /// Test hook: simulates the plugin firing its completion handler.
  void complete() => _onComplete?.call();
}

/// A fake rather than a mocktail `Mock` — plain call counters are simpler
/// than stubbing five void-returning `Future<void>` methods for a service
/// with no meaningful return value to script.
class _FakeSoundEffectsService implements SoundEffectsService {
  int tickStartCount = 0;
  int tickStopCount = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int nextCount = 0;

  @override
  Future<void> startTicking() async => tickStartCount++;

  @override
  Future<void> stopTicking() async => tickStopCount++;

  @override
  Future<void> playCorrect() async => correctCount++;

  @override
  Future<void> playWrong() async => wrongCount++;

  @override
  Future<void> playNextQuestion() async => nextCount++;

  @override
  Future<void> dispose() async {}
}

/// A fake rather than a mocktail `Mock`: recording call arguments in order
/// matters more than stubbing return values (same reasoning as
/// `_FakeTtsService` above).
class _FakeAudioCacheService implements QuestionAudioCacheService {
  /// Each `prefetch` call's URL list, in call order.
  final List<List<String>> prefetchCalls = [];

  @override
  Future<void> prefetch(List<String> urls) async {
    prefetchCalls.add(urls);
  }

  @override
  Future<String?> localPathFor(String url) async => null;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  late _MockQuizPlayRepository repository;
  late _MockSettingsRepository settingsRepository;
  late _MockContentLanguageRepository contentLanguageRepository;
  late _FakeTtsService ttsService;
  late _FakeSoundEffectsService soundEffects;
  late _FakeAudioCacheService audioCacheService;

  final levelId = MockCatalog.levelId(MockCatalog.footballId, 12);
  final questions = MockQuestions.forLevel(
    subcategoryId: MockCatalog.footballId,
    levelNumber: 12,
  ).map((q) => q.copyWith(audioUrl: 'https://cdn.test/audio.mp3')).toList();

  setUp(() {
    repository = _MockQuizPlayRepository();
    when(() => repository.forget(any())).thenReturn(null);

    // Audio off by default — every existing test below exercises exactly
    // today's instant-reveal behavior (plan 007's own regression guard).
    // Tests of the TTS phase machine itself opt into audio explicitly.
    settingsRepository = _MockSettingsRepository();
    when(
      () => settingsRepository.current,
    ).thenReturn(const AppSettings(soundOn: false));
    when(() => settingsRepository.update(any())).thenAnswer(
      (invocation) => invocation.positionalArguments.first as AppSettings,
    );

    contentLanguageRepository = _MockContentLanguageRepository();
    when(
      () => contentLanguageRepository.voiceIdFor(any()),
    ).thenAnswer((_) async => 'voice-placeholder');

    ttsService = _FakeTtsService();
    soundEffects = _FakeSoundEffectsService();
    audioCacheService = _FakeAudioCacheService();
  });

  QuizPlayCubit buildCubit() => QuizPlayCubit(
    repository,
    settingsRepository,
    contentLanguageRepository,
    ttsService,
    soundEffects,
    audioCacheService,
  );

  void stubQuestions([
    List<Question>? override,
    int secondsPerQuestion = 20,
    bool isBoss = false,
  ]) {
    when(
      () => repository.questionsFor(
        levelId: any(named: 'levelId'),
        subcategoryId: any(named: 'subcategoryId'),
        levelNumber: any(named: 'levelNumber'),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => override ?? questions);
    when(
      () => repository.attemptIdFor(
        any(),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenReturn('attempt_test');
    when(
      () => repository.secondsPerQuestionFor(
        any(),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenReturn(secondsPerQuestion);
    when(
      () =>
          repository.isBossFor(any(), languageCode: any(named: 'languageCode')),
    ).thenReturn(isBoss);
  }

  Future<void> start(QuizPlayCubit cubit) => cubit.startLevel(
    levelId: levelId,
    categoryId: MockCatalog.sportsId,
    subcategoryName: 'Football',
    perks: const ProPerks.free(),
  );

  group('QuizPlayCubit', () {
    test('starts in the preparing state', () {
      expect(buildCubit().state, isA<QuizPlayPreparing>());
    });

    blocTest<QuizPlayCubit, QuizPlayState>(
      'success path: loads a level and opens the countdown at 3',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: start,
      expect: () => [
        isA<QuizPlayPreparing>(),
        isA<QuizPlayCountdown>()
            .having((state) => state.beat, 'beat', 3)
            .having((state) => state.run.levelNumber, 'level', 12)
            .having((state) => state.run.secondsPerQuestion, 'seconds', 20),
      ],
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'uses the server-authoritative seconds/isBoss from the prepared '
      'level, never a hardcoded ladder',
      setUp: () => stubQuestions(null, 7, true),
      build: () => buildCubit(),
      act: start,
      expect: () => [
        isA<QuizPlayPreparing>(),
        isA<QuizPlayCountdown>()
            .having((state) => state.run.secondsPerQuestion, 'seconds', 7)
            .having((state) => state.run.isBoss, 'isBoss', isTrue),
      ],
    );

    test('audio on: speaking -> revealing -> answering, clock starts only '
        'once answering', () {
      stubQuestions();
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        var state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.speaking);
        expect(state.secondsRemaining, 20);
        expect(ttsService.spoken, [state.question.audioUrl]);

        // Nothing moves while still speaking, however long it takes.
        async.elapse(const Duration(seconds: 5));
        state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.speaking);
        expect(state.secondsRemaining, 20);

        ttsService.complete();
        state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.revealing);
        expect(state.secondsRemaining, 20, reason: 'clock still not running');

        async.elapse(QuizPlayCubit.revealDuration);
        state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.answering);

        async.elapse(const Duration(seconds: 3));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 17);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('toggling audio off mid-speech stops TTS and reveals immediately', () {
      stubQuestions();
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        expect(
          (cubit.state as QuizPlayInProgress).phase,
          QuestionPhase.speaking,
        );

        cubit.toggleQuestionAudio();

        final state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.answering);
        expect(state.isAudioOn, isFalse);
        expect(ttsService.stopCount, 1);

        // The clock is now actually running, straight from the toggle.
        async.elapse(const Duration(seconds: 2));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 18);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test(
      'a ttsExcluded question skips straight to answering, audio or not',
      () {
        stubQuestions([
          questions.first.copyWith(ttsExcluded: true),
          ...questions.skip(1),
        ]);
        when(
          () => settingsRepository.current,
        ).thenReturn(const AppSettings(soundOn: true));
        fakeAsync((async) {
          final cubit = buildCubit();
          unawaited(start(cubit));
          async.flushMicrotasks();
          cubit.skipCountdown();

          final state = cubit.state as QuizPlayInProgress;
          expect(state.phase, QuestionPhase.answering);
          expect(ttsService.spoken, isEmpty);

          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      },
    );

    test('a question with no audioUrl skips straight to answering, audio or '
        'not', () {
      stubQuestions([
        questions.first.copyWith(audioUrl: null),
        ...questions.skip(1),
      ]);
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        final state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.answering);
        expect(ttsService.spoken, isEmpty);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test(
      'falls back to silent mode when the active language has no voice pack',
      () {
        stubQuestions();
        ttsService.languageAvailable = false;
        when(
          () => settingsRepository.current,
        ).thenReturn(const AppSettings(soundOn: true));
        fakeAsync((async) {
          final cubit = buildCubit();
          unawaited(start(cubit));
          async.flushMicrotasks();
          cubit.skipCountdown();

          final state = cubit.state as QuizPlayInProgress;
          expect(state.phase, QuestionPhase.answering);
          expect(ttsService.spoken, isEmpty);

          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      },
    );

    test('falls back to silent mode when no voice_id is configured for the '
        'active language', () {
      stubQuestions();
      when(
        () => contentLanguageRepository.voiceIdFor(any()),
      ).thenAnswer((_) async => null);
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        final state = cubit.state as QuizPlayInProgress;
        expect(state.phase, QuestionPhase.answering);
        expect(ttsService.spoken, isEmpty);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('starting a level with audio available prefetches the first '
        'audioPrefetchWindow questions during the countdown', () {
      stubQuestions();
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();

        expect(
          audioCacheService.prefetchCalls.first,
          questions
              .take(QuizPlayCubit.audioPrefetchWindow)
              .map((q) => q.audioUrl)
              .toList(),
        );

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('advancing to the next question tops up the prefetch window', () {
      stubQuestions();
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        for (var i = 0; i < 3; i++) {
          ttsService.complete();
          async.elapse(QuizPlayCubit.revealDuration);
          final question = (cubit.state as QuizPlayInProgress).question;
          cubit.answer(question.correctIndex);
          async.elapse(QuizPlayCubit.autoAdvance);
        }

        // Question index is now 3 (0-indexed); the window should have
        // topped up to include question 7 (3 + audioPrefetchWindow - 1),
        // which the initial countdown-time call never covered.
        final laterQuestionUrl = questions[7].audioUrl;
        expect(
          audioCacheService.prefetchCalls.any(
            (call) => call.contains(laterQuestionUrl),
          ),
          isTrue,
        );

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    blocTest<QuizPlayCubit, QuizPlayState>(
      'failure path: a failed fetch ends in QuizPlayFailed',
      setUp: () {
        when(
          () => repository.questionsFor(
            levelId: any(named: 'levelId'),
            subcategoryId: any(named: 'subcategoryId'),
            levelNumber: any(named: 'levelNumber'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenThrow(const ApiException.network());
      },
      build: () => buildCubit(),
      act: start,
      expect: () => [isA<QuizPlayPreparing>(), isA<QuizPlayFailed>()],
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'a topic with no questions behind it fails rather than opening empty',
      setUp: () => stubQuestions(const []),
      build: () => buildCubit(),
      act: start,
      expect: () => [
        isA<QuizPlayPreparing>(),
        isA<QuizPlayFailed>().having(
          (state) => state.error.kind,
          'kind',
          ApiErrorKind.notFound,
        ),
      ],
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'the clock does not start until the countdown has finished',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<QuizPlayInProgress>());
        state as QuizPlayInProgress;
        // The first question opens on a full clock — it was never ticking
        // underneath the countdown.
        expect(state.secondsRemaining, 20);
        expect(state.isAwaitingAnswer, isTrue);
        expect(state.run.answers, isEmpty);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'a correct answer scores by §19 and extends the streak',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        final question = (cubit.state as QuizPlayInProgress).question;
        cubit.answer(question.correctIndex);
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayInProgress;
        final feedback = state.feedback as CorrectFeedback;

        // Level 12, answered on a full 20-second clock, no streak yet:
        // (100 + 100) × 1.55 × 1.0 = 310.
        expect(feedback.pointsEarned, 310);
        expect(feedback.speedBonus, 100);
        expect(feedback.difficultyMultiplier, closeTo(1.55, 0.001));
        expect(feedback.streakMultiplier, 1.0);

        expect(state.run.score, 310);
        expect(state.run.currentStreak, 1);
        expect(state.run.longestStreak, 1);
        expect(state.run.heartsRemaining, 3);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'a wrong answer costs a heart, resets the streak and reveals the answer',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        final question = (cubit.state as QuizPlayInProgress).question;
        cubit.answer((question.correctIndex + 1) % question.options.length);
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayInProgress;
        final feedback = state.feedback as WrongFeedback;

        expect(state.run.heartsRemaining, 2);
        expect(state.run.currentStreak, 0);
        expect(state.run.score, 0);
        expect(feedback.heartsRemaining, 2);
        // The correct index is still on the state, which is what lets the
        // screen light the right answer mint alongside the wrong one.
        expect(state.question.correctIndex, isNot(feedback.chosenIndex));
      },
    );

    test('sound off (default): no sound effect plays through a full '
        'answer + advance cycle', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        final question = (cubit.state as QuizPlayInProgress).question;
        cubit.answer(question.correctIndex);
        async.elapse(QuizPlayCubit.autoAdvance);

        expect(soundEffects.tickStartCount, 0);
        expect(soundEffects.tickStopCount, 0);
        expect(soundEffects.correctCount, 0);
        expect(soundEffects.nextCount, 0);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('sound on: the tick starts once answering begins, stops on '
        'answer, the right chime plays, and next() plays the advance '
        'chime', () {
      stubQuestions();
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        // Still speaking — the clock (and so the tick) has not started.
        expect(soundEffects.tickStartCount, 0);
        ttsService.complete();
        async.elapse(QuizPlayCubit.revealDuration);
        expect(soundEffects.tickStartCount, 1);

        final question = (cubit.state as QuizPlayInProgress).question;
        cubit.answer(question.correctIndex);
        expect(soundEffects.tickStopCount, 1);
        expect(soundEffects.correctCount, 1);
        expect(soundEffects.wrongCount, 0);

        async.elapse(QuizPlayCubit.autoAdvance);
        expect(soundEffects.nextCount, 1);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('sound on: a wrong answer plays the wrong chime and stops the '
        'tick', () {
      stubQuestions([
        questions.first.copyWith(ttsExcluded: true),
        ...questions.skip(1),
      ]);
      when(
        () => settingsRepository.current,
      ).thenReturn(const AppSettings(soundOn: true));
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();
        // ttsExcluded skips straight to answering, so the tick is already
        // running.
        expect(soundEffects.tickStartCount, 1);

        final question = (cubit.state as QuizPlayInProgress).question;
        cubit.answer((question.correctIndex + 1) % question.options.length);

        expect(soundEffects.tickStopCount, 1);
        expect(soundEffects.wrongCount, 1);
        expect(soundEffects.correctCount, 0);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('a timeout costs the question and a heart, like a wrong answer', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        // Let the whole 20-second clock run out with nothing selected.
        async.elapse(const Duration(seconds: 21));

        final state = cubit.state as QuizPlayInProgress;
        final feedback = state.feedback as TimeoutFeedback;
        expect(state.run.answers.single.outcome, AnswerOutcome.timedOut);
        expect(state.run.heartsRemaining, 2);
        expect(feedback.heartsRemaining, 2);
        expect(state.run.currentStreak, 0);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('three timeouts in a row open S-19 rather than ending the run', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        for (var attempt = 0; attempt < 2; attempt++) {
          async.elapse(const Duration(seconds: 21));
          cubit.next();
          async.flushMicrotasks();
        }
        async.elapse(const Duration(seconds: 21));

        final state = cubit.state;
        expect(state, isA<QuizPlayOutOfLives>());
        expect((state as QuizPlayOutOfLives).underlying.run.heartsRemaining, 0);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('the clock counts down while a question is live', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 20);
        async.elapse(const Duration(seconds: 6));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 14);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('the arena enters its danger state in the last five seconds', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        async.elapse(const Duration(seconds: 14));
        expect((cubit.state as QuizPlayInProgress).isDanger, isFalse);

        async.elapse(const Duration(seconds: 1));
        expect((cubit.state as QuizPlayInProgress).isDanger, isTrue);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('+5s extends the clock rather than restarting it', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        async.elapse(const Duration(seconds: 5));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 15);

        cubit.usePowerUp(PowerUp.addTime);
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 20);

        async.elapse(const Duration(seconds: 2));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 18);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    blocTest<QuizPlayCubit, QuizPlayState>(
      'losing the last heart opens S-19 rather than ending the run',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        for (var attempt = 0; attempt < 3; attempt++) {
          final state = cubit.state.playing!;
          cubit.answer(
            (state.question.correctIndex + 1) % state.question.options.length,
          );
          if (cubit.state is QuizPlayInProgress) cubit.next();
        }
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<QuizPlayOutOfLives>());
        expect((state as QuizPlayOutOfLives).underlying.run.heartsRemaining, 0);
      },
    );

    test('pausing freezes the clock and resuming continues from there', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = buildCubit();
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        async.elapse(const Duration(seconds: 4));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 16);

        cubit.pause();
        async.elapse(const Duration(seconds: 10));

        // Ten seconds passed with the sheet up and the clock did not move.
        final paused = cubit.state as QuizPlayPaused;
        expect(paused.underlying.secondsRemaining, 16);

        // Resuming continues from 16, not from a fresh 20.
        cubit.resume();
        async.elapse(const Duration(seconds: 3));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 13);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    blocTest<QuizPlayCubit, QuizPlayState>(
      '50:50 removes exactly two wrong options and forfeits the clean run',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        cubit.usePowerUp(PowerUp.fiftyFifty);
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayInProgress;

        expect(state.eliminatedIndexes, hasLength(2));
        expect(
          state.eliminatedIndexes.contains(state.question.correctIndex),
          isFalse,
          reason: '50:50 must never remove the correct answer',
        );
        expect(state.powerUps.fiftyFifty, 0);
        expect(state.run.usedPowerUp, isTrue);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'a spent power-up stays spent into the next question rather than '
      'being re-seeded (regression guard, plan 013)',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        cubit.usePowerUp(PowerUp.fiftyFifty);
        final question = (cubit.state as QuizPlayInProgress).question;
        cubit
          ..answer(question.correctIndex)
          ..next();
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayInProgress;
        expect(state.powerUps.fiftyFifty, 0);
        expect(state.run.powerUps.fiftyFifty, 0);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'grantHeartFromAd puts one heart back and resumes the run',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        for (var attempt = 0; attempt < 3; attempt++) {
          final playing = cubit.state.playing!;
          cubit.answer(
            (playing.question.correctIndex + 1) %
                playing.question.options.length,
          );
          if (cubit.state is QuizPlayInProgress) cubit.next();
        }
        cubit.grantHeartFromAd();
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<QuizPlayInProgress>());
        expect((state as QuizPlayInProgress).run.heartsRemaining, 1);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'leaving from S-19 is recorded as a heart loss, not a quit',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        for (var attempt = 0; attempt < 3; attempt++) {
          final playing = cubit.state.playing!;
          cubit.answer(
            (playing.question.correctIndex + 1) %
                playing.question.options.length,
          );
          if (cubit.state is QuizPlayInProgress) cubit.next();
        }
        cubit.abandonRun();
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayEnded;
        expect(state.run.ending, RunEnding.outOfHearts);
        expect(state.run.ending, isNot(RunEnding.quit));
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'quitting is recorded distinctly from running out of hearts',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        cubit
          ..requestQuit()
          ..confirmQuit();
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayEnded;
        expect(state.run.ending, RunEnding.quit);
        expect(state.run.ending, isNot(RunEnding.outOfHearts));
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'answering all twenty correctly ends the run finished and flawless',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        while (cubit.state is QuizPlayInProgress) {
          final state = cubit.state as QuizPlayInProgress;
          cubit
            ..answer(state.question.correctIndex)
            ..next();
        }
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayEnded;
        expect(state.run.ending, RunEnding.finished);
        expect(state.run.correctCount, MockQuestions.questionsPerLevel);
        expect(state.run.isFlawless, isTrue);
        expect(
          Scoring.stars(state.run.correctCount, state.run.questionCount),
          3,
        );
        // The breakdown is the only source of the total, so it always sums.
        expect(
          Scoring.breakdown(state.run).fold<int>(0, (a, b) => a + b.value),
          Scoring.total(state.run),
        );
      },
    );

    late bool isLastQuestionAtNineteen;
    blocTest<QuizPlayCubit, QuizPlayState>(
      'isLastQuestion only flips true on the twentieth verdict, not the '
      "nineteenth's",
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        for (var i = 0; i < MockQuestions.questionsPerLevel - 2; i++) {
          final state = cubit.state as QuizPlayInProgress;
          cubit
            ..answer(state.question.correctIndex)
            ..next();
        }
        // Now on the nineteenth question — answering it must not yet flag
        // the banner as the level's last.
        final nineteenth = cubit.state as QuizPlayInProgress;
        cubit.answer(nineteenth.question.correctIndex);
        isLastQuestionAtNineteen =
            (cubit.state as QuizPlayInProgress).isLastQuestion;
        cubit.next();
        final twentieth = cubit.state as QuizPlayInProgress;
        cubit.answer(twentieth.question.correctIndex);
      },
      verify: (cubit) {
        expect(isLastQuestionAtNineteen, isFalse);
        final state = cubit.state as QuizPlayInProgress;
        expect(state.run.answers.length, MockQuestions.questionsPerLevel);
        expect(state.isLastQuestion, isTrue);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'running out of hearts on the final question finishes the run instead '
      'of opening S-19',
      setUp: stubQuestions,
      build: () => buildCubit(),
      act: (cubit) async {
        await start(cubit);
        cubit.skipCountdown();
        var wrongsSpent = 0;
        while (cubit.state is QuizPlayInProgress) {
          final state = cubit.state as QuizPlayInProgress;
          final isFinalQuestion =
              state.run.answers.length == MockQuestions.questionsPerLevel - 1;
          final answerWrong = wrongsSpent < 2 || isFinalQuestion;
          if (answerWrong) wrongsSpent++;
          cubit.answer(
            answerWrong
                ? (state.question.correctIndex + 1) %
                      state.question.options.length
                : state.question.correctIndex,
          );
          cubit.next();
        }
      },
      verify: (cubit) {
        final state = cubit.state as QuizPlayEnded;
        expect(state.run.heartsRemaining, 0);
        expect(state.run.ending, RunEnding.finished);
      },
    );
  });
}
