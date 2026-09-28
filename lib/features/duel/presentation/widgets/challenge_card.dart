import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/challenge_card_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/fairness.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_countdown_ring.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_clock_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One card in the Duel Arena feed (plan 017, "Challenge card states").
///
/// Purely presentational: [cardState] and [fairness] are derived by
/// `DuelArenaReady`, and [now] is the Bloc's server-clock tick. One widget
/// covers every state — open, request sent, deciding, not-this-time/retry,
/// away, in progress and the viewer's own (end-aligned, like a chat "me"
/// bubble).
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    required this.challenge,
    required this.cardState,
    required this.fairness,
    required this.now,
    required this.config,
    super.key,
    this.onJoin,
    this.onWithdraw,
    this.onCancel,
  });

  final DuelChallenge challenge;
  final ChallengeCardState cardState;
  final Fairness fairness;

  /// Server time.
  final DateTime now;

  /// For the TTL, the decision window, the round count and the reward.
  final DuelConfig config;

  /// Null disables Join.
  final VoidCallback? onJoin;
  final VoidCallback? onWithdraw;

  /// Null disables Cancel on the viewer's own card.
  final VoidCallback? onCancel;

  /// The viewer's own card is narrower and end-aligned.
  static const double ownWidthFactor = 0.86;

  /// An away creator's card is dimmed to this.
  static const double awayOpacity = 0.55;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final creator = challenge.creator;
    final remaining = _remaining(challenge.expiresAt, now);

    final semanticsLabel = l10n.duelCardSemantics(
      creator.displayName(l10n),
      creator.leagueName,
      creator.elo,
      challenge.topic.name,
      remaining.clockLabel(l10n.localeName),
    );

    final Widget card = switch (cardState) {
      ChallengeCardOwn(:final paused) => _OwnCard(
        challenge: challenge,
        remaining: remaining,
        total: Duration(seconds: config.challengeTtlSeconds),
        paused: paused,
        onCancel: onCancel,
      ),
      ChallengeCardInProgress(:final opponentName, :final opponentGuestTag) =>
        _InProgressCard(
          challenge: challenge,
          opponentLabel:
              opponentName ?? l10n.duelGuestName(opponentGuestTag ?? ''),
        ),
      ChallengeCardOpen() ||
      ChallengeCardQueued() ||
      ChallengeCardPending() ||
      ChallengeCardCooling() ||
      ChallengeCardAway() => _JoinableCard(
        challenge: challenge,
        cardState: cardState,
        fairness: fairness,
        now: now,
        remaining: remaining,
        config: config,
        onJoin: onJoin,
        onWithdraw: onWithdraw,
      ),
    };

    return Semantics(container: true, label: semanticsLabel, child: card);
  }
}

Duration _remaining(DateTime until, DateTime now) {
  final left = until.difference(now);
  return left.isNegative ? Duration.zero : left;
}

// -------------------------------------------------------------- joinable

class _JoinableCard extends StatelessWidget {
  const _JoinableCard({
    required this.challenge,
    required this.cardState,
    required this.fairness,
    required this.now,
    required this.remaining,
    required this.config,
    required this.onJoin,
    required this.onWithdraw,
  });

  final DuelChallenge challenge;
  final ChallengeCardState cardState;
  final Fairness fairness;
  final DateTime now;
  final Duration remaining;
  final DuelConfig config;
  final VoidCallback? onJoin;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;
    final isAway = cardState is ChallengeCardAway;
    final isPending = cardState is ChallengeCardPending;

