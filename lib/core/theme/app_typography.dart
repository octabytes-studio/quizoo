import 'package:flutter/material.dart';
import 'package:quizoo/core/theme/app_colors.dart';

/// The design bible's §04 type scale, expressed as a complete [TextTheme].
///
/// Every one of Material's fifteen slots is filled from a real value in
/// `.claude/docs/quizoo-design-bible.html` — nothing is left to Flutter's
/// Roboto defaults, and nothing is invented. The slot each bible style landed
/// on is named in the comment beside it, so a screen can keep using
/// `Theme.of(context).textTheme.titleLarge` and still be reading "Title
/// 22/26 Baloo 800" from the spec.
///
/// Sizes here are raw logical pixels against the 390×844 design size; call
/// sites scale them with `flutter_screenutil` (`.sp`) where a style needs to
/// track screen size.
abstract final class AppTypography {
  /// Display / headings / buttons / scores.
  static const String display = 'Baloo2';

  /// Body and UI text.
  static const String body = 'PlusJakartaSans';

  /// Meta and mono labels.
  static const String mono = 'JetBrainsMono';

  /// Urdu question and UI text.
  static const String urdu = 'NotoNastaliqUrdu';

  /// Fallbacks matching the bible's CSS font stacks, so a missing glyph
  /// (emoji, CJK, an Urdu diacritic) still resolves.
  static const List<String> displayFallback = [body, urdu];
  static const List<String> bodyFallback = [display, urdu];

  /// Scores, ranks, timers and leaderboard points stack vertically, so they
  /// always render with tabular figures (§04 rules).
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Urdu and Arabic need ~2.1 line-height and 4px more vertical padding in
  /// every button and option row. The line-height is applied by
  /// [localize]; this is the padding half of that rule, read by
  /// `ChunkyButton` and `AnswerOption` rather than by individual screens.
  static const double rtlExtraVerticalPadding = 4;

  /// Line-height ratio the bible specifies for Nastaliq text.
  static const double urduHeight = 2.1;

