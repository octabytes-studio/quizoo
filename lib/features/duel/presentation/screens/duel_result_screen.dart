import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/navigation/badge_celebration.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/native_ad_tile.dart';
import 'package:quizoo/core/widgets/result_wash.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/data/live_duel_api.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/presentation/bloc/bot_rematch_cubit.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_rematch_cubit.dart';
import 'package:quizoo/features/duel/presentation/screens/bot_duel_args.dart';
import 'package:quizoo/features/duel/presentation/widgets/bot_rematch_button.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_topic_picker_sheet.dart';
import 'package:quizoo/features/duel/presentation/widgets/rematch_actions.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-41 — the duel result: victory, defeat and draw rendered from **one**
/// parameterized screen (plan 004, Research findings: "identical in
/// structure … build both from one parameterized screen/widget, not two
/// separate files").
///
/// Plan 017 (Phase 11) makes it serve live duels too: the real players'
/// avatars, the unranked note and forfeit captions, and a two-sided rematch
/// handshake ([DuelRematchCubit]). After a practice-bot duel, "Rematch"
/// deals a fresh bot in the same topic ([BotRematchCubit]) instead.
///
/// A `StatefulWidget` so it can run the same post-frame celebration chain as
/// `LevelCompleteScreen` — every newly-earned badge in [result] gets its own
/// S-23 celebration, not just the first (plan 014).
class DuelResultScreen extends StatefulWidget {
  const DuelResultScreen({
    super.key,
    this.result,
    @visibleForTesting this.rematchCubit,
    @visibleForTesting this.botRematchCubit,
  });

  final DuelResult? result;

  /// Replaces the live rematch handshake a live result builds for itself.
  final DuelRematchCubit? rematchCubit;

  /// Replaces the bot-rematch dealer a bot result builds for itself.
  final BotRematchCubit? botRematchCubit;

  /// What a design-review visit (no `extra`) renders.
  static const DuelResult _fallback = DuelResult(
    me: DuelPlayer(id: 'me', name: null, avatarEmoji: '🐼', elo: 1200),
    opponent: DuelPlayer(
      id: 'bot_review',
      name: 'Fennec',
      avatarEmoji: '🦊',
      elo: 1180,
      isBot: true,
    ),
    playerRoundsWon: 3,
    opponentRoundsWon: 2,
    playerAverageAnswerSeconds: 4.2,
    opponentAverageAnswerSeconds: 5.6,
    eloBefore: 1200,
    eloAfter: 1218,
    rewardCoins: 200,
  );

  @override
  State<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends State<DuelResultScreen> {
  DuelResult get _result => widget.result ?? DuelResultScreen._fallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChain());
  }

  Future<void> _runChain() async {
    await celebrateBadges(context, _result.newlyEarnedBadgeIds);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final liveDuelId = result.isBot ? null : result.duelId;

    if (liveDuelId != null) {
      final view = BlocListener<DuelRematchCubit, DuelRematchState>(
        listener: (context, state) {
          if (state is RematchStarting) {
            context.pushReplacement(AppRoutes.duelPlayPath(state.duelId));
          }
        },
        child: _DuelResultView(
          result: result,
          rematch: RematchActions(
            opponentName: result.opponent.displayName(
              AppLocalizations.of(context),
            ),
          ),
        ),
      );
      final injected = widget.rematchCubit;
      return injected != null
          ? BlocProvider<DuelRematchCubit>.value(value: injected, child: view)
          : BlocProvider<DuelRematchCubit>(
              create: (context) => DuelRematchCubit(
                LiveDuelRepository(
                  LiveDuelApi(supabase, context.read<DuelRealtime>()),
                  context.read<ServerClock>(),
                ),
                duelId: liveDuelId,
                opponent: result.opponent,
                window: Duration(
                  seconds: DuelConfig.fallback.rematchWindowSeconds,
                ),
              ),
              child: view,
            );
    }

    if (result.isBot) {
      final view = BlocListener<BotRematchCubit, BotRematchState>(
        listener: (context, state) {
          switch (state) {
            case BotRematchFound(:final me, :final opponent, :final topic):
              context.pushReplacement(
                AppRoutes.duelBot,
                extra: BotDuelArgs(me: me, opponent: opponent, topic: topic),
              );
            case BotRematchFailed():
              AppSnackbar.show(
                context,
                title: AppLocalizations.of(context).duelNoticeGeneric,
                intent: SnackbarIntent.error,
              );
            case BotRematchIdle() || BotRematchLoading():
              break;
          }
        },
        child: _DuelResultView(
          result: result,
          rematch: BotRematchButton(topic: result.topic),
        ),
      );
      final injected = widget.botRematchCubit;
      return injected != null
          ? BlocProvider<BotRematchCubit>.value(value: injected, child: view)
          : BlocProvider<BotRematchCubit>(
              create: (_) => BotRematchCubit(
                DuelRepository(DuelApi(supabase)),
                previous: result,
              ),
              child: view,
            );
    }

    // A live result without a duel id has nothing to rematch.
    return _DuelResultView(result: result, rematch: null);
  }
}

/// The result itself — headline, scoreline, captions and stats — over the
/// rematch control a provider above supplied.
///
/// A `StatefulWidget` only for [_DuelResultViewState._isLeaving], the
/// re-entrancy guard on its two exits.
class _DuelResultView extends StatefulWidget {
  const _DuelResultView({required this.result, required this.rematch});

  final DuelResult result;

  /// Null when there is nothing to rematch.
  final Widget? rematch;

  @override
  State<_DuelResultView> createState() => _DuelResultViewState();
}

class _DuelResultViewState extends State<_DuelResultView> {
  /// True while an exit is in flight (an interstitial may be up) — a second
  /// tap on either exit is ignored. Ephemeral UI state, never rendered.
  bool _isLeaving = false;

