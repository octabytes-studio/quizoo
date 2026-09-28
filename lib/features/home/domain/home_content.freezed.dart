// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PopularQuiz {

 String get id;/// The topic tapping the card opens.
 String get subcategoryId; String get title; String get emoji;/// Start of the card's 150° gradient, as `#RRGGBB`.
 String get colorFrom;/// End of the card's gradient.
 String get colorTo;/// Plays this week, rendered compactly as "84.2k played".
 int get playedCount;/// Wears the raspberry "HOT" badge.
 bool get isHot;
/// Create a copy of PopularQuiz
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PopularQuizCopyWith<PopularQuiz> get copyWith => _$PopularQuizCopyWithImpl<PopularQuiz>(this as PopularQuiz, _$identity);

  /// Serializes this PopularQuiz to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PopularQuiz&&(identical(other.id, id) || other.id == id)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.colorFrom, colorFrom) || other.colorFrom == colorFrom)&&(identical(other.colorTo, colorTo) || other.colorTo == colorTo)&&(identical(other.playedCount, playedCount) || other.playedCount == playedCount)&&(identical(other.isHot, isHot) || other.isHot == isHot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subcategoryId,title,emoji,colorFrom,colorTo,playedCount,isHot);

@override
String toString() {
  return 'PopularQuiz(id: $id, subcategoryId: $subcategoryId, title: $title, emoji: $emoji, colorFrom: $colorFrom, colorTo: $colorTo, playedCount: $playedCount, isHot: $isHot)';
}


}

