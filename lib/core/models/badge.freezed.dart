// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppBadge {

 String get id; String get name; String get emoji;/// One-line explanation of what earns it.
 String get description;/// Start of the medallion's gradient, as `#RRGGBB`.
 String get gradientFrom;/// End of the medallion's gradient, as `#RRGGBB`.
 String get gradientTo; bool get isLocked;/// Share of players holding this badge, 0…100 — the "Top 3%" line.
 double get rarityPercent; DateTime? get unlockedAt;
/// Create a copy of AppBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppBadgeCopyWith<AppBadge> get copyWith => _$AppBadgeCopyWithImpl<AppBadge>(this as AppBadge, _$identity);

  /// Serializes this AppBadge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBadge&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.description, description) || other.description == description)&&(identical(other.gradientFrom, gradientFrom) || other.gradientFrom == gradientFrom)&&(identical(other.gradientTo, gradientTo) || other.gradientTo == gradientTo)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.rarityPercent, rarityPercent) || other.rarityPercent == rarityPercent)&&(identical(other.unlockedAt, unlockedAt) || other.unlockedAt == unlockedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,description,gradientFrom,gradientTo,isLocked,rarityPercent,unlockedAt);

@override
String toString() {
  return 'AppBadge(id: $id, name: $name, emoji: $emoji, description: $description, gradientFrom: $gradientFrom, gradientTo: $gradientTo, isLocked: $isLocked, rarityPercent: $rarityPercent, unlockedAt: $unlockedAt)';
}


}

/// @nodoc
abstract mixin class $AppBadgeCopyWith<$Res>  {
  factory $AppBadgeCopyWith(AppBadge value, $Res Function(AppBadge) _then) = _$AppBadgeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, String description, String gradientFrom, String gradientTo, bool isLocked, double rarityPercent, DateTime? unlockedAt
});




}
/// @nodoc
class _$AppBadgeCopyWithImpl<$Res>
    implements $AppBadgeCopyWith<$Res> {
  _$AppBadgeCopyWithImpl(this._self, this._then);

  final AppBadge _self;
  final $Res Function(AppBadge) _then;

/// Create a copy of AppBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? description = null,Object? gradientFrom = null,Object? gradientTo = null,Object? isLocked = null,Object? rarityPercent = null,Object? unlockedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gradientFrom: null == gradientFrom ? _self.gradientFrom : gradientFrom // ignore: cast_nullable_to_non_nullable
as String,gradientTo: null == gradientTo ? _self.gradientTo : gradientTo // ignore: cast_nullable_to_non_nullable
as String,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,rarityPercent: null == rarityPercent ? _self.rarityPercent : rarityPercent // ignore: cast_nullable_to_non_nullable
as double,unlockedAt: freezed == unlockedAt ? _self.unlockedAt : unlockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppBadge].
extension AppBadgePatterns on AppBadge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppBadge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppBadge value)  $default,){
final _that = this;
switch (_that) {
case _AppBadge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppBadge value)?  $default,){
final _that = this;
switch (_that) {
case _AppBadge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String description,  String gradientFrom,  String gradientTo,  bool isLocked,  double rarityPercent,  DateTime? unlockedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppBadge() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.description,_that.gradientFrom,_that.gradientTo,_that.isLocked,_that.rarityPercent,_that.unlockedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String description,  String gradientFrom,  String gradientTo,  bool isLocked,  double rarityPercent,  DateTime? unlockedAt)  $default,) {final _that = this;
switch (_that) {
case _AppBadge():
return $default(_that.id,_that.name,_that.emoji,_that.description,_that.gradientFrom,_that.gradientTo,_that.isLocked,_that.rarityPercent,_that.unlockedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  String description,  String gradientFrom,  String gradientTo,  bool isLocked,  double rarityPercent,  DateTime? unlockedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppBadge() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.description,_that.gradientFrom,_that.gradientTo,_that.isLocked,_that.rarityPercent,_that.unlockedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppBadge implements AppBadge {
  const _AppBadge({required this.id, required this.name, required this.emoji, required this.description, required this.gradientFrom, required this.gradientTo, this.isLocked = true, this.rarityPercent = 100, this.unlockedAt});
  factory _AppBadge.fromJson(Map<String, dynamic> json) => _$AppBadgeFromJson(json);

@override final  String id;
@override final  String name;
@override final  String emoji;
/// One-line explanation of what earns it.
@override final  String description;
/// Start of the medallion's gradient, as `#RRGGBB`.
@override final  String gradientFrom;
/// End of the medallion's gradient, as `#RRGGBB`.
@override final  String gradientTo;
@override@JsonKey() final  bool isLocked;
/// Share of players holding this badge, 0…100 — the "Top 3%" line.
@override@JsonKey() final  double rarityPercent;
@override final  DateTime? unlockedAt;

/// Create a copy of AppBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppBadgeCopyWith<_AppBadge> get copyWith => __$AppBadgeCopyWithImpl<_AppBadge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppBadgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppBadge&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.description, description) || other.description == description)&&(identical(other.gradientFrom, gradientFrom) || other.gradientFrom == gradientFrom)&&(identical(other.gradientTo, gradientTo) || other.gradientTo == gradientTo)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.rarityPercent, rarityPercent) || other.rarityPercent == rarityPercent)&&(identical(other.unlockedAt, unlockedAt) || other.unlockedAt == unlockedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,description,gradientFrom,gradientTo,isLocked,rarityPercent,unlockedAt);

@override
String toString() {
  return 'AppBadge(id: $id, name: $name, emoji: $emoji, description: $description, gradientFrom: $gradientFrom, gradientTo: $gradientTo, isLocked: $isLocked, rarityPercent: $rarityPercent, unlockedAt: $unlockedAt)';
}


}

/// @nodoc
abstract mixin class _$AppBadgeCopyWith<$Res> implements $AppBadgeCopyWith<$Res> {
  factory _$AppBadgeCopyWith(_AppBadge value, $Res Function(_AppBadge) _then) = __$AppBadgeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, String description, String gradientFrom, String gradientTo, bool isLocked, double rarityPercent, DateTime? unlockedAt
});




}
/// @nodoc
class __$AppBadgeCopyWithImpl<$Res>
    implements _$AppBadgeCopyWith<$Res> {
  __$AppBadgeCopyWithImpl(this._self, this._then);

  final _AppBadge _self;
  final $Res Function(_AppBadge) _then;

/// Create a copy of AppBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? description = null,Object? gradientFrom = null,Object? gradientTo = null,Object? isLocked = null,Object? rarityPercent = null,Object? unlockedAt = freezed,}) {
  return _then(_AppBadge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gradientFrom: null == gradientFrom ? _self.gradientFrom : gradientFrom // ignore: cast_nullable_to_non_nullable
as String,gradientTo: null == gradientTo ? _self.gradientTo : gradientTo // ignore: cast_nullable_to_non_nullable
as String,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,rarityPercent: null == rarityPercent ? _self.rarityPercent : rarityPercent // ignore: cast_nullable_to_non_nullable
as double,unlockedAt: freezed == unlockedAt ? _self.unlockedAt : unlockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
