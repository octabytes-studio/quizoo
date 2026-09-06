part of 'level_map_cubit.dart';

/// S-08's states (CLAUDE.md §3), including the empty and error branches the
/// bible calls S-47 and S-48.
sealed class LevelMapState extends Equatable {
  const LevelMapState();

  @override
  List<Object?> get props => const [];
}

final class LevelMapInitial extends LevelMapState {
  const LevelMapInitial();
}

final class LevelMapLoading extends LevelMapState {
  const LevelMapLoading();
}

final class LevelMapLoaded extends LevelMapState {
  const LevelMapLoaded(this.map);

  final LevelMap map;

  @override
  List<Object?> get props => [map];
}

/// S-47 — the topic exists but has no levels built yet.
final class LevelMapEmpty extends LevelMapState {
  const LevelMapEmpty(this.map);

  final LevelMap map;

  @override
  List<Object?> get props => [map];
}

/// S-48 — the topic could not be loaded at all.
final class LevelMapError extends LevelMapState {
  const LevelMapError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
