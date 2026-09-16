part of 'home_cubit.dart';

/// Home's four states (CLAUDE.md §3), which are also S-04, S-05 and S-45.
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

/// Before [HomeCubit.load] has been called.
final class HomeInitial extends HomeState {
  const HomeInitial();
}

/// S-45 — Home's skeleton state.
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// S-04 / S-05. Which of the two renders is the session's business, not this
/// state's: one content model serves both layouts.
final class HomeLoaded extends HomeState {
  const HomeLoaded({required this.content, this.isPopularRailLoading = false});

  final HomeContent content;

  /// True between the cached first paint and the popular rail landing, so the
  /// rail can show skeletons while the rest of Home is already interactive.
  final bool isPopularRailLoading;

  HomeLoaded copyWith({HomeContent? content, bool? isPopularRailLoading}) =>
      HomeLoaded(
        content: content ?? this.content,
        isPopularRailLoading: isPopularRailLoading ?? this.isPopularRailLoading,
      );

  @override
  List<Object?> get props => [content, isPopularRailLoading];
}

/// The cached read itself failed, which is the only way Home has nothing at
/// all to show.
final class HomeError extends HomeState {
  const HomeError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