    final plate = _CardPlate(
      borderColor: isPending ? arena.pendingGlow : null,
      glowColor: isPending ? arena.pendingGlow : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CreatorHeader(
                  player: challenge.creator,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAway) ...[
                        const _AwayChip(),
                        SizedBox(width: AppSpacing.sm.w),
                      ],
                      ChallengeCountdownRing(
                        remaining: remaining,
                        total: Duration(seconds: config.challengeTtlSeconds),
                        trackColor: arena.cardChip,
                        labelStyle: textTheme.labelMedium!.copyWith(
                          color: arena.cardInk,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                _TopicLine(
                  topic: challenge.topic,
                  trailing: _FairnessChip(fairness: fairness),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          _JoinActionArea(
            challenge: challenge,
            cardState: cardState,
            now: now,
            config: config,
            onJoin: onJoin,
            onWithdraw: onWithdraw,
          ),
        ],
      ),
    );

    return isAway
        ? Opacity(opacity: ChallengeCard.awayOpacity, child: plate)
        : plate;
  }
}

/// The bottom row of a joinable card — the part that changes with the
/// viewer's request.
class _JoinActionArea extends StatelessWidget {
  const _JoinActionArea({
    required this.challenge,
    required this.cardState,
    required this.now,
    required this.config,
    required this.onJoin,
    required this.onWithdraw,
  });

  final DuelChallenge challenge;
  final ChallengeCardState cardState;
  final DateTime now;
  final DuelConfig config;
  final VoidCallback? onJoin;
  final VoidCallback? onWithdraw;

  static const double joinWidth = 112;
  static const double retryWidth = 156;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;
    final reward = ExcludeSemantics(
      child: Text(
        l10n.duelCardReward(config.rounds, config.winCoins),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelMedium!.copyWith(color: arena.cardInkMuted),
      ),
    );

    Widget withButton(Widget button, double width) => Row(
      children: [
        Expanded(child: reward),
        SizedBox(width: AppSpacing.sm.w),
        SizedBox(width: width.w, child: button),
      ],
    );

    return switch (cardState) {
      ChallengeCardOpen() => withButton(
        ChunkyButton(
          label: l10n.duelCardJoin,
          icon: const Text('⚔️'),
          isSmall: true,
          onPressed: onJoin,
        ),
        joinWidth,
      ),
      ChallengeCardAway() => withButton(
        ChunkyButton(
          label: l10n.duelCardJoin,
          icon: const Text('⚔️'),
          isSmall: true,
          onPressed: null,
        ),
        joinWidth,
      ),
      ChallengeCardCooling(:final retryAt, :final justResolved) => withButton(
        ChunkyButton(
          label: justResolved
              ? l10n.duelCardNotThisTime
              : l10n.duelCardRetryIn(_remaining(retryAt, now).secondsUp),
          isSmall: true,
          onPressed: null,
        ),
        retryWidth,
      ),
      ChallengeCardQueued(:final position) => _RequestStatusRow(
        emoji: '⏳',
        label: position == null || position <= 0
            ? l10n.duelCardSent
            : l10n.duelCardQueued(position),
        onWithdraw: onWithdraw,
      ),
      ChallengeCardPending(:final expiresAt) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RequestStatusRow(
            emoji: '🤔',
            label: l10n.duelCardDeciding(challenge.creator.displayName(l10n)),
            onWithdraw: onWithdraw,
          ),
          SizedBox(height: AppSpacing.sm.h),
          _WindowBar(
            remaining: _remaining(expiresAt, now),
            window: Duration(seconds: config.joinWindowSeconds),
            color: arena.pendingGlow,
            trackColor: arena.cardChip,
          ),
        ],
      ),
      // Rendered by their own card widgets, never here.
      ChallengeCardOwn() ||
      ChallengeCardInProgress() => const SizedBox.shrink(),
    };
  }
}

/// "⏳ Request sent · 2 ahead" + a small ✕ to withdraw.
class _RequestStatusRow extends StatelessWidget {
  const _RequestStatusRow({
    required this.emoji,
    required this.label,
    required this.onWithdraw,
  });

  final String emoji;
  final String label;
  final VoidCallback? onWithdraw;

