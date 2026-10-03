import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The small "Advertisement" caption above an in-content ad, so an ad is
/// never mistaken for the app's own content.
///
/// Plan 023 adds a trailing "Remove ads" link, shown only when Pro is
/// actually available on this device. It keeps at least [AppSpacing.md]
/// between itself and the ad below (the accidental-click policy from plan
/// 022), and it is a text link rather than a button so it never competes
/// with the ad for a tap.
class AdLabel extends StatelessWidget {
  const AdLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(color: context.quizoo.tx3);

    final showUpsell = context.select<SubscriptionCubit, bool>((cubit) {
      final state = cubit.state;
      return state is SubscriptionFree && state.isAvailable;
    });

    return Padding(
      // The link must stay clear of the ad underneath it (plan 022's
      // accidental-click policy), so the label carries the minimum gap
      // itself — every host gets it without repeating the number.
      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
      child: Row(
        children: [
          Text(l10n.adLabel, style: labelStyle),
          const Spacer(),
          if (showUpsell)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.push(AppRoutes.paywall, extra: PaywallSource.adLabel),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs.w,
                  vertical: AppSpacing.xs.h,
                ),
                child: Text(
                  l10n.proRemoveAds,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: context.quizoo.g,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
