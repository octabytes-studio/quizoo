import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The Topic Mastered screen's hero: a slow-rotating gold sunburst behind a
/// crowned medallion in the topic's own plate colour, with a "N / N LEVELS"
/// ribbon (plan 020).
class MasteryMedallion extends StatefulWidget {
  const MasteryMedallion({
    required this.emoji,
    required this.plateColor,
    required this.levelsCleared,
    required this.levelCount,
    required this.topicName,
    super.key,
  });

  final String emoji;
  final String plateColor;
  final int levelsCleared;
  final int levelCount;
  final String topicName;

  @override
  State<MasteryMedallion> createState() => _MasteryMedallionState();
}

class _MasteryMedallionState extends State<MasteryMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rayController;
  bool _firedHaptic = false;
  bool _startedRays = false;

  @override
  void initState() {
    super.initState();
    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    Future<void>.delayed(const Duration(milliseconds: 460), _fireHapticOnce);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `MediaQuery` (which `AppMotion.reduceMotion` reads) isn't safely
    // available to depend on until after `initState` completes, so the
    // reduced-motion check happens here instead.
    if (!_startedRays && !AppMotion.reduceMotion(context)) {
      _startedRays = true;
      _rayController.repeat();
    }
  }

  @override
  void dispose() {
    _rayController.dispose();
    super.dispose();
  }

  void _fireHapticOnce() {
    if (_firedHaptic || !mounted) return;
    _firedHaptic = true;
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final quizoo = context.quizoo;

    return Semantics(
      label: l10n.masteryTitle(widget.topicName),
      image: true,
      child: SizedBox(
        width: 220.w,
        height: 220.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: RotationTransition(
                turns: _rayController,
                child: CustomPaint(
                  size: Size(220.w, 220.w),
                  painter: _SunburstPainter(color: AppColors.masteryRay),
                ),
              ),
            ),
            Container(
              width: 150.w,
              height: 150.w,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [quizoo.gold, quizoo.goldShadow],
                ),
                boxShadow: [
                  BoxShadow(
                    color: quizoo.gold.withValues(alpha: 0.45),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.tileFromHex(
                    widget.plateColor,
                    widget.plateColor,
                  ),
                ),
                child: Center(
                  child: Text(widget.emoji, style: AppTypography.glyph(64.sp)),
                ),
              ),
            ).animate().scale(
              duration: AppMotion.durationOf(context, AppMotion.pop),
              curve: AppMotion.curveOf(context, AppMotion.popCurve),
              begin: const Offset(0.3, 0.3),
              end: const Offset(1, 1),
            ),
            Positioned(
              top: 6.h,
              child:
                  ExcludeSemantics(
                        child: Text('👑', style: AppTypography.glyph(44.sp)),
                      )
                      .animate(delay: const Duration(milliseconds: 400))
                      .fadeIn(
                        duration: AppMotion.durationOf(
                          context,
                          AppMotion.slide,
                        ),
                      )
                      .slideY(
                        begin: -0.4,
                        end: 0,
                        duration: AppMotion.durationOf(
                          context,
                          AppMotion.slide,
                        ),
                        curve: AppMotion.curveOf(context, Curves.easeOutBack),
                      ),
            ),
            Positioned(
              bottom: 0,
              child:
                  _RibbonPill(
                        label: l10n.masteryLevelsRibbon(
                          widget.levelsCleared,
                          widget.levelCount,
                        ),
                        textTheme: textTheme,
                      )
                      .animate(delay: const Duration(milliseconds: 560))
                      .scale(
                        alignment: Alignment.center,
                        duration: AppMotion.durationOf(
                          context,
                          AppMotion.slide,
                        ),
                        begin: const Offset(0, 1),
                        end: const Offset(1, 1),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonPill extends StatelessWidget {
  const _RibbonPill({required this.label, required this.textTheme});

  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.quizoo.gold,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.lightTx,
        ),
      ),
    );
  }
}

/// 16 wedge rays fading outward from the centre.
class _SunburstPainter extends CustomPainter {
  const _SunburstPainter({required this.color});

  final Color color;

  static const int rayCount = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (var i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi / rayCount) * i;
      final halfWidth = math.pi / rayCount / 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(angle - halfWidth),
          center.dy + radius * math.sin(angle - halfWidth),
        )
        ..lineTo(
          center.dx + radius * math.cos(angle + halfWidth),
          center.dy + radius * math.sin(angle + halfWidth),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter oldDelegate) =>
      oldDelegate.color != color;
}
