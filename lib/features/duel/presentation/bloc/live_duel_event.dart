part of 'live_duel_bloc.dart';

/// What drives a live duel (plan 017, Phase 10).
sealed class LiveDuelEvent extends Equatable {
  const LiveDuelEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened: load the snapshot, join the room, mark ready.
final class LiveDuelStarted extends LiveDuelEvent {
  const LiveDuelStarted();
}

/// Something arrived on the duel's room channel.
final class LiveDuelServerEvent extends LiveDuelEvent {
  const LiveDuelServerEvent(this.event);

  final DuelRoomEvent event;

  @override
  List<Object?> get props => [event];
}

/// The 100 ms heartbeat of the screen's clocks.
final class LiveDuelTicked extends LiveDuelEvent {
  const LiveDuelTicked();
}

/// The player tapped option [index].
final class LiveDuelAnswerSelected extends LiveDuelEvent {
  const LiveDuelAnswerSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// The player confirmed "Leave the duel?".
final class LiveDuelQuitConfirmed extends LiveDuelEvent {
  const LiveDuelQuitConfirmed();
}

/// The app came back to the foreground — broadcasts may have been missed.
final class LiveDuelResumed extends LiveDuelEvent {
  const LiveDuelResumed();
}

/// The player tapped the speaker toggle (read-aloud + sound effects).
final class LiveDuelAudioToggled extends LiveDuelEvent {
  const LiveDuelAudioToggled();
}
