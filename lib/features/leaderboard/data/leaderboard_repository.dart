import 'package:quizoo/features/leaderboard/data/leaderboard_api.dart';
import 'package:quizoo/features/leaderboard/domain/friend.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_scope.dart';
import 'package:quizoo/features/leaderboard/domain/league_standing.dart';

/// The only thing that talks to [LeaderboardApi].
class LeaderboardRepository {
  LeaderboardRepository(this._api);

  final LeaderboardApi _api;

  Future<List<LeaderboardEntry>> fetchRoster({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) => _api.fetchRoster(scope: scope, period: period);

  Future<LeaderboardEntry> fetchSelfEntry({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) => _api.fetchSelfEntry(scope: scope, period: period);

  Future<List<LeaderboardEntry>> fetchCategoryRoster(String subcategoryId) =>
      _api.fetchCategoryRoster(subcategoryId);

  Future<(int rank, int pointsFromTop, String countryName)> fetchCategoryHeader(
    String subcategoryId,
  ) => _api.fetchCategoryHeader(subcategoryId);

  Future<List<Friend>> fetchFriends() => _api.fetchFriends();

  Future<List<LeagueStanding>> fetchLeagueNeighbors() =>
      _api.fetchLeagueNeighbors();
}
