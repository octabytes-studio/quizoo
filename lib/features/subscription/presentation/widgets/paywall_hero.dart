import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/app_mark.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The app mark, title and tagline at the top of the paywall and the
/// membership screen (plan 023). The mark is an [AppMark], undecorated.
///
/// A gentle pop-in, respecting [AppMotion.durationOf] so a reduced-motion
/// player gets no animation at all.
class PaywallHero extends StatelessWidget {
  const PaywallHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          [
                // The white mark: the Pro wash is dark grape-to-night in
                // both themes, so the colour variant would sit at too little
                // contrast. Undecorated — the gold verified tick after a
                // name is the app's only Pro marker.
                AppMark(size: 88.w, variant: AppMarkVariant.white),
                SizedBox(height: AppSpacing.lg.h),
                Text(
                  l10n.proPaywallTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  l10n.proPaywallTagline,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ]
              .animate(interval: 80.ms)
              .fade(duration: AppMotion.durationOf(context, AppMotion.pop))
              .scale(
                begin: const Offset(0.94, 0.94),
                curve: AppMotion.curveOf(context, AppMotion.popCurve),
              ),
    );
  }
}

/// The translucent surface the benefit rows sit on.
class ProGlassCard extends StatelessWidget {
  const ProGlassCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.proCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.proCardBorder),
      ),
      child: child,
    );
  }
}
