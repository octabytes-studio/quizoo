// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Level {

 String get id; String get subcategoryId;/// 1-based position on the level map.
 int get number; DifficultyBand get difficultyBand;/// The per-question clock, which tightens with the band.
 int get secondsPerQuestion; LevelStatus get status;/// Every tenth level, which wears a crown on the map.
 bool get isBoss; int get questionCount;/// 0…3.
 int get starsEarned; int get bestScore;
/// Create a copy of Level
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelCopyWith<Level> get copyWith => _$LevelCopyWithImpl<Level>(this as Level, _$identity);

  /// Serializes this Level to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Level&&(identical(other.id, id) || other.id == id)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.number, number) || other.number == number)&&(identical(other.difficultyBand, difficultyBand) || other.difficultyBand == difficultyBand)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion)&&(identical(other.status, status) || other.status == status)&&(identical(other.isBoss, isBoss) || other.isBoss == isBoss)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.bestScore, bestScore) || other.bestScore == bestScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subcategoryId,number,difficultyBand,secondsPerQuestion,status,isBoss,questionCount,starsEarned,bestScore);

@override
String toString() {
  return 'Level(id: $id, subcategoryId: $subcategoryId, number: $number, difficultyBand: $difficultyBand, secondsPerQuestion: $secondsPerQuestion, status: $status, isBoss: $isBoss, questionCount: $questionCount, starsEarned: $starsEarned, bestScore: $bestScore)';
}


}

/// @nodoc
abstract mixin class $LevelCopyWith<$Res>  {
  factory $LevelCopyWith(Level value, $Res Function(Level) _then) = _$LevelCopyWithImpl;
@useResult
$Res call({
 String id, String subcategoryId, int number, DifficultyBand difficultyBand, int secondsPerQuestion, LevelStatus status, bool isBoss, int questionCount, int starsEarned, int bestScore
});




}
/// @nodoc
class _$LevelCopyWithImpl<$Res>
    implements $LevelCopyWith<$Res> {
  _$LevelCopyWithImpl(this._self, this._then);

  final Level _self;
  final $Res Function(Level) _then;

/// Create a copy of Level
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subcategoryId = null,Object? number = null,Object? difficultyBand = null,Object? secondsPerQuestion = null,Object? status = null,Object? isBoss = null,Object? questionCount = null,Object? starsEarned = null,Object? bestScore = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,difficultyBand: null == difficultyBand ? _self.difficultyBand : difficultyBand // ignore: cast_nullable_to_non_nullable
as DifficultyBand,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LevelStatus,isBoss: null == isBoss ? _self.isBoss : isBoss // ignore: cast_nullable_to_non_nullable
as bool,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,bestScore: null == bestScore ? _self.bestScore : bestScore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Level].
extension LevelPatterns on Level {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Level value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Level() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Level value)  $default,){
final _that = this;
switch (_that) {
case _Level():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Level value)?  $default,){
final _that = this;
switch (_that) {
case _Level() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subcategoryId,  int number,  DifficultyBand difficultyBand,  int secondsPerQuestion,  LevelStatus status,  bool isBoss,  int questionCount,  int starsEarned,  int bestScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Level() when $default != null:
return $default(_that.id,_that.subcategoryId,_that.number,_that.difficultyBand,_that.secondsPerQuestion,_that.status,_that.isBoss,_that.questionCount,_that.starsEarned,_that.bestScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subcategoryId,  int number,  DifficultyBand difficultyBand,  int secondsPerQuestion,  LevelStatus status,  bool isBoss,  int questionCount,  int starsEarned,  int bestScore)  $default,) {final _that = this;
switch (_that) {
case _Level():
return $default(_that.id,_that.subcategoryId,_that.number,_that.difficultyBand,_that.secondsPerQuestion,_that.status,_that.isBoss,_that.questionCount,_that.starsEarned,_that.bestScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subcategoryId,  int number,  DifficultyBand difficultyBand,  int secondsPerQuestion,  LevelStatus status,  bool isBoss,  int questionCount,  int starsEarned,  int bestScore)?  $default,) {final _that = this;
switch (_that) {
case _Level() when $default != null:
return $default(_that.id,_that.subcategoryId,_that.number,_that.difficultyBand,_that.secondsPerQuestion,_that.status,_that.isBoss,_that.questionCount,_that.starsEarned,_that.bestScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Level implements Level {
  const _Level({required this.id, required this.subcategoryId, required this.number, required this.difficultyBand, required this.secondsPerQuestion, required this.status, this.isBoss = false, this.questionCount = 10, this.starsEarned = 0, this.bestScore = 0});
  factory _Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);

@override final  String id;
@override final  String subcategoryId;
/// 1-based position on the level map.
@override final  int number;
@override final  DifficultyBand difficultyBand;
/// The per-question clock, which tightens with the band.
@override final  int secondsPerQuestion;
@override final  LevelStatus status;
/// Every tenth level, which wears a crown on the map.
@override@JsonKey() final  bool isBoss;
@override@JsonKey() final  int questionCount;
/// 0…3.
@override@JsonKey() final  int starsEarned;
@override@JsonKey() final  int bestScore;

/// Create a copy of Level
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelCopyWith<_Level> get copyWith => __$LevelCopyWithImpl<_Level>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Level&&(identical(other.id, id) || other.id == id)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.number, number) || other.number == number)&&(identical(other.difficultyBand, difficultyBand) || other.difficultyBand == difficultyBand)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion)&&(identical(other.status, status) || other.status == status)&&(identical(other.isBoss, isBoss) || other.isBoss == isBoss)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.bestScore, bestScore) || other.bestScore == bestScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subcategoryId,number,difficultyBand,secondsPerQuestion,status,isBoss,questionCount,starsEarned,bestScore);

@override
String toString() {
  return 'Level(id: $id, subcategoryId: $subcategoryId, number: $number, difficultyBand: $difficultyBand, secondsPerQuestion: $secondsPerQuestion, status: $status, isBoss: $isBoss, questionCount: $questionCount, starsEarned: $starsEarned, bestScore: $bestScore)';
}


}

/// @nodoc
abstract mixin class _$LevelCopyWith<$Res> implements $LevelCopyWith<$Res> {
  factory _$LevelCopyWith(_Level value, $Res Function(_Level) _then) = __$LevelCopyWithImpl;
@override @useResult
$Res call({
 String id, String subcategoryId, int number, DifficultyBand difficultyBand, int secondsPerQuestion, LevelStatus status, bool isBoss, int questionCount, int starsEarned, int bestScore
});




}
/// @nodoc
class __$LevelCopyWithImpl<$Res>
    implements _$LevelCopyWith<$Res> {
  __$LevelCopyWithImpl(this._self, this._then);

  final _Level _self;
  final $Res Function(_Level) _then;

/// Create a copy of Level
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subcategoryId = null,Object? number = null,Object? difficultyBand = null,Object? secondsPerQuestion = null,Object? status = null,Object? isBoss = null,Object? questionCount = null,Object? starsEarned = null,Object? bestScore = null,}) {
  return _then(_Level(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,difficultyBand: null == difficultyBand ? _self.difficultyBand : difficultyBand // ignore: cast_nullable_to_non_nullable
as DifficultyBand,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LevelStatus,isBoss: null == isBoss ? _self.isBoss : isBoss // ignore: cast_nullable_to_non_nullable
as bool,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,bestScore: null == bestScore ? _self.bestScore : bestScore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
