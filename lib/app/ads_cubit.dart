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
/// pacing clock.
///
/// It is also the single switch a "Remove ads" purchase flips (plan 023):
/// [setAdFree] turns every placement and every interstitial off in one
/// place, so no feature has to know about the subscription. The rewarded
/// heart ad is not gated here — it is opt-in and Pro explicitly promises to
/// keep it (design bible S-36) — but it reports in through
/// [noteFullScreenAdShown] so the two never land back to back.
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

  bool _isAdFree = false;

  /// Ad-free (plan 023). True while the player owns Quizoo Pro.
  bool get isAdFree => _isAdFree;

  /// Flips the whole ad layer on or off. Call before [initialize] at start
  /// up, and whenever the subscription state changes; turning ad-free *off*
  /// preloads an interstitial so the next break is not a blank.
  void setAdFree(bool value) {
    if (_isAdFree == value) return;
    _isAdFree = value;

    final current = state;
    if (current is AdsReady) {
      emit(
        AdsReady(
          config: current.config,
          privacyOptionsRequired: current.privacyOptionsRequired,
          isAdFree: value,
        ),
      );
      if (!value) unawaited(_interstitial.preload());
    }
  }

  /// Gathers consent, then starts the SDK and preloads the first
  /// interstitial. Never throws: anything going wrong means no ads.
  ///
  /// An ad-free player still ends up in [AdsReady] (so the state machine
  /// stays honest about consent and config) but no interstitial is fetched —
  /// they would never be shown.
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
      if (!_isAdFree) unawaited(_interstitial.preload());
      emit(
        AdsReady(
          config: config,
          privacyOptionsRequired: privacyOptionsRequired,
          isAdFree: _isAdFree,
        ),
      );
    } catch (_) {
      _disable();
    }
  }

  void _disable() {
    if (!isClosed) emit(const AdsDisabled());
  }

  /// True only once ads are ready, the player is not ad-free, and
  /// [placement] is not on the kill list.
  bool isPlacementEnabled(AdPlacement placement) => switch (state) {
    AdsReady(:final config, :final isAdFree) =>
      !isAdFree && !config.disabledPlacements.contains(placement.id),
    AdsInitial() || AdsDisabled() => false,
  };

  /// Registers one break at [placement] and, if the pacing allows, shows an
  /// interstitial. Completes when the ad is dismissed — or immediately when
  /// nothing is shown, so a missing ad never delays navigation.
  ///
  /// Returns whether an interstitial was actually displayed, so
  /// `runAdBreak` (plan 023) can count them toward the one-time ad-free
  /// offer without asking this Cubit twice.
  ///
  /// [isCelebration] marks a run that just earned something (mastery, a
  /// badge, the save-progress offer): it never shows an ad, but still counts
  /// toward the cadence.
  Future<bool> showInterstitialIfDue(
    AdPlacement placement, {
    bool isCelebration = false,
  }) async {
    final current = state;
    if (current is! AdsReady || !isPlacementEnabled(placement)) return false;

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
    if (!isDue) return false;

    if (await _interstitial.show()) {
      _pacer.noteInterstitialShown();
      return true;
    }
    return false;
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
