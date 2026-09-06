part of 'daily_result_cubit.dart';

/// S-28's states (CLAUDE.md §3).
sealed class DailyResultState extends Equatable {
  const DailyResultState();

  @override
  List<Object?> get props => const [];
}

final class DailyResultLoading extends DailyResultState {
  const DailyResultLoading();
}

final class DailyResultLoaded extends DailyResultState {
  const DailyResultLoaded(this.result);

  final DailyResult result;

  @override
  List<Object?> get props => [result];
}

final class DailyResultError extends DailyResultState {
  const DailyResultError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
