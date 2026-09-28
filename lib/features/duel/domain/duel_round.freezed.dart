// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_round.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelRoundRecord {

 int get roundNumber; bool get playerCorrect; bool get opponentCorrect; int get playerAnswerSeconds; int get opponentAnswerSeconds; RoundOutcome get outcome; int? get correctIndex; int? get playerChoice; int? get opponentChoice;
/// Create a copy of DuelRoundRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelRoundRecordCopyWith<DuelRoundRecord> get copyWith => _$DuelRoundRecordCopyWithImpl<DuelRoundRecord>(this as DuelRoundRecord, _$identity);

  /// Serializes this DuelRoundRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelRoundRecord&&(identical(other.roundNumber, roundNumber) || other.roundNumber == roundNumber)&&(identical(other.playerCorrect, playerCorrect) || other.playerCorrect == playerCorrect)&&(identical(other.opponentCorrect, opponentCorrect) || other.opponentCorrect == opponentCorrect)&&(identical(other.playerAnswerSeconds, playerAnswerSeconds) || other.playerAnswerSeconds == playerAnswerSeconds)&&(identical(other.opponentAnswerSeconds, opponentAnswerSeconds) || other.opponentAnswerSeconds == opponentAnswerSeconds)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.correctIndex, correctIndex) || other.correctIndex == correctIndex)&&(identical(other.playerChoice, playerChoice) || other.playerChoice == playerChoice)&&(identical(other.opponentChoice, opponentChoice) || other.opponentChoice == opponentChoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roundNumber,playerCorrect,opponentCorrect,playerAnswerSeconds,opponentAnswerSeconds,outcome,correctIndex,playerChoice,opponentChoice);

@override
String toString() {
  return 'DuelRoundRecord(roundNumber: $roundNumber, playerCorrect: $playerCorrect, opponentCorrect: $opponentCorrect, playerAnswerSeconds: $playerAnswerSeconds, opponentAnswerSeconds: $opponentAnswerSeconds, outcome: $outcome, correctIndex: $correctIndex, playerChoice: $playerChoice, opponentChoice: $opponentChoice)';
}


}

