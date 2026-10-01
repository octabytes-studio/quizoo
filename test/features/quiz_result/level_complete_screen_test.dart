import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/widgets/inline_ad_view.dart';
import 'package:quizoo/core/widgets/native_ad_tile.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/level_complete_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/fake_ads.dart';
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
  List<String> newlyEarnedBadgeIds = const [],
  bool shouldOfferSaveProgress = false,
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
  newlyEarnedBadgeIds: newlyEarnedBadgeIds,
  shouldOfferSaveProgress: shouldOfferSaveProgress,
);

void main() {
  late _MockQuizResultCubit cubit;

  setUp(() => cubit = _MockQuizResultCubit());

  Future<void> pumpScreenWith(
    WidgetTester tester,
    LevelResult result, {
    FakeAdsCubit? ads,
    FakeInlineAdService? inlineAds,
  }) async {
    await tester.pumpScreen(
      BlocProvider<QuizResultCubit>.value(
        value: cubit,
        child: LevelCompleteScreen(state: QuizResultCompleted(result)),
      ),
      ads: ads,
      inlineAds: inlineAds,
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

  group('LevelCompleteScreen ads (plan 022)', () {
    AppLocalizations l10n(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(LevelCompleteScreen)));

    testWidgets('Next level waits for the interstitial break, then starts the '
        'next level', (tester) async {
      final ads = FakeAdsCubit.ready()..interstitialGate = Completer<void>();
      await pumpScreenWith(
        tester,
        _buildResult(levelNumber: 5, stars: 2),
        ads: ads,
      );

      await tester.tap(find.text(l10n(tester).resultNextLevel));
      await tester.pump();

      expect(ads.breaks, [
        (placement: AdPlacement.levelCompleteBreak, isCelebration: false),
      ]);
      final nextLevel = AppRoutes.countdownPath('sub_football::6');
      expect(
        find.text('pushed:$nextLevel'),
        findsNothing,
        reason: 'the countdown must not start under an ad',
      );

      ads.interstitialGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:$nextLevel'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2600));
    });

    testWidgets('Replay is a break too, and a second tap is ignored', (
      tester,
    ) async {
      final ads = FakeAdsCubit.ready()..interstitialGate = Completer<void>();
      await pumpScreenWith(
        tester,
        _buildResult(levelNumber: 5, stars: 2),
        ads: ads,
      );

      await tester.tap(find.text(l10n(tester).resultReplay));
      await tester.pump();
      await tester.tap(find.text(l10n(tester).resultReplay));
      await tester.tap(find.text(l10n(tester).resultNextLevel));
      await tester.pump();

      expect(ads.breaks, hasLength(1));

      ads.interstitialGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('pushed:${AppRoutes.countdownPath('sub_football::5')}'),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 2600));
    });

    for (final (name, result) in [
      (
        'a badge',
        _buildResult(levelNumber: 5, stars: 2, newlyEarnedBadgeIds: ['streak']),
      ),
      (
        'the save-progress offer',
        _buildResult(levelNumber: 5, stars: 2, shouldOfferSaveProgress: true),
      ),
      (
        'mastery',
        _buildResult(
          levelNumber: 30,
          stars: 2,
          isFinalLevel: true,
          unlocksMastery: true,
        ),
      ),
    ]) {
      testWidgets('a run that earned $name is flagged as a celebration', (
        tester,
      ) async {
        final ads = FakeAdsCubit.ready();
        await pumpScreenWith(tester, result, ads: ads);

        await tester.tap(find.text(l10n(tester).resultReplay));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(ads.breaks.single.isCelebration, isTrue);
        await tester.pump(const Duration(milliseconds: 2600));
      });
    }

    testWidgets('"See your trophy" is not a break', (tester) async {
      final ads = FakeAdsCubit.ready();
      await pumpScreenWith(
        tester,
        _buildResult(
          levelNumber: 30,
          isFinalLevel: true,
          unlocksMastery: true,
          isFirstClear: true,
        ),
        ads: ads,
      );

      await tester.tap(find.text(l10n(tester).resultSeeTrophy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(ads.breaks, isEmpty);
      await tester.pump(const Duration(milliseconds: 2600));
    });

    testWidgets('shows a native tile under the score breakdown', (
      tester,
    ) async {
      final inlineAds = FakeInlineAdService(fills: true);
      await pumpScreenWith(
        tester,
        _buildResult(levelNumber: 5, stars: 2),
        ads: FakeAdsCubit.ready(),
        inlineAds: inlineAds,
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(NativeAdTile),
          matching: find.byType(InlineAdView),
        ),
        findsOneWidget,
      );
      expect(
        inlineAds.requests.single.placement,
        AdPlacement.levelCompleteNative,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 2600));
    });

    testWidgets('with ads off there is no tile and no ad request', (
      tester,
    ) async {
      final inlineAds = FakeInlineAdService(fills: true);
      await pumpScreenWith(
        tester,
        _buildResult(levelNumber: 5, stars: 2),
        inlineAds: inlineAds,
      );
      await tester.pump();

      expect(find.byType(InlineAdView), findsNothing);
      expect(inlineAds.requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 2600));
    });
  });
}