  /// A style for a bare glyph — an emoji plate, a ✓/✕ verdict mark, a ⭐ run.
  ///
  /// These carry no family, weight or colour of their own: the glyph *is* the
  /// content and only its size is a design decision. Routing them through one
  /// helper keeps that decision in the type file rather than scattering
  /// ad-hoc `TextStyle`s through the widget layer (CLAUDE.md §5), and gives
  /// one place to add a fallback family if a platform renders one badly.
  static TextStyle glyph(
    double size, {
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Display-family headings the bible does not size explicitly inherit
  /// Title's 26/22 ratio.
  static const double _displayHeight = 26 / 22;

  static TextTheme _textTheme(Color tx, Color tx2, Color tx3) {
    return TextTheme(
      // Display XL — 56/56 · −3% · Baloo 800. Level-complete score.
      displayLarge: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 56,
        height: 56 / 56,
        letterSpacing: -1.68,
        fontFeatures: tabular,
        color: tx,
      ),
      // Display L — 28/32 · −2% · Baloo 800. "Level complete!"
      displayMedium: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        height: 32 / 28,
        letterSpacing: -0.56,
        color: tx,
      ),
      // Timer numeral (`.timer .n`) — 23 · Baloo 800, tabular.
      displaySmall: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 23,
        height: 1,
        fontFeatures: tabular,
        color: tx,
      ),
      // Sheet / dialog title (`.sheet h3`, `.dlg h3`) — 21 · Baloo 800.
      headlineLarge: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 21,
        height: _displayHeight,
        color: tx,
      ),
      // Feedback banner heading (`.fb .hd b`) — 20 · Baloo 800.
      headlineMedium: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 20,
        height: _displayHeight,
        color: tx,
      ),
      // Question — 19/24 · Baloo 700. Wraps balanced, hard 3-line cap.
      headlineSmall: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w700,
        fontSize: 19,
        height: 24 / 19,
        color: tx,
      ),
      // Title — 22/26 · −2% · Baloo 800. Screen headers.
      titleLarge: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 22,
        height: 26 / 22,
        letterSpacing: -0.44,
        color: tx,
      ),
      // Section — 17/22 · Baloo 800. Section headers.
      titleMedium: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 17,
        height: 22 / 17,
        color: tx,
      ),
      // Popular-card title (`.pq b`) — 15.5 · Baloo 800.
      titleSmall: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 15.5,
        height: 1.12,
        color: tx,
      ),
      // Answer — 15/20 · Jakarta 700.
      bodyLarge: TextStyle(
        fontFamily: body,
        fontFamilyFallback: bodyFallback,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        height: 20 / 15,
        color: tx,
      ),
      // Body — 14/20 · Jakarta 400.
      bodyMedium: TextStyle(
        fontFamily: body,
        fontFamilyFallback: bodyFallback,
        fontSize: 14,
        height: 20 / 14,
        color: tx,
      ),
      // Sheet / dialog body (`.sheet p`, `.dlg p`) — 13 · 1.5 · Jakarta 400.
      bodySmall: TextStyle(
        fontFamily: body,
        fontFamilyFallback: bodyFallback,
        fontSize: 13,
        height: 1.5,
        color: tx2,
      ),
      // Button — 17.5/1 · +1% · Baloo 800.
      labelLarge: TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontWeight: FontWeight.w800,
        fontSize: 17.5,
        height: 1,
        letterSpacing: 0.175,
        color: tx,
      ),
      // Label — 11.5/14 · Jakarta 800.
      labelMedium: TextStyle(
        fontFamily: body,
        fontFamilyFallback: bodyFallback,
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        height: 14 / 11.5,
        color: tx2,
      ),
      // Meta — 10.5/13 · +4% · Jakarta 700. Never smaller than this, anywhere.
      labelSmall: TextStyle(
        fontFamily: body,
        fontFamilyFallback: bodyFallback,
        fontWeight: FontWeight.w700,
        fontSize: 10.5,
        height: 13 / 10.5,
        letterSpacing: 0.42,
        color: tx3,
      ),
    );
  }

  static TextTheme get light =>
      _textTheme(AppColors.lightTx, AppColors.lightTx2, AppColors.lightTx3);

  static TextTheme get dark =>
      _textTheme(AppColors.darkTx, AppColors.darkTx2, AppColors.darkTx3);

  /// Locales written in Nastaliq — Urdu today, Arabic and Persian when their
  /// translations land.
  static const Set<String> nastaliqLanguages = {'ur', 'ar', 'fa'};

  /// Re-families a [TextTheme] for Nastaliq scripts and opens the line-height
  /// to the ~2.1 the bible requires.
  ///
  /// Applied once in `app/app.dart`'s `MaterialApp.builder`, which is where
  /// the active locale first becomes readable — so screens never do this
  /// themselves, exactly as §04's "build this into the theme, not into
  /// individual screens" rule demands.
  static TextTheme localize(TextTheme base, Locale locale) {
    if (!nastaliqLanguages.contains(locale.languageCode)) return base;

    TextStyle? nastaliq(TextStyle? style) => style?.copyWith(
      fontFamily: urdu,
      fontFamilyFallback: const [body, display],
      height: urduHeight,
      // Nastaliq's own forms carry the emphasis; synthetic tracking on top of
      // them just breaks the joins.
      letterSpacing: 0,
    );

    return TextTheme(
      displayLarge: nastaliq(base.displayLarge),
      displayMedium: nastaliq(base.displayMedium),
      displaySmall: nastaliq(base.displaySmall),
      headlineLarge: nastaliq(base.headlineLarge),
      headlineMedium: nastaliq(base.headlineMedium),
      // Urdu question text drops to 17px (§04 type spec: Urdu question 17/36).
      headlineSmall: nastaliq(base.headlineSmall)?.copyWith(fontSize: 17),
      titleLarge: nastaliq(base.titleLarge)?.copyWith(fontSize: 19),
      titleMedium: nastaliq(base.titleMedium),
      titleSmall: nastaliq(base.titleSmall),
      // Options drop to 14px with a 2.0 line-height (`.app.rtl .opt`).
      bodyLarge: nastaliq(base.bodyLarge)?.copyWith(fontSize: 14, height: 2),
      bodyMedium: nastaliq(base.bodyMedium),
      bodySmall: nastaliq(base.bodySmall),
      labelLarge: nastaliq(base.labelLarge),
      labelMedium: nastaliq(base.labelMedium),
      labelSmall: nastaliq(base.labelSmall),
    );
  }
}
