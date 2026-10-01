import 'package:flutter/material.dart';
import 'package:quizoo/core/content_language/language_direction.dart';
import 'package:quizoo/core/theme/app_theme.dart';

/// Lays [child] out in the direction and script of [languageCode] — the
/// language the question content is in — instead of the UI locale's.
///
/// Wraps a play surface's question card and answer options, so an Urdu or
/// Arabic question reads right-to-left in Nastaliq (with `AnswerOption`'s
/// RTL keys and padding) even under an English UI, and an English question
/// stays left-to-right under an Urdu one. The HUD and other chrome around it
/// keep following the UI locale.
class ContentLanguageScope extends StatelessWidget {
  const ContentLanguageScope({
    required this.languageCode,
    required this.child,
    super.key,
  });

  final String languageCode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirectionFor(languageCode),
      child: Theme(
        data: AppTheme.forContent(
          Theme.of(context),
          uiLocale: Localizations.localeOf(context),
          contentLocale: Locale(languageCode),
        ),
        child: child,
      ),
    );
  }
}
