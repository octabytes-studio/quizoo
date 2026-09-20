// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'avatar_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvatarOption {

 String get id; String get emoji; int get sortOrder;
/// Create a copy of AvatarOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvatarOptionCopyWith<AvatarOption> get copyWith => _$AvatarOptionCopyWithImpl<AvatarOption>(this as AvatarOption, _$identity);

  /// Serializes this AvatarOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvatarOption&&(identical(other.id, id) || other.id == id)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,emoji,sortOrder);

@override
String toString() {
  return 'AvatarOption(id: $id, emoji: $emoji, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $AvatarOptionCopyWith<$Res>  {
  factory $AvatarOptionCopyWith(AvatarOption value, $Res Function(AvatarOption) _then) = _$AvatarOptionCopyWithImpl;
@useResult
$Res call({
 String id, String emoji, int sortOrder
});




}
/// @nodoc
class _$AvatarOptionCopyWithImpl<$Res>
    implements $AvatarOptionCopyWith<$Res> {
  _$AvatarOptionCopyWithImpl(this._self, this._then);

  final AvatarOption _self;
  final $Res Function(AvatarOption) _then;

/// Create a copy of AvatarOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? emoji = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AvatarOption].
extension AvatarOptionPatterns on AvatarOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvatarOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvatarOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvatarOption value)  $default,){
final _that = this;
switch (_that) {
case _AvatarOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvatarOption value)?  $default,){
final _that = this;
switch (_that) {
case _AvatarOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String emoji,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvatarOption() when $default != null:
return $default(_that.id,_that.emoji,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String emoji,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _AvatarOption():
return $default(_that.id,_that.emoji,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String emoji,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _AvatarOption() when $default != null:
return $default(_that.id,_that.emoji,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvatarOption implements AvatarOption {
  const _AvatarOption({required this.id, required this.emoji, required this.sortOrder});
  factory _AvatarOption.fromJson(Map<String, dynamic> json) => _$AvatarOptionFromJson(json);

@override final  String id;
@override final  String emoji;
@override final  int sortOrder;

/// Create a copy of AvatarOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvatarOptionCopyWith<_AvatarOption> get copyWith => __$AvatarOptionCopyWithImpl<_AvatarOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvatarOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvatarOption&&(identical(other.id, id) || other.id == id)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,emoji,sortOrder);

@override
String toString() {
  return 'AvatarOption(id: $id, emoji: $emoji, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$AvatarOptionCopyWith<$Res> implements $AvatarOptionCopyWith<$Res> {
  factory _$AvatarOptionCopyWith(_AvatarOption value, $Res Function(_AvatarOption) _then) = __$AvatarOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String emoji, int sortOrder
});




}
/// @nodoc
class __$AvatarOptionCopyWithImpl<$Res>
    implements _$AvatarOptionCopyWith<$Res> {
  __$AvatarOptionCopyWithImpl(this._self, this._then);

  final _AvatarOption _self;
  final $Res Function(_AvatarOption) _then;

/// Create a copy of AvatarOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? emoji = null,Object? sortOrder = null,}) {
  return _then(_AvatarOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
