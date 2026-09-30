import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_api.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_repository.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockQuizResultApi extends Mock implements QuizResultApi {}

class _MockAuthApi extends Mock implements AuthApi {}

class _MockLadderConfigRepository extends Mock
    implements LadderConfigRepository {}

/// A ladder config stubbed at the real 30-level ladder — every test level
/// number here (12) sits well below it, so `isFinalLevel` is false unless a
/// test explicitly builds a level-30 run.
LadderConfigRepository buildLadderConfig() {
  final ladderConfig = _MockLadderConfigRepository();
  when(() => ladderConfig.totalLevels).thenReturn(30);
  return ladderConfig;
}

/// A `RunRecord` computed the same way `submit_level_attempt` would, from
/// the run being submitted — a real server double, not a fixed fixture, so
/// assertions on `stars`/`finalScore` stay meaningful now that
/// `QuizResultRepository` trusts the server's numbers rather than
/// recomputing them.
RunRecord recordFor(QuizRun run, {bool isFirstClear = false}) {
  final stars = run.isComplete
      ? Scoring.stars(run.correctCount, run.questionCount)
      : 0;
  return RunRecord(
    isFirstClear: isFirstClear,
    finalScore: run.isComplete ? Scoring.total(run) : run.score,
    stars: stars,
    coinsEarned: run.isComplete
        ? Scoring.coinsEarned(
            levelNumber: run.levelNumber,
            stars: stars,
            isBoss: run.isBoss,
          )
        : 0,
    xpEarned: run.isComplete
        ? Scoring.xpEarned(
            levelNumber: run.levelNumber,
            stars: stars,
            isFirstClear: isFirstClear,
          )
        : 0,
    playerLevel: 12,
    totalXp: 1240,
    newlyEarnedBadgeIds: const [],
  );
}

/// A run of [correct] right answers out of twenty, ended as [ending].
QuizRun buildRun({
  required int correct,
  RunEnding ending = RunEnding.finished,
  int heartsRemaining = 3,
  int answered = 20,
  bool usedPowerUp = false,
  int levelNumber = 12,
}) {
  final questions = MockQuestions.forLevel(
    subcategoryId: MockCatalog.footballId,
    levelNumber: levelNumber,
  );

  final answers = <AnsweredQuestion>[
    for (var index = 0; index < answered; index++)
      AnsweredQuestion(
        question: questions[index],
        outcome: index < correct ? AnswerOutcome.correct : AnswerOutcome.wrong,
        chosenIndex: index < correct
            ? questions[index].correctIndex
            : (questions[index].correctIndex + 1) %
                  questions[index].options.length,
        secondsLeft: index < correct ? 14 : 0,
        pointsEarned: index < correct ? 310 : 0,
      ),
  ];

  return QuizRun(
    attemptId: 'attempt_test',
    levelId: MockCatalog.levelId(MockCatalog.footballId, levelNumber),
    subcategoryId: MockCatalog.footballId,
    subcategoryName: 'Football',
    categoryId: MockCatalog.sportsId,
    levelNumber: levelNumber,
    secondsPerQuestion: 20,
    startedAt: DateTime(2026),
    answers: answers,
    score: correct * 310,
    longestStreak: correct,
    heartsRemaining: heartsRemaining,
    usedPowerUp: usedPowerUp,
    ending: ending,
    isBoss: levelNumber % 5 == 0,
  );
}

