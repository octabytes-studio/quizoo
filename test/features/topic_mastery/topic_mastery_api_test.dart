import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/models/difficulty_tier.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_api.dart';

void main() {
  // The seeded 30-level, 3-tier ladder (plan 020).
  const tiers = [
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

  Map<String, dynamic> progressRow({
    required int level,
    required int stars,
    required int bestScore,
    bool completed = true,
  }) => {
    'level': level,
    'stars': stars,
    'best_score': bestScore,
    'completed_at': completed ? '2026-01-0${level % 9 + 1}T00:00:00Z' : null,
  };

  group('TopicMasteryApi.aggregate', () {
    test(
      'a fully-cleared topic aggregates stars, score and per-tier splits',
      () {
        final rows = [
          for (var level = 1; level <= 30; level++)
            progressRow(
              level: level,
              stars: level % 3 == 0 ? 2 : 3,
              bestScore: 1000 + level,
            ),
        ];

        final mastery = TopicMasteryApi.aggregate(
          categoryId: 'cat_sports',
          subcategoryId: 'sub_football',
          topicName: 'Football',
          emoji: '⚽',
          plateColor: '#FFE9D6',
          progressRows: rows,
          startedAtRaw: '2026-01-01T00:00:00Z',
          tiers: tiers,
          levelCount: 30,
        );

        expect(mastery.levelsCleared, 30);
        expect(
          mastery.perfectLevels,
          rows.where((r) => r['stars'] == 3).length,
        );
        expect(
          mastery.starsEarned,
          rows.fold<int>(0, (sum, r) => sum + (r['stars'] as int)),
        );
        expect(
          mastery.totalScore,
          rows.fold<int>(0, (sum, r) => sum + (r['best_score'] as int)),
        );
        expect(mastery.tiers, hasLength(3));
        expect(mastery.tiers[0].band, DifficultyBand.warmUp);
        expect(mastery.tiers[0].starsAvailable, 30);
        expect(mastery.tiers[1].band, DifficultyBand.steady);
        expect(mastery.tiers[1].starsAvailable, 30);
        expect(mastery.tiers[2].band, DifficultyBand.sharp);
        expect(mastery.tiers[2].starsAvailable, 30);
        expect(mastery.isMastered, isTrue);
        expect(mastery.masteredAt, isNotNull);
      },
    );

    test('an uncleared level is not counted and leaves masteredAt null', () {
      final rows = [
        for (var level = 1; level <= 29; level++)
          progressRow(level: level, stars: 3, bestScore: 100),
        progressRow(level: 30, stars: 0, bestScore: 0, completed: false),
      ];

      final mastery = TopicMasteryApi.aggregate(
        categoryId: 'cat_sports',
        subcategoryId: 'sub_football',
        topicName: 'Football',
        emoji: '⚽',
        plateColor: '#FFE9D6',
        progressRows: rows,
        startedAtRaw: null,
        tiers: tiers,
        levelCount: 30,
      );

      expect(mastery.levelsCleared, 29);
      expect(mastery.isMastered, isFalse);
      expect(mastery.masteredAt, isNull);
      expect(mastery.startedAt, isNull);
    });
  });
}
