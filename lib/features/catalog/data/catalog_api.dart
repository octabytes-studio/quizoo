import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/domain/category_detail.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';

/// Browse's mocked endpoints.
class CatalogApi extends MockApi {
  CatalogApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// A missing id is a 404, not a generic failure — S-48 shows the code.
  @override
  ApiException get simulatedFailure => const ApiException.network();

  Future<CategoryDetail> fetchCategory(String categoryId) => respond(() {
    final category = _categoryOrThrow(categoryId);
    return CategoryDetail(
      category: category,
      topics: MockCatalog.forCategory(categoryId),
      playerCount: MockCatalog.categoryPlayerCounts[categoryId] ?? 0,
    );
  });

  Future<LevelMap> fetchLevelMap({
    required String categoryId,
    required String subcategoryId,
  }) => respond(() {
    final category = _categoryOrThrow(categoryId);
    final subcategory = _subcategoryOrThrow(subcategoryId);
    return LevelMap(
      category: category,
      subcategory: subcategory,
      levels: MockCatalog.levelsFor(subcategory),
      rank: subcategory.levelsCleared == 0 ? 0 : MockPlayer.subcategoryRank,
    );
  });

  /// S-09's data. The level itself comes from the map; this is the wallet and
  /// power-up half of the contract.
  Future<Level> fetchLevel({
    required String subcategoryId,
    required int levelNumber,
  }) => respond(() {
    final subcategory = _subcategoryOrThrow(subcategoryId);
    return MockCatalog.levelsFor(
      subcategory,
    ).firstWhere((level) => level.number == levelNumber);
  });

  static Category _categoryOrThrow(String id) {
    try {
      return MockCatalog.categoryById(id);
    } on StateError {
      throw const ApiException(
        'No such category',
        kind: ApiErrorKind.notFound,
        code: 'ERR_CONTENT_404',
      );
    }
  }

  static Subcategory _subcategoryOrThrow(String id) {
    try {
      return MockCatalog.subcategoryById(id);
    } on StateError {
      throw const ApiException(
        'No such topic',
        kind: ApiErrorKind.notFound,
        code: 'ERR_CONTENT_404',
      );
    }
  }
}
