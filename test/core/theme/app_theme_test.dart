import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

void main() {
  group('AppTheme', () {
    test('both themes carry the Quizoo and Arena extensions', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.extension<QuizooColors>(), isNotNull);
        expect(theme.extension<ArenaColors>(), isNotNull);
      }
    });

    test('the scaffold background is s0, not the card surface s1', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.lightS0);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkS0);
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        isNot(AppTheme.light.colorScheme.surface),
      );
    });

    test('every TextTheme slot is filled from a bible family', () {
      const families = {
        AppTypography.display,
        AppTypography.body,
        AppTypography.mono,
        AppTypography.urdu,
      };

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final text = theme.textTheme;
        final slots = <TextStyle?>[
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ];

        for (final style in slots) {
          expect(style, isNotNull);
          // Nothing may fall through to Flutter's Roboto default.
          expect(families, contains(style!.fontFamily));
          // §04: never below 10.5px, anywhere.
          expect(style.fontSize, greaterThanOrEqualTo(10.5));
        }
      }
    });

    test('stacking numerals use tabular figures', () {
      final text = AppTheme.light.textTheme;
      expect(text.displayLarge!.fontFeatures, AppTypography.tabular);
      expect(text.displaySmall!.fontFeatures, AppTypography.tabular);
    });

    test('the arena palette is identical in light and dark', () {
      final light = AppTheme.light.extension<ArenaColors>()!;
      final dark = AppTheme.dark.extension<ArenaColors>()!;

      // §09: the arena is "the one place the app commits to a single look".
      expect(light.base.colors, dark.base.colors);
      expect(light.danger.colors, dark.danger.colors);
      expect(light.onArena, dark.onArena);
    });

    test('a light↔dark lerp never moves the arena', () {
      const arena = ArenaColors();
      expect(
        arena.lerp(const ArenaColors(), 0.5).base.colors,
        arena.base.colors,
      );
    });

    test('QuizooColors differs between the two themes', () {
      final light = AppTheme.light.extension<QuizooColors>()!;
      final dark = AppTheme.dark.extension<QuizooColors>()!;

      expect(light.s0, isNot(dark.s0));
      expect(light.tx, isNot(dark.tx));
      expect(light.p, isNot(dark.p));
    });

    test('localize swaps to Nastaliq for Urdu and leaves English alone', () {
      final english = AppTheme.localize(AppTheme.light, const Locale('en'));
      expect(
        english.textTheme.headlineSmall!.fontFamily,
        AppTypography.display,
      );

      final urdu = AppTheme.localize(AppTheme.light, const Locale('ur'));
      expect(urdu.textTheme.headlineSmall!.fontFamily, AppTypography.urdu);
      // §04: Urdu needs ~2.1 line-height, and the question drops to 17px.
      expect(urdu.textTheme.headlineSmall!.height, AppTypography.urduHeight);
      expect(urdu.textTheme.headlineSmall!.fontSize, 17);
    });
  });
}
