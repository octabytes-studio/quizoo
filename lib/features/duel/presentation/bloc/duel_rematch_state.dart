part of 'duel_rematch_cubit.dart';

/// Where S-41's two-sided rematch handshake stands (plan 017, Phase 11).
sealed class DuelRematchState extends Equatable {
  const DuelRematchState();

  @override
  List<Object?> get props => const [];
}

/// Nobody has asked yet — "Rematch" is tappable.
final class RematchIdle extends DuelRematchState {
  const RematchIdle();
}

/// This player asked; waiting for the opponent to ask back.
final class RematchWaiting extends DuelRematchState {
  const RematchWaiting();
}

/// The opponent asked first — "Accept rematch" starts the new duel.
final class RematchOffered extends DuelRematchState {
  const RematchOffered();
}

/// Both asked and the server created the new duel [duelId] — the screen
/// moves to it.
final class RematchStarting extends DuelRematchState {
  const RematchStarting(this.duelId);

  final String duelId;

  @override
  List<Object?> get props => [duelId];
}

/// No rematch is possible any more — the opponent left or declined, the
/// window closed, or the server refused (`rematch_unavailable`).
final class RematchUnavailable extends DuelRematchState {
  const RematchUnavailable();
}
