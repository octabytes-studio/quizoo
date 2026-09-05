import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// Assembles the light and dark [ThemeData] from the token files.
///
/// Nothing here invents a value: colours come from [AppColors]/[QuizooColors],
/// type from [AppTypography], radii from [AppRadius]. The two themes are built
/// by one function so a component theme added for light mode cannot ship
/// without its dark counterpart (CLAUDE.md §5).
abstract final class AppTheme {
  static ThemeData get light => _build(
    scheme: AppColors.lightScheme,
    quizoo: QuizooColors.light,
    textTheme: AppTypography.light,
  );

  static ThemeData get dark => _build(
    scheme: AppColors.darkScheme,
    quizoo: QuizooColors.dark,
    textTheme: AppTypography.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required QuizooColors quizoo,
    required TextTheme textTheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      // §03: the app background is `--s0`, which is deliberately not the same
      // as the card surface `--s1` that ColorScheme.surface carries.
      scaffoldBackgroundColor: quizoo.s0,
      canvasColor: quizoo.s0,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[quizoo, const ArenaColors()],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: quizoo.tx),
        // Every screen draws behind the status bar (§05), so the bar itself is
        // transparent and only its icon brightness is set per route.
        systemOverlayStyle: scheme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      dividerTheme: DividerThemeData(color: quizoo.ln, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: quizoo.tx2),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: quizoo.s1,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: quizoo.s1,
        modalBarrierColor: quizoo.ov,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: quizoo.s1,
        surfaceTintColor: Colors.transparent,
        barrierColor: quizoo.ov,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogAll),
        titleTextStyle: textTheme.headlineLarge,
        contentTextStyle: textTheme.bodySmall,
      ),
      // The app never uses Material's own SnackBar chrome — AppSnackbar draws
      // the bible's four intents — but the theme is set so a stray framework
      // snackbar at least lands in-palette rather than in Material purple.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: quizoo.tx,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: quizoo.s1),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.snackbar)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: quizoo.g,
        linearTrackColor: quizoo.s3,
        circularTrackColor: quizoo.s3,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: quizoo.g,
        selectionColor: quizoo.g.withValues(alpha: 0.28),
        selectionHandleColor: quizoo.g,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : quizoo.s1,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? quizoo.ok : quizoo.s3,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : quizoo.ln,
        ),
      ),
    );
  }

  /// Applies the locale-dependent half of the type system — Nastaliq families
  /// and their taller line-height for Urdu/Arabic.
  ///
  /// Called from `MaterialApp.builder`, the first place below `Localizations`
  /// where the active locale is readable.
  static ThemeData localize(ThemeData theme, Locale locale) {
    final localized = AppTypography.localize(theme.textTheme, locale);
    if (identical(localized, theme.textTheme)) return theme;
    return theme.copyWith(
      textTheme: localized,
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: localized.titleLarge,
      ),
      dialogTheme: theme.dialogTheme.copyWith(
        titleTextStyle: localized.headlineLarge,
        contentTextStyle: localized.bodySmall,
      ),
    );
  }
}
