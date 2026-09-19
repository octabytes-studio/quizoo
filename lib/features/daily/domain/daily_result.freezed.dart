// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyResult {

 int get correctCount; int get totalCount; int get betterThanPercent;/// Five bucket heights, 0…100 — 0-2 / 3-4 / 5-6 / 7-8 / 9-10 correct.
 List<int> get distributionPercents; int get highlightedBucketIndex; int get coinsEarned; int get streakNow;/// One entry per question, true for a correct answer — the raw material
/// for the share sheet's spoiler-free emoji grid.
 List<bool> get answerPattern; List<String> get newlyEarnedBadgeIds;
/// Create a copy of DailyResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyResultCopyWith<DailyResult> get copyWith => _$DailyResultCopyWithImpl<DailyResult>(this as DailyResult, _$identity);

  /// Serializes this DailyResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyResult&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.betterThanPercent, betterThanPercent) || other.betterThanPercent == betterThanPercent)&&const DeepCollectionEquality().equals(other.distributionPercents, distributionPercents)&&(identical(other.highlightedBucketIndex, highlightedBucketIndex) || other.highlightedBucketIndex == highlightedBucketIndex)&&(identical(other.coinsEarned, coinsEarned) || other.coinsEarned == coinsEarned)&&(identical(other.streakNow, streakNow) || other.streakNow == streakNow)&&const DeepCollectionEquality().equals(other.answerPattern, answerPattern)&&const DeepCollectionEquality().equals(other.newlyEarnedBadgeIds, newlyEarnedBadgeIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,correctCount,totalCount,betterThanPercent,const DeepCollectionEquality().hash(distributionPercents),highlightedBucketIndex,coinsEarned,streakNow,const DeepCollectionEquality().hash(answerPattern),const DeepCollectionEquality().hash(newlyEarnedBadgeIds));

@override
String toString() {
  return 'DailyResult(correctCount: $correctCount, totalCount: $totalCount, betterThanPercent: $betterThanPercent, distributionPercents: $distributionPercents, highlightedBucketIndex: $highlightedBucketIndex, coinsEarned: $coinsEarned, streakNow: $streakNow, answerPattern: $answerPattern, newlyEarnedBadgeIds: $newlyEarnedBadgeIds)';
}


}

