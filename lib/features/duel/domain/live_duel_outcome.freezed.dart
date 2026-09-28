// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_duel_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveDuelOutcome {

 String get reason; bool get won; bool get draw; int get eloBefore; int get eloAfter; int get coins; int get xp; List<String> get badgeIds; bool get opponentForfeited; bool get youForfeited; double? get myAvgMs; double? get opponentAvgMs; String? get cause;
/// Create a copy of LiveDuelOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveDuelOutcomeCopyWith<LiveDuelOutcome> get copyWith => _$LiveDuelOutcomeCopyWithImpl<LiveDuelOutcome>(this as LiveDuelOutcome, _$identity);

  /// Serializes this LiveDuelOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveDuelOutcome&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.won, won) || other.won == won)&&(identical(other.draw, draw) || other.draw == draw)&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.xp, xp) || other.xp == xp)&&const DeepCollectionEquality().equals(other.badgeIds, badgeIds)&&(identical(other.opponentForfeited, opponentForfeited) || other.opponentForfeited == opponentForfeited)&&(identical(other.youForfeited, youForfeited) || other.youForfeited == youForfeited)&&(identical(other.myAvgMs, myAvgMs) || other.myAvgMs == myAvgMs)&&(identical(other.opponentAvgMs, opponentAvgMs) || other.opponentAvgMs == opponentAvgMs)&&(identical(other.cause, cause) || other.cause == cause));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,won,draw,eloBefore,eloAfter,coins,xp,const DeepCollectionEquality().hash(badgeIds),opponentForfeited,youForfeited,myAvgMs,opponentAvgMs,cause);

