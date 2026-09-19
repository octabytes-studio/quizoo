// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelResult {

 DuelOpponent get opponent; int get playerRoundsWon; int get opponentRoundsWon; double get playerAverageAnswerSeconds; double get opponentAverageAnswerSeconds; int get eloBefore; int get eloAfter; int get rewardCoins; List<String> get newlyEarnedBadgeIds;
/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelResultCopyWith<DuelResult> get copyWith => _$DuelResultCopyWithImpl<DuelResult>(this as DuelResult, _$identity);

  /// Serializes this DuelResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelResult&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.playerRoundsWon, playerRoundsWon) || other.playerRoundsWon == playerRoundsWon)&&(identical(other.opponentRoundsWon, opponentRoundsWon) || other.opponentRoundsWon == opponentRoundsWon)&&(identical(other.playerAverageAnswerSeconds, playerAverageAnswerSeconds) || other.playerAverageAnswerSeconds == playerAverageAnswerSeconds)&&(identical(other.opponentAverageAnswerSeconds, opponentAverageAnswerSeconds) || other.opponentAverageAnswerSeconds == opponentAverageAnswerSeconds)&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.rewardCoins, rewardCoins) || other.rewardCoins == rewardCoins)&&const DeepCollectionEquality().equals(other.newlyEarnedBadgeIds, newlyEarnedBadgeIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opponent,playerRoundsWon,opponentRoundsWon,playerAverageAnswerSeconds,opponentAverageAnswerSeconds,eloBefore,eloAfter,rewardCoins,const DeepCollectionEquality().hash(newlyEarnedBadgeIds));

@override
String toString() {
  return 'DuelResult(opponent: $opponent, playerRoundsWon: $playerRoundsWon, opponentRoundsWon: $opponentRoundsWon, playerAverageAnswerSeconds: $playerAverageAnswerSeconds, opponentAverageAnswerSeconds: $opponentAverageAnswerSeconds, eloBefore: $eloBefore, eloAfter: $eloAfter, rewardCoins: $rewardCoins, newlyEarnedBadgeIds: $newlyEarnedBadgeIds)';
}


}

/// @nodoc
abstract mixin class $DuelResultCopyWith<$Res>  {
  factory $DuelResultCopyWith(DuelResult value, $Res Function(DuelResult) _then) = _$DuelResultCopyWithImpl;
@useResult
$Res call({
 DuelOpponent opponent, int playerRoundsWon, int opponentRoundsWon, double playerAverageAnswerSeconds, double opponentAverageAnswerSeconds, int eloBefore, int eloAfter, int rewardCoins, List<String> newlyEarnedBadgeIds
});


$DuelOpponentCopyWith<$Res> get opponent;

}
/// @nodoc
class _$DuelResultCopyWithImpl<$Res>
    implements $DuelResultCopyWith<$Res> {
  _$DuelResultCopyWithImpl(this._self, this._then);

  final DuelResult _self;
  final $Res Function(DuelResult) _then;

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opponent = null,Object? playerRoundsWon = null,Object? opponentRoundsWon = null,Object? playerAverageAnswerSeconds = null,Object? opponentAverageAnswerSeconds = null,Object? eloBefore = null,Object? eloAfter = null,Object? rewardCoins = null,Object? newlyEarnedBadgeIds = null,}) {
  return _then(_self.copyWith(
opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as DuelOpponent,playerRoundsWon: null == playerRoundsWon ? _self.playerRoundsWon : playerRoundsWon // ignore: cast_nullable_to_non_nullable
as int,opponentRoundsWon: null == opponentRoundsWon ? _self.opponentRoundsWon : opponentRoundsWon // ignore: cast_nullable_to_non_nullable
as int,playerAverageAnswerSeconds: null == playerAverageAnswerSeconds ? _self.playerAverageAnswerSeconds : playerAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,opponentAverageAnswerSeconds: null == opponentAverageAnswerSeconds ? _self.opponentAverageAnswerSeconds : opponentAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,rewardCoins: null == rewardCoins ? _self.rewardCoins : rewardCoins // ignore: cast_nullable_to_non_nullable
as int,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self.newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelOpponentCopyWith<$Res> get opponent {
  
  return $DuelOpponentCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}
}


/// Adds pattern-matching-related methods to [DuelResult].
extension DuelResultPatterns on DuelResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelResult value)  $default,){
final _that = this;
switch (_that) {
case _DuelResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelResult value)?  $default,){
final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DuelOpponent opponent,  int playerRoundsWon,  int opponentRoundsWon,  double playerAverageAnswerSeconds,  double opponentAverageAnswerSeconds,  int eloBefore,  int eloAfter,  int rewardCoins,  List<String> newlyEarnedBadgeIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
return $default(_that.opponent,_that.playerRoundsWon,_that.opponentRoundsWon,_that.playerAverageAnswerSeconds,_that.opponentAverageAnswerSeconds,_that.eloBefore,_that.eloAfter,_that.rewardCoins,_that.newlyEarnedBadgeIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DuelOpponent opponent,  int playerRoundsWon,  int opponentRoundsWon,  double playerAverageAnswerSeconds,  double opponentAverageAnswerSeconds,  int eloBefore,  int eloAfter,  int rewardCoins,  List<String> newlyEarnedBadgeIds)  $default,) {final _that = this;
switch (_that) {
case _DuelResult():
return $default(_that.opponent,_that.playerRoundsWon,_that.opponentRoundsWon,_that.playerAverageAnswerSeconds,_that.opponentAverageAnswerSeconds,_that.eloBefore,_that.eloAfter,_that.rewardCoins,_that.newlyEarnedBadgeIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DuelOpponent opponent,  int playerRoundsWon,  int opponentRoundsWon,  double playerAverageAnswerSeconds,  double opponentAverageAnswerSeconds,  int eloBefore,  int eloAfter,  int rewardCoins,  List<String> newlyEarnedBadgeIds)?  $default,) {final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
return $default(_that.opponent,_that.playerRoundsWon,_that.opponentRoundsWon,_that.playerAverageAnswerSeconds,_that.opponentAverageAnswerSeconds,_that.eloBefore,_that.eloAfter,_that.rewardCoins,_that.newlyEarnedBadgeIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelResult extends DuelResult {
  const _DuelResult({required this.opponent, required this.playerRoundsWon, required this.opponentRoundsWon, required this.playerAverageAnswerSeconds, required this.opponentAverageAnswerSeconds, required this.eloBefore, required this.eloAfter, required this.rewardCoins, final  List<String> newlyEarnedBadgeIds = const []}): _newlyEarnedBadgeIds = newlyEarnedBadgeIds,super._();
  factory _DuelResult.fromJson(Map<String, dynamic> json) => _$DuelResultFromJson(json);

@override final  DuelOpponent opponent;
@override final  int playerRoundsWon;
@override final  int opponentRoundsWon;
@override final  double playerAverageAnswerSeconds;
@override final  double opponentAverageAnswerSeconds;
@override final  int eloBefore;
@override final  int eloAfter;
@override final  int rewardCoins;
 final  List<String> _newlyEarnedBadgeIds;
@override@JsonKey() List<String> get newlyEarnedBadgeIds {
  if (_newlyEarnedBadgeIds is EqualUnmodifiableListView) return _newlyEarnedBadgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newlyEarnedBadgeIds);
}


/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelResultCopyWith<_DuelResult> get copyWith => __$DuelResultCopyWithImpl<_DuelResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelResult&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.playerRoundsWon, playerRoundsWon) || other.playerRoundsWon == playerRoundsWon)&&(identical(other.opponentRoundsWon, opponentRoundsWon) || other.opponentRoundsWon == opponentRoundsWon)&&(identical(other.playerAverageAnswerSeconds, playerAverageAnswerSeconds) || other.playerAverageAnswerSeconds == playerAverageAnswerSeconds)&&(identical(other.opponentAverageAnswerSeconds, opponentAverageAnswerSeconds) || other.opponentAverageAnswerSeconds == opponentAverageAnswerSeconds)&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.rewardCoins, rewardCoins) || other.rewardCoins == rewardCoins)&&const DeepCollectionEquality().equals(other._newlyEarnedBadgeIds, _newlyEarnedBadgeIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opponent,playerRoundsWon,opponentRoundsWon,playerAverageAnswerSeconds,opponentAverageAnswerSeconds,eloBefore,eloAfter,rewardCoins,const DeepCollectionEquality().hash(_newlyEarnedBadgeIds));

