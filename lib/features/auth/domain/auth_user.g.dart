// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => _AuthUser(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  provider: $enumDecode(_$AuthProviderEnumMap, json['provider']),
  avatarEmoji: json['avatarEmoji'] as String? ?? '🐼',
  email: json['email'] as String?,
  countryName: json['countryName'] as String?,
  countryFlag: json['countryFlag'] as String?,
  isProfileComplete: json['isProfileComplete'] as bool? ?? true,
  suggestedDisplayName: json['suggestedDisplayName'] as String?,
);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'provider': _$AuthProviderEnumMap[instance.provider]!,
  'avatarEmoji': instance.avatarEmoji,
  'email': instance.email,
  'countryName': instance.countryName,
  'countryFlag': instance.countryFlag,
  'isProfileComplete': instance.isProfileComplete,
  'suggestedDisplayName': instance.suggestedDisplayName,
};

const _$AuthProviderEnumMap = {
  AuthProvider.google: 'google',
  AuthProvider.apple: 'apple',
  AuthProvider.email: 'email',
};
