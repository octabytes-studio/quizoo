import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/features/settings/presentation/widgets/settings_row.dart';
import 'package:quizoo/features/settings/presentation/widgets/settings_toggle_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Privacy & leaderboard visibility.
///
/// The bible lists this as a settings row with a "›" affordance but never
/// mockups its own destination (plan 004, Assumption 4) — this stub is a
/// reasonable reading of the row's own label: two on/off toggles, held as
/// local, ephemeral UI state (CLAUDE.md §3) since there is no backend for
/// either preference to reach.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showOnLeaderboards = true;
  bool _showActivityToFriends = true;

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
                children: [
                  SettingsToggleRow(
                    title: l10n.privacyShowOnLeaderboards,
                    value: _showOnLeaderboards,
                    onChanged: (value) =>
                        setState(() => _showOnLeaderboards = value),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsToggleRow(
                    title: l10n.privacyShowActivityToFriends,
                    value: _showActivityToFriends,
                    onChanged: (value) =>
                        setState(() => _showActivityToFriends = value),
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