@override
String toString() {
  return 'DuelResult(opponent: $opponent, playerRoundsWon: $playerRoundsWon, opponentRoundsWon: $opponentRoundsWon, playerAverageAnswerSeconds: $playerAverageAnswerSeconds, opponentAverageAnswerSeconds: $opponentAverageAnswerSeconds, eloBefore: $eloBefore, eloAfter: $eloAfter, rewardCoins: $rewardCoins, newlyEarnedBadgeIds: $newlyEarnedBadgeIds)';
}


}

/// @nodoc
abstract mixin class _$DuelResultCopyWith<$Res> implements $DuelResultCopyWith<$Res> {
  factory _$DuelResultCopyWith(_DuelResult value, $Res Function(_DuelResult) _then) = __$DuelResultCopyWithImpl;
@override @useResult
$Res call({
 DuelOpponent opponent, int playerRoundsWon, int opponentRoundsWon, double playerAverageAnswerSeconds, double opponentAverageAnswerSeconds, int eloBefore, int eloAfter, int rewardCoins, List<String> newlyEarnedBadgeIds
});


@override $DuelOpponentCopyWith<$Res> get opponent;

}
/// @nodoc
class __$DuelResultCopyWithImpl<$Res>
    implements _$DuelResultCopyWith<$Res> {
  __$DuelResultCopyWithImpl(this._self, this._then);

  final _DuelResult _self;
  final $Res Function(_DuelResult) _then;

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opponent = null,Object? playerRoundsWon = null,Object? opponentRoundsWon = null,Object? playerAverageAnswerSeconds = null,Object? opponentAverageAnswerSeconds = null,Object? eloBefore = null,Object? eloAfter = null,Object? rewardCoins = null,Object? newlyEarnedBadgeIds = null,}) {
  return _then(_DuelResult(
opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as DuelOpponent,playerRoundsWon: null == playerRoundsWon ? _self.playerRoundsWon : playerRoundsWon // ignore: cast_nullable_to_non_nullable
as int,opponentRoundsWon: null == opponentRoundsWon ? _self.opponentRoundsWon : opponentRoundsWon // ignore: cast_nullable_to_non_nullable
as int,playerAverageAnswerSeconds: null == playerAverageAnswerSeconds ? _self.playerAverageAnswerSeconds : playerAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,opponentAverageAnswerSeconds: null == opponentAverageAnswerSeconds ? _self.opponentAverageAnswerSeconds : opponentAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,rewardCoins: null == rewardCoins ? _self.rewardCoins : rewardCoins // ignore: cast_nullable_to_non_nullable
as int,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self._newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelOpponentCopyWith<$Res> get opponent {
  
  return $DuelOpponentCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}
}

// dart format on
