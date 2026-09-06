import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.tb` — the plain top bar: an optional back button, a title (with an
/// optional subtitle line), and an optional trailing widget.
///
/// Distinct from the bespoke gradient headers (Category detail, Profile),
/// this is the flat bar every other pushed screen in plan 003 uses —
/// Achievements, Stats, Friends, Category leaderboard — which is what earns it
/// a place in `core/` rather than four near-identical private widgets.
class SimpleTopBar extends StatelessWidget {
  const SimpleTopBar({
    required this.title,
    super.key,
    this.subtitle,
    this.showBackButton = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.sm.h,
        AppSpacing.screenMargin.w,
        AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            _BackButton(onTap: () => Navigator.of(context).maybePop()),
            SizedBox(width: AppSpacing.sm.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge!.copyWith(fontSize: 19.sp),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: context.quizoo.tx2,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// `.ib.plain` — a glyph with no plate behind it.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).commonBack,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34.w,
          height: 34.w,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('←', style: AppTypography.glyph(19.sp)),
          ),
        ),
      ),
    );
  }
}
