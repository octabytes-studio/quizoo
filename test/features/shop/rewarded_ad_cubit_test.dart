import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/shop/presentation/bloc/rewarded_ad_cubit.dart';

/// Never rolls below [RewardedAdCubit.failureRate] — deterministic success,
/// so the success-path test isn't a ~1-in-6 coin flip.
class _AlwaysSucceedRandom implements Random {
  @override
  double nextDouble() => 1.0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  RewardedAdCubit build({Random? random}) => RewardedAdCubit(
    coinsBefore: 100,
    rewardCoins: 50,
    freeAdsLeft: 2,
    freeAdsPerDay: 3,
    random: random ?? _AlwaysSucceedRandom(),
  );

  group('RewardedAdCubit', () {
    test('starts ready, with the projected balance already computed', () {
      final cubit = build();
      expect(cubit.state, isA<RewardedAdReady>());
      expect(cubit.state.coinsAfter, 150);
    });

    test('success path: watching plays the ad then succeeds', () {
      fakeAsync((async) {
        final cubit = build()..watch();
        expect(cubit.state, isA<RewardedAdPlaying>());

        async.elapse(RewardedAdCubit.adDuration);
        expect(cubit.state, isA<RewardedAdSucceeded>());
        expect(cubit.state.coinsAfter, 150);

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('failure path: a failed load never leaves the button dead — retry '
        'returns to Ready', () {
      fakeAsync((async) {
        final cubit = build()
          ..debugForceNextFailure = true
          ..watch();

        async.elapse(RewardedAdCubit.adDuration);
        expect(cubit.state, isA<RewardedAdFailed>());

        cubit.retry();
        expect(cubit.state, isA<RewardedAdReady>());

        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });
  });
}
