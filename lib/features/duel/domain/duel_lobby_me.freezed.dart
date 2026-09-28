// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_lobby_me.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelLobbyMe {

 DuelPlayer get player; bool get isGuest; String? get activeDuelId; String? get openChallengeId; DateTime? get cooldownEndsAt; int get challengesLeftToday;
/// Create a copy of DuelLobbyMe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelLobbyMeCopyWith<DuelLobbyMe> get copyWith => _$DuelLobbyMeCopyWithImpl<DuelLobbyMe>(this as DuelLobbyMe, _$identity);

  /// Serializes this DuelLobbyMe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelLobbyMe&&(identical(other.player, player) || other.player == player)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.activeDuelId, activeDuelId) || other.activeDuelId == activeDuelId)&&(identical(other.openChallengeId, openChallengeId) || other.openChallengeId == openChallengeId)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt)&&(identical(other.challengesLeftToday, challengesLeftToday) || other.challengesLeftToday == challengesLeftToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,player,isGuest,activeDuelId,openChallengeId,cooldownEndsAt,challengesLeftToday);

@override
String toString() {
  return 'DuelLobbyMe(player: $player, isGuest: $isGuest, activeDuelId: $activeDuelId, openChallengeId: $openChallengeId, cooldownEndsAt: $cooldownEndsAt, challengesLeftToday: $challengesLeftToday)';
}


}

