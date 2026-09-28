// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelTopic _$DuelTopicFromJson(Map<String, dynamic> json) => _DuelTopic(
  id: json['id'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String,
  plateColor: json['plateColor'] as String,
  categoryName: json['categoryName'] as String,
  categoryEmoji: json['categoryEmoji'] as String,
  categoryId: json['categoryId'] as String? ?? '',
  myTopicLevel: (json['myTopicLevel'] as num?)?.toInt() ?? 0,
  openChallenges: (json['openChallenges'] as num?)?.toInt() ?? 0,
  searching: (json['searching'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DuelTopicToJson(_DuelTopic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'emoji': instance.emoji,
      'plateColor': instance.plateColor,
      'categoryName': instance.categoryName,
      'categoryEmoji': instance.categoryEmoji,
      'categoryId': instance.categoryId,
      'myTopicLevel': instance.myTopicLevel,
      'openChallenges': instance.openChallenges,
      'searching': instance.searching,
    };
