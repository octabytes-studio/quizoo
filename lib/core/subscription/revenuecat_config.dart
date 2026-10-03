import 'package:flutter/foundation.dart';

/// The only file in the app that may contain a RevenueCat key (plan 023,
/// Assumption 7 — the same rule the ad-unit ids follow in
/// `core/ads/ad_unit_ids.dart`).
///
/// These are **public** SDK keys by design: they ship inside the app bundle
/// and identify the app to RevenueCat, not grant access to anything secret.
/// The secret REST key and the webhook bearer secret live only in Supabase
/// Edge Function secrets.
abstract final class RevenueCatConfig {
  /// RevenueCat's Test Store app (`app4ae025b9bd`). Debug builds talk to
  /// this so the paywall is exercisable with no store setup at all.
  static const String testStoreApiKey = 'test_LsapuPuPkRpXMBtNCTLUhvZfKfH';

  /// RevenueCat's App Store app (`app6d4e7125fb`).
  static const String appleApiKey = 'appl_AEjqKZSVFUBYquiHBRvYzVdWMaA';

  /// RevenueCat's Play Store app (`app632311ce98`).
  static const String googleApiKey = 'goog_ivBIZLyBjLXONicsZaJgCFrkAtL';

  /// The one entitlement every plan unlocks.
  static const String entitlementId = 'quizoo_pro';

  /// Auto-renewing subscriptions require a Terms of Use (EULA) link on the
  /// paywall in both stores. **Placeholder** — see the owner checklist in
  /// plan 023 before release.
  static const String termsUrl = 'https://example.com/terms';

  /// Required alongside [termsUrl]. **Placeholder** — same owner checklist.
  static const String privacyUrl = 'https://example.com/privacy';

  /// Which key this platform should use.
  ///
  /// Returns `null` when the platform has no store to buy from (web,
  /// desktop) — the caller then leaves Pro unavailable rather than calling
  /// into a plugin that cannot work.
  ///
  /// Debug builds default to the Test Store so development needs no store
  /// configuration. `--dart-define=RC_USE_REAL_STORE=true` opts a debug
  /// build into the real sandbox stores.
  ///
  /// Release builds **never** fall back to the Test Store key: an empty
  /// platform key must leave Pro unavailable (plan 023, Risks).
  static String? apiKeyFor(
    TargetPlatform platform, {
    required bool useRealStore,
  }) {
    final useReal = useRealStore || kReleaseMode;
    return switch (platform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS => useReal ? appleApiKey : testStoreApiKey,
      TargetPlatform.android => useReal ? googleApiKey : testStoreApiKey,
      _ => null,
    };
  }
}
