import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// A duel play surface that could not start — the bot duel with no topic,
/// or a live duel that failed to load (not found, not a participant,
/// offline). One way out: Back.
class DuelErrorView extends StatelessWidget {
  const DuelErrorView({super.key, this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '⚔️',
        message: l10n.contentErrorBody,
        errorCode: errorCode,
        action: ChunkyButton.ghost(
          label: l10n.commonBack,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
