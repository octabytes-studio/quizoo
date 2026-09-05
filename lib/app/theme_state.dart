part of 'theme_cubit.dart';

/// The theme preference, as a sealed hierarchy so every consumer switches
/// exhaustively (CLAUDE.md §3) rather than defaulting a case it forgot.
///
/// Flutter's own `ThemeMode` enum is reached only at the single point
/// `MaterialApp.router` needs it, via [mode].
sealed class ThemeState extends Equatable {
  const ThemeState();

  /// The preference as this state's [AppThemeMode].
  AppThemeMode get mode => switch (this) {
    ThemeLight() => AppThemeMode.light,
    ThemeDark() => AppThemeMode.dark,
    ThemeSystem() => AppThemeMode.system,
  };

  @override
  List<Object?> get props => const [];
}

/// Always light, whatever the platform says.
final class ThemeLight extends ThemeState {
  const ThemeLight();
}

/// Always dark.
final class ThemeDark extends ThemeState {
  const ThemeDark();
}

/// Follow the platform — the default.
final class ThemeSystem extends ThemeState {
  const ThemeSystem();
}
