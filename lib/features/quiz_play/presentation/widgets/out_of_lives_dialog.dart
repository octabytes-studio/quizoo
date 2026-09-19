import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/heart_ad_cubit.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-19 — out of lives.
///
/// **Never a hard wall.** The free option is listed first and is visually the
/// loudest; leaving is always available. Hearts simply reset to 3 the next
/// time this level is started — the copy makes no claim about a refill timer.
class OutOfLivesDialog extends StatelessWidget {
  const OutOfLivesDialog({
    required this.state,
    required this.onBackToMap,
    super.key,
  });

  final QuizPlayOutOfLives state;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<HeartAdCubit, HeartAdState>(
      listener: (context, adState) {
        if (adState is HeartAdFailed) {
          AppSnackbar.show(
            context,
            title: l10n.outOfLivesAdFailedTitle,
            message: l10n.commonRetry,
            intent: SnackbarIntent.error,
          );
        }
        if (adState is HeartAdSucceeded) {
          context.read<QuizPlayCubit>().grantHeartFromAd();
        }
      },
      builder: (context, adState) {
        final watch = context.read<HeartAdCubit>().watch;
        final (String label, VoidCallback? onPressed) = switch (adState) {
          HeartAdReady() => (l10n.outOfLivesWatchAd, watch),
          HeartAdLoading() => (l10n.outOfLivesAdLoading, null),
          HeartAdPlaying() => (l10n.outOfLivesAdPlaying, null),
          HeartAdSucceeded() => (l10n.outOfLivesAdPlaying, null),
          HeartAdFailed() => (l10n.outOfLivesWatchAd, watch),
        };

        return AppDialog(
          emoji: '💔',
          iconPlateColor: quizoo.badBg,
          title: l10n.outOfLivesTitle,
          message: l10n.outOfLivesBody,
          actions: [
            ChunkyButton.gold(label: label, onPressed: onPressed),
            SizedBox(height: 9.h),
            ChunkyButton.line(
              label: l10n.outOfLivesBackToMap,
              onPressed: onBackToMap,
            ),
          ],
        );
      },
    );
  }
}
