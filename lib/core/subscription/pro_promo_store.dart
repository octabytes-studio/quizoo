import 'package:shared_preferences/shared_preferences.dart';

/// Promo dismissals and counters for the Quizoo Pro upsell (plan 023).
///
/// Kept in `core/` beside the rest of the entitlement layer because both the
/// Home promo card and the post-interstitial sheet read it. Every key is
/// prefixed `subscription.` so a `SharedPreferences` dump is self-describing.
class ProPromoStore {
  ProPromoStore(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _homePromoDismissedAt = 'subscription.homePromoDismissedAt';
  static const _interstitialsSeen = 'subscription.interstitialsSeen';
  static const _adFreeOfferShown = 'subscription.adFreeOfferShown';

  /// Long enough that a player who dismissed the card is not nagged weekly,
  /// short enough that a change of mind is possible.
  static const dismissalWindow = Duration(days: 7);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  /// The Home promo card may show: it has never been dismissed, or the
  /// dismissal is older than [dismissalWindow].
  bool get shouldShowHomeCard {
    final dismissedAt = _prefs.getString(_homePromoDismissedAt);
    if (dismissedAt == null) return true;
    final dismissed = DateTime.tryParse(dismissedAt);
    if (dismissed == null) return true;
    return _clock().difference(dismissed) >= dismissalWindow;
  }

  void dismissHomeCard() =>
      _prefs.setString(_homePromoDismissedAt, _clock().toIso8601String());

  /// How many interstitials this device has actually shown (plan 023, the
  /// "one sheet after the third interstitial" entry point).
  int get interstitialsSeen => _prefs.getInt(_interstitialsSeen) ?? 0;

  void noteInterstitialSeen() =>
      _prefs.setInt(_interstitialsSeen, interstitialsSeen + 1);

  /// The post-interstitial ad-free offer has already been shown once ever.
  bool get adFreeOfferShown => _prefs.getBool(_adFreeOfferShown) ?? false;

  void markAdFreeOfferShown() => _prefs.setBool(_adFreeOfferShown, true);
}
