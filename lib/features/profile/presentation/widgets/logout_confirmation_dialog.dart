import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-32 — the logout confirmation, shown from the You screen's own logout
/// button (signed-in players only).
///
/// Mirrors `QuitConfirmationDialog`'s shape: the safe choice ("Stay signed
/// in") is first and dominant, the destructive one is second and never
/// pre-focused.
class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return AppDialog(
      emoji: '👋',
      iconPlateColor: quizoo.badBg,
      title: l10n.profileLogoutTitle,
      message: l10n.profileLogoutBody,
      actions: [
        ChunkyButton.ghost(
          label: l10n.profileLogoutCancel,
          onPressed: onCancel,
        ),
        SizedBox(height: 9.h),
        ChunkyButton.danger(
          label: l10n.profileLogoutConfirm,
          onPressed: onConfirm,
        ),
      ],
    );
  }
}
