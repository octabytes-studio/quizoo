// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelConfig _$DuelConfigFromJson(Map<String, dynamic> json) => _DuelConfig(
  challengeTtlSeconds: (json['challengeTtlSeconds'] as num?)?.toInt() ?? 300,
  cooldownSeconds: (json['cooldownSeconds'] as num?)?.toInt() ?? 120,
  joinWindowSeconds: (json['joinWindowSeconds'] as num?)?.toInt() ?? 5,
  lobbyHeartbeatSeconds: (json['lobbyHeartbeatSeconds'] as num?)?.toInt() ?? 10,
  mmHeartbeatSeconds: (json['mmHeartbeatSeconds'] as num?)?.toInt() ?? 3,
  botAfterSeconds: (json['botAfterSeconds'] as num?)?.toInt() ?? 30,
  bandStepSeconds: (json['bandStepSeconds'] as num?)?.toInt() ?? 5,
  rounds: (json['rounds'] as num?)?.toInt() ?? 10,
  roundSeconds: (json['roundSeconds'] as num?)?.toInt() ?? 15,
  revealSeconds: (json['revealSeconds'] as num?)?.toInt() ?? 2,
  introSeconds: (json['introSeconds'] as num?)?.toInt() ?? 3,
  duelHeartbeatSeconds: (json['duelHeartbeatSeconds'] as num?)?.toInt() ?? 5,
  rematchWindowSeconds: (json['rematchWindowSeconds'] as num?)?.toInt() ?? 30,
  presenceEnabled: json['presenceEnabled'] as bool? ?? true,
  winCoins: (json['winCoins'] as num?)?.toInt() ?? 200,
);

Map<String, dynamic> _$DuelConfigToJson(_DuelConfig instance) =>
    <String, dynamic>{
      'challengeTtlSeconds': instance.challengeTtlSeconds,
      'cooldownSeconds': instance.cooldownSeconds,
      'joinWindowSeconds': instance.joinWindowSeconds,
      'lobbyHeartbeatSeconds': instance.lobbyHeartbeatSeconds,
      'mmHeartbeatSeconds': instance.mmHeartbeatSeconds,
      'botAfterSeconds': instance.botAfterSeconds,
      'bandStepSeconds': instance.bandStepSeconds,
      'rounds': instance.rounds,
      'roundSeconds': instance.roundSeconds,
      'revealSeconds': instance.revealSeconds,
      'introSeconds': instance.introSeconds,
      'duelHeartbeatSeconds': instance.duelHeartbeatSeconds,
      'rematchWindowSeconds': instance.rematchWindowSeconds,
      'presenceEnabled': instance.presenceEnabled,
      'winCoins': instance.winCoins,
    };
