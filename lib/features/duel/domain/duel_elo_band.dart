/// The ELO bands a [DuelEloBand]-keyed bot timing table is scripted from.
///
/// Moved out of the old `duel_opponent.dart` unchanged (plan 017): the bands
/// only ever drove the labelled practice bot's behaviour, which a real
/// opponent never needs.
enum DuelEloBand { bronze, silver, gold, platinum }

/// How fast, and how accurately, a bot in each band answers.
///
/// A small fixed table rather than a real opponent model — the practice bot
/// is always this scripted timing, never a second live client, and is always
/// labelled as a bot (bible §14, "never a secret bot").
extension DuelBotTiming on DuelEloBand {
  /// The bot's average time-to-answer.
  Duration get averageAnswerTime => switch (this) {
    DuelEloBand.bronze => const Duration(seconds: 9),
    DuelEloBand.silver => const Duration(seconds: 6),
    DuelEloBand.gold => const Duration(seconds: 4),
    DuelEloBand.platinum => const Duration(milliseconds: 2500),
  };

  /// The chance the bot answers correctly.
  double get accuracy => switch (this) {
    DuelEloBand.bronze => 0.55,
    DuelEloBand.silver => 0.65,
    DuelEloBand.gold => 0.78,
    DuelEloBand.platinum => 0.9,
  };
}
