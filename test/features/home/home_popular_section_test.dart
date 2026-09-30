import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/features/home/presentation/widgets/home_popular_section.dart';
import 'package:quizoo/features/home/presentation/widgets/popular_quiz_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';

const _popular = [
  PopularQuiz(
    id: 'pq1',
    subcategoryId: MockCatalog.footballId,
    title: 'Football Legends',
    emoji: '⚽',
    colorFrom: '#FF8A24',
    colorTo: '#FF3D6E',
  ),
  PopularQuiz(
    id: 'pq2',
    subcategoryId: MockCatalog.solarSystemId,
    title: 'Planets',
    emoji: '🪐',
    colorFrom: '#7C4DFF',
    colorTo: '#57C4FF',
  ),
];

void main() {
  group('HomePopularSection', () {
    String heading(WidgetTester tester) => AppLocalizations.of(
      tester.element(find.byType(HomePopularSection)),
    ).homePopularThisWeek;

    testWidgets('hides entirely once the rail has loaded empty', (
      tester,
    ) async {
      await tester.pumpApp(
        HomePopularSection(
          popular: const [],
          isLoading: false,
          onSeeAll: () {},
          onQuizTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(heading(tester)), findsNothing);
      expect(find.byType(PopularQuizCard), findsNothing);
    });

    testWidgets('shows the header and three skeleton cards while loading', (
      tester,
    ) async {
      await tester.pumpApp(
        HomePopularSection(
          popular: const [],
          isLoading: true,
          onSeeAll: () {},
          onQuizTap: (_) {},
        ),
      );
      await tester.pump(AppMotion.skeletonDelay);

      expect(find.text(heading(tester)), findsOneWidget);
      expect(find.byType(SkeletonBox), findsNWidgets(3));

      // Stop the infinite shimmer so the tester can settle.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('renders one card per quiz and reports taps', (tester) async {
      PopularQuiz? tapped;
      await tester.pumpApp(
        HomePopularSection(
          popular: _popular,
          isLoading: false,
          onSeeAll: () {},
          onQuizTap: (quiz) => tapped = quiz,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopularQuizCard), findsNWidgets(_popular.length));
      await tester.tap(find.byType(PopularQuizCard).first);
      expect(tapped, _popular.first);
    });
  });
}
