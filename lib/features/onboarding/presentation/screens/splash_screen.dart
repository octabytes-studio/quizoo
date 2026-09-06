import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/onboarding/presentation/widgets/owl_mark.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-01 — the launch route.
///
/// The bible's timing contract (§01) is the whole design of this screen:
/// **Splash → Home in ≤ 1.2 s**, and if bootstrap is still running at that
/// point we leave anyway and let Home render skeletons. So the 1200 ms cap is
/// a race, not a floor — [_bootstrap] finishing early cuts the wait short,
/// and finishing late does not extend it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.repository, super.key});

  /// Consulted for whether this is a genuine first launch.
  final OnboardingRepository repository;

  /// `linear-gradient(178deg,#7B4DFF,#4B22C4)`, edge to edge.
  static const String gradientFrom = '#7B4DFF';
  static const String gradientTo = '#4B22C4';

  /// The hard cap from §01. Never wait longer than this for anything.
  static const Duration maxHold = Duration(milliseconds: 1200);

  /// The mocked bootstrap this races against — warming the fixture data a
  /// real build would be reading out of local storage here.
  static const Duration bootstrapDuration = Duration(milliseconds: 700);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_leaveWhenReady());
  }

  Future<void> _leaveWhenReady() async {
    await Future.any([
      Future<void>.delayed(SplashScreen.bootstrapDuration),
      Future<void>.delayed(SplashScreen.maxHold),
    ]);
    if (!mounted) return;
    context.go(
      widget.repository.isFirstLaunch ? AppRoutes.onboarding : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    const onSplash = Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White status-bar icons over the grape wash.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.linear(AppGradients.washAngle, const [
              Color(0xFF7B4DFF),
              Color(0xFF4B22C4),
            ]),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OwlMark(size: 130.w)
                        .animate()
                        .scale(
                          duration: AppMotion.durationOf(
                            context,
                            AppMotion.pop,
                          ),
                          curve: AppMotion.curveOf(context, AppMotion.popCurve),
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                        )
                        .fadeIn(
                          duration: AppMotion.durationOf(
                            context,
                            AppMotion.press,
                          ),
                        ),
                    SizedBox(height: 14.h),
                    // The wordmark writes on after the owl has landed.
                    Text(
                          l10n.appTitle,
                          style: textTheme.displayMedium!.copyWith(
                            fontSize: 44.sp,
                            height: 1.08,
                            color: onSplash,
                          ),
                        )
                        .animate()
                        .fadeIn(
                          delay: AppMotion.durationOf(context, AppMotion.pop),
                          duration: AppMotion.durationOf(
                            context,
                            AppMotion.slide,
                          ),
                        )
                        .slideY(
                          begin: 0.25,
                          end: 0,
                          curve: AppMotion.curveOf(
                            context,
                            AppMotion.slideCurve,
                          ),
                        ),
                    Text(
                      l10n.splashTagline,
                      style: textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: onSplash.withValues(alpha: 0.8),
                      ),
                    ).animate().fadeIn(
                      delay: AppMotion.durationOf(context, AppMotion.slide),
                      duration: AppMotion.durationOf(context, AppMotion.slide),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 56.h,
                child: Text(
                  l10n.splashVersion('1.0.0'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: onSplash.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
