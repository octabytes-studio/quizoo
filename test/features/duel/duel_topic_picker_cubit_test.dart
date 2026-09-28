import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_topic_picker_cubit.dart';

class _MockDuelArenaRepository extends Mock implements DuelArenaRepository {}

const List<DuelTopic> _topics = [
  DuelTopic(
    id: 'football',
    name: 'Football',
    emoji: '⚽',
    plateColor: '#DDF1FF',
    categoryName: 'Sports',
    categoryEmoji: '🏅',
    categoryId: 'sports',
    openChallenges: 2,
  ),
  DuelTopic(
    id: 'solar',
    name: 'Solar System',
    emoji: '🪐',
    plateColor: '#EDE8FA',
    categoryName: 'Science',
    categoryEmoji: '🔬',
    categoryId: 'science',
  ),
];

void main() {
  late _MockDuelArenaRepository repository;

  setUp(() => repository = _MockDuelArenaRepository());

  group('DuelTopicPickerCubit', () {
    test('starts loading', () {
      expect(
        DuelTopicPickerCubit(repository).state,
        const DuelTopicPickerLoading(),
      );
    });

    blocTest<DuelTopicPickerCubit, DuelTopicPickerState>(
      'success path: loads the topics for the content language',
      setUp: () => when(
        () => repository.fetchTopics('en'),
      ).thenAnswer((_) async => _topics),
      build: () => DuelTopicPickerCubit(repository),
      act: (cubit) => cubit.load('en'),
      expect: () => [
        const DuelTopicPickerLoading(),
        const DuelTopicPickerLoaded(_topics),
      ],
    );

    blocTest<DuelTopicPickerCubit, DuelTopicPickerState>(
      'an empty language loads an empty list, not an error',
      setUp: () => when(
        () => repository.fetchTopics('ur'),
      ).thenAnswer((_) async => const []),
      build: () => DuelTopicPickerCubit(repository),
      act: (cubit) => cubit.load('ur'),
      expect: () => [
        const DuelTopicPickerLoading(),
        const DuelTopicPickerLoaded([]),
      ],
    );

    blocTest<DuelTopicPickerCubit, DuelTopicPickerState>(
      'failure path: an API error lands on Failed',
      setUp: () => when(
        () => repository.fetchTopics(any()),
      ).thenThrow(const ApiException.network()),
      build: () => DuelTopicPickerCubit(repository),
      act: (cubit) => cubit.load('en'),
      expect: () => [
        const DuelTopicPickerLoading(),
        const DuelTopicPickerFailed(ApiException.network()),
      ],
    );

    blocTest<DuelTopicPickerCubit, DuelTopicPickerState>(
      'retry reloads in the last language',
      setUp: () {
        var calls = 0;
        when(() => repository.fetchTopics('en')).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw const ApiException.network();
          return _topics;
        });
      },
      build: () => DuelTopicPickerCubit(repository),
      act: (cubit) async {
        await cubit.load('en');
        await cubit.retry();
      },
      expect: () => [
        const DuelTopicPickerLoading(),
        const DuelTopicPickerFailed(ApiException.network()),
        const DuelTopicPickerLoading(),
        const DuelTopicPickerLoaded(_topics),
      ],
      verify: (_) => verify(() => repository.fetchTopics('en')).called(2),
    );
  });
}
