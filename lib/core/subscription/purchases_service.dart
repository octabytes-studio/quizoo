import 'pro_membership.dart';
import 'pro_offer.dart';

/// What the purchase SDK reports about the current customer (plan 023).
class PurchasesSnapshot {
  const PurchasesSnapshot({required this.isPro, this.membership});

  /// Whether the `quizoo_pro` entitlement is active on this device right now.
  /// False while only the cache is known and the player is free.
  final bool isPro;

  /// Null while only the cached flag is known, or for a free player.
  final ProMembership? membership;

  static const PurchasesSnapshot free = PurchasesSnapshot(isPro: false);

  @override
  bool operator ==(Object other) =>
      other is PurchasesSnapshot &&
      other.isPro == isPro &&
      other.membership == membership;

  @override
  int get hashCode => Object.hash(isPro, membership);
}

/// How a purchase attempt ended (plan 023).
sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

/// The store completed the purchase — Pro is now active.
final class PurchasePurchased extends PurchaseOutcome {
  const PurchasePurchased();
}

/// The player backed out of the store sheet. Not an error: the paywall
/// returns silently.
final class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

/// The store has taken the request but not finished it (Play slow payment,
/// Ask to Buy). The SDK's update listener flips the state later.
final class PurchasePending extends PurchaseOutcome {
  const PurchasePending();
}

/// Anything else went wrong. [message] is for logs; screens show their own
/// copy.
final class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.message);

  final String message;
}

/// A seam over the purchase SDK (plan 023, the `core/ads` service-seam
/// pattern): abstract class plus one `purchases_flutter` implementation,
/// with hand-written fakes in tests.
///
/// All SDK types stay inside `revenuecat_purchases_service.dart`; nothing
/// above this file knows RevenueCat exists. No test may construct the real
/// implementation.
abstract class PurchasesService {
  /// Starts the SDK. [userId] is always the current Supabase `auth.uid()`.
  Future<void> configure({required String apiKey, required String userId});

  /// The uid changed (guest signed in to a vendor, or anyone signed out).
  /// Returns the new state. [carryPurchases] asks RevenueCat to move the
  /// store receipt onto the new id — done only on a sign-in.
  Future<PurchasesSnapshot> logIn(
    String userId, {
    required bool carryPurchases,
  });

  /// The state as the SDK currently has it, without a network round trip
  /// when its cache is warm.
  Future<PurchasesSnapshot> current();

  /// Emits every time the SDK learns something new about this customer —
  /// including a purchase made on another device, or one approved late.
  Stream<PurchasesSnapshot> get changes;

  /// The current offering's purchasable plans, priced from the store.
  Future<List<ProOffer>> offers();

  Future<PurchaseOutcome> purchase(ProOffer offer);

  /// Player-initiated "Restore purchases" — may raise the OS prompt.
  Future<PurchasesSnapshot> restore();

  /// Opens the store's own subscription-management page, where the player
  /// can cancel or change their plan. The app never cancels anything itself:
  /// both stores require the user to do it on their surface.
  ///
  /// RevenueCat's hybrid SDKs do not expose `showManageSubscriptions`, so
  /// this opens the SDK's `managementURL` and falls back to the store's
  /// account page when it has none (Test Store, sandbox, a cache-only read).
  /// Returns false when no page could be opened.
  Future<bool> openManagement();

  /// Silent re-attach of the store receipt; no OS prompt.
  Future<PurchasesSnapshot> syncPurchases();
}