/// @nodoc
abstract mixin class $DuelRoundRecordCopyWith<$Res>  {
  factory $DuelRoundRecordCopyWith(DuelRoundRecord value, $Res Function(DuelRoundRecord) _then) = _$DuelRoundRecordCopyWithImpl;
@useResult
$Res call({
 int roundNumber, bool playerCorrect, bool opponentCorrect, int playerAnswerSeconds, int opponentAnswerSeconds, RoundOutcome outcome, int? correctIndex, int? playerChoice, int? opponentChoice
});




}
/// @nodoc
class _$DuelRoundRecordCopyWithImpl<$Res>
    implements $DuelRoundRecordCopyWith<$Res> {
  _$DuelRoundRecordCopyWithImpl(this._self, this._then);

  final DuelRoundRecord _self;
  final $Res Function(DuelRoundRecord) _then;

/// Create a copy of DuelRoundRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roundNumber = null,Object? playerCorrect = null,Object? opponentCorrect = null,Object? playerAnswerSeconds = null,Object? opponentAnswerSeconds = null,Object? outcome = null,Object? correctIndex = freezed,Object? playerChoice = freezed,Object? opponentChoice = freezed,}) {
  return _then(_self.copyWith(
roundNumber: null == roundNumber ? _self.roundNumber : roundNumber // ignore: cast_nullable_to_non_nullable
as int,playerCorrect: null == playerCorrect ? _self.playerCorrect : playerCorrect // ignore: cast_nullable_to_non_nullable
as bool,opponentCorrect: null == opponentCorrect ? _self.opponentCorrect : opponentCorrect // ignore: cast_nullable_to_non_nullable
as bool,playerAnswerSeconds: null == playerAnswerSeconds ? _self.playerAnswerSeconds : playerAnswerSeconds // ignore: cast_nullable_to_non_nullable
as int,opponentAnswerSeconds: null == opponentAnswerSeconds ? _self.opponentAnswerSeconds : opponentAnswerSeconds // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as RoundOutcome,correctIndex: freezed == correctIndex ? _self.correctIndex : correctIndex // ignore: cast_nullable_to_non_nullable
as int?,playerChoice: freezed == playerChoice ? _self.playerChoice : playerChoice // ignore: cast_nullable_to_non_nullable
as int?,opponentChoice: freezed == opponentChoice ? _self.opponentChoice : opponentChoice // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelRoundRecord].
extension DuelRoundRecordPatterns on DuelRoundRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelRoundRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelRoundRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelRoundRecord value)  $default,){
final _that = this;
switch (_that) {
case _DuelRoundRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelRoundRecord value)?  $default,){
final _that = this;
switch (_that) {
case _DuelRoundRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int roundNumber,  bool playerCorrect,  bool opponentCorrect,  int playerAnswerSeconds,  int opponentAnswerSeconds,  RoundOutcome outcome,  int? correctIndex,  int? playerChoice,  int? opponentChoice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelRoundRecord() when $default != null:
return $default(_that.roundNumber,_that.playerCorrect,_that.opponentCorrect,_that.playerAnswerSeconds,_that.opponentAnswerSeconds,_that.outcome,_that.correctIndex,_that.playerChoice,_that.opponentChoice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int roundNumber,  bool playerCorrect,  bool opponentCorrect,  int playerAnswerSeconds,  int opponentAnswerSeconds,  RoundOutcome outcome,  int? correctIndex,  int? playerChoice,  int? opponentChoice)  $default,) {final _that = this;
switch (_that) {
case _DuelRoundRecord():
return $default(_that.roundNumber,_that.playerCorrect,_that.opponentCorrect,_that.playerAnswerSeconds,_that.opponentAnswerSeconds,_that.outcome,_that.correctIndex,_that.playerChoice,_that.opponentChoice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int roundNumber,  bool playerCorrect,  bool opponentCorrect,  int playerAnswerSeconds,  int opponentAnswerSeconds,  RoundOutcome outcome,  int? correctIndex,  int? playerChoice,  int? opponentChoice)?  $default,) {final _that = this;
switch (_that) {
case _DuelRoundRecord() when $default != null:
return $default(_that.roundNumber,_that.playerCorrect,_that.opponentCorrect,_that.playerAnswerSeconds,_that.opponentAnswerSeconds,_that.outcome,_that.correctIndex,_that.playerChoice,_that.opponentChoice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelRoundRecord extends DuelRoundRecord {
  const _DuelRoundRecord({required this.roundNumber, required this.playerCorrect, required this.opponentCorrect, required this.playerAnswerSeconds, required this.opponentAnswerSeconds, required this.outcome, this.correctIndex, this.playerChoice, this.opponentChoice}): super._();
  factory _DuelRoundRecord.fromJson(Map<String, dynamic> json) => _$DuelRoundRecordFromJson(json);

@override final  int roundNumber;
@override final  bool playerCorrect;
@override final  bool opponentCorrect;
@override final  int playerAnswerSeconds;
@override final  int opponentAnswerSeconds;
@override final  RoundOutcome outcome;
@override final  int? correctIndex;
@override final  int? playerChoice;
@override final  int? opponentChoice;

/// Create a copy of DuelRoundRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelRoundRecordCopyWith<_DuelRoundRecord> get copyWith => __$DuelRoundRecordCopyWithImpl<_DuelRoundRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelRoundRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelRoundRecord&&(identical(other.roundNumber, roundNumber) || other.roundNumber == roundNumber)&&(identical(other.playerCorrect, playerCorrect) || other.playerCorrect == playerCorrect)&&(identical(other.opponentCorrect, opponentCorrect) || other.opponentCorrect == opponentCorrect)&&(identical(other.playerAnswerSeconds, playerAnswerSeconds) || other.playerAnswerSeconds == playerAnswerSeconds)&&(identical(other.opponentAnswerSeconds, opponentAnswerSeconds) || other.opponentAnswerSeconds == opponentAnswerSeconds)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.correctIndex, correctIndex) || other.correctIndex == correctIndex)&&(identical(other.playerChoice, playerChoice) || other.playerChoice == playerChoice)&&(identical(other.opponentChoice, opponentChoice) || other.opponentChoice == opponentChoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roundNumber,playerCorrect,opponentCorrect,playerAnswerSeconds,opponentAnswerSeconds,outcome,correctIndex,playerChoice,opponentChoice);

@override
String toString() {
  return 'DuelRoundRecord(roundNumber: $roundNumber, playerCorrect: $playerCorrect, opponentCorrect: $opponentCorrect, playerAnswerSeconds: $playerAnswerSeconds, opponentAnswerSeconds: $opponentAnswerSeconds, outcome: $outcome, correctIndex: $correctIndex, playerChoice: $playerChoice, opponentChoice: $opponentChoice)';
}


}

/// @nodoc
abstract mixin class _$DuelRoundRecordCopyWith<$Res> implements $DuelRoundRecordCopyWith<$Res> {
  factory _$DuelRoundRecordCopyWith(_DuelRoundRecord value, $Res Function(_DuelRoundRecord) _then) = __$DuelRoundRecordCopyWithImpl;
@override @useResult
$Res call({
 int roundNumber, bool playerCorrect, bool opponentCorrect, int playerAnswerSeconds, int opponentAnswerSeconds, RoundOutcome outcome, int? correctIndex, int? playerChoice, int? opponentChoice
});




}
/// @nodoc
class __$DuelRoundRecordCopyWithImpl<$Res>
    implements _$DuelRoundRecordCopyWith<$Res> {
  __$DuelRoundRecordCopyWithImpl(this._self, this._then);

  final _DuelRoundRecord _self;
  final $Res Function(_DuelRoundRecord) _then;

/// Create a copy of DuelRoundRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roundNumber = null,Object? playerCorrect = null,Object? opponentCorrect = null,Object? playerAnswerSeconds = null,Object? opponentAnswerSeconds = null,Object? outcome = null,Object? correctIndex = freezed,Object? playerChoice = freezed,Object? opponentChoice = freezed,}) {
  return _then(_DuelRoundRecord(
roundNumber: null == roundNumber ? _self.roundNumber : roundNumber // ignore: cast_nullable_to_non_nullable
as int,playerCorrect: null == playerCorrect ? _self.playerCorrect : playerCorrect // ignore: cast_nullable_to_non_nullable
as bool,opponentCorrect: null == opponentCorrect ? _self.opponentCorrect : opponentCorrect // ignore: cast_nullable_to_non_nullable
as bool,playerAnswerSeconds: null == playerAnswerSeconds ? _self.playerAnswerSeconds : playerAnswerSeconds // ignore: cast_nullable_to_non_nullable
as int,opponentAnswerSeconds: null == opponentAnswerSeconds ? _self.opponentAnswerSeconds : opponentAnswerSeconds // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as RoundOutcome,correctIndex: freezed == correctIndex ? _self.correctIndex : correctIndex // ignore: cast_nullable_to_non_nullable
as int?,playerChoice: freezed == playerChoice ? _self.playerChoice : playerChoice // ignore: cast_nullable_to_non_nullable
as int?,opponentChoice: freezed == opponentChoice ? _self.opponentChoice : opponentChoice // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
