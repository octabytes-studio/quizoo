import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';

/// `.authbtn` — a sign-in button drawn to its vendor's required chrome.
///
/// Google and Apple both mandate exact surface, border and label colours, so
/// these cannot read from the app's palette and are the one deliberate
/// exception to CLAUDE.md §5's "no hardcoded colours in a feature": the values
/// *are* the specification, not a choice. They are named constants here rather
/// than inline hex so the exception is visible and confined to one file.
///
/// The brand slot holds a **placeholder glyph, not the real vendor mark**
/// (plan 001, Assumption 9) — shipping either logo needs their brand assets
/// and their guidelines, which is a legal step, not a design one.
class VendorSignInButton extends StatefulWidget {
  const VendorSignInButton({
    required this.provider,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final AuthProvider provider;
  final String label;
  final VoidCallback? onPressed;

  /// `.btn` — 54, matching every other primary button in the app.
  static const double height = 54;

  /// `.brandslot` — 28×28.
  static const double brandSlotSize = 28;

  // ------------------------------------------------- Google's required chrome
  static const Color googleSurface = Color(0xFFFFFFFF);
  static const Color googleBorder = Color(0xFFDADCE0);
  static const Color googleLabel = Color(0xFF3C4043);
  static const Color googleBlue = Color(0xFF4285F4);

  // -------------------------------------------------- Apple's required chrome
  static const Color appleSurface = Color(0xFF000000);
  static const Color appleLabel = Color(0xFFFFFFFF);
  static const Color appleLedge = Color(0xFF2C2C2E);

  @override
  State<VendorSignInButton> createState() => _VendorSignInButtonState();
}

class _VendorSignInButtonState extends State<VendorSignInButton> {
  bool _isPressed = false;

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
      Color surface,
      Color label,
      Color ledgeColor,
      Color? border,
      Color slotBackground,
      Color slotForeground,
      String glyph,
    ) = switch (widget.provider) {
      AuthProvider.google => (
        VendorSignInButton.googleSurface,
        VendorSignInButton.googleLabel,
        VendorSignInButton.googleBorder,
        VendorSignInButton.googleBorder,
        VendorSignInButton.googleBlue,
        Colors.white,
        'G',
      ),
      AuthProvider.apple => (
        VendorSignInButton.appleSurface,
        VendorSignInButton.appleLabel,
        VendorSignInButton.appleLedge,
        null,
        Colors.white,
        Colors.black,
        'A',
      ),
      // Email is ours, so it wears the app's grape.
      AuthProvider.email => (
        quizoo.g,
        Colors.white,
        quizoo.gShadow,
        null,
        Colors.white.withValues(alpha: 0.26),
        Colors.white,
        '✉',
      ),
    };

    final isEnabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: isEnabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: isEnabled ? 1 : 0.6,
          child: SizedBox(
            height: VendorSignInButton.height.h + ledge,
            child: AnimatedPadding(
              duration: AppMotion.durationOf(context, AppMotion.press),
              curve: AppMotion.curveOf(context, AppMotion.pressCurve),
              padding: EdgeInsets.only(
                top: _isPressed ? ledge : 0,
                bottom: _isPressed ? 0 : ledge,
              ),
              child: Container(
                padding: EdgeInsetsDirectional.only(
                  start: AppSpacing.base.w,
                  end: AppSpacing.base.w,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                  border: border == null
                      ? null
                      : Border.all(color: border, width: 1.5),
                  boxShadow: _isPressed
                      ? null
                      : [
                          BoxShadow(
                            color: ledgeColor,
                            offset: Offset(0, ledge),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: VendorSignInButton.brandSlotSize.w,
                      height: VendorSignInButton.brandSlotSize.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: slotBackground,
                        borderRadius: BorderRadius.circular(9.r),
                      ),
                      child: Text(
                        glyph,
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: slotForeground,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: label,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
