import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_motion.dart';

/// A one-shot confetti burst launched from just above the medallion, fanning
/// upward and falling with gravity — the Topic Mastered screen's biggest
/// celebration beat (plan 020). Runs once and never loops; disabled entirely
/// under reduced motion.
class MasteryConfetti extends StatefulWidget {
  const MasteryConfetti({super.key});

  static const int particleCount = 70;
  static const Duration lifetime = Duration(milliseconds: 2400);
  static const Duration startDelay = Duration(milliseconds: 460);

  @override
  State<MasteryConfetti> createState() => _MasteryConfettiState();
}

class _MasteryConfettiState extends State<MasteryConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  bool _scheduledStart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MasteryConfetti.lifetime,
    );
    final random = Random(7);
    _particles = [
      for (var i = 0; i < MasteryConfetti.particleCount; i++)
        _Particle.random(random),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `MediaQuery` (which `AppMotion.reduceMotion` reads) isn't safely
    // available to depend on until after `initState` completes, so the
    // reduced-motion check happens here instead.
    if (!_scheduledStart && !AppMotion.reduceMotion(context)) {
      _scheduledStart = true;
      Future<void>.delayed(MasteryConfetti.startDelay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return const SizedBox.shrink();

    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.rotationSpeed,
  });

  factory _Particle.random(Random random) {
    // A 120° fan centred straight up.
    final angle = -pi / 2 + (random.nextDouble() - 0.5) * (2 * pi / 3);
    return _Particle(
      angle: angle,
      speed: 260 + random.nextDouble() * 220,
      size: 4 + random.nextDouble() * 4,
      color: AppColors
          .masteryConfetti[random.nextInt(AppColors.masteryConfetti.length)],
      isCircle: random.nextBool(),
      rotationSpeed: (random.nextDouble() - 0.5) * 10,
    );
  }

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final bool isCircle;
  final double rotationSpeed;

  static const double gravity = 700;

  Offset positionAt(double t, Offset origin) {
    final vx = cos(angle) * speed;
    final vy = sin(angle) * speed;
    final dx = vx * t;
    final dy = vy * t + 0.5 * gravity * t * t;
    return origin + Offset(dx, dy);
  }

  double opacityAt(double progress) => (1 - progress).clamp(0, 1);
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.62);
    final elapsedSeconds =
        progress * (MasteryConfetti.lifetime.inMilliseconds / 1000);

    for (final particle in particles) {
      final position = particle.positionAt(elapsedSeconds, origin);
      final opacity = particle.opacityAt(progress);
      if (opacity <= 0) continue;

      final paint = Paint()..color = particle.color.withValues(alpha: opacity);
      final rotation = elapsedSeconds * particle.rotationSpeed;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
