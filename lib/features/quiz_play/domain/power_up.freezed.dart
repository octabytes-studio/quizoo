// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'power_up.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PowerUpInventory {

 int get fiftyFifty; int get addTime; int get skip;
/// Create a copy of PowerUpInventory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PowerUpInventoryCopyWith<PowerUpInventory> get copyWith => _$PowerUpInventoryCopyWithImpl<PowerUpInventory>(this as PowerUpInventory, _$identity);

  /// Serializes this PowerUpInventory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PowerUpInventory&&(identical(other.fiftyFifty, fiftyFifty) || other.fiftyFifty == fiftyFifty)&&(identical(other.addTime, addTime) || other.addTime == addTime)&&(identical(other.skip, skip) || other.skip == skip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fiftyFifty,addTime,skip);

@override
String toString() {
  return 'PowerUpInventory(fiftyFifty: $fiftyFifty, addTime: $addTime, skip: $skip)';
}


}

/// @nodoc
abstract mixin class $PowerUpInventoryCopyWith<$Res>  {
  factory $PowerUpInventoryCopyWith(PowerUpInventory value, $Res Function(PowerUpInventory) _then) = _$PowerUpInventoryCopyWithImpl;
@useResult
$Res call({
 int fiftyFifty, int addTime, int skip
});




}
/// @nodoc
class _$PowerUpInventoryCopyWithImpl<$Res>
    implements $PowerUpInventoryCopyWith<$Res> {
  _$PowerUpInventoryCopyWithImpl(this._self, this._then);

  final PowerUpInventory _self;
  final $Res Function(PowerUpInventory) _then;

/// Create a copy of PowerUpInventory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fiftyFifty = null,Object? addTime = null,Object? skip = null,}) {
  return _then(_self.copyWith(
fiftyFifty: null == fiftyFifty ? _self.fiftyFifty : fiftyFifty // ignore: cast_nullable_to_non_nullable
as int,addTime: null == addTime ? _self.addTime : addTime // ignore: cast_nullable_to_non_nullable
as int,skip: null == skip ? _self.skip : skip // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PowerUpInventory].
extension PowerUpInventoryPatterns on PowerUpInventory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PowerUpInventory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PowerUpInventory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PowerUpInventory value)  $default,){
final _that = this;
switch (_that) {
case _PowerUpInventory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PowerUpInventory value)?  $default,){
final _that = this;
switch (_that) {
case _PowerUpInventory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int fiftyFifty,  int addTime,  int skip)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PowerUpInventory() when $default != null:
return $default(_that.fiftyFifty,_that.addTime,_that.skip);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int fiftyFifty,  int addTime,  int skip)  $default,) {final _that = this;
switch (_that) {
case _PowerUpInventory():
return $default(_that.fiftyFifty,_that.addTime,_that.skip);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int fiftyFifty,  int addTime,  int skip)?  $default,) {final _that = this;
switch (_that) {
case _PowerUpInventory() when $default != null:
return $default(_that.fiftyFifty,_that.addTime,_that.skip);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PowerUpInventory extends PowerUpInventory {
  const _PowerUpInventory({this.fiftyFifty = 0, this.addTime = 0, this.skip = 0}): super._();
  factory _PowerUpInventory.fromJson(Map<String, dynamic> json) => _$PowerUpInventoryFromJson(json);

@override@JsonKey() final  int fiftyFifty;
@override@JsonKey() final  int addTime;
@override@JsonKey() final  int skip;

/// Create a copy of PowerUpInventory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PowerUpInventoryCopyWith<_PowerUpInventory> get copyWith => __$PowerUpInventoryCopyWithImpl<_PowerUpInventory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PowerUpInventoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PowerUpInventory&&(identical(other.fiftyFifty, fiftyFifty) || other.fiftyFifty == fiftyFifty)&&(identical(other.addTime, addTime) || other.addTime == addTime)&&(identical(other.skip, skip) || other.skip == skip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fiftyFifty,addTime,skip);

@override
String toString() {
  return 'PowerUpInventory(fiftyFifty: $fiftyFifty, addTime: $addTime, skip: $skip)';
}


}

/// @nodoc
abstract mixin class _$PowerUpInventoryCopyWith<$Res> implements $PowerUpInventoryCopyWith<$Res> {
  factory _$PowerUpInventoryCopyWith(_PowerUpInventory value, $Res Function(_PowerUpInventory) _then) = __$PowerUpInventoryCopyWithImpl;
@override @useResult
$Res call({
 int fiftyFifty, int addTime, int skip
});




}
/// @nodoc
class __$PowerUpInventoryCopyWithImpl<$Res>
    implements _$PowerUpInventoryCopyWith<$Res> {
  __$PowerUpInventoryCopyWithImpl(this._self, this._then);

  final _PowerUpInventory _self;
  final $Res Function(_PowerUpInventory) _then;

/// Create a copy of PowerUpInventory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fiftyFifty = null,Object? addTime = null,Object? skip = null,}) {
  return _then(_PowerUpInventory(
fiftyFifty: null == fiftyFifty ? _self.fiftyFifty : fiftyFifty // ignore: cast_nullable_to_non_nullable
as int,addTime: null == addTime ? _self.addTime : addTime // ignore: cast_nullable_to_non_nullable
as int,skip: null == skip ? _self.skip : skip // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
