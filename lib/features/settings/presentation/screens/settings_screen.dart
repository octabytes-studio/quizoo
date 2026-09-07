import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/connectivity_cubit.dart';
import 'package:quizoo/app/theme_cubit.dart';
import 'package:quizoo/core/models/app_theme_mode.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/segmented_tabs.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:quizoo/features/settings/presentation/widgets/settings_row.dart';
import 'package:quizoo/features/settings/presentation/widgets/settings_toggle_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-42 — Settings.
///
/// Also hosts the debug-only "Simulate offline" toggle (plan 001's
/// Assumption 7), in its own labelled DEVELOPER section so a reviewer can
/// tell it apart from a real bible-specified row.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => SettingsCubit(SettingsRepository()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  static String _themeLabel(AppLocalizations l10n, AppThemeMode mode) =>
      switch (mode) {
        AppThemeMode.light => l10n.themeLight,
        AppThemeMode.dark => l10n.themeDark,
        AppThemeMode.system => l10n.themeAuto,
      };

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsCubit>().state.settings;
    final themeMode = context.watch<ThemeCubit>().state.mode;
    final isOffline = context.watch<ConnectivityCubit>().state.isOffline;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimpleTopBar(title: l10n.settingsTitle),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin.w,
                  vertical: AppSpacing.sm.h,
                ),
                children: [
                  _GroupLabel(l10n.settingsAppearance),
                  SizedBox(height: AppSpacing.sm.h),
                  SegmentedTabs(
                    labels: [
                      _themeLabel(l10n, AppThemeMode.light),
                      _themeLabel(l10n, AppThemeMode.dark),
                      _themeLabel(l10n, AppThemeMode.system),
                    ],
                    selectedIndex: AppThemeMode.values.indexOf(themeMode),
                    onChanged: (index) => context.read<ThemeCubit>().setMode(
                      AppThemeMode.values[index],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  _GroupLabel(l10n.settingsGame),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsRow(
                    title: l10n.settingsLanguage,
                    onTap: () => context.push(AppRoutes.languagePicker),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsToggleRow(
                    title: l10n.settingsSoundEffects,
                    value: settings.soundOn,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleSound(),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsToggleRow(
                    title: l10n.settingsMusic,
                    value: settings.musicOn,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleMusic(),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsToggleRow(
                    title: l10n.settingsHaptics,
                    value: settings.hapticsOn,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleHaptics(),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  _GroupLabel(l10n.settingsAccount),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsRow(
                    title: l10n.settingsNotifications,
                    onTap: () => context.push(AppRoutes.notificationSettings),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsRow(
                    title: l10n.settingsPrivacy,
                    onTap: () => context.push(AppRoutes.privacySettings),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsRow(
                    title: l10n.settingsDeleteAccount,
                    isDestructive: true,
                    onTap: () => context.push(AppRoutes.deleteAccount),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  _GroupLabel(l10n.settingsDeveloper),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsToggleRow(
                    title: l10n.settingsSimulateOffline,
                    value: isOffline,
                    onChanged: (_) =>
                        context.read<ConnectivityCubit>().toggle(),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsRow(
                    title: l10n.settingsPreviewForceUpdate,
                    onTap: () => context.push(AppRoutes.forceUpdate),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  SettingsRow(
                    title: l10n.settingsPreviewNotificationPermission,
                    onTap: () => context.push(AppRoutes.notificationPermission),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  Center(
                    child: Text(
                      l10n.settingsVersion,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelSmall);
  }
}
