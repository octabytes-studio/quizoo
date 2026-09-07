part of 'matchmaking_cubit.dart';

/// S-39's states (CLAUDE.md §3).
sealed class MatchmakingState extends Equatable {
  const MatchmakingState();

  @override
  List<Object?> get props => const [];
}

/// Widening the ELO band every [MatchmakingCubit.widenInterval].
final class MatchmakingSearching extends MatchmakingState {
  const MatchmakingSearching({
    required this.elapsedSeconds,
    required this.widenings,
  });

  final int elapsedSeconds;

  /// How many times the band has widened — printed as "±{n+1}00" in the
  /// screen, not read directly.
  final int widenings;

  @override
  List<Object?> get props => [elapsedSeconds, widenings];
}

/// An opponent is ready — always a bot in this mock phase, always labelled
/// as one.
final class MatchmakingFound extends MatchmakingState {
  const MatchmakingFound(this.opponent);

  final DuelOpponent opponent;

  @override
  List<Object?> get props => [opponent];
}
