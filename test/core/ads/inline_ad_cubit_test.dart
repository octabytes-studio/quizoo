import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_cubit.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';

import '../../support/fake_ads.dart';

const _banner = AnchoredBannerRequest(
  placement: AdPlacement.levelMapBanner,
  widthDp: 390,
);
const _rectangle = RectangleBannerRequest(
  placement: AdPlacement.dailyTabRectangle,
);

void main() {
  late FakeInlineAdService service;

  setUp(() => service = FakeInlineAdService());

  group('InlineAdCubit', () {
    test('starts loading, reserving the height it was given', () {
      final cubit = InlineAdCubit(service, initialReservedHeight: 250);

      expect(cubit.state, const InlineAdLoading(reservedHeight: 250));
      expect(service.requests, isEmpty);
      unawaited(cubit.close());
    });

    blocTest<InlineAdCubit, InlineAdState>(
      'load() reserves the height, then shows the ad',
      setUp: () => service.fills = true,
      build: () => InlineAdCubit(service),
      act: (cubit) => cubit.load(_banner),
      expect: () => [
        const InlineAdLoading(reservedHeight: 60),
        isA<InlineAdLoaded>(),
      ],
      verify: (cubit) {
        expect(service.requests, [_banner]);
        expect((cubit.state as InlineAdLoaded).ad, service.loaded.single);
      },
    );

    blocTest<InlineAdCubit, InlineAdState>(
      'a failed load ends unavailable, still knowing the reserved height',
      build: () => InlineAdCubit(service),
      act: (cubit) => cubit.load(_banner),
      expect: () => const [
        InlineAdLoading(reservedHeight: 60),
        InlineAdUnavailable(reservedHeight: 60),
      ],
    );

    blocTest<InlineAdCubit, InlineAdState>(
      'a slot the SDK cannot size is unavailable without requesting an ad',
      setUp: () => service.anchoredHeight = null,
      build: () => InlineAdCubit(service),
      act: (cubit) => cubit.load(_banner),
      expect: () => const [InlineAdUnavailable(reservedHeight: 0)],
      verify: (_) => expect(service.requests, isEmpty),
    );

    blocTest<InlineAdCubit, InlineAdState>(
      'a fixed-size slot holds the same reserved height until the ad arrives',
      setUp: () => service.fills = true,
      build: () => InlineAdCubit(service, initialReservedHeight: 250),
      act: (cubit) => cubit.load(_rectangle),
      expect: () => [
        const InlineAdLoading(reservedHeight: 250),
        isA<InlineAdLoaded>(),
      ],
    );

    test('an ad that arrives after close() is disposed, not shown', () async {
      service
        ..fills = true
        ..loadGate = Completer<void>();
      final cubit = InlineAdCubit(service);
      final loading = cubit.load(_banner);
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      service.loadGate!.complete();
      await loading;

      expect(service.loaded.single.isDisposed, isTrue);
    });

    test('close() disposes the ad on screen', () async {
      service.fills = true;
      final cubit = InlineAdCubit(service);
      await cubit.load(_banner);

      await cubit.close();

      expect(service.loaded.single.isDisposed, isTrue);
    });

    group('refreshIfStale', () {
      late DateTime clock;

      Future<InlineAdCubit> loaded() async {
        service.fills = true;
        clock = DateTime(2026, 10, 1, 12);
        final cubit = InlineAdCubit(service, now: () => clock);
        await cubit.load(_banner);
        return cubit;
      }

      test('leaves a fresh ad alone', () async {
        final cubit = await loaded();
        clock = clock.add(const Duration(minutes: 54));

        await cubit.refreshIfStale();

        expect(service.requests, hasLength(1));
        expect(service.loaded.single.isDisposed, isFalse);
        await cubit.close();
      });

      test('swaps an expired ad for a new one', () async {
        final cubit = await loaded();
        clock = clock.add(adFreshnessWindow);

        await cubit.refreshIfStale();

        expect(service.requests, hasLength(2));
        expect(service.loaded.first.isDisposed, isTrue);
        expect((cubit.state as InlineAdLoaded).ad, service.loaded.last);
        await cubit.close();
      });

      test('keeps the current ad when the refresh fails', () async {
        final cubit = await loaded();
        clock = clock.add(adFreshnessWindow);
        service.fills = false;

        await cubit.refreshIfStale();

        expect((cubit.state as InlineAdLoaded).ad, service.loaded.single);
        expect(service.loaded.single.isDisposed, isFalse);
        await cubit.close();
      });

      test('does nothing for a slot with no ad', () async {
        final cubit = InlineAdCubit(service);
        await cubit.load(_banner);

        await cubit.refreshIfStale();

        expect(service.requests, hasLength(1));
        await cubit.close();
      });
    });
  });
}
