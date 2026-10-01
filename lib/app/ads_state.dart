part of 'ads_cubit.dart';

/// [AdsCubit]'s states (CLAUDE.md §3).
sealed class AdsState extends Equatable {
  const AdsState();

  @override
  List<Object?> get props => const [];
}

/// Consent has not been gathered yet — no ad may be requested.
final class AdsInitial extends AdsState {
  const AdsInitial();
}

/// No interstitial, banner or native ad will be requested this session:
/// consent was not given, the platform has no ad SDK, the remote master
/// switch is off, or start-up failed.
final class AdsDisabled extends AdsState {
  const AdsDisabled();
}

/// Consent is in hand and the SDK is initialised.
final class AdsReady extends AdsState {
  const AdsReady({required this.config, required this.privacyOptionsRequired});

  final AdsConfig config;

  /// Whether Google requires an "Ad privacy choices" entry point.
  final bool privacyOptionsRequired;

  @override
  List<Object?> get props => [config, privacyOptionsRequired];
}
