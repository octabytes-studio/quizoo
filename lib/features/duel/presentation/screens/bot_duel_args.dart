import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

/// The `extra` the labelled practice-bot duel (`AppRoutes.duelBot`) is
/// pushed with: both players and the topic its questions come from
/// (plan 017 — formerly `DuelPlayArgs`, which carried only the opponent).
class BotDuelArgs {
  const BotDuelArgs({
    required this.me,
    required this.opponent,
    required this.topic,
  });

  final DuelPlayer me;

  /// Always `isBot: true` — never a secret bot (bible §14).
  final DuelPlayer opponent;
  final DuelTopic topic;
}
