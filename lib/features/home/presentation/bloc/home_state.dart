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
  const HomeLoading({this.previous});

  /// The last content shown, if any — so the top bar keeps the real wallet
  /// while the body skeletons during a language switch (plan 021).
  final HomeContent? previous;

  @override
  List<Object?> get props => [previous];
}

/// S-04 / S-05. Which of the two renders is the session's business, not this
/// state's: one content model serves both layouts.
final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.languageCode,
    required this.content,
    this.isPopularRailLoading = false,
  });

  /// The content language [content] was fetched for (plan 021).
  final String languageCode;

  final HomeContent content;

  /// True between the cached first paint and the popular rail landing, so the
  /// rail can show skeletons while the rest of Home is already interactive.
  final bool isPopularRailLoading;

  HomeLoaded copyWith({
    String? languageCode,
    HomeContent? content,
    bool? isPopularRailLoading,
  }) => HomeLoaded(
    languageCode: languageCode ?? this.languageCode,
    content: content ?? this.content,
    isPopularRailLoading: isPopularRailLoading ?? this.isPopularRailLoading,
  );

  @override
  List<Object?> get props => [languageCode, content, isPopularRailLoading];
}

/// The cached read itself failed, which is the only way Home has nothing at
/// all to show for the requested language.
final class HomeError extends HomeState {
  const HomeError(this.error, {this.previous});

  final ApiException error;

  /// The last content shown, if any — see [HomeLoading.previous].
  final HomeContent? previous;

  @override
  List<Object?> get props => [error.kind, error.message, previous];
}
