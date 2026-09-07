import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';

/// The VS row shared by S-39 (searching) and S-40 (live round score).
///
/// A null [rightAvatarEmoji] renders the shimmering "❓ searching…" skeleton
/// side rather than a real avatar — the one state this widget itself decides,
/// since both callers need it and neither should re-implement the shimmer.
class VsHeader extends StatelessWidget {
  const VsHeader({
    required this.leftAvatarEmoji,
    required this.leftCaption,
    required this.rightCaption,
    super.key,
    this.rightAvatarEmoji,
  });

  final String leftAvatarEmoji;
  final String leftCaption;
  final String? rightAvatarEmoji;
  final String rightCaption;

  static const double avatarSize = 64;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Side(emoji: leftAvatarEmoji, caption: leftCaption),
        Text(
          'VS',
          style: AppTypography.glyph(15.sp, color: context.arena.onArena),
        ),
        if (rightAvatarEmoji != null)
          _Side(emoji: rightAvatarEmoji!, caption: rightCaption)
        else
          _SearchingSide(caption: rightCaption),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.emoji, required this.caption});

  final String emoji;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: VsHeader.avatarSize.w,
          height: VsHeader.avatarSize.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: arena.chrome,
            border: Border.all(
              color: arena.onArena.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Text(emoji, style: AppTypography.glyph(28.sp)),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          caption,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: arena.metaText),
        ),
      ],
    );
  }
}

class _SearchingSide extends StatelessWidget {
  const _SearchingSide({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SkeletonBox(
            width: VsHeader.avatarSize.w,
            height: VsHeader.avatarSize.w,
            appearAfter: Duration.zero,
          ),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          caption,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: arena.metaText),
        ),
      ],
    );
  }
}
