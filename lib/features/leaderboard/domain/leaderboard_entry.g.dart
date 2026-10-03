// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    _LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      score: (json['score'] as num).toInt(),
      locationLabel: json['locationLabel'] as String?,
      rankDelta: (json['rankDelta'] as num?)?.toInt(),
      isSelf: json['isSelf'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
      topPercent: (json['topPercent'] as num?)?.toInt(),
      levelsCleared: (json['levelsCleared'] as num?)?.toInt(),
      levelCount: (json['levelCount'] as num?)?.toInt(),
      starsEarned: (json['starsEarned'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LeaderboardEntryToJson(_LeaderboardEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'playerId': instance.playerId,
      'name': instance.name,
      'avatarEmoji': instance.avatarEmoji,
      'score': instance.score,
      'locationLabel': instance.locationLabel,
      'rankDelta': instance.rankDelta,
      'isSelf': instance.isSelf,
      'isPro': instance.isPro,
      'topPercent': instance.topPercent,
      'levelsCleared': instance.levelsCleared,
      'levelCount': instance.levelCount,
      'starsEarned': instance.starsEarned,
    };
