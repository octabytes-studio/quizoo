import 'package:flutter/material.dart';

/// Raw palette constants transcribed verbatim from the Quizoo Design Bible v1.0
/// (`.claude/docs/quizoo-design-bible.html`, §03 Color — the `.app` /
/// `.app[data-app="dark"]` CSS custom-property blocks).
///
/// Nothing in a feature should reach for these directly. Read the semantic
/// tokens off [QuizooColors] (`context.quizoo`) or the [ColorScheme] instead —
/// these are the source values those are assembled from.
abstract final class AppColors {
  // ---------------------------------------------------------------- light
  /// App background. Never pure white — it reads as cheap.
  static const Color lightS0 = Color(0xFFF3F0FC);

  /// Card / sheet surface.
  static const Color lightS1 = Color(0xFFFFFFFF);

  /// Raised / selected surface.
  static const Color lightS2 = Color(0xFFF8F6FE);

  /// Sunken surface / progress track.
  static const Color lightS3 = Color(0xFFEDE8FA);

  static const Color lightTx = Color(0xFF1B1438);
  static const Color lightTx2 = Color(0xFF6E668C);
  static const Color lightTx3 = Color(0xFF9E97B8);
  static const Color lightLn = Color(0xFFE7E2F5);

  /// Mango — primary CTA, FAB, timer ring, level "now" node.
  static const Color lightP = Color(0xFFFF8A24);
  static const Color lightPd = Color(0xFFF06E00);
  static const Color lightPsh = Color(0xFFC85800);

  /// Grape — brand, XP bar, active tab, links.
  static const Color lightG = Color(0xFF7B4DFF);
  static const Color lightGsh = Color(0xFF5A2CD8);

  /// Mint — correct answer, success, completed nodes.
  static const Color lightOk = Color(0xFF12C79B);
  static const Color lightOkSh = Color(0xFF0A9A77);
  static const Color lightOkBg = Color(0xFFE2F9F2);

  /// Raspberry — wrong answer, lives lost, destructive.
  static const Color lightBad = Color(0xFFFF3D6E);
  static const Color lightBadSh = Color(0xFFD31C4C);
  static const Color lightBadBg = Color(0xFFFFE8EE);

  /// Sky — gems, duels, informational toasts.
  static const Color lightInfo = Color(0xFF2BB3FF);

  /// Lemon — coins, stars, 1st place, streak flame.
  static const Color lightGold = Color(0xFFFFC61A);
  static const Color lightGoldSh = Color(0xFFD19A00);

  /// Scrim behind sheets and dialogs — `rgba(27,20,56,.5)`.
  static const Color lightOv = Color(0x801B1438);

  // ----------------------------------------------------------------- dark
  static const Color darkS0 = Color(0xFF120D25);
  static const Color darkS1 = Color(0xFF201941);
  static const Color darkS2 = Color(0xFF2A2154);
  static const Color darkS3 = Color(0xFF181233);

  static const Color darkTx = Color(0xFFF2EEFF);
  static const Color darkTx2 = Color(0xFFADA4CC);
  static const Color darkTx3 = Color(0xFF7B7399);
  static const Color darkLn = Color(0xFF332968);

  static const Color darkP = Color(0xFFFF9A3D);
  static const Color darkPd = Color(0xFFFF8A24);
  static const Color darkPsh = Color(0xFFB85F00);

  static const Color darkG = Color(0xFF9A78FF);
  static const Color darkGsh = Color(0xFF6A45D6);

  static const Color darkOk = Color(0xFF22D6AA);
  static const Color darkOkSh = Color(0xFF0E9C79);
  static const Color darkOkBg = Color(0xFF0E3B33);

  static const Color darkBad = Color(0xFFFF5C84);
  static const Color darkBadSh = Color(0xFFC92253);
  static const Color darkBadBg = Color(0xFF40122A);

  static const Color darkInfo = Color(0xFF57C4FF);

