// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelChallenge _$DuelChallengeFromJson(Map<String, dynamic> json) =>
    _DuelChallenge(
      id: json['id'] as String,
      status: $enumDecode(_$ChallengeStatusEnumMap, json['status']),
      creatorPresent: json['creatorPresent'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      creator: DuelPlayer.fromJson(json['creator'] as Map<String, dynamic>),
      topic: DuelTopic.fromJson(json['topic'] as Map<String, dynamic>),
      opponentName: json['opponentName'] as String?,
      opponentGuestTag: json['opponentGuestTag'] as String?,
      duelId: json['duelId'] as String?,
      endReason: json['endReason'] as String?,
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
    );

Map<String, dynamic> _$DuelChallengeToJson(_DuelChallenge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$ChallengeStatusEnumMap[instance.status]!,
      'creatorPresent': instance.creatorPresent,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'creator': instance.creator,
      'topic': instance.topic,
      'opponentName': instance.opponentName,
      'opponentGuestTag': instance.opponentGuestTag,
      'duelId': instance.duelId,
      'endReason': instance.endReason,
      'endedAt': instance.endedAt?.toIso8601String(),
    };

const _$ChallengeStatusEnumMap = {
  ChallengeStatus.open: 'open',
  ChallengeStatus.matched: 'matched',
  ChallengeStatus.ended: 'ended',
};