/// @nodoc
abstract mixin class $PopularQuizCopyWith<$Res>  {
  factory $PopularQuizCopyWith(PopularQuiz value, $Res Function(PopularQuiz) _then) = _$PopularQuizCopyWithImpl;
@useResult
$Res call({
 String id, String subcategoryId, String title, String emoji, String colorFrom, String colorTo, int playedCount, bool isHot
});




}
/// @nodoc
class _$PopularQuizCopyWithImpl<$Res>
    implements $PopularQuizCopyWith<$Res> {
  _$PopularQuizCopyWithImpl(this._self, this._then);

  final PopularQuiz _self;
  final $Res Function(PopularQuiz) _then;

/// Create a copy of PopularQuiz
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subcategoryId = null,Object? title = null,Object? emoji = null,Object? colorFrom = null,Object? colorTo = null,Object? playedCount = null,Object? isHot = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,colorFrom: null == colorFrom ? _self.colorFrom : colorFrom // ignore: cast_nullable_to_non_nullable
as String,colorTo: null == colorTo ? _self.colorTo : colorTo // ignore: cast_nullable_to_non_nullable
as String,playedCount: null == playedCount ? _self.playedCount : playedCount // ignore: cast_nullable_to_non_nullable
as int,isHot: null == isHot ? _self.isHot : isHot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PopularQuiz].
extension PopularQuizPatterns on PopularQuiz {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PopularQuiz value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PopularQuiz() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PopularQuiz value)  $default,){
final _that = this;
switch (_that) {
case _PopularQuiz():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PopularQuiz value)?  $default,){
final _that = this;
switch (_that) {
case _PopularQuiz() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subcategoryId,  String title,  String emoji,  String colorFrom,  String colorTo,  int playedCount,  bool isHot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PopularQuiz() when $default != null:
return $default(_that.id,_that.subcategoryId,_that.title,_that.emoji,_that.colorFrom,_that.colorTo,_that.playedCount,_that.isHot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subcategoryId,  String title,  String emoji,  String colorFrom,  String colorTo,  int playedCount,  bool isHot)  $default,) {final _that = this;
switch (_that) {
case _PopularQuiz():
return $default(_that.id,_that.subcategoryId,_that.title,_that.emoji,_that.colorFrom,_that.colorTo,_that.playedCount,_that.isHot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subcategoryId,  String title,  String emoji,  String colorFrom,  String colorTo,  int playedCount,  bool isHot)?  $default,) {final _that = this;
switch (_that) {
case _PopularQuiz() when $default != null:
return $default(_that.id,_that.subcategoryId,_that.title,_that.emoji,_that.colorFrom,_that.colorTo,_that.playedCount,_that.isHot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PopularQuiz implements PopularQuiz {
  const _PopularQuiz({required this.id, required this.subcategoryId, required this.title, required this.emoji, required this.colorFrom, required this.colorTo, this.playedCount = 0, this.isHot = false});
  factory _PopularQuiz.fromJson(Map<String, dynamic> json) => _$PopularQuizFromJson(json);

@override final  String id;
/// The topic tapping the card opens.
@override final  String subcategoryId;
@override final  String title;
@override final  String emoji;
/// Start of the card's 150° gradient, as `#RRGGBB`.
@override final  String colorFrom;
/// End of the card's gradient.
@override final  String colorTo;
/// Plays this week, rendered compactly as "84.2k played".
@override@JsonKey() final  int playedCount;
/// Wears the raspberry "HOT" badge.
@override@JsonKey() final  bool isHot;

/// Create a copy of PopularQuiz
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PopularQuizCopyWith<_PopularQuiz> get copyWith => __$PopularQuizCopyWithImpl<_PopularQuiz>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PopularQuizToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PopularQuiz&&(identical(other.id, id) || other.id == id)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.colorFrom, colorFrom) || other.colorFrom == colorFrom)&&(identical(other.colorTo, colorTo) || other.colorTo == colorTo)&&(identical(other.playedCount, playedCount) || other.playedCount == playedCount)&&(identical(other.isHot, isHot) || other.isHot == isHot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subcategoryId,title,emoji,colorFrom,colorTo,playedCount,isHot);

@override
String toString() {
  return 'PopularQuiz(id: $id, subcategoryId: $subcategoryId, title: $title, emoji: $emoji, colorFrom: $colorFrom, colorTo: $colorTo, playedCount: $playedCount, isHot: $isHot)';
}


}

/// @nodoc
abstract mixin class _$PopularQuizCopyWith<$Res> implements $PopularQuizCopyWith<$Res> {
  factory _$PopularQuizCopyWith(_PopularQuiz value, $Res Function(_PopularQuiz) _then) = __$PopularQuizCopyWithImpl;
@override @useResult
$Res call({
 String id, String subcategoryId, String title, String emoji, String colorFrom, String colorTo, int playedCount, bool isHot
});




}
/// @nodoc
class __$PopularQuizCopyWithImpl<$Res>
    implements _$PopularQuizCopyWith<$Res> {
  __$PopularQuizCopyWithImpl(this._self, this._then);

  final _PopularQuiz _self;
  final $Res Function(_PopularQuiz) _then;

/// Create a copy of PopularQuiz
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subcategoryId = null,Object? title = null,Object? emoji = null,Object? colorFrom = null,Object? colorTo = null,Object? playedCount = null,Object? isHot = null,}) {
  return _then(_PopularQuiz(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,colorFrom: null == colorFrom ? _self.colorFrom : colorFrom // ignore: cast_nullable_to_non_nullable
as String,colorTo: null == colorTo ? _self.colorTo : colorTo // ignore: cast_nullable_to_non_nullable
as String,playedCount: null == playedCount ? _self.playedCount : playedCount // ignore: cast_nullable_to_non_nullable
as int,isHot: null == isHot ? _self.isHot : isHot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ContinueEntry {

 String get subcategoryId; String get subcategoryName; String get emoji;/// Tint behind the emoji plate, as `#RRGGBB`.
 String get plateColor; int get levelNumber; int get points; int get livesLeft;
/// Create a copy of ContinueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContinueEntryCopyWith<ContinueEntry> get copyWith => _$ContinueEntryCopyWithImpl<ContinueEntry>(this as ContinueEntry, _$identity);

  /// Serializes this ContinueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContinueEntry&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.levelNumber, levelNumber) || other.levelNumber == levelNumber)&&(identical(other.points, points) || other.points == points)&&(identical(other.livesLeft, livesLeft) || other.livesLeft == livesLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subcategoryId,subcategoryName,emoji,plateColor,levelNumber,points,livesLeft);

@override
String toString() {
  return 'ContinueEntry(subcategoryId: $subcategoryId, subcategoryName: $subcategoryName, emoji: $emoji, plateColor: $plateColor, levelNumber: $levelNumber, points: $points, livesLeft: $livesLeft)';
}


}

/// @nodoc
abstract mixin class $ContinueEntryCopyWith<$Res>  {
  factory $ContinueEntryCopyWith(ContinueEntry value, $Res Function(ContinueEntry) _then) = _$ContinueEntryCopyWithImpl;
@useResult
$Res call({
 String subcategoryId, String subcategoryName, String emoji, String plateColor, int levelNumber, int points, int livesLeft
});




}
/// @nodoc
class _$ContinueEntryCopyWithImpl<$Res>
    implements $ContinueEntryCopyWith<$Res> {
  _$ContinueEntryCopyWithImpl(this._self, this._then);

  final ContinueEntry _self;
  final $Res Function(ContinueEntry) _then;

/// Create a copy of ContinueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subcategoryId = null,Object? subcategoryName = null,Object? emoji = null,Object? plateColor = null,Object? levelNumber = null,Object? points = null,Object? livesLeft = null,}) {
  return _then(_self.copyWith(
subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,subcategoryName: null == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,levelNumber: null == levelNumber ? _self.levelNumber : levelNumber // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,livesLeft: null == livesLeft ? _self.livesLeft : livesLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ContinueEntry].
extension ContinueEntryPatterns on ContinueEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContinueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContinueEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContinueEntry value)  $default,){
final _that = this;
switch (_that) {
case _ContinueEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContinueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ContinueEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subcategoryId,  String subcategoryName,  String emoji,  String plateColor,  int levelNumber,  int points,  int livesLeft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContinueEntry() when $default != null:
return $default(_that.subcategoryId,_that.subcategoryName,_that.emoji,_that.plateColor,_that.levelNumber,_that.points,_that.livesLeft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subcategoryId,  String subcategoryName,  String emoji,  String plateColor,  int levelNumber,  int points,  int livesLeft)  $default,) {final _that = this;
switch (_that) {
case _ContinueEntry():
return $default(_that.subcategoryId,_that.subcategoryName,_that.emoji,_that.plateColor,_that.levelNumber,_that.points,_that.livesLeft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subcategoryId,  String subcategoryName,  String emoji,  String plateColor,  int levelNumber,  int points,  int livesLeft)?  $default,) {final _that = this;
switch (_that) {
case _ContinueEntry() when $default != null:
return $default(_that.subcategoryId,_that.subcategoryName,_that.emoji,_that.plateColor,_that.levelNumber,_that.points,_that.livesLeft);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContinueEntry implements ContinueEntry {
  const _ContinueEntry({required this.subcategoryId, required this.subcategoryName, required this.emoji, required this.plateColor, required this.levelNumber, this.points = 0, this.livesLeft = 3});
  factory _ContinueEntry.fromJson(Map<String, dynamic> json) => _$ContinueEntryFromJson(json);

@override final  String subcategoryId;
@override final  String subcategoryName;
@override final  String emoji;
/// Tint behind the emoji plate, as `#RRGGBB`.
@override final  String plateColor;
@override final  int levelNumber;
@override@JsonKey() final  int points;
@override@JsonKey() final  int livesLeft;

/// Create a copy of ContinueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContinueEntryCopyWith<_ContinueEntry> get copyWith => __$ContinueEntryCopyWithImpl<_ContinueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContinueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContinueEntry&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.levelNumber, levelNumber) || other.levelNumber == levelNumber)&&(identical(other.points, points) || other.points == points)&&(identical(other.livesLeft, livesLeft) || other.livesLeft == livesLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subcategoryId,subcategoryName,emoji,plateColor,levelNumber,points,livesLeft);

@override
String toString() {
  return 'ContinueEntry(subcategoryId: $subcategoryId, subcategoryName: $subcategoryName, emoji: $emoji, plateColor: $plateColor, levelNumber: $levelNumber, points: $points, livesLeft: $livesLeft)';
}


}

/// @nodoc
abstract mixin class _$ContinueEntryCopyWith<$Res> implements $ContinueEntryCopyWith<$Res> {
  factory _$ContinueEntryCopyWith(_ContinueEntry value, $Res Function(_ContinueEntry) _then) = __$ContinueEntryCopyWithImpl;
@override @useResult
$Res call({
 String subcategoryId, String subcategoryName, String emoji, String plateColor, int levelNumber, int points, int livesLeft
});




}
/// @nodoc
class __$ContinueEntryCopyWithImpl<$Res>
    implements _$ContinueEntryCopyWith<$Res> {
  __$ContinueEntryCopyWithImpl(this._self, this._then);

  final _ContinueEntry _self;
  final $Res Function(_ContinueEntry) _then;

/// Create a copy of ContinueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subcategoryId = null,Object? subcategoryName = null,Object? emoji = null,Object? plateColor = null,Object? levelNumber = null,Object? points = null,Object? livesLeft = null,}) {
  return _then(_ContinueEntry(
subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,subcategoryName: null == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,levelNumber: null == levelNumber ? _self.levelNumber : levelNumber // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,livesLeft: null == livesLeft ? _self.livesLeft : livesLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DailyChallengePreview {

 int get questionCount;/// Minutes until today's challenge closes, so the banner can render
/// "ends in 4h 12m" without holding a live clock.
 int get minutesRemaining;
/// Create a copy of DailyChallengePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyChallengePreviewCopyWith<DailyChallengePreview> get copyWith => _$DailyChallengePreviewCopyWithImpl<DailyChallengePreview>(this as DailyChallengePreview, _$identity);

  /// Serializes this DailyChallengePreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyChallengePreview&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.minutesRemaining, minutesRemaining) || other.minutesRemaining == minutesRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionCount,minutesRemaining);

@override
String toString() {
  return 'DailyChallengePreview(questionCount: $questionCount, minutesRemaining: $minutesRemaining)';
}


}

/// @nodoc
abstract mixin class $DailyChallengePreviewCopyWith<$Res>  {
  factory $DailyChallengePreviewCopyWith(DailyChallengePreview value, $Res Function(DailyChallengePreview) _then) = _$DailyChallengePreviewCopyWithImpl;
@useResult
$Res call({
 int questionCount, int minutesRemaining
});




}
/// @nodoc
class _$DailyChallengePreviewCopyWithImpl<$Res>
    implements $DailyChallengePreviewCopyWith<$Res> {
  _$DailyChallengePreviewCopyWithImpl(this._self, this._then);

  final DailyChallengePreview _self;
  final $Res Function(DailyChallengePreview) _then;

/// Create a copy of DailyChallengePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionCount = null,Object? minutesRemaining = null,}) {
  return _then(_self.copyWith(
questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,minutesRemaining: null == minutesRemaining ? _self.minutesRemaining : minutesRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyChallengePreview].
extension DailyChallengePreviewPatterns on DailyChallengePreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyChallengePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyChallengePreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyChallengePreview value)  $default,){
final _that = this;
switch (_that) {
case _DailyChallengePreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyChallengePreview value)?  $default,){
final _that = this;
switch (_that) {
case _DailyChallengePreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int questionCount,  int minutesRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyChallengePreview() when $default != null:
return $default(_that.questionCount,_that.minutesRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int questionCount,  int minutesRemaining)  $default,) {final _that = this;
switch (_that) {
case _DailyChallengePreview():
return $default(_that.questionCount,_that.minutesRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int questionCount,  int minutesRemaining)?  $default,) {final _that = this;
switch (_that) {
case _DailyChallengePreview() when $default != null:
return $default(_that.questionCount,_that.minutesRemaining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyChallengePreview extends DailyChallengePreview {
  const _DailyChallengePreview({this.questionCount = 10, this.minutesRemaining = 0}): super._();
  factory _DailyChallengePreview.fromJson(Map<String, dynamic> json) => _$DailyChallengePreviewFromJson(json);

@override@JsonKey() final  int questionCount;
/// Minutes until today's challenge closes, so the banner can render
/// "ends in 4h 12m" without holding a live clock.
@override@JsonKey() final  int minutesRemaining;

/// Create a copy of DailyChallengePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyChallengePreviewCopyWith<_DailyChallengePreview> get copyWith => __$DailyChallengePreviewCopyWithImpl<_DailyChallengePreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyChallengePreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyChallengePreview&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.minutesRemaining, minutesRemaining) || other.minutesRemaining == minutesRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionCount,minutesRemaining);

@override
String toString() {
  return 'DailyChallengePreview(questionCount: $questionCount, minutesRemaining: $minutesRemaining)';
}


}

/// @nodoc
abstract mixin class _$DailyChallengePreviewCopyWith<$Res> implements $DailyChallengePreviewCopyWith<$Res> {
  factory _$DailyChallengePreviewCopyWith(_DailyChallengePreview value, $Res Function(_DailyChallengePreview) _then) = __$DailyChallengePreviewCopyWithImpl;
@override @useResult
$Res call({
 int questionCount, int minutesRemaining
});




}
/// @nodoc
class __$DailyChallengePreviewCopyWithImpl<$Res>
    implements _$DailyChallengePreviewCopyWith<$Res> {
  __$DailyChallengePreviewCopyWithImpl(this._self, this._then);

  final _DailyChallengePreview _self;
  final $Res Function(_DailyChallengePreview) _then;

/// Create a copy of DailyChallengePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionCount = null,Object? minutesRemaining = null,}) {
  return _then(_DailyChallengePreview(
questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,minutesRemaining: null == minutesRemaining ? _self.minutesRemaining : minutesRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HomeContent {

 List<Category> get categories; List<Subcategory> get subcategories; List<PopularQuiz> get popular; ContinueEntry? get continueEntry; DailyChallengePreview? get daily;/// Null for a guest, which is what removes the wallet pills from the top
/// bar — the bible is explicit that a guest has earned nothing yet.
 PlayerCurrency? get currency;/// The signed-in player's real `profiles.streak_days`/`player_level`
/// (plan 019) — 0 for a guest, and 0 in `_HomeSkeleton`'s pre-fetch
/// flash, which has no [HomeContent] to read yet.
 int get dayStreak; int get playerLevel;
/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeContentCopyWith<HomeContent> get copyWith => _$HomeContentCopyWithImpl<HomeContent>(this as HomeContent, _$identity);

  /// Serializes this HomeContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeContent&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.subcategories, subcategories)&&const DeepCollectionEquality().equals(other.popular, popular)&&(identical(other.continueEntry, continueEntry) || other.continueEntry == continueEntry)&&(identical(other.daily, daily) || other.daily == daily)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.dayStreak, dayStreak) || other.dayStreak == dayStreak)&&(identical(other.playerLevel, playerLevel) || other.playerLevel == playerLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(subcategories),const DeepCollectionEquality().hash(popular),continueEntry,daily,currency,dayStreak,playerLevel);

@override
String toString() {
  return 'HomeContent(categories: $categories, subcategories: $subcategories, popular: $popular, continueEntry: $continueEntry, daily: $daily, currency: $currency, dayStreak: $dayStreak, playerLevel: $playerLevel)';
}


}

/// @nodoc
abstract mixin class $HomeContentCopyWith<$Res>  {
  factory $HomeContentCopyWith(HomeContent value, $Res Function(HomeContent) _then) = _$HomeContentCopyWithImpl;
@useResult
$Res call({
 List<Category> categories, List<Subcategory> subcategories, List<PopularQuiz> popular, ContinueEntry? continueEntry, DailyChallengePreview? daily, PlayerCurrency? currency, int dayStreak, int playerLevel
});


$ContinueEntryCopyWith<$Res>? get continueEntry;$DailyChallengePreviewCopyWith<$Res>? get daily;$PlayerCurrencyCopyWith<$Res>? get currency;

}
/// @nodoc
class _$HomeContentCopyWithImpl<$Res>
    implements $HomeContentCopyWith<$Res> {
  _$HomeContentCopyWithImpl(this._self, this._then);

  final HomeContent _self;
  final $Res Function(HomeContent) _then;

/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? subcategories = null,Object? popular = null,Object? continueEntry = freezed,Object? daily = freezed,Object? currency = freezed,Object? dayStreak = null,Object? playerLevel = null,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,subcategories: null == subcategories ? _self.subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,popular: null == popular ? _self.popular : popular // ignore: cast_nullable_to_non_nullable
as List<PopularQuiz>,continueEntry: freezed == continueEntry ? _self.continueEntry : continueEntry // ignore: cast_nullable_to_non_nullable
as ContinueEntry?,daily: freezed == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as DailyChallengePreview?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as PlayerCurrency?,dayStreak: null == dayStreak ? _self.dayStreak : dayStreak // ignore: cast_nullable_to_non_nullable
as int,playerLevel: null == playerLevel ? _self.playerLevel : playerLevel // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContinueEntryCopyWith<$Res>? get continueEntry {
    if (_self.continueEntry == null) {
    return null;
  }

  return $ContinueEntryCopyWith<$Res>(_self.continueEntry!, (value) {
    return _then(_self.copyWith(continueEntry: value));
  });
}/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyChallengePreviewCopyWith<$Res>? get daily {
    if (_self.daily == null) {
    return null;
  }

  return $DailyChallengePreviewCopyWith<$Res>(_self.daily!, (value) {
    return _then(_self.copyWith(daily: value));
  });
}/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerCurrencyCopyWith<$Res>? get currency {
    if (_self.currency == null) {
    return null;
  }

  return $PlayerCurrencyCopyWith<$Res>(_self.currency!, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeContent].
extension HomeContentPatterns on HomeContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeContent value)  $default,){
final _that = this;
switch (_that) {
case _HomeContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeContent value)?  $default,){
final _that = this;
switch (_that) {
case _HomeContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Category> categories,  List<Subcategory> subcategories,  List<PopularQuiz> popular,  ContinueEntry? continueEntry,  DailyChallengePreview? daily,  PlayerCurrency? currency,  int dayStreak,  int playerLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeContent() when $default != null:
return $default(_that.categories,_that.subcategories,_that.popular,_that.continueEntry,_that.daily,_that.currency,_that.dayStreak,_that.playerLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Category> categories,  List<Subcategory> subcategories,  List<PopularQuiz> popular,  ContinueEntry? continueEntry,  DailyChallengePreview? daily,  PlayerCurrency? currency,  int dayStreak,  int playerLevel)  $default,) {final _that = this;
switch (_that) {
case _HomeContent():
return $default(_that.categories,_that.subcategories,_that.popular,_that.continueEntry,_that.daily,_that.currency,_that.dayStreak,_that.playerLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Category> categories,  List<Subcategory> subcategories,  List<PopularQuiz> popular,  ContinueEntry? continueEntry,  DailyChallengePreview? daily,  PlayerCurrency? currency,  int dayStreak,  int playerLevel)?  $default,) {final _that = this;
switch (_that) {
case _HomeContent() when $default != null:
return $default(_that.categories,_that.subcategories,_that.popular,_that.continueEntry,_that.daily,_that.currency,_that.dayStreak,_that.playerLevel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeContent extends HomeContent {
  const _HomeContent({final  List<Category> categories = const [], final  List<Subcategory> subcategories = const [], final  List<PopularQuiz> popular = const [], this.continueEntry, this.daily, this.currency, this.dayStreak = 0, this.playerLevel = 0}): _categories = categories,_subcategories = subcategories,_popular = popular,super._();
  factory _HomeContent.fromJson(Map<String, dynamic> json) => _$HomeContentFromJson(json);

 final  List<Category> _categories;
@override@JsonKey() List<Category> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<Subcategory> _subcategories;
@override@JsonKey() List<Subcategory> get subcategories {
  if (_subcategories is EqualUnmodifiableListView) return _subcategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subcategories);
}

 final  List<PopularQuiz> _popular;
@override@JsonKey() List<PopularQuiz> get popular {
  if (_popular is EqualUnmodifiableListView) return _popular;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_popular);
}

@override final  ContinueEntry? continueEntry;
@override final  DailyChallengePreview? daily;
/// Null for a guest, which is what removes the wallet pills from the top
/// bar — the bible is explicit that a guest has earned nothing yet.
@override final  PlayerCurrency? currency;
/// The signed-in player's real `profiles.streak_days`/`player_level`
/// (plan 019) — 0 for a guest, and 0 in `_HomeSkeleton`'s pre-fetch
/// flash, which has no [HomeContent] to read yet.
@override@JsonKey() final  int dayStreak;
@override@JsonKey() final  int playerLevel;

/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeContentCopyWith<_HomeContent> get copyWith => __$HomeContentCopyWithImpl<_HomeContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeContent&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._subcategories, _subcategories)&&const DeepCollectionEquality().equals(other._popular, _popular)&&(identical(other.continueEntry, continueEntry) || other.continueEntry == continueEntry)&&(identical(other.daily, daily) || other.daily == daily)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.dayStreak, dayStreak) || other.dayStreak == dayStreak)&&(identical(other.playerLevel, playerLevel) || other.playerLevel == playerLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_subcategories),const DeepCollectionEquality().hash(_popular),continueEntry,daily,currency,dayStreak,playerLevel);

@override
String toString() {
  return 'HomeContent(categories: $categories, subcategories: $subcategories, popular: $popular, continueEntry: $continueEntry, daily: $daily, currency: $currency, dayStreak: $dayStreak, playerLevel: $playerLevel)';
}


}

/// @nodoc
abstract mixin class _$HomeContentCopyWith<$Res> implements $HomeContentCopyWith<$Res> {
  factory _$HomeContentCopyWith(_HomeContent value, $Res Function(_HomeContent) _then) = __$HomeContentCopyWithImpl;
@override @useResult
$Res call({
 List<Category> categories, List<Subcategory> subcategories, List<PopularQuiz> popular, ContinueEntry? continueEntry, DailyChallengePreview? daily, PlayerCurrency? currency, int dayStreak, int playerLevel
});


@override $ContinueEntryCopyWith<$Res>? get continueEntry;@override $DailyChallengePreviewCopyWith<$Res>? get daily;@override $PlayerCurrencyCopyWith<$Res>? get currency;

}
/// @nodoc
class __$HomeContentCopyWithImpl<$Res>
    implements _$HomeContentCopyWith<$Res> {
  __$HomeContentCopyWithImpl(this._self, this._then);

  final _HomeContent _self;
  final $Res Function(_HomeContent) _then;

/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? subcategories = null,Object? popular = null,Object? continueEntry = freezed,Object? daily = freezed,Object? currency = freezed,Object? dayStreak = null,Object? playerLevel = null,}) {
  return _then(_HomeContent(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,subcategories: null == subcategories ? _self._subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,popular: null == popular ? _self._popular : popular // ignore: cast_nullable_to_non_nullable
as List<PopularQuiz>,continueEntry: freezed == continueEntry ? _self.continueEntry : continueEntry // ignore: cast_nullable_to_non_nullable
as ContinueEntry?,daily: freezed == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as DailyChallengePreview?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as PlayerCurrency?,dayStreak: null == dayStreak ? _self.dayStreak : dayStreak // ignore: cast_nullable_to_non_nullable
as int,playerLevel: null == playerLevel ? _self.playerLevel : playerLevel // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContinueEntryCopyWith<$Res>? get continueEntry {
    if (_self.continueEntry == null) {
    return null;
  }

  return $ContinueEntryCopyWith<$Res>(_self.continueEntry!, (value) {
    return _then(_self.copyWith(continueEntry: value));
  });
}/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyChallengePreviewCopyWith<$Res>? get daily {
    if (_self.daily == null) {
    return null;
  }

  return $DailyChallengePreviewCopyWith<$Res>(_self.daily!, (value) {
    return _then(_self.copyWith(daily: value));
  });
}/// Create a copy of HomeContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerCurrencyCopyWith<$Res>? get currency {
    if (_self.currency == null) {
    return null;
  }

  return $PlayerCurrencyCopyWith<$Res>(_self.currency!, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}

// dart format on