  static const double withdrawSize = 32;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(emoji, style: AppTypography.glyph(15.sp)),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: arena.cardInk,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm.w),
        Semantics(
          button: true,
          enabled: onWithdraw != null,
          label: l10n.duelCardCancel,
          child: GestureDetector(
            onTap: onWithdraw,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: withdrawSize.w,
              height: withdrawSize.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: arena.cardChip,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Text(
                  '✕',
                  style: AppTypography.glyph(13.sp, color: arena.cardInkMuted),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The 5-second decision bar, synced to the server's deadline.
class _WindowBar extends StatelessWidget {
  const _WindowBar({
    required this.remaining,
    required this.window,
    required this.color,
    required this.trackColor,
  });

  final Duration remaining;
  final Duration window;
  final Color color;
  final Color trackColor;

  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    final fraction = window <= Duration.zero
        ? 0.0
        : (remaining.inMilliseconds / window.inMilliseconds).clamp(0.0, 1.0);

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: height.h,
          color: color,
          backgroundColor: trackColor,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- own card

class _OwnCard extends StatelessWidget {
  const _OwnCard({
    required this.challenge,
    required this.remaining,
    required this.total,
    required this.paused,
    required this.onCancel,
  });

  final DuelChallenge challenge;
  final Duration remaining;
  final Duration total;
  final bool paused;
  final VoidCallback? onCancel;

  static const double cancelWidth = 104;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FractionallySizedBox(
        widthFactor: ChallengeCard.ownWidthFactor,
        child: _CardPlate(
          borderColor: arena.ownCardBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.duelCardYours,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall!.copyWith(
                              color: arena.cardInk,
                            ),
                          ),
                        ),
                        ChallengeCountdownRing(
                          remaining: remaining,
                          total: total,
                          trackColor: arena.cardChip,
                          labelStyle: textTheme.labelMedium!.copyWith(
                            color: arena.cardInk,
                            fontFeatures: AppTypography.tabular,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        _Avatar(
                          emoji: challenge.creator.avatarEmoji,
                          size: _Avatar.smallSize,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    _TopicLine(topic: challenge.topic),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      paused
                          ? '💤 ${l10n.duelCardPaused}'
                          : l10n.duelCardWaiting,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium!.copyWith(
                        color: arena.cardInkMuted,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  SizedBox(
                    width: cancelWidth.w,
                    child: ChunkyButton.ghost(
                      label: l10n.duelCardCancel,
                      isSmall: true,
                      onPressed: onCancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------- in-progress card

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({required this.challenge, required this.opponentLabel});

  final DuelChallenge challenge;
  final String opponentLabel;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final creator = challenge.creator;
    final topic = challenge.topic;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: arena.chrome,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: arena.questionCardBorder),
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Avatar(emoji: creator.avatarEmoji, onArena: true),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(child: _NameAndRating(player: creator, onArena: true)),
                SizedBox(width: AppSpacing.sm.w),
                const _LiveBadge(),
              ],
            ),
            SizedBox(height: AppSpacing.sm.h),
            Row(
              children: [
                Text(topic.emoji, style: AppTypography.glyph(15.sp)),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Text(
                    '${topic.name} · ${l10n.duelCardInProgress(opponentLabel)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium!.copyWith(
                      color: arena.metaText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "● LIVE" — the dot pulses unless motion is reduced.
///
/// Stateful only for the pulse's [AnimationController] (ephemeral UI). A
/// ticker rather than a `flutter_animate` chain, so no start-up timer is
/// left pending behind a card that is built and thrown away quickly.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  static const double dotSize = 8;

  /// The dot fades down to this and back, once per [AppMotion.count].
  static const double dimOpacity = 0.35;

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.count,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(
            begin: 1,
            end: _LiveBadge.dimOpacity,
          ).animate(_pulse),
          child: Container(
            width: _LiveBadge.dotSize.w,
            height: _LiveBadge.dotSize.w,
            decoration: BoxDecoration(
              color: arena.liveDot,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs.w),
        Text(
          l10n.duelCardLive,
          style: textTheme.labelMedium!.copyWith(color: arena.onArena),
        ),
      ],
    );
  }
}

// --------------------------------------------------------- shared pieces

/// The white plate on its 4px hard ledge (`.opt` language), with an optional
/// border and a soft outer glow.
class _CardPlate extends StatelessWidget {
  const _CardPlate({required this.child, this.borderColor, this.glowColor});

  final Widget child;
  final Color? borderColor;
  final Color? glowColor;

  static const double borderWidth = 2;
  static const double glowBlur = 14;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final glow = glowColor;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: arena.cardPlate,
        borderRadius: AppRadius.cardAll,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: arena.cardLedge,
            offset: Offset(0, AppElevation.ledge.h),
          ),
          if (glow != null)
            BoxShadow(
              color: glow.withValues(alpha: 0.55),
              blurRadius: glowBlur.r,
            ),
        ],
      ),
      child: child,
    );
  }
}

class _CreatorHeader extends StatelessWidget {
  const _CreatorHeader({required this.player, required this.trailing});

  final DuelPlayer player;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(emoji: player.avatarEmoji),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(child: _NameAndRating(player: player)),
        SizedBox(width: AppSpacing.sm.w),
        trailing,
      ],
    );
  }
}

