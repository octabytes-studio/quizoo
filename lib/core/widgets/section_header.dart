import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// `.sec-t` — the heading above every rail, grid and list in the app.
///
/// Lives in `core/` because Home, Browse, the profile and the shop all use it
/// (CLAUDE.md §2's 3+ bar), which is what keeps their section rhythm identical
/// by construction rather than by discipline.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;

  /// The grape link on the trailing edge — "See all", "All 14",
  /// "Sort: Popular".
  final String? actionLabel;

  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: textTheme.titleMedium)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionPressed,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                button: onActionPressed != null,
                child: Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm.w),
                  child: Text(
                    actionLabel!,
                    style: textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: quizoo.g,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
