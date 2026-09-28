import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_clock_label.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The small "◔ 4:12" countdown on a challenge card and the composer bar
/// (plan 017, S-38).
///
/// The ring colour follows the time left: mint, lemon under two minutes,
/// raspberry under thirty seconds. The whole widget is excluded from
/// semantics — the card's own label already says how long is left.
class ChallengeCountdownRing extends StatelessWidget {
  const ChallengeCountdownRing({
    required this.remaining,
    required this.total,
    required this.trackColor,
    required this.labelStyle,
    super.key,
    this.diameter = defaultDiameter,
    this.showLabel = true,
  });

  final Duration remaining;
  final Duration total;

  /// The unfilled part of the ring — dark on a white plate, light on the
  /// arena.
  final Color trackColor;

  /// The "4:12" beside the ring.
  final TextStyle labelStyle;

  final double diameter;
  final bool showLabel;

  static const double defaultDiameter = 18;

  /// Under this, the ring turns lemon.
  static const Duration warnBelow = Duration(minutes: 2);

  /// Under this, the ring turns raspberry.
  static const Duration dangerBelow = Duration(seconds: 30);

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final localeName = AppLocalizations.of(context).localeName;

    final color = remaining < dangerBelow
        ? arena.countdownDanger
        : remaining < warnBelow
        ? arena.countdownWarn
        : arena.countdownSafe;
    final progress = total <= Duration.zero
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: AppMotion.durationOf(context, AppMotion.tick),
              curve: AppMotion.tickCurve,
              builder: (context, value, _) => CustomPaint(
                size: Size.square(diameter.w),
                painter: _CountdownRingPainter(
                  progress: value,
                  color: color,
                  trackColor: trackColor,
                  strokeWidth: (diameter / 6).w,
                ),
              ),
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: AppSpacing.xs.w),
            Text(remaining.clockLabel(localeName), style: labelStyle),
          ],
        ],
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
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

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );
    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // The sweep starts at twelve o'clock and empties anticlockwise.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
