import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/quiz_result_screen.dart';

import '../../support/pump_screen.dart';
import 'quiz_result_cubit_test.dart' show buildRun;

/// `QuizResultScreen` constructs a real `QuizResultRepository(QuizResultApi
/// (supabase), ...)` inline (matching every other screen post plan-005's
/// migration), reaching the unreachable placeholder client
/// `test/flutter_test_config.dart` sets up — `submit_level_attempt` always
/// fails, so `QuizResultCubit` always lands on `QuizResultError` here rather
/// than the real stars/breakdown/review-list content this suite used to
/// assert on with `MockApi`. That coverage now belongs at the
/// `QuizResultCubit`/`QuizResultRepository` level (see
/// `quiz_result_cubit_test.dart`, which already mocks `QuizResultApi`
/// directly per CLAUDE.md §11) — only the crash-free rendering check
/// survives here as a full-screen smoke test.
void main() {
  Future<void> pumpResult(WidgetTester tester, QuizRun run) async {
    await tester.pumpScreen(QuizResultScreen(run: run));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('renders the error state without throwing', (tester) async {
    await pumpResult(
      tester,
      buildRun(correct: 10, answered: 14, ending: RunEnding.outOfHearts),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark theme without overflowing', (tester) async {
    await tester.pumpScreen(
      QuizResultScreen(
        run: buildRun(correct: 10, answered: 14, ending: RunEnding.outOfHearts),
      ),
      brightness: Brightness.dark,
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
