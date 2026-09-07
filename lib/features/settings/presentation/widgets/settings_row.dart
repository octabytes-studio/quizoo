import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// S-42's tappable settings row — a title, an optional caption, and a
/// trailing "›" that opens another screen.
///
/// [isDestructive] switches the title to raspberry — S-42's "Delete account"
/// row is the one place this is used.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    required this.onTap,
    super.key,
    this.caption,
    this.isDestructive = false,
  });

  final String title;
  final String? caption;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: caption == null ? title : '$title, $caption',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: BorderRadius.circular(AppRadius.listRow.r),
            border: Border.all(color: quizoo.ln),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDestructive ? quizoo.bad : quizoo.tx,
                  ),
                ),
              ),
              if (caption != null) ...[
                Text(
                  caption!,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 12.5.sp,
                    color: quizoo.tx3,
                  ),
                ),
                SizedBox(width: AppSpacing.xs.w),
              ],
              Text('›', style: AppTypography.glyph(16.sp, color: quizoo.tx3)),
            ],
          ),
        ),
      ),
    );
  }
}
