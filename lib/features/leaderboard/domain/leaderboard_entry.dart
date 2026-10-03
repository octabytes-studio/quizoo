import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';
part 'leaderboard_entry.g.dart';

/// One row of a global, country or category leaderboard — S-29/S-30's
/// podium, ranked rows and pinned self-row all render this same shape.
///
/// The secondary line differs by context (a city on the global board, a
/// levels/stars line on a category board), so both are carried and each
/// screen reads the one it needs rather than the model deciding for it.
@freezed
abstract class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required int rank,
    required String playerId,
    required String name,
    required String avatarEmoji,
    required int score,

    /// "🇵🇰 Lahore" — flag plus city, as the bible always prints them
    /// together. Null on a category board, which has no location line.
    String? locationLabel,

    /// Positive = climbed, negative = dropped, zero = unchanged. Null when
    /// there is no prior-period rank to compare against (a category board).
    int? rankDelta,

    /// Set only on the player's own row.
    @Default(false) bool isSelf,

    /// A Quizoo Pro member (plan 023) — drives the crown and the tick. From
    /// `profiles.is_pro`, written only by the server.
    @Default(false) bool isPro,

    /// "Top N%", shown only on the self row of a global/country board.
    int? topPercent,

    /// Category-board-only progress line: "{levelsCleared}/{levelCount}
    /// levels · {starsEarned} ⭐".
    int? levelsCleared,
    int? levelCount,
    int? starsEarned,
  }) = _LeaderboardEntry;

  const LeaderboardEntry._();

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);

  /// The category-board secondary line, or null when this entry carries no
  /// level progress (a global/country row).
  String? get levelsLabel => levelsCleared == null
      ? null
      : '$levelsCleared/$levelCount levels · $starsEarned ⭐';
}