/// @nodoc
abstract mixin class $DailyResultCopyWith<$Res>  {
  factory $DailyResultCopyWith(DailyResult value, $Res Function(DailyResult) _then) = _$DailyResultCopyWithImpl;
@useResult
$Res call({
 int correctCount, int totalCount, int betterThanPercent, List<int> distributionPercents, int highlightedBucketIndex, int coinsEarned, int streakNow, List<bool> answerPattern, List<String> newlyEarnedBadgeIds
});




}
/// @nodoc
class _$DailyResultCopyWithImpl<$Res>
    implements $DailyResultCopyWith<$Res> {
  _$DailyResultCopyWithImpl(this._self, this._then);

  final DailyResult _self;
  final $Res Function(DailyResult) _then;

/// Create a copy of DailyResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? correctCount = null,Object? totalCount = null,Object? betterThanPercent = null,Object? distributionPercents = null,Object? highlightedBucketIndex = null,Object? coinsEarned = null,Object? streakNow = null,Object? answerPattern = null,Object? newlyEarnedBadgeIds = null,}) {
  return _then(_self.copyWith(
correctCount: null == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,betterThanPercent: null == betterThanPercent ? _self.betterThanPercent : betterThanPercent // ignore: cast_nullable_to_non_nullable
as int,distributionPercents: null == distributionPercents ? _self.distributionPercents : distributionPercents // ignore: cast_nullable_to_non_nullable
as List<int>,highlightedBucketIndex: null == highlightedBucketIndex ? _self.highlightedBucketIndex : highlightedBucketIndex // ignore: cast_nullable_to_non_nullable
as int,coinsEarned: null == coinsEarned ? _self.coinsEarned : coinsEarned // ignore: cast_nullable_to_non_nullable
as int,streakNow: null == streakNow ? _self.streakNow : streakNow // ignore: cast_nullable_to_non_nullable
as int,answerPattern: null == answerPattern ? _self.answerPattern : answerPattern // ignore: cast_nullable_to_non_nullable
as List<bool>,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self.newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyResult].
extension DailyResultPatterns on DailyResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyResult value)  $default,){
final _that = this;
switch (_that) {
case _DailyResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyResult value)?  $default,){
final _that = this;
switch (_that) {
case _DailyResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int correctCount,  int totalCount,  int betterThanPercent,  List<int> distributionPercents,  int highlightedBucketIndex,  int coinsEarned,  int streakNow,  List<bool> answerPattern,  List<String> newlyEarnedBadgeIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyResult() when $default != null:
return $default(_that.correctCount,_that.totalCount,_that.betterThanPercent,_that.distributionPercents,_that.highlightedBucketIndex,_that.coinsEarned,_that.streakNow,_that.answerPattern,_that.newlyEarnedBadgeIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int correctCount,  int totalCount,  int betterThanPercent,  List<int> distributionPercents,  int highlightedBucketIndex,  int coinsEarned,  int streakNow,  List<bool> answerPattern,  List<String> newlyEarnedBadgeIds)  $default,) {final _that = this;
switch (_that) {
case _DailyResult():
return $default(_that.correctCount,_that.totalCount,_that.betterThanPercent,_that.distributionPercents,_that.highlightedBucketIndex,_that.coinsEarned,_that.streakNow,_that.answerPattern,_that.newlyEarnedBadgeIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int correctCount,  int totalCount,  int betterThanPercent,  List<int> distributionPercents,  int highlightedBucketIndex,  int coinsEarned,  int streakNow,  List<bool> answerPattern,  List<String> newlyEarnedBadgeIds)?  $default,) {final _that = this;
switch (_that) {
case _DailyResult() when $default != null:
return $default(_that.correctCount,_that.totalCount,_that.betterThanPercent,_that.distributionPercents,_that.highlightedBucketIndex,_that.coinsEarned,_that.streakNow,_that.answerPattern,_that.newlyEarnedBadgeIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyResult extends DailyResult {
  const _DailyResult({required this.correctCount, required this.totalCount, required this.betterThanPercent, required final  List<int> distributionPercents, required this.highlightedBucketIndex, required this.coinsEarned, required this.streakNow, required final  List<bool> answerPattern, final  List<String> newlyEarnedBadgeIds = const []}): _distributionPercents = distributionPercents,_answerPattern = answerPattern,_newlyEarnedBadgeIds = newlyEarnedBadgeIds,super._();
  factory _DailyResult.fromJson(Map<String, dynamic> json) => _$DailyResultFromJson(json);

@override final  int correctCount;
@override final  int totalCount;
@override final  int betterThanPercent;
/// Five bucket heights, 0…100 — 0-2 / 3-4 / 5-6 / 7-8 / 9-10 correct.
 final  List<int> _distributionPercents;
/// Five bucket heights, 0…100 — 0-2 / 3-4 / 5-6 / 7-8 / 9-10 correct.
@override List<int> get distributionPercents {
  if (_distributionPercents is EqualUnmodifiableListView) return _distributionPercents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_distributionPercents);
}

@override final  int highlightedBucketIndex;
@override final  int coinsEarned;
@override final  int streakNow;
/// One entry per question, true for a correct answer — the raw material
/// for the share sheet's spoiler-free emoji grid.
 final  List<bool> _answerPattern;
/// One entry per question, true for a correct answer — the raw material
/// for the share sheet's spoiler-free emoji grid.
@override List<bool> get answerPattern {
  if (_answerPattern is EqualUnmodifiableListView) return _answerPattern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answerPattern);
}

 final  List<String> _newlyEarnedBadgeIds;
@override@JsonKey() List<String> get newlyEarnedBadgeIds {
  if (_newlyEarnedBadgeIds is EqualUnmodifiableListView) return _newlyEarnedBadgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newlyEarnedBadgeIds);
}


/// Create a copy of DailyResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyResultCopyWith<_DailyResult> get copyWith => __$DailyResultCopyWithImpl<_DailyResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyResult&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.betterThanPercent, betterThanPercent) || other.betterThanPercent == betterThanPercent)&&const DeepCollectionEquality().equals(other._distributionPercents, _distributionPercents)&&(identical(other.highlightedBucketIndex, highlightedBucketIndex) || other.highlightedBucketIndex == highlightedBucketIndex)&&(identical(other.coinsEarned, coinsEarned) || other.coinsEarned == coinsEarned)&&(identical(other.streakNow, streakNow) || other.streakNow == streakNow)&&const DeepCollectionEquality().equals(other._answerPattern, _answerPattern)&&const DeepCollectionEquality().equals(other._newlyEarnedBadgeIds, _newlyEarnedBadgeIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,correctCount,totalCount,betterThanPercent,const DeepCollectionEquality().hash(_distributionPercents),highlightedBucketIndex,coinsEarned,streakNow,const DeepCollectionEquality().hash(_answerPattern),const DeepCollectionEquality().hash(_newlyEarnedBadgeIds));

@override
String toString() {
  return 'DailyResult(correctCount: $correctCount, totalCount: $totalCount, betterThanPercent: $betterThanPercent, distributionPercents: $distributionPercents, highlightedBucketIndex: $highlightedBucketIndex, coinsEarned: $coinsEarned, streakNow: $streakNow, answerPattern: $answerPattern, newlyEarnedBadgeIds: $newlyEarnedBadgeIds)';
}


}

/// @nodoc
abstract mixin class _$DailyResultCopyWith<$Res> implements $DailyResultCopyWith<$Res> {
  factory _$DailyResultCopyWith(_DailyResult value, $Res Function(_DailyResult) _then) = __$DailyResultCopyWithImpl;
@override @useResult
$Res call({
 int correctCount, int totalCount, int betterThanPercent, List<int> distributionPercents, int highlightedBucketIndex, int coinsEarned, int streakNow, List<bool> answerPattern, List<String> newlyEarnedBadgeIds
});




}
/// @nodoc
class __$DailyResultCopyWithImpl<$Res>
    implements _$DailyResultCopyWith<$Res> {
  __$DailyResultCopyWithImpl(this._self, this._then);

  final _DailyResult _self;
  final $Res Function(_DailyResult) _then;

/// Create a copy of DailyResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? correctCount = null,Object? totalCount = null,Object? betterThanPercent = null,Object? distributionPercents = null,Object? highlightedBucketIndex = null,Object? coinsEarned = null,Object? streakNow = null,Object? answerPattern = null,Object? newlyEarnedBadgeIds = null,}) {
  return _then(_DailyResult(
correctCount: null == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,betterThanPercent: null == betterThanPercent ? _self.betterThanPercent : betterThanPercent // ignore: cast_nullable_to_non_nullable
as int,distributionPercents: null == distributionPercents ? _self._distributionPercents : distributionPercents // ignore: cast_nullable_to_non_nullable
as List<int>,highlightedBucketIndex: null == highlightedBucketIndex ? _self.highlightedBucketIndex : highlightedBucketIndex // ignore: cast_nullable_to_non_nullable
as int,coinsEarned: null == coinsEarned ? _self.coinsEarned : coinsEarned // ignore: cast_nullable_to_non_nullable
as int,streakNow: null == streakNow ? _self.streakNow : streakNow // ignore: cast_nullable_to_non_nullable
as int,answerPattern: null == answerPattern ? _self._answerPattern : answerPattern // ignore: cast_nullable_to_non_nullable
as List<bool>,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self._newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
