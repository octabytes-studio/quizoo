import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/core/widgets/subcategory_card.dart';
import 'package:quizoo/features/home/presentation/widgets/home_content_skeleton.dart';
import 'package:quizoo/features/home/presentation/widgets/popular_quiz_card.dart';

import '../../support/pump_app.dart';

void main() {
  group('HomeContentSkeleton', () {
    Iterable<SkeletonBox> boxesSized(
      WidgetTester tester,
      double width,
      double height,
    ) => tester
        .widgetList<SkeletonBox>(find.byType(SkeletonBox))
        .where((box) => box.width == width.w && box.height == height.h);

    testWidgets('mirrors the real rails in both themes', (tester) async {
      await tester.pumpInBothThemes(
        () => const HomeContentSkeleton(),
        body: () async {
          await tester.pump(AppMotion.skeletonDelay);
          expect(tester.takeException(), isNull);

          // Separate popular cards, not one full-width block.
          expect(
            boxesSized(tester, PopularQuizCard.width, PopularQuizCard.height),
            hasLength(greaterThanOrEqualTo(3)),
          );
          // Two category sections × three rail cards each.
          expect(
            boxesSized(
              tester,
              SubcategoryCard.railWidth,
              SubcategoryCard.railHeight,
            ),
            hasLength(greaterThanOrEqualTo(6)),
          );
        },
      );

      // Stop the infinite shimmer so the tester can settle.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
