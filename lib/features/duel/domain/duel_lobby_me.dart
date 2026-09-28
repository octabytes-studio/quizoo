import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';

part 'duel_lobby_me.freezed.dart';
part 'duel_lobby_me.g.dart';

/// The viewer's own standing in the arena, from `get_duel_lobby.me`.
@freezed
abstract class DuelLobbyMe with _$DuelLobbyMe {
  const factory DuelLobbyMe({
    required DuelPlayer player,
    @Default(false) bool isGuest,
    String? activeDuelId,
    String? openChallengeId,
    DateTime? cooldownEndsAt,
    @Default(0) int challengesLeftToday,
  }) = _DuelLobbyMe;

  factory DuelLobbyMe.fromJson(Map<String, dynamic> json) =>
      _$DuelLobbyMeFromJson(json);
}
