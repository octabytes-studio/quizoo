import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-50 — force update.
///
/// **Blocking**: no back gesture, no system-back, no dismiss — "used only for
/// a genuine protocol break" (bible). A soft update gets a dismissible Home
/// banner instead, which is not separately specified anywhere else in the
/// bible and so is not built here (plan 004, Research findings). Reached only
/// from a debug row in Settings — there is no real version-check service in
/// this mock phase.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.linear(AppGradients.washAngle, [
              quizoo.g,
              const Color(0xFF160E36),
            ]),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚀', style: AppTypography.glyph(64.sp)),
                  SizedBox(height: AppSpacing.lg.h),
                  Text(
                    l10n.forceUpdateTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium!.copyWith(
                      fontSize: 27.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    l10n.forceUpdateBody,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium!.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl.h),
                  ChunkyButton.gold(
                    label: l10n.forceUpdateCta,
                    onPressed: () => AppSnackbar.show(
                      context,
                      title: l10n.forceUpdateMock,
                      intent: SnackbarIntent.info,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
