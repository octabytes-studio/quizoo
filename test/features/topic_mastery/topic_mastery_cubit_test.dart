import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_repository.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';
import 'package:quizoo/features/topic_mastery/presentation/bloc/topic_mastery_cubit.dart';

class _MockTopicMasteryRepository extends Mock
    implements TopicMasteryRepository {}

void main() {
  late _MockTopicMasteryRepository repository;

  const mastered = TopicMastery(
    categoryId: 'cat_sports',
    subcategoryId: 'sub_football',
    topicName: 'Football',
    emoji: '⚽',
    plateColor: '#FFE9D6',
    levelsCleared: 30,
    levelCount: 30,
    starsEarned: 78,
    perfectLevels: 21,
    totalScore: 184320,
    tiers: [],
  );

  const notYetMastered = TopicMastery(
    categoryId: 'cat_sports',
    subcategoryId: 'sub_football',
    topicName: 'Football',
    emoji: '⚽',
    plateColor: '#FFE9D6',
    levelsCleared: 29,
    levelCount: 30,
    starsEarned: 70,
    perfectLevels: 18,
    totalScore: 160000,
    tiers: [],
  );

  setUp(() => repository = _MockTopicMasteryRepository());

  test('starts in its initial state', () {
    expect(TopicMasteryCubit(repository).state, isA<TopicMasteryLoading>());
  });

  blocTest<TopicMasteryCubit, TopicMasteryState>(
    'success path: a mastered topic lands on Loaded',
    setUp: () {
      when(
        () => repository.fetch(
          categoryId: any(named: 'categoryId'),
          subcategoryId: any(named: 'subcategoryId'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => mastered);
    },
    build: () => TopicMasteryCubit(repository),
    act: (cubit) => cubit.load(
      categoryId: 'cat_sports',
      subcategoryId: 'sub_football',
      locale: 'en',
    ),
    expect: () => [
      isA<TopicMasteryLoading>(),
      isA<TopicMasteryLoaded>().having(
        (state) => state.mastery,
        'mastery',
        mastered,
      ),
    ],
  );

  blocTest<TopicMasteryCubit, TopicMasteryState>(
    'failure path: the repository throws',
    setUp: () {
      // `thenAnswer` (not `thenThrow`), matching how a real async
      // implementation fails — plan 008 memory.
      when(
        () => repository.fetch(
          categoryId: any(named: 'categoryId'),
          subcategoryId: any(named: 'subcategoryId'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => throw const ApiException.network());
    },
    build: () => TopicMasteryCubit(repository),
    act: (cubit) => cubit.load(
      categoryId: 'cat_sports',
      subcategoryId: 'sub_football',
      locale: 'en',
    ),
    expect: () => [isA<TopicMasteryLoading>(), isA<TopicMasteryError>()],
  );

  blocTest<TopicMasteryCubit, TopicMasteryState>(
    'a topic that is not yet mastered surfaces as an error, never a '
    'congratulation',
    setUp: () {
      when(
        () => repository.fetch(
          categoryId: any(named: 'categoryId'),
          subcategoryId: any(named: 'subcategoryId'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => notYetMastered);
    },
    build: () => TopicMasteryCubit(repository),
    act: (cubit) => cubit.load(
      categoryId: 'cat_sports',
      subcategoryId: 'sub_football',
      locale: 'en',
    ),
    expect: () => [isA<TopicMasteryLoading>(), isA<TopicMasteryError>()],
  );
}
