import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/domain/app_settings.dart';

/// Covers `QuizPlayCubit.startDaily` — the daily challenge playing through
/// the same arena a level does (design decision: one play surface, not two).
/// Level-run behavior stays in quiz_play_cubit_test.dart; this file is only
/// the daily-specific surface: hearts never depleting, no power-up dock, and
/// ending by scoring with the server instead of routing to a level result.
class _MockQuizPlayRepository extends Mock implements QuizPlayRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockDailyRepository extends Mock implements DailyRepository {}

class _NoopTtsService implements TtsService {
  @override
  Future<void> speak(String audioUrl) async {}

  @override
  Future<void> stop() async {}

  @override
  void onComplete(void Function() callback) {}

  @override
  Future<void> dispose() async {}
}

class _NoopSoundEffectsService implements SoundEffectsService {
  @override
  Future<void> startTicking() async {}

  @override
  Future<void> stopTicking() async {}

  @override
  Future<void> playCorrect() async {}

  @override
  Future<void> playWrong() async {}

  @override
  Future<void> playNextQuestion() async {}

  @override
  Future<void> dispose() async {}
}

class _NoopAudioCacheService implements QuestionAudioCacheService {
  @override
  Future<void> prefetch(List<String> urls) async {}

  @override
  Future<String?> localPathFor(String url) async => null;
}

void main() {
  late _MockQuizPlayRepository repository;
  late _MockSettingsRepository settingsRepository;
  late _MockDailyRepository dailyRepository;

  const questions = [
    Question(
      id: 'q1',
      subcategoryId: 'sub',
      difficulty: 1,
      text: 'Q1',
      options: ['A', 'B'],
      correctIndex: 0,
      explanation: '',
      ttsExcluded: true,
    ),
    Question(
      id: 'q2',
      subcategoryId: 'sub',
      difficulty: 1,
      text: 'Q2',
      options: ['A', 'B'],
      correctIndex: 1,
      explanation: '',
      ttsExcluded: true,
    ),
  ];

  const session = DailyQuestionSession(
    questions: questions,
    secondsPerQuestion: 20,
  );

  const result = DailyResult(
    correctCount: 1,
    totalCount: 2,
    betterThanPercent: 50,
    distributionPercents: [10, 20, 30, 20, 20],
    highlightedBucketIndex: 0,
    coinsEarned: 300,
    streakNow: 4,
    answerPattern: [true, false],
  );

  const alreadyPlayed = ApiException(
    'already_played_today',
    kind: ApiErrorKind.server,
    code: 'already_played_today',
  );

  setUpAll(() {
    registerFallbackValue(const <bool>[]);
  });

  setUp(() {
    repository = _MockQuizPlayRepository();
    settingsRepository = _MockSettingsRepository();
    when(
      () => settingsRepository.current,
    ).thenReturn(const AppSettings(soundOn: false));
    dailyRepository = _MockDailyRepository();
  });

  QuizPlayCubit buildCubit() => QuizPlayCubit(
    repository,
    settingsRepository,
    _NoopTtsService(),
    _NoopSoundEffectsService(),
    _NoopAudioCacheService(),
    dailyRepository: dailyRepository,
  );

  blocTest<QuizPlayCubit, QuizPlayState>(
    'success path: loads today\'s real questions and opens the countdown',
    setUp: () => when(
      () => repository.questionsForDaily(
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => session),
    build: buildCubit,
    act: (cubit) => cubit.startDaily(languageCode: 'en'),
    expect: () => [
      isA<QuizPlayPreparing>(),
      isA<QuizPlayCountdown>()
          .having((state) => state.run.isDaily, 'isDaily', isTrue)
          .having((state) => state.run.questionCount, 'questionCount', 2),
    ],
  );

  blocTest<QuizPlayCubit, QuizPlayState>(
    'already-played: the initial fetch surfaces its own state, not a '
    'generic error',
    setUp: () => when(
      () => repository.questionsForDaily(
        languageCode: any(named: 'languageCode'),
      ),
    ).thenThrow(alreadyPlayed),
    build: buildCubit,
    act: (cubit) => cubit.startDaily(languageCode: 'en'),
    expect: () => [isA<QuizPlayPreparing>(), isA<QuizPlayDailyAlreadyPlayed>()],
  );

  blocTest<QuizPlayCubit, QuizPlayState>(
    'a wrong answer never costs a heart or opens the out-of-lives wall',
    setUp: () => when(
      () => repository.questionsForDaily(
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => session),
    build: buildCubit,
    act: (cubit) async {
      await cubit.startDaily(languageCode: 'en');
      cubit.skipCountdown();
      // Wrong: q1's correctIndex is 0.
      cubit.answer(1);
    },
    verify: (cubit) {
      final state = cubit.state as QuizPlayInProgress;
      expect(state.run.heartsRemaining, greaterThan(0));
      expect(cubit.state, isNot(isA<QuizPlayOutOfLives>()));
    },
  );

  blocTest<QuizPlayCubit, QuizPlayState>(
    'finishing the run submits the real pattern and ends scored by the '
    'server, never a level-complete/failed route',
    setUp: () {
      when(
        () => repository.questionsForDaily(
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => session);
      when(
        () => dailyRepository.playToday(
          languageCode: any(named: 'languageCode'),
          answerPattern: any(named: 'answerPattern'),
        ),
      ).thenAnswer((_) async => result);
    },
    build: buildCubit,
    act: (cubit) async {
      await cubit.startDaily(languageCode: 'en');
      cubit.skipCountdown();
      cubit
        ..answer(0) // correct
        ..next();
      cubit
        ..answer(0) // wrong: q2's correctIndex is 1
        ..next();
    },
    wait: const Duration(milliseconds: 1),
    verify: (cubit) {
      expect(cubit.state, isA<QuizPlayDailyFinished>());
      expect((cubit.state as QuizPlayDailyFinished).result, result);
      verify(
        () => dailyRepository.playToday(
          languageCode: 'en',
          answerPattern: [true, false],
        ),
      ).called(1);
    },
  );

  blocTest<QuizPlayCubit, QuizPlayState>(
    'already played at submit time (a race, not the normal path) surfaces '
    'the same friendly state as the initial fetch',
    setUp: () {
      when(
        () => repository.questionsForDaily(
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => session);
      when(
        () => dailyRepository.playToday(
          languageCode: any(named: 'languageCode'),
          answerPattern: any(named: 'answerPattern'),
        ),
      ).thenThrow(alreadyPlayed);
    },
    build: buildCubit,
    act: (cubit) async {
      await cubit.startDaily(languageCode: 'en');
      cubit.skipCountdown();
      cubit
        ..answer(0)
        ..next();
      cubit
        ..answer(1)
        ..next();
    },
    wait: const Duration(milliseconds: 1),
    verify: (cubit) {
      expect(cubit.state, isA<QuizPlayDailyAlreadyPlayed>());
    },
  );

  blocTest<QuizPlayCubit, QuizPlayState>(
    'usePowerUp is a no-op on a daily run — there is no power-up economy',
    setUp: () => when(
      () => repository.questionsForDaily(
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => session),
    build: buildCubit,
    act: (cubit) async {
      await cubit.startDaily(languageCode: 'en');
      cubit.skipCountdown();
      cubit.usePowerUp(PowerUp.fiftyFifty);
    },
    verify: (cubit) {
      final state = cubit.state as QuizPlayInProgress;
      expect(state.eliminatedIndexes, isEmpty);
      expect(state.run.usedPowerUp, isFalse);
    },
  );
}
