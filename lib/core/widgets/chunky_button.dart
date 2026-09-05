import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The design bible's signature: a pressable surface sitting on a solid,
/// un-blurred 4px ledge in a darker shade of its own colour, which translates
/// down 4px on press so the ledge disappears under it.
///
/// > "That single detail is what makes the app read as a toy rather than a
/// > form." — §05
///
/// Every variant is a named constructor rather than a bag of booleans
/// (CLAUDE.md §7), and the widget always occupies `height + 4` so a press
/// never reflows the column around it.
enum ChunkyButtonVariant {
  /// Mango. The colour of "go".
  primary,

  /// Grape. Identity actions — continue, sign in.
  secondary,

  /// Mint. Claiming something.
  success,

  /// Lemon. Rewarded / value actions.
  gold,

  /// Surface-coloured with a hairline ledge. The soft decline.
  ghost,

  /// Outline only, no ledge, smaller type. Tertiary actions.
  line,

  /// Keeps its ledge so the shape does not jump when a button disables.
  disabled,
}

class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = ChunkyButtonVariant.primary,
    this.subLabel,
    this.icon,
    this.isSmall = false,
    this.semanticLabel,
  });

  const ChunkyButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.subLabel,
    this.icon,
    this.isSmall = false,
    this.semanticLabel,
  }) : variant = ChunkyButtonVariant.secondary;

  const ChunkyButton.success({
    required this.label,
    required this.onPressed,
    super.key,
    this.subLabel,
    this.icon,
    this.isSmall = false,
    this.semanticLabel,
  }) : variant = ChunkyButtonVariant.success;

  const ChunkyButton.gold({
    required this.label,
    required this.onPressed,
    super.key,
    this.subLabel,
    this.icon,
    this.isSmall = false,
    this.semanticLabel,
  }) : variant = ChunkyButtonVariant.gold;

  const ChunkyButton.ghost({
    required this.label,
    required this.onPressed,
    super.key,
    this.subLabel,
    this.icon,
    this.isSmall = false,
    this.semanticLabel,
  }) : variant = ChunkyButtonVariant.ghost;

  const ChunkyButton.line({
    required this.label,
    required this.onPressed,
    super.key,
    this.subLabel,
    this.icon,
    this.isSmall = false,
    this.semanticLabel,
  }) : variant = ChunkyButtonVariant.line;

  /// The button's label. Rendered in Baloo 800 at 17.5 (15.5 for
  /// [ChunkyButtonVariant.line], 15 when [isSmall]).
  final String label;

  /// An optional second line in body type at 11 — "Watch ad for +1 ❤️" style
  /// buttons use it to carry their cost or condition.
  final String? subLabel;

  /// Leading glyph. Emoji render as text; anything else as an icon.
  final Widget? icon;

  /// Null disables the button — it keeps its ledge and takes the disabled
  /// palette, so the layout does not shift.
  final VoidCallback? onPressed;

  final ChunkyButtonVariant variant;

  /// `.btn.sm` — 44 tall, 15pt type, radius 14.
  final bool isSmall;

  final String? semanticLabel;

  /// `.btn` — 54.
  static const double height = 54;

  /// `.btn.sm` — 44.
  static const double smallHeight = 44;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _isPressed = false;

  bool get _isEnabled =>
      widget.onPressed != null &&
      widget.variant != ChunkyButtonVariant.disabled;

  ChunkyButtonVariant get _effectiveVariant =>
      _isEnabled ? widget.variant : ChunkyButtonVariant.disabled;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final variant = _effectiveVariant;
    final ledge = AppElevation.ledge.h;
    final height = (widget.isSmall
        ? ChunkyButton.smallHeight
        : ChunkyButton.height);

    final (
      Color background,
      Color foreground,
      Color ledgeColor,
    ) = switch (variant) {
      ChunkyButtonVariant.primary => (quizoo.p, Colors.white, quizoo.pShadow),
      ChunkyButtonVariant.secondary => (quizoo.g, Colors.white, quizoo.gShadow),
      ChunkyButtonVariant.success => (quizoo.ok, Colors.white, quizoo.okShadow),
      ChunkyButtonVariant.gold => (
        quizoo.gold,
        AppColors.onGold,
        quizoo.goldShadow,
      ),
      ChunkyButtonVariant.ghost => (quizoo.s1, quizoo.tx, quizoo.ln),
      ChunkyButtonVariant.line => (
        Colors.transparent,
        quizoo.tx2,
        Colors.transparent,
      ),
      ChunkyButtonVariant.disabled => (quizoo.s3, quizoo.tx3, quizoo.ln),
    };

    final hasBorder =
        variant == ChunkyButtonVariant.ghost ||
        variant == ChunkyButtonVariant.line;
    final hasLedge = variant != ChunkyButtonVariant.line;

    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelLarge!.copyWith(
      color: foreground,
      fontSize: switch ((widget.isSmall, variant)) {
        (true, _) => 15.sp,
        (false, ChunkyButtonVariant.line) => 15.5.sp,
        (false, _) => 17.5.sp,
      },
    );

    // §04: Urdu and Arabic need 4px more vertical room in every button and
    // option row. Handled here so no screen has to think about it.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final verticalPadding = isRtl
        ? AppTypography.rtlExtraVerticalPadding.h
        : 0.0;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: foreground, size: 20.sp),
            child: DefaultTextStyle.merge(
              style: AppTypography.glyph(18.sp, color: foreground),
              child: widget.icon!,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: labelStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subLabel != null)
                Text(
                  widget.subLabel!,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 11.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: foreground.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

    final showDepressed = _isPressed && _isEnabled;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: _isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: _isEnabled ? () => _setPressed(false) : null,
        onTap: _isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: height.h + verticalPadding * 2 + (hasLedge ? ledge : 0),
          child: AnimatedPadding(
            duration: AppMotion.durationOf(context, AppMotion.press),
            curve: AppMotion.curveOf(context, AppMotion.pressCurve),
            padding: EdgeInsets.only(
              top: showDepressed && hasLedge ? ledge : 0,
              bottom: hasLedge && !showDepressed ? ledge : 0,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(
                  (widget.isSmall ? AppRadius.buttonSmall : AppRadius.button).r,
                ),
                border: hasBorder
                    ? Border.all(color: quizoo.ln, width: 1.5)
                    : null,
                boxShadow: hasLedge && !showDepressed
                    ? [BoxShadow(color: ledgeColor, offset: Offset(0, ledge))]
                    : null,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
