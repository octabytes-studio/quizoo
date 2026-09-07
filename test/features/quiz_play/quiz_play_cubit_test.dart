import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';

class _MockQuizPlayRepository extends Mock implements QuizPlayRepository {}

void main() {
  late _MockQuizPlayRepository repository;

  final levelId = MockCatalog.levelId(MockCatalog.footballId, 12);
  final questions = MockQuestions.forLevel(
    subcategoryId: MockCatalog.footballId,
    levelNumber: 12,
  );

  setUp(() {
    repository = _MockQuizPlayRepository();
    when(() => repository.forget(any())).thenReturn(null);
  });

  void stubQuestions([List<Question>? override]) {
    when(
      () => repository.questionsFor(
        levelId: any(named: 'levelId'),
        subcategoryId: any(named: 'subcategoryId'),
        levelNumber: any(named: 'levelNumber'),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => override ?? questions);
  }

  Future<void> start(QuizPlayCubit cubit) => cubit.startLevel(
    levelId: levelId,
    categoryId: MockCatalog.sportsId,
    subcategoryName: 'Football',
  );

  group('QuizPlayCubit', () {
    test('starts in the preparing state', () {
      expect(QuizPlayCubit(repository).state, isA<QuizPlayPreparing>());
    });

    blocTest<QuizPlayCubit, QuizPlayState>(
      'success path: loads a level and opens the countdown at 3',
      setUp: stubQuestions,
      build: () => QuizPlayCubit(repository),
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
      build: () => QuizPlayCubit(repository),
      act: start,
      expect: () => [isA<QuizPlayPreparing>(), isA<QuizPlayFailed>()],
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'a topic with no questions behind it fails rather than opening empty',
      setUp: () => stubQuestions(const []),
      build: () => QuizPlayCubit(repository),
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
      build: () => QuizPlayCubit(repository),
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
      build: () => QuizPlayCubit(repository),
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
      build: () => QuizPlayCubit(repository),
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

    test('a timeout costs the question but never a heart (§19)', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = QuizPlayCubit(repository);
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        // Let the whole 20-second clock run out with nothing selected.
        async.elapse(const Duration(seconds: 21));

        final state = cubit.state as QuizPlayInProgress;
        expect(state.feedback, isA<TimeoutFeedback>());
        expect(state.run.answers.single.outcome, AnswerOutcome.timedOut);
        // The whole point of the branch: hearts are untouched.
        expect(state.run.heartsRemaining, 3);
        expect(state.run.currentStreak, 0);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('the clock counts down while a question is live', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = QuizPlayCubit(repository);
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
        final cubit = QuizPlayCubit(repository);
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

    test('+15s extends the clock rather than restarting it', () {
      stubQuestions();
      fakeAsync((async) {
        final cubit = QuizPlayCubit(repository);
        unawaited(start(cubit));
        async.flushMicrotasks();
        cubit.skipCountdown();

        async.elapse(const Duration(seconds: 5));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 15);

        cubit.usePowerUp(PowerUp.addTime);
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 30);

        async.elapse(const Duration(seconds: 2));
        expect((cubit.state as QuizPlayInProgress).secondsRemaining, 28);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    blocTest<QuizPlayCubit, QuizPlayState>(
      'losing the last heart opens S-19 rather than ending the run',
      setUp: stubQuestions,
      build: () => QuizPlayCubit(repository),
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
        final cubit = QuizPlayCubit(repository);
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
      build: () => QuizPlayCubit(repository),
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
        expect(state.powerUps.fiftyFifty, 2);
        expect(state.run.usedPowerUp, isTrue);
      },
    );

    blocTest<QuizPlayCubit, QuizPlayState>(
      'leaving from S-19 is recorded as a heart loss, not a quit',
      setUp: stubQuestions,
      build: () => QuizPlayCubit(repository),
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
      build: () => QuizPlayCubit(repository),
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
      build: () => QuizPlayCubit(repository),
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
        expect(Scoring.stars(state.run.correctCount), 3);
        // The breakdown is the only source of the total, so it always sums.
        expect(
          Scoring.breakdown(state.run).fold<int>(0, (a, b) => a + b.value),
          Scoring.total(state.run),
        );
      },
    );
  });
}
