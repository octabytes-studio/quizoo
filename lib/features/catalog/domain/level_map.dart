import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/models/subcategory.dart';

part 'level_map.freezed.dart';
part 'level_map.g.dart';

/// Everything S-08 renders: the topic, its parent category, its levels, and
/// the player's rank in it.
@freezed
abstract class LevelMap with _$LevelMap {
  const factory LevelMap({
    required Category category,
    required Subcategory subcategory,
    @Default([]) List<Level> levels,

    /// The "#412" stat. Zero means unranked, which is a guest.
    @Default(0) int rank,
  }) = _LevelMap;

  const LevelMap._();

  factory LevelMap.fromJson(Map<String, dynamic> json) =>
      _$LevelMapFromJson(json);

  /// The level the "YOU'RE HERE" flag sits on and the bottom CTA plays.
  ///
  /// Falls back to the first level, which is where a player who has cleared
  /// every level lands when they come back to replay.
  Level get currentLevel => levels.firstWhere(
    (level) => level.status == LevelStatus.current,
    orElse: () => levels.isEmpty ? _placeholder : levels.first,
  );

  /// Stars earned of `levels.length * 3` available (§19).
  int get starsAvailable => levels.length * 3;

  static const Level _placeholder = Level(
    id: '',
    subcategoryId: '',
    number: 1,
    difficultyBand: DifficultyBand.warmUp,
    secondsPerQuestion: 20,
    status: LevelStatus.current,
  );
}
