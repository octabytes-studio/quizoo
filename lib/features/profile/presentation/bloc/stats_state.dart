part of 'stats_cubit.dart';

/// S-35's states (CLAUDE.md §3).
sealed class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => const [];
}

final class StatsInitial extends StatsState {
  const StatsInitial();
}

final class StatsLoading extends StatsState {
  const StatsLoading();
}

final class StatsLoaded extends StatsState {
  const StatsLoaded(this.stats);

  final StatsSummary stats;

  @override
  List<Object?> get props => [stats];
}

final class StatsError extends StatsState {
  const StatsError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
