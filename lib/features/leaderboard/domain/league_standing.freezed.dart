// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'league_standing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LeagueStanding {

 int get rank; String get playerId; String get name; String get avatarEmoji; int get points; bool get isSelf;/// A Quizoo Pro member (plan 023) — drives the crown and the tick.
 bool get isPro;
/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeagueStandingCopyWith<LeagueStanding> get copyWith => _$LeagueStandingCopyWithImpl<LeagueStanding>(this as LeagueStanding, _$identity);

  /// Serializes this LeagueStanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeagueStanding&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.points, points) || other.points == points)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf)&&(identical(other.isPro, isPro) || other.isPro == isPro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,playerId,name,avatarEmoji,points,isSelf,isPro);

@override
String toString() {
  return 'LeagueStanding(rank: $rank, playerId: $playerId, name: $name, avatarEmoji: $avatarEmoji, points: $points, isSelf: $isSelf, isPro: $isPro)';
}


}

/// @nodoc
abstract mixin class $LeagueStandingCopyWith<$Res>  {
  factory $LeagueStandingCopyWith(LeagueStanding value, $Res Function(LeagueStanding) _then) = _$LeagueStandingCopyWithImpl;
@useResult
$Res call({
 int rank, String playerId, String name, String avatarEmoji, int points, bool isSelf, bool isPro
});




}
/// @nodoc
class _$LeagueStandingCopyWithImpl<$Res>
    implements $LeagueStandingCopyWith<$Res> {
  _$LeagueStandingCopyWithImpl(this._self, this._then);

  final LeagueStanding _self;
  final $Res Function(LeagueStanding) _then;

/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? playerId = null,Object? name = null,Object? avatarEmoji = null,Object? points = null,Object? isSelf = null,Object? isPro = null,}) {
  return _then(_self.copyWith(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LeagueStanding].
extension LeagueStandingPatterns on LeagueStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeagueStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeagueStanding value)  $default,){
final _that = this;
switch (_that) {
case _LeagueStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeagueStanding value)?  $default,){
final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String playerId,  String name,  String avatarEmoji,  int points,  bool isSelf,  bool isPro)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
return $default(_that.rank,_that.playerId,_that.name,_that.avatarEmoji,_that.points,_that.isSelf,_that.isPro);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String playerId,  String name,  String avatarEmoji,  int points,  bool isSelf,  bool isPro)  $default,) {final _that = this;
switch (_that) {
case _LeagueStanding():
return $default(_that.rank,_that.playerId,_that.name,_that.avatarEmoji,_that.points,_that.isSelf,_that.isPro);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String playerId,  String name,  String avatarEmoji,  int points,  bool isSelf,  bool isPro)?  $default,) {final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
return $default(_that.rank,_that.playerId,_that.name,_that.avatarEmoji,_that.points,_that.isSelf,_that.isPro);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeagueStanding implements LeagueStanding {
  const _LeagueStanding({required this.rank, required this.playerId, required this.name, required this.avatarEmoji, required this.points, this.isSelf = false, this.isPro = false});
  factory _LeagueStanding.fromJson(Map<String, dynamic> json) => _$LeagueStandingFromJson(json);

@override final  int rank;
@override final  String playerId;
@override final  String name;
@override final  String avatarEmoji;
@override final  int points;
@override@JsonKey() final  bool isSelf;
/// A Quizoo Pro member (plan 023) — drives the crown and the tick.
@override@JsonKey() final  bool isPro;

/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeagueStandingCopyWith<_LeagueStanding> get copyWith => __$LeagueStandingCopyWithImpl<_LeagueStanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeagueStandingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeagueStanding&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.points, points) || other.points == points)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf)&&(identical(other.isPro, isPro) || other.isPro == isPro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,playerId,name,avatarEmoji,points,isSelf,isPro);

@override
String toString() {
  return 'LeagueStanding(rank: $rank, playerId: $playerId, name: $name, avatarEmoji: $avatarEmoji, points: $points, isSelf: $isSelf, isPro: $isPro)';
}


}

/// @nodoc
abstract mixin class _$LeagueStandingCopyWith<$Res> implements $LeagueStandingCopyWith<$Res> {
  factory _$LeagueStandingCopyWith(_LeagueStanding value, $Res Function(_LeagueStanding) _then) = __$LeagueStandingCopyWithImpl;
@override @useResult
$Res call({
 int rank, String playerId, String name, String avatarEmoji, int points, bool isSelf, bool isPro
});




}
/// @nodoc
class __$LeagueStandingCopyWithImpl<$Res>
    implements _$LeagueStandingCopyWith<$Res> {
  __$LeagueStandingCopyWithImpl(this._self, this._then);

  final _LeagueStanding _self;
  final $Res Function(_LeagueStanding) _then;

/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? playerId = null,Object? name = null,Object? avatarEmoji = null,Object? points = null,Object? isSelf = null,Object? isPro = null,}) {
  return _then(_LeagueStanding(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
