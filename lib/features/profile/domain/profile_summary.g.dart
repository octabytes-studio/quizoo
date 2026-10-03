// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BestCategoryEntry _$BestCategoryEntryFromJson(Map<String, dynamic> json) =>
    _BestCategoryEntry(
      subcategoryId: json['subcategoryId'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      plateColor: json['plateColor'] as String,
      levelsCleared: (json['levelsCleared'] as num).toInt(),
      levelCount: (json['levelCount'] as num).toInt(),
      starsEarned: (json['starsEarned'] as num).toInt(),
      accuracyPercent: (json['accuracyPercent'] as num).toInt(),
    );

Map<String, dynamic> _$BestCategoryEntryToJson(_BestCategoryEntry instance) =>
    <String, dynamic>{
      'subcategoryId': instance.subcategoryId,
      'name': instance.name,
      'emoji': instance.emoji,
      'plateColor': instance.plateColor,
      'levelsCleared': instance.levelsCleared,
      'levelCount': instance.levelCount,
      'starsEarned': instance.starsEarned,
      'accuracyPercent': instance.accuracyPercent,
    };

_ProfileSummary _$ProfileSummaryFromJson(Map<String, dynamic> json) =>
    _ProfileSummary(
      username: json['username'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      cityLabel: json['cityLabel'] as String,
      joinedLabel: json['joinedLabel'] as String,
      leagueEmoji: json['leagueEmoji'] as String,
      leagueName: json['leagueName'] as String,
      dayStreak: (json['dayStreak'] as num).toInt(),
      playerLevel: (json['playerLevel'] as num).toInt(),
      rankTitle: json['rankTitle'] as String,
      xpIntoLevel: (json['xpIntoLevel'] as num).toInt(),
      xpToNextLevel: (json['xpToNextLevel'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      totalLevels: (json['totalLevels'] as num).toInt(),
      accuracyPercent: (json['accuracyPercent'] as num).toInt(),
      badgeCount: (json['badgeCount'] as num).toInt(),
      recentBadges: (json['recentBadges'] as List<dynamic>)
          .map((e) => AppBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestCategories: (json['bestCategories'] as List<dynamic>)
          .map((e) => BestCategoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPro: json['isPro'] as bool? ?? false,
    );

Map<String, dynamic> _$ProfileSummaryToJson(_ProfileSummary instance) =>
    <String, dynamic>{
      'username': instance.username,
      'avatarEmoji': instance.avatarEmoji,
      'cityLabel': instance.cityLabel,
      'joinedLabel': instance.joinedLabel,
      'leagueEmoji': instance.leagueEmoji,
      'leagueName': instance.leagueName,
      'dayStreak': instance.dayStreak,
      'playerLevel': instance.playerLevel,
      'rankTitle': instance.rankTitle,
      'xpIntoLevel': instance.xpIntoLevel,
      'xpToNextLevel': instance.xpToNextLevel,
      'totalPoints': instance.totalPoints,
      'totalLevels': instance.totalLevels,
      'accuracyPercent': instance.accuracyPercent,
      'badgeCount': instance.badgeCount,
      'recentBadges': instance.recentBadges,
      'bestCategories': instance.bestCategories,
      'isPro': instance.isPro,
    };
