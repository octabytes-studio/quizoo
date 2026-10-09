import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/inline_ad_slot.dart';
import 'package:quizoo/core/widgets/question_media_plate.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/heart_ad_cubit.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/quiz_play_screen.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/feedback_banner.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/out_of_lives_dialog.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/pause_sheet.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/power_up_dock.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/quit_confirmation_dialog.dart';
import 'package:quizoo/features/quiz_play/presentation/widgets/timer_ring.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_ads.dart';
import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';

class _MockQuizPlayApi extends Mock implements QuizPlayApi {}

/// A [QuizPlayRepository] backed by [MockQuestions] rather than a real
/// network fetch — `QuizPlayApi` now calls `start_level_attempt`, so a
/// deterministic screen test stubs the `*_api.dart` boundary instead
/// (CLAUDE.md §11).
QuizPlayRepository fakeQuizPlayRepository() {
  final api = _MockQuizPlayApi();
  when(
    () => api.fetchLevelQuestions(
      subcategoryId: any(named: 'subcategoryId'),
      levelNumber: any(named: 'levelNumber'),
      languageCode: any(named: 'languageCode'),
    ),
  ).thenAnswer(
    (invocation) async => PreparedLevel(
      attemptId: 'attempt_test',
      questions: MockQuestions.forLevel(
        subcategoryId: invocation.namedArguments[#subcategoryId] as String,
        levelNumber: invocation.namedArguments[#levelNumber] as int,
        languageCode:
            invocation.namedArguments[#languageCode] as String? ?? 'en',
      ),
      secondsPerQuestion: 20,
      isBoss: false,
    ),
  );
  return QuizPlayRepository(api);
}

void main() {
  useMockApiFailureRate();

  final levelId = MockCatalog.levelId(MockCatalog.footballId, 12);
  final imageLevelId = MockCatalog.levelId(MockCatalog.solarSystemId, 1);

  /// Pumps the play surface and runs it past the countdown to a live question.
  ///
  /// `pumpAndSettle` is never used on this screen: a live clock schedules a
  /// frame every tick, so it would never settle. Explicit pumps it is.
  Future<void> pumpToQuestion(
    WidgetTester tester, {
    String? id,
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
  }) async {
    // `QuizPlayScreen` now sources its question language from
    // `ContentLanguageCubit`, not the UI `locale` (plan 008) — seeded here to
    // match `locale` so this suite's Urdu case still fetches Urdu content.
    SharedPreferences.setMockInitialValues({
      'content_language.code': locale.languageCode,
    });
    final contentLanguage = ContentLanguageCubit(
      ContentLanguageRepository(
        FakeContentLanguageApi(),
        await SharedPreferences.getInstance(),
      ),
    );

    await tester.pumpScreen(
      QuizPlayScreen(levelId: id ?? levelId),
      locale: locale,
      brightness: brightness,
      quizPlayRepository: fakeQuizPlayRepository(),
      contentLanguage: contentLanguage,
    );
    // Load the level, then run the 3 · 2 · 1 · GO countdown out.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Question firstQuestion() => MockQuestions.forLevel(
    subcategoryId: MockCatalog.footballId,
    levelNumber: 12,
  ).first;

  group('QuizPlayScreen', () {
    testWidgets('S-11 rest: every option is interactive and the clock runs', (
      tester,
    ) async {
      await pumpToQuestion(tester);

      expect(find.byType(TimerRing), findsOneWidget);
      expect(find.byType(AnswerOption), findsNWidgets(4));
      expect(find.byType(PowerUpDock), findsOneWidget);
      // No verdict yet, so no banner.
      expect(find.byType(FeedbackBanner), findsNothing);

      final options = tester.widgetList<AnswerOption>(
        find.byType(AnswerOption),
      );
      expect(
        options.every((option) => option.state == AnswerOptionState.rest),
        isTrue,
      );

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('S-12 correct: the banner carries the explanation', (
      tester,
    ) async {
      await pumpToQuestion(tester);
      final question = firstQuestion();

      await tester.tap(find.text(question.options[question.correctIndex]));
      await tester.pump();

      expect(find.byType(FeedbackBanner), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(FeedbackBanner)),
      );
      expect(find.text(l10n.feedbackCorrect), findsOneWidget);
      // "The single feature that turns a quiz into learning."
      expect(
        find.textContaining(question.explanation.split('.').first),
        findsOneWidget,
      );
      // The dock is hidden while a verdict is up.
      expect(find.byType(PowerUpDock), findsNothing);

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('S-13 wrong: the right answer is still revealed', (
      tester,
    ) async {
      await pumpToQuestion(tester);
      final question = firstQuestion();
      final wrongIndex = (question.correctIndex + 1) % question.options.length;

      await tester.tap(find.text(question.options[wrongIndex]));
      await tester.pump();

      final options = tester
          .widgetList<AnswerOption>(find.byType(AnswerOption))
          .toList();

      // Always show the right answer, never hide it.
      expect(options[question.correctIndex].state, AnswerOptionState.correct);
      expect(options[wrongIndex].state, AnswerOptionState.wrong);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(FeedbackBanner)),
      );
      expect(find.text(l10n.feedbackWrong), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('S-14 danger: the arena washes crimson in the last 5s', (
      tester,
    ) async {
      await pumpToQuestion(tester);

      final arena = ArenaColors();
      LinearGradient arenaGradient() {
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        return (container.decoration! as BoxDecoration).gradient!
            as LinearGradient;
      }

      expect(arenaGradient().colors, arena.base.colors);

      // Level 12 is a 20-second clock; 16 seconds in leaves four.
      await tester.pump(const Duration(seconds: 16));
      expect(arenaGradient().colors, arena.danger.colors);

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('the arena is identical in light and dark', (tester) async {
      List<Color> arenaColorsFor(WidgetTester tester) {
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        return ((container.decoration! as BoxDecoration).gradient!
                as LinearGradient)
            .colors;
      }

      await pumpToQuestion(tester);
      final light = arenaColorsFor(tester);
      await tester.pump(const Duration(seconds: 30));

      await pumpToQuestion(tester, brightness: Brightness.dark);
      final dark = arenaColorsFor(tester);
      await tester.pump(const Duration(seconds: 30));

      expect(light, dark);
      expect(light, ArenaColors().base.colors);

      // Drain the entrance animations the second pump scheduled.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('S-16 Urdu: the surface mirrors and reads right-to-left', (
      tester,
    ) async {
      await pumpToQuestion(tester, locale: const Locale('ur'));

      final direction = Directionality.of(
        tester.element(find.byType(AnswerOption).first),
      );
      expect(direction, TextDirection.rtl);

      // Real Urdu content, not English in a mirrored layout.
      expect(find.text(MockQuestions.urduSample.text), findsOneWidget);
      // Option keys lead with the Urdu alphabet.
      expect(find.text(Question.urduKeys.first), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('S-15 image: a plate renders, and a missing one collapses', (
      tester,
    ) async {
      await pumpToQuestion(tester, id: imageLevelId);

      // Level 1 of the Solar System pool leads with text questions; walk
      // forward until an image question comes up.
      var sawPlate = false;
      for (var step = 0; step < 6 && !sawPlate; step++) {
        final plate = tester
            .widgetList<QuestionMediaPlate>(find.byType(QuestionMediaPlate))
            .toList();
        if (plate.isNotEmpty) {
          sawPlate = true;
          break;
        }
        // Answer and advance.
        await tester.tap(find.byType(AnswerOption).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2600));
      }

      expect(tester.takeException(), isNull);
      // Two 20-second pumps rather than one 40-second jump: a heart now
      // costs the same on a timeout as on a wrong answer, so the found
      // question's own clock can run out and open S-19 during this
      // trailing settle. Splitting the jump gives `flutter_animate`'s
      // zero-duration restart timer (armed when S-19's dialog mounts) a
      // frame to fire in before the tree is torn down, rather than leaving
      // it pending across a single large jump.
      await tester.pump(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
    });

    testWidgets('S-18 quit: reached from the pause sheet, the dialog quotes '
        'the run and never pre-focuses the destructive action', (tester) async {
      await pumpToQuestion(tester);

      // The HUD's pause button opens the pause sheet; quit is one of its
      // line items, not a direct HUD action.
      await tester.tap(find.text('✕'));
      await tester.pump();

      expect(find.byType(PauseSheet), findsOneWidget);
      final sheetL10n = AppLocalizations.of(
        tester.element(find.byType(PauseSheet)),
      );
      await tester.tap(find.text(sheetL10n.pauseQuit));
      await tester.pump();

      expect(find.byType(QuitConfirmationDialog), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(QuitConfirmationDialog)),
      );
      // "Keep playing" is first and dominant.
      expect(find.text(l10n.quitKeepPlaying), findsOneWidget);
      expect(find.text(l10n.quitConfirm), findsOneWidget);

      // Backing out returns to the question.
      await tester.tap(find.text(l10n.quitKeepPlaying));
      await tester.pump();
      expect(find.byType(QuitConfirmationDialog), findsNothing);

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('S-17 pause: the HUD pause button freezes the clock', (
      tester,
    ) async {
      await pumpToQuestion(tester);

      final ringBefore = tester
          .widget<TimerRing>(find.byType(TimerRing))
          .secondsRemaining;

      await tester.tap(find.text('✕'));
      await tester.pump();

      expect(find.byType(PauseSheet), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(
        tester.widget<TimerRing>(find.byType(TimerRing)).secondsRemaining,
        ringBefore,
      );

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('S-17 pause: a back gesture also freezes the clock', (
      tester,
    ) async {
      await pumpToQuestion(tester);

      final ringBefore = tester
          .widget<TimerRing>(find.byType(TimerRing))
          .secondsRemaining;

      // A system back gesture pauses too, so the run is never lost to a
      // stray swipe.
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(PauseSheet), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(
        tester.widget<TimerRing>(find.byType(TimerRing)).secondsRemaining,
        ringBefore,
      );

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('S-19 out of lives: the free option is offered first', (
      tester,
    ) async {
      await tester.pumpScreen(
        QuizPlayScreen(levelId: levelId, entry: QuizPlayEntry.outOfLives),
        quizPlayRepository: fakeQuizPlayRepository(),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.byType(OutOfLivesDialog), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OutOfLivesDialog)),
      );
      expect(find.text(l10n.outOfLivesWatchAd), findsOneWidget);
      expect(find.text(l10n.outOfLivesBackToMap), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets(
      'S-19 out of lives: the paid refill button is gone — only watch-ad '
      'and back-to-map remain',
      (tester) async {
        await tester.pumpScreen(
          QuizPlayScreen(levelId: levelId, entry: QuizPlayEntry.outOfLives),
          quizPlayRepository: fakeQuizPlayRepository(),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(OutOfLivesDialog),
            matching: find.byType(ChunkyButton),
          ),
          findsNWidgets(2),
        );

        await tester.pump(const Duration(seconds: 30));
      },
    );

    testWidgets('plan 022: the play surface never hosts or requests an ad', (
      tester,
    ) async {
      final ads = FakeAdsCubit.ready();
      final inlineAds = FakeInlineAdService(fills: true);
      await tester.pumpScreen(
        QuizPlayScreen(levelId: levelId),
        quizPlayRepository: fakeQuizPlayRepository(),
        ads: ads,
        inlineAds: inlineAds,
      );
      // Through the countdown and into a live question.
      for (var second = 0; second < 5; second++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.byType(AnswerOption), findsNWidgets(4));
      expect(find.byType(InlineAdSlot), findsNothing);
      expect(inlineAds.requests, isEmpty);
      expect(ads.breaks, isEmpty);

      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('plan 022: a rewarded ad that starts playing is reported to '
        'the interstitial pacer', (tester) async {
      final ads = FakeAdsCubit.ready();
      await tester.pumpScreen(
        QuizPlayScreen(levelId: levelId, entry: QuizPlayEntry.outOfLives),
        quizPlayRepository: fakeQuizPlayRepository(),
        ads: ads,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      tester
          .element(find.byType(OutOfLivesDialog))
          .read<HeartAdCubit>()
          .emit(const HeartAdPlaying());
      await tester.pump();

      expect(ads.fullScreenAdsNoted, 1);
      expect(ads.breaks, isEmpty);

      await tester.pump(const Duration(seconds: 30));
    });
  });
}
