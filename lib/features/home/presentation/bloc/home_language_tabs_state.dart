part of 'home_language_tabs_cubit.dart';

/// Home's language pill row (plan 021, CLAUDE.md §3).
sealed class HomeLanguageTabsState extends Equatable {
  const HomeLanguageTabsState();

  @override
  List<Object?> get props => const [];
}

/// The live `languages` list is on its way.
final class HomeLanguageTabsLoading extends HomeLanguageTabsState {
  const HomeLanguageTabsLoading();
}

/// [languages] is already in display order — the lead first, then the rest
/// in `sort_order`.
final class HomeLanguageTabsLoaded extends HomeLanguageTabsState {
  const HomeLanguageTabsLoaded(this.languages);

  final List<LanguageOption> languages;

  @override
  List<Object?> get props => [languages];
}

/// The list failed to load — the row hides and Home stays fully usable
/// (plan 021, Assumption 7).
final class HomeLanguageTabsError extends HomeLanguageTabsState {
  const HomeLanguageTabsError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
