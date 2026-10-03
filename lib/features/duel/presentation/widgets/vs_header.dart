import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/widgets/pro_name.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';

/// The VS row shared by S-39 (searching), the live duel's intro and S-40's
/// round score.
///
/// A null [rightAvatarEmoji] renders the shimmering "❓ searching…" skeleton
/// side rather than a real avatar — the one state this widget itself decides,
/// since both callers need it and neither should re-implement the shimmer.
///
/// [leftName]/[rightName] add a name line above each caption, and
/// [leftBadge]/[rightBadge] a small pill on the avatar — the practice bot's
/// "BOT" label (never a secret bot, bible §14).
class VsHeader extends StatelessWidget {
  const VsHeader({
    required this.leftAvatarEmoji,
    required this.leftCaption,
    required this.rightCaption,
    super.key,
    this.rightAvatarEmoji,
    this.leftName,
    this.rightName,
    this.leftBadge,
    this.rightBadge,
    this.leftIsPro = false,
    this.rightIsPro = false,
  });

  final String leftAvatarEmoji;
  final String leftCaption;
  final String? rightAvatarEmoji;
  final String rightCaption;
  final String? leftName;
  final String? rightName;
  final String? leftBadge;
  final String? rightBadge;

  /// Quizoo Pro members (plan 023) — crown + tick on that side.
  final bool leftIsPro;
  final bool rightIsPro;

  static const double avatarSize = 64;

  /// How wide a side's name and caption may grow before ellipsizing.
  static const double sideMaxWidth = 140;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Side(
          emoji: leftAvatarEmoji,
          caption: leftCaption,
          name: leftName,
          badge: leftBadge,
          isPro: leftIsPro,
        ),
        Text(
          'VS',
          style: AppTypography.glyph(15.sp, color: context.arena.onArena),
        ),
        if (rightAvatarEmoji != null)
          _Side(
            emoji: rightAvatarEmoji!,
            caption: rightCaption,
            name: rightName,
            badge: rightBadge,
            isPro: rightIsPro,
          )
        else
          _SearchingSide(caption: rightCaption),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.emoji,
    required this.caption,
    this.name,
    this.badge,
    this.isPro = false,
  });

  final String emoji;
  final String caption;
  final String? name;
  final String? badge;

  /// A Quizoo Pro member (plan 023) — the gold verified tick follows the
  /// name. The avatar is never decorated.
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;
    final avatar = Container(
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
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: VsHeader.sideMaxWidth.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge == null)
            avatar
          else
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                avatar,
                PositionedDirectional(
                  bottom: -AppSpacing.sm.h,
                  child: _Badge(label: badge!),
                ),
              ],
            ),
          SizedBox(height: (badge == null ? AppSpacing.xs : AppSpacing.md).h),
          if (name != null)
            ProName(
              name: name!,
              isPro: isPro,
              style: textTheme.labelMedium!.copyWith(
                color: arena.onArena,
                fontWeight: FontWeight.w800,
              ),
            ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall!.copyWith(color: arena.metaText),
          ),
        ],
      ),
    );
  }
}

/// The small lemon pill on an avatar ("BOT").
class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.arena.botBadge,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: AppColors.onGold,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SearchingSide extends StatelessWidget {
  const _SearchingSide({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: VsHeader.sideMaxWidth.w),
      child: Column(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(color: arena.metaText),
          ),
        ],
      ),
    );
  }
}
