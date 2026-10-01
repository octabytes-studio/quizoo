/// A seam over Google's User Messaging Platform so `AdsCubit` stays pure Dart
/// and testable without a plugin channel (mirrors `RewardedAdService`).
abstract class AdConsentService {
  /// Updates consent info and shows Google's form if one is required.
  /// Returns whether ads may be requested. Never throws.
  Future<bool> gather();

  /// Whether Google requires the app to offer a way back into its privacy
  /// options form. Never throws.
  Future<bool> isPrivacyOptionsRequired();

  /// Re-opens Google's privacy options form. Never throws.
  Future<void> showPrivacyOptions();
}
