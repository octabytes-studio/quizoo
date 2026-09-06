// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryDetail {

 Category get category; List<Subcategory> get topics;/// The "128k players" half of the header meta line. It is not on
/// [Category] because it is a live engagement figure, not taxonomy.
 int get playerCount;
/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryDetailCopyWith<CategoryDetail> get copyWith => _$CategoryDetailCopyWithImpl<CategoryDetail>(this as CategoryDetail, _$identity);

  /// Serializes this CategoryDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryDetail&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(topics),playerCount);

@override
String toString() {
  return 'CategoryDetail(category: $category, topics: $topics, playerCount: $playerCount)';
}


}

/// @nodoc
abstract mixin class $CategoryDetailCopyWith<$Res>  {
  factory $CategoryDetailCopyWith(CategoryDetail value, $Res Function(CategoryDetail) _then) = _$CategoryDetailCopyWithImpl;
@useResult
$Res call({
 Category category, List<Subcategory> topics, int playerCount
});


$CategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryDetailCopyWithImpl<$Res>
    implements $CategoryDetailCopyWith<$Res> {
  _$CategoryDetailCopyWithImpl(this._self, this._then);

  final CategoryDetail _self;
  final $Res Function(CategoryDetail) _then;

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? topics = null,Object? playerCount = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryDetail].
extension CategoryDetailPatterns on CategoryDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryDetail value)  $default,){
final _that = this;
switch (_that) {
case _CategoryDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Category category,  List<Subcategory> topics,  int playerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
return $default(_that.category,_that.topics,_that.playerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Category category,  List<Subcategory> topics,  int playerCount)  $default,) {final _that = this;
switch (_that) {
case _CategoryDetail():
return $default(_that.category,_that.topics,_that.playerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Category category,  List<Subcategory> topics,  int playerCount)?  $default,) {final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
return $default(_that.category,_that.topics,_that.playerCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryDetail implements CategoryDetail {
  const _CategoryDetail({required this.category, final  List<Subcategory> topics = const [], this.playerCount = 0}): _topics = topics;
  factory _CategoryDetail.fromJson(Map<String, dynamic> json) => _$CategoryDetailFromJson(json);

@override final  Category category;
 final  List<Subcategory> _topics;
@override@JsonKey() List<Subcategory> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

/// The "128k players" half of the header meta line. It is not on
/// [Category] because it is a live engagement figure, not taxonomy.
@override@JsonKey() final  int playerCount;

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryDetailCopyWith<_CategoryDetail> get copyWith => __$CategoryDetailCopyWithImpl<_CategoryDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryDetail&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_topics),playerCount);

@override
String toString() {
  return 'CategoryDetail(category: $category, topics: $topics, playerCount: $playerCount)';
}


}

/// @nodoc
abstract mixin class _$CategoryDetailCopyWith<$Res> implements $CategoryDetailCopyWith<$Res> {
  factory _$CategoryDetailCopyWith(_CategoryDetail value, $Res Function(_CategoryDetail) _then) = __$CategoryDetailCopyWithImpl;
@override @useResult
$Res call({
 Category category, List<Subcategory> topics, int playerCount
});


@override $CategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryDetailCopyWithImpl<$Res>
    implements _$CategoryDetailCopyWith<$Res> {
  __$CategoryDetailCopyWithImpl(this._self, this._then);

  final _CategoryDetail _self;
  final $Res Function(_CategoryDetail) _then;

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? topics = null,Object? playerCount = null,}) {
  return _then(_CategoryDetail(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
