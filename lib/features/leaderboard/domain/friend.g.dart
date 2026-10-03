// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Friend _$FriendFromJson(Map<String, dynamic> json) => _Friend(
  id: json['id'] as String,
  name: json['name'] as String,
  avatarEmoji: json['avatarEmoji'] as String,
  status: $enumDecode(_$FriendStatusEnumMap, json['status']),
  subtitle: json['subtitle'] as String,
  isPro: json['isPro'] as bool? ?? false,
);

Map<String, dynamic> _$FriendToJson(_Friend instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatarEmoji': instance.avatarEmoji,
  'status': _$FriendStatusEnumMap[instance.status]!,
  'subtitle': instance.subtitle,
  'isPro': instance.isPro,
};

const _$FriendStatusEnumMap = {
  FriendStatus.pending: 'pending',
  FriendStatus.online: 'online',
  FriendStatus.offline: 'offline',
};
