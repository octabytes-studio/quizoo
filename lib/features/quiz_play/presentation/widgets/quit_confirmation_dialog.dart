import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-18 — the quit confirmation.
///
/// It states the cost in the player's **own live numbers**, not in general
/// terms, and the destructive action is second and never pre-focused. "Keep
/// playing" is first and dominant.
class QuitConfirmationDialog extends StatelessWidget {
  const QuitConfirmationDialog({
    required this.run,
    required this.onKeepPlaying,
    required this.onQuit,
    super.key,
  });

  final QuizRun run;
  final VoidCallback onKeepPlaying;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return AppDialog(
      emoji: '😬',
      iconPlateColor: quizoo.badBg,
      title: l10n.quitTitle(run.levelNumber),
      message: l10n.quitBody(
        run.answers.length,
        AppFormat.number(run.score, localeName),
      ),
      actions: [
        ChunkyButton.ghost(
          label: l10n.quitKeepPlaying,
          onPressed: onKeepPlaying,
        ),
        SizedBox(height: 9.h),
        _DestructiveButton(label: l10n.quitConfirm, onPressed: onQuit),
      ],
    );
  }
}

/// A raspberry-filled [ChunkyButton], for the one action on this screen that
/// costs the player something.
class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    // The primary variant already paints itself in mango and its ledge in
    // mango-shadow; swapping those two tokens is what makes it destructive
    // without a second button widget or a bag of colour parameters.
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [quizoo.copyWith(p: quizoo.bad, pShadow: quizoo.badShadow)],
      ),
      child: ChunkyButton(label: label, onPressed: onPressed),
    );
  }
}
