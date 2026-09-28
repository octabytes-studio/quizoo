import 'package:equatable/equatable.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

/// Where the player stands in the matchmaking queue — what `join_matchmaking`
/// and `matchmaking_heartbeat` answer with (plan 017, "Matchmaking").
sealed class MatchmakingTicket extends Equatable {
  const MatchmakingTicket();

  @override
  List<Object?> get props => const [];
}

/// Still searching. [bandMin]–[bandMax] is the ELO range currently accepted;
/// it widens server-side as [queuedAt] recedes.
final class MatchmakingQueued extends MatchmakingTicket {
  const MatchmakingQueued({
    required this.queuedAt,
    required this.bandMin,
    required this.bandMax,
    required this.elo,
    required this.botAvailable,
    required this.me,
    required this.topic,
    required this.serverNow,
    this.botAvailableAt,
  });

  final DateTime queuedAt;
  final int bandMin;
  final int bandMax;
  final int elo;

  /// True once the player has waited long enough to be offered the labelled
  /// practice bot.
  final bool botAvailable;
  final DateTime? botAvailableAt;
  final DuelPlayer me;
  final DuelTopic topic;
  final DateTime serverNow;

  @override
  List<Object?> get props => [
    queuedAt,
    bandMin,
    bandMax,
    elo,
    botAvailable,
    botAvailableAt,
    me,
    topic,
    serverNow,
  ];
}

/// Paired — the server already created the duel.
final class MatchmakingMatched extends MatchmakingTicket {
  const MatchmakingMatched(this.duelId);

  final String duelId;

  @override
  List<Object?> get props => [duelId];
}