@override
String toString() {
  return 'LiveDuelOutcome(reason: $reason, won: $won, draw: $draw, eloBefore: $eloBefore, eloAfter: $eloAfter, coins: $coins, xp: $xp, badgeIds: $badgeIds, opponentForfeited: $opponentForfeited, youForfeited: $youForfeited, myAvgMs: $myAvgMs, opponentAvgMs: $opponentAvgMs, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $LiveDuelOutcomeCopyWith<$Res>  {
  factory $LiveDuelOutcomeCopyWith(LiveDuelOutcome value, $Res Function(LiveDuelOutcome) _then) = _$LiveDuelOutcomeCopyWithImpl;
@useResult
$Res call({
 String reason, bool won, bool draw, int eloBefore, int eloAfter, int coins, int xp, List<String> badgeIds, bool opponentForfeited, bool youForfeited, double? myAvgMs, double? opponentAvgMs, String? cause
});




}
/// @nodoc
class _$LiveDuelOutcomeCopyWithImpl<$Res>
    implements $LiveDuelOutcomeCopyWith<$Res> {
  _$LiveDuelOutcomeCopyWithImpl(this._self, this._then);

  final LiveDuelOutcome _self;
  final $Res Function(LiveDuelOutcome) _then;

/// Create a copy of LiveDuelOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,Object? won = null,Object? draw = null,Object? eloBefore = null,Object? eloAfter = null,Object? coins = null,Object? xp = null,Object? badgeIds = null,Object? opponentForfeited = null,Object? youForfeited = null,Object? myAvgMs = freezed,Object? opponentAvgMs = freezed,Object? cause = freezed,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as bool,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as bool,eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,badgeIds: null == badgeIds ? _self.badgeIds : badgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,opponentForfeited: null == opponentForfeited ? _self.opponentForfeited : opponentForfeited // ignore: cast_nullable_to_non_nullable
as bool,youForfeited: null == youForfeited ? _self.youForfeited : youForfeited // ignore: cast_nullable_to_non_nullable
as bool,myAvgMs: freezed == myAvgMs ? _self.myAvgMs : myAvgMs // ignore: cast_nullable_to_non_nullable
as double?,opponentAvgMs: freezed == opponentAvgMs ? _self.opponentAvgMs : opponentAvgMs // ignore: cast_nullable_to_non_nullable
as double?,cause: freezed == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveDuelOutcome].
extension LiveDuelOutcomePatterns on LiveDuelOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveDuelOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveDuelOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveDuelOutcome value)  $default,){
final _that = this;
switch (_that) {
case _LiveDuelOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveDuelOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _LiveDuelOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reason,  bool won,  bool draw,  int eloBefore,  int eloAfter,  int coins,  int xp,  List<String> badgeIds,  bool opponentForfeited,  bool youForfeited,  double? myAvgMs,  double? opponentAvgMs,  String? cause)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveDuelOutcome() when $default != null:
return $default(_that.reason,_that.won,_that.draw,_that.eloBefore,_that.eloAfter,_that.coins,_that.xp,_that.badgeIds,_that.opponentForfeited,_that.youForfeited,_that.myAvgMs,_that.opponentAvgMs,_that.cause);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reason,  bool won,  bool draw,  int eloBefore,  int eloAfter,  int coins,  int xp,  List<String> badgeIds,  bool opponentForfeited,  bool youForfeited,  double? myAvgMs,  double? opponentAvgMs,  String? cause)  $default,) {final _that = this;
switch (_that) {
case _LiveDuelOutcome():
return $default(_that.reason,_that.won,_that.draw,_that.eloBefore,_that.eloAfter,_that.coins,_that.xp,_that.badgeIds,_that.opponentForfeited,_that.youForfeited,_that.myAvgMs,_that.opponentAvgMs,_that.cause);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reason,  bool won,  bool draw,  int eloBefore,  int eloAfter,  int coins,  int xp,  List<String> badgeIds,  bool opponentForfeited,  bool youForfeited,  double? myAvgMs,  double? opponentAvgMs,  String? cause)?  $default,) {final _that = this;
switch (_that) {
case _LiveDuelOutcome() when $default != null:
return $default(_that.reason,_that.won,_that.draw,_that.eloBefore,_that.eloAfter,_that.coins,_that.xp,_that.badgeIds,_that.opponentForfeited,_that.youForfeited,_that.myAvgMs,_that.opponentAvgMs,_that.cause);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveDuelOutcome implements LiveDuelOutcome {
  const _LiveDuelOutcome({required this.reason, this.won = false, this.draw = false, this.eloBefore = 0, this.eloAfter = 0, this.coins = 0, this.xp = 0, final  List<String> badgeIds = const [], this.opponentForfeited = false, this.youForfeited = false, this.myAvgMs, this.opponentAvgMs, this.cause}): _badgeIds = badgeIds;
  factory _LiveDuelOutcome.fromJson(Map<String, dynamic> json) => _$LiveDuelOutcomeFromJson(json);

@override final  String reason;
@override@JsonKey() final  bool won;
@override@JsonKey() final  bool draw;
@override@JsonKey() final  int eloBefore;
@override@JsonKey() final  int eloAfter;
@override@JsonKey() final  int coins;
@override@JsonKey() final  int xp;
 final  List<String> _badgeIds;
@override@JsonKey() List<String> get badgeIds {
  if (_badgeIds is EqualUnmodifiableListView) return _badgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badgeIds);
}

@override@JsonKey() final  bool opponentForfeited;
@override@JsonKey() final  bool youForfeited;
@override final  double? myAvgMs;
@override final  double? opponentAvgMs;
@override final  String? cause;

/// Create a copy of LiveDuelOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveDuelOutcomeCopyWith<_LiveDuelOutcome> get copyWith => __$LiveDuelOutcomeCopyWithImpl<_LiveDuelOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveDuelOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveDuelOutcome&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.won, won) || other.won == won)&&(identical(other.draw, draw) || other.draw == draw)&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.xp, xp) || other.xp == xp)&&const DeepCollectionEquality().equals(other._badgeIds, _badgeIds)&&(identical(other.opponentForfeited, opponentForfeited) || other.opponentForfeited == opponentForfeited)&&(identical(other.youForfeited, youForfeited) || other.youForfeited == youForfeited)&&(identical(other.myAvgMs, myAvgMs) || other.myAvgMs == myAvgMs)&&(identical(other.opponentAvgMs, opponentAvgMs) || other.opponentAvgMs == opponentAvgMs)&&(identical(other.cause, cause) || other.cause == cause));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,won,draw,eloBefore,eloAfter,coins,xp,const DeepCollectionEquality().hash(_badgeIds),opponentForfeited,youForfeited,myAvgMs,opponentAvgMs,cause);

@override
String toString() {
  return 'LiveDuelOutcome(reason: $reason, won: $won, draw: $draw, eloBefore: $eloBefore, eloAfter: $eloAfter, coins: $coins, xp: $xp, badgeIds: $badgeIds, opponentForfeited: $opponentForfeited, youForfeited: $youForfeited, myAvgMs: $myAvgMs, opponentAvgMs: $opponentAvgMs, cause: $cause)';
}


}

/// @nodoc
abstract mixin class _$LiveDuelOutcomeCopyWith<$Res> implements $LiveDuelOutcomeCopyWith<$Res> {
  factory _$LiveDuelOutcomeCopyWith(_LiveDuelOutcome value, $Res Function(_LiveDuelOutcome) _then) = __$LiveDuelOutcomeCopyWithImpl;
@override @useResult
$Res call({
 String reason, bool won, bool draw, int eloBefore, int eloAfter, int coins, int xp, List<String> badgeIds, bool opponentForfeited, bool youForfeited, double? myAvgMs, double? opponentAvgMs, String? cause
});




}
/// @nodoc
class __$LiveDuelOutcomeCopyWithImpl<$Res>
    implements _$LiveDuelOutcomeCopyWith<$Res> {
  __$LiveDuelOutcomeCopyWithImpl(this._self, this._then);

  final _LiveDuelOutcome _self;
  final $Res Function(_LiveDuelOutcome) _then;

/// Create a copy of LiveDuelOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? won = null,Object? draw = null,Object? eloBefore = null,Object? eloAfter = null,Object? coins = null,Object? xp = null,Object? badgeIds = null,Object? opponentForfeited = null,Object? youForfeited = null,Object? myAvgMs = freezed,Object? opponentAvgMs = freezed,Object? cause = freezed,}) {
  return _then(_LiveDuelOutcome(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as bool,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as bool,eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,badgeIds: null == badgeIds ? _self._badgeIds : badgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,opponentForfeited: null == opponentForfeited ? _self.opponentForfeited : opponentForfeited // ignore: cast_nullable_to_non_nullable
as bool,youForfeited: null == youForfeited ? _self.youForfeited : youForfeited // ignore: cast_nullable_to_non_nullable
as bool,myAvgMs: freezed == myAvgMs ? _self.myAvgMs : myAvgMs // ignore: cast_nullable_to_non_nullable
as double?,opponentAvgMs: freezed == opponentAvgMs ? _self.opponentAvgMs : opponentAvgMs // ignore: cast_nullable_to_non_nullable
as double?,cause: freezed == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
