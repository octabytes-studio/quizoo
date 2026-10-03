// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelPlayer _$DuelPlayerFromJson(Map<String, dynamic> json) => _DuelPlayer(
  id: json['id'] as String,
  name: json['name'] as String?,
  avatarEmoji: json['avatar'] as String,
  elo: (json['elo'] as num).toInt(),
  isGuest: json['isGuest'] as bool? ?? false,
  guestTag: json['guestTag'] as String?,
  league: json['league'] as String? ?? 'bronze',
  topicLevel: (json['topicLevel'] as num?)?.toInt() ?? 0,
  isBot: json['isBot'] as bool? ?? false,
  isPro: json['isPro'] as bool? ?? false,
);

Map<String, dynamic> _$DuelPlayerToJson(_DuelPlayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatarEmoji,
      'elo': instance.elo,
      'isGuest': instance.isGuest,
      'guestTag': instance.guestTag,
      'league': instance.league,
      'topicLevel': instance.topicLevel,
      'isBot': instance.isBot,
      'isPro': instance.isPro,
    };
