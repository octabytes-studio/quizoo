import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';

TopicMastery buildMastery({
  int starsEarned = 78,
  int levelCount = 30,
  int levelsCleared = 30,
  DateTime? startedAt,
  DateTime? masteredAt,
}) => TopicMastery(
  categoryId: 'cat_sports',
  subcategoryId: 'sub_football',
  topicName: 'Football',
  emoji: '⚽',
  plateColor: '#FFE9D6',
  levelsCleared: levelsCleared,
  levelCount: levelCount,
  starsEarned: starsEarned,
  perfectLevels: 21,
  totalScore: 184320,
  tiers: const [],
  startedAt: startedAt,
  masteredAt: masteredAt,
);

void main() {
  group('TopicMastery', () {
    test('starsAvailable is levelCount * 3', () {
      expect(buildMastery(levelCount: 30).starsAvailable, 90);
    });

    test('missingStars is the gap to a perfect run', () {
      expect(buildMastery(starsEarned: 78, levelCount: 30).missingStars, 12);
    });

    test('isFlawless is true only when every star is earned', () {
      expect(buildMastery(starsEarned: 90, levelCount: 30).isFlawless, isTrue);
      expect(buildMastery(starsEarned: 89, levelCount: 30).isFlawless, isFalse);
    });

    test('isMastered compares levelsCleared against levelCount', () {
      expect(
        buildMastery(levelsCleared: 30, levelCount: 30).isMastered,
        isTrue,
      );
      expect(
        buildMastery(levelsCleared: 29, levelCount: 30).isMastered,
        isFalse,
      );
    });

    group('daysToMaster', () {
      test('is null when startedAt is missing', () {
        expect(
          buildMastery(masteredAt: DateTime(2026, 1, 12)).daysToMaster,
          isNull,
        );
      });

      test('is null when masteredAt is missing', () {
        expect(
          buildMastery(startedAt: DateTime(2026, 1, 1)).daysToMaster,
          isNull,
        );
      });

      test('is the whole-day gap between the two', () {
        final mastery = buildMastery(
          startedAt: DateTime(2026, 1, 1),
          masteredAt: DateTime(2026, 1, 13),
        );
        expect(mastery.daysToMaster, 12);
      });

      test('is at least 1 even when mastered the same day', () {
        final mastery = buildMastery(
          startedAt: DateTime(2026, 1, 1, 9),
          masteredAt: DateTime(2026, 1, 1, 14),
        );
        expect(mastery.daysToMaster, 1);
      });
    });
  });
}
