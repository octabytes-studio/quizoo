// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_lobby_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelLobbySnapshot _$DuelLobbySnapshotFromJson(
  Map<String, dynamic> json,
) => _DuelLobbySnapshot(
  serverNow: DateTime.parse(json['serverNow'] as String),
  config: DuelConfig.fromJson(json['config'] as Map<String, dynamic>),
  me: DuelLobbyMe.fromJson(json['me'] as Map<String, dynamic>),
  challenges:
      (json['challenges'] as List<dynamic>?)
          ?.map((e) => DuelChallenge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  myRequests:
      (json['myRequests'] as List<dynamic>?)
          ?.map((e) => OutgoingJoinRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  incoming: json['incoming'] == null
      ? null
      : IncomingJoinRequest.fromJson(json['incoming'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DuelLobbySnapshotToJson(_DuelLobbySnapshot instance) =>
    <String, dynamic>{
      'serverNow': instance.serverNow.toIso8601String(),
      'config': instance.config,
      'me': instance.me,
      'challenges': instance.challenges,
      'myRequests': instance.myRequests,
      'incoming': instance.incoming,
    };
