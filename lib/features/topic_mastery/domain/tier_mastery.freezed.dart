// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tier_mastery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TierMastery {

 DifficultyBand get band; int get starsEarned; int get starsAvailable; int get secondsPerQuestion;
/// Create a copy of TierMastery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TierMasteryCopyWith<TierMastery> get copyWith => _$TierMasteryCopyWithImpl<TierMastery>(this as TierMastery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierMastery&&(identical(other.band, band) || other.band == band)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.starsAvailable, starsAvailable) || other.starsAvailable == starsAvailable)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion));
}


@override
int get hashCode => Object.hash(runtimeType,band,starsEarned,starsAvailable,secondsPerQuestion);

@override
String toString() {
  return 'TierMastery(band: $band, starsEarned: $starsEarned, starsAvailable: $starsAvailable, secondsPerQuestion: $secondsPerQuestion)';
}


}

/// @nodoc
abstract mixin class $TierMasteryCopyWith<$Res>  {
  factory $TierMasteryCopyWith(TierMastery value, $Res Function(TierMastery) _then) = _$TierMasteryCopyWithImpl;
@useResult
$Res call({
 DifficultyBand band, int starsEarned, int starsAvailable, int secondsPerQuestion
});




}
/// @nodoc
class _$TierMasteryCopyWithImpl<$Res>
    implements $TierMasteryCopyWith<$Res> {
  _$TierMasteryCopyWithImpl(this._self, this._then);

  final TierMastery _self;
  final $Res Function(TierMastery) _then;

/// Create a copy of TierMastery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? band = null,Object? starsEarned = null,Object? starsAvailable = null,Object? secondsPerQuestion = null,}) {
  return _then(_self.copyWith(
band: null == band ? _self.band : band // ignore: cast_nullable_to_non_nullable
as DifficultyBand,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,starsAvailable: null == starsAvailable ? _self.starsAvailable : starsAvailable // ignore: cast_nullable_to_non_nullable
as int,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TierMastery].
extension TierMasteryPatterns on TierMastery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TierMastery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TierMastery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TierMastery value)  $default,){
final _that = this;
switch (_that) {
case _TierMastery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TierMastery value)?  $default,){
final _that = this;
switch (_that) {
case _TierMastery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DifficultyBand band,  int starsEarned,  int starsAvailable,  int secondsPerQuestion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TierMastery() when $default != null:
return $default(_that.band,_that.starsEarned,_that.starsAvailable,_that.secondsPerQuestion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DifficultyBand band,  int starsEarned,  int starsAvailable,  int secondsPerQuestion)  $default,) {final _that = this;
switch (_that) {
case _TierMastery():
return $default(_that.band,_that.starsEarned,_that.starsAvailable,_that.secondsPerQuestion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DifficultyBand band,  int starsEarned,  int starsAvailable,  int secondsPerQuestion)?  $default,) {final _that = this;
switch (_that) {
case _TierMastery() when $default != null:
return $default(_that.band,_that.starsEarned,_that.starsAvailable,_that.secondsPerQuestion);case _:
  return null;

}
}

}

/// @nodoc


class _TierMastery implements TierMastery {
  const _TierMastery({required this.band, required this.starsEarned, required this.starsAvailable, required this.secondsPerQuestion});
  

@override final  DifficultyBand band;
@override final  int starsEarned;
@override final  int starsAvailable;
@override final  int secondsPerQuestion;

/// Create a copy of TierMastery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TierMasteryCopyWith<_TierMastery> get copyWith => __$TierMasteryCopyWithImpl<_TierMastery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TierMastery&&(identical(other.band, band) || other.band == band)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.starsAvailable, starsAvailable) || other.starsAvailable == starsAvailable)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion));
}


@override
int get hashCode => Object.hash(runtimeType,band,starsEarned,starsAvailable,secondsPerQuestion);

@override
String toString() {
  return 'TierMastery(band: $band, starsEarned: $starsEarned, starsAvailable: $starsAvailable, secondsPerQuestion: $secondsPerQuestion)';
}


}

/// @nodoc
abstract mixin class _$TierMasteryCopyWith<$Res> implements $TierMasteryCopyWith<$Res> {
  factory _$TierMasteryCopyWith(_TierMastery value, $Res Function(_TierMastery) _then) = __$TierMasteryCopyWithImpl;
@override @useResult
$Res call({
 DifficultyBand band, int starsEarned, int starsAvailable, int secondsPerQuestion
});




}
/// @nodoc
class __$TierMasteryCopyWithImpl<$Res>
    implements _$TierMasteryCopyWith<$Res> {
  __$TierMasteryCopyWithImpl(this._self, this._then);

  final _TierMastery _self;
  final $Res Function(_TierMastery) _then;

/// Create a copy of TierMastery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? band = null,Object? starsEarned = null,Object? starsAvailable = null,Object? secondsPerQuestion = null,}) {
  return _then(_TierMastery(
band: null == band ? _self.band : band // ignore: cast_nullable_to_non_nullable
as DifficultyBand,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,starsAvailable: null == starsAvailable ? _self.starsAvailable : starsAvailable // ignore: cast_nullable_to_non_nullable
as int,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
