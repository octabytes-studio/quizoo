part of 'blocked_players_cubit.dart';

/// Privacy → Blocked players' states (CLAUDE.md §3).
sealed class BlockedPlayersState extends Equatable {
  const BlockedPlayersState();

  @override
  List<Object?> get props => const [];
}

final class BlockedPlayersInitial extends BlockedPlayersState {
  const BlockedPlayersInitial();
}

final class BlockedPlayersLoading extends BlockedPlayersState {
  const BlockedPlayersLoading();
}

final class BlockedPlayersLoaded extends BlockedPlayersState {
  const BlockedPlayersLoaded(this.players);

  final List<BlockedPlayer> players;

  @override
  List<Object?> get props => [players];
}

final class BlockedPlayersError extends BlockedPlayersState {
  const BlockedPlayersError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
