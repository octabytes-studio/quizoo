// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outgoing_join_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OutgoingJoinRequest _$OutgoingJoinRequestFromJson(Map<String, dynamic> json) =>
    _OutgoingJoinRequest(
      requestId: json['requestId'] as String,
      challengeId: json['challengeId'] as String,
      status: $enumDecode(
        _$JoinRequestStatusEnumMap,
        json['status'],
        unknownValue: JoinRequestStatus.unavailable,
      ),
      position: (json['position'] as num?)?.toInt(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      retryAfter: json['retryAfter'] == null
          ? null
          : DateTime.parse(json['retryAfter'] as String),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$OutgoingJoinRequestToJson(
  _OutgoingJoinRequest instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'challengeId': instance.challengeId,
  'status': _$JoinRequestStatusEnumMap[instance.status]!,
  'position': instance.position,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'retryAfter': instance.retryAfter?.toIso8601String(),
  'reason': instance.reason,
};

const _$JoinRequestStatusEnumMap = {
  JoinRequestStatus.queued: 'queued',
  JoinRequestStatus.pending: 'pending',
  JoinRequestStatus.accepted: 'accepted',
  JoinRequestStatus.declined: 'declined',
  JoinRequestStatus.expired: 'expired',
  JoinRequestStatus.withdrawn: 'withdrawn',
  JoinRequestStatus.unavailable: 'unavailable',
};
