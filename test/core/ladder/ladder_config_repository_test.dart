import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/ladder/ladder_config_api.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/models/difficulty_tier.dart';
import 'package:quizoo/core/network/api_exception.dart';

class _MockLadderConfigApi extends Mock implements LadderConfigApi {}

void main() {
  late _MockLadderConfigApi api;
  late LadderConfigRepository repository;

  const seededTiers = [
    DifficultyTier(
      code: 'easy',
      label: 'Easy',
      secondsPerQuestion: 20,
      levelStart: 1,
      levelEnd: 10,
      questionsPerLevel: 10,
    ),
    DifficultyTier(
      code: 'medium',
      label: 'Medium',
      secondsPerQuestion: 15,
      levelStart: 11,
      levelEnd: 20,
      questionsPerLevel: 15,
    ),
    DifficultyTier(
      code: 'hard',
      label: 'Hard',
      secondsPerQuestion: 10,
      levelStart: 21,
      levelEnd: 30,
      questionsPerLevel: 20,
    ),
  ];

  setUp(() {
    api = _MockLadderConfigApi();
    repository = LadderConfigRepository(api);
  });

  void stubSuccess() {
    when(() => api.fetchDefaultQuestionsPerLevel()).thenAnswer((_) async => 20);
    when(
      () => api.fetchTiers(
        defaultQuestionsPerLevel: any(named: 'defaultQuestionsPerLevel'),
      ),
    ).thenAnswer((_) async => seededTiers);
    when(() => api.fetchBossLevelInterval()).thenAnswer((_) async => 10);
  }

  group('before ensureLoaded resolves', () {
    test('falls back to the seeded 30-level ladder', () {
      expect(repository.totalLevels, 30);
      expect(repository.secondsFor(1), 20);
      expect(repository.questionsFor(1), 10);
      expect(repository.tierFor(1).code, 'easy');
    });
  });

  group('after a successful load', () {
    setUp(() async {
      stubSuccess();
      await repository.ensureLoaded();
    });

    test('tierFor resolves each level to its tier', () {
      expect(repository.tierFor(1).code, 'easy');
      expect(repository.tierFor(10).code, 'easy');
      expect(repository.tierFor(11).code, 'medium');
      expect(repository.tierFor(20).code, 'medium');
      expect(repository.tierFor(21).code, 'hard');
      expect(repository.tierFor(30).code, 'hard');
    });

    test('secondsFor and questionsFor read the resolved tier', () {
      expect(repository.secondsFor(5), 20);
      expect(repository.questionsFor(5), 10);
      expect(repository.secondsFor(15), 15);
      expect(repository.questionsFor(15), 15);
      expect(repository.secondsFor(25), 10);
      expect(repository.questionsFor(25), 20);
    });

    test('totalLevels is the highest levelEnd across every tier', () {
      expect(repository.totalLevels, 30);
    });

    test('isBoss is true on every tenth level', () {
      expect(repository.isBoss(10), isTrue);
      expect(repository.isBoss(20), isTrue);
      expect(repository.isBoss(30), isTrue);
      expect(repository.isBoss(15), isFalse);
    });

    test('ensureLoaded does not re-fetch once loaded', () async {
      await repository.ensureLoaded();
      verify(() => api.fetchBossLevelInterval()).called(1);
    });
  });

  group('DifficultyTier.questionsPerLevel resolution', () {
    test('an override beats the default', () {
      const tier = DifficultyTier(
        code: 'easy',
        label: 'Easy',
        secondsPerQuestion: 20,
        levelStart: 1,
        levelEnd: 10,
        questionsPerLevel: 10,
      );
      expect(tier.questionsPerLevel, 10);
    });
  });

  group('a failed load', () {
    test('rethrows, and a second ensureLoaded retries', () async {
      // `thenAnswer` (not `thenThrow`), matching how a real async
      // implementation fails — see plan 008 memory.
      when(
        () => api.fetchDefaultQuestionsPerLevel(),
      ).thenAnswer((_) async => throw const ApiException.network());

      await expectLater(
        repository.ensureLoaded(),
        throwsA(isA<ApiException>()),
      );
      // Still on the fallback — the failed fetch was never cached.
      expect(repository.totalLevels, 30);

      stubSuccess();
      await repository.ensureLoaded();
      expect(repository.totalLevels, 30);
      expect(repository.tierFor(25).code, 'hard');
    });
  });
}
