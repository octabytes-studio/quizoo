// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  soundOn: json['soundOn'] as bool? ?? true,
  musicOn: json['musicOn'] as bool? ?? false,
  hapticsOn: json['hapticsOn'] as bool? ?? true,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'soundOn': instance.soundOn,
      'musicOn': instance.musicOn,
      'hapticsOn': instance.hapticsOn,
    };
