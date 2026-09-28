import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One topic in the duel topic picker (plan 017, "Topic picker sheet"): the
/// sub-category's emoji plate, its name, "Lv 4" once the player has cleared
/// levels there, and "🔥 3 searching" / "⚔️ 2 open" when others are active.
class DuelTopicRow extends StatelessWidget {
  const DuelTopicRow({required this.topic, required this.onTap, super.key});

  final DuelTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return ListRowTile(
      title: topic.name,
      subtitle: topic.myTopicLevel > 0
          ? l10n.duelTopicLevel(topic.myTopicLevel)
          : null,
      leadingEmoji: topic.emoji,
      leadingPlateColor: AppGradients.hex(
        topic.plateColor,
        fallback: quizoo.s3,
      ),
      trailing: topic.hasActivity
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topic.searching > 0)
                  AppChip.status(
                    leading: '🔥',
                    label: l10n.duelPickerSearching(topic.searching),
                  ),
                if (topic.searching > 0 && topic.openChallenges > 0)
                  SizedBox(height: 4.h),
                if (topic.openChallenges > 0)
                  AppChip.status(
                    leading: '⚔️',
                    label: l10n.duelPickerOpen(topic.openChallenges),
                  ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}
