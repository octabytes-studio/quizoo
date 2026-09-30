import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The two chip shapes in the bible.
enum AppChipVariant {
  /// `.cat` — the tappable category chip on Home. 36 tall; selecting it
  /// inverts to the primary-text fill.
  category,

  /// `.chipf` — a small read-only status chip ("🔥 12-day streak",
  /// "🏅 Top 3%") on a sunken fill.
  status,
}

/// A pill-shaped chip — Home's category filter row, or a read-only status
/// marker.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
    this.leading,
    this.isSelected = false,
    this.onTap,
    this.variant = AppChipVariant.category,
    this.semanticLabel,
  });

  const AppChip.status({required this.label, super.key, this.leading})
    : isSelected = false,
      onTap = null,
      variant = AppChipVariant.status,
      semanticLabel = null;

  final String label;

  /// Usually an emoji.
  final String? leading;

  final bool isSelected;
  final VoidCallback? onTap;
  final AppChipVariant variant;

  /// What a screen reader announces instead of [label] on a tappable chip —
  /// e.g. Home's language pills spell out "Show quizzes in Urdu" rather than
  /// reading the native-script name (plan 021). When set, the visible text is
  /// excluded from semantics so it isn't read twice.
  final String? semanticLabel;

  /// `.cat` — 36.
  static const double categoryHeight = 36;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    final isCategory = variant == AppChipVariant.category;

    final background = switch ((isCategory, isSelected)) {
      (true, true) => quizoo.tx,
      (true, false) => quizoo.s1,
      (false, _) => quizoo.s3,
    };
    final foreground = switch ((isCategory, isSelected)) {
      (true, true) => quizoo.s1,
      (true, false) => quizoo.tx2,
      (false, _) => quizoo.tx2,
    };

    final style = isCategory
        ? textTheme.bodyLarge!.copyWith(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            color: foreground,
          )
        : textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w800,
            color: foreground,
          );

    final chip = Container(
      height: isCategory ? categoryHeight.h : null,
      padding: isCategory
          ? EdgeInsets.symmetric(horizontal: 14.w)
          : EdgeInsets.symmetric(horizontal: 10.w, vertical: AppSpacing.xs.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
        border: isCategory
            ? Border.all(color: isSelected ? quizoo.tx : quizoo.ln)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Text(leading!, style: style),
            SizedBox(width: isCategory ? 6.w : 5.w),
          ],
          Text(label, style: style),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel ?? label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: semanticLabel == null ? chip : ExcludeSemantics(child: chip),
      ),
    );
  }
}
