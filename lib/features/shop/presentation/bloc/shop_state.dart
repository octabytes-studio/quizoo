part of 'shop_cubit.dart';

/// S-36's states (CLAUDE.md §3).
sealed class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => const [];
}

final class ShopInitial extends ShopState {
  const ShopInitial();
}

final class ShopLoading extends ShopState {
  const ShopLoading();
}

final class ShopLoaded extends ShopState {
  const ShopLoaded({required this.content});

  final ShopContent content;

  @override
  List<Object?> get props => [content];
}

final class ShopError extends ShopState {
  const ShopError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
