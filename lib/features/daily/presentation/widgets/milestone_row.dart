import 'package:flutter/material.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';

/// One row of S-27's "Milestones" list — an upcoming streak-length reward.
class MilestoneRow extends StatelessWidget {
  const MilestoneRow({required this.milestone, super.key});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    return ListRowTile(
      title: milestone.title,
      subtitle: '${milestone.daysAway} days away · ${milestone.rewardLabel}',
      leadingEmoji: '🎖️',
    );
  }
}
