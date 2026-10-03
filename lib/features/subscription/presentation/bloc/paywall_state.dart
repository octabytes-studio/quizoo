part of 'paywall_cubit.dart';

/// One-shot notices the paywall surfaces as a snackbar (plan 023).
enum PaywallNotice {
  /// The store rejected the purchase — show a retry.
  failed,

  /// The store has taken the money request but not finished (slow payment,
  /// Ask to Buy). Not an error: explain and wait.
  pending,

  /// "Restore purchases" found nothing to restore.
  nothingToRestore,
}

/// The paywall's own state machine (CLAUDE.md §3).
sealed class PaywallState extends Equatable {
  const PaywallState();

  @override
  List<Object?> get props => [];
}

/// Loading the store's offers.
final class PaywallLoading extends PaywallState {
  const PaywallLoading();
}

/// Offers are in hand and the player can act on them.
final class PaywallReady extends PaywallState {
  const PaywallReady({
    required this.offers,
    required this.selected,
    this.isBusy = false,
    this.notice,
  });

  /// Every purchasable plan the store reported, priced from the store.
  final List<ProOffer> offers;

  /// The plan the CTA would buy. Preselected to yearly when available.
  final ProPlan selected;

  /// A purchase or restore is in flight — every control is inert.
  final bool isBusy;

  /// One-shot; the screen shows it and calls `clearNotice()`.
  final PaywallNotice? notice;

  /// The offer currently selected.
  ProOffer? get selectedOffer {
    for (final offer in offers) {
      if (offer.plan == selected) return offer;
    }
    return null;
  }

  /// How much cheaper yearly is than twelve monthlies, rounded to a whole
  /// percent — the "Save N%" pill. Null unless both prices are known and in
  /// the same currency (plan 023, Assumption 6).
  int? get yearlySavingsPercent {
    ProOffer? monthly;
    ProOffer? yearly;
    for (final offer in offers) {
      if (offer.plan == ProPlan.monthly) monthly = offer;
      if (offer.plan == ProPlan.yearly) yearly = offer;
    }
    if (monthly == null || yearly == null) return null;
    if (monthly.currencyCode != yearly.currencyCode) return null;
    final full = monthly.price * 12;
    if (full <= 0 || yearly.price >= full) return null;
    return ((1 - yearly.price / full) * 100).round();
  }

  @override
  List<Object?> get props => [offers, selected, isBusy, notice];
}

/// The store's offers could not be loaded at all — offline, or no store.
final class PaywallUnavailable extends PaywallState {
  const PaywallUnavailable(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error];
}

/// The player now owns Pro. The screen navigates away.
final class PaywallPurchased extends PaywallState {
  const PaywallPurchased({required this.wasRestore});

  /// True when the gain came from "Restore purchases" rather than a new
  /// purchase, so the welcome screen can word itself accordingly.
  final bool wasRestore;

  @override
  List<Object?> get props => [wasRestore];
}
