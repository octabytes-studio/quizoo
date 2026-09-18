import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// A shape-matched loading placeholder with the bible's 1.4s shimmer.
///
/// Two rules from §06 are baked in rather than left to call sites:
/// it only appears after [AppMotion.skeletonDelay] of waiting ("anything
/// faster just flashes"), and under reduced motion the sweep is replaced by a
/// flat fill instead of animating.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.appearAfter = AppMotion.skeletonDelay,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double? height;

  /// Match the real content's radius — that is the whole point of a skeleton.
  final BorderRadius? borderRadius;

  /// How long to stay invisible before fading in. [Duration.zero] shows it
  /// immediately, which is what a widget test usually wants.
  final Duration appearAfter;

  /// Overrides the sweep's outer colour. Defaults to `quizoo.s3` — only
  /// needed when the skeleton sits on a background (e.g. a gradient header)
  /// that the theme's neutral surface tones don't read against.
  final Color? baseColor;

  /// Overrides the sweep's highlight colour. Defaults to `quizoo.s2`.
  final Color? highlightColor;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  );

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.appearAfter == Duration.zero) {
      _isVisible = true;
    } else {
      Future<void>.delayed(widget.appearAfter, () {
        if (mounted) setState(() => _isVisible = true);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A shimmer that never stops is exactly the kind of motion a reduced-
    // motion setting is asking us to drop.
    if (AppMotion.reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppRadius.skeleton.r);
    final base = widget.baseColor ?? quizoo.s3;
    final highlight = widget.highlightColor ?? quizoo.s2;

    if (!_isVisible) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // `background-size: 200% 100%` swept from 0 to -200%.
          final shift = _controller.value * 2;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment(-1 - shift * 2, 0),
                end: Alignment(1 + 2 - shift * 2, 0),
                colors: [base, highlight, base],
                stops: const [0.25, 0.5, 0.75],
              ),
            ),
          );
        },
      ),
    );
  }
}
