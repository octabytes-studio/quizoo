import 'package:flutter/material.dart';

/// The five motion tokens from §05, plus the reduced-motion escape hatch the
/// bible requires ("screen-shake on wrong answer is explicitly disabled under
/// reduce-motion").
///
/// Read a duration through [durationOf] rather than the raw constant whenever
/// the animation is decorative — it collapses to [Duration.zero] when the
/// platform asks for reduced motion, which makes every animated widget honour
/// the setting without each one re-implementing the check.
abstract final class AppMotion {
  /// Button / option depress — translateY 4px, shadow to 0.
  static const Duration press = Duration(milliseconds: 90);
  static const Curve pressCurve = Curves.easeOut;

  /// Stars landing, badge unlock, mascot entrance, coin burst.
  static const Duration pop = Duration(milliseconds: 340);

  /// `elasticOut(0.9)` — the bible's period, not Flutter's 0.4 default.
  static const Curve popCurve = ElasticOutCurve(0.9);

  /// Question card exits left / next enters right.
  static const Duration slide = Duration(milliseconds: 260);
  static const Curve slideCurve = Curves.easeOutCubic;

  /// Bottom sheets.
  static const Duration sheet = Duration(milliseconds: 300);
  static const Curve sheetCurve = Curves.easeOutQuint;

  /// The scrim fades faster than the sheet travels.
  static const Duration scrim = Duration(milliseconds: 200);

  /// Score roll-up, XP bar fill, coin counter increment.
  static const Duration count = Duration(milliseconds: 900);
  static const Curve countCurve = Curves.easeOutExpo;

  /// Timer ring sweep — one second per revolution step, linear.
  static const Duration tick = Duration(milliseconds: 1000);
  static const Curve tickCurve = Curves.linear;

  /// The last-5s pulse scales the ring to 1.06 once per second.
  static const double dangerPulseScale = 1.06;

  /// Skeleton shimmer sweep.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// A skeleton only appears once a wait has lasted this long — anything
  /// faster just flashes (§06).
  static const Duration skeletonDelay = Duration(milliseconds: 300);

  /// Snackbar auto-dismiss, and the longer window used when it carries an
  /// action.
  static const Duration snackbar = Duration(milliseconds: 3200);
  static const Duration snackbarWithAction = Duration(seconds: 5);

  /// True when the platform (or a widget test) has asked for reduced motion.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or nothing at all under reduced motion.
  static Duration durationOf(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;

  /// [curve], or a linear ramp under reduced motion — an elastic overshoot
  /// still reads as motion even across a zero-length duration in some
  /// implicit animations.
  static Curve curveOf(BuildContext context, Curve curve) =>
      reduceMotion(context) ? Curves.linear : curve;
}
