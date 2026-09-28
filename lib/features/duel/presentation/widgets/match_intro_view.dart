import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_quit_button.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_status_chip.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The live duel's VS intro (plan 017, Design §4): both players, the topic,
/// whether it's ranked, then — once both are ready — a big 3-2-1 synced to
/// round 1's server start.
///
/// [secondsToStart] is null while the opponent hasn't loaded yet
/// ("Waiting for {name}…").
class MatchIntroView extends StatelessWidget {
  const MatchIntroView({
    required this.me,
    required this.opponent,
    required this.topic,
    required this.isRanked,
    super.key,
    this.secondsToStart,
    this.onQuit,
  });

  final DuelPlayer me;
  final DuelPlayer opponent;
  final DuelTopic topic;
  final bool isRanked;
  final int? secondsToStart;

  /// Shows the HUD ✕ when set.
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final opponentName = opponent.displayName(l10n);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        children: [
          SizedBox(height: AppSpacing.xs.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: onQuit == null
                ? SizedBox(height: DuelQuitButton.size.w)
                : DuelQuitButton(onPressed: onQuit!),
          ),
          const Spacer(),
          _TopicPlate(topic: topic),
          SizedBox(height: AppSpacing.xl.h),
          VsHeader(
            leftAvatarEmoji: me.avatarEmoji,
            leftName: me.displayName(l10n),
            leftCaption: _standing(me, l10n),
            rightAvatarEmoji: opponent.avatarEmoji,
            rightName: opponentName,
            rightCaption: _standing(opponent, l10n),
            rightBadge: opponent.isBot ? l10n.duelBotBadge : null,
          ),
          SizedBox(height: AppSpacing.lg.h),
          DuelStatusChip(
            emoji: isRanked ? '🏆' : '🤝',
            label: isRanked ? l10n.duelIntroRanked : l10n.duelIntroUnranked,
          ),
          const Spacer(),
          _Countdown(
            secondsToStart: secondsToStart,
            opponentName: opponentName,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  /// "🥇 Gold · 1412 ELO".
  static String _standing(DuelPlayer player, AppLocalizations l10n) =>
      '${player.leagueEmoji} ${player.leagueName} · '
      '${l10n.duelEloLabel(player.elo)}';
}

/// The topic both players are fighting in: sub-category plate, name and
/// category.
class _TopicPlate extends StatelessWidget {
  const _TopicPlate({required this.topic});

  final DuelTopic topic;

  static const double plateSize = 40;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm.w,
        AppSpacing.sm.h,
        AppSpacing.base.w,
        AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: arena.chrome,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: plateSize.w,
            height: plateSize.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppGradients.hex(topic.plateColor),
              borderRadius: BorderRadius.circular(AppRadius.subcategoryPlate.r),
            ),
            child: Text(topic.emoji, style: AppTypography.glyph(20.sp)),
          ),
          SizedBox(width: AppSpacing.md.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall!.copyWith(color: arena.onArena),
                ),
                Text(
                  '${topic.categoryEmoji} ${topic.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall!.copyWith(color: arena.metaText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Waiting for {name}…" with a spinner, then the big 3-2-1.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.secondsToStart, required this.opponentName});

  final int? secondsToStart;
  final String opponentName;

  /// Keeps the block the same height whichever line is showing.
  static const double height = 96;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final seconds = secondsToStart;

    final Widget child;
    if (seconds == null) {
      child = Column(
        key: const ValueKey('waiting'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: AppSpacing.xl.w,
            child: CircularProgressIndicator(
              color: arena.onArena,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            l10n.duelWaitingFor(opponentName),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(color: arena.metaText),
          ),
        ],
      );
    } else if (seconds <= 0) {
      child = Text(
        l10n.duelGetReady,
        key: const ValueKey('ready'),
        style: textTheme.displayMedium!.copyWith(color: arena.onArena),
      );
    } else {
      child = Semantics(
        key: ValueKey(seconds),
        label: l10n.duelIntroStartsIn(seconds),
        liveRegion: true,
        child: ExcludeSemantics(
          child: Text(
            '$seconds',
            style: textTheme.displayLarge!.copyWith(color: arena.onArena),
          ),
        ),
      );
    }

    return SizedBox(
      height: height.h,
      child: Center(
        child: AnimatedSwitcher(
          duration: AppMotion.durationOf(context, AppMotion.pop),
          switchInCurve: AppMotion.curveOf(context, AppMotion.popCurve),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: child,
        ),
      ),
    );
  }
}
