part of 'heart_ad_cubit.dart';

/// S-19's "watch ad" button states (CLAUDE.md §3).
sealed class HeartAdState extends Equatable {
  const HeartAdState();

  @override
  List<Object?> get props => const [];
}

/// Idle, waiting for the player to tap "Watch ad" — the initial state, and
/// where nothing has been loaded yet.
final class HeartAdReady extends HeartAdState {
  const HeartAdReady();
}

/// The ad is loading, triggered by the player's tap — the button is
/// disabled and reads "Loading ad…".
final class HeartAdLoading extends HeartAdState {
  const HeartAdLoading();
}

/// The ad loaded and is now playing full-screen.
final class HeartAdPlaying extends HeartAdState {
  const HeartAdPlaying();
}

/// The ad finished and the player earned the reward.
final class HeartAdSucceeded extends HeartAdState {
  const HeartAdSucceeded();
}

/// The ad failed to load or to show — the "never a dead button" state.
/// The button re-enables here exactly as in [HeartAdReady]; tapping "Watch
/// ad" again calls [HeartAdCubit.watch] to retry from scratch.
final class HeartAdFailed extends HeartAdState {
  const HeartAdFailed();
}
