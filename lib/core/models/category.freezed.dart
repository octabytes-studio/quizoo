// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Category {

 String get id; String get name;/// The emoji that stands in for the category everywhere it is listed.
 String get emoji;/// Start of the tile's gradient, as `#RRGGBB`.
 String get colorFrom;/// End of the tile's gradient, as `#RRGGBB`.
 String get colorTo;/// Display order in the chip row.
 int get order; int get subcategoryCount; int get questionCount; bool get isNew; bool get isLocked;
/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryCopyWith<Category> get copyWith => _$CategoryCopyWithImpl<Category>(this as Category, _$identity);

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Category&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.colorFrom, colorFrom) || other.colorFrom == colorFrom)&&(identical(other.colorTo, colorTo) || other.colorTo == colorTo)&&(identical(other.order, order) || other.order == order)&&(identical(other.subcategoryCount, subcategoryCount) || other.subcategoryCount == subcategoryCount)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,colorFrom,colorTo,order,subcategoryCount,questionCount,isNew,isLocked);

@override
String toString() {
  return 'Category(id: $id, name: $name, emoji: $emoji, colorFrom: $colorFrom, colorTo: $colorTo, order: $order, subcategoryCount: $subcategoryCount, questionCount: $questionCount, isNew: $isNew, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class $CategoryCopyWith<$Res>  {
  factory $CategoryCopyWith(Category value, $Res Function(Category) _then) = _$CategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, String colorFrom, String colorTo, int order, int subcategoryCount, int questionCount, bool isNew, bool isLocked
});




}
/// @nodoc
class _$CategoryCopyWithImpl<$Res>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._self, this._then);

  final Category _self;
  final $Res Function(Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? colorFrom = null,Object? colorTo = null,Object? order = null,Object? subcategoryCount = null,Object? questionCount = null,Object? isNew = null,Object? isLocked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,colorFrom: null == colorFrom ? _self.colorFrom : colorFrom // ignore: cast_nullable_to_non_nullable
as String,colorTo: null == colorTo ? _self.colorTo : colorTo // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,subcategoryCount: null == subcategoryCount ? _self.subcategoryCount : subcategoryCount // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Category].
extension CategoryPatterns on Category {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Category value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Category value)  $default,){
final _that = this;
switch (_that) {
case _Category():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Category value)?  $default,){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String colorFrom,  String colorTo,  int order,  int subcategoryCount,  int questionCount,  bool isNew,  bool isLocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.colorFrom,_that.colorTo,_that.order,_that.subcategoryCount,_that.questionCount,_that.isNew,_that.isLocked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String colorFrom,  String colorTo,  int order,  int subcategoryCount,  int questionCount,  bool isNew,  bool isLocked)  $default,) {final _that = this;
switch (_that) {
case _Category():
return $default(_that.id,_that.name,_that.emoji,_that.colorFrom,_that.colorTo,_that.order,_that.subcategoryCount,_that.questionCount,_that.isNew,_that.isLocked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  String colorFrom,  String colorTo,  int order,  int subcategoryCount,  int questionCount,  bool isNew,  bool isLocked)?  $default,) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.colorFrom,_that.colorTo,_that.order,_that.subcategoryCount,_that.questionCount,_that.isNew,_that.isLocked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Category implements Category {
  const _Category({required this.id, required this.name, required this.emoji, required this.colorFrom, required this.colorTo, required this.order, this.subcategoryCount = 0, this.questionCount = 0, this.isNew = false, this.isLocked = false});
  factory _Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

@override final  String id;
@override final  String name;
/// The emoji that stands in for the category everywhere it is listed.
@override final  String emoji;
/// Start of the tile's gradient, as `#RRGGBB`.
@override final  String colorFrom;
/// End of the tile's gradient, as `#RRGGBB`.
@override final  String colorTo;
/// Display order in the chip row.
@override final  int order;
@override@JsonKey() final  int subcategoryCount;
@override@JsonKey() final  int questionCount;
@override@JsonKey() final  bool isNew;
@override@JsonKey() final  bool isLocked;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryCopyWith<_Category> get copyWith => __$CategoryCopyWithImpl<_Category>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Category&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.colorFrom, colorFrom) || other.colorFrom == colorFrom)&&(identical(other.colorTo, colorTo) || other.colorTo == colorTo)&&(identical(other.order, order) || other.order == order)&&(identical(other.subcategoryCount, subcategoryCount) || other.subcategoryCount == subcategoryCount)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,colorFrom,colorTo,order,subcategoryCount,questionCount,isNew,isLocked);

@override
String toString() {
  return 'Category(id: $id, name: $name, emoji: $emoji, colorFrom: $colorFrom, colorTo: $colorTo, order: $order, subcategoryCount: $subcategoryCount, questionCount: $questionCount, isNew: $isNew, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class _$CategoryCopyWith<$Res> implements $CategoryCopyWith<$Res> {
  factory _$CategoryCopyWith(_Category value, $Res Function(_Category) _then) = __$CategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, String colorFrom, String colorTo, int order, int subcategoryCount, int questionCount, bool isNew, bool isLocked
});




}
/// @nodoc
class __$CategoryCopyWithImpl<$Res>
    implements _$CategoryCopyWith<$Res> {
  __$CategoryCopyWithImpl(this._self, this._then);

  final _Category _self;
  final $Res Function(_Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? colorFrom = null,Object? colorTo = null,Object? order = null,Object? subcategoryCount = null,Object? questionCount = null,Object? isNew = null,Object? isLocked = null,}) {
  return _then(_Category(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,colorFrom: null == colorFrom ? _self.colorFrom : colorFrom // ignore: cast_nullable_to_non_nullable
as String,colorTo: null == colorTo ? _self.colorTo : colorTo // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,subcategoryCount: null == subcategoryCount ? _self.subcategoryCount : subcategoryCount // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
