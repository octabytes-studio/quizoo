import 'package:flutter/material.dart';
import 'package:quizoo/core/share/share_links.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-53's three real destinations (plan 025), wired to [ShareLinks] exactly
/// once so every screen that presents a `ShareSheet` behaves identically:
///
/// * WhatsApp / X hand [text] to the external app and close the sheet once it
///   opens; a launch that fails leaves the sheet usable and shows
///   `commonShareFailed`.
/// * Copy puts [text] on the clipboard, closes the sheet and confirms with
///   `commonCopied` (the one transport that can never "fail").
///
/// [context] must be the presenting screen's context — the sheet sits on the
/// same navigator, so one `maybePop` closes it from here.
abstract final class ShareTargets {
  static List<ShareTarget> real({
    required BuildContext context,
    required String text,
  }) {
    return [
      ShareTarget(
        emoji: '💬',
        label: 'WhatsApp',
        onTap: () => _launchExternal(context, () => ShareLinks.whatsApp(text)),
      ),
      ShareTarget(
        emoji: '✖️',
        label: 'X',
        onTap: () => _launchExternal(context, () => ShareLinks.x(text)),
      ),
      ShareTarget(
        emoji: '🔗',
        label: 'Copy',
        onTap: () => _copy(context, text),
      ),
    ];
  }

  static Future<void> _launchExternal(
    BuildContext context,
    Future<bool> Function() launch,
  ) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final opened = await launch();
    if (!context.mounted) return;
    if (!opened) {
      AppSnackbar.show(
        context,
        title: l10n.commonShareFailed,
        intent: SnackbarIntent.error,
      );
      return;
    }
    navigator.maybePop();
  }

  static Future<void> _copy(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    await ShareLinks.copy(text);
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      title: l10n.commonCopied,
      intent: SnackbarIntent.success,
    );
    navigator.maybePop();
  }
}
