part of 'avatar_picker_cubit.dart';

/// S-25's avatar-sheet states, sealed so the sheet switches over them
/// exhaustively (CLAUDE.md §3).
sealed class AvatarPickerState extends Equatable {
  const AvatarPickerState();

  @override
  List<Object?> get props => const [];
}

/// Fetching `avatar_options` where `is_active = true`.
final class AvatarPickerLoading extends AvatarPickerState {
  const AvatarPickerLoading();
}

/// The live, orderable list the sheet renders.
final class AvatarPickerLoaded extends AvatarPickerState {
  const AvatarPickerLoaded(this.avatars);

  final List<AvatarOption> avatars;

  @override
  List<Object?> get props => [avatars];
}

final class AvatarPickerError extends AvatarPickerState {
  const AvatarPickerError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
