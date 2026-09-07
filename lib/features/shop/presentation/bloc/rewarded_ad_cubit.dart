import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'rewarded_ad_state.dart';

/// Owns S-37's modal: the mocked ad "plays" for [adDuration] then either
/// succeeds or, occasionally, fails to load.
///
/// The wallet itself is not this Cubit's to change — [ShopCubit] owns the
/// wallet, and the dialog reports success back up to it (see
/// `RewardedAdDialog`) rather than each holding its own copy of the balance.
class RewardedAdCubit extends Cubit<RewardedAdState> {
  RewardedAdCubit({
    required int coinsBefore,
    required int rewardCoins,
    required int freeAdsLeft,
    required int freeAdsPerDay,
    Random? random,
  }) : _random = random ?? Random(),
       super(
         RewardedAdReady(
           coinsBefore: coinsBefore,
           rewardCoins: rewardCoins,
           freeAdsLeft: freeAdsLeft,
           freeAdsPerDay: freeAdsPerDay,
         ),
       );

  final Random _random;

  /// The mocked ad's runtime.
  static const Duration adDuration = Duration(milliseconds: 1200);

  /// Roughly one ad in six fails to load — often enough that the required
  /// toast fallback (plan 004, Research findings) actually gets exercised in
  /// review, rare enough the dialog is usually a clean success.
  static const double failureRate = 1 / 6;

  /// Forces the next [watch] to fail, whatever [failureRate] says — a test's
  /// deterministic hook, mirroring `MockApi.failNextRequest`.
  bool debugForceNextFailure = false;

  Timer? _adTimer;

  Future<void> watch() async {
    final current = state;
    if (current is! RewardedAdReady) return;
    emit(_playingFrom(current));

    final completer = Completer<void>();
    _adTimer?.cancel();
    _adTimer = Timer(adDuration, completer.complete);
    await completer.future;
    if (isClosed) return;

    final fails = debugForceNextFailure || _random.nextDouble() < failureRate;
    debugForceNextFailure = false;

    final playing = state;
    if (playing is! RewardedAdPlaying) return;
    emit(
      fails
          ? RewardedAdFailed(
              coinsBefore: playing.coinsBefore,
              rewardCoins: playing.rewardCoins,
              freeAdsLeft: playing.freeAdsLeft,
              freeAdsPerDay: playing.freeAdsPerDay,
            )
          : RewardedAdSucceeded(
              coinsBefore: playing.coinsBefore,
              rewardCoins: playing.rewardCoins,
              freeAdsLeft: playing.freeAdsLeft,
              freeAdsPerDay: playing.freeAdsPerDay,
            ),
    );
  }

  /// Returns to a tappable [RewardedAdReady] after a failure — the toast
  /// fallback must never leave the button dead (plan 004, Edge cases).
  void retry() {
    final current = state;
    if (current is! RewardedAdFailed) return;
    emit(
      RewardedAdReady(
        coinsBefore: current.coinsBefore,
        rewardCoins: current.rewardCoins,
        freeAdsLeft: current.freeAdsLeft,
        freeAdsPerDay: current.freeAdsPerDay,
      ),
    );
  }

  RewardedAdPlaying _playingFrom(RewardedAdReady ready) => RewardedAdPlaying(
    coinsBefore: ready.coinsBefore,
    rewardCoins: ready.rewardCoins,
    freeAdsLeft: ready.freeAdsLeft,
    freeAdsPerDay: ready.freeAdsPerDay,
  );

  @override
  Future<void> close() {
    _adTimer?.cancel();
    return super.close();
  }
}
