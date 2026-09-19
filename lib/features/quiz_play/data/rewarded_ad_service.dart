/// A small seam over the concrete AdMob implementation so `HeartAdCubit`
/// stays pure Dart and testable without a plugin channel or a real ad
/// network call — a test supplies a completer-backed fake that resolves on
/// its own schedule (CLAUDE.md §11, mirroring `TtsService`'s own seam).
abstract class RewardedAdService {
  /// Loads a rewarded ad. Returns true once it's ready to [show], false if
  /// it failed to load — never throws.
  Future<bool> load();

  /// Shows the ad already loaded by [load]. Returns true iff the user
  /// watched to completion and earned the reward — never throws.
  Future<bool> show();

  /// Releases any native resources this service opened.
  Future<void> dispose();
}
