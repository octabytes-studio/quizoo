import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/pro_name.dart';
import 'package:quizoo/core/widgets/pro_tick.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';
import 'package:quizoo/core/widgets/app_mark.dart';
import 'package:quizoo/features/subscription/presentation/widgets/paywall_hero.dart';

import '../../support/pump_app.dart';

void main() {
  // Regression guards for the Pro UI:
  //  * "only show the verified tick in front of the name of a Pro user — no
  //    crown badge on the profile picture"
  //  * "replace the owl emoji with the app icon" on the paywall and the
  //    purchased screens.
  group('the Pro marker is the tick, never a crown on an avatar', () {
    testWidgets('ProName shows the tick only for a member', (tester) async {
      await tester.pumpApp(
        const Column(
          children: [
            ProName(name: 'Waleed', isPro: true),
            ProName(name: 'Ayesha', isPro: false),
          ],
        ),
      );

      expect(find.byType(ProTick), findsOneWidget);
      expect(find.text('Waleed'), findsOneWidget);
      expect(find.text('Ayesha'), findsOneWidget);
    });

    testWidgets('ProName truncates a long name and keeps the tick', (
      tester,
    ) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 120,
            child: ProName(
              name: 'A very very very long player name indeed',
              isPro: true,
            ),
          ),
        ),
      );

      expect(find.byType(ProTick), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ListRowTile carries the tick and no crown', (tester) async {
      await tester.pumpApp(
        const ListRowTile(title: 'Waleed', leadingEmoji: '🐼', isPro: true),
      );

      expect(find.byType(ProTick), findsOneWidget);
      expect(find.text('👑'), findsNothing);
    });

    testWidgets('ListRowTile shows nothing extra for a free player', (
      tester,
    ) async {
      await tester.pumpApp(
        const ListRowTile(title: 'Ayesha', leadingEmoji: '🦊', isPro: false),
      );

      expect(find.byType(ProTick), findsNothing);
      expect(find.text('👑'), findsNothing);
    });

    testWidgets('PlayerTopBar carries the tick and no crown', (tester) async {
      await tester.pumpApp(
        PlayerTopBar(
          name: 'Waleed',
          avatarEmoji: '🐼',
          dayStreak: 3,
          playerLevel: 4,
          onSearchPressed: () {},
          onAvatarTap: () {},
          isPro: true,
        ),
      );

      expect(find.byType(ProTick), findsOneWidget);
      expect(find.text('👑'), findsNothing);
    });

    testWidgets('the tick still shows under RTL (Urdu)', (tester) async {
      await tester.pumpApp(
        Directionality(
          textDirection: TextDirection.rtl,
          child: const ProName(name: 'Waleed', isPro: true),
        ),
      );

      // The row mirrors, but the tick is still drawn after the name in
      // reading order — never dropped.
      expect(find.byType(ProTick), findsOneWidget);
    });
  });

  group('ListRowTile leading', () {
    testWidgets('leadingChild replaces the emoji inside the plate', (
      tester,
    ) async {
      await tester.pumpApp(
        const ListRowTile(
          title: 'Quizoo Pro · Active',
          leadingEmoji: '👑',
          leadingChild: Icon(Icons.apps),
        ),
      );

      // The custom widget wins, and no emoji glyph is drawn.
      expect(find.byIcon(Icons.apps), findsOneWidget);
      expect(find.text('👑'), findsNothing);
    });

    testWidgets('without leadingChild the emoji still renders', (tester) async {
      await tester.pumpApp(
        const ListRowTile(title: 'Cricket', leadingEmoji: '⚽'),
      );

      expect(find.text('⚽'), findsOneWidget);
    });
  });

  group('PaywallHero', () {
    testWidgets('shows the app mark, not an owl emoji', (tester) async {
      await tester.pumpApp(const PaywallHero());
      // `PaywallHero` animates its entrance (`flutter_animate`), so let the
      // tickers drain before asserting.
      await tester.pumpAndSettle();

      expect(find.byType(AppMark), findsOneWidget);
      expect(find.text('🦉'), findsNothing);
    });

    testWidgets('wears no crown badge on the mark', (tester) async {
      await tester.pumpApp(const PaywallHero());
      await tester.pumpAndSettle();

      expect(find.text('👑'), findsNothing);
    });
  });
}
