import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/leaderboard/domain/friend.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One row of S-31 — a pending request (✓/✕ pair) or a friend (a duel pill,
/// bright when online and dimmed when not).
class FriendRow extends StatelessWidget {
  const FriendRow({
    required this.friend,
    super.key,
    this.onAccept,
    this.onDecline,
    this.onDuel,
  });

  final Friend friend;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onDuel;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return ListRowTile(
      variant: ListRowVariant.player,
      title: friend.name,
      subtitle: friend.subtitle,
      leadingEmoji: friend.avatarEmoji,
      isPro: friend.isPro,
      trailing: friend.status == FriendStatus.pending
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundIconButton(
                  glyph: '✓',
                  background: quizoo.ok,
                  foreground: Colors.white,
                  semanticLabel: l10n.friendsAccept,
                  onTap: onAccept,
                ),
                SizedBox(width: AppSpacing.xs.w + 2.w),
                _RoundIconButton(
                  glyph: '✕',
                  background: quizoo.s3,
                  foreground: quizoo.tx3,
                  semanticLabel: l10n.friendsDecline,
                  onTap: onDecline,
                ),
              ],
            )
          : _DuelPill(
              isEnabled: friend.status == FriendStatus.online,
              onTap: onDuel,
            ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.glyph,
    required this.background,
    required this.foreground,
    required this.semanticLabel,
    this.onTap,
  });

  final String glyph;
  final Color background;
  final Color foreground;
  final String semanticLabel;
  final VoidCallback? onTap;

  static const double size = 32;

  @override
  Widget build(BuildContext context) {
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
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.rowAvatar.r),
          ),
          child: Text(
            glyph,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _DuelPill extends StatelessWidget {
  const _DuelPill({required this.isEnabled, this.onTap});

  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: l10n.friendsDuel,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isEnabled ? quizoo.p : quizoo.s3,
            borderRadius: BorderRadius.circular(AppRadius.rowAvatar.r),
          ),
          child: Text(
            l10n.friendsDuel,
            style: textTheme.labelMedium!.copyWith(
              color: isEnabled ? Colors.white : quizoo.tx3,
            ),
          ),
        ),
      ),
    );
  }
}
