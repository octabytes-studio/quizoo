import 'package:freezed_annotation/freezed_annotation.dart';

part 'subcategory.freezed.dart';
part 'subcategory.g.dart';

/// A playable topic inside a [Category] — the cell in Home's 3-up tile grid.
///
/// Carries the player's own progress through it, because the tile renders
/// "Lv 7/20" and a progress bar from the same object it renders its name from.
@freezed
abstract class Subcategory with _$Subcategory {
  const factory Subcategory({
    required String id,
    required String categoryId,
    required String name,
    required String emoji,

    /// The grouping the bible's search breadcrumb prints between the category
    /// and this topic — "Science › **Astronomy** · 400 questions".
    /// Empty when the topic sits directly under its category.
    @Default('') String groupName,

    /// Tint behind the tile's emoji plate, as `#RRGGBB`.
    required String plateColor,
    @Default(0) int questionCount,

    /// Levels the player has finished, of [levelCount].
    @Default(0) int levelsCleared,
    @Default(50) int levelCount,
    @Default(0) int bestScore,

    /// Stars earned across every level, of `levelCount * 3`.
    @Default(0) int starsEarned,
    @Default(false) bool isNew,
    @Default(false) bool isLocked,
  }) = _Subcategory;

  const Subcategory._();

  factory Subcategory.fromJson(Map<String, dynamic> json) =>
      _$SubcategoryFromJson(json);

  /// 0…1, for the tile's progress bar.
  double get progress =>
      levelCount == 0 ? 0 : (levelsCleared / levelCount).clamp(0, 1).toDouble();
}
