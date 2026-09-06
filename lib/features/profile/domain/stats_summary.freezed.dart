// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatsSummary {

/// Seven bars, Monday..Sunday, 0…100 — today's is the highlighted one.
 List<int> get pointsPerDayPercents; int get todayIndex; List<CategoryAccuracy> get categoryAccuracies; double get fastestAverageSeconds; String get fastestSubcategoryName; int get fastestLevelNumber; String get fastestPercentileLabel;
/// Create a copy of StatsSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsSummaryCopyWith<StatsSummary> get copyWith => _$StatsSummaryCopyWithImpl<StatsSummary>(this as StatsSummary, _$identity);

  /// Serializes this StatsSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsSummary&&const DeepCollectionEquality().equals(other.pointsPerDayPercents, pointsPerDayPercents)&&(identical(other.todayIndex, todayIndex) || other.todayIndex == todayIndex)&&const DeepCollectionEquality().equals(other.categoryAccuracies, categoryAccuracies)&&(identical(other.fastestAverageSeconds, fastestAverageSeconds) || other.fastestAverageSeconds == fastestAverageSeconds)&&(identical(other.fastestSubcategoryName, fastestSubcategoryName) || other.fastestSubcategoryName == fastestSubcategoryName)&&(identical(other.fastestLevelNumber, fastestLevelNumber) || other.fastestLevelNumber == fastestLevelNumber)&&(identical(other.fastestPercentileLabel, fastestPercentileLabel) || other.fastestPercentileLabel == fastestPercentileLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pointsPerDayPercents),todayIndex,const DeepCollectionEquality().hash(categoryAccuracies),fastestAverageSeconds,fastestSubcategoryName,fastestLevelNumber,fastestPercentileLabel);

@override
String toString() {
  return 'StatsSummary(pointsPerDayPercents: $pointsPerDayPercents, todayIndex: $todayIndex, categoryAccuracies: $categoryAccuracies, fastestAverageSeconds: $fastestAverageSeconds, fastestSubcategoryName: $fastestSubcategoryName, fastestLevelNumber: $fastestLevelNumber, fastestPercentileLabel: $fastestPercentileLabel)';
}


}

