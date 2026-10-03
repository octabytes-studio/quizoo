/// Which Quizoo Pro plan a purchase or membership is (plan 023).
///
/// The three values map one-to-one onto RevenueCat's three packages —
/// `$rc_monthly`, `$rc_annual`, `$rc_lifetime` — and onto the store product
/// ids in the plan's "Data model / API changes" table.
enum ProPlan {
  /// `quizoo_pro_monthly` / `quizoo_pro:monthly`.
  monthly,

  /// `quizoo_pro_yearly` / `quizoo_pro:yearly`.
  yearly,

  /// `quizoo_pro_lifetime` — a non-consumable on the App Store, a one-time
  /// product on Play.
  lifetime,
}

/// The one place a store product id becomes a [ProPlan]. Covers the App
/// Store ids, the Play `quizoo_pro:monthly` form and the Test Store ids —
/// the same rule `_shared/revenuecat.ts` applies server-side.
ProPlan? planFromProductId(String? productId) {
  if (productId == null) return null;
  if (productId.contains('lifetime')) return ProPlan.lifetime;
  if (productId.contains('yearly') || productId.contains('annual')) {
    return ProPlan.yearly;
  }
  if (productId.contains('monthly')) return ProPlan.monthly;
  return null;
}