void main() {
  late _MockQuizResultApi api;
  late AuthRepository authRepository;
  late QuizResultRepository repository;

  setUpAll(() => registerFallbackValue(buildRun(correct: 0, answered: 0)));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = _MockQuizResultApi();
    authRepository = AuthRepository(
      _MockAuthApi(),
      await SharedPreferences.getInstance(),
    );
    repository = QuizResultRepository(api, authRepository, buildLadderConfig());

    when(() => api.submit(any())).thenAnswer(
      (invocation) async => recordFor(
        invocation.positionalArguments.first as QuizRun,
        isFirstClear: true,
      ),
    );
  });

  group('QuizResultCubit', () {
    test('starts by submitting', () {
      expect(QuizResultCubit(repository).state, isA<QuizResultLoading>());
    });

    blocTest<QuizResultCubit, QuizResultState>(
      'success path: a completed run lands on S-21 with stars',
      build: () => QuizResultCubit(repository),
      act: (cubit) => cubit.submit(buildRun(correct: 17), isGuest: true),
      expect: () => [
        isA<QuizResultLoading>(),
        isA<QuizResultCompleted>()
            .having((state) => state.result.stars, 'stars', 2)
            .having((state) => state.result.finalScore, 'score', isPositive),
      ],
    );

    blocTest<QuizResultCubit, QuizResultState>(
      'failure path: a failed submit surfaces as an error',
      setUp: () {
        when(() => api.submit(any())).thenThrow(const ApiException.network());
      },
      build: () => QuizResultCubit(repository),
      act: (cubit) => cubit.submit(buildRun(correct: 17), isGuest: true),
      expect: () => [isA<QuizResultLoading>(), isA<QuizResultError>()],
    );

    blocTest<QuizResultCubit, QuizResultState>(
      'a run that ran out of hearts lands on S-22 with no stars',
      build: () => QuizResultCubit(repository),
      act: (cubit) => cubit.submit(
        buildRun(
          correct: 10,
          answered: 14,
          heartsRemaining: 0,
          ending: RunEnding.outOfHearts,
        ),
        isGuest: true,
      ),
      expect: () => [
        isA<QuizResultLoading>(),
        isA<QuizResultFailed>()
            .having((state) => state.result.stars, 'stars', 0)
            .having((state) => state.ranOutOfHearts, 'ranOutOfHearts', isTrue),
      ],
    );

    blocTest<QuizResultCubit, QuizResultState>(
      'a quit lands on S-22 but is not reported as running out of hearts',
      build: () => QuizResultCubit(repository),
      act: (cubit) => cubit.submit(
        buildRun(correct: 4, answered: 6, ending: RunEnding.quit),
        isGuest: true,
      ),
      expect: () => [
        isA<QuizResultLoading>(),
        isA<QuizResultFailed>().having(
          (state) => state.ranOutOfHearts,
          'ranOutOfHearts',
          isFalse,
        ),
      ],
    );
  });

  group('the save-progress rules', () {
    test(
      'a guest is offered the sheet after their first completed level',
      () async {
        final result = await repository.submit(
          buildRun(correct: 17),
          isGuest: true,
        );
        expect(result.shouldOfferSaveProgress, isTrue);
      },
    );

    test('the sheet is never offered after a failed run', () async {
      // Both ways a run can fail, since they take different code paths.
      for (final ending in [RunEnding.outOfHearts, RunEnding.quit]) {
        final api = _MockQuizResultApi();
        when(() => api.submit(any())).thenAnswer(
          (invocation) async =>
              recordFor(invocation.positionalArguments.first as QuizRun),
        );
        final auth = AuthRepository(
          _MockAuthApi(),
          await SharedPreferences.getInstance(),
        )..markLevelCompleted();
        final repository = QuizResultRepository(api, auth, buildLadderConfig());

        final result = await repository.submit(
          buildRun(correct: 8, answered: 12, ending: ending),
          isGuest: true,
        );

        expect(
          result.shouldOfferSaveProgress,
          isFalse,
          reason:
              'S-24 must never follow a failure, even for a guest who has '
              'completed a level before ($ending)',
        );
      }
    });

    test('the sheet is never offered twice in a session', () async {
      final first = await repository.submit(
        buildRun(correct: 20),
        isGuest: true,
      );
      expect(first.shouldOfferSaveProgress, isTrue);

      repository.markSaveProgressShown();

      final second = await repository.submit(
        buildRun(correct: 20),
        isGuest: true,
      );
      expect(second.shouldOfferSaveProgress, isFalse);
    });

    test('the sheet is never offered to a signed-in player', () async {
      final result = await repository.submit(
        buildRun(correct: 20),
        isGuest: false,
      );
      expect(result.shouldOfferSaveProgress, isFalse);
    });
  });

  group('isFinalLevel / unlocksMastery (plan 020)', () {
    Future<LevelResult> submitAt(
      int levelNumber, {
      required bool isFirstClear,
      int correct = 20,
      int answered = 20,
      RunEnding ending = RunEnding.finished,
    }) async {
      final api = _MockQuizResultApi();
      when(() => api.submit(any())).thenAnswer(
        (invocation) async => recordFor(
          invocation.positionalArguments.first as QuizRun,
          isFirstClear: isFirstClear,
        ),
      );
      final repository = QuizResultRepository(
        api,
        AuthRepository(_MockAuthApi(), await SharedPreferences.getInstance()),
        buildLadderConfig(),
      );
      return repository.submit(
        buildRun(
          correct: correct,
          answered: answered,
          ending: ending,
          levelNumber: levelNumber,
        ),
        isGuest: true,
      );
    }

    test('a level 5 completion is neither final nor mastery', () async {
      final result = await submitAt(5, isFirstClear: true);
      expect(result.isFinalLevel, isFalse);
      expect(result.unlocksMastery, isFalse);
    });

    test('a level 30 first clear is final and unlocks mastery', () async {
      final result = await submitAt(30, isFirstClear: true);
      expect(result.isFinalLevel, isTrue);
      expect(result.unlocksMastery, isTrue);
    });

    test(
      'a level 30 replay is final but does not unlock mastery again',
      () async {
        final result = await submitAt(30, isFirstClear: false);
        expect(result.isFinalLevel, isTrue);
        expect(result.unlocksMastery, isFalse);
      },
    );

    test('level 30 out of hearts (not complete) is final but never unlocks '
        'mastery', () async {
      final result = await submitAt(
        30,
        isFirstClear: true,
        correct: 8,
        answered: 12,
        ending: RunEnding.outOfHearts,
      );
      expect(result.isFinalLevel, isTrue);
      expect(result.unlocksMastery, isFalse);
    });
  });

  group('§19 scoring', () {
    test('the breakdown always sums to the total shown', () {
      for (final correct in [12, 16, 17, 20]) {
        for (final usedPowerUp in [true, false]) {
          final run = buildRun(correct: correct, usedPowerUp: usedPowerUp);
          expect(
            Scoring.breakdown(
              run,
            ).fold<int>(0, (sum, line) => sum + line.value),
            Scoring.total(run),
          );
        }
      }
    });

    test('a speed bonus is never larger than the base score', () {
      // The reviewer-sanity rule from plan 002's scope note.
      for (final secondsLeft in [0, 5, 14, 20]) {
        expect(
          Scoring.speedBonus(secondsLeft: secondsLeft, secondsTotal: 20),
          lessThanOrEqualTo(Scoring.base),
        );
      }
    });

    test("matches the bible's worked example", () {
      // "Level 12, answered with 14 of 20 seconds left, 5-answer streak:
      //  (100 + 70) × 1.55 × 1.5 = 395 points"
      expect(
        Scoring.questionScore(
          levelNumber: 12,
          secondsLeft: 14,
          secondsTotal: 20,
          streak: 5,
        ),
        395,
      );
    });

    test('stars follow the 60% / 80% / 100% thresholds of 20', () {
      expect(Scoring.stars(11, 20), 0);
      expect(Scoring.stars(12, 20), 1);
      expect(Scoring.stars(15, 20), 1);
      expect(Scoring.stars(16, 20), 2);
      expect(Scoring.stars(19, 20), 2);
      expect(Scoring.stars(20, 20), 3);
    });

    test('stars stay reachable at a different questionsPerLevel', () {
      expect(Scoring.stars(5, 10), 0);
      expect(Scoring.stars(6, 10), 1);
      expect(Scoring.stars(8, 10), 2);
      expect(Scoring.stars(10, 10), 3);
    });

    test('a boss level doubles the total', () {
      final normal = Scoring.total(buildRun(correct: 20, levelNumber: 12));
      final boss = Scoring.total(buildRun(correct: 20, levelNumber: 15));
      // Level 15 is a boss, so its own subtotal is doubled. Comparing totals
      // directly would also fold in the level number, so compare the ratio of
      // the boss run to its own pre-multiplier subtotal instead.
      final bossRun = buildRun(correct: 20, levelNumber: 15);
      final lines = Scoring.breakdown(bossRun);
      final subtotal = lines
          .where((line) => line.kind != ScoreLineKind.boss)
          .fold<int>(0, (sum, line) => sum + line.value);
      expect(Scoring.total(bossRun), subtotal * 2);
      expect(boss, greaterThan(normal));
    });
  });
}
