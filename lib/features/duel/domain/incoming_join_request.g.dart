// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_join_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IncomingJoinRequest _$IncomingJoinRequestFromJson(Map<String, dynamic> json) =>
    _IncomingJoinRequest(
      requestId: json['requestId'] as String,
      challengeId: json['challengeId'] as String,
      requester: DuelPlayer.fromJson(json['requester'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      queuedCount: (json['queuedCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$IncomingJoinRequestToJson(
  _IncomingJoinRequest instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'challengeId': instance.challengeId,
  'requester': instance.requester,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'queuedCount': instance.queuedCount,
};
