import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// A top-level content category — the bible's fourteen ("General knowledge",
/// "IQ", "Sports"…), shown as the Home chip row and the Browse header.
///
/// Lives in `core/` rather than a feature because Home, Browse, Shop,
/// Profile-stats and Leaderboards all consume it (CLAUDE.md §2's 3+ bar).
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,

    /// The emoji that stands in for the category everywhere it is listed.
    required String emoji,

    /// Start of the tile's gradient, as `#RRGGBB`.
    required String colorFrom,

    /// End of the tile's gradient, as `#RRGGBB`.
    required String colorTo,

    /// Display order in the chip row.
    required int order,
    @Default(0) int subcategoryCount,
    @Default(0) int questionCount,
    @Default(false) bool isNew,
    @Default(false) bool isLocked,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
