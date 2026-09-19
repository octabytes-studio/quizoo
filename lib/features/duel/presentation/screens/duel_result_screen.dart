import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/navigation/badge_celebration.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/result_wash.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-41 — the duel result, victory and defeat rendered from **one**
/// parameterized screen (plan 004, Research findings: "identical in
/// structure … build both from one parameterized screen/widget, not two
/// separate files").
///
/// A `StatefulWidget` so it can run the same post-frame celebration chain as
/// `LevelCompleteScreen` — every newly-earned badge in [result] gets its own
/// S-23 celebration, not just the first (plan 014).
class DuelResultScreen extends StatefulWidget {
  const DuelResultScreen({super.key, this.result});

  final DuelResult? result;

  static const DuelResult _fallback = DuelResult(
    opponent: DuelOpponent(
      id: 'bot_review',
      name: 'Fennec',
      avatarEmoji: '🦊',
      elo: 1240,
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChain());
  }

  Future<void> _runChain() async {
    final effective = widget.result ?? DuelResultScreen._fallback;
    await celebrateBadges(context, effective.newlyEarnedBadgeIds);
  }

  @override
  Widget build(BuildContext context) {
    final effective = widget.result ?? DuelResultScreen._fallback;
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isVictory = effective.isVictory;

    void rematch() => context.pushReplacement(AppRoutes.duelMatchmaking);
    void findNew() => context.pushReplacement(AppRoutes.duelMatchmaking);

    return ResultWash(
      accent: isVictory ? quizoo.ok : quizoo.bad,
      onClose: () => context.go(AppRoutes.home),
      actions: [
        ChunkyButton(label: l10n.duelResultRematch, onPressed: rematch),
        SizedBox(height: 9.h),
        ChunkyButton.line(label: l10n.duelResultFindNew, onPressed: findNew),
      ],
      child: Column(
        children: [
          Text(isVictory ? '🏆' : '🤝', style: AppTypography.glyph(52.sp)),
          Text(
            isVictory
                ? l10n.duelResultVictoryTitle
                : l10n.duelResultDefeatTitle,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 27.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AvatarBadge(
                emoji: '🐼',
                isWinner: isVictory,
                score: effective.playerRoundsWon,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                child: Text(
                  '–',
                  style: textTheme.displayMedium!.copyWith(color: Colors.white),
                ),
              ),
              _AvatarBadge(
                emoji: effective.opponent.avatarEmoji,
                isWinner: !isVictory,
                score: effective.opponentRoundsWon,
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
                      '${effective.playerRoundsWon} – ${effective.opponentRoundsWon}',
                ),
                Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                _StatRow(
                  label: l10n.duelResultAvgTime,
                  value: l10n.duelResultAvgTimeValue(
                    effective.playerAverageAnswerSeconds.toStringAsFixed(1),
                    effective.opponentAverageAnswerSeconds.toStringAsFixed(1),
                  ),
                ),
                Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                _StatRow(
                  label: l10n.duelResultElo,
                  value: '${effective.eloBefore} → ${effective.eloAfter}',
                  valueColor: effective.eloDelta >= 0 ? quizoo.ok : quizoo.bad,
                ),
                Divider(height: AppSpacing.lg.h, color: quizoo.ln),
                _StatRow(
                  label: l10n.duelResultReward,
                  value: '+${effective.rewardCoins} 🪙',
                  valueColor: quizoo.gold,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.emoji,
    required this.isWinner,
    required this.score,
  });

  final String emoji;
  final bool isWinner;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  ? const Color(0xFFFFC61A)
                  : Colors.white.withValues(alpha: 0.4),
              width: isWinner ? 3 : 2,
            ),
          ),
          child: Text(emoji, style: AppTypography.glyph(30.sp)),
        ),
        SizedBox(height: 4.h),
        Text(
          '$score',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
            fontSize: 20.sp,
            color: Colors.white,
          ),
        ),
      ],
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