/// @nodoc
abstract mixin class $StatsSummaryCopyWith<$Res>  {
  factory $StatsSummaryCopyWith(StatsSummary value, $Res Function(StatsSummary) _then) = _$StatsSummaryCopyWithImpl;
@useResult
$Res call({
 List<int> pointsPerDayPercents, int todayIndex, List<CategoryAccuracy> categoryAccuracies, double fastestAverageSeconds, String fastestSubcategoryName, int fastestLevelNumber, String fastestPercentileLabel
});




}
/// @nodoc
class _$StatsSummaryCopyWithImpl<$Res>
    implements $StatsSummaryCopyWith<$Res> {
  _$StatsSummaryCopyWithImpl(this._self, this._then);

  final StatsSummary _self;
  final $Res Function(StatsSummary) _then;

/// Create a copy of StatsSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pointsPerDayPercents = null,Object? todayIndex = null,Object? categoryAccuracies = null,Object? fastestAverageSeconds = null,Object? fastestSubcategoryName = null,Object? fastestLevelNumber = null,Object? fastestPercentileLabel = null,}) {
  return _then(_self.copyWith(
pointsPerDayPercents: null == pointsPerDayPercents ? _self.pointsPerDayPercents : pointsPerDayPercents // ignore: cast_nullable_to_non_nullable
as List<int>,todayIndex: null == todayIndex ? _self.todayIndex : todayIndex // ignore: cast_nullable_to_non_nullable
as int,categoryAccuracies: null == categoryAccuracies ? _self.categoryAccuracies : categoryAccuracies // ignore: cast_nullable_to_non_nullable
as List<CategoryAccuracy>,fastestAverageSeconds: null == fastestAverageSeconds ? _self.fastestAverageSeconds : fastestAverageSeconds // ignore: cast_nullable_to_non_nullable
as double,fastestSubcategoryName: null == fastestSubcategoryName ? _self.fastestSubcategoryName : fastestSubcategoryName // ignore: cast_nullable_to_non_nullable
as String,fastestLevelNumber: null == fastestLevelNumber ? _self.fastestLevelNumber : fastestLevelNumber // ignore: cast_nullable_to_non_nullable
as int,fastestPercentileLabel: null == fastestPercentileLabel ? _self.fastestPercentileLabel : fastestPercentileLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsSummary].
extension StatsSummaryPatterns on StatsSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsSummary value)  $default,){
final _that = this;
switch (_that) {
case _StatsSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsSummary value)?  $default,){
final _that = this;
switch (_that) {
case _StatsSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> pointsPerDayPercents,  int todayIndex,  List<CategoryAccuracy> categoryAccuracies,  double fastestAverageSeconds,  String fastestSubcategoryName,  int fastestLevelNumber,  String fastestPercentileLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsSummary() when $default != null:
return $default(_that.pointsPerDayPercents,_that.todayIndex,_that.categoryAccuracies,_that.fastestAverageSeconds,_that.fastestSubcategoryName,_that.fastestLevelNumber,_that.fastestPercentileLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> pointsPerDayPercents,  int todayIndex,  List<CategoryAccuracy> categoryAccuracies,  double fastestAverageSeconds,  String fastestSubcategoryName,  int fastestLevelNumber,  String fastestPercentileLabel)  $default,) {final _that = this;
switch (_that) {
case _StatsSummary():
return $default(_that.pointsPerDayPercents,_that.todayIndex,_that.categoryAccuracies,_that.fastestAverageSeconds,_that.fastestSubcategoryName,_that.fastestLevelNumber,_that.fastestPercentileLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> pointsPerDayPercents,  int todayIndex,  List<CategoryAccuracy> categoryAccuracies,  double fastestAverageSeconds,  String fastestSubcategoryName,  int fastestLevelNumber,  String fastestPercentileLabel)?  $default,) {final _that = this;
switch (_that) {
case _StatsSummary() when $default != null:
return $default(_that.pointsPerDayPercents,_that.todayIndex,_that.categoryAccuracies,_that.fastestAverageSeconds,_that.fastestSubcategoryName,_that.fastestLevelNumber,_that.fastestPercentileLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsSummary extends StatsSummary {
  const _StatsSummary({required final  List<int> pointsPerDayPercents, required this.todayIndex, required final  List<CategoryAccuracy> categoryAccuracies, required this.fastestAverageSeconds, required this.fastestSubcategoryName, required this.fastestLevelNumber, required this.fastestPercentileLabel}): _pointsPerDayPercents = pointsPerDayPercents,_categoryAccuracies = categoryAccuracies,super._();
  factory _StatsSummary.fromJson(Map<String, dynamic> json) => _$StatsSummaryFromJson(json);

/// Seven bars, Monday..Sunday, 0…100 — today's is the highlighted one.
 final  List<int> _pointsPerDayPercents;
/// Seven bars, Monday..Sunday, 0…100 — today's is the highlighted one.
@override List<int> get pointsPerDayPercents {
  if (_pointsPerDayPercents is EqualUnmodifiableListView) return _pointsPerDayPercents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pointsPerDayPercents);
}

@override final  int todayIndex;
 final  List<CategoryAccuracy> _categoryAccuracies;
@override List<CategoryAccuracy> get categoryAccuracies {
  if (_categoryAccuracies is EqualUnmodifiableListView) return _categoryAccuracies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryAccuracies);
}

@override final  double fastestAverageSeconds;
@override final  String fastestSubcategoryName;
@override final  int fastestLevelNumber;
@override final  String fastestPercentileLabel;

/// Create a copy of StatsSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsSummaryCopyWith<_StatsSummary> get copyWith => __$StatsSummaryCopyWithImpl<_StatsSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsSummary&&const DeepCollectionEquality().equals(other._pointsPerDayPercents, _pointsPerDayPercents)&&(identical(other.todayIndex, todayIndex) || other.todayIndex == todayIndex)&&const DeepCollectionEquality().equals(other._categoryAccuracies, _categoryAccuracies)&&(identical(other.fastestAverageSeconds, fastestAverageSeconds) || other.fastestAverageSeconds == fastestAverageSeconds)&&(identical(other.fastestSubcategoryName, fastestSubcategoryName) || other.fastestSubcategoryName == fastestSubcategoryName)&&(identical(other.fastestLevelNumber, fastestLevelNumber) || other.fastestLevelNumber == fastestLevelNumber)&&(identical(other.fastestPercentileLabel, fastestPercentileLabel) || other.fastestPercentileLabel == fastestPercentileLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pointsPerDayPercents),todayIndex,const DeepCollectionEquality().hash(_categoryAccuracies),fastestAverageSeconds,fastestSubcategoryName,fastestLevelNumber,fastestPercentileLabel);

@override
String toString() {
  return 'StatsSummary(pointsPerDayPercents: $pointsPerDayPercents, todayIndex: $todayIndex, categoryAccuracies: $categoryAccuracies, fastestAverageSeconds: $fastestAverageSeconds, fastestSubcategoryName: $fastestSubcategoryName, fastestLevelNumber: $fastestLevelNumber, fastestPercentileLabel: $fastestPercentileLabel)';
}


}

/// @nodoc
abstract mixin class _$StatsSummaryCopyWith<$Res> implements $StatsSummaryCopyWith<$Res> {
  factory _$StatsSummaryCopyWith(_StatsSummary value, $Res Function(_StatsSummary) _then) = __$StatsSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<int> pointsPerDayPercents, int todayIndex, List<CategoryAccuracy> categoryAccuracies, double fastestAverageSeconds, String fastestSubcategoryName, int fastestLevelNumber, String fastestPercentileLabel
});




}
/// @nodoc
class __$StatsSummaryCopyWithImpl<$Res>
    implements _$StatsSummaryCopyWith<$Res> {
  __$StatsSummaryCopyWithImpl(this._self, this._then);

  final _StatsSummary _self;
  final $Res Function(_StatsSummary) _then;

/// Create a copy of StatsSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pointsPerDayPercents = null,Object? todayIndex = null,Object? categoryAccuracies = null,Object? fastestAverageSeconds = null,Object? fastestSubcategoryName = null,Object? fastestLevelNumber = null,Object? fastestPercentileLabel = null,}) {
  return _then(_StatsSummary(
pointsPerDayPercents: null == pointsPerDayPercents ? _self._pointsPerDayPercents : pointsPerDayPercents // ignore: cast_nullable_to_non_nullable
as List<int>,todayIndex: null == todayIndex ? _self.todayIndex : todayIndex // ignore: cast_nullable_to_non_nullable
as int,categoryAccuracies: null == categoryAccuracies ? _self._categoryAccuracies : categoryAccuracies // ignore: cast_nullable_to_non_nullable
as List<CategoryAccuracy>,fastestAverageSeconds: null == fastestAverageSeconds ? _self.fastestAverageSeconds : fastestAverageSeconds // ignore: cast_nullable_to_non_nullable
as double,fastestSubcategoryName: null == fastestSubcategoryName ? _self.fastestSubcategoryName : fastestSubcategoryName // ignore: cast_nullable_to_non_nullable
as String,fastestLevelNumber: null == fastestLevelNumber ? _self.fastestLevelNumber : fastestLevelNumber // ignore: cast_nullable_to_non_nullable
as int,fastestPercentileLabel: null == fastestPercentileLabel ? _self.fastestPercentileLabel : fastestPercentileLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