/// @nodoc
abstract mixin class $DuelLobbyMeCopyWith<$Res>  {
  factory $DuelLobbyMeCopyWith(DuelLobbyMe value, $Res Function(DuelLobbyMe) _then) = _$DuelLobbyMeCopyWithImpl;
@useResult
$Res call({
 DuelPlayer player, bool isGuest, String? activeDuelId, String? openChallengeId, DateTime? cooldownEndsAt, int challengesLeftToday
});


$DuelPlayerCopyWith<$Res> get player;

}
/// @nodoc
class _$DuelLobbyMeCopyWithImpl<$Res>
    implements $DuelLobbyMeCopyWith<$Res> {
  _$DuelLobbyMeCopyWithImpl(this._self, this._then);

  final DuelLobbyMe _self;
  final $Res Function(DuelLobbyMe) _then;

/// Create a copy of DuelLobbyMe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? isGuest = null,Object? activeDuelId = freezed,Object? openChallengeId = freezed,Object? cooldownEndsAt = freezed,Object? challengesLeftToday = null,}) {
  return _then(_self.copyWith(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as DuelPlayer,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,activeDuelId: freezed == activeDuelId ? _self.activeDuelId : activeDuelId // ignore: cast_nullable_to_non_nullable
as String?,openChallengeId: freezed == openChallengeId ? _self.openChallengeId : openChallengeId // ignore: cast_nullable_to_non_nullable
as String?,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,challengesLeftToday: null == challengesLeftToday ? _self.challengesLeftToday : challengesLeftToday // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of DuelLobbyMe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get player {
  
  return $DuelPlayerCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [DuelLobbyMe].
extension DuelLobbyMePatterns on DuelLobbyMe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelLobbyMe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelLobbyMe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelLobbyMe value)  $default,){
final _that = this;
switch (_that) {
case _DuelLobbyMe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelLobbyMe value)?  $default,){
final _that = this;
switch (_that) {
case _DuelLobbyMe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DuelPlayer player,  bool isGuest,  String? activeDuelId,  String? openChallengeId,  DateTime? cooldownEndsAt,  int challengesLeftToday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelLobbyMe() when $default != null:
return $default(_that.player,_that.isGuest,_that.activeDuelId,_that.openChallengeId,_that.cooldownEndsAt,_that.challengesLeftToday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DuelPlayer player,  bool isGuest,  String? activeDuelId,  String? openChallengeId,  DateTime? cooldownEndsAt,  int challengesLeftToday)  $default,) {final _that = this;
switch (_that) {
case _DuelLobbyMe():
return $default(_that.player,_that.isGuest,_that.activeDuelId,_that.openChallengeId,_that.cooldownEndsAt,_that.challengesLeftToday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DuelPlayer player,  bool isGuest,  String? activeDuelId,  String? openChallengeId,  DateTime? cooldownEndsAt,  int challengesLeftToday)?  $default,) {final _that = this;
switch (_that) {
case _DuelLobbyMe() when $default != null:
return $default(_that.player,_that.isGuest,_that.activeDuelId,_that.openChallengeId,_that.cooldownEndsAt,_that.challengesLeftToday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelLobbyMe implements DuelLobbyMe {
  const _DuelLobbyMe({required this.player, this.isGuest = false, this.activeDuelId, this.openChallengeId, this.cooldownEndsAt, this.challengesLeftToday = 0});
  factory _DuelLobbyMe.fromJson(Map<String, dynamic> json) => _$DuelLobbyMeFromJson(json);

@override final  DuelPlayer player;
@override@JsonKey() final  bool isGuest;
@override final  String? activeDuelId;
@override final  String? openChallengeId;
@override final  DateTime? cooldownEndsAt;
@override@JsonKey() final  int challengesLeftToday;

/// Create a copy of DuelLobbyMe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelLobbyMeCopyWith<_DuelLobbyMe> get copyWith => __$DuelLobbyMeCopyWithImpl<_DuelLobbyMe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelLobbyMeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelLobbyMe&&(identical(other.player, player) || other.player == player)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.activeDuelId, activeDuelId) || other.activeDuelId == activeDuelId)&&(identical(other.openChallengeId, openChallengeId) || other.openChallengeId == openChallengeId)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt)&&(identical(other.challengesLeftToday, challengesLeftToday) || other.challengesLeftToday == challengesLeftToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,player,isGuest,activeDuelId,openChallengeId,cooldownEndsAt,challengesLeftToday);

@override
String toString() {
  return 'DuelLobbyMe(player: $player, isGuest: $isGuest, activeDuelId: $activeDuelId, openChallengeId: $openChallengeId, cooldownEndsAt: $cooldownEndsAt, challengesLeftToday: $challengesLeftToday)';
}


}

/// @nodoc
abstract mixin class _$DuelLobbyMeCopyWith<$Res> implements $DuelLobbyMeCopyWith<$Res> {
  factory _$DuelLobbyMeCopyWith(_DuelLobbyMe value, $Res Function(_DuelLobbyMe) _then) = __$DuelLobbyMeCopyWithImpl;
@override @useResult
$Res call({
 DuelPlayer player, bool isGuest, String? activeDuelId, String? openChallengeId, DateTime? cooldownEndsAt, int challengesLeftToday
});


@override $DuelPlayerCopyWith<$Res> get player;

}
/// @nodoc
class __$DuelLobbyMeCopyWithImpl<$Res>
    implements _$DuelLobbyMeCopyWith<$Res> {
  __$DuelLobbyMeCopyWithImpl(this._self, this._then);

  final _DuelLobbyMe _self;
  final $Res Function(_DuelLobbyMe) _then;

/// Create a copy of DuelLobbyMe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? isGuest = null,Object? activeDuelId = freezed,Object? openChallengeId = freezed,Object? cooldownEndsAt = freezed,Object? challengesLeftToday = null,}) {
  return _then(_DuelLobbyMe(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as DuelPlayer,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,activeDuelId: freezed == activeDuelId ? _self.activeDuelId : activeDuelId // ignore: cast_nullable_to_non_nullable
as String?,openChallengeId: freezed == openChallengeId ? _self.openChallengeId : openChallengeId // ignore: cast_nullable_to_non_nullable
as String?,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,challengesLeftToday: null == challengesLeftToday ? _self.challengesLeftToday : challengesLeftToday // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of DuelLobbyMe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get player {
  
  return $DuelPlayerCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}

// dart format on
