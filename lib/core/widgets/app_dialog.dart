import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The app's modal dialog: 26pt corners, a tinted icon plate, centred copy,
/// and a **column** of full-width actions.
///
/// Side-by-side buttons are the one place the bible allows them, but the
/// stacked form is the default because it keeps the destructive choice from
/// sitting at thumb height next to the safe one.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.actions,
    super.key,
    this.emoji,
    this.iconPlateColor,
    this.message,
    this.content,
  });

  final String title;
  final String? message;

  /// The glyph in the icon plate.
  final String? emoji;

  /// Fill behind [emoji] — usually a tint like `okBg` or `badBg`.
  final Color? iconPlateColor;

  /// Extra body content between the copy and the actions.
  final Widget? content;

  /// Full-width actions, most-recommended first.
  final List<Widget> actions;

  /// `.dlg .ico` — 66×66.
  static const double iconPlateSize = 66;

  /// Presents [builder]'s widget as a modal dialog.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    final quizoo = context.quizoo;
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: quizoo.ov,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w + 2.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          22.w,
          AppSpacing.xl.h,
          22.w,
          AppSpacing.lg.h,
        ),
        decoration: BoxDecoration(
          color: quizoo.s1,
          borderRadius: AppRadius.dialogAll,
          boxShadow: quizoo.shadowLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (emoji != null) ...[
              Center(
                child: Container(
                  width: iconPlateSize.w,
                  height: iconPlateSize.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconPlateColor ?? quizoo.s3,
                    borderRadius: BorderRadius.circular(AppRadius.dialogIcon.r),
                  ),
                  child: Text(emoji!, style: AppTypography.glyph(33.sp)),
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge,
            ),
            if (message != null) ...[
              SizedBox(height: 6.h),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
            if (content != null) ...[
              SizedBox(height: AppSpacing.base.h),
              content!,
            ],
            SizedBox(height: AppSpacing.base.h + 2.h),
            for (final (index, action) in actions.indexed) ...[
              if (index > 0) SizedBox(height: 9.h),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
