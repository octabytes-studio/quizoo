part of 'rewarded_ad_cubit.dart';

/// S-37's states (CLAUDE.md §3). Every variant carries the same numbers —
/// only the phase differs — so they live on the sealed base rather than being
/// re-declared per subtype.
sealed class RewardedAdState extends Equatable {
  const RewardedAdState({
    required this.coinsBefore,
    required this.rewardCoins,
    required this.freeAdsLeft,
    required this.freeAdsPerDay,
  });

  final int coinsBefore;
  final int rewardCoins;
  final int freeAdsLeft;
  final int freeAdsPerDay;

  /// The projected balance the mint-outlined chip shows.
  int get coinsAfter => coinsBefore + rewardCoins;

  @override
  List<Object?> get props => [
    coinsBefore,
    rewardCoins,
    freeAdsLeft,
    freeAdsPerDay,
  ];
}

/// Idle, waiting for "Watch now".
final class RewardedAdReady extends RewardedAdState {
  const RewardedAdReady({
    required super.coinsBefore,
    required super.rewardCoins,
    required super.freeAdsLeft,
    required super.freeAdsPerDay,
  });
}

/// The mocked ad is "playing".
final class RewardedAdPlaying extends RewardedAdState {
  const RewardedAdPlaying({
    required super.coinsBefore,
    required super.rewardCoins,
    required super.freeAdsLeft,
    required super.freeAdsPerDay,
  });
}

/// The ad finished and the reward is ready to be credited.
final class RewardedAdSucceeded extends RewardedAdState {
  const RewardedAdSucceeded({
    required super.coinsBefore,
    required super.rewardCoins,
    required super.freeAdsLeft,
    required super.freeAdsPerDay,
  });
}

/// The mocked ad "failed to load" — the toast fallback, never a dead button.
final class RewardedAdFailed extends RewardedAdState {
  const RewardedAdFailed({
    required super.coinsBefore,
    required super.rewardCoins,
    required super.freeAdsLeft,
    required super.freeAdsPerDay,
  });
}
