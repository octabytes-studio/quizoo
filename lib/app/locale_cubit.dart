import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_bloc/flutter_bloc.dart';

part 'locale_state.dart';

/// The language the player picked on S-03 (and, from plan 004, in Settings).
///
/// App-root like [ThemeCubit], for the same reason: every screen is
/// downstream of it, so scoping it lower would mean re-providing it
/// everywhere (CLAUDE.md §3).
///
/// **Two honest limitations**, both deliberate for this phase:
///
/// * The choice is not persisted — no `shared_preferences` in the mock-data
///   phase — so a cold start returns to [LocaleSystem].
/// * Only `en` and `ur` are in `supportedLocales`. Picking Arabic, Hindi or
///   Spanish is *recorded* here so S-03's row stays checked, but Flutter
///   resolves the actual display language back to English. S-03 says so on
///   screen rather than pretending otherwise (plan 002, S-03 research note).
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(const LocaleSystem());

  /// Records [locale] as the player's choice.
  void select(Locale locale) => emit(LocaleSelected(locale));

  /// Falls back to whatever the device asks for.
  void followSystem() => emit(const LocaleSystem());
}
