import 'package:freezed_annotation/freezed_annotation.dart';

import 'pro_plan.dart';

part 'pro_membership.freezed.dart';

/// What this device's Pro membership currently is (plan 023).
///
/// Distinct from [ProOffer], which is a thing you could *buy* — this is a
/// thing already owned. Fields the store does not report are null/false
/// rather than invented.
@freezed
abstract class ProMembership with _$ProMembership {
  const factory ProMembership({
    /// Null only while just the local cache is known.
    ProPlan? plan,

    /// Null for a lifetime purchase.
    DateTime? expiresAt,

    /// False for lifetime and for a subscription the player has cancelled.
    @Default(false) bool willRenew,

    /// The introductory free-trial window, if the store says so.
    @Default(false) bool isTrial,

    /// Billing recovery / grace period — RevenueCat
    /// `billing_issues_detected_at`.
    @Default(false) bool hasBillingIssue,

    /// The store's own "manage this subscription" page, when the SDK
    /// reported one. Hidden on the membership screen when null or when the
    /// plan is lifetime.
    String? managementUrl,
  }) = _ProMembership;
}
