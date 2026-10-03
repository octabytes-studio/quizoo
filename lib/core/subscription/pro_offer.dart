import 'package:freezed_annotation/freezed_annotation.dart';

import 'pro_plan.dart';

part 'pro_offer.freezed.dart';

/// One purchasable Quizoo Pro plan, priced from the store (plan 023,
/// Assumption 6).
///
/// Nothing about price is hardcoded in the UI: [priceLabel] is the store's
/// own formatted string, and [trialDays] only exists when the store product
/// actually carries a free introductory offer. The paywall renders whatever
/// these say.
@freezed
abstract class ProOffer with _$ProOffer {
  const factory ProOffer({
    required ProPlan plan,

    /// RevenueCat package identifier (`$rc_monthly` …) — the purchase key.
    required String packageId,

    /// Store-formatted price, e.g. `$4.99` / `4,99 US$`.
    required String priceLabel,
    required double price,
    required String currencyCode,

    /// Non-null only when the product carries a free trial, in whole days.
    int? trialDays,

    /// Yearly only: the monthly-equivalent price (`$Y per month`), so the
    /// plan card can show the saving. Null when the currency or the monthly
    /// price is not known.
    String? perMonthLabel,
  }) = _ProOffer;
}
