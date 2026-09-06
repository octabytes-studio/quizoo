part of 'leaderboard_cubit.dart';

/// S-29's states (CLAUDE.md §3).
sealed class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => const [];
}

final class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

final class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

final class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded({
    required this.scope,
    required this.period,
    required this.roster,
    required this.selfEntry,
  });

  final LeaderboardScope scope;
  final LeaderboardPeriod period;

  /// The podium (top 3) plus the ranked rows below it — [selfEntry] is
  /// pinned separately and never part of this list.
  final List<LeaderboardEntry> roster;
  final LeaderboardEntry selfEntry;

  List<LeaderboardEntry> get podium => roster.take(3).toList();
  List<LeaderboardEntry> get remainingRows => roster.skip(3).toList();

  @override
  List<Object?> get props => [scope, period, roster, selfEntry];
}

final class LeaderboardError extends LeaderboardState {
  const LeaderboardError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
