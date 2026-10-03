import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_membership_line.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_mark.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The Quizoo Pro row at the top of the player's own profile (plan 023).
///
/// A member: "Quizoo Pro · Active" over the renewal date — "Lifetime member"
/// when the plan never expires. Free: a gold "Go Pro" row into the paywall.
/// Both use [ListRowTile] so the row keeps the list's rhythm rather than
/// inventing its own.
///
/// The leading plate carries the [AppMark], not a crown glyph: this row
/// names a store membership, and the crown is no longer part of the Pro
/// language — the gold verified tick after a name is the only Pro marker.
class MembershipRow extends StatelessWidget {
  const MembershipRow({required this.isPro, super.key});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizoo = context.quizoo;
    // The renewal date comes from this device's own membership detail
    // (`SubscriptionPro.membership`), not from `profiles` — the server has
    // no store dates, only the entitlement flag.
    final membership = context.select<SubscriptionCubit, ProMembership?>(
      (cubit) => switch (cubit.state) {
        SubscriptionPro(:final membership) => membership,
        _ => null,
      },
    );

    return ListRowTile(
      title: isPro ? l10n.proMembershipActive : l10n.proGoPro,
      subtitle: isPro
          ? proMembershipLineLabel(
              context,
              line: membershipLineOf(membership),
              expiresAt: membership?.expiresAt,
            )
          : l10n.proGoProCardBody,
      leadingChild: AppMark(size: 26.w),
      leadingPlateColor: AppColors.proGoldFrom,
      accentColor: quizoo.gold,
      onTap: () => context.push(
        isPro ? AppRoutes.proMembership : AppRoutes.paywall,
        extra: isPro ? null : PaywallSource.profile,
      ),
    );
  }
}
