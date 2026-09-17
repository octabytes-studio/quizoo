// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  id: json['id'] as String,
  subcategoryId: json['subcategoryId'] as String,
  difficulty: (json['difficulty'] as num).toInt(),
  text: json['text'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctIndex: (json['correctIndex'] as num).toInt(),
  explanation: json['explanation'] as String,
  hasImage: json['hasImage'] as bool? ?? false,
  imageEmoji: json['imageEmoji'] as String?,
  imageAsset: json['imageAsset'] as String?,
  imageColorFrom: json['imageColorFrom'] as String? ?? '#2BB3FF',
  imageColorTo: json['imageColorTo'] as String? ?? '#7B4DFF',
  ttsExcluded: json['ttsExcluded'] as bool? ?? false,
  audioUrl: json['audioUrl'] as String?,
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'id': instance.id,
  'subcategoryId': instance.subcategoryId,
  'difficulty': instance.difficulty,
  'text': instance.text,
  'options': instance.options,
  'correctIndex': instance.correctIndex,
  'explanation': instance.explanation,
  'hasImage': instance.hasImage,
  'imageEmoji': instance.imageEmoji,
  'imageAsset': instance.imageAsset,
  'imageColorFrom': instance.imageColorFrom,
  'imageColorTo': instance.imageColorTo,
  'ttsExcluded': instance.ttsExcluded,
  'audioUrl': instance.audioUrl,
};
