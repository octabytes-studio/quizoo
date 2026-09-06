import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The full-bleed wash both result screens sit on.
///
/// `linear-gradient(178deg, <accent> 0%, var(--s0) 46%)` — a saturated band at
/// the top that dissolves into the app background, so the celebration (or the
/// commiseration) reads before a single word does.
class ResultWash extends StatelessWidget {
  const ResultWash({
    required this.accent,
    required this.onClose,
    required this.child,
    required this.actions,
    super.key,
    this.onShare,
  });

  /// Mint for a completed level, raspberry for a failed one.
  final Color accent;

  final VoidCallback onClose;

  /// Present only on S-21 — there is nothing to share about a failed run.
  final VoidCallback? onShare;

  /// The scrolling body between the top bar and the buttons.
  final Widget child;

  /// The stacked buttons pinned to the bottom.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The top of the wash is always a saturated fill, so its status-bar
      // icons are light in both themes.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.linear(
              AppGradients.washAngle,
              [accent, quizoo.s0],
              stops: const [0, 0.46],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin.w,
                    AppSpacing.xs.h,
                    AppSpacing.screenMargin.w,
                    AppSpacing.md.h,
                  ),
                  child: Row(
                    children: [
                      _WashGlyphButton(glyph: '✕', onTap: onClose),
                      const Spacer(),
                      if (onShare != null)
                        _WashGlyphButton(glyph: '↗', onTap: onShare!),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                    child: child,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin.w,
                    AppSpacing.md.h,
                    AppSpacing.screenMargin.w,
                    AppSpacing.sm.h + 2.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WashGlyphButton extends StatelessWidget {
  const _WashGlyphButton({required this.glyph, required this.onTap});

  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        child: SizedBox(
          width: 38.w,
          height: 38.w,
          child: Center(
            child: Text(
              glyph,
              style: AppTypography.glyph(20.sp, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
