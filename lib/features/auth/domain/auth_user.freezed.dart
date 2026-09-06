// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthUser {

 String get id; String get displayName; AuthProvider get provider;/// The avatar the player picked on S-25, or the mascot they start with.
 String get avatarEmoji; String? get email; String? get countryName; String? get countryFlag;/// False until the player has been through S-25. A vendor sign-in skips
/// it, so most users are complete the moment they arrive.
 bool get isProfileComplete;
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserCopyWith<AuthUser> get copyWith => _$AuthUserCopyWithImpl<AuthUser>(this as AuthUser, _$identity);

  /// Serializes this AuthUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.email, email) || other.email == email)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.countryFlag, countryFlag) || other.countryFlag == countryFlag)&&(identical(other.isProfileComplete, isProfileComplete) || other.isProfileComplete == isProfileComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,provider,avatarEmoji,email,countryName,countryFlag,isProfileComplete);

@override
String toString() {
  return 'AuthUser(id: $id, displayName: $displayName, provider: $provider, avatarEmoji: $avatarEmoji, email: $email, countryName: $countryName, countryFlag: $countryFlag, isProfileComplete: $isProfileComplete)';
}


}

/// @nodoc
abstract mixin class $AuthUserCopyWith<$Res>  {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) _then) = _$AuthUserCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, AuthProvider provider, String avatarEmoji, String? email, String? countryName, String? countryFlag, bool isProfileComplete
});




}
/// @nodoc
class _$AuthUserCopyWithImpl<$Res>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._self, this._then);

  final AuthUser _self;
  final $Res Function(AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? provider = null,Object? avatarEmoji = null,Object? email = freezed,Object? countryName = freezed,Object? countryFlag = freezed,Object? isProfileComplete = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AuthProvider,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,countryName: freezed == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String?,countryFlag: freezed == countryFlag ? _self.countryFlag : countryFlag // ignore: cast_nullable_to_non_nullable
as String?,isProfileComplete: null == isProfileComplete ? _self.isProfileComplete : isProfileComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthUser].
extension AuthUserPatterns on AuthUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUser value)  $default,){
final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUser value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  AuthProvider provider,  String avatarEmoji,  String? email,  String? countryName,  String? countryFlag,  bool isProfileComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.displayName,_that.provider,_that.avatarEmoji,_that.email,_that.countryName,_that.countryFlag,_that.isProfileComplete);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  AuthProvider provider,  String avatarEmoji,  String? email,  String? countryName,  String? countryFlag,  bool isProfileComplete)  $default,) {final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that.id,_that.displayName,_that.provider,_that.avatarEmoji,_that.email,_that.countryName,_that.countryFlag,_that.isProfileComplete);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  AuthProvider provider,  String avatarEmoji,  String? email,  String? countryName,  String? countryFlag,  bool isProfileComplete)?  $default,) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.displayName,_that.provider,_that.avatarEmoji,_that.email,_that.countryName,_that.countryFlag,_that.isProfileComplete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthUser implements AuthUser {
  const _AuthUser({required this.id, required this.displayName, required this.provider, this.avatarEmoji = '🐼', this.email, this.countryName, this.countryFlag, this.isProfileComplete = true});
  factory _AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  AuthProvider provider;
/// The avatar the player picked on S-25, or the mascot they start with.
@override@JsonKey() final  String avatarEmoji;
@override final  String? email;
@override final  String? countryName;
@override final  String? countryFlag;
/// False until the player has been through S-25. A vendor sign-in skips
/// it, so most users are complete the moment they arrive.
@override@JsonKey() final  bool isProfileComplete;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserCopyWith<_AuthUser> get copyWith => __$AuthUserCopyWithImpl<_AuthUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.email, email) || other.email == email)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.countryFlag, countryFlag) || other.countryFlag == countryFlag)&&(identical(other.isProfileComplete, isProfileComplete) || other.isProfileComplete == isProfileComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,provider,avatarEmoji,email,countryName,countryFlag,isProfileComplete);

@override
String toString() {
  return 'AuthUser(id: $id, displayName: $displayName, provider: $provider, avatarEmoji: $avatarEmoji, email: $email, countryName: $countryName, countryFlag: $countryFlag, isProfileComplete: $isProfileComplete)';
}


}

/// @nodoc
abstract mixin class _$AuthUserCopyWith<$Res> implements $AuthUserCopyWith<$Res> {
  factory _$AuthUserCopyWith(_AuthUser value, $Res Function(_AuthUser) _then) = __$AuthUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, AuthProvider provider, String avatarEmoji, String? email, String? countryName, String? countryFlag, bool isProfileComplete
});




}
/// @nodoc
class __$AuthUserCopyWithImpl<$Res>
    implements _$AuthUserCopyWith<$Res> {
  __$AuthUserCopyWithImpl(this._self, this._then);

  final _AuthUser _self;
  final $Res Function(_AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? provider = null,Object? avatarEmoji = null,Object? email = freezed,Object? countryName = freezed,Object? countryFlag = freezed,Object? isProfileComplete = null,}) {
  return _then(_AuthUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AuthProvider,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,countryName: freezed == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String?,countryFlag: freezed == countryFlag ? _self.countryFlag : countryFlag // ignore: cast_nullable_to_non_nullable
as String?,isProfileComplete: null == isProfileComplete ? _self.isProfileComplete : isProfileComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
