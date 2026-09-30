import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/level_complete_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

class _MockQuizResultCubit extends MockCubit<QuizResultState>
    implements QuizResultCubit {}

QuizRun _buildRun({required int levelNumber}) => QuizRun(
  attemptId: 'attempt_test',
  levelId: 'sub_football::$levelNumber',
  subcategoryId: 'sub_football',
  subcategoryName: 'Football',
  categoryId: 'cat_sports',
  levelNumber: levelNumber,
  secondsPerQuestion: 20,
  startedAt: DateTime(2026),
  ending: RunEnding.finished,
);

LevelResult _buildResult({
  required int levelNumber,
  int stars = 3,
  bool isFinalLevel = false,
  bool unlocksMastery = false,
  bool isFirstClear = false,
}) => LevelResult(
  run: _buildRun(levelNumber: levelNumber),
  stars: stars,
  finalScore: 12000,
  coinsEarned: 400,
  xpEarned: 500,
  playerLevel: 12,
  xpIntoLevel: 100,
  xpToNextLevel: 400,
  isFirstClear: isFirstClear,
  isFinalLevel: isFinalLevel,
  unlocksMastery: unlocksMastery,
);

void main() {
  late _MockQuizResultCubit cubit;

  setUp(() => cubit = _MockQuizResultCubit());

  Future<void> pumpScreenWith(WidgetTester tester, LevelResult result) async {
    await tester.pumpScreen(
      BlocProvider<QuizResultCubit>.value(
        value: cubit,
        child: LevelCompleteScreen(state: QuizResultCompleted(result)),
      ),
    );
  }

  group('LevelCompleteScreen action buttons', () {
    testWidgets('a mid-ladder level shows "Next level"', (tester) async {
      await pumpScreenWith(tester, _buildResult(levelNumber: 5, stars: 2));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LevelCompleteScreen)),
      );

      expect(find.text(l10n.resultNextLevel), findsOneWidget);
      expect(find.text(l10n.resultSeeTrophy), findsNothing);
      expect(find.text(l10n.resultBackToMap), findsNothing);

      // Flushes the payout-delay timer `_runChain` scheduled in `initState`,
      // so it isn't still pending when the test tears down.
      await tester.pump(const Duration(milliseconds: 2600));
    });

    testWidgets(
      'a level 30 first clear shows "See your trophy" and no "Next level"',
      (tester) async {
        await pumpScreenWith(
          tester,
          _buildResult(
            levelNumber: 30,
            stars: 3,
            isFinalLevel: true,
            unlocksMastery: true,
            isFirstClear: true,
          ),
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LevelCompleteScreen)),
        );

        expect(find.text(l10n.resultSeeTrophy), findsOneWidget);
        expect(find.text(l10n.resultNextLevel), findsNothing);
        expect(find.text(l10n.resultBackToMap), findsNothing);

        await tester.pump(const Duration(milliseconds: 2600));
      },
    );

    testWidgets('a level 30 replay shows "Back to map" and no "Next level"', (
      tester,
    ) async {
      await pumpScreenWith(
        tester,
        _buildResult(
          levelNumber: 30,
          stars: 3,
          isFinalLevel: true,
          unlocksMastery: false,
          isFirstClear: false,
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LevelCompleteScreen)),
      );

      expect(find.text(l10n.resultBackToMap), findsOneWidget);
      expect(find.text(l10n.resultNextLevel), findsNothing);
      expect(find.text(l10n.resultSeeTrophy), findsNothing);

      await tester.pump(const Duration(milliseconds: 2600));
    });
  });

  testWidgets(
    'a level 30 first clear pushes the Topic Mastered route after the '
    'payout delay',
    (tester) async {
      final result = _buildResult(
        levelNumber: 30,
        stars: 3,
        isFinalLevel: true,
        unlocksMastery: true,
        isFirstClear: true,
      );
      await pumpScreenWith(tester, result);

      // The chain waits out the ~2.6s payout before pushing anywhere —
      // `pump`, not `pumpAndSettle`, per the pumpAndSettle-vs-timers memory.
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump();

      final expectedPath = AppRoutes.topicMasteredPath(
        result.run.categoryId,
        result.run.subcategoryId,
      );
      expect(find.text('pushed:$expectedPath'), findsOneWidget);
    },
  );
}
