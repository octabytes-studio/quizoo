part of 'bot_rematch_cubit.dart';

/// S-41's "Rematch" for a practice-bot duel (plan 017, Phase 11).
sealed class BotRematchState extends Equatable {
  const BotRematchState();

  @override
  List<Object?> get props => const [];
}

/// "Rematch" is tappable.
final class BotRematchIdle extends BotRematchState {
  const BotRematchIdle();
}

/// Dealing the next bot.
final class BotRematchLoading extends BotRematchState {
  const BotRematchLoading();
}

/// The next bot duel is ready to start — [me] carries the ELO the last duel
/// left the player on.
final class BotRematchFound extends BotRematchState {
  const BotRematchFound({
    required this.me,
    required this.opponent,
    required this.topic,
  });

  final DuelPlayer me;

  /// Always `isBot: true` — never a secret bot (bible §14).
  final DuelPlayer opponent;
  final DuelTopic topic;

  @override
  List<Object?> get props => [me, opponent, topic];
}

/// No bot could be dealt; "Rematch" is tappable again.
final class BotRematchFailed extends BotRematchState {
  const BotRematchFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.code, error.message];
}
