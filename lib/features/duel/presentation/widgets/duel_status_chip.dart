import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';

/// S-40's status-chip pair — "🐼 answered in {t}s" once a side has locked in
/// an answer, "🦊 thinking…" while it hasn't. Never shows who was right: that
/// is the whole point of the withheld-correctness rule this screen exists to
/// demonstrate.
class DuelStatusChip extends StatelessWidget {
  const DuelStatusChip({required this.emoji, required this.label, super.key});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w + 2.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: arena.chrome,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: AppTypography.glyph(13.sp)),
          SizedBox(width: 5.w),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(color: arena.onArena),
          ),
        ],
      ),
    );
  }
}
