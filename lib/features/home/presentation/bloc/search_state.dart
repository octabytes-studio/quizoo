part of 'search_cubit.dart';

/// S-06's states.
///
/// Every one carries [trending] so the chip cloud below the results does not
/// flicker out while a search is running — it is loaded once and survives
/// every transition.
sealed class SearchState extends Equatable {
  const SearchState({this.trending = const []});

  /// The "TRENDING SEARCHES" chips.
  final List<String> trending;

  /// What the field currently holds, or empty before anything is typed.
  String get query => switch (this) {
    SearchInitial() => '',
    SearchSearching(:final query) => query,
    SearchSuccess(:final query) => query,
    SearchFailure(:final query) => query,
  };

  @override
  List<Object?> get props => [trending, query];
}

/// Nothing typed yet: trending chips only.
final class SearchInitial extends SearchState {
  const SearchInitial({super.trending});
}

/// Typed, waiting out the debounce or the lookup.
final class SearchSearching extends SearchState {
  const SearchSearching({required this.query, super.trending});

  @override
  final String query;
}

/// Results, which may legitimately be an empty list — that is the empty
/// state, not a failure.
final class SearchSuccess extends SearchState {
  const SearchSuccess({
    required this.query,
    required this.results,
    super.trending,
  });

  @override
  final String query;

  final List<Subcategory> results;

  bool get isEmpty => results.isEmpty;

  @override
  List<Object?> get props => [trending, query, results];
}

/// The lookup itself failed.
final class SearchFailure extends SearchState {
  const SearchFailure(this.error, {required this.query, super.trending});

  final ApiException error;

  @override
  final String query;

  @override
  List<Object?> get props => [trending, query, error.kind];
}
