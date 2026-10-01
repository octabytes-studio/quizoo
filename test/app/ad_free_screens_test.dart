import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/inline_ad_slot.dart';
import 'package:quizoo/core/widgets/inline_ad_view.dart';
import 'package:quizoo/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:quizoo/features/catalog/presentation/screens/category_detail_screen.dart';
import 'package:quizoo/features/catalog/presentation/screens/level_map_screen.dart';
import 'package:quizoo/features/daily/presentation/screens/daily_screen.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:quizoo/features/profile/presentation/screens/stats_screen.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/level_failed_screen.dart';

import '../features/quiz_result/quiz_result_cubit_test.dart' show buildRun;
import '../support/fake_ads.dart';
import '../support/pump_screen.dart';

/// Regression guards for where ads must **not** be (plan 022): never beside
/// an error state, and never — of any kind — on Level Failed.
///
/// Each of these screens builds its own real `*Api(supabase)` against the
/// unreachable placeholder client, so in a widget test it always settles in
/// its error state — exactly the state under test. Ads are fully on, with a
/// service that would fill every request.
void main() {
  final screens = <String, Widget>{
    'Level Map': const LevelMapScreen(
      categoryId: 'cat_sports',
      subcategoryId: 'sub_football',
    ),
    'Category Detail': const CategoryDetailScreen(categoryId: 'cat_sports'),
    'Stats': const StatsScreen(),
    'Achievements': const AchievementsScreen(),
    'Daily tab': const DailyScreen(),
    'Home': const HomeScreen(),
    'Ranks': const LeaderboardScreen(),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name shows no ad beside its error state', (tester) async {
      final ads = FakeAdsCubit.ready();
      final inlineAds = FakeInlineAdService(fills: true);

      await tester.pumpScreen(screen, ads: ads, inlineAds: inlineAds);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.byType(InlineAdSlot), findsNothing);
      expect(find.byType(InlineAdView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Level Failed has no ad and offers no interstitial break', (
    tester,
  ) async {
    final ads = FakeAdsCubit.ready();
    final inlineAds = FakeInlineAdService(fills: true);
    final run = buildRun(
      correct: 4,
      answered: 9,
      ending: RunEnding.outOfHearts,
      heartsRemaining: 0,
    );

    await tester.pumpScreen(
      LevelFailedScreen(
        state: QuizResultFailed(
          LevelResult(
            run: run,
            stars: 0,
            finalScore: 0,
            coinsEarned: 0,
            xpEarned: 0,
            playerLevel: 12,
            xpIntoLevel: 100,
            xpToNextLevel: 400,
            isFirstClear: false,
          ),
        ),
      ),
      ads: ads,
      inlineAds: inlineAds,
    );
    await tester.pump();

    expect(find.byType(InlineAdSlot), findsNothing);
    expect(inlineAds.requests, isEmpty);

    await tester.tap(find.textContaining('Try again').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('pushed:'), findsOneWidget);
    expect(ads.breaks, isEmpty, reason: 'the bible: never an ad or offer here');
  });
}
