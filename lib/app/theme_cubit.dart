import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/models/app_theme_mode.dart';

part 'theme_state.dart';

/// The app's light/dark/system preference.
///
/// This is the one Cubit that genuinely belongs at the app root (CLAUDE.md
/// §3) — every screen in the app is downstream of it, so scoping it any
/// lower would mean re-providing it everywhere.
///
/// **Known limitation**: the choice is not persisted. `shared_preferences` is
/// deliberately not part of the design-with-mock-data phase, so the app
/// returns to [ThemeSystem] on restart. That is a scoping decision, not a bug.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeSystem());

  void setLight() => emit(const ThemeLight());

  void setDark() => emit(const ThemeDark());

  void setSystem() => emit(const ThemeSystem());

  void setMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => setLight(),
    AppThemeMode.dark => setDark(),
    AppThemeMode.system => setSystem(),
  };
}
