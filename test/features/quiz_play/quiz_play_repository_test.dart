import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';

class _MockQuizPlayApi extends Mock implements QuizPlayApi {}

void main() {
  late _MockQuizPlayApi api;
  late QuizPlayRepository repository;

  final levelId = MockCatalog.levelId(MockCatalog.footballId, 12);
  final questions = MockQuestions.forLevel(
    subcategoryId: MockCatalog.footballId,
    levelNumber: 12,
  );

  setUp(() {
    api = _MockQuizPlayApi();
    repository = QuizPlayRepository(api);
  });

  void stubSuccess() {
    when(
      () => api.fetchLevelQuestions(
        subcategoryId: any(named: 'subcategoryId'),
        levelNumber: any(named: 'levelNumber'),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer(
      (_) async =>
          PreparedLevel(attemptId: 'attempt_test', questions: questions),
    );
  }

  Future<void> prepare() => repository.prepareLevel(
    levelId: levelId,
    subcategoryId: MockCatalog.footballId,
    levelNumber: 12,
  );

  group('QuizPlayRepository', () {
    test('success path: prepares a level and reports it ready', () async {
      stubSuccess();

      expect(repository.isPrepared(levelId), isFalse);
      await prepare();
      expect(repository.isPrepared(levelId), isTrue);
    });

    test('preparing twice does not fetch twice', () async {
      stubSuccess();

      await prepare();
      await prepare();

      // The whole point of the prefetch: reopening S-09's sheet must not go
      // back to the network for questions already in hand.
      verify(
        () => api.fetchLevelQuestions(
          subcategoryId: any(named: 'subcategoryId'),
          levelNumber: any(named: 'levelNumber'),
          languageCode: any(named: 'languageCode'),
        ),
      ).called(1);
    });

    test(
      'the play surface reads the cache rather than fetching again',
      () async {
        stubSuccess();

        await prepare();
        final played = await repository.questionsFor(
          levelId: levelId,
          subcategoryId: MockCatalog.footballId,
          levelNumber: 12,
        );

        expect(played, hasLength(MockQuestions.questionsPerLevel));
        verify(
          () => api.fetchLevelQuestions(
            subcategoryId: any(named: 'subcategoryId'),
            levelNumber: any(named: 'levelNumber'),
            languageCode: any(named: 'languageCode'),
          ),
        ).called(1);
      },
    );

    test('a deep-linked level that skipped the sheet still fetches', () async {
      stubSuccess();

      final played = await repository.questionsFor(
        levelId: levelId,
        subcategoryId: MockCatalog.footballId,
        levelNumber: 12,
      );

      expect(played, isNotEmpty);
    });

    test('each language is cached separately', () async {
      stubSuccess();

      await prepare();
      expect(repository.isPrepared(levelId), isTrue);
      // The Urdu deal is a different set of questions, so it is a different
      // cache entry rather than a hit on the English one.
      expect(repository.isPrepared(levelId, languageCode: 'ur'), isFalse);
    });

    test('forgetting a level makes a replay re-deal it', () async {
      stubSuccess();

      await prepare();
      repository.forget(levelId);
      expect(repository.isPrepared(levelId), isFalse);

      await prepare();
      verify(
        () => api.fetchLevelQuestions(
          subcategoryId: any(named: 'subcategoryId'),
          levelNumber: any(named: 'levelNumber'),
          languageCode: any(named: 'languageCode'),
        ),
      ).called(2);
    });

    test('error-mapping path: the typed exception reaches the caller', () {
      when(
        () => api.fetchLevelQuestions(
          subcategoryId: any(named: 'subcategoryId'),
          levelNumber: any(named: 'levelNumber'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenThrow(const ApiException.network());

      expect(prepare, throwsA(isA<ApiException>()));
      expect(repository.isPrepared(levelId), isFalse);
    });
  });

  group('MockQuestions', () {
    test('deals exactly twenty questions, deterministically', () {
      final first = MockQuestions.forLevel(
        subcategoryId: MockCatalog.footballId,
        levelNumber: 12,
      );
      final again = MockQuestions.forLevel(
        subcategoryId: MockCatalog.footballId,
        levelNumber: 12,
      );

      expect(first, hasLength(MockQuestions.questionsPerLevel));
      expect(
        first.map((question) => question.id),
        again.map((question) => question.id),
        reason: 'a replay must deal the same level, so a test is repeatable',
      );
    });

    test('a topic with no content behind it deals nothing', () {
      expect(
        MockQuestions.forLevel(subcategoryId: 'sub_tennis', levelNumber: 1),
        isEmpty,
      );
    });

    test('Urdu leads with the authored Nastaliq question', () {
      final urdu = MockQuestions.forLevel(
        subcategoryId: MockCatalog.footballId,
        levelNumber: 12,
        languageCode: 'ur',
      );
      expect(urdu.first.id, MockQuestions.urduSample.id);
      expect(urdu, hasLength(MockQuestions.questionsPerLevel));
    });

    test('every question carries an explanation and a valid answer', () {
      for (final question in [
        ...MockQuestions.football,
        ...MockQuestions.solarSystem,
        MockQuestions.urduSample,
      ]) {
        expect(question.explanation, isNotEmpty, reason: question.id);
        expect(question.options, isNotEmpty, reason: question.id);
        expect(
          question.correctIndex,
          inInclusiveRange(0, question.options.length - 1),
          reason: question.id,
        );
        // Image questions get three options; the media plate takes the room
        // the fourth would need (S-15).
        expect(
          question.options.length,
          question.hasImage ? 3 : 4,
          reason: question.id,
        );
      }
    });
  });
}
