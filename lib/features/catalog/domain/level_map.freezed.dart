// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_map.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LevelMap {

 Category get category; Subcategory get subcategory; List<Level> get levels;/// The "#412" stat. Zero means unranked, which is a guest.
 int get rank;
/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelMapCopyWith<LevelMap> get copyWith => _$LevelMapCopyWithImpl<LevelMap>(this as LevelMap, _$identity);

  /// Serializes this LevelMap to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelMap&&(identical(other.category, category) || other.category == category)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&const DeepCollectionEquality().equals(other.levels, levels)&&(identical(other.rank, rank) || other.rank == rank));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,subcategory,const DeepCollectionEquality().hash(levels),rank);

@override
String toString() {
  return 'LevelMap(category: $category, subcategory: $subcategory, levels: $levels, rank: $rank)';
}


}

/// @nodoc
abstract mixin class $LevelMapCopyWith<$Res>  {
  factory $LevelMapCopyWith(LevelMap value, $Res Function(LevelMap) _then) = _$LevelMapCopyWithImpl;
@useResult
$Res call({
 Category category, Subcategory subcategory, List<Level> levels, int rank
});


$CategoryCopyWith<$Res> get category;$SubcategoryCopyWith<$Res> get subcategory;

}
/// @nodoc
class _$LevelMapCopyWithImpl<$Res>
    implements $LevelMapCopyWith<$Res> {
  _$LevelMapCopyWithImpl(this._self, this._then);

  final LevelMap _self;
  final $Res Function(LevelMap) _then;

/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? subcategory = null,Object? levels = null,Object? rank = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,subcategory: null == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as Subcategory,levels: null == levels ? _self.levels : levels // ignore: cast_nullable_to_non_nullable
as List<Level>,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubcategoryCopyWith<$Res> get subcategory {
  
  return $SubcategoryCopyWith<$Res>(_self.subcategory, (value) {
    return _then(_self.copyWith(subcategory: value));
  });
}
}


/// Adds pattern-matching-related methods to [LevelMap].
extension LevelMapPatterns on LevelMap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelMap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelMap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelMap value)  $default,){
final _that = this;
switch (_that) {
case _LevelMap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelMap value)?  $default,){
final _that = this;
switch (_that) {
case _LevelMap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Category category,  Subcategory subcategory,  List<Level> levels,  int rank)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelMap() when $default != null:
return $default(_that.category,_that.subcategory,_that.levels,_that.rank);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Category category,  Subcategory subcategory,  List<Level> levels,  int rank)  $default,) {final _that = this;
switch (_that) {
case _LevelMap():
return $default(_that.category,_that.subcategory,_that.levels,_that.rank);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Category category,  Subcategory subcategory,  List<Level> levels,  int rank)?  $default,) {final _that = this;
switch (_that) {
case _LevelMap() when $default != null:
return $default(_that.category,_that.subcategory,_that.levels,_that.rank);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelMap extends LevelMap {
  const _LevelMap({required this.category, required this.subcategory, final  List<Level> levels = const [], this.rank = 0}): _levels = levels,super._();
  factory _LevelMap.fromJson(Map<String, dynamic> json) => _$LevelMapFromJson(json);

@override final  Category category;
@override final  Subcategory subcategory;
 final  List<Level> _levels;
@override@JsonKey() List<Level> get levels {
  if (_levels is EqualUnmodifiableListView) return _levels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_levels);
}

/// The "#412" stat. Zero means unranked, which is a guest.
@override@JsonKey() final  int rank;

/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelMapCopyWith<_LevelMap> get copyWith => __$LevelMapCopyWithImpl<_LevelMap>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelMapToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelMap&&(identical(other.category, category) || other.category == category)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&const DeepCollectionEquality().equals(other._levels, _levels)&&(identical(other.rank, rank) || other.rank == rank));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,subcategory,const DeepCollectionEquality().hash(_levels),rank);

@override
String toString() {
  return 'LevelMap(category: $category, subcategory: $subcategory, levels: $levels, rank: $rank)';
}


}

/// @nodoc
abstract mixin class _$LevelMapCopyWith<$Res> implements $LevelMapCopyWith<$Res> {
  factory _$LevelMapCopyWith(_LevelMap value, $Res Function(_LevelMap) _then) = __$LevelMapCopyWithImpl;
@override @useResult
$Res call({
 Category category, Subcategory subcategory, List<Level> levels, int rank
});


@override $CategoryCopyWith<$Res> get category;@override $SubcategoryCopyWith<$Res> get subcategory;

}
/// @nodoc
class __$LevelMapCopyWithImpl<$Res>
    implements _$LevelMapCopyWith<$Res> {
  __$LevelMapCopyWithImpl(this._self, this._then);

  final _LevelMap _self;
  final $Res Function(_LevelMap) _then;

/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? subcategory = null,Object? levels = null,Object? rank = null,}) {
  return _then(_LevelMap(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,subcategory: null == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as Subcategory,levels: null == levels ? _self._levels : levels // ignore: cast_nullable_to_non_nullable
as List<Level>,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of LevelMap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubcategoryCopyWith<$Res> get subcategory {
  
  return $SubcategoryCopyWith<$Res>(_self.subcategory, (value) {
    return _then(_self.copyWith(subcategory: value));
  });
}
}

// dart format on
