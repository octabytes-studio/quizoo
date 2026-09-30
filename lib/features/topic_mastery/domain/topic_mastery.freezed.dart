// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic_mastery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopicMastery {

 String get categoryId; String get subcategoryId; String get topicName; String get emoji;/// The topic tile's plate tint, as `#RRGGBB`.
 String get plateColor; int get levelsCleared;/// The ladder total (30) at the time this was fetched.
 int get levelCount; int get starsEarned;/// Levels cleared with all three stars.
 int get perfectLevels;/// Sum of `level_progress.best_score` across every cleared level.
 int get totalScore;/// In ladder order (Easy → Medium → Hard).
 List<TierMastery> get tiers;/// `min(level_attempts.created_at)` for this topic. Null if there is no
/// attempt row (progress written some other way).
 DateTime? get startedAt;/// `level_progress.completed_at` of the final level.
 DateTime? get masteredAt;
/// Create a copy of TopicMastery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicMasteryCopyWith<TopicMastery> get copyWith => _$TopicMasteryCopyWithImpl<TopicMastery>(this as TopicMastery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopicMastery&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.topicName, topicName) || other.topicName == topicName)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.perfectLevels, perfectLevels) || other.perfectLevels == perfectLevels)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&const DeepCollectionEquality().equals(other.tiers, tiers)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.masteredAt, masteredAt) || other.masteredAt == masteredAt));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,subcategoryId,topicName,emoji,plateColor,levelsCleared,levelCount,starsEarned,perfectLevels,totalScore,const DeepCollectionEquality().hash(tiers),startedAt,masteredAt);

@override
String toString() {
  return 'TopicMastery(categoryId: $categoryId, subcategoryId: $subcategoryId, topicName: $topicName, emoji: $emoji, plateColor: $plateColor, levelsCleared: $levelsCleared, levelCount: $levelCount, starsEarned: $starsEarned, perfectLevels: $perfectLevels, totalScore: $totalScore, tiers: $tiers, startedAt: $startedAt, masteredAt: $masteredAt)';
}


}

