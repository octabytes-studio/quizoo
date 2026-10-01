import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The small "Advertisement" caption above an in-content ad, so an ad is
/// never mistaken for the app's own content.
class AdLabel extends StatelessWidget {
  const AdLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).adLabel,
      style: Theme.of(
        context,
      ).textTheme.labelSmall!.copyWith(color: context.quizoo.tx3),
    );
  }
}
