// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Friend {

 String get id; String get name; String get avatarEmoji; FriendStatus get status;/// "Level 22 · Gold League" for a request, "🟢 Playing Cricket now" or
/// "Last seen 2h ago · 142k pts" for a friend — precomputed by the
/// fixture, since it is presentation copy over otherwise-identical data.
 String get subtitle;/// A Quizoo Pro member (plan 023) — drives the crown and the tick.
 bool get isPro;
/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendCopyWith<Friend> get copyWith => _$FriendCopyWithImpl<Friend>(this as Friend, _$identity);

  /// Serializes this Friend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Friend&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isPro, isPro) || other.isPro == isPro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarEmoji,status,subtitle,isPro);

@override
String toString() {
  return 'Friend(id: $id, name: $name, avatarEmoji: $avatarEmoji, status: $status, subtitle: $subtitle, isPro: $isPro)';
}


}

/// @nodoc
abstract mixin class $FriendCopyWith<$Res>  {
  factory $FriendCopyWith(Friend value, $Res Function(Friend) _then) = _$FriendCopyWithImpl;
@useResult
$Res call({
 String id, String name, String avatarEmoji, FriendStatus status, String subtitle, bool isPro
});




}
/// @nodoc
class _$FriendCopyWithImpl<$Res>
    implements $FriendCopyWith<$Res> {
  _$FriendCopyWithImpl(this._self, this._then);

  final Friend _self;
  final $Res Function(Friend) _then;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatarEmoji = null,Object? status = null,Object? subtitle = null,Object? isPro = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FriendStatus,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Friend].
extension FriendPatterns on Friend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Friend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Friend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Friend value)  $default,){
final _that = this;
switch (_that) {
case _Friend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Friend value)?  $default,){
final _that = this;
switch (_that) {
case _Friend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String avatarEmoji,  FriendStatus status,  String subtitle,  bool isPro)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Friend() when $default != null:
return $default(_that.id,_that.name,_that.avatarEmoji,_that.status,_that.subtitle,_that.isPro);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String avatarEmoji,  FriendStatus status,  String subtitle,  bool isPro)  $default,) {final _that = this;
switch (_that) {
case _Friend():
return $default(_that.id,_that.name,_that.avatarEmoji,_that.status,_that.subtitle,_that.isPro);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String avatarEmoji,  FriendStatus status,  String subtitle,  bool isPro)?  $default,) {final _that = this;
switch (_that) {
case _Friend() when $default != null:
return $default(_that.id,_that.name,_that.avatarEmoji,_that.status,_that.subtitle,_that.isPro);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Friend implements Friend {
  const _Friend({required this.id, required this.name, required this.avatarEmoji, required this.status, required this.subtitle, this.isPro = false});
  factory _Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);

@override final  String id;
@override final  String name;
@override final  String avatarEmoji;
@override final  FriendStatus status;
/// "Level 22 · Gold League" for a request, "🟢 Playing Cricket now" or
/// "Last seen 2h ago · 142k pts" for a friend — precomputed by the
/// fixture, since it is presentation copy over otherwise-identical data.
@override final  String subtitle;
/// A Quizoo Pro member (plan 023) — drives the crown and the tick.
@override@JsonKey() final  bool isPro;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendCopyWith<_Friend> get copyWith => __$FriendCopyWithImpl<_Friend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Friend&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isPro, isPro) || other.isPro == isPro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarEmoji,status,subtitle,isPro);

@override
String toString() {
  return 'Friend(id: $id, name: $name, avatarEmoji: $avatarEmoji, status: $status, subtitle: $subtitle, isPro: $isPro)';
}


}

/// @nodoc
abstract mixin class _$FriendCopyWith<$Res> implements $FriendCopyWith<$Res> {
  factory _$FriendCopyWith(_Friend value, $Res Function(_Friend) _then) = __$FriendCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String avatarEmoji, FriendStatus status, String subtitle, bool isPro
});




}
/// @nodoc
class __$FriendCopyWithImpl<$Res>
    implements _$FriendCopyWith<$Res> {
  __$FriendCopyWithImpl(this._self, this._then);

  final _Friend _self;
  final $Res Function(_Friend) _then;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarEmoji = null,Object? status = null,Object? subtitle = null,Object? isPro = null,}) {
  return _then(_Friend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FriendStatus,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
