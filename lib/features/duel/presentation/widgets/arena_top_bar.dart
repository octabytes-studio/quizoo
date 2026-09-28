import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The Duel Arena's header (plan 017, S-38): ✕ to close, the title, and the
/// "● 23" head-count pill — or a "Reconnecting…" chip while the Realtime
/// channels are down.
class ArenaTopBar extends StatelessWidget {
  const ArenaTopBar({
    required this.onClose,
    super.key,
    this.isLive = true,
    this.onlineCount,
  });

  final VoidCallback onClose;

  /// False while the channels are re-subscribing.
  final bool isLive;

  /// Players on the arena; null hides the pill (presence off, or not loaded).
  final int? onlineCount;

  /// `.play .hud .x` — the close button's square.
  static const double closeSize = 38;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final count = onlineCount;

    final Widget trailing;
    if (!isLive) {
      trailing = _Pill(label: l10n.duelArenaReconnecting);
    } else if (count != null && count > 0) {
      trailing = Semantics(
        label: l10n.duelArenaOnline(count),
        child: ExcludeSemantics(
          child: _Pill(
            label: AppFormat.number(count, l10n.localeName),
            dotColor: arena.countdownSafe,
          ),
        ),
      );
    } else {
      trailing = SizedBox(width: closeSize.w);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.sm.h,
        AppSpacing.screenMargin.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.duelArenaCloseLabel,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: closeSize.w,
                height: closeSize.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: arena.chrome,
                  borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    '✕',
                    style: AppTypography.glyph(16.sp, color: arena.onArena),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                '⚔️ ${l10n.duelArenaTitle}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge!.copyWith(color: arena.onArena),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.dotColor});

  final String label;
  final Color? dotColor;

  static const double dotSize = 7;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;
    final dot = dotColor;

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
          if (dot != null) ...[
            Container(
              width: dotSize.w,
              height: dotSize.w,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            SizedBox(width: 5.w),
          ],
          Text(
            label,
            style: textTheme.labelMedium!.copyWith(color: arena.onArena),
          ),
        ],
      ),
    );
  }
}
