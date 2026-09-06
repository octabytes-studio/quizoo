part of 'badge_unlocked_cubit.dart';

/// S-23's states (CLAUDE.md §3).
sealed class BadgeUnlockedState extends Equatable {
  const BadgeUnlockedState();

  @override
  List<Object?> get props => const [];
}

final class BadgeUnlockedLoading extends BadgeUnlockedState {
  const BadgeUnlockedLoading();
}

final class BadgeUnlockedLoaded extends BadgeUnlockedState {
  const BadgeUnlockedLoaded(this.progress);

  final BadgeProgress progress;

  @override
  List<Object?> get props => [progress];
}

final class BadgeUnlockedError extends BadgeUnlockedState {
  const BadgeUnlockedError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
