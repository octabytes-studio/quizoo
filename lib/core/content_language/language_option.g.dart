// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LanguageOption _$LanguageOptionFromJson(Map<String, dynamic> json) =>
    _LanguageOption(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['nativeName'] as String,
      isRtl: json['isRtl'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$LanguageOptionToJson(_LanguageOption instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'nativeName': instance.nativeName,
      'isRtl': instance.isRtl,
      'sortOrder': instance.sortOrder,
    };
