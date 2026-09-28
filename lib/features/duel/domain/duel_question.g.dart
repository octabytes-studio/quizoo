// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelQuestion _$DuelQuestionFromJson(Map<String, dynamic> json) =>
    _DuelQuestion(
      text: json['prompt'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      kind: json['kind'] as String? ?? 'text',
      mediaUrl: json['mediaUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      ttsExcluded: json['ttsExcluded'] as bool? ?? false,
    );

Map<String, dynamic> _$DuelQuestionToJson(_DuelQuestion instance) =>
    <String, dynamic>{
      'prompt': instance.text,
      'options': instance.options,
      'kind': instance.kind,
      'mediaUrl': instance.mediaUrl,
      'audioUrl': instance.audioUrl,
      'ttsExcluded': instance.ttsExcluded,
    };
