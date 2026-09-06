part of 'category_leaderboard_cubit.dart';

/// S-30's states (CLAUDE.md §3).
sealed class CategoryLeaderboardState extends Equatable {
  const CategoryLeaderboardState();

  @override
  List<Object?> get props => const [];
}

final class CategoryLeaderboardInitial extends CategoryLeaderboardState {
  const CategoryLeaderboardInitial();
}

final class CategoryLeaderboardLoading extends CategoryLeaderboardState {
  const CategoryLeaderboardLoading();
}

final class CategoryLeaderboardLoaded extends CategoryLeaderboardState {
  const CategoryLeaderboardLoaded({
    required this.roster,
    required this.selfRank,
    required this.pointsFromTop,
    required this.countryName,
  });

  final List<LeaderboardEntry> roster;
  final int selfRank;
  final int pointsFromTop;
  final String countryName;

  @override
  List<Object?> get props => [roster, selfRank, pointsFromTop, countryName];
}

final class CategoryLeaderboardError extends CategoryLeaderboardState {
  const CategoryLeaderboardError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
