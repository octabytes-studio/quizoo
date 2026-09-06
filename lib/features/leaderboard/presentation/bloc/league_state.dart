part of 'league_cubit.dart';

/// S-26's states (CLAUDE.md §3).
sealed class LeagueState extends Equatable {
  const LeagueState();

  @override
  List<Object?> get props => const [];
}

final class LeagueInitial extends LeagueState {
  const LeagueInitial();
}

final class LeagueLoading extends LeagueState {
  const LeagueLoading();
}

final class LeagueLoaded extends LeagueState {
  const LeagueLoaded(this.neighbors);

  final List<LeagueStanding> neighbors;

  @override
  List<Object?> get props => [neighbors];
}

final class LeagueError extends LeagueState {
  const LeagueError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
