import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-19 — out of lives.
///
/// **Never a hard wall.** The free option is listed first and is visually the
/// loudest, the paid one is second, and leaving is always available. The
/// refill time is a **clock time**, not "in 28 minutes", so it stays true if
/// the app is backgrounded.
class OutOfLivesDialog extends StatelessWidget {
  const OutOfLivesDialog({
    required this.state,
    required this.onWatchAd,
    required this.onRefill,
    required this.onBackToMap,
    super.key,
  });

  final QuizPlayOutOfLives state;
  final VoidCallback onWatchAd;
  final VoidCallback onRefill;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return AppDialog(
      emoji: '💔',
      iconPlateColor: quizoo.badBg,
      title: l10n.outOfLivesTitle,
      message: l10n.outOfLivesBody(
        AppFormat.clock(state.heartRefillAt, localeName),
      ),
      actions: [
        ChunkyButton.gold(
          label: state.isWatchingAd
              ? l10n.outOfLivesAdPlaying
              : l10n.outOfLivesWatchAd,
          onPressed: state.isWatchingAd ? null : onWatchAd,
        ),
        SizedBox(height: 9.h),
        ChunkyButton(
          label: l10n.outOfLivesRefill(MockPlayer.refillCost),
          subLabel: state.canAffordRefill
              ? null
              : l10n.outOfLivesNotEnoughCoins,
          onPressed: state.canAffordRefill ? onRefill : null,
        ),
        SizedBox(height: 9.h),
        ChunkyButton.line(
          label: l10n.outOfLivesBackToMap,
          onPressed: onBackToMap,
        ),
      ],
    );
  }
}
