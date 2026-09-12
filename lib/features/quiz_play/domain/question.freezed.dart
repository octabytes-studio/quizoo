// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Question {

 String get id; String get subcategoryId;/// 1–5, which is what §19's level table draws its pool from.
 int get difficulty; String get text;/// Four options, or three when [hasImage] — the media plate takes the
/// room the fourth would need.
 List<String> get options; int get correctIndex;/// The one-sentence explanation shown on **every** verdict, right or
/// wrong. The bible calls it "the single feature that turns a quiz into
/// learning", so it is required, not optional.
 String get explanation;/// Renders the 132px media plate above the question box (S-15).
 bool get hasImage;/// The emoji standing in for real artwork.
///
/// There is no image CDN in this phase, so an "image question" is an
/// emoji on a gradient plate. [imageAsset] is the hook a real asset drops
/// into, and the plate falls back to the text-only layout when it is
/// missing or fails to decode.
 String? get imageEmoji; String? get imageAsset;/// Start of the media plate's gradient, as `#RRGGBB`.
 String get imageColorFrom; String get imageColorTo;/// True when this question should skip TTS read-aloud (e.g. it leans on
/// a figure/image the voice can't describe). Sourced from
/// `questions.tts_excluded`.
 bool get ttsExcluded;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.id, id) || other.id == id)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.correctIndex, correctIndex) || other.correctIndex == correctIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.hasImage, hasImage) || other.hasImage == hasImage)&&(identical(other.imageEmoji, imageEmoji) || other.imageEmoji == imageEmoji)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.imageColorFrom, imageColorFrom) || other.imageColorFrom == imageColorFrom)&&(identical(other.imageColorTo, imageColorTo) || other.imageColorTo == imageColorTo)&&(identical(other.ttsExcluded, ttsExcluded) || other.ttsExcluded == ttsExcluded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subcategoryId,difficulty,text,const DeepCollectionEquality().hash(options),correctIndex,explanation,hasImage,imageEmoji,imageAsset,imageColorFrom,imageColorTo,ttsExcluded);

