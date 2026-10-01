import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/ads/ad_consent_service.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/ads_config_repository.dart';
import 'package:quizoo/core/ads/interstitial_ad_service.dart';
import 'package:quizoo/core/ads/interstitial_pacer.dart';

part 'ads_state.dart';

/// Whether — and how often — the app may show interstitial, banner and
/// native ads.
///
/// App-root like [ConnectivityCubit], for the same reason (CLAUDE.md §3):
/// every tab and seven features host an ad slot or an interstitial break, and
/// all of them must agree on one consent result, one remote config and one
/// pacing clock. It is also the single switch a future "Remove ads" purchase
/// would flip.
///
/// The rewarded heart ad is not gated here — it is opt-in and predates this
/// Cubit — but it reports in through [noteFullScreenAdShown] so the two never
/// land back to back.
class AdsCubit extends Cubit<AdsState> {
  AdsCubit({
    required this._consent,
    required this._config,
    required this._interstitial,
    required this._pacer,
    required this._initializeSdk,
    required this._isSupportedPlatform,
  }) : super(const AdsInitial());

  final AdConsentService _consent;
  final AdsConfigRepository _config;
  final InterstitialAdService _interstitial;
  final InterstitialPacer _pacer;
  final Future<void> Function() _initializeSdk;
  final bool _isSupportedPlatform;

  /// Gathers consent, then starts the SDK and preloads the first
  /// interstitial. Never throws: anything going wrong means no ads.
  Future<void> initialize() async {
    if (state is! AdsInitial) return;
    try {
      if (!_isSupportedPlatform) return _disable();
      final config = _config.read();
      if (!config.enabled) return _disable();
      if (!await _consent.gather()) return _disable();

      await _initializeSdk();
      final privacyOptionsRequired = await _consent.isPrivacyOptionsRequired();
      if (isClosed) return;
      unawaited(_interstitial.preload());
      emit(
        AdsReady(
          config: config,
          privacyOptionsRequired: privacyOptionsRequired,
        ),
      );
    } catch (_) {
      _disable();
    }
  }

  void _disable() {
    if (!isClosed) emit(const AdsDisabled());
  }

  /// True only once ads are ready and [placement] is not on the kill list.
  bool isPlacementEnabled(AdPlacement placement) => switch (state) {
    AdsReady(:final config) => !config.disabledPlacements.contains(
      placement.id,
    ),
    AdsInitial() || AdsDisabled() => false,
  };

  /// Registers one break at [placement] and, if the pacing allows, shows an
  /// interstitial. Completes when the ad is dismissed — or immediately when
  /// nothing is shown, so a missing ad never delays navigation.
  ///
  /// [isCelebration] marks a run that just earned something (mastery, a
  /// badge, the save-progress offer): it never shows an ad, but still counts
  /// toward the cadence.
  Future<void> showInterstitialIfDue(
    AdPlacement placement, {
    bool isCelebration = false,
  }) async {
    final current = state;
    if (current is! AdsReady || !isPlacementEnabled(placement)) return;

    final isAdReady = _interstitial.isReady;
    final isDue = _pacer.registerBreak(
      current.config,
      isCelebration: isCelebration,
      isAdReady: isAdReady,
    );
    if (!isAdReady) {
      // Missing or expired — fetch a fresh one for the next break.
      unawaited(_interstitial.preload());
    }
    if (!isDue) return;

    if (await _interstitial.show()) _pacer.noteInterstitialShown();
  }

  /// A full-screen ad owned by someone else (the rewarded heart ad) was
  /// shown, so the interstitial cooldown starts again.
  void noteFullScreenAdShown() => _pacer.noteFullScreenAdShown();

  /// Re-opens Google's privacy options form.
  Future<void> showPrivacyOptions() => _consent.showPrivacyOptions();

  @override
  Future<void> close() {
    unawaited(_interstitial.dispose());
    return super.close();
  }
}
