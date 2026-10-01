import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/widgets/inline_ad_view.dart';
import 'package:quizoo/core/widgets/native_ad_card.dart';
import 'package:quizoo/core/widgets/result_wash.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/daily/presentation/screens/daily_result_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/fake_ads.dart';
import '../../support/pump_screen.dart';

/// Hosts the result one push above a launcher, so `context.pop()` has
/// somewhere to go — the way the Daily tab sits under it in the app.
class _Launcher extends StatelessWidget {
  const _Launcher({required this.result});

  final DailyResult result;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DailyResultScreen(result: result),
          ),
        ),
        child: const Text('launcher'),
      ),
    );
  }
}

void main() {
  Future<void> pumpResult(
    WidgetTester tester, {
    required FakeAdsCubit ads,
    DailyResult? result,
    FakeInlineAdService? inlineAds,
  }) async {
    await tester.pumpScreen(
      _Launcher(result: result ?? DailyResult.preview()),
      ads: ads,
      inlineAds: inlineAds,
    );
    await tester.tap(find.text('launcher'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  String backToDaily(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(DailyResultScreen)),
  ).dailyResultBackToDaily;

  group('DailyResultScreen ads (plan 022)', () {
    testWidgets('"Back to daily" waits for the interstitial break, then pops', (
      tester,
    ) async {
      final ads = FakeAdsCubit.ready()..interstitialGate = Completer<void>();
      await pumpResult(tester, ads: ads);
      final label = backToDaily(tester);

      await tester.tap(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();

      expect(ads.breaks, [
        (placement: AdPlacement.dailyResultBreak, isCelebration: false),
      ]);
      expect(find.byType(DailyResultScreen), findsOneWidget);

      ads.interstitialGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DailyResultScreen), findsNothing);
      expect(find.text('launcher'), findsOneWidget);
    });

    testWidgets('✕ is a break too', (tester) async {
      final ads = FakeAdsCubit.ready();
      await pumpResult(tester, ads: ads);

      await tester.tap(find.text('✕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(ads.breaks.single.placement, AdPlacement.dailyResultBreak);
      expect(find.byType(DailyResultScreen), findsNothing);
    });

    testWidgets('sharing is not a break', (tester) async {
      final ads = FakeAdsCubit.ready();
      await pumpResult(tester, ads: ads);

      await tester.tap(find.text('↗'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(ads.breaks, isEmpty);
    });

    testWidgets('a day that earned a badge is flagged as a celebration', (
      tester,
    ) async {
      final ads = FakeAdsCubit.ready();
      await pumpResult(
        tester,
        ads: ads,
        result: DailyResult.preview().copyWith(
          newlyEarnedBadgeIds: ['daily_7'],
        ),
      );
      // The badge celebration is on top by now, so ✕ is invoked directly.
      tester
          .widget<ResultWash>(find.byType(ResultWash, skipOffstage: false))
          .onClose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(ads.breaks.single.isCelebration, isTrue);
    });

    testWidgets('shows a medium native card under the distribution card', (
      tester,
    ) async {
      final inlineAds = FakeInlineAdService(fills: true);
      await pumpResult(tester, ads: FakeAdsCubit.ready(), inlineAds: inlineAds);

      expect(
        find.descendant(
          of: find.byType(NativeAdCard),
          matching: find.byType(InlineAdView),
        ),
        findsOneWidget,
      );
      expect(
        inlineAds.requests.single.placement,
        AdPlacement.dailyResultNative,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
