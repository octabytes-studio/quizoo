import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/features/home/data/home_api.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/features/home/domain/search_result.dart';

/// The only thing that talks to [HomeApi].
class HomeRepository {
  HomeRepository(this._api);

  final HomeApi _api;

  /// Home's first paint, from cache.
  Future<HomeContent> fetchCachedHome({
    required bool isSignedIn,
    required String languageCode,
  }) =>
      _api.fetchCachedHome(isSignedIn: isSignedIn, languageCode: languageCode);

  /// The popular rail, which lands after the first paint.
  Future<List<PopularQuiz>> fetchPopularRail(List<String> subcategoryIds) =>
      _api.fetchPopularRail(subcategoryIds);

  /// S-06's result list.
  ///
  /// Matching happens here rather than in the Cubit because "what counts as a
  /// match" is a data-shape decision — it searches a topic's own name, the
  /// sub-path the breadcrumb prints, and its category — and the presentation
  /// layer has no business knowing that.
  Future<List<SearchResult>> search(
    String query, {
    required String languageCode,
  }) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return const [];

    final content = await _api.fetchCachedHome(
      isSignedIn: false,
      languageCode: languageCode,
    );
    final categoriesById = {
      for (final category in content.categories) category.id: category,
    };

    return [
      for (final subcategory in content.subcategories)
        if (categoriesById[subcategory.categoryId] case final category?
            when _matches(subcategory, category, trimmed))
          SearchResult(subcategory: subcategory, categoryName: category.name),
    ];
  }

  /// The chip cloud under S-06's results.
  Future<List<String>> fetchTrendingSearches({
    required String languageCode,
  }) async {
    final popular = await _api.fetchTrendingSearches(
      languageCode: languageCode,
    );
    return [for (final quiz in popular) quiz.title.toLowerCase()];
  }

  static bool _matches(
    Subcategory subcategory,
    Category category,
    String query,
  ) =>
      subcategory.name.toLowerCase().contains(query) ||
      subcategory.groupName.toLowerCase().contains(query) ||
      category.name.toLowerCase().contains(query);
}
