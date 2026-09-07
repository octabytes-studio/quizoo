// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_opponent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelOpponent _$DuelOpponentFromJson(Map<String, dynamic> json) =>
    _DuelOpponent(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      elo: (json['elo'] as num).toInt(),
      isBot: json['isBot'] as bool? ?? true,
    );

Map<String, dynamic> _$DuelOpponentToJson(_DuelOpponent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarEmoji': instance.avatarEmoji,
      'elo': instance.elo,
      'isBot': instance.isBot,
    };
