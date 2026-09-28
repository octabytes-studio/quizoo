import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/bot_rematch_cubit.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_topic_picker_sheet.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-41's "Rematch" after a practice-bot duel (plan 017, Phase 11): deals a
/// new bot through [BotRematchCubit], in [topic] — or, when the finished duel
/// carried none (a design-review visit), in whatever topic the picker
/// returns. A dismissed picker does nothing.
class BotRematchButton extends StatelessWidget {
  const BotRematchButton({required this.topic, super.key});

  /// The finished duel's topic, reused for the rematch.
  final DuelTopic? topic;

  Future<void> _rematch(BuildContext context) async {
    final picked =
        topic ??
        await DuelTopicPickerSheet.show(
          context,
          purpose: DuelTopicPurpose.matchmake,
        );
    if (picked == null || !context.mounted) return;
    await context.read<BotRematchCubit>().rematch(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<BotRematchCubit, BotRematchState>(
      builder: (context, state) => switch (state) {
        BotRematchIdle() || BotRematchFailed() => ChunkyButton(
          label: l10n.duelResultRematch,
          onPressed: () => _rematch(context),
        ),
        BotRematchLoading() || BotRematchFound() => SizedBox(
          height: ChunkyButton.height.h + AppElevation.ledge.h,
          child: Center(
            child: SizedBox.square(
              dimension: 28.w,
              child: CircularProgressIndicator(
                color: context.quizoo.p,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      },
    );
  }
}
