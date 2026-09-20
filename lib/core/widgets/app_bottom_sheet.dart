import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The app's bottom sheet: 28pt top corners, a grab handle, and the screen's
/// invariant 20px margin held **inside** the sheet too (§05).
///
/// [show] is the only way any feature should present a sheet, so the radius,
/// scrim colour, 88%-height cap and 300ms easeOutQuint entrance are decided
/// once here rather than at twenty call sites.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.message,
    this.showHandle = true,
  });

  /// The sheet's body, below the title block.
  final Widget child;

  final String? title;

  /// The line of body copy under [title].
  final String? message;

  final bool showHandle;

  /// `.sheet` — never taller than 88% of the viewport.
  static const double maxHeightFraction = 0.88;

  /// Presents [builder]'s widget as a modal sheet and resolves to whatever it
  /// pops with.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool isScrollControlled = true,
  }) {
    final quizoo = context.quizoo;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      // The sheet itself accounts for the bottom safe-area inset (see
      // build() below) so its rounded card reaches the true screen edge.
      // Letting the framework also wrap the route in SafeArea would pad
      // with transparent, scrim-coloured space *outside* that card,
      // leaving a visible gap beneath it.
      backgroundColor: Colors.transparent,
      barrierColor: quizoo.ov,
      elevation: 0,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.durationOf(context, AppMotion.sheet),
        curve: AppMotion.curveOf(context, AppMotion.sheetCurve),
        reverseDuration: AppMotion.durationOf(context, AppMotion.scrim),
      ),
      constraints: BoxConstraints(
        // Percentage-of-screen sizing goes through screenutil's `.sh`, never
        // MediaQuery height math (CLAUDE.md §6).
        maxHeight: maxHeightFraction.sh,
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    // The design's bottom padding and the device's safe-area inset (home
    // indicator, gesture bar) both reserve breathing room at the bottom —
    // take whichever is larger instead of stacking them, or a sheet on a
    // notched device ends up with the inset *plus* the full design padding
    // as dead space beneath its content.
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final designBottomPadding = AppSpacing.xl.h + 2.h;
    final bottomPadding = safeAreaBottom > designBottomPadding
        ? safeAreaBottom
        : designBottomPadding;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: AppRadius.sheetTop,
        boxShadow: quizoo.shadowLarge,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle) ...[
                Center(
                  child: Container(
                    width: 42.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: quizoo.ln,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
              ],
              if (title != null) Text(title!, style: textTheme.headlineLarge),
              if (message != null) ...[
                SizedBox(height: 5.h),
                Text(message!, style: textTheme.bodySmall),
              ],
              if (title != null || message != null)
                SizedBox(height: AppSpacing.base.h),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