/// @nodoc
abstract mixin class $TopicMasteryCopyWith<$Res>  {
  factory $TopicMasteryCopyWith(TopicMastery value, $Res Function(TopicMastery) _then) = _$TopicMasteryCopyWithImpl;
@useResult
$Res call({
 String categoryId, String subcategoryId, String topicName, String emoji, String plateColor, int levelsCleared, int levelCount, int starsEarned, int perfectLevels, int totalScore, List<TierMastery> tiers, DateTime? startedAt, DateTime? masteredAt
});




}
/// @nodoc
class _$TopicMasteryCopyWithImpl<$Res>
    implements $TopicMasteryCopyWith<$Res> {
  _$TopicMasteryCopyWithImpl(this._self, this._then);

  final TopicMastery _self;
  final $Res Function(TopicMastery) _then;

/// Create a copy of TopicMastery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? subcategoryId = null,Object? topicName = null,Object? emoji = null,Object? plateColor = null,Object? levelsCleared = null,Object? levelCount = null,Object? starsEarned = null,Object? perfectLevels = null,Object? totalScore = null,Object? tiers = null,Object? startedAt = freezed,Object? masteredAt = freezed,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,topicName: null == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,levelCount: null == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,perfectLevels: null == perfectLevels ? _self.perfectLevels : perfectLevels // ignore: cast_nullable_to_non_nullable
as int,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,tiers: null == tiers ? _self.tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<TierMastery>,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,masteredAt: freezed == masteredAt ? _self.masteredAt : masteredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TopicMastery].
extension TopicMasteryPatterns on TopicMastery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopicMastery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopicMastery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopicMastery value)  $default,){
final _that = this;
switch (_that) {
case _TopicMastery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopicMastery value)?  $default,){
final _that = this;
switch (_that) {
case _TopicMastery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String subcategoryId,  String topicName,  String emoji,  String plateColor,  int levelsCleared,  int levelCount,  int starsEarned,  int perfectLevels,  int totalScore,  List<TierMastery> tiers,  DateTime? startedAt,  DateTime? masteredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopicMastery() when $default != null:
return $default(_that.categoryId,_that.subcategoryId,_that.topicName,_that.emoji,_that.plateColor,_that.levelsCleared,_that.levelCount,_that.starsEarned,_that.perfectLevels,_that.totalScore,_that.tiers,_that.startedAt,_that.masteredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String subcategoryId,  String topicName,  String emoji,  String plateColor,  int levelsCleared,  int levelCount,  int starsEarned,  int perfectLevels,  int totalScore,  List<TierMastery> tiers,  DateTime? startedAt,  DateTime? masteredAt)  $default,) {final _that = this;
switch (_that) {
case _TopicMastery():
return $default(_that.categoryId,_that.subcategoryId,_that.topicName,_that.emoji,_that.plateColor,_that.levelsCleared,_that.levelCount,_that.starsEarned,_that.perfectLevels,_that.totalScore,_that.tiers,_that.startedAt,_that.masteredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String subcategoryId,  String topicName,  String emoji,  String plateColor,  int levelsCleared,  int levelCount,  int starsEarned,  int perfectLevels,  int totalScore,  List<TierMastery> tiers,  DateTime? startedAt,  DateTime? masteredAt)?  $default,) {final _that = this;
switch (_that) {
case _TopicMastery() when $default != null:
return $default(_that.categoryId,_that.subcategoryId,_that.topicName,_that.emoji,_that.plateColor,_that.levelsCleared,_that.levelCount,_that.starsEarned,_that.perfectLevels,_that.totalScore,_that.tiers,_that.startedAt,_that.masteredAt);case _:
  return null;

}
}

}

/// @nodoc


class _TopicMastery extends TopicMastery {
  const _TopicMastery({required this.categoryId, required this.subcategoryId, required this.topicName, required this.emoji, required this.plateColor, required this.levelsCleared, required this.levelCount, required this.starsEarned, required this.perfectLevels, required this.totalScore, required final  List<TierMastery> tiers, this.startedAt, this.masteredAt}): _tiers = tiers,super._();
  

@override final  String categoryId;
@override final  String subcategoryId;
@override final  String topicName;
@override final  String emoji;
/// The topic tile's plate tint, as `#RRGGBB`.
@override final  String plateColor;
@override final  int levelsCleared;
/// The ladder total (30) at the time this was fetched.
@override final  int levelCount;
@override final  int starsEarned;
/// Levels cleared with all three stars.
@override final  int perfectLevels;
/// Sum of `level_progress.best_score` across every cleared level.
@override final  int totalScore;
/// In ladder order (Easy → Medium → Hard).
 final  List<TierMastery> _tiers;
/// In ladder order (Easy → Medium → Hard).
@override List<TierMastery> get tiers {
  if (_tiers is EqualUnmodifiableListView) return _tiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiers);
}

/// `min(level_attempts.created_at)` for this topic. Null if there is no
/// attempt row (progress written some other way).
@override final  DateTime? startedAt;
/// `level_progress.completed_at` of the final level.
@override final  DateTime? masteredAt;

/// Create a copy of TopicMastery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicMasteryCopyWith<_TopicMastery> get copyWith => __$TopicMasteryCopyWithImpl<_TopicMastery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopicMastery&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.topicName, topicName) || other.topicName == topicName)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.perfectLevels, perfectLevels) || other.perfectLevels == perfectLevels)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&const DeepCollectionEquality().equals(other._tiers, _tiers)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.masteredAt, masteredAt) || other.masteredAt == masteredAt));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,subcategoryId,topicName,emoji,plateColor,levelsCleared,levelCount,starsEarned,perfectLevels,totalScore,const DeepCollectionEquality().hash(_tiers),startedAt,masteredAt);

@override
String toString() {
  return 'TopicMastery(categoryId: $categoryId, subcategoryId: $subcategoryId, topicName: $topicName, emoji: $emoji, plateColor: $plateColor, levelsCleared: $levelsCleared, levelCount: $levelCount, starsEarned: $starsEarned, perfectLevels: $perfectLevels, totalScore: $totalScore, tiers: $tiers, startedAt: $startedAt, masteredAt: $masteredAt)';
}


}

/// @nodoc
abstract mixin class _$TopicMasteryCopyWith<$Res> implements $TopicMasteryCopyWith<$Res> {
  factory _$TopicMasteryCopyWith(_TopicMastery value, $Res Function(_TopicMastery) _then) = __$TopicMasteryCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String subcategoryId, String topicName, String emoji, String plateColor, int levelsCleared, int levelCount, int starsEarned, int perfectLevels, int totalScore, List<TierMastery> tiers, DateTime? startedAt, DateTime? masteredAt
});




}
/// @nodoc
class __$TopicMasteryCopyWithImpl<$Res>
    implements _$TopicMasteryCopyWith<$Res> {
  __$TopicMasteryCopyWithImpl(this._self, this._then);

  final _TopicMastery _self;
  final $Res Function(_TopicMastery) _then;

/// Create a copy of TopicMastery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? subcategoryId = null,Object? topicName = null,Object? emoji = null,Object? plateColor = null,Object? levelsCleared = null,Object? levelCount = null,Object? starsEarned = null,Object? perfectLevels = null,Object? totalScore = null,Object? tiers = null,Object? startedAt = freezed,Object? masteredAt = freezed,}) {
  return _then(_TopicMastery(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,topicName: null == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,levelCount: null == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,perfectLevels: null == perfectLevels ? _self.perfectLevels : perfectLevels // ignore: cast_nullable_to_non_nullable
as int,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,tiers: null == tiers ? _self._tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<TierMastery>,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,masteredAt: freezed == masteredAt ? _self.masteredAt : masteredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
