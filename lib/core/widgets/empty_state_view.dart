import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The `.empty` block — a centred emoji, a display-type headline, a line of
/// body copy, and an optional way out.
///
/// The bible's anti-pillar rule applies here too: never end on a dead end.
/// Give this an [action] wherever the player could plausibly do something.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.emoji,
    required this.title,
    super.key,
    this.message,
    this.action,
    this.secondaryAction,
  });

  final String emoji;
  final String title;
  final String? message;

  /// Usually a `ChunkyButton`.
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
