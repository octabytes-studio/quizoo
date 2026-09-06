// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyChallenge {

 String get title; int get questionCount; int get categoryCount; int get secondsPerQuestion; int get coinReward; int get xpReward;/// Minutes until today's window closes — stored as an int so the model
/// stays JSON-round-trippable without a custom `Duration` converter.
 int get timeRemainingMinutes; int get playedTodayCount; int get averageCorrect; int get averageOutOf;
/// Create a copy of DailyChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyChallengeCopyWith<DailyChallenge> get copyWith => _$DailyChallengeCopyWithImpl<DailyChallenge>(this as DailyChallenge, _$identity);

  /// Serializes this DailyChallenge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyChallenge&&(identical(other.title, title) || other.title == title)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.categoryCount, categoryCount) || other.categoryCount == categoryCount)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion)&&(identical(other.coinReward, coinReward) || other.coinReward == coinReward)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.timeRemainingMinutes, timeRemainingMinutes) || other.timeRemainingMinutes == timeRemainingMinutes)&&(identical(other.playedTodayCount, playedTodayCount) || other.playedTodayCount == playedTodayCount)&&(identical(other.averageCorrect, averageCorrect) || other.averageCorrect == averageCorrect)&&(identical(other.averageOutOf, averageOutOf) || other.averageOutOf == averageOutOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,questionCount,categoryCount,secondsPerQuestion,coinReward,xpReward,timeRemainingMinutes,playedTodayCount,averageCorrect,averageOutOf);

@override
String toString() {
  return 'DailyChallenge(title: $title, questionCount: $questionCount, categoryCount: $categoryCount, secondsPerQuestion: $secondsPerQuestion, coinReward: $coinReward, xpReward: $xpReward, timeRemainingMinutes: $timeRemainingMinutes, playedTodayCount: $playedTodayCount, averageCorrect: $averageCorrect, averageOutOf: $averageOutOf)';
}


}

