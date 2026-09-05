import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';

/// One destination in [ShareSheet]'s target row.
///
/// The bible is explicit that this row is **ordered by locale, not
/// alphabetically** — WhatsApp leads in our primary markets — so the order is
/// the caller's decision, not this widget's.
class ShareTarget {
  const ShareTarget({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
}

/// S-53 — the share sheet.
///
/// Renders our own preview card above the OS share sheet "so the player sees
/// exactly what will be posted". Lives in `core/` rather than a feature
/// because it is pure parameterised chrome with no business logic and two
/// features already present it (quiz result, daily) — flagged as a judgment
/// call in plan 001's Assumption 6.
class ShareSheet extends StatelessWidget {
  const ShareSheet({
    required this.title,
    required this.preview,
    required this.targets,
    super.key,
    this.message,
    this.onMoreOptions,
    this.moreOptionsLabel = 'More options',
  });

  final String title;

  /// "Spoiler-free — no answers included."
  final String? message;

  /// The card the player is about to post. Built by the calling feature,
  /// because only it knows what the result looked like.
  final Widget preview;

  final List<ShareTarget> targets;

  /// Hands off to the OS share sheet.
  final VoidCallback? onMoreOptions;
  final String moreOptionsLabel;

  /// `.c` share-target plate — 52×52.
  static const double targetSize = 52;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return AppBottomSheet(
      title: title,
      message: message,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          preview,
          SizedBox(height: AppSpacing.base.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final target in targets)
                Semantics(
                  button: true,
                  label: target.label,
                  child: GestureDetector(
                    onTap: target.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: targetSize.w,
                          height: targetSize.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: quizoo.s3,
                            borderRadius: BorderRadius.circular(
                              AppRadius.shareTarget.r,
                            ),
                          ),
                          child: Text(
                            target.emoji,
                            style: AppTypography.glyph(24.sp),
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(target.label, style: textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (onMoreOptions != null) ...[
            SizedBox(height: AppSpacing.base.h),
            ChunkyButton.ghost(
              label: moreOptionsLabel,
              onPressed: onMoreOptions,
            ),
          ],
        ],
      ),
    );
  }
}
