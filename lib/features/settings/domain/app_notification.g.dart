// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      kind: $enumDecode(_$NotificationKindEnumMap, json['kind']),
      title: json['title'] as String,
      body: json['body'] as String,
      timeLabel: json['timeLabel'] as String,
      isRead: json['isRead'] as bool? ?? false,
      challengerName: json['challengerName'] as String?,
      challengerAvatarEmoji: json['challengerAvatarEmoji'] as String?,
      challengerElo: (json['challengerElo'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$NotificationKindEnumMap[instance.kind]!,
      'title': instance.title,
      'body': instance.body,
      'timeLabel': instance.timeLabel,
      'isRead': instance.isRead,
      'challengerName': instance.challengerName,
      'challengerAvatarEmoji': instance.challengerAvatarEmoji,
      'challengerElo': instance.challengerElo,
    };

const _$NotificationKindEnumMap = {
  NotificationKind.duelChallenge: 'duelChallenge',
  NotificationKind.streakEnding: 'streakEnding',
  NotificationKind.leagueRankDrop: 'leagueRankDrop',
  NotificationKind.newContent: 'newContent',
  NotificationKind.rewardClaimed: 'rewardClaimed',
};