@override
String toString() {
  return 'Question(id: $id, subcategoryId: $subcategoryId, difficulty: $difficulty, text: $text, options: $options, correctIndex: $correctIndex, explanation: $explanation, hasImage: $hasImage, imageEmoji: $imageEmoji, imageAsset: $imageAsset, imageColorFrom: $imageColorFrom, imageColorTo: $imageColorTo, ttsExcluded: $ttsExcluded)';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 String id, String subcategoryId, int difficulty, String text, List<String> options, int correctIndex, String explanation, bool hasImage, String? imageEmoji, String? imageAsset, String imageColorFrom, String imageColorTo, bool ttsExcluded
});




}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subcategoryId = null,Object? difficulty = null,Object? text = null,Object? options = null,Object? correctIndex = null,Object? explanation = null,Object? hasImage = null,Object? imageEmoji = freezed,Object? imageAsset = freezed,Object? imageColorFrom = null,Object? imageColorTo = null,Object? ttsExcluded = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,correctIndex: null == correctIndex ? _self.correctIndex : correctIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,hasImage: null == hasImage ? _self.hasImage : hasImage // ignore: cast_nullable_to_non_nullable
as bool,imageEmoji: freezed == imageEmoji ? _self.imageEmoji : imageEmoji // ignore: cast_nullable_to_non_nullable
as String?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,imageColorFrom: null == imageColorFrom ? _self.imageColorFrom : imageColorFrom // ignore: cast_nullable_to_non_nullable
as String,imageColorTo: null == imageColorTo ? _self.imageColorTo : imageColorTo // ignore: cast_nullable_to_non_nullable
as String,ttsExcluded: null == ttsExcluded ? _self.ttsExcluded : ttsExcluded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Question].
extension QuestionPatterns on Question {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Question value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Question value)  $default,){
final _that = this;
switch (_that) {
case _Question():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Question value)?  $default,){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subcategoryId,  int difficulty,  String text,  List<String> options,  int correctIndex,  String explanation,  bool hasImage,  String? imageEmoji,  String? imageAsset,  String imageColorFrom,  String imageColorTo,  bool ttsExcluded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.subcategoryId,_that.difficulty,_that.text,_that.options,_that.correctIndex,_that.explanation,_that.hasImage,_that.imageEmoji,_that.imageAsset,_that.imageColorFrom,_that.imageColorTo,_that.ttsExcluded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subcategoryId,  int difficulty,  String text,  List<String> options,  int correctIndex,  String explanation,  bool hasImage,  String? imageEmoji,  String? imageAsset,  String imageColorFrom,  String imageColorTo,  bool ttsExcluded)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.id,_that.subcategoryId,_that.difficulty,_that.text,_that.options,_that.correctIndex,_that.explanation,_that.hasImage,_that.imageEmoji,_that.imageAsset,_that.imageColorFrom,_that.imageColorTo,_that.ttsExcluded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subcategoryId,  int difficulty,  String text,  List<String> options,  int correctIndex,  String explanation,  bool hasImage,  String? imageEmoji,  String? imageAsset,  String imageColorFrom,  String imageColorTo,  bool ttsExcluded)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.subcategoryId,_that.difficulty,_that.text,_that.options,_that.correctIndex,_that.explanation,_that.hasImage,_that.imageEmoji,_that.imageAsset,_that.imageColorFrom,_that.imageColorTo,_that.ttsExcluded);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question extends Question {
  const _Question({required this.id, required this.subcategoryId, required this.difficulty, required this.text, required final  List<String> options, required this.correctIndex, required this.explanation, this.hasImage = false, this.imageEmoji, this.imageAsset, this.imageColorFrom = '#2BB3FF', this.imageColorTo = '#7B4DFF', this.ttsExcluded = false}): _options = options,super._();
  factory _Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

@override final  String id;
@override final  String subcategoryId;
/// 1–5, which is what §19's level table draws its pool from.
@override final  int difficulty;
@override final  String text;
/// Four options, or three when [hasImage] — the media plate takes the
/// room the fourth would need.
 final  List<String> _options;
/// Four options, or three when [hasImage] — the media plate takes the
/// room the fourth would need.
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override final  int correctIndex;
/// The one-sentence explanation shown on **every** verdict, right or
/// wrong. The bible calls it "the single feature that turns a quiz into
/// learning", so it is required, not optional.
@override final  String explanation;
/// Renders the 132px media plate above the question box (S-15).
@override@JsonKey() final  bool hasImage;
/// The emoji standing in for real artwork.
///
/// There is no image CDN in this phase, so an "image question" is an
/// emoji on a gradient plate. [imageAsset] is the hook a real asset drops
/// into, and the plate falls back to the text-only layout when it is
/// missing or fails to decode.
@override final  String? imageEmoji;
@override final  String? imageAsset;
/// Start of the media plate's gradient, as `#RRGGBB`.
@override@JsonKey() final  String imageColorFrom;
@override@JsonKey() final  String imageColorTo;
/// True when this question should skip TTS read-aloud (e.g. it leans on
/// a figure/image the voice can't describe). Sourced from
/// `questions.tts_excluded`.
@override@JsonKey() final  bool ttsExcluded;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCopyWith<_Question> get copyWith => __$QuestionCopyWithImpl<_Question>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.id, id) || other.id == id)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.correctIndex, correctIndex) || other.correctIndex == correctIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.hasImage, hasImage) || other.hasImage == hasImage)&&(identical(other.imageEmoji, imageEmoji) || other.imageEmoji == imageEmoji)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.imageColorFrom, imageColorFrom) || other.imageColorFrom == imageColorFrom)&&(identical(other.imageColorTo, imageColorTo) || other.imageColorTo == imageColorTo)&&(identical(other.ttsExcluded, ttsExcluded) || other.ttsExcluded == ttsExcluded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subcategoryId,difficulty,text,const DeepCollectionEquality().hash(_options),correctIndex,explanation,hasImage,imageEmoji,imageAsset,imageColorFrom,imageColorTo,ttsExcluded);

@override
String toString() {
  return 'Question(id: $id, subcategoryId: $subcategoryId, difficulty: $difficulty, text: $text, options: $options, correctIndex: $correctIndex, explanation: $explanation, hasImage: $hasImage, imageEmoji: $imageEmoji, imageAsset: $imageAsset, imageColorFrom: $imageColorFrom, imageColorTo: $imageColorTo, ttsExcluded: $ttsExcluded)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String subcategoryId, int difficulty, String text, List<String> options, int correctIndex, String explanation, bool hasImage, String? imageEmoji, String? imageAsset, String imageColorFrom, String imageColorTo, bool ttsExcluded
});




}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subcategoryId = null,Object? difficulty = null,Object? text = null,Object? options = null,Object? correctIndex = null,Object? explanation = null,Object? hasImage = null,Object? imageEmoji = freezed,Object? imageAsset = freezed,Object? imageColorFrom = null,Object? imageColorTo = null,Object? ttsExcluded = null,}) {
  return _then(_Question(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,correctIndex: null == correctIndex ? _self.correctIndex : correctIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,hasImage: null == hasImage ? _self.hasImage : hasImage // ignore: cast_nullable_to_non_nullable
as bool,imageEmoji: freezed == imageEmoji ? _self.imageEmoji : imageEmoji // ignore: cast_nullable_to_non_nullable
as String?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,imageColorFrom: null == imageColorFrom ? _self.imageColorFrom : imageColorFrom // ignore: cast_nullable_to_non_nullable
as String,imageColorTo: null == imageColorTo ? _self.imageColorTo : imageColorTo // ignore: cast_nullable_to_non_nullable
as String,ttsExcluded: null == ttsExcluded ? _self.ttsExcluded : ttsExcluded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
