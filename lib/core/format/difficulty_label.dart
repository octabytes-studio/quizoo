import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// §19's band names, resolved from the enum the taxonomy stores. Lives in
/// `core/` (plan 020) because both `features/catalog` and
/// `features/topic_mastery` need it.
String difficultyLabel(AppLocalizations l10n, DifficultyBand band) =>
    switch (band) {
      DifficultyBand.warmUp => l10n.difficultyEasy,
      DifficultyBand.steady => l10n.difficultyMedium,
      DifficultyBand.sharp => l10n.difficultyHard,
    };
