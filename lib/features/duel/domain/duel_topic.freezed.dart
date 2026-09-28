// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_topic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelTopic {

 String get id; String get name; String get emoji; String get plateColor; String get categoryName; String get categoryEmoji; String get categoryId; int get myTopicLevel; int get openChallenges; int get searching;
/// Create a copy of DuelTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<DuelTopic> get copyWith => _$DuelTopicCopyWithImpl<DuelTopic>(this as DuelTopic, _$identity);

  /// Serializes this DuelTopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryEmoji, categoryEmoji) || other.categoryEmoji == categoryEmoji)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.myTopicLevel, myTopicLevel) || other.myTopicLevel == myTopicLevel)&&(identical(other.openChallenges, openChallenges) || other.openChallenges == openChallenges)&&(identical(other.searching, searching) || other.searching == searching));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,plateColor,categoryName,categoryEmoji,categoryId,myTopicLevel,openChallenges,searching);

@override
String toString() {
  return 'DuelTopic(id: $id, name: $name, emoji: $emoji, plateColor: $plateColor, categoryName: $categoryName, categoryEmoji: $categoryEmoji, categoryId: $categoryId, myTopicLevel: $myTopicLevel, openChallenges: $openChallenges, searching: $searching)';
}


}

/// @nodoc
abstract mixin class $DuelTopicCopyWith<$Res>  {
  factory $DuelTopicCopyWith(DuelTopic value, $Res Function(DuelTopic) _then) = _$DuelTopicCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, String plateColor, String categoryName, String categoryEmoji, String categoryId, int myTopicLevel, int openChallenges, int searching
});




}
/// @nodoc
class _$DuelTopicCopyWithImpl<$Res>
    implements $DuelTopicCopyWith<$Res> {
  _$DuelTopicCopyWithImpl(this._self, this._then);

  final DuelTopic _self;
  final $Res Function(DuelTopic) _then;

/// Create a copy of DuelTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? plateColor = null,Object? categoryName = null,Object? categoryEmoji = null,Object? categoryId = null,Object? myTopicLevel = null,Object? openChallenges = null,Object? searching = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,categoryEmoji: null == categoryEmoji ? _self.categoryEmoji : categoryEmoji // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,myTopicLevel: null == myTopicLevel ? _self.myTopicLevel : myTopicLevel // ignore: cast_nullable_to_non_nullable
as int,openChallenges: null == openChallenges ? _self.openChallenges : openChallenges // ignore: cast_nullable_to_non_nullable
as int,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelTopic].
extension DuelTopicPatterns on DuelTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelTopic value)  $default,){
final _that = this;
switch (_that) {
case _DuelTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelTopic value)?  $default,){
final _that = this;
switch (_that) {
case _DuelTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String plateColor,  String categoryName,  String categoryEmoji,  String categoryId,  int myTopicLevel,  int openChallenges,  int searching)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelTopic() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.plateColor,_that.categoryName,_that.categoryEmoji,_that.categoryId,_that.myTopicLevel,_that.openChallenges,_that.searching);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String plateColor,  String categoryName,  String categoryEmoji,  String categoryId,  int myTopicLevel,  int openChallenges,  int searching)  $default,) {final _that = this;
switch (_that) {
case _DuelTopic():
return $default(_that.id,_that.name,_that.emoji,_that.plateColor,_that.categoryName,_that.categoryEmoji,_that.categoryId,_that.myTopicLevel,_that.openChallenges,_that.searching);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  String plateColor,  String categoryName,  String categoryEmoji,  String categoryId,  int myTopicLevel,  int openChallenges,  int searching)?  $default,) {final _that = this;
switch (_that) {
case _DuelTopic() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.plateColor,_that.categoryName,_that.categoryEmoji,_that.categoryId,_that.myTopicLevel,_that.openChallenges,_that.searching);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelTopic extends DuelTopic {
  const _DuelTopic({required this.id, required this.name, required this.emoji, required this.plateColor, required this.categoryName, required this.categoryEmoji, this.categoryId = '', this.myTopicLevel = 0, this.openChallenges = 0, this.searching = 0}): super._();
  factory _DuelTopic.fromJson(Map<String, dynamic> json) => _$DuelTopicFromJson(json);

@override final  String id;
@override final  String name;
@override final  String emoji;
@override final  String plateColor;
@override final  String categoryName;
@override final  String categoryEmoji;
@override@JsonKey() final  String categoryId;
@override@JsonKey() final  int myTopicLevel;
@override@JsonKey() final  int openChallenges;
@override@JsonKey() final  int searching;

/// Create a copy of DuelTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelTopicCopyWith<_DuelTopic> get copyWith => __$DuelTopicCopyWithImpl<_DuelTopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelTopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryEmoji, categoryEmoji) || other.categoryEmoji == categoryEmoji)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.myTopicLevel, myTopicLevel) || other.myTopicLevel == myTopicLevel)&&(identical(other.openChallenges, openChallenges) || other.openChallenges == openChallenges)&&(identical(other.searching, searching) || other.searching == searching));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,plateColor,categoryName,categoryEmoji,categoryId,myTopicLevel,openChallenges,searching);

@override
String toString() {
  return 'DuelTopic(id: $id, name: $name, emoji: $emoji, plateColor: $plateColor, categoryName: $categoryName, categoryEmoji: $categoryEmoji, categoryId: $categoryId, myTopicLevel: $myTopicLevel, openChallenges: $openChallenges, searching: $searching)';
}


}

/// @nodoc
abstract mixin class _$DuelTopicCopyWith<$Res> implements $DuelTopicCopyWith<$Res> {
  factory _$DuelTopicCopyWith(_DuelTopic value, $Res Function(_DuelTopic) _then) = __$DuelTopicCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, String plateColor, String categoryName, String categoryEmoji, String categoryId, int myTopicLevel, int openChallenges, int searching
});




}
/// @nodoc
class __$DuelTopicCopyWithImpl<$Res>
    implements _$DuelTopicCopyWith<$Res> {
  __$DuelTopicCopyWithImpl(this._self, this._then);

  final _DuelTopic _self;
  final $Res Function(_DuelTopic) _then;

/// Create a copy of DuelTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? plateColor = null,Object? categoryName = null,Object? categoryEmoji = null,Object? categoryId = null,Object? myTopicLevel = null,Object? openChallenges = null,Object? searching = null,}) {
  return _then(_DuelTopic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,categoryEmoji: null == categoryEmoji ? _self.categoryEmoji : categoryEmoji // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,myTopicLevel: null == myTopicLevel ? _self.myTopicLevel : myTopicLevel // ignore: cast_nullable_to_non_nullable
as int,openChallenges: null == openChallenges ? _self.openChallenges : openChallenges // ignore: cast_nullable_to_non_nullable
as int,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
