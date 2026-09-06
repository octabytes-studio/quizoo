import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/features/catalog/data/catalog_api.dart';
import 'package:quizoo/features/catalog/domain/category_detail.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';

/// The only thing that talks to [CatalogApi].
class CatalogRepository {
  CatalogRepository(this._api);

  final CatalogApi _api;

  Future<CategoryDetail> fetchCategory(String categoryId) =>
      _api.fetchCategory(categoryId);

  /// S-08's data, with the topic grid already sorted the way the header's
  /// control claims.
  Future<LevelMap> fetchLevelMap({
    required String categoryId,
    required String subcategoryId,
  }) =>
      _api.fetchLevelMap(categoryId: categoryId, subcategoryId: subcategoryId);

  Future<Level> fetchLevel({
    required String subcategoryId,
    required int levelNumber,
  }) => _api.fetchLevel(subcategoryId: subcategoryId, levelNumber: levelNumber);

  /// Applies S-07's sort control.
  ///
  /// Ordering is a data concern, so it happens here rather than in the screen
  /// — and having it in one place is what will make the two sorts the bible
  /// lists but this phase does not wire a one-line change later.
  static CategoryDetail sorted(CategoryDetail detail, TopicSort sort) {
    final topics = [...detail.topics];
    switch (sort) {
      case TopicSort.popular:
        topics.sort((a, b) => b.questionCount.compareTo(a.questionCount));
      case TopicSort.alphabetical:
        topics.sort((a, b) => a.name.compareTo(b.name));
      case TopicSort.progress:
        topics.sort((a, b) => b.levelsCleared.compareTo(a.levelsCleared));
    }
    return detail.copyWith(topics: topics);
  }
}
