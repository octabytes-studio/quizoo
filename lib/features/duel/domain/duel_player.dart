import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_elo_band.dart';

part 'duel_player.freezed.dart';
part 'duel_player.g.dart';

/// One side of a duel — the player themself, a real opponent, or the
/// labelled practice bot (plan 017).
///
/// JSON keys match the server's `_duel_player_json` exactly; `avatar` is the
/// profile's `avatar_key` emoji. [name] is null for guests, who are shown as
/// "Guest {guestTag}" instead (plan 017, Decision 4).
@freezed
abstract class DuelPlayer with _$DuelPlayer {
  const factory DuelPlayer({
    required String id,
    required String? name,
    @JsonKey(name: 'avatar') required String avatarEmoji,
    required int elo,
    @Default(false) bool isGuest,
    String? guestTag,
    @Default('bronze') String league,
    @Default(0) int topicLevel,
    @Default(false) bool isBot,
  }) = _DuelPlayer;

  const DuelPlayer._();

  factory DuelPlayer.fromJson(Map<String, dynamic> json) =>
      _$DuelPlayerFromJson(json);

  DuelEloBand get eloBand => switch (elo) {
    < 1000 => DuelEloBand.bronze,
    < 1400 => DuelEloBand.silver,
    < 1800 => DuelEloBand.gold,
    _ => DuelEloBand.platinum,
  };
}
