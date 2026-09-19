import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';
import 'package:quizoo/features/daily/presentation/bloc/daily_cubit.dart';

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
        when(
          () => repository.fetchToday(languageCode: any(named: 'languageCode')),
        ).thenAnswer((_) async => challenge);
        when(() => repository.fetchStreak()).thenAnswer((_) async => streak);
      },
      build: () => DailyCubit(repository),
      act: (cubit) => cubit.load(languageCode: 'en'),
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
          () => repository.fetchToday(languageCode: any(named: 'languageCode')),
        ).thenThrow(const ApiException.network());
      },
      build: () => DailyCubit(repository),
      act: (cubit) => cubit.load(languageCode: 'en'),
      expect: () => [isA<DailyLoading>(), isA<DailyError>()],
    );
  });

  // `DailyResultCubit` is gone: `DailyResultScreen` is now pure display,
  // handed an already-scored `DailyResult` by `QuizPlayCubit.startDaily`
  // (covered in quiz_play_cubit_daily_test.dart) rather than playing the
  // challenge itself.

  // The 'DailyApi + DailyRepository' end-to-end group is gone: `DailyApi` now
  // talks to a real Supabase project (`fetchToday`/`play_daily_challenge`),
  // so there is no more pure-Dart `DailyApi()` to construct and exercise
  // directly the way the mock's deterministic `Random`-seeded fixture
  // allowed.
}
