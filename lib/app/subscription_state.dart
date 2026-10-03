part of 'subscription_cubit.dart';

/// Whether this player is a Quizoo Pro member (plan 023).
///
/// App-root like [AdsCubit] because eight features read it and all of them
/// must agree on one answer: the ad layer, the level map, play, results, the
/// avatar picker, the identity surfaces, the Home promo card and the
/// out-of-lives dialog.
///
/// `isPro` is **this device's own view**, fed by the purchase SDK — instant
/// after a purchase and available offline from its cache. Anything another
/// player sees, or anything the server must enforce, reads `profiles.is_pro`
/// instead (see the plan's "How Pro status flows").
sealed class SubscriptionState extends Equatable {
  const SubscriptionState();

  /// Whether the player currently has Pro on this device.
  bool get isPro;

  /// The per-level numbers to play under — never a bare `isPro` bool, so the
  /// paywall's promises and the play surface cannot drift.
  ProPerks get perks => ProPerks.of(isPro: isPro);

  @override
  List<Object?> get props => [isPro];
}

/// Not a member.
final class SubscriptionFree extends SubscriptionState {
  const SubscriptionFree({
    required this.isAvailable,
    required this.showHomePromo,
  });

  /// False when Pro cannot be bought here at all — an unsupported platform,
  /// or `pro_enabled = false` in Remote Config. Every entry point hides.
  final bool isAvailable;

  /// The Home promo card may show right now (not dismissed within the last
  /// seven days).
  final bool showHomePromo;

  @override
  bool get isPro => false;

  @override
  List<Object?> get props => [isAvailable, showHomePromo];
}

/// A member on this device.
final class SubscriptionPro extends SubscriptionState {
  const SubscriptionPro({this.membership});

  /// Null while only the cached flag is known — the SDK has not reported a
  /// membership detail yet. The membership screen must cope.
  final ProMembership? membership;

  @override
  bool get isPro => true;

  @override
  List<Object?> get props => [membership];
}
