// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvatarOption _$AvatarOptionFromJson(Map<String, dynamic> json) =>
    _AvatarOption(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      isPro: json['isPro'] as bool? ?? false,
    );

Map<String, dynamic> _$AvatarOptionToJson(_AvatarOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'emoji': instance.emoji,
      'sortOrder': instance.sortOrder,
      'isPro': instance.isPro,
    };
