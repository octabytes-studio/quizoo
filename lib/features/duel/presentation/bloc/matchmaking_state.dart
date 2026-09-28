part of 'matchmaking_cubit.dart';

/// S-39's states (CLAUDE.md §3).
sealed class MatchmakingState extends Equatable {
  const MatchmakingState();

  @override
  List<Object?> get props => const [];
}

/// `join_matchmaking` is in flight.
final class MatchmakingJoining extends MatchmakingState {
  const MatchmakingJoining();
}

/// Queued and waiting for the server to pair us.
///
/// [bandMin]–[bandMax] is the ELO range the server last reported; it widens
/// server-side every `bandStepSeconds`, and the next heartbeat brings the new
/// range. [elapsedSeconds] counts from the server's `queuedAt` on the shared
/// [ServerClock], so it survives a slow first response.
final class MatchmakingSearching extends MatchmakingState {
  const MatchmakingSearching({
    required this.me,
    required this.topic,
    required this.elapsedSeconds,
    required this.bandMin,
    required this.bandMax,
    required this.secondsToNextWiden,
    required this.botAvailable,
    this.botOfferSnoozedUntil,
    this.isStartingBot = false,
  });

  final DuelPlayer me;
  final DuelTopic topic;
  final int elapsedSeconds;
  final int bandMin;
  final int bandMax;
  final int secondsToNextWiden;

  /// The server's "you have waited long enough for the labelled bot" flag.
  final bool botAvailable;

  /// "Keep searching" hides the bot offer until [elapsedSeconds] reaches
  /// this value. Null until the player first dismisses the offer.
  final int? botOfferSnoozedUntil;

  /// `playBot()` is in flight — the offer's button is disabled meanwhile.
  final bool isStartingBot;

  /// Whether the `MatchmakingBotOffer` card is up.
  bool get showBotOffer =>
      botAvailable && elapsedSeconds >= (botOfferSnoozedUntil ?? 0);

  @override
  List<Object?> get props => [
    me,
    topic,
    elapsedSeconds,
    bandMin,
    bandMax,
    secondsToNextWiden,
    botAvailable,
    botOfferSnoozedUntil,
    isStartingBot,
  ];
}

/// Paired with a real player — the server already created the duel.
final class MatchmakingFound extends MatchmakingState {
  const MatchmakingFound(this.duelId);

  final String duelId;

  @override
  List<Object?> get props => [duelId];
}

/// The player took the labelled practice bot instead of waiting.
///
/// [opponent] is always `isBot: true` — never a secret bot (bible §14).
final class MatchmakingBotReady extends MatchmakingState {
  const MatchmakingBotReady({
    required this.me,
    required this.opponent,
    required this.topic,
  });

  final DuelPlayer me;
  final DuelPlayer opponent;
  final DuelTopic topic;

  @override
  List<Object?> get props => [me, opponent, topic];
}

/// Joining the queue failed (or the queue row vanished twice in a row).
final class MatchmakingFailed extends MatchmakingState {
  const MatchmakingFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.code, error.message];
}
