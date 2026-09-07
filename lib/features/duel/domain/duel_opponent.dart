import 'package:freezed_annotation/freezed_annotation.dart';

part 'duel_opponent.freezed.dart';
part 'duel_opponent.g.dart';

/// The ELO bands `MatchmakingCubit` widens through and `DuelPlayCubit` scripts
/// the bot's timing table from.
enum DuelEloBand { bronze, silver, gold, platinum }

/// How fast, and how accurately, a bot in each band answers.
///
/// A small fixed table rather than a real opponent model — plan 004's Scope
/// is explicit that duel networking is out of this series, so the "opponent"
/// is always this scripted timing, never a second live client.
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

/// A duel opponent.
///
/// [isBot] defaults `true` because this mock phase never has a real second
/// player — the bible's "never a secret bot" rule (§14) means the field
/// exists so the UI's bot badge is driven by data rather than a hardcoded
/// assumption, ready for a real opponent the day matchmaking is real.
@freezed
abstract class DuelOpponent with _$DuelOpponent {
  const factory DuelOpponent({
    required String id,
    required String name,
    required String avatarEmoji,
    required int elo,
    @Default(true) bool isBot,
  }) = _DuelOpponent;

  const DuelOpponent._();

  factory DuelOpponent.fromJson(Map<String, dynamic> json) =>
      _$DuelOpponentFromJson(json);

  DuelEloBand get eloBand => switch (elo) {
    < 1000 => DuelEloBand.bronze,
    < 1400 => DuelEloBand.silver,
    < 1800 => DuelEloBand.gold,
    _ => DuelEloBand.platinum,
  };
}
