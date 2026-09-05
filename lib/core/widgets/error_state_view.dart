import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The content-error state — the empty state's shape plus a machine-readable
/// error code, so a support conversation has something to quote.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.title,
    super.key,
    this.emoji = '🧩',
    this.message,
    this.errorCode,
    this.action,
    this.secondaryAction,
  });

  final String title;
  final String emoji;
  final String? message;

  /// Rendered in mono at meta size — "ERR_CONTENT_404".
  final String? errorCode;

  /// Usually a `ChunkyButton` labelled "Try again".
  final Widget? action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                emoji,
                textAlign: TextAlign.center,
                style: AppTypography.glyph(60.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: quizoo.tx,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: 5.h),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
              ],
              if (errorCode != null) ...[
                SizedBox(height: AppSpacing.md.h),
                Text(
                  errorCode!,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall!.copyWith(
                    fontFamily: AppTypography.mono,
                    color: quizoo.tx3,
                  ),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: AppSpacing.xl.h),
                action!,
              ],
              if (secondaryAction != null) ...[
                SizedBox(height: AppSpacing.sm.h),
                secondaryAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
