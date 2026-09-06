import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/question_media_plate.dart';

import '../../support/pump_app.dart';

void main() {
  const base = Question(
    id: 'q',
    subcategoryId: MockCatalog.solarSystemId,
    difficulty: 1,
    text: 'Which planet is this?',
    options: ['Saturn', 'Uranus', 'Neptune'],
    correctIndex: 0,
    explanation: 'Saturn.',
  );

  double plateHeight(WidgetTester tester) =>
      tester.getSize(find.byType(QuestionMediaPlate)).height;

  group('QuestionMediaPlate', () {
    testWidgets('a text question has no plate at all', (tester) async {
      await tester.pumpApp(const QuestionMediaPlate(question: base));
      expect(plateHeight(tester), 0);
    });

    testWidgets('an image question renders its 132px plate', (tester) async {
      await tester.pumpApp(
        const QuestionMediaPlate(
          question: Question(
            id: 'q',
            subcategoryId: MockCatalog.solarSystemId,
            difficulty: 1,
            text: 'Which planet is this?',
            options: ['Saturn', 'Uranus', 'Neptune'],
            correctIndex: 0,
            explanation: 'Saturn.',
            hasImage: true,
            imageEmoji: '🪐',
          ),
        ),
      );

      expect(find.text('🪐'), findsOneWidget);
      expect(plateHeight(tester), greaterThan(QuestionMediaPlate.height));
    });

    testWidgets(
      'a missing asset degrades to the text-only layout, never a broken box',
      (tester) async {
        await tester.pumpApp(
          const QuestionMediaPlate(
            question: Question(
              id: 'q',
              subcategoryId: MockCatalog.solarSystemId,
              difficulty: 1,
              text: 'Which planet is closest to the Sun?',
              options: ['Mercury', 'Venus', 'Earth'],
              correctIndex: 0,
              explanation: 'Mercury.',
              hasImage: true,
              // No emoji to fall back to, and an asset that does not resolve.
              imageAsset: 'assets/mock/missing_landmark.png',
            ),
          ),
        );
        // The asset resolves (and fails) asynchronously.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // The bible's hard requirement: the whole plate collapses, so the
        // question lays out as if it never had an image. Reserving 132px of
        // empty gradient *is* the broken box.
        expect(plateHeight(tester), 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a failed asset still falls back to an emoji when there is one',
      (tester) async {
        await tester.pumpApp(
          const QuestionMediaPlate(
            question: Question(
              id: 'q',
              subcategoryId: MockCatalog.solarSystemId,
              difficulty: 1,
              text: 'Which planet is this?',
              options: ['Saturn', 'Uranus', 'Neptune'],
              correctIndex: 0,
              explanation: 'Saturn.',
              hasImage: true,
              imageAsset: 'assets/mock/missing_landmark.png',
              imageEmoji: '🪐',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('🪐'), findsOneWidget);
        expect(plateHeight(tester), greaterThan(0));
      },
    );
  });
}
