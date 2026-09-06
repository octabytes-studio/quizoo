part of 'profile_cubit.dart';

/// S-32's states (CLAUDE.md §3).
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => const [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.summary);

  final ProfileSummary summary;

  @override
  List<Object?> get props => [summary];
}

final class ProfileError extends ProfileState {
  const ProfileError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
