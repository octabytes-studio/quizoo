import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/countdown_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';

QuizRun _run({required bool isDaily}) => QuizRun(
  attemptId: isDaily ? 'daily' : 'attempt_test',
  levelId: isDaily ? 'daily' : 'sub_black_holes@6',
  subcategoryId: isDaily ? '' : 'sub_black_holes',
  subcategoryName: isDaily ? '' : 'Black Holes',
  categoryId: isDaily ? '' : 'cat_space',
  levelNumber: isDaily ? 0 : 6,
  secondsPerQuestion: 20,
  startedAt: DateTime(2026, 10, 17),
  isDaily: isDaily,
);

void main() {
  group('CountdownView', () {
    testWidgets(
      "a level countdown shows the run's server-provided topic name and "
      'level (plan 025)',
      (tester) async {
        await tester.pumpApp(
          CountdownView(
            state: QuizPlayCountdown(run: _run(isDaily: false), beat: 3),
            onSkip: () {},
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(CountdownView)),
        );
        expect(find.text(l10n.countdownMeta('BLACK HOLES', 6)), findsOneWidget);
      },
    );

    testWidgets(
      'a daily countdown shows the daily label rather than the old blank '
      '"· LEVEL 0" (plan 025)',
      (tester) async {
        await tester.pumpApp(
          CountdownView(
            state: QuizPlayCountdown(run: _run(isDaily: true), beat: 3),
            onSkip: () {},
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(CountdownView)),
        );
        expect(find.text(l10n.countdownDailyMeta), findsOneWidget);
        expect(find.textContaining('LEVEL 0'), findsNothing);
      },
    );
  });
}
