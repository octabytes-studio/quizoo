import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/quiz_result_screen.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/missed_question_row.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/score_breakdown_card.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/stars_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';
import 'quiz_result_cubit_test.dart' show buildRun;

void main() {
  useMockApiFailureRate();

  Future<void> pumpResult(WidgetTester tester, QuizRun run) async {
    await tester.pumpScreen(QuizResultScreen(run: run));
    await tester.pump(const Duration(seconds: 1));
  }

  group('S-21 level complete', () {
    testWidgets('shows stars, a breakdown, and both CTAs', (tester) async {
      await pumpResult(tester, buildRun(correct: 17));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ScoreBreakdownCard)),
      );

      expect(find.byType(StarsRow), findsOneWidget);
      expect(find.byType(ScoreBreakdownCard), findsOneWidget);
      expect(find.text(l10n.resultCompleteTitle(12)), findsOneWidget);
      expect(find.text(l10n.resultNextLevel), findsOneWidget);
      // Two stars, so the third is still winnable.
      expect(find.text(l10n.resultReplay), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a three-star run is not offered a replay', (tester) async {
      await pumpResult(tester, buildRun(correct: 20));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ScoreBreakdownCard)),
      );
      expect(find.text(l10n.resultReplay), findsNothing);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the breakdown it renders sums to the total it shows', (
      tester,
    ) async {
      final run = buildRun(correct: 17);
      await pumpResult(tester, run);
      // Let the count-up finish so the figure on screen is the final one.
      await tester.pump(const Duration(seconds: 2));

      final total = Scoring.total(run);
      final lines = Scoring.breakdown(run);
      expect(lines.fold<int>(0, (sum, line) => sum + line.value), total);

      // The total appears twice: as the big score and as the breakdown's
      // last row.
      expect(
        find.text(
          '$total'.replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (match) => '${match[1]},',
          ),
        ),
        findsNWidgets(2),
      );

      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('S-22 level failed', () {
    testWidgets('no stars, no offer, and the misses become a review list', (
      tester,
    ) async {
      await pumpResult(
        tester,
        buildRun(
          correct: 10,
          answered: 14,
          heartsRemaining: 0,
          ending: RunEnding.outOfHearts,
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(MissedQuestionRow).first),
      );

      // "No stars shown (nothing to grey out)."
      expect(find.byType(StarsRow), findsNothing);
      expect(find.byType(ScoreBreakdownCard), findsNothing);

      expect(find.text(l10n.failedTitle), findsOneWidget);
      expect(find.text(l10n.failedRanOutOfHearts(14)), findsOneWidget);
      expect(find.byType(MissedQuestionRow), findsNWidgets(4));
      expect(find.text(l10n.failedTryAgain), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a quit is never described as running out of hearts', (
      tester,
    ) async {
      await pumpResult(
        tester,
        buildRun(correct: 4, answered: 6, ending: RunEnding.quit),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(MissedQuestionRow).first),
      );
      expect(find.text(l10n.failedQuitEarly(6)), findsOneWidget);
      expect(find.text(l10n.failedRanOutOfHearts(6)), findsNothing);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpScreen(
        QuizResultScreen(
          run: buildRun(
            correct: 10,
            answered: 14,
            ending: RunEnding.outOfHearts,
          ),
        ),
        brightness: Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