/// @nodoc
abstract mixin class $DailyChallengeCopyWith<$Res>  {
  factory $DailyChallengeCopyWith(DailyChallenge value, $Res Function(DailyChallenge) _then) = _$DailyChallengeCopyWithImpl;
@useResult
$Res call({
 String title, int questionCount, int categoryCount, int secondsPerQuestion, int coinReward, int xpReward, int timeRemainingMinutes, int playedTodayCount, int averageCorrect, int averageOutOf
});




}
/// @nodoc
class _$DailyChallengeCopyWithImpl<$Res>
    implements $DailyChallengeCopyWith<$Res> {
  _$DailyChallengeCopyWithImpl(this._self, this._then);

  final DailyChallenge _self;
  final $Res Function(DailyChallenge) _then;

/// Create a copy of DailyChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? questionCount = null,Object? categoryCount = null,Object? secondsPerQuestion = null,Object? coinReward = null,Object? xpReward = null,Object? timeRemainingMinutes = null,Object? playedTodayCount = null,Object? averageCorrect = null,Object? averageOutOf = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,categoryCount: null == categoryCount ? _self.categoryCount : categoryCount // ignore: cast_nullable_to_non_nullable
as int,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,coinReward: null == coinReward ? _self.coinReward : coinReward // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,timeRemainingMinutes: null == timeRemainingMinutes ? _self.timeRemainingMinutes : timeRemainingMinutes // ignore: cast_nullable_to_non_nullable
as int,playedTodayCount: null == playedTodayCount ? _self.playedTodayCount : playedTodayCount // ignore: cast_nullable_to_non_nullable
as int,averageCorrect: null == averageCorrect ? _self.averageCorrect : averageCorrect // ignore: cast_nullable_to_non_nullable
as int,averageOutOf: null == averageOutOf ? _self.averageOutOf : averageOutOf // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyChallenge].
extension DailyChallengePatterns on DailyChallenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyChallenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyChallenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyChallenge value)  $default,){
final _that = this;
switch (_that) {
case _DailyChallenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyChallenge value)?  $default,){
final _that = this;
switch (_that) {
case _DailyChallenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int questionCount,  int categoryCount,  int secondsPerQuestion,  int coinReward,  int xpReward,  int timeRemainingMinutes,  int playedTodayCount,  int averageCorrect,  int averageOutOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyChallenge() when $default != null:
return $default(_that.title,_that.questionCount,_that.categoryCount,_that.secondsPerQuestion,_that.coinReward,_that.xpReward,_that.timeRemainingMinutes,_that.playedTodayCount,_that.averageCorrect,_that.averageOutOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int questionCount,  int categoryCount,  int secondsPerQuestion,  int coinReward,  int xpReward,  int timeRemainingMinutes,  int playedTodayCount,  int averageCorrect,  int averageOutOf)  $default,) {final _that = this;
switch (_that) {
case _DailyChallenge():
return $default(_that.title,_that.questionCount,_that.categoryCount,_that.secondsPerQuestion,_that.coinReward,_that.xpReward,_that.timeRemainingMinutes,_that.playedTodayCount,_that.averageCorrect,_that.averageOutOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int questionCount,  int categoryCount,  int secondsPerQuestion,  int coinReward,  int xpReward,  int timeRemainingMinutes,  int playedTodayCount,  int averageCorrect,  int averageOutOf)?  $default,) {final _that = this;
switch (_that) {
case _DailyChallenge() when $default != null:
return $default(_that.title,_that.questionCount,_that.categoryCount,_that.secondsPerQuestion,_that.coinReward,_that.xpReward,_that.timeRemainingMinutes,_that.playedTodayCount,_that.averageCorrect,_that.averageOutOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyChallenge extends DailyChallenge {
  const _DailyChallenge({required this.title, required this.questionCount, required this.categoryCount, required this.secondsPerQuestion, required this.coinReward, required this.xpReward, required this.timeRemainingMinutes, required this.playedTodayCount, required this.averageCorrect, required this.averageOutOf}): super._();
  factory _DailyChallenge.fromJson(Map<String, dynamic> json) => _$DailyChallengeFromJson(json);

@override final  String title;
@override final  int questionCount;
@override final  int categoryCount;
@override final  int secondsPerQuestion;
@override final  int coinReward;
@override final  int xpReward;
/// Minutes until today's window closes — stored as an int so the model
/// stays JSON-round-trippable without a custom `Duration` converter.
@override final  int timeRemainingMinutes;
@override final  int playedTodayCount;
@override final  int averageCorrect;
@override final  int averageOutOf;

/// Create a copy of DailyChallenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyChallengeCopyWith<_DailyChallenge> get copyWith => __$DailyChallengeCopyWithImpl<_DailyChallenge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyChallengeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyChallenge&&(identical(other.title, title) || other.title == title)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.categoryCount, categoryCount) || other.categoryCount == categoryCount)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion)&&(identical(other.coinReward, coinReward) || other.coinReward == coinReward)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.timeRemainingMinutes, timeRemainingMinutes) || other.timeRemainingMinutes == timeRemainingMinutes)&&(identical(other.playedTodayCount, playedTodayCount) || other.playedTodayCount == playedTodayCount)&&(identical(other.averageCorrect, averageCorrect) || other.averageCorrect == averageCorrect)&&(identical(other.averageOutOf, averageOutOf) || other.averageOutOf == averageOutOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,questionCount,categoryCount,secondsPerQuestion,coinReward,xpReward,timeRemainingMinutes,playedTodayCount,averageCorrect,averageOutOf);

@override
String toString() {
  return 'DailyChallenge(title: $title, questionCount: $questionCount, categoryCount: $categoryCount, secondsPerQuestion: $secondsPerQuestion, coinReward: $coinReward, xpReward: $xpReward, timeRemainingMinutes: $timeRemainingMinutes, playedTodayCount: $playedTodayCount, averageCorrect: $averageCorrect, averageOutOf: $averageOutOf)';
}


}

/// @nodoc
abstract mixin class _$DailyChallengeCopyWith<$Res> implements $DailyChallengeCopyWith<$Res> {
  factory _$DailyChallengeCopyWith(_DailyChallenge value, $Res Function(_DailyChallenge) _then) = __$DailyChallengeCopyWithImpl;
@override @useResult
$Res call({
 String title, int questionCount, int categoryCount, int secondsPerQuestion, int coinReward, int xpReward, int timeRemainingMinutes, int playedTodayCount, int averageCorrect, int averageOutOf
});




}
/// @nodoc
class __$DailyChallengeCopyWithImpl<$Res>
    implements _$DailyChallengeCopyWith<$Res> {
  __$DailyChallengeCopyWithImpl(this._self, this._then);

  final _DailyChallenge _self;
  final $Res Function(_DailyChallenge) _then;

/// Create a copy of DailyChallenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? questionCount = null,Object? categoryCount = null,Object? secondsPerQuestion = null,Object? coinReward = null,Object? xpReward = null,Object? timeRemainingMinutes = null,Object? playedTodayCount = null,Object? averageCorrect = null,Object? averageOutOf = null,}) {
  return _then(_DailyChallenge(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,categoryCount: null == categoryCount ? _self.categoryCount : categoryCount // ignore: cast_nullable_to_non_nullable
as int,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,coinReward: null == coinReward ? _self.coinReward : coinReward // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,timeRemainingMinutes: null == timeRemainingMinutes ? _self.timeRemainingMinutes : timeRemainingMinutes // ignore: cast_nullable_to_non_nullable
as int,playedTodayCount: null == playedTodayCount ? _self.playedTodayCount : playedTodayCount // ignore: cast_nullable_to_non_nullable
as int,averageCorrect: null == averageCorrect ? _self.averageCorrect : averageCorrect // ignore: cast_nullable_to_non_nullable
as int,averageOutOf: null == averageOutOf ? _self.averageOutOf : averageOutOf // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
