import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-39's "No one's around" card, which slides up once the server offers the
/// labelled practice bot (plan 017, UX §3).
///
/// The card is the arena's invariant white plate, so its buttons are pinned
/// to the light palette in both themes. Otherwise the dark theme's pale
/// "Keep searching" line text would sit on white.
class MatchmakingBotOffer extends StatelessWidget {
  const MatchmakingBotOffer({
    required this.topic,
    required this.onPlayBot,
    required this.onKeepSearching,
    super.key,
  });

  final DuelTopic topic;

  /// Null while the bot is being fetched, which disables the button.
  final VoidCallback? onPlayBot;
  final VoidCallback onKeepSearching;

  static const double _botPlateSize = 44;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final extension in theme.extensions.values)
            if (extension is! QuizooColors) extension,
          QuizooColors.light,
        ],
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base.w,
          AppSpacing.base.h,
          AppSpacing.base.w,
          AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: arena.cardPlate,
          borderRadius: AppRadius.cardAll,
          boxShadow: [
            BoxShadow(
              color: arena.cardLedge,
              offset: Offset(0, AppElevation.ledge.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _BotPlate(size: _botPlateSize.w),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Text(
                    l10n.duelBotOfferTitle('${topic.emoji} ${topic.name}'),
                    style: textTheme.titleMedium!.copyWith(
                      color: arena.cardInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              l10n.duelBotOfferBody,
              style: textTheme.bodyMedium!.copyWith(color: arena.cardInkMuted),
            ),
            SizedBox(height: AppSpacing.base.h),
            ChunkyButton(label: l10n.duelBotOfferPlay, onPressed: onPlayBot),
            SizedBox(height: AppSpacing.xs.h),
            ChunkyButton.line(
              label: l10n.duelKeepSearching,
              onPressed: onKeepSearching,
            ),
          ],
        ),
      ),
    );
  }
}

/// A 🤖 avatar with the BOT badge — a bot is never named without it
/// (bible §14).
class _BotPlate extends StatelessWidget {
  const _BotPlate({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: quizoo.s3,
            borderRadius: BorderRadius.circular(AppRadius.emojiPlate.r),
          ),
          child: Text('🤖', style: AppTypography.glyph(24.sp)),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          decoration: BoxDecoration(
            color: arena.botBadge,
            borderRadius: AppRadius.pillAll,
          ),
          child: Text(
            l10n.duelBotBadge,
            style: textTheme.labelSmall!.copyWith(
              color: AppColors.onGold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
