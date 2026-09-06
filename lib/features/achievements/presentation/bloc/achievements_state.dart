part of 'achievements_cubit.dart';

/// S-33's states (CLAUDE.md §3).
sealed class AchievementsState extends Equatable {
  const AchievementsState();

  @override
  List<Object?> get props => const [];
}

final class AchievementsInitial extends AchievementsState {
  const AchievementsInitial();
}

final class AchievementsLoading extends AchievementsState {
  const AchievementsLoading();
}

final class AchievementsLoaded extends AchievementsState {
  const AchievementsLoaded({required this.all, this.filter});

  final List<BadgeProgress> all;

  /// Null means the "All" chip is active.
  final BadgeCategory? filter;

  int get unlockedCount =>
      all.where((progress) => !progress.badge.isLocked).length;

  List<BadgeProgress> get visible => filter == null
      ? all
      : [
          for (final progress in all)
            if (progress.category == filter) progress,
        ];

  AchievementsLoaded copyWith({
    List<BadgeProgress>? all,
    BadgeCategory? filter,
    bool clearFilter = false,
  }) => AchievementsLoaded(
    all: all ?? this.all,
    filter: clearFilter ? null : (filter ?? this.filter),
  );

  @override
  List<Object?> get props => [all, filter];
}

final class AchievementsError extends AchievementsState {
  const AchievementsError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
