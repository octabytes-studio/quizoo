import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/ads/ad_dimensions.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/widgets/ad_label.dart';
import 'package:quizoo/core/widgets/anchored_banner_ad.dart';
import 'package:quizoo/core/widgets/inline_ad_view.dart';
import 'package:quizoo/core/widgets/medium_rectangle_ad.dart';
import 'package:quizoo/core/widgets/native_ad_card.dart';
import 'package:quizoo/core/widgets/native_ad_tile.dart';

import '../../support/fake_ads.dart';
import '../../support/pump_screen.dart';

/// The four ad widgets, each with the placement it would really be used at
/// and the height it must hold open.
final _widgets =
    <
      ({
        String name,
        Widget widget,
        double height,
        bool keepsSpace,
        Matcher matchesRequest,
      })
    >[
      (
        name: 'AnchoredBannerAd',
        widget: const AnchoredBannerAd(placement: AdPlacement.levelMapBanner),
        height: 60,
        keepsSpace: true,
        matchesRequest: isA<AnchoredBannerRequest>().having(
          (request) => request.widthDp,
          'widthDp',
          390,
        ),
      ),
      (
        name: 'MediumRectangleAd',
        widget: const MediumRectangleAd(
          placement: AdPlacement.dailyTabRectangle,
        ),
        height: AdDimensions.rectangleHeight,
        keepsSpace: false,
        matchesRequest: isA<RectangleBannerRequest>(),
      ),
      (
        name: 'NativeAdTile',
        widget: const NativeAdTile(placement: AdPlacement.homeFeedNative),
        height: AdDimensions.nativeSmallHeight,
        keepsSpace: false,
        matchesRequest: isA<NativeAdRequest>().having(
          (request) => request.size,
          'size',
          NativeAdSize.small,
        ),
      ),
      (
        name: 'NativeAdCard',
        widget: const NativeAdCard(placement: AdPlacement.dailyResultNative),
        height: AdDimensions.nativeMediumHeight,
        keepsSpace: false,
        matchesRequest: isA<NativeAdRequest>().having(
          (request) => request.size,
          'size',
          NativeAdSize.medium,
        ),
      ),
    ];

void main() {
  /// Hosts [ad] the way a screen would: at the top of a column, so its own
  /// height is what gets measured.
  Future<void> pumpAd(
    WidgetTester tester,
    Widget ad, {
    required FakeAdsCubit ads,
    required FakeInlineAdService service,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpScreen(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [KeyedSubtree(key: const Key('ad'), child: ad)],
      ),
      ads: ads,
      inlineAds: service,
      brightness: brightness,
    );
  }

  double adHeight(WidgetTester tester) =>
      tester.getSize(find.byKey(const Key('ad'))).height;

  for (final entry in _widgets) {
    group(entry.name, () {
      testWidgets('renders nothing while ads are disabled', (tester) async {
        final service = FakeInlineAdService(fills: true);
        await pumpAd(
          tester,
          entry.widget,
          ads: FakeAdsCubit(),
          service: service,
        );
        await tester.pumpAndSettle();

        expect(adHeight(tester), 0);
        expect(find.byType(InlineAdView), findsNothing);
        expect(service.requests, isEmpty, reason: 'no ad request without ads');
      });

      testWidgets('renders nothing when its placement is switched off', (
        tester,
      ) async {
        final service = FakeInlineAdService(fills: true);
        await pumpAd(
          tester,
          entry.widget,
          ads: FakeAdsCubit.ready(
            config: AdsConfig(
              disabledPlacements: {for (final p in AdPlacement.values) p.id},
            ),
          ),
          service: service,
        );
        await tester.pumpAndSettle();

        expect(adHeight(tester), 0);
        expect(service.requests, isEmpty);
      });

      testWidgets('reserves its height while the ad loads', (tester) async {
        final service = FakeInlineAdService(fills: true)
          ..loadGate = Completer<void>();
        await pumpAd(
          tester,
          entry.widget,
          ads: FakeAdsCubit.ready(),
          service: service,
        );
        await tester.pump();

        expect(find.byType(InlineAdView), findsNothing);
        expect(adHeight(tester), greaterThanOrEqualTo(entry.height));

        final reserved = adHeight(tester);
        service.loadGate!.complete();
        await tester.pumpAndSettle();

        expect(find.byType(InlineAdView), findsOneWidget);
        expect(
          adHeight(tester),
          reserved,
          reason: 'nothing moves when the ad arrives',
        );
      });

      testWidgets('renders the ad at its SDK size, in both themes', (
        tester,
      ) async {
        for (final brightness in Brightness.values) {
          await pumpAd(
            tester,
            entry.widget,
            ads: FakeAdsCubit.ready(),
            service: FakeInlineAdService(fills: true),
            brightness: brightness,
          );
          await tester.pumpAndSettle();

          expect(
            tester.getSize(find.byType(InlineAdView)).height,
            entry.height,
          );
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets(
        entry.keepsSpace
            ? 'keeps its space when no ad arrives'
            : 'folds away when no ad arrives',
        (tester) async {
          await pumpAd(
            tester,
            entry.widget,
            ads: FakeAdsCubit.ready(),
            service: FakeInlineAdService(),
          );
          await tester.pumpAndSettle();

          expect(find.byType(InlineAdView), findsNothing);
          if (entry.keepsSpace) {
            expect(adHeight(tester), greaterThanOrEqualTo(entry.height));
          } else {
            expect(adHeight(tester), 0);
            expect(find.byType(AdLabel), findsNothing);
          }
        },
      );

      testWidgets(
        entry.keepsSpace
            ? 'is a bare strip, with no caption'
            : 'is labelled "Advertisement"',
        (tester) async {
          await pumpAd(
            tester,
            entry.widget,
            ads: FakeAdsCubit.ready(),
            service: FakeInlineAdService(fills: true),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('Advertisement'),
            entry.keepsSpace ? findsNothing : findsOneWidget,
          );
        },
      );

      testWidgets('asks for its own format', (tester) async {
        final service = FakeInlineAdService(fills: true);
        await pumpAd(
          tester,
          entry.widget,
          ads: FakeAdsCubit.ready(),
          service: service,
        );
        await tester.pumpAndSettle();

        expect(service.requests.single, entry.matchesRequest);
      });
    });
  }

  testWidgets('a hidden anchored banner requests no ad', (tester) async {
    final service = FakeInlineAdService(fills: true);
    await pumpAd(
      tester,
      const AnchoredBannerAd(
        placement: AdPlacement.levelMapBanner,
        isVisible: false,
      ),
      ads: FakeAdsCubit.ready(),
      service: service,
    );
    await tester.pumpAndSettle();

    expect(adHeight(tester), 0);
    expect(service.requests, isEmpty);
  });

  testWidgets('a native ad is requested again in the new theme\'s colours', (
    tester,
  ) async {
    final service = FakeInlineAdService(fills: true);
    final ads = FakeAdsCubit.ready();
    const tile = NativeAdTile(placement: AdPlacement.homeFeedNative);

    await pumpAd(tester, tile, ads: ads, service: service);
    await tester.pumpAndSettle();
    await pumpAd(
      tester,
      tile,
      ads: ads,
      service: service,
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();

    final palettes = [
      for (final request in service.requests)
        (request as NativeAdRequest).palette.background,
    ];
    expect(palettes, hasLength(2));
    expect(palettes.first, isNot(palettes.last));
    expect(service.loaded.first.isDisposed, isTrue);
  });
}
