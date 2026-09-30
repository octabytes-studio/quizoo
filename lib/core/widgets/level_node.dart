import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// A node on the level map.
///
/// Four looks driven by [LevelStatus] plus [isBoss]: done (mint, with the
/// stars it earned), current (mango, scaled 1.12 with a soft ring so the eye
/// lands on it first), locked (sunken with a padlock), and boss — every tenth
/// level, which wears a crown.
///
/// Like every pressable surface it sits on a 4px ledge.
class LevelNode extends StatefulWidget {
  const LevelNode({
    required this.number,
    required this.status,
    super.key,
    this.isBoss = false,
    this.starsEarned = 0,
    this.onTap,
  });

  final int number;
  final LevelStatus status;
  final bool isBoss;

  /// 0…3. Only rendered for a completed node.
  final int starsEarned;

  final VoidCallback? onTap;

  /// `.node` — 62×62.
  static const double size = 62;

  /// `.node.now` — the current node is 12% larger than the rest.
  static const double currentScale = 1.12;

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode> {
  bool _isPressed = false;

  bool get _isEnabled =>
      widget.onTap != null && widget.status != LevelStatus.locked;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final ledge = AppElevation.ledge.h;

    final (
      Color background,
      Color foreground,
      Color ledgeColor,
    ) = switch (widget.status) {
      LevelStatus.done => (quizoo.ok, Colors.white, quizoo.okShadow),
      LevelStatus.current => (quizoo.p, Colors.white, quizoo.pShadow),
      LevelStatus.locked => (quizoo.s3, quizoo.tx3, quizoo.ln),
    };

    final showDepressed = _isPressed && _isEnabled;

    Widget node = AnimatedPadding(
      duration: AppMotion.durationOf(context, AppMotion.press),
      curve: AppMotion.curveOf(context, AppMotion.pressCurve),
      padding: EdgeInsets.only(
        top: showDepressed ? ledge : 0,
        bottom: showDepressed ? 0 : ledge,
      ),
      child: Container(
        width: LevelNode.size.w,
        height: LevelNode.size.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.node.r),
          // Only the locked/idle node keeps a hairline; the filled ones let
          // their ledge do the work.
          border: widget.status == LevelStatus.locked
              ? null
              : Border.all(color: Colors.transparent),
          boxShadow: showDepressed
              ? null
              : [BoxShadow(color: ledgeColor, offset: Offset(0, ledge))],
        ),
        child: Text(
          '${widget.number}',
          style: textTheme.titleLarge!.copyWith(
            fontSize: 22.sp,
            letterSpacing: 0,
            color: foreground,
          ),
        ),
      ),
    );

    if (widget.status == LevelStatus.current) {
      // `.node.now .ring` — a 3px halo at 42% mango, inset 7px.
      node = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -7.w,
            right: -7.w,
            top: -7.h,
            bottom: -7.h + ledge,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: quizoo.p.withValues(alpha: 0.42),
                  width: 3,
                ),
              ),
            ),
          ),
          node,
        ],
      );
      node = Transform.scale(scale: LevelNode.currentScale, child: node);
    }

    final decorations = <Widget>[
      node,
      if (widget.isBoss)
        Positioned(
          top: -9.h,
          right: -9.w,
          child: Text('👑', style: AppTypography.glyph(17.sp)),
        ),
      if (widget.status == LevelStatus.locked)
        Positioned(
          top: -5.h,
          right: -5.w,
          child: Container(
            width: 21.w,
            height: 21.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quizoo.s1,
              border: Border.all(color: quizoo.ln),
            ),
            child: Text('🔒', style: AppTypography.glyph(10.sp)),
          ),
        ),
      if (widget.status == LevelStatus.done && widget.starsEarned > 0)
        Positioned(
          bottom: -7.h,
          child: Text(
            '⭐' * widget.starsEarned,
            style: AppTypography.glyph(11.sp, letterSpacing: -2),
          ),
        ),
    ];

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: 'Level ${widget.number}',
      value: switch (widget.status) {
        LevelStatus.done => '${widget.starsEarned} of 3 stars',
        LevelStatus.current => 'Current level',
        LevelStatus.locked => 'Locked',
      },
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: _isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: _isEnabled ? () => _setPressed(false) : null,
        onTap: _isEnabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: LevelNode.size.w,
          height: LevelNode.size.w + ledge,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: decorations,
          ),
        ),
      ),
    );
  }
}
