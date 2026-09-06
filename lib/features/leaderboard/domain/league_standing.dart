import 'package:freezed_annotation/freezed_annotation.dart';

part 'league_standing.freezed.dart';
part 'league_standing.g.dart';

/// One row of S-26's weekly league — a distinct system from the leaderboard
/// (§19: "leagues are separate from boards"): a fixed cohort of ~30
/// similar-XP players that promotes and relegates at its edges each week,
/// rather than an open, all-time ranking.
@freezed
abstract class LeagueStanding with _$LeagueStanding {
  const factory LeagueStanding({
    required int rank,
    required String playerId,
    required String name,
    required String avatarEmoji,
    required int points,
    @Default(false) bool isSelf,
  }) = _LeagueStanding;

  factory LeagueStanding.fromJson(Map<String, dynamic> json) =>
      _$LeagueStandingFromJson(json);
}
