import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/topic_mastery/presentation/screens/topic_mastered_screen.dart';

import '../../support/pump_screen.dart';

/// `TopicMasteredScreen` constructs a real `TopicMasteryApi(supabase, ...)`
/// inline (matching every other "real repository inline" screen post plan
/// 005's migration — see `result_screen_test.dart`'s own note), reaching the
/// unreachable placeholder client `test/flutter_test_config.dart` sets up, so
/// it always lands on `TopicMasteryError` here. That's still a meaningful
/// smoke test (crash-free rendering, both themes); the real Loading/Loaded/
/// Error branch coverage lives at the `TopicMasteryCubit` level
/// (`topic_mastery_cubit_test.dart`), which mocks the repository directly
/// per CLAUDE.md §11.
void main() {
  Future<void> pumpMastered(WidgetTester tester, {Brightness? brightness}) =>
      tester.pumpScreen(
        const TopicMasteredScreen(
          categoryId: 'cat_sports',
          subcategoryId: 'sub_football',
        ),
        brightness: brightness ?? Brightness.light,
      );

  testWidgets('renders the error state without throwing', (tester) async {
    await pumpMastered(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark theme without overflowing', (tester) async {
    await pumpMastered(tester, brightness: Brightness.dark);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
