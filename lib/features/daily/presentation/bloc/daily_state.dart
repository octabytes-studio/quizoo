part of 'daily_cubit.dart';

/// S-27's states (CLAUDE.md §3).
sealed class DailyState extends Equatable {
  const DailyState();

  @override
  List<Object?> get props => const [];
}

final class DailyInitial extends DailyState {
  const DailyInitial();
}

final class DailyLoading extends DailyState {
  const DailyLoading();
}

final class DailyLoaded extends DailyState {
  const DailyLoaded({required this.challenge, required this.streak});

  final DailyChallenge challenge;
  final StreakStatus streak;

  @override
  List<Object?> get props => [challenge, streak];
}

final class DailyError extends DailyState {
  const DailyError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
