import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/data/home_repository.dart';

part 'search_state.dart';

/// S-06's search.
///
/// Debounced at the bible's own 250 ms, and local-first: the repository
/// filters the cached taxonomy rather than asking a server, which is what
/// makes search work offline. The debounce lives here rather than in the
/// screen because "how often do we search" is behaviour, not layout.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository, {required this.languageCode})
    : super(const SearchInitial());

  final HomeRepository _repository;

  /// Fixed for this Cubit's lifetime (plan 008, Assumption 6) — Search is a
  /// pushed route, not part of the persistent tab shell, so it does not need
  /// to react live to a language change the way Home does.
  final String languageCode;

  /// §07: "Debounced at 250 ms".
  static const Duration debounce = Duration(milliseconds: 250);

  Timer? _debounceTimer;

  /// Guards against an in-flight search for an older query overwriting a
  /// newer one's results.
  int _requestId = 0;

  /// Loads the trending chip cloud, which is what an empty search shows.
  Future<void> loadTrending() async {
    try {
      emit(
        SearchInitial(
          trending: await _repository.fetchTrendingSearches(
            languageCode: languageCode,
          ),
        ),
      );
    } on ApiException {
      // The chip cloud is a convenience. Losing it leaves an empty field,
      // which is still a usable screen.
      if (!isClosed) emit(const SearchInitial());
    }
  }

  void queryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      emit(SearchInitial(trending: state.trending));
      return;
    }
    emit(SearchSearching(query: query, trending: state.trending));
    _debounceTimer = Timer(debounce, () => _search(query));
  }

  /// Runs a search immediately — a trending chip is an explicit choice, so it
  /// should not wait out a debounce meant for typing.
  Future<void> searchNow(String query) {
    _debounceTimer?.cancel();
    emit(SearchSearching(query: query, trending: state.trending));
    return _search(query);
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    try {
      final results = await _repository.search(
        query,
        languageCode: languageCode,
      );
      if (isClosed || requestId != _requestId) return;
      emit(
        SearchSuccess(query: query, results: results, trending: state.trending),
      );
    } on ApiException catch (error) {
      if (isClosed || requestId != _requestId) return;
      emit(SearchFailure(error, query: query, trending: state.trending));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
