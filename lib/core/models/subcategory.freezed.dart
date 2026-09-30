// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subcategory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subcategory {

 String get id; String get categoryId; String get name; String get emoji;/// The grouping the bible's search breadcrumb prints between the category
/// and this topic — "Science › **Astronomy** · 400 questions".
/// Empty when the topic sits directly under its category.
 String get groupName;/// Tint behind the tile's emoji plate, as `#RRGGBB`.
 String get plateColor; int get questionCount;/// Levels the player has finished, of [levelCount].
 int get levelsCleared; int get levelCount; int get bestScore;/// Stars earned across every level, of `levelCount * 3`.
 int get starsEarned; bool get isNew; bool get isLocked;
/// Create a copy of Subcategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubcategoryCopyWith<Subcategory> get copyWith => _$SubcategoryCopyWithImpl<Subcategory>(this as Subcategory, _$identity);

  /// Serializes this Subcategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subcategory&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.bestScore, bestScore) || other.bestScore == bestScore)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,name,emoji,groupName,plateColor,questionCount,levelsCleared,levelCount,bestScore,starsEarned,isNew,isLocked);

@override
String toString() {
  return 'Subcategory(id: $id, categoryId: $categoryId, name: $name, emoji: $emoji, groupName: $groupName, plateColor: $plateColor, questionCount: $questionCount, levelsCleared: $levelsCleared, levelCount: $levelCount, bestScore: $bestScore, starsEarned: $starsEarned, isNew: $isNew, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class $SubcategoryCopyWith<$Res>  {
  factory $SubcategoryCopyWith(Subcategory value, $Res Function(Subcategory) _then) = _$SubcategoryCopyWithImpl;
@useResult
$Res call({
 String id, String categoryId, String name, String emoji, String groupName, String plateColor, int questionCount, int levelsCleared, int levelCount, int bestScore, int starsEarned, bool isNew, bool isLocked
});




}
/// @nodoc
class _$SubcategoryCopyWithImpl<$Res>
    implements $SubcategoryCopyWith<$Res> {
  _$SubcategoryCopyWithImpl(this._self, this._then);

  final Subcategory _self;
  final $Res Function(Subcategory) _then;

/// Create a copy of Subcategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? emoji = null,Object? groupName = null,Object? plateColor = null,Object? questionCount = null,Object? levelsCleared = null,Object? levelCount = null,Object? bestScore = null,Object? starsEarned = null,Object? isNew = null,Object? isLocked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,levelCount: null == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int,bestScore: null == bestScore ? _self.bestScore : bestScore // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Subcategory].
extension SubcategoryPatterns on Subcategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subcategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subcategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subcategory value)  $default,){
final _that = this;
switch (_that) {
case _Subcategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subcategory value)?  $default,){
final _that = this;
switch (_that) {
case _Subcategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String categoryId,  String name,  String emoji,  String groupName,  String plateColor,  int questionCount,  int levelsCleared,  int levelCount,  int bestScore,  int starsEarned,  bool isNew,  bool isLocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subcategory() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.emoji,_that.groupName,_that.plateColor,_that.questionCount,_that.levelsCleared,_that.levelCount,_that.bestScore,_that.starsEarned,_that.isNew,_that.isLocked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String categoryId,  String name,  String emoji,  String groupName,  String plateColor,  int questionCount,  int levelsCleared,  int levelCount,  int bestScore,  int starsEarned,  bool isNew,  bool isLocked)  $default,) {final _that = this;
switch (_that) {
case _Subcategory():
return $default(_that.id,_that.categoryId,_that.name,_that.emoji,_that.groupName,_that.plateColor,_that.questionCount,_that.levelsCleared,_that.levelCount,_that.bestScore,_that.starsEarned,_that.isNew,_that.isLocked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String categoryId,  String name,  String emoji,  String groupName,  String plateColor,  int questionCount,  int levelsCleared,  int levelCount,  int bestScore,  int starsEarned,  bool isNew,  bool isLocked)?  $default,) {final _that = this;
switch (_that) {
case _Subcategory() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.emoji,_that.groupName,_that.plateColor,_that.questionCount,_that.levelsCleared,_that.levelCount,_that.bestScore,_that.starsEarned,_that.isNew,_that.isLocked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subcategory extends Subcategory {
  const _Subcategory({required this.id, required this.categoryId, required this.name, required this.emoji, this.groupName = '', required this.plateColor, this.questionCount = 0, this.levelsCleared = 0, this.levelCount = LadderConfigRepository.fallbackTotalLevels, this.bestScore = 0, this.starsEarned = 0, this.isNew = false, this.isLocked = false}): super._();
  factory _Subcategory.fromJson(Map<String, dynamic> json) => _$SubcategoryFromJson(json);

@override final  String id;
@override final  String categoryId;
@override final  String name;
@override final  String emoji;
/// The grouping the bible's search breadcrumb prints between the category
/// and this topic — "Science › **Astronomy** · 400 questions".
/// Empty when the topic sits directly under its category.
@override@JsonKey() final  String groupName;
/// Tint behind the tile's emoji plate, as `#RRGGBB`.
@override final  String plateColor;
@override@JsonKey() final  int questionCount;
/// Levels the player has finished, of [levelCount].
@override@JsonKey() final  int levelsCleared;
@override@JsonKey() final  int levelCount;
@override@JsonKey() final  int bestScore;
/// Stars earned across every level, of `levelCount * 3`.
@override@JsonKey() final  int starsEarned;
@override@JsonKey() final  bool isNew;
@override@JsonKey() final  bool isLocked;

/// Create a copy of Subcategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubcategoryCopyWith<_Subcategory> get copyWith => __$SubcategoryCopyWithImpl<_Subcategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubcategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subcategory&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.bestScore, bestScore) || other.bestScore == bestScore)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,name,emoji,groupName,plateColor,questionCount,levelsCleared,levelCount,bestScore,starsEarned,isNew,isLocked);

@override
String toString() {
  return 'Subcategory(id: $id, categoryId: $categoryId, name: $name, emoji: $emoji, groupName: $groupName, plateColor: $plateColor, questionCount: $questionCount, levelsCleared: $levelsCleared, levelCount: $levelCount, bestScore: $bestScore, starsEarned: $starsEarned, isNew: $isNew, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class _$SubcategoryCopyWith<$Res> implements $SubcategoryCopyWith<$Res> {
  factory _$SubcategoryCopyWith(_Subcategory value, $Res Function(_Subcategory) _then) = __$SubcategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String categoryId, String name, String emoji, String groupName, String plateColor, int questionCount, int levelsCleared, int levelCount, int bestScore, int starsEarned, bool isNew, bool isLocked
});




}
/// @nodoc
class __$SubcategoryCopyWithImpl<$Res>
    implements _$SubcategoryCopyWith<$Res> {
  __$SubcategoryCopyWithImpl(this._self, this._then);

  final _Subcategory _self;
  final $Res Function(_Subcategory) _then;

/// Create a copy of Subcategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? emoji = null,Object? groupName = null,Object? plateColor = null,Object? questionCount = null,Object? levelsCleared = null,Object? levelCount = null,Object? bestScore = null,Object? starsEarned = null,Object? isNew = null,Object? isLocked = null,}) {
  return _then(_Subcategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,levelCount: null == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int,bestScore: null == bestScore ? _self.bestScore : bestScore // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
