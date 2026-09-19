import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';

/// Pushes S-23 once per id in [badgeIds], in order, awaiting each screen's
/// dismissal before pushing the next. A no-op for an empty list.
///
/// Shared by level-complete, duel-result, and daily-result screens
/// (CLAUDE.md §2/§10: reused by 3+ features, so it lives in `core/`) —
/// every gameplay flow that can unlock a badge celebrates all of them, not
/// just the first.
Future<void> celebrateBadges(
  BuildContext context,
  List<String> badgeIds,
) async {
  for (final badgeId in badgeIds) {
    if (!context.mounted) return;
    await context.push(AppRoutes.badgeUnlockedPath(badgeId));
  }
}