/// "Ayesha K." over "🥇 1,412 · Lv 7".
class _NameAndRating extends StatelessWidget {
  const _NameAndRating({required this.player, this.onArena = false});

  final DuelPlayer player;
  final bool onArena;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rating = [
      '${player.leagueEmoji} ${AppFormat.number(player.elo, l10n.localeName)}',
      if (player.topicLevel > 0) l10n.duelTopicLevel(player.topicLevel),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          player.displayName(l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall!.copyWith(
            color: onArena ? arena.onArena : arena.cardInk,
          ),
        ),
        Text(
          rating,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium!.copyWith(
            color: onArena ? arena.metaText : arena.cardInkMuted,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.emoji,
    this.size = defaultSize,
    this.onArena = false,
  });

  final String emoji;
  final double size;
  final bool onArena;

  static const double defaultSize = 40;
  static const double smallSize = 28;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onArena ? arena.chrome : arena.cardChip,
      ),
      child: Text(emoji, style: AppTypography.glyph((size / 2).sp)),
    );
  }
}

/// The topic plate: sub-category emoji on its tint, name and category.
class _TopicLine extends StatelessWidget {
  const _TopicLine({required this.topic, this.trailing});

  final DuelTopic topic;
  final Widget? trailing;

  static const double plateSize = 28;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: plateSize.w,
          height: plateSize.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppGradients.hex(topic.plateColor, fallback: arena.cardChip),
            borderRadius: BorderRadius.circular(AppRadius.medallion.r),
          ),
          child: Text(topic.emoji, style: AppTypography.glyph(15.sp)),
        ),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(
          child: Text(
            '${topic.name} · ${topic.categoryName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: arena.cardInk,
            ),
          ),
        ),
        if (trailing != null) ...[SizedBox(width: AppSpacing.sm.w), trailing!],
      ],
    );
  }
}

class _FairnessChip extends StatelessWidget {
  const _FairnessChip({required this.fairness});

  final Fairness fairness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (emoji, label) = switch (fairness) {
      Fairness.even => ('⚖️', l10n.duelFairnessEven),
      Fairness.tough => ('🔥', l10n.duelFairnessTough),
      Fairness.favourable => ('🟢', l10n.duelFairnessFavourable),
    };
    return _CardChip(emoji: emoji, label: label);
  }
}

class _AwayChip extends StatelessWidget {
  const _AwayChip();

  @override
  Widget build(BuildContext context) =>
      _CardChip(emoji: '💤', label: AppLocalizations.of(context).duelCardAway);
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: arena.cardChip,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: AppTypography.glyph(11.sp)),
          SizedBox(width: AppSpacing.xs.w),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(color: arena.cardInk),
          ),
        ],
      ),
    );
  }
}
