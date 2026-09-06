part of 'locale_cubit.dart';

/// The language preference, sealed so consumers switch exhaustively
/// (CLAUDE.md §3).
sealed class LocaleState extends Equatable {
  const LocaleState();

  /// What `MaterialApp.locale` should be — null means "follow the device".
  Locale? get locale => switch (this) {
    LocaleSystem() => null,
    LocaleSelected(:final locale) => locale,
  };

  @override
  List<Object?> get props => [locale];
}

/// Follow the device — the default.
final class LocaleSystem extends LocaleState {
  const LocaleSystem();
}

/// The player picked a language explicitly.
final class LocaleSelected extends LocaleState {
  const LocaleSelected(this.locale);

  @override
  final Locale locale;
}
