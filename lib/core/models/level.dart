import 'package:freezed_annotation/freezed_annotation.dart';

part 'level.freezed.dart';
part 'level.g.dart';

/// Where a level sits in the player's progression — the four `LevelNode`
/// states from §06.
enum LevelStatus { locked, current, done }

/// The escalating difficulty bands, which set the clock: 30s → 25s → 20s →
/// 15s → 10s per question as the player climbs the 50-level ladder.
enum DifficultyBand { warmUp, steady, sharp, brutal, master }

/// One of the twenty levels inside a [Subcategory].
@freezed
abstract class Level with _$Level {
  const factory Level({
    required String id,
    required String subcategoryId,

    /// 1-based position on the level map.
    required int number,
    required DifficultyBand difficultyBand,

    /// The per-question clock, which tightens with the band.
    required int secondsPerQuestion,
    required LevelStatus status,

    /// Every fifth level, which wears a crown on the map.
    @Default(false) bool isBoss,
    @Default(20) int questionCount,

    /// 0…3.
    @Default(0) int starsEarned,
    @Default(0) int bestScore,
  }) = _Level;

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
}
