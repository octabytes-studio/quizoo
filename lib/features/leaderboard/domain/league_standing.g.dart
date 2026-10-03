// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league_standing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LeagueStanding _$LeagueStandingFromJson(Map<String, dynamic> json) =>
    _LeagueStanding(
      rank: (json['rank'] as num).toInt(),
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      points: (json['points'] as num).toInt(),
      isSelf: json['isSelf'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
    );

Map<String, dynamic> _$LeagueStandingToJson(_LeagueStanding instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'playerId': instance.playerId,
      'name': instance.name,
      'avatarEmoji': instance.avatarEmoji,
      'points': instance.points,
      'isSelf': instance.isSelf,
      'isPro': instance.isPro,
    };
