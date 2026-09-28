// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_duel_round_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveDuelRoundState {

 int get number; DateTime? get startsAt; DateTime? get deadline; bool get myLocked; int? get myChoice; int? get myMs; bool get opponentLocked; int? get opponentMs; DuelQuestion? get question;
/// Create a copy of LiveDuelRoundState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveDuelRoundStateCopyWith<LiveDuelRoundState> get copyWith => _$LiveDuelRoundStateCopyWithImpl<LiveDuelRoundState>(this as LiveDuelRoundState, _$identity);

  /// Serializes this LiveDuelRoundState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveDuelRoundState&&(identical(other.number, number) || other.number == number)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.myLocked, myLocked) || other.myLocked == myLocked)&&(identical(other.myChoice, myChoice) || other.myChoice == myChoice)&&(identical(other.myMs, myMs) || other.myMs == myMs)&&(identical(other.opponentLocked, opponentLocked) || other.opponentLocked == opponentLocked)&&(identical(other.opponentMs, opponentMs) || other.opponentMs == opponentMs)&&(identical(other.question, question) || other.question == question));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,startsAt,deadline,myLocked,myChoice,myMs,opponentLocked,opponentMs,question);

@override
String toString() {
  return 'LiveDuelRoundState(number: $number, startsAt: $startsAt, deadline: $deadline, myLocked: $myLocked, myChoice: $myChoice, myMs: $myMs, opponentLocked: $opponentLocked, opponentMs: $opponentMs, question: $question)';
}


}

