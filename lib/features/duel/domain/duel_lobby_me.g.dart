// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_lobby_me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelLobbyMe _$DuelLobbyMeFromJson(Map<String, dynamic> json) => _DuelLobbyMe(
  player: DuelPlayer.fromJson(json['player'] as Map<String, dynamic>),
  isGuest: json['isGuest'] as bool? ?? false,
  activeDuelId: json['activeDuelId'] as String?,
  openChallengeId: json['openChallengeId'] as String?,
  cooldownEndsAt: json['cooldownEndsAt'] == null
      ? null
      : DateTime.parse(json['cooldownEndsAt'] as String),
  challengesLeftToday: (json['challengesLeftToday'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DuelLobbyMeToJson(_DuelLobbyMe instance) =>
    <String, dynamic>{
      'player': instance.player,
      'isGuest': instance.isGuest,
      'activeDuelId': instance.activeDuelId,
      'openChallengeId': instance.openChallengeId,
      'cooldownEndsAt': instance.cooldownEndsAt?.toIso8601String(),
      'challengesLeftToday': instance.challengesLeftToday,
    };
