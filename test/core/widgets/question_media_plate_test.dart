import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/widgets/question_media_plate.dart';

import '../../support/pump_app.dart';

void main() {
  double plateHeight(WidgetTester tester) =>
      tester.getSize(find.byType(QuestionMediaPlate)).height;

  group('QuestionMediaPlate', () {
    testWidgets('nothing to draw has no plate at all', (tester) async {
      await tester.pumpApp(const QuestionMediaPlate());
      expect(plateHeight(tester), 0);
    });

    testWidgets('an emoji fallback renders the 132px plate', (tester) async {
      await tester.pumpApp(const QuestionMediaPlate(imageEmoji: '🪐'));

      expect(find.text('🪐'), findsOneWidget);
      expect(plateHeight(tester), greaterThan(QuestionMediaPlate.height));
    });

    testWidgets(
      'a missing asset degrades to the text-only layout, never a broken box',
      (tester) async {
        await tester.pumpApp(
          const QuestionMediaPlate(
            // No emoji to fall back to, and an asset that does not resolve.
            imageAsset: 'assets/mock/missing_landmark.png',
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
            imageAsset: 'assets/mock/missing_landmark.png',
            imageEmoji: '🪐',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('🪐'), findsOneWidget);
        expect(plateHeight(tester), greaterThan(0));
      },
    );

    testWidgets('a failed network image degrades to the text-only layout too', (
      tester,
    ) async {
      await tester.pumpApp(
        const QuestionMediaPlate(
          mediaUrl: 'https://example.invalid/missing.png',
        ),
      );
      // The request fails against the test HttpClient's 400 stub.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(plateHeight(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pattern renders its SVG on the taller figure plate', (
      tester,
    ) async {
      await tester.pumpApp(
        const QuestionMediaPlate(
          figureSvg:
              '<svg xmlns="http://www.w3.org/2000/svg" '
              'viewBox="0 0 64 40"><rect width="64" height="40" '
              'fill="#F5F7FA"/><circle cx="32" cy="20" r="10" '
              'fill="#1B2430"/></svg>',
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(plateHeight(tester), greaterThan(QuestionMediaPlate.figureHeight));
    });
  });
}
