import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/daily/data/daily_api.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';
import 'package:quizoo/features/daily/presentation/bloc/daily_cubit.dart';
import 'package:quizoo/features/daily/presentation/bloc/daily_result_cubit.dart';

class _MockDailyRepository extends Mock implements DailyRepository {}

void main() {
  const challenge = DailyChallenge(
    title: 'Mixed Bag',
    questionCount: 10,
    categoryCount: 10,
    secondsPerQuestion: 20,
    coinReward: 300,
    xpReward: 500,
    timeRemainingMinutes: 252,
    playedTodayCount: 18402,
    averageCorrect: 6,
    averageOutOf: 10,
  );

  const streak = StreakStatus(
    currentStreak: 12,
    freezesLeft: 2,
    days: [StreakDay(label: 'W', mark: StreakDayMark.today)],
    milestones: [],
  );

  group('DailyCubit', () {
    late _MockDailyRepository repository;

    setUp(() => repository = _MockDailyRepository());

    test('starts in its initial state', () {
      expect(DailyCubit(repository).state, isA<DailyInitial>());
    });

    blocTest<DailyCubit, DailyState>(
      'success path: loads the challenge and the streak together',
      setUp: () {
        when(() => repository.fetchToday()).thenAnswer((_) async => challenge);
        when(() => repository.fetchStreak()).thenAnswer((_) async => streak);
      },
      build: () => DailyCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DailyLoading>(),
        isA<DailyLoaded>()
            .having((state) => state.challenge, 'challenge', challenge)
            .having((state) => state.streak, 'streak', streak),
      ],
    );

    blocTest<DailyCubit, DailyState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchToday(),
        ).thenThrow(const ApiException.network());
      },
      build: () => DailyCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<DailyLoading>(), isA<DailyError>()],
    );
  });

  group('DailyResultCubit', () {
    late _MockDailyRepository repository;

    const result = DailyResult(
      correctCount: 8,
      totalCount: 10,
      betterThanPercent: 82,
      distributionPercents: [14, 34, 72, 100, 41],
      highlightedBucketIndex: 3,
      coinsEarned: 300,
      streakNow: 13,
      answerPattern: [
        true,
        true,
        false,
        true,
        true,
        true,
        false,
        true,
        true,
        true,
      ],
    );

    setUp(() => repository = _MockDailyRepository());

    test('starts by playing', () {
      expect(DailyResultCubit(repository).state, isA<DailyResultLoading>());
    });

    blocTest<DailyResultCubit, DailyResultState>(
      'success path: playing today lands on a loaded result',
      setUp: () {
        when(() => repository.playToday()).thenAnswer((_) async => result);
      },
      build: () => DailyResultCubit(repository),
      act: (cubit) => cubit.play(),
      expect: () => [
        isA<DailyResultLoading>(),
        isA<DailyResultLoaded>().having(
          (state) => state.result,
          'result',
          result,
        ),
      ],
    );

    blocTest<DailyResultCubit, DailyResultState>(
      'failure path: a failed play surfaces as an error',
      setUp: () {
        when(
          () => repository.playToday(),
        ).thenThrow(const ApiException.network());
      },
      build: () => DailyResultCubit(repository),
      act: (cubit) => cubit.play(),
      expect: () => [isA<DailyResultLoading>(), isA<DailyResultError>()],
    );
  });

  group('DailyApi + DailyRepository', () {
    test('playToday derives the bucket highlight from the score', () async {
      final repository = DailyRepository(DailyApi(failureRate: 0));
      final result = await repository.playToday();

      expect(result.totalCount, 10);
      expect(
        result.highlightedBucketIndex,
        DailyResult.bucketIndexFor(result.correctCount),
      );
      expect(
        result.answerPattern.where((correct) => correct).length,
        result.correctCount,
      );
    });
  });
}
