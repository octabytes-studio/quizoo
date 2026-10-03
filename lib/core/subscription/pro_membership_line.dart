import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Which date line a membership carries (plan 023).
///
/// Pure: no `BuildContext`, no l10n — the caller maps each value to its own
/// localized string through [proMembershipLineLabel], so the wording lives
/// in `app_en.arb`/`app_ur.arb` and the *decision* lives here, where it can
/// be unit-tested without a widget.
///
/// In `core/`, not in the subscription feature, because the You screen's
/// membership row renders the same line — and no feature imports
/// `features/subscription/` (plan 023, Assumption 5).
enum ProMembershipLine {
  /// A subscription that will charge again.
  renewsOn,

  /// A subscription the player cancelled; access until the expiry.
  endsOn,

  /// A one-time lifetime purchase.
  lifetime,

  /// A free trial that has not been charged yet.
  inTrial,

  /// The store reported nothing to say. Still a member — just no date.
  none,
}

/// Decides [ProMembershipLine] from a membership. Null membership (only the
/// local cache is known) is [ProMembershipLine.none].
ProMembershipLine membershipLineOf(ProMembership? membership) {
  if (membership == null) return ProMembershipLine.none;
  if (membership.plan == ProPlan.lifetime) return ProMembershipLine.lifetime;
  if (membership.isTrial) return ProMembershipLine.inTrial;
  if (membership.expiresAt == null) return ProMembershipLine.none;
  return membership.willRenew
      ? ProMembershipLine.renewsOn
      : ProMembershipLine.endsOn;
}

/// The localized label for [line], with [expiresAt] formatted for the
/// device's locale where the line names a date.
///
/// Shared by the Pro Membership screen and the You screen's membership row,
/// so the two can never drift. A null [expiresAt] on a date line falls back
/// to an empty date rather than a crash — the store occasionally reports an
/// entitlement with no expiry recorded.
String proMembershipLineLabel(
  BuildContext context, {
  required ProMembershipLine line,
  DateTime? expiresAt,
}) {
  final l10n = AppLocalizations.of(context);
  final formatted = expiresAt == null
      ? ''
      : DateFormat.yMMMd(
          Localizations.localeOf(context).toString(),
        ).format(expiresAt);
  return switch (line) {
    ProMembershipLine.lifetime => l10n.proMembershipLifetime,
    ProMembershipLine.renewsOn => l10n.proMembershipRenewsOn(formatted),
    ProMembershipLine.endsOn => l10n.proMembershipEndsOn(formatted),
    ProMembershipLine.inTrial => l10n.proMembershipInTrial(formatted),
    ProMembershipLine.none => l10n.proMembershipNoDate,
  };
}
