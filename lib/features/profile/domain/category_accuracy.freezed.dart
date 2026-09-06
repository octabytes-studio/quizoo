// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_accuracy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryAccuracy {

 String get categoryName; String get emoji; int get accuracyPercent;
/// Create a copy of CategoryAccuracy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryAccuracyCopyWith<CategoryAccuracy> get copyWith => _$CategoryAccuracyCopyWithImpl<CategoryAccuracy>(this as CategoryAccuracy, _$identity);

  /// Serializes this CategoryAccuracy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryAccuracy&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.accuracyPercent, accuracyPercent) || other.accuracyPercent == accuracyPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryName,emoji,accuracyPercent);

@override
String toString() {
  return 'CategoryAccuracy(categoryName: $categoryName, emoji: $emoji, accuracyPercent: $accuracyPercent)';
}


}

/// @nodoc
abstract mixin class $CategoryAccuracyCopyWith<$Res>  {
  factory $CategoryAccuracyCopyWith(CategoryAccuracy value, $Res Function(CategoryAccuracy) _then) = _$CategoryAccuracyCopyWithImpl;
@useResult
$Res call({
 String categoryName, String emoji, int accuracyPercent
});




}
/// @nodoc
class _$CategoryAccuracyCopyWithImpl<$Res>
    implements $CategoryAccuracyCopyWith<$Res> {
  _$CategoryAccuracyCopyWithImpl(this._self, this._then);

  final CategoryAccuracy _self;
  final $Res Function(CategoryAccuracy) _then;

/// Create a copy of CategoryAccuracy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryName = null,Object? emoji = null,Object? accuracyPercent = null,}) {
  return _then(_self.copyWith(
categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,accuracyPercent: null == accuracyPercent ? _self.accuracyPercent : accuracyPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryAccuracy].
extension CategoryAccuracyPatterns on CategoryAccuracy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryAccuracy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryAccuracy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryAccuracy value)  $default,){
final _that = this;
switch (_that) {
case _CategoryAccuracy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryAccuracy value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryAccuracy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryName,  String emoji,  int accuracyPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryAccuracy() when $default != null:
return $default(_that.categoryName,_that.emoji,_that.accuracyPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryName,  String emoji,  int accuracyPercent)  $default,) {final _that = this;
switch (_that) {
case _CategoryAccuracy():
return $default(_that.categoryName,_that.emoji,_that.accuracyPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryName,  String emoji,  int accuracyPercent)?  $default,) {final _that = this;
switch (_that) {
case _CategoryAccuracy() when $default != null:
return $default(_that.categoryName,_that.emoji,_that.accuracyPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryAccuracy implements CategoryAccuracy {
  const _CategoryAccuracy({required this.categoryName, required this.emoji, required this.accuracyPercent});
  factory _CategoryAccuracy.fromJson(Map<String, dynamic> json) => _$CategoryAccuracyFromJson(json);

@override final  String categoryName;
@override final  String emoji;
@override final  int accuracyPercent;

/// Create a copy of CategoryAccuracy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryAccuracyCopyWith<_CategoryAccuracy> get copyWith => __$CategoryAccuracyCopyWithImpl<_CategoryAccuracy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryAccuracyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryAccuracy&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.accuracyPercent, accuracyPercent) || other.accuracyPercent == accuracyPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryName,emoji,accuracyPercent);

@override
String toString() {
  return 'CategoryAccuracy(categoryName: $categoryName, emoji: $emoji, accuracyPercent: $accuracyPercent)';
}


}

/// @nodoc
abstract mixin class _$CategoryAccuracyCopyWith<$Res> implements $CategoryAccuracyCopyWith<$Res> {
  factory _$CategoryAccuracyCopyWith(_CategoryAccuracy value, $Res Function(_CategoryAccuracy) _then) = __$CategoryAccuracyCopyWithImpl;
@override @useResult
$Res call({
 String categoryName, String emoji, int accuracyPercent
});




}
/// @nodoc
class __$CategoryAccuracyCopyWithImpl<$Res>
    implements _$CategoryAccuracyCopyWith<$Res> {
  __$CategoryAccuracyCopyWithImpl(this._self, this._then);

  final _CategoryAccuracy _self;
  final $Res Function(_CategoryAccuracy) _then;

/// Create a copy of CategoryAccuracy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryName = null,Object? emoji = null,Object? accuracyPercent = null,}) {
  return _then(_CategoryAccuracy(
categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,accuracyPercent: null == accuracyPercent ? _self.accuracyPercent : accuracyPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
