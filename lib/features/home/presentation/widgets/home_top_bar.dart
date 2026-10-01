import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.tb` — Home's top bar, in its two forms.
///
/// The bible's two variants differ in more than a name: a guest gets a 22px
/// title and a search button, a signed-in player gets an avatar, a 19px
/// title, a streak line and the same search button. Two purpose-built widgets
/// rather than one with flags (CLAUDE.md §7).
class GuestTopBar extends StatelessWidget {
  const GuestTopBar({required this.onSearchPressed, super.key});

  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return _TopBarFrame(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.homeWelcome, style: textTheme.titleLarge),
              Text(
                l10n.homePlayingAsGuest,
                style: textTheme.bodyMedium!.copyWith(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: quizoo.tx3,
                ),
              ),
            ],
          ),
        ),
        HomeIconButton(
          glyph: '🔍',
          semanticLabel: l10n.homeSearchLabel,
          onTap: onSearchPressed,
        ),
      ],
    );
  }
}

/// S-05's top bar: avatar, greeting, streak line, search.
class PlayerTopBar extends StatelessWidget {
  const PlayerTopBar({
    required this.name,
    required this.avatarEmoji,
    required this.dayStreak,
    required this.playerLevel,
    required this.onSearchPressed,
    required this.onAvatarTap,
    super.key,
  });

  final String name;
  final String avatarEmoji;
  final int dayStreak;
  final int playerLevel;
  final VoidCallback onSearchPressed;

  /// Opens Edit Profile (plan 019) — Home's only entry point to it.
  final VoidCallback onAvatarTap;

  /// `.avc` at the size the top bar uses.
  static const double avatarSize = 38;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return _TopBarFrame(
      children: [
        Semantics(
          button: true,
          label: l10n.profileEditAction,
          child: GestureDetector(
            onTap: onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: avatarSize.w,
              height: avatarSize.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: quizoo.s3,
                border: Border.all(color: quizoo.s1, width: 2),
              ),
              child: Text(avatarEmoji, style: AppTypography.glyph(19.sp)),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge!.copyWith(fontSize: 19.sp),
              ),
              Text(
                l10n.homeStreakLevel(dayStreak, playerLevel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium!.copyWith(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: quizoo.tx3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.sm.w),
        HomeIconButton(
          glyph: '🔍',
          semanticLabel: l10n.homeSearchLabel,
          onTap: onSearchPressed,
        ),
      ],
    );
  }
}

/// `.ib` — the 38px surface icon button used across Home and Browse.
class HomeIconButton extends StatelessWidget {
  const HomeIconButton({
    required this.glyph,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String glyph;
  final String semanticLabel;
  final VoidCallback onTap;

  static const double size = 38;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size.w,
          height: size.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
            border: Border.all(color: quizoo.ln),
            boxShadow: quizoo.shadow,
          ),
          child: Text(glyph, style: AppTypography.glyph(17.sp)),
        ),
      ),
    );
  }
}

/// `.tb` — the shared padding and min-height of every top bar.
class _TopBarFrame extends StatelessWidget {
  const _TopBarFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.xs.h,
        AppSpacing.screenMargin.w,
        AppSpacing.md.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 52.h),
        child: Row(children: children),
      ),
    );
  }
}
