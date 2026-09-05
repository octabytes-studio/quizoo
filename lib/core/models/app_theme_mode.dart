import 'package:flutter/material.dart';

/// The app's theme preference, as the user chooses it in Settings.
///
/// Distinct from Flutter's [ThemeMode] so the choice can be persisted and
/// switched on exhaustively without depending on the framework enum's shape;
/// [toThemeMode] is the single conversion point.
enum AppThemeMode {
  light,
  dark,
  system;

  ThemeMode toThemeMode() => switch (this) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  /// The label key each mode shows in Settings (§16's Light / Dark / Auto).
  String get labelKey => switch (this) {
    AppThemeMode.light => 'themeLight',
    AppThemeMode.dark => 'themeDark',
    AppThemeMode.system => 'themeAuto',
  };
}
