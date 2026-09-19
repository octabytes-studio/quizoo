import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/quiz_play/data/rewarded_ad_service.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/heart_ad_cubit.dart';

/// A fake rather than a mocktail `Mock`: the Cubit's phase machine is driven
/// through real completer-controlled timing, which a stubbed `Mock` can't
/// express (same reasoning as `quiz_play_cubit_test.dart`'s `_FakeTtsService`).
class _FakeRewardedAdService implements RewardedAdService {
  Completer<bool> loadCompleter = Completer<bool>();
  Completer<bool> showCompleter = Completer<bool>();
  int loadCount = 0;
  int disposeCount = 0;

  @override
  Future<bool> load() {
    loadCount++;
    loadCompleter = Completer<bool>();
    return loadCompleter.future;
  }

  @override
  Future<bool> show() {
    showCompleter = Completer<bool>();
    return showCompleter.future;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

void main() {
  late _FakeRewardedAdService service;

  setUp(() {
    service = _FakeRewardedAdService();
  });

  group('HeartAdCubit', () {
    test('starts ready, with nothing loaded until the player taps', () {
      final cubit = HeartAdCubit(service);
      expect(cubit.state, isA<HeartAdReady>());
      expect(service.loadCount, 0);
      unawaited(cubit.close());
    });

    blocTest<HeartAdCubit, HeartAdState>(
      'watch() loads on tap, then plays and succeeds once earned',
      build: () => HeartAdCubit(service),
      act: (cubit) async {
        unawaited(cubit.watch());
        await Future<void>.delayed(Duration.zero);
        service.loadCompleter.complete(true);
        await Future<void>.delayed(Duration.zero);
        service.showCompleter.complete(true);
      },
      expect: () => [
        isA<HeartAdLoading>(),
        isA<HeartAdPlaying>(),
        isA<HeartAdSucceeded>(),
      ],
      verify: (_) => expect(service.loadCount, 1),
    );

    blocTest<HeartAdCubit, HeartAdState>(
      'a load failure ends in HeartAdFailed without ever showing the ad',
      build: () => HeartAdCubit(service),
      act: (cubit) async {
        unawaited(cubit.watch());
        await Future<void>.delayed(Duration.zero);
        service.loadCompleter.complete(false);
      },
      expect: () => [isA<HeartAdLoading>(), isA<HeartAdFailed>()],
    );

    blocTest<HeartAdCubit, HeartAdState>(
      'a failed watch ends in HeartAdFailed — never a dead button',
      build: () => HeartAdCubit(service),
      act: (cubit) async {
        unawaited(cubit.watch());
        await Future<void>.delayed(Duration.zero);
        service.loadCompleter.complete(true);
        await Future<void>.delayed(Duration.zero);
        service.showCompleter.complete(false);
      },
      expect: () => [
        isA<HeartAdLoading>(),
        isA<HeartAdPlaying>(),
        isA<HeartAdFailed>(),
      ],
    );

    blocTest<HeartAdCubit, HeartAdState>(
      'tapping watch() again after a failure retries from scratch',
      build: () => HeartAdCubit(service),
      act: (cubit) async {
        unawaited(cubit.watch());
        await Future<void>.delayed(Duration.zero);
        service.loadCompleter.complete(false);
        await Future<void>.delayed(Duration.zero);
        unawaited(cubit.watch());
        await Future<void>.delayed(Duration.zero);
        service.loadCompleter.complete(true);
        await Future<void>.delayed(Duration.zero);
        service.showCompleter.complete(true);
      },
      expect: () => [
        isA<HeartAdLoading>(),
        isA<HeartAdFailed>(),
        isA<HeartAdLoading>(),
        isA<HeartAdPlaying>(),
        isA<HeartAdSucceeded>(),
      ],
      verify: (_) => expect(service.loadCount, 2),
    );
  });
}
