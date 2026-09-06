part of 'category_detail_cubit.dart';

/// S-07's states (CLAUDE.md §3).
sealed class CategoryDetailState extends Equatable {
  const CategoryDetailState();

  @override
  List<Object?> get props => const [];
}

final class CategoryDetailInitial extends CategoryDetailState {
  const CategoryDetailInitial();
}

final class CategoryDetailLoading extends CategoryDetailState {
  const CategoryDetailLoading();
}

final class CategoryDetailLoaded extends CategoryDetailState {
  const CategoryDetailLoaded({
    required this.detail,
    this.sort = TopicSort.popular,
  });

  final CategoryDetail detail;
  final TopicSort sort;

  @override
  List<Object?> get props => [detail, sort];
}

final class CategoryDetailError extends CategoryDetailState {
  const CategoryDetailError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
