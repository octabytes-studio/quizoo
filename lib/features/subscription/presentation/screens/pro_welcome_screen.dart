import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/widgets/app_mark.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Shown once, right after a purchase or a restore that found Pro (plan 023).
///
/// The player's own avatar wearing the crown, "You're Pro!", three chips of
/// what just changed, and one button back to whatever opened the paywall. A
/// guest also gets "Save Pro to your account", because a guest purchase is
/// attached to a device identity until they sign in — see the plan's
/// "Identity" section.
class ProWelcomeScreen extends StatelessWidget {
  const ProWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // The player's own avatar when they have one; the app mark otherwise.
    // Never an emoji placeholder — the owl glyph used to stand in here for a
    // guest with no avatar, which is not the brand.
    final avatarEmoji = context.select<SessionCubit, String?>(
      (cubit) => cubit.state.user?.avatarEmoji,
    );
    final isGuest = context.select<SessionCubit, bool>(
      (cubit) => cubit.state.user == null,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.linear(AppGradients.washAngle, [
            AppColors.proWashTop,
            AppColors.proWashBottom,
          ]),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Column(
              children: [
                const Spacer(),
                if (avatarEmoji == null)
                  AppMark(size: 96.w, variant: AppMarkVariant.white)
                else
                  Text(
                    avatarEmoji,
                    style: TextStyle(fontSize: 80.sp, height: 1),
                  ),
                SizedBox(height: AppSpacing.lg.h),
                Text(
                  l10n.proWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm.w,
                  runSpacing: AppSpacing.sm.h,
                  children: [
                    _Chip(label: l10n.proWelcomeChipAdsOff),
                    _Chip(label: l10n.proWelcomeChipAllLevels),
                    _Chip(label: l10n.proWelcomeChipBadge),
                  ],
                ),
                const Spacer(),
                ChunkyButton.gold(
                  label: l10n.proStartPlaying,
                  onPressed: () => context.pop(),
                ),
                if (isGuest) ...[
                  SizedBox(height: AppSpacing.sm.h),
                  ChunkyButton.line(
                    label: l10n.proSaveToAccount,
                    onPressed: () => context.push(AppRoutes.saveProgress),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.proCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.proCardBorder),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
