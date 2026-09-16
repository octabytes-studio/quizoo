import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/category_section_header.dart';
import 'package:quizoo/core/widgets/category_tile.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/currency_pill.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/level_node.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/power_up_tile.dart';
import 'package:quizoo/core/widgets/report_question_sheet.dart';
import 'package:quizoo/core/widgets/segmented_tabs.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/core/widgets/subcategory_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_app.dart';

void main() {
  group('ChunkyButton', () {
    testWidgets('renders every variant in both themes', (tester) async {
      for (final variant in ChunkyButtonVariant.values) {
        await tester.pumpInBothThemes(
          () => ChunkyButton(
            label: variant.name,
            variant: variant,
            subLabel: 'sub',
            icon: const Text('🎯'),
            onPressed: () {},
          ),
          body: () async {
            expect(find.text(variant.name), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    });

    testWidgets('fires onPressed when enabled', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        ChunkyButton(label: 'Start', onPressed: () => taps++),
      );

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('a null onPressed disables without changing height', (
      tester,
    ) async {
      await tester.pumpApp(
        const ChunkyButton(label: 'Locked', onPressed: null),
      );
      final disabledHeight = tester.getSize(find.byType(ChunkyButton)).height;

      await tester.pumpApp(ChunkyButton(label: 'Locked', onPressed: () {}));
      final enabledHeight = tester.getSize(find.byType(ChunkyButton)).height;

      // The disabled variant keeps its ledge "so the shape does not jump".
      expect(disabledHeight, enabledHeight);
    });

    testWidgets('the ledge collapses on press and returns on release', (
      tester,
    ) async {
      await tester.pumpApp(ChunkyButton(label: 'Press', onPressed: () {}));

      BoxDecoration decoration() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(ChunkyButton),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      expect(decoration().boxShadow, isNotEmpty);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      await tester.pumpAndSettle();
      expect(decoration().boxShadow, anyOf(isNull, isEmpty));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(decoration().boxShadow, isNotEmpty);
    });

    testWidgets('adds vertical room under an RTL locale', (tester) async {
      await tester.pumpApp(ChunkyButton(label: 'ابھی', onPressed: () {}));
      final ltrHeight = tester.getSize(find.byType(ChunkyButton)).height;

      await tester.pumpApp(
        ChunkyButton(label: 'ابھی', onPressed: () {}),
        locale: const Locale('ur'),
      );
      final rtlHeight = tester.getSize(find.byType(ChunkyButton)).height;

      // §04: Urdu needs 4px more vertical padding in every button.
      expect(rtlHeight, greaterThan(ltrHeight));
    });
  });

  group('AnswerOption', () {
    testWidgets('renders every state in both themes', (tester) async {
      for (final state in AnswerOptionState.values) {
        await tester.pumpInBothThemes(
          () => AnswerOption(
            label: 'Jupiter',
            optionKey: 'A',
            state: state,
            onPressed: () {},
          ),
          body: () async {
            expect(find.text('Jupiter'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    });

    testWidgets('doubles colour with a glyph on correct and wrong', (
      tester,
    ) async {
      await tester.pumpApp(
        const AnswerOption(
          label: 'Neptune',
          optionKey: 'C',
          state: AnswerOptionState.correct,
          onPressed: null,
        ),
      );
      expect(find.text('✓'), findsOneWidget);

      await tester.pumpApp(
        const AnswerOption(
          label: 'Mars',
          optionKey: 'D',
          state: AnswerOptionState.wrong,
          onPressed: null,
        ),
      );
      expect(find.text('✕'), findsOneWidget);
    });

    testWidgets('an eliminated option is inert', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AnswerOption(
          label: 'Removed by 50:50',
          optionKey: 'A',
          state: AnswerOptionState.eliminated,
          onPressed: () => taps++,
        ),
      );

      await tester.tap(find.text('Removed by 50:50'));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });
  });

  group('CurrencyPill', () {
    testWidgets('renders each currency in both themes', (tester) async {
      for (final kind in CurrencyKind.values) {
        await tester.pumpInBothThemes(
          () => CurrencyPill(kind: kind, value: '1,240'),
          body: () async {
            expect(find.text('1,240'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    });
  });

  group('AppChip', () {
    testWidgets('renders both variants and selection in both themes', (
      tester,
    ) async {
      await tester.pumpInBothThemes(
        () => Column(
          children: [
            AppChip(label: 'IQ', leading: '🧠', isSelected: true, onTap: () {}),
            AppChip(label: 'Sports', leading: '⚽', onTap: () {}),
            const AppChip.status(label: '12-day streak', leading: '🔥'),
          ],
        ),
        body: () async {
          expect(find.text('IQ'), findsOneWidget);
          expect(find.text('12-day streak'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });
  });

  group('SegmentedTabs', () {
    testWidgets('renders in both themes and reports taps', (tester) async {
      var selected = 0;
      await tester.pumpInBothThemes(
        () => SegmentedTabs(
          labels: const ['Global', 'Country', 'Friends'],
          selectedIndex: 0,
          onChanged: (index) => selected = index,
        ),
        body: () async {
          expect(find.text('Country'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();
      expect(selected, 2);
    });
  });

  group('ListRowTile', () {
    testWidgets('renders all three configurations in both themes', (
      tester,
    ) async {
      await tester.pumpInBothThemes(
        () => Column(
          children: [
            const ListRowTile(
              title: 'Football Legends',
              subtitle: 'Level 12 · 68% accuracy',
              leadingEmoji: '⚽',
              trailingValue: '4,820',
              trailingLabel: 'pts',
            ),
            const ListRowTile(
              title: 'Ayesha K.',
              subtitle: 'Karachi · Level 34',
              leadingEmoji: '🦊',
              variant: ListRowVariant.player,
              trailingValue: '#2',
              trailingLabel: '▲ 3',
            ),
            const ListRowTile(
              title: 'You',
              subtitle: 'Not ranked — sign in to compete',
              leadingEmoji: '🐼',
              variant: ListRowVariant.self,
              trailingValue: '—',
            ),
          ],
        ),
        body: () async {
          expect(find.text('You'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('the self row takes a 2px grape border', (tester) async {
      await tester.pumpApp(
        const ListRowTile(title: 'You', variant: ListRowVariant.self),
      );

      final context = tester.element(find.byType(ListRowTile));
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ListRowTile),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (container.decoration! as BoxDecoration).border! as Border;

      expect(border.top.color, context.quizoo.g);
      expect(border.top.width, 2);
    });
  });

  group('CategoryTile', () {
    testWidgets('renders played, new and locked in both themes', (
      tester,
    ) async {
      await tester.pumpInBothThemes(
        () => Row(
          children: [
            const Expanded(
              child: CategoryTile(
                name: 'World Facts',
                emoji: '🌍',
                caption: 'Lv 7/20',
                progress: 0.35,
              ),
            ),
            const Expanded(
              child: CategoryTile(name: 'Movies', emoji: '🎬', caption: 'New'),
            ),
            const Expanded(
              child: CategoryTile(
                name: 'Puzzles',
                emoji: '🧩',
                caption: 'Locked',
                isLocked: true,
              ),
            ),
          ],
        ),
        body: () async {
          expect(find.text('World Facts'), findsOneWidget);
          expect(find.text('🔒'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });
  });

  group('SubcategoryCard', () {
    Subcategory topicWith({
      String name = 'Football',
      int levelsCleared = 0,
      int levelCount = 50,
      int starsEarned = 0,
      bool isLocked = false,
    }) => Subcategory(
      id: 'sub_x',
      categoryId: 'cat_x',
      name: name,
      emoji: '⚽',
      plateColor: '#FFE9D6',
      questionCount: 400,
      levelsCleared: levelsCleared,
      levelCount: levelCount,
      starsEarned: starsEarned,
      isLocked: isLocked,
    );

    testWidgets('renders every content state from the table in both themes', (
      tester,
    ) async {
      await tester.pumpInBothThemes(
        () => Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Row(
              children: [
                Expanded(
                  child: SubcategoryCard.forTopic(
                    topicWith(isLocked: true),
                    l10n,
                  ),
                ),
                Expanded(child: SubcategoryCard.forTopic(topicWith(), l10n)),
                Expanded(
                  child: SubcategoryCard.forTopic(
                    topicWith(
                      levelsCleared: 50,
                      levelCount: 50,
                      starsEarned: 150,
                    ),
                    l10n,
                  ),
                ),
                Expanded(
                  child: SubcategoryCard.forTopic(
                    topicWith(levelsCleared: 12, starsEarned: 24),
                    l10n,
                  ),
                ),
              ],
            );
          },
        ),
        body: () async {
          // Locked, never-played, complete and in-progress — one of each.
          expect(find.text('Locked'), findsOneWidget);
          expect(find.text('400 questions'), findsOneWidget);
          expect(find.text('New'), findsOneWidget);
          expect(find.text('Complete'), findsOneWidget);
          expect(find.text('⭐⭐⭐'), findsOneWidget);
          expect(find.text('Lv 12'), findsOneWidget);
          expect(find.text('⭐⭐'), findsOneWidget);
          // The lock scrim renders on top of the locked card only.
          expect(find.text('🔒'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('a wrapped two-line name does not change the card height', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Column(
              children: [
                SubcategoryCard.forTopic(
                  topicWith(name: 'Football'),
                  l10n,
                  width: SubcategoryCard.railWidth,
                ),
                SubcategoryCard.forTopic(
                  topicWith(name: 'A very long topic name that wraps twice'),
                  l10n,
                  width: SubcategoryCard.railWidth,
                ),
              ],
            );
          },
        ),
      );

      final heights = tester
          .widgetList<SubcategoryCard>(find.byType(SubcategoryCard))
          .map((card) => tester.getSize(find.byWidget(card)).height)
          .toSet();

      expect(heights, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('CategorySectionHeader', () {
    testWidgets('shows a plain count at ten topics, the pill past it', (
      tester,
    ) async {
      await tester.pumpApp(
        const Column(
          children: [
            CategorySectionHeader(name: 'Sports', emoji: '⚽', topicCount: 10),
            CategorySectionHeader(
              name: 'General',
              emoji: '🌍',
              topicCount: 11,
              showSeeAll: true,
            ),
          ],
        ),
      );

      expect(find.text('10 topics'), findsOneWidget);
      expect(find.text('See all 11'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the whole row is one tap target, not just the pill', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        CategorySectionHeader(
          name: 'Sports',
          emoji: '⚽',
          topicCount: 8,
          onTap: () => taps++,
        ),
      );

      // Tapping the category name, not a dedicated button, still fires it.
      await tester.tap(find.text('Sports'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('LevelNode', () {
    testWidgets('renders every status and the boss crown in both themes', (
      tester,
    ) async {
      await tester.pumpInBothThemes(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LevelNode(
              number: 7,
              status: LevelStatus.done,
              starsEarned: 3,
            ),
            const LevelNode(number: 8, status: LevelStatus.current),
            const LevelNode(number: 9, status: LevelStatus.locked),
            const LevelNode(
              number: 10,
              status: LevelStatus.locked,
              isBoss: true,
            ),
          ],
        ),
        body: () async {
          expect(find.text('⭐⭐⭐'), findsOneWidget);
          expect(find.text('👑'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('a locked node is not tappable', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        LevelNode(number: 9, status: LevelStatus.locked, onTap: () => taps++),
      );

      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });
  });

  group('PowerUpTile', () {
    testWidgets('renders available and empty in both themes', (tester) async {
      await tester.pumpInBothThemes(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PowerUpTile(
              emoji: '🎯',
              label: '50:50',
              count: 3,
              onUse: () {},
              onBuy: () {},
            ),
            PowerUpTile(
              emoji: '❄️',
              label: 'FREEZE',
              count: 0,
              onUse: () {},
              onBuy: () {},
            ),
          ],
        ),
        body: () async {
          expect(find.text('50:50'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('a zero-count tile routes to the shop instead of firing', (
      tester,
    ) async {
      var used = 0;
      var bought = 0;
      await tester.pumpApp(
        PowerUpTile(
          emoji: '❄️',
          label: 'FREEZE',
          count: 0,
          onUse: () => used++,
          onBuy: () => bought++,
        ),
      );

      await tester.tap(find.byType(PowerUpTile));
      await tester.pumpAndSettle();

      expect(used, 0);
      expect(bought, 1);
    });
  });

  group('SkeletonBox', () {
    testWidgets('renders in both themes', (tester) async {
      await tester.pumpInBothThemes(
        () => const SkeletonBox(
          width: 172,
          height: 132,
          appearAfter: Duration.zero,
        ),
        body: () async {
          expect(tester.takeException(), isNull);
        },
      );
      // Stop the infinite shimmer so the tester can settle.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('stays invisible until the 300ms wait has elapsed', (
      tester,
    ) async {
      await tester.pumpApp(const SkeletonBox(width: 100, height: 20));
      expect(tester.widget<SizedBox>(find.byType(SizedBox).last).child, isNull);

      await tester.pump(const Duration(milliseconds: 320));
      expect(find.byType(AnimatedBuilder), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('does not animate under reduced motion', (tester) async {
      await tester.pumpApp(
        const SkeletonBox(width: 100, height: 20, appearAfter: Duration.zero),
        disableAnimations: true,
      );

      // A running shimmer would leave the tester with pending frames forever.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('AppSnackbar', () {
    testWidgets('renders every intent in both themes', (tester) async {
      for (final intent in SnackbarIntent.values) {
        await tester.pumpInBothThemes(
          () => AppSnackbar(
            title: intent.name,
            message: 'A second line',
            intent: intent,
          ),
          body: () async {
            expect(find.text(intent.name), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    });

    testWidgets('show replaces the current snackbar rather than stacking', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Column(
            children: [
              ChunkyButton(
                label: 'first',
                onPressed: () => AppSnackbar.show(
                  context,
                  title: 'Progress saved',
                  intent: SnackbarIntent.success,
                ),
              ),
              ChunkyButton(
                label: 'second',
                onPressed: () => AppSnackbar.show(
                  context,
                  title: "You're offline",
                  intent: SnackbarIntent.error,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('first'));
      await tester.pump();
      expect(find.text('Progress saved'), findsOneWidget);

      await tester.tap(find.text('second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Progress saved'), findsNothing);
      expect(find.text("You're offline"), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('EmptyStateView / ErrorStateView', () {
    testWidgets('render in both themes', (tester) async {
      await tester.pumpInBothThemes(
        () => EmptyStateView(
          emoji: '🔍',
          title: 'Nothing here yet',
          message: 'Try a different category.',
          action: ChunkyButton(label: 'Browse', onPressed: () {}),
        ),
        body: () async {
          expect(find.text('Nothing here yet'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      await tester.pumpInBothThemes(
        () => ErrorStateView(
          title: "Couldn't load this level",
          message: 'Check your connection and try again.',
          errorCode: 'ERR_CONTENT_404',
          action: ChunkyButton(label: 'Try again', onPressed: () {}),
        ),
        body: () async {
          expect(find.text('ERR_CONTENT_404'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });
  });

  group('AppBottomSheet / AppDialog', () {
    testWidgets('render in both themes', (tester) async {
      await tester.pumpInBothThemes(
        () => AppBottomSheet(
          title: 'Play',
          message: 'Pick how you want to play right now.',
          child: ChunkyButton(label: 'Quick Play', onPressed: () {}),
        ),
        body: () async {
          expect(find.text('Play'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      await tester.pumpInBothThemes(
        () => AppDialog(
          emoji: '🗑️',
          title: 'Delete your account?',
          message: 'This cannot be undone.',
          actions: [
            ChunkyButton.ghost(label: 'Keep my account', onPressed: () {}),
            const ChunkyButton(label: 'Delete permanently', onPressed: null),
          ],
        ),
        body: () async {
          expect(find.text('Delete your account?'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('AppBottomSheet.show presents and pops with a value', (
      tester,
    ) async {
      String? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => ChunkyButton(
            label: 'open',
            onPressed: () async {
              result = await AppBottomSheet.show<String>(
                context,
                builder: (sheetContext) => AppBottomSheet(
                  title: 'Sheet',
                  child: ChunkyButton(
                    label: 'pick',
                    onPressed: () => Navigator.of(sheetContext).pop('picked'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsOneWidget);

      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(result, 'picked');
    });
  });

  group('ShareSheet', () {
    testWidgets('renders its preview and targets in both themes', (
      tester,
    ) async {
      await tester.pumpInBothThemes(
        () => ShareSheet(
          title: 'Share your result',
          message: 'Spoiler-free — no answers included.',
          preview: const Text('8/10 · beat 82% of players'),
          onMoreOptions: () {},
          targets: [
            ShareTarget(emoji: '💬', label: 'WhatsApp', onTap: () {}),
            ShareTarget(emoji: '🔗', label: 'Copy', onTap: () {}),
          ],
        ),
        body: () async {
          expect(find.text('WhatsApp'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });
  });

  group('ReportQuestionSheet', () {
    testWidgets('renders in both themes', (tester) async {
      await tester.pumpInBothThemes(
        () => ReportQuestionSheet(
          title: 'Report this question',
          message: 'Question 6 · Football · Level 12.',
          submitLabel: 'Send report',
          reasons: const ['The answer is wrong', 'Question is unclear'],
          onSubmit: (_) {},
        ),
        body: () async {
          expect(find.text('Question is unclear'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('submit stays disabled until a reason is chosen', (
      tester,
    ) async {
      int? submitted;
      await tester.pumpApp(
        ReportQuestionSheet(
          title: 'Report this question',
          submitLabel: 'Send report',
          reasons: const ['The answer is wrong', 'Question is unclear'],
          onSubmit: (index) => submitted = index,
        ),
      );

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(submitted, isNull);

      await tester.tap(find.text('Question is unclear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(submitted, 1);
    });
  });
}
