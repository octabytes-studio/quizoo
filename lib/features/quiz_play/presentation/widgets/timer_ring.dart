import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/arena_colors.dart';

/// `.timer` — the circular countdown.
///
/// The Cubit emits only on whole-second changes, so the sweep is interpolated
/// here: a [TweenAnimationBuilder] walks linearly between the last second and
/// this one over exactly one second, which is [AppMotion.tick]. That keeps
/// per-frame work in the one widget that needs it, painted by a
/// [CustomPainter] behind a [RepaintBoundary] — §25's own performance rule for
/// this screen.
class TimerRing extends StatelessWidget {
  const TimerRing({
    required this.secondsRemaining,
    required this.secondsTotal,
    required this.color,
    super.key,
    this.diameter = defaultDiameter,
    this.isPulsing = false,
  });

  final int secondsRemaining;
  final int secondsTotal;

  /// Mango while there is time, mint or raspberry once a verdict lands, and
  /// raspberry through the last five seconds.
  final Color color;

  /// `.timer` — 64, dropping to [imageDiameter] on an image question so the
  /// media plate has room.
  static const double defaultDiameter = 64;
  static const double imageDiameter = 52;

  final double diameter;

  /// S-14: the ring pulses to 1.06 once a second through the danger window.
  final bool isPulsing;

  /// `stroke-width: 7` at 64, scaled with the ring.
  double get _strokeWidth => diameter * 7 / defaultDiameter;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    final progress = secondsTotal == 0
        ? 0.0
        : (secondsRemaining / secondsTotal).clamp(0.0, 1.0);

    final ring = SizedBox.square(
      dimension: diameter.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: AppMotion.durationOf(context, AppMotion.tick),
              curve: AppMotion.tickCurve,
              builder: (context, value, _) => CustomPaint(
                size: Size.square(diameter.w),
                painter: _TimerRingPainter(
                  progress: value,
                  color: color,
                  trackColor: Colors.white.withValues(alpha: 0.16),
                  strokeWidth: _strokeWidth.w,
                ),
              ),
            ),
          ),
          Text(
            AppFormat.plain(secondsRemaining, localeName),
            style: textTheme.displaySmall!.copyWith(
              fontSize: (diameter * 23 / defaultDiameter).sp,
              color: isPulsing ? const Color(0xFFFF6E92) : arena.onArena,
            ),
          ),
        ],
      ),
    );

    if (!isPulsing) return ring;

    // One pulse per second, and nothing at all under reduced motion.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: AppMotion.dangerPulseScale),
      duration: AppMotion.durationOf(context, AppMotion.tick),
      curve: Curves.easeOut,
      // Keying on the second restarts the tween on every tick, which is what
      // makes it a repeating pulse rather than one slow grow.
      key: ValueKey(secondsRemaining),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: ring,
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // `transform: rotate(-90deg)` — the sweep starts at twelve o'clock.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