  /// The match is over and nothing is time-critical yet, so leaving is a
  /// natural break for an interstitial (plan 022, I2). **Rematches never
  /// come through here**: a live rematch has a server-side window and a
  /// synced clock, so nothing full-screen may sit in its way.
  Future<void> _showBreakAd() => context.read<AdsCubit>().showInterstitialIfDue(
    AdPlacement.duelResultBreak,
    isCelebration: widget.result.newlyEarnedBadgeIds.isNotEmpty,
  );

  Future<void> _close() async {
    if (_isLeaving) return;
    _isLeaving = true;
    await _showBreakAd();
    if (!mounted) return;
    _isLeaving = false;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Matchmaking in the same topic; a result without one asks first, and a
  /// dismissed picker stays here.
  Future<void> _findNewOpponent() async {
    if (_isLeaving) return;
    _isLeaving = true;
    final topic =
        widget.result.topic ??
        await DuelTopicPickerSheet.show(
          context,
          purpose: DuelTopicPurpose.matchmake,
        );
    if (!mounted) return;
    if (topic == null) {
      _isLeaving = false;
      return;
    }
    await _showBreakAd();
    if (!mounted) return;
    _isLeaving = false;
    context.pushReplacement(AppRoutes.duelMatchmaking, extra: topic);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final rematch = widget.rematch;
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isDefeat = !result.isVictory && !result.isDraw;
    final (glyph, title, accent) = switch ((result.isVictory, result.isDraw)) {
      (true, _) => ('🏆', l10n.duelResultVictoryTitle, quizoo.ok),
      (false, true) => ('⚖️', l10n.duelResultDrawTitle, quizoo.info),
      (false, false) => ('🤝', l10n.duelResultDefeatTitle, quizoo.bad),
    };
    final forfeitCaption = switch (result.endReason) {
      DuelEndReason.completed => null,
      DuelEndReason.opponentForfeited => l10n.duelResultOpponentForfeit(
        result.opponent.displayName(l10n),
      ),
      DuelEndReason.youForfeited => l10n.duelResultYouForfeited,
    };
    final rematchControl = rematch;

    return ResultWash(
      accent: accent,
      onClose: _close,
      actions: [
        if (rematchControl != null) ...[
          rematchControl,
          SizedBox(height: AppSpacing.sm.h),
        ],
        ChunkyButton.line(
          label: l10n.duelResultFindNew,
          onPressed: _findNewOpponent,
        ),
      ],
      child: Column(
        children: [
          Text(glyph, style: AppTypography.glyph(52.sp)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 27.sp,
              color: Colors.white,
            ),
          ),
          if (forfeitCaption != null) _ResultCaption(text: forfeitCaption),
          if (!result.isRanked)
            _ResultCaption(text: l10n.duelResultUnrankedShort),
          SizedBox(height: AppSpacing.md.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBadge(
                player: result.me,
                isWinner: result.isVictory,
                score: result.playerRoundsWon,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                child: Text(
                  '–',
                  style: textTheme.displayMedium!.copyWith(color: Colors.white),
                ),
              ),
              _AvatarBadge(
                player: result.opponent,
                isWinner: isDefeat,
                score: result.opponentRoundsWon,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.base.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              color: quizoo.s1,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              boxShadow: quizoo.shadow,
            ),
            child: Column(
              children: [
                _StatRow(
                  label: l10n.duelResultRoundsWon,
                  value:
                      '${result.playerRoundsWon} – ${result.opponentRoundsWon}',
                ),
                Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                _StatRow(
                  label: l10n.duelResultAvgTime,
                  value: l10n.duelResultAvgTimeValue(
                    result.playerAverageAnswerSeconds.toStringAsFixed(1),
                    result.opponentAverageAnswerSeconds.toStringAsFixed(1),
                  ),
                ),
                Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                _StatRow(
                  label: l10n.duelResultElo,
                  value: '${result.eloBefore} → ${result.eloAfter}',
                  valueColor: result.eloDelta >= 0 ? quizoo.ok : quizoo.bad,
                ),
                Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                _StatRow(
                  label: l10n.duelResultReward,
                  value: '+${result.rewardCoins} 🪙',
                  valueColor: quizoo.gold,
                ),
                if (result.xpEarned > 0) ...[
                  Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                  _StatRow(
                    label: l10n.duelResultXp,
                    value: '+${result.xpEarned}',
                    valueColor: quizoo.g,
                  ),
                ],
              ],
            ),
          ),
          NativeAdTile(
            placement: AdPlacement.duelResultNative,
            padding: EdgeInsets.only(top: AppSpacing.base.h),
          ),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}

/// A line of context under the headline — a forfeit, or an unranked duel.
class _ResultCaption extends StatelessWidget {
  const _ResultCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// One side of the scoreline: the player's own avatar and name, a BOT tag
/// for the practice bot (never a secret one — bible §14), and rounds won.
class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.player,
    required this.isWinner,
    required this.score,
  });

  final DuelPlayer player;
  final bool isWinner;
  final int score;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 104.w,
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: isWinner
                    ? quizoo.gold
                    : Colors.white.withValues(alpha: 0.4),
                width: isWinner ? 3 : 2,
              ),
            ),
            child: Text(player.avatarEmoji, style: AppTypography.glyph(30.sp)),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            player.displayName(l10n),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium!.copyWith(color: Colors.white),
          ),
          if (player.isBot)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs.h),
              child: AppChip.status(label: l10n.duelBotBadge, leading: '🤖'),
            ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            '$score',
            style: textTheme.displayMedium!.copyWith(
              fontSize: 20.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium!.copyWith(color: quizoo.tx2),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? quizoo.tx,
          ),
        ),
      ],
    );
  }
}
