import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

/// The real S-53 share transports (plan 025): WhatsApp, X and the clipboard.
///
/// The sheet and its preview stay owned by whichever feature presents them;
/// this class is only "how a text reaches each destination" — no new share
/// package, just the `url_launcher` + `Clipboard` the app already ships.
///
/// Every method returns whether the destination actually opened, so callers
/// pick their own feedback (`commonCopied`, `commonShareFailed`) rather than
/// this layer knowing about snackbars.
abstract final class ShareLinks {
  /// Pure URI builders, public so a test can assert the exact URLs without
  /// launching anything.
  static Uri whatsAppUri(String text) =>
      Uri.https('wa.me', '/', {'text': text});

  static Uri xUri(String text) =>
      Uri.https('x.com', '/intent/post', {'text': text});

  static Future<bool> whatsApp(String text) => _launch(whatsAppUri(text));

  static Future<bool> x(String text) => _launch(xUri(text));

  static Future<bool> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
