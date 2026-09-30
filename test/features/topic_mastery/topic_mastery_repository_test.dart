import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_api.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_repository.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';

class _MockTopicMasteryApi extends Mock implements TopicMasteryApi {}

void main() {
  late _MockTopicMasteryApi api;
  late TopicMasteryRepository repository;

  const mastery = TopicMastery(
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

  setUp(() {
    api = _MockTopicMasteryApi();
    repository = TopicMasteryRepository(api);
  });

  test('success path: passes the API response through', () async {
    when(
      () => api.fetch(
        categoryId: any(named: 'categoryId'),
        subcategoryId: any(named: 'subcategoryId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => mastery);

    final result = await repository.fetch(
      categoryId: 'cat_sports',
      subcategoryId: 'sub_football',
      locale: 'en',
    );

    expect(result, mastery);
  });

  test('error-mapping path: the typed exception reaches the caller', () {
    when(
      () => api.fetch(
        categoryId: any(named: 'categoryId'),
        subcategoryId: any(named: 'subcategoryId'),
        locale: any(named: 'locale'),
      ),
    ).thenThrow(const ApiException.network());

    expect(
      () => repository.fetch(
        categoryId: 'cat_sports',
        subcategoryId: 'sub_football',
        locale: 'en',
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
