import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The five states an answer option can be in (§06).
enum AnswerOptionState {
  /// Untouched. A near-white plate on the arena.
  rest,

  /// Tapped, awaiting the verdict — a 3px lemon ring, offset 2px.
  selected,

  /// Right. Mint fill **and** a ✓.
  correct,

  /// Wrong. Raspberry fill **and** a ✕.
  wrong,

  /// Removed by 50:50 — 24% opacity, no ledge, not tappable.
  eliminated,
}

/// One tappable answer on the play surface.
///
/// The colour is always doubled by a ✓/✕ glyph, never carried by hue alone —
/// the bible is explicit that "roughly 1 in 12 male players cannot separate
/// [mint/raspberry] by hue alone".
///
/// Like [ChunkyButton] this sits on a 4px ledge and translates into it on
/// press, and it reads its palette from [ArenaColors] rather than the active
/// brightness, because the arena looks the same in light and dark.
class AnswerOption extends StatefulWidget {
  const AnswerOption({
    required this.label,
    required this.optionKey,
    required this.state,
    required this.onPressed,
    super.key,
  });

  /// The answer text.
  final String label;

  /// The A/B/C/D badge at the leading edge.
  final String optionKey;

  final AnswerOptionState state;

  /// Null, or an [AnswerOptionState.eliminated] state, makes the option inert.
  final VoidCallback? onPressed;

  /// `.opt` — the minimum height; long answers grow past it.
  static const double minHeight = 56;

  /// `.opt .k` — the key badge is a 30px square.
  static const double keyBadgeSize = 30;

  @override
  State<AnswerOption> createState() => _AnswerOptionState();
}

class _AnswerOptionState extends State<AnswerOption> {
  bool _isPressed = false;

  bool get _isEnabled =>
      widget.onPressed != null && widget.state != AnswerOptionState.eliminated;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final ledge = AppElevation.ledge.h;

    final (
      Color background,
      Color foreground,
      Color? ledgeColor,
    ) = switch (widget.state) {
      AnswerOptionState.rest || AnswerOptionState.selected => (
        arena.optionRest,
        AppColors.onAnswerRest,
        arena.optionRestShadow,
      ),
      AnswerOptionState.correct => (quizoo.ok, Colors.white, quizoo.okShadow),
      AnswerOptionState.wrong => (quizoo.bad, Colors.white, quizoo.badShadow),
      AnswerOptionState.eliminated => (arena.optionGone, arena.onArena, null),
    };

    final isFeedback =
        widget.state == AnswerOptionState.correct ||
        widget.state == AnswerOptionState.wrong;

    final keyBackground = isFeedback
        ? Colors.white.withValues(alpha: 0.28)
        : AppColors.answerKeyBg;
    final keyForeground = isFeedback ? Colors.white : AppColors.answerKeyFg;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final extraPadding = isRtl ? AppTypography.rtlExtraVerticalPadding.h : 0.0;

    final showDepressed = _isPressed && _isEnabled;
    final hasLedge = ledgeColor != null && !showDepressed;

    Widget plate = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.answer.r),
        boxShadow: hasLedge
            ? [BoxShadow(color: ledgeColor, offset: Offset(0, ledge))]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: AppSpacing.sm.h + extraPadding,
        ),
        child: Row(
          children: [
            Container(
              width: AnswerOption.keyBadgeSize.w,
              height: AnswerOption.keyBadgeSize.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: keyBackground,
                borderRadius: BorderRadius.circular(AppRadius.answerKey.r),
              ),
              child: Text(
                widget.optionKey,
                style: textTheme.titleSmall!.copyWith(
                  fontSize: 15.sp,
                  color: keyForeground,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Text(
                widget.label,
                style: textTheme.bodyLarge!.copyWith(color: foreground),
              ),
            ),
            if (isFeedback) ...[
              SizedBox(width: AppSpacing.sm.w),
              Text(
                widget.state == AnswerOptionState.correct ? '✓' : '✕',
                style: AppTypography.glyph(18.sp, color: foreground),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.state == AnswerOptionState.eliminated) {
      plate = Opacity(opacity: 0.24, child: plate);
    }

    if (widget.state == AnswerOptionState.selected) {
      // `.opt.sel` — a 3px lemon outline, offset 2px outside the plate.
      plate = Container(
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.answer.r + 5.r),
          border: Border.all(color: quizoo.gold, width: 3),
        ),
        child: plate,
      );
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      selected: widget.state == AnswerOptionState.selected,
      label: '${widget.optionKey}. ${widget.label}',
      value: switch (widget.state) {
        AnswerOptionState.correct => 'Correct',
        AnswerOptionState.wrong => 'Wrong',
        AnswerOptionState.eliminated => 'Removed',
        _ => null,
      },
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: _isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: _isEnabled ? () => _setPressed(false) : null,
        onTap: _isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: AnswerOption.minHeight.h + ledge + extraPadding * 2,
          ),
          child: AnimatedPadding(
            duration: AppMotion.durationOf(context, AppMotion.press),
            curve: AppMotion.curveOf(context, AppMotion.pressCurve),
            padding: EdgeInsets.only(
              top: showDepressed ? ledge : 0,
              bottom: showDepressed ? 0 : ledge,
            ),
            child: plate,
          ),
        ),
      ),
    );
  }
}