  static const Color darkGold = Color(0xFFFFD34D);
  static const Color darkGoldSh = Color(0xFFB98700);

  /// Scrim — `rgba(4,2,12,.66)`.
  static const Color darkOv = Color(0xA804020C);

  // ------------------------------------------------------- theme-invariant
  /// Ink used on top of lemon/gold fills (`.btn.gold`, `.toast.warn`).
  static const Color onGold = Color(0xFF4A3200);

  /// Ink used on a resting answer option, which is always a near-white plate
  /// on the dark arena regardless of theme.
  static const Color onAnswerRest = Color(0xFF20183F);

  /// Answer-option key badge (`.opt .k`) on a resting option.
  static const Color answerKeyBg = Color(0xFFEDE8FA);
  static const Color answerKeyFg = Color(0xFF5A4E86);

  /// Second stop of the grape XP gradient (`.bar i`).
  static const Color xpGradientEnd = Color(0xFFB79BFF);

  /// Second stop of the mint progress gradient (`.bar.ok i`).
  static const Color okGradientEnd = Color(0xFF6EE7C8);

  // Wallet token discs (`.pill .o`) — fixed brand gradients, not themed.
  static const Color coinDiscFrom = Color(0xFFFFD84D);
  static const Color coinDiscTo = Color(0xFFF0A500);
  static const Color gemDiscFrom = Color(0xFF7BD5FF);
  static const Color gemDiscTo = Color(0xFF2BB3FF);
  static const Color lifeDiscFrom = Color(0xFFFF7A9C);
  static const Color lifeDiscTo = Color(0xFFFF3D6E);

  /// Light [ColorScheme] seeded from the brand hues.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lightP,
    onPrimary: Colors.white,
    primaryContainer: lightPsh,
    onPrimaryContainer: Colors.white,
    secondary: lightG,
    onSecondary: Colors.white,
    secondaryContainer: lightGsh,
    onSecondaryContainer: Colors.white,
    tertiary: lightGold,
    onTertiary: onGold,
    tertiaryContainer: lightGoldSh,
    onTertiaryContainer: onGold,
    error: lightBad,
    onError: Colors.white,
    errorContainer: lightBadBg,
    onErrorContainer: lightBadSh,
    surface: lightS1,
    onSurface: lightTx,
    surfaceContainerLowest: lightS1,
    surfaceContainerLow: lightS2,
    surfaceContainer: lightS0,
    surfaceContainerHigh: lightS2,
    surfaceContainerHighest: lightS3,
    surfaceDim: lightS3,
    surfaceBright: lightS1,
    onSurfaceVariant: lightTx2,
    outline: lightLn,
    outlineVariant: lightLn,
    scrim: lightOv,
    inverseSurface: lightTx,
    onInverseSurface: lightS1,
    inversePrimary: darkP,
  );

  /// Dark [ColorScheme] — the same roles against the dark token set.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkP,
    onPrimary: Colors.white,
    primaryContainer: darkPsh,
    onPrimaryContainer: Colors.white,
    secondary: darkG,
    onSecondary: Colors.white,
    secondaryContainer: darkGsh,
    onSecondaryContainer: Colors.white,
    tertiary: darkGold,
    onTertiary: onGold,
    tertiaryContainer: darkGoldSh,
    onTertiaryContainer: onGold,
    error: darkBad,
    onError: Colors.white,
    errorContainer: darkBadBg,
    onErrorContainer: darkBad,
    surface: darkS1,
    onSurface: darkTx,
    surfaceContainerLowest: darkS3,
    surfaceContainerLow: darkS0,
    surfaceContainer: darkS1,
    surfaceContainerHigh: darkS2,
    surfaceContainerHighest: darkS2,
    surfaceDim: darkS0,
    surfaceBright: darkS2,
    onSurfaceVariant: darkTx2,
    outline: darkLn,
    outlineVariant: darkLn,
    scrim: darkOv,
    inverseSurface: darkTx,
    onInverseSurface: darkS1,
    inversePrimary: lightP,
  );
}
