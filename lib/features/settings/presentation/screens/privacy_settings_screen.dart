import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/features/settings/presentation/widgets/settings_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Privacy & leaderboard visibility.
///
/// The bible lists this as a settings row with a "›" affordance but never
/// mockups its own destination (plan 004, Assumption 4). Plan 025 removed the
/// two fake toggles it used to hold ("show me on leaderboards", "show my
/// activity to friends"): neither had a backend, both looked real, and a
/// toggle that silently does nothing is worse than no toggle. What is real
/// stays: Google's ad-privacy choices where they apply (plan 022), and the
/// player-safety surface the app actually has — blocked players.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    // Google requires a way back into its privacy options form wherever that
    // form applies (plan 022) — and nowhere else, so the row is conditional.
    final showAdChoices = context.select<AdsCubit, bool>(
      (cubit) => switch (cubit.state) {
        AdsReady(:final privacyOptionsRequired) => privacyOptionsRequired,
        AdsInitial() || AdsDisabled() => false,
      },
    );

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimpleTopBar(title: l10n.privacyTitle),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsRow(
                    title: l10n.safetyBlockedPlayersTitle,
                    onTap: () => context.push(AppRoutes.blockedPlayers),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.xs.h,
                      left: AppSpacing.xs.w,
                    ),
                    child: Text(
                      l10n.safetyBlockedPlayersHelper,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  if (showAdChoices) ...[
                    SizedBox(height: AppSpacing.sm.h),
                    SettingsRow(
                      title: l10n.privacyAdChoices,
                      onTap: () =>
                          context.read<AdsCubit>().showPrivacyOptions(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
