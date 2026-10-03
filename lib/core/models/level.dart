import 'package:freezed_annotation/freezed_annotation.dart';

part 'level.freezed.dart';
part 'level.g.dart';

/// Where a level sits in the player's progression.
///
/// Four states since plan 023: `open` is a level a Quizoo Pro player can
/// play that is *not* the next step in the ladder — every locked level
/// becomes `open` for them (see `LevelMap.withAllLevelsOpen`), so the map
/// shows "playable" without pretending it is the current one. A lapsed
/// member's replayable levels also land here.
enum LevelStatus {
  /// Not playable yet — no clear on this or the level before it.
  locked,

  /// The next one to play. The "YOU'RE HERE" flag lands on this.
  current,

  /// Cleared at least once.
  done,

  /// Playable, but not the next step in the ladder (plan 023).
  open,
}

/// The escalating difficulty bands, which set the clock: 20s → 15s → 10s per
/// question as the player climbs the 30-level ladder.
enum DifficultyBand { warmUp, steady, sharp }

/// Maps a `difficulty_tiers.code` to its [DifficultyBand]. The single
/// owner of that mapping (plan 020): `CatalogApi._bandForTierCode` and
/// `TopicMasteryApi` both delegate to this rather than each keeping their
/// own copy. An unknown future code renders as the hardest band rather than
/// crashing.
DifficultyBand bandForTierCode(String code) => switch (code) {
  'easy' => DifficultyBand.warmUp,
  'medium' => DifficultyBand.steady,
  _ => DifficultyBand.sharp,
};

/// One of the levels inside a [Subcategory].
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

    /// Every tenth level, which wears a crown on the map.
    @Default(false) bool isBoss,
    @Default(10) int questionCount,

    /// 0…3.
    @Default(0) int starsEarned,
    @Default(0) int bestScore,
  }) = _Level;

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
}
