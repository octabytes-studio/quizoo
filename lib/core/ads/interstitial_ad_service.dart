/// A seam over the concrete AdMob interstitial so `AdsCubit` stays pure Dart
/// and testable without a plugin channel (mirrors `RewardedAdService`).
abstract class InterstitialAdService {
  /// Loads one interstitial to have ready for the next break. A no-op while
  /// a load is in flight or a fresh ad is already held. Never throws.
  Future<void> preload();

  /// Whether an ad is loaded and still fresh enough to show.
  bool get isReady;

  /// Shows the loaded ad and completes once it is dismissed. Returns false if
  /// there was nothing to show or it failed to show. Never throws.
  Future<bool> show();

  /// Releases any native resources this service opened.
  Future<void> dispose();
}
