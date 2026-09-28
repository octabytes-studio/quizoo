// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelQuestion {

@JsonKey(name: 'prompt') String get text; List<String> get options; String get kind; String? get mediaUrl;/// The question's pre-generated narration clip (the same one play mode
/// reads aloud), or null when none exists yet.
 String? get audioUrl;/// True when this question should never be read aloud.
 bool get ttsExcluded;
/// Create a copy of DuelQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelQuestionCopyWith<DuelQuestion> get copyWith => _$DuelQuestionCopyWithImpl<DuelQuestion>(this as DuelQuestion, _$identity);

  /// Serializes this DuelQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelQuestion&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.ttsExcluded, ttsExcluded) || other.ttsExcluded == ttsExcluded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(options),kind,mediaUrl,audioUrl,ttsExcluded);

@override
String toString() {
  return 'DuelQuestion(text: $text, options: $options, kind: $kind, mediaUrl: $mediaUrl, audioUrl: $audioUrl, ttsExcluded: $ttsExcluded)';
}


}

/// @nodoc
abstract mixin class $DuelQuestionCopyWith<$Res>  {
  factory $DuelQuestionCopyWith(DuelQuestion value, $Res Function(DuelQuestion) _then) = _$DuelQuestionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'prompt') String text, List<String> options, String kind, String? mediaUrl, String? audioUrl, bool ttsExcluded
});




}
/// @nodoc
class _$DuelQuestionCopyWithImpl<$Res>
    implements $DuelQuestionCopyWith<$Res> {
  _$DuelQuestionCopyWithImpl(this._self, this._then);

  final DuelQuestion _self;
  final $Res Function(DuelQuestion) _then;

/// Create a copy of DuelQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? options = null,Object? kind = null,Object? mediaUrl = freezed,Object? audioUrl = freezed,Object? ttsExcluded = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,ttsExcluded: null == ttsExcluded ? _self.ttsExcluded : ttsExcluded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelQuestion].
extension DuelQuestionPatterns on DuelQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelQuestion value)  $default,){
final _that = this;
switch (_that) {
case _DuelQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _DuelQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'prompt')  String text,  List<String> options,  String kind,  String? mediaUrl,  String? audioUrl,  bool ttsExcluded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelQuestion() when $default != null:
return $default(_that.text,_that.options,_that.kind,_that.mediaUrl,_that.audioUrl,_that.ttsExcluded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'prompt')  String text,  List<String> options,  String kind,  String? mediaUrl,  String? audioUrl,  bool ttsExcluded)  $default,) {final _that = this;
switch (_that) {
case _DuelQuestion():
return $default(_that.text,_that.options,_that.kind,_that.mediaUrl,_that.audioUrl,_that.ttsExcluded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'prompt')  String text,  List<String> options,  String kind,  String? mediaUrl,  String? audioUrl,  bool ttsExcluded)?  $default,) {final _that = this;
switch (_that) {
case _DuelQuestion() when $default != null:
return $default(_that.text,_that.options,_that.kind,_that.mediaUrl,_that.audioUrl,_that.ttsExcluded);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelQuestion implements DuelQuestion {
  const _DuelQuestion({@JsonKey(name: 'prompt') required this.text, required final  List<String> options, this.kind = 'text', this.mediaUrl, this.audioUrl, this.ttsExcluded = false}): _options = options;
  factory _DuelQuestion.fromJson(Map<String, dynamic> json) => _$DuelQuestionFromJson(json);

@override@JsonKey(name: 'prompt') final  String text;
 final  List<String> _options;
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  String kind;
@override final  String? mediaUrl;
/// The question's pre-generated narration clip (the same one play mode
/// reads aloud), or null when none exists yet.
@override final  String? audioUrl;
/// True when this question should never be read aloud.
@override@JsonKey() final  bool ttsExcluded;

/// Create a copy of DuelQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelQuestionCopyWith<_DuelQuestion> get copyWith => __$DuelQuestionCopyWithImpl<_DuelQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelQuestion&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.ttsExcluded, ttsExcluded) || other.ttsExcluded == ttsExcluded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_options),kind,mediaUrl,audioUrl,ttsExcluded);

@override
String toString() {
  return 'DuelQuestion(text: $text, options: $options, kind: $kind, mediaUrl: $mediaUrl, audioUrl: $audioUrl, ttsExcluded: $ttsExcluded)';
}


}

/// @nodoc
abstract mixin class _$DuelQuestionCopyWith<$Res> implements $DuelQuestionCopyWith<$Res> {
  factory _$DuelQuestionCopyWith(_DuelQuestion value, $Res Function(_DuelQuestion) _then) = __$DuelQuestionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'prompt') String text, List<String> options, String kind, String? mediaUrl, String? audioUrl, bool ttsExcluded
});




}
/// @nodoc
class __$DuelQuestionCopyWithImpl<$Res>
    implements _$DuelQuestionCopyWith<$Res> {
  __$DuelQuestionCopyWithImpl(this._self, this._then);

  final _DuelQuestion _self;
  final $Res Function(_DuelQuestion) _then;

/// Create a copy of DuelQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? options = null,Object? kind = null,Object? mediaUrl = freezed,Object? audioUrl = freezed,Object? ttsExcluded = null,}) {
  return _then(_DuelQuestion(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,ttsExcluded: null == ttsExcluded ? _self.ttsExcluded : ttsExcluded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
