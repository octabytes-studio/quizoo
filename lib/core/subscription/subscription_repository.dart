import 'dart:async';

import 'package:quizoo/core/network/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pro_offer.dart';
import 'pro_status_api.dart';
import 'purchases_service.dart';

/// The seam between the purchase SDK and the app (plan 023).
///
/// Two responsibilities, deliberately split the way "How Pro status flows"
/// in the plan describes:
///
/// * **This device's own perks** come from [PurchasesService] — instant
///   after a purchase, and available offline from the SDK's cache.
/// * **Anything the server must know** goes through [ProStatusApi], fired
///   un-awaited after a purchase, a restore or a sign-in carry-over. The
///   RevenueCat webhook is the backstop, so a failure here is swallowed
///   rather than surfaced (Assumption 10).
///
/// The only thing that ever throws is an `ApiException`, per CLAUDE.md §9.
class SubscriptionRepository {
  SubscriptionRepository(this._purchases, this._proStatus, this._preferences);

  final PurchasesService _purchases;
  final ProStatusApi _proStatus;
  final SharedPreferences _preferences;

  static const _isProKey = 'subscription.isPro';

  /// The cached flag, readable synchronously at launch so a returning Pro
  /// player never sees an ad flash before the SDK warms up.
  bool get cachedIsPro => _preferences.getBool(_isProKey) ?? false;

  /// Points the SDK at this device's user and returns the state it reports.
  ///
  /// [apiKey] is passed in rather than stored on this class so the key stays
  /// a startup concern of `app.dart` (which decides Test Store vs. real
  /// store) and the repository keeps its three-argument shape. A null key
  /// means Pro is unavailable here — see [PurchasesService.configure].
  Future<PurchasesSnapshot> start(
    String userId, {
    required String apiKey,
  }) async {
    try {
      await _purchases.configure(apiKey: apiKey, userId: userId);
      final snapshot = await _purchases.current();
      _cache(snapshot.isPro);
      // Self-heal (plan 023): the server mirror is what *other* players see,
      // so a device that already knows it is Pro asks the server to re-check
      // on every launch. A purchase's sync can have failed (missing secret,
      // offline, a slow webhook) and nothing else ever retried it — without
      // this, `profiles.is_pro` stays false and every leaderboard and duel
      // badge is missing even though the player is a member.
      if (snapshot.isPro) _fireServerSync();
      return snapshot;
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// The uid changed. [carryPurchases] is true only for a sign-in, so the
  /// store receipt attaches to the account rather than staying with a device
  /// identity (plan 023, "Identity").
  Future<PurchasesSnapshot> switchUser(
    String userId, {
    required bool carryPurchases,
  }) async {
    try {
      final snapshot = await _purchases.logIn(
        userId,
        carryPurchases: carryPurchases,
      );
      _cache(snapshot.isPro);
      if (carryPurchases) _fireServerSync();
      return snapshot;
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Every time the SDK learns something new about this customer — a
  /// purchase on another device, or one approved late. Each snapshot also
  /// refreshes the [cachedIsPro] flag, so a cold start renders the right
  /// thing before any network call (plan 023).
  Stream<PurchasesSnapshot> get changes => _purchases.changes.map((snapshot) {
    _cache(snapshot.isPro);
    return snapshot;
  });

  /// A silent re-read of the SDK's view — no OS prompt, unlike [restore].
  Future<PurchasesSnapshot> current() async {
    try {
      final snapshot = await _purchases.current();
      _cache(snapshot.isPro);
      return snapshot;
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<List<ProOffer>> offers() async {
    try {
      return await _purchases.offers();
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Runs the store sheet. The returned outcome is the caller's to handle —
  /// a cancellation is not an error. A success writes the cache and asks the
  /// server to re-check.
  Future<PurchaseOutcome> purchase(ProOffer offer) async {
    final PurchaseOutcome outcome;
    try {
      outcome = await _purchases.purchase(offer);
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
    if (outcome is PurchasePurchased) {
      _cache(true);
      _fireServerSync();
    }
    return outcome;
  }

  /// Player-initiated "Restore purchases".
  Future<PurchasesSnapshot> restore() async {
    try {
      final snapshot = await _purchases.restore();
      _cache(snapshot.isPro);
      if (snapshot.isPro) _fireServerSync();
      return snapshot;
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Opens the store's subscription-management page (cancel or change plan).
  /// Returns false when no page could be opened.
  Future<bool> openManagement() async {
    try {
      return await _purchases.openManagement();
    } on Exception catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Records the device's own view of Pro, so the next cold start renders
  /// the right thing before any network call.
  void _cache(bool isPro) => unawaited(_preferences.setBool(_isProKey, isPro));

  /// Asks the server to re-check. Un-awaited and swallowed: the webhook is
  /// the backstop (plan 023, Assumption 10), and a player who just bought
  /// must not see an error because a mirror write was slow.
  void _fireServerSync() {
    try {
      unawaited(_proStatus.sync().then((_) {}, onError: (_) {}));
    } on Exception {
      // A fire-and-forget must never surface: the webhook is the backstop
      // (plan 023, Assumption 10), and an implementation that throws
      // synchronously is the same case as one that rejects.
    }
  }
}