/// @nodoc
abstract mixin class $LiveDuelRoundStateCopyWith<$Res>  {
  factory $LiveDuelRoundStateCopyWith(LiveDuelRoundState value, $Res Function(LiveDuelRoundState) _then) = _$LiveDuelRoundStateCopyWithImpl;
@useResult
$Res call({
 int number, DateTime? startsAt, DateTime? deadline, bool myLocked, int? myChoice, int? myMs, bool opponentLocked, int? opponentMs, DuelQuestion? question
});


$DuelQuestionCopyWith<$Res>? get question;

}
/// @nodoc
class _$LiveDuelRoundStateCopyWithImpl<$Res>
    implements $LiveDuelRoundStateCopyWith<$Res> {
  _$LiveDuelRoundStateCopyWithImpl(this._self, this._then);

  final LiveDuelRoundState _self;
  final $Res Function(LiveDuelRoundState) _then;

/// Create a copy of LiveDuelRoundState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? startsAt = freezed,Object? deadline = freezed,Object? myLocked = null,Object? myChoice = freezed,Object? myMs = freezed,Object? opponentLocked = null,Object? opponentMs = freezed,Object? question = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,myLocked: null == myLocked ? _self.myLocked : myLocked // ignore: cast_nullable_to_non_nullable
as bool,myChoice: freezed == myChoice ? _self.myChoice : myChoice // ignore: cast_nullable_to_non_nullable
as int?,myMs: freezed == myMs ? _self.myMs : myMs // ignore: cast_nullable_to_non_nullable
as int?,opponentLocked: null == opponentLocked ? _self.opponentLocked : opponentLocked // ignore: cast_nullable_to_non_nullable
as bool,opponentMs: freezed == opponentMs ? _self.opponentMs : opponentMs // ignore: cast_nullable_to_non_nullable
as int?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as DuelQuestion?,
  ));
}
/// Create a copy of LiveDuelRoundState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelQuestionCopyWith<$Res>? get question {
    if (_self.question == null) {
    return null;
  }

  return $DuelQuestionCopyWith<$Res>(_self.question!, (value) {
    return _then(_self.copyWith(question: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveDuelRoundState].
extension LiveDuelRoundStatePatterns on LiveDuelRoundState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveDuelRoundState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveDuelRoundState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveDuelRoundState value)  $default,){
final _that = this;
switch (_that) {
case _LiveDuelRoundState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveDuelRoundState value)?  $default,){
final _that = this;
switch (_that) {
case _LiveDuelRoundState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  DateTime? startsAt,  DateTime? deadline,  bool myLocked,  int? myChoice,  int? myMs,  bool opponentLocked,  int? opponentMs,  DuelQuestion? question)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveDuelRoundState() when $default != null:
return $default(_that.number,_that.startsAt,_that.deadline,_that.myLocked,_that.myChoice,_that.myMs,_that.opponentLocked,_that.opponentMs,_that.question);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  DateTime? startsAt,  DateTime? deadline,  bool myLocked,  int? myChoice,  int? myMs,  bool opponentLocked,  int? opponentMs,  DuelQuestion? question)  $default,) {final _that = this;
switch (_that) {
case _LiveDuelRoundState():
return $default(_that.number,_that.startsAt,_that.deadline,_that.myLocked,_that.myChoice,_that.myMs,_that.opponentLocked,_that.opponentMs,_that.question);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  DateTime? startsAt,  DateTime? deadline,  bool myLocked,  int? myChoice,  int? myMs,  bool opponentLocked,  int? opponentMs,  DuelQuestion? question)?  $default,) {final _that = this;
switch (_that) {
case _LiveDuelRoundState() when $default != null:
return $default(_that.number,_that.startsAt,_that.deadline,_that.myLocked,_that.myChoice,_that.myMs,_that.opponentLocked,_that.opponentMs,_that.question);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveDuelRoundState implements LiveDuelRoundState {
  const _LiveDuelRoundState({required this.number, this.startsAt, this.deadline, this.myLocked = false, this.myChoice, this.myMs, this.opponentLocked = false, this.opponentMs, this.question});
  factory _LiveDuelRoundState.fromJson(Map<String, dynamic> json) => _$LiveDuelRoundStateFromJson(json);

@override final  int number;
@override final  DateTime? startsAt;
@override final  DateTime? deadline;
@override@JsonKey() final  bool myLocked;
@override final  int? myChoice;
@override final  int? myMs;
@override@JsonKey() final  bool opponentLocked;
@override final  int? opponentMs;
@override final  DuelQuestion? question;

/// Create a copy of LiveDuelRoundState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveDuelRoundStateCopyWith<_LiveDuelRoundState> get copyWith => __$LiveDuelRoundStateCopyWithImpl<_LiveDuelRoundState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveDuelRoundStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveDuelRoundState&&(identical(other.number, number) || other.number == number)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.myLocked, myLocked) || other.myLocked == myLocked)&&(identical(other.myChoice, myChoice) || other.myChoice == myChoice)&&(identical(other.myMs, myMs) || other.myMs == myMs)&&(identical(other.opponentLocked, opponentLocked) || other.opponentLocked == opponentLocked)&&(identical(other.opponentMs, opponentMs) || other.opponentMs == opponentMs)&&(identical(other.question, question) || other.question == question));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,startsAt,deadline,myLocked,myChoice,myMs,opponentLocked,opponentMs,question);

@override
String toString() {
  return 'LiveDuelRoundState(number: $number, startsAt: $startsAt, deadline: $deadline, myLocked: $myLocked, myChoice: $myChoice, myMs: $myMs, opponentLocked: $opponentLocked, opponentMs: $opponentMs, question: $question)';
}


}

/// @nodoc
abstract mixin class _$LiveDuelRoundStateCopyWith<$Res> implements $LiveDuelRoundStateCopyWith<$Res> {
  factory _$LiveDuelRoundStateCopyWith(_LiveDuelRoundState value, $Res Function(_LiveDuelRoundState) _then) = __$LiveDuelRoundStateCopyWithImpl;
@override @useResult
$Res call({
 int number, DateTime? startsAt, DateTime? deadline, bool myLocked, int? myChoice, int? myMs, bool opponentLocked, int? opponentMs, DuelQuestion? question
});


@override $DuelQuestionCopyWith<$Res>? get question;

}
/// @nodoc
class __$LiveDuelRoundStateCopyWithImpl<$Res>
    implements _$LiveDuelRoundStateCopyWith<$Res> {
  __$LiveDuelRoundStateCopyWithImpl(this._self, this._then);

  final _LiveDuelRoundState _self;
  final $Res Function(_LiveDuelRoundState) _then;

/// Create a copy of LiveDuelRoundState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? startsAt = freezed,Object? deadline = freezed,Object? myLocked = null,Object? myChoice = freezed,Object? myMs = freezed,Object? opponentLocked = null,Object? opponentMs = freezed,Object? question = freezed,}) {
  return _then(_LiveDuelRoundState(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,myLocked: null == myLocked ? _self.myLocked : myLocked // ignore: cast_nullable_to_non_nullable
as bool,myChoice: freezed == myChoice ? _self.myChoice : myChoice // ignore: cast_nullable_to_non_nullable
as int?,myMs: freezed == myMs ? _self.myMs : myMs // ignore: cast_nullable_to_non_nullable
as int?,opponentLocked: null == opponentLocked ? _self.opponentLocked : opponentLocked // ignore: cast_nullable_to_non_nullable
as bool,opponentMs: freezed == opponentMs ? _self.opponentMs : opponentMs // ignore: cast_nullable_to_non_nullable
as int?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as DuelQuestion?,
  ));
}

/// Create a copy of LiveDuelRoundState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelQuestionCopyWith<$Res>? get question {
    if (_self.question == null) {
    return null;
  }

  return $DuelQuestionCopyWith<$Res>(_self.question!, (value) {
    return _then(_self.copyWith(question: value));
  });
}
}

// dart format on
