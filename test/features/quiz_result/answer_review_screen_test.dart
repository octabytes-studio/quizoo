import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/answer_review_screen.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/review_question_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

Question _question({required int correctIndex}) => Question(
  id: 'q1',
  subcategoryId: 's1',
  difficulty: 1,
  text: 'What is 2 + 2?',
  options: const ['3', '4', '5', '6'],
  correctIndex: correctIndex,
  explanation: 'Two plus two is four.',
);

QuizRun _run(List<AnsweredQuestion> answers) => QuizRun(
  attemptId: 'a1',
  levelId: 'level-1',
  subcategoryId: 's1',
  subcategoryName: 'Football',
  categoryId: 'c1',
  levelNumber: 12,
  secondsPerQuestion: 20,
  startedAt: DateTime(2026, 10, 1),
  answers: answers,
  questionCount: 3,
  powerUps: const PowerUpInventory(),
);

void main() {
  group('AnswerReviewScreen', () {
    testWidgets('marks the right answer and the player pick', (tester) async {
      await tester.pumpScreen(
        AnswerReviewScreen(
          run: _run([
            AnsweredQuestion(
              question: _question(correctIndex: 1),
              outcome: AnswerOutcome.wrong,
              chosenIndex: 0,
            ),
          ]),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AnswerReviewScreen)),
      );
      expect(find.text('What is 2 + 2?'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text(l10n.reviewCorrect), findsOneWidget);
      expect(find.text(l10n.reviewYourAnswer), findsOneWidget);
      expect(find.text(l10n.reviewExplanation), findsOneWidget);
      expect(find.text('Two plus two is four.'), findsOneWidget);
    });

    testWidgets('a timeout shows "You didn\'t answer"', (tester) async {
      await tester.pumpScreen(
        AnswerReviewScreen(
          run: _run([
            AnsweredQuestion(
              question: _question(correctIndex: 1),
              outcome: AnswerOutcome.timedOut,
            ),
          ]),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AnswerReviewScreen)),
      );
      expect(find.text(l10n.reviewTimedOut), findsOneWidget);
      expect(find.text(l10n.reviewYourAnswer), findsNothing);
    });

    testWidgets('a correct answer shows no "Your answer" marker', (
      tester,
    ) async {
      await tester.pumpScreen(
        AnswerReviewScreen(
          run: _run([
            AnsweredQuestion(
              question: _question(correctIndex: 1),
              outcome: AnswerOutcome.correct,
              chosenIndex: 1,
            ),
          ]),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AnswerReviewScreen)),
      );
      expect(find.text(l10n.reviewCorrect), findsOneWidget);
      expect(find.text(l10n.reviewYourAnswer), findsNothing);
    });

    testWidgets('renders one card per question', (tester) async {
      await tester.pumpScreen(
        AnswerReviewScreen(
          run: _run([
            for (var i = 0; i < 3; i++)
              AnsweredQuestion(
                question: _question(correctIndex: 1),
                outcome: AnswerOutcome.correct,
                chosenIndex: 1,
              ),
          ]),
        ),
      );

      expect(find.byType(ReviewQuestionCard), findsNWidgets(3));
    });

    testWidgets('a null run renders the empty state', (tester) async {
      await tester.pumpScreen(const AnswerReviewScreen());

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AnswerReviewScreen)),
      );
      expect(find.text(l10n.reviewEmpty), findsOneWidget);
    });
  });
}
