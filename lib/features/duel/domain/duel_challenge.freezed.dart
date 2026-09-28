// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelChallenge {

 String get id; ChallengeStatus get status; bool get creatorPresent; DateTime get createdAt; DateTime get expiresAt; DuelPlayer get creator; DuelTopic get topic; String? get opponentName; String? get opponentGuestTag; String? get duelId;
/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelChallengeCopyWith<DuelChallenge> get copyWith => _$DuelChallengeCopyWithImpl<DuelChallenge>(this as DuelChallenge, _$identity);

  /// Serializes this DuelChallenge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelChallenge&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.creatorPresent, creatorPresent) || other.creatorPresent == creatorPresent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName)&&(identical(other.opponentGuestTag, opponentGuestTag) || other.opponentGuestTag == opponentGuestTag)&&(identical(other.duelId, duelId) || other.duelId == duelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,creatorPresent,createdAt,expiresAt,creator,topic,opponentName,opponentGuestTag,duelId);

@override
String toString() {
  return 'DuelChallenge(id: $id, status: $status, creatorPresent: $creatorPresent, createdAt: $createdAt, expiresAt: $expiresAt, creator: $creator, topic: $topic, opponentName: $opponentName, opponentGuestTag: $opponentGuestTag, duelId: $duelId)';
}


}

/// @nodoc
abstract mixin class $DuelChallengeCopyWith<$Res>  {
  factory $DuelChallengeCopyWith(DuelChallenge value, $Res Function(DuelChallenge) _then) = _$DuelChallengeCopyWithImpl;
@useResult
$Res call({
 String id, ChallengeStatus status, bool creatorPresent, DateTime createdAt, DateTime expiresAt, DuelPlayer creator, DuelTopic topic, String? opponentName, String? opponentGuestTag, String? duelId
});


$DuelPlayerCopyWith<$Res> get creator;$DuelTopicCopyWith<$Res> get topic;

}
/// @nodoc
class _$DuelChallengeCopyWithImpl<$Res>
    implements $DuelChallengeCopyWith<$Res> {
  _$DuelChallengeCopyWithImpl(this._self, this._then);

  final DuelChallenge _self;
  final $Res Function(DuelChallenge) _then;

/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? creatorPresent = null,Object? createdAt = null,Object? expiresAt = null,Object? creator = null,Object? topic = null,Object? opponentName = freezed,Object? opponentGuestTag = freezed,Object? duelId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChallengeStatus,creatorPresent: null == creatorPresent ? _self.creatorPresent : creatorPresent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as DuelPlayer,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DuelTopic,opponentName: freezed == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String?,opponentGuestTag: freezed == opponentGuestTag ? _self.opponentGuestTag : opponentGuestTag // ignore: cast_nullable_to_non_nullable
as String?,duelId: freezed == duelId ? _self.duelId : duelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get creator {
  
  return $DuelPlayerCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<$Res> get topic {
  
  return $DuelTopicCopyWith<$Res>(_self.topic, (value) {
    return _then(_self.copyWith(topic: value));
  });
}
}


/// Adds pattern-matching-related methods to [DuelChallenge].
extension DuelChallengePatterns on DuelChallenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelChallenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelChallenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelChallenge value)  $default,){
final _that = this;
switch (_that) {
case _DuelChallenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelChallenge value)?  $default,){
final _that = this;
switch (_that) {
case _DuelChallenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ChallengeStatus status,  bool creatorPresent,  DateTime createdAt,  DateTime expiresAt,  DuelPlayer creator,  DuelTopic topic,  String? opponentName,  String? opponentGuestTag,  String? duelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelChallenge() when $default != null:
return $default(_that.id,_that.status,_that.creatorPresent,_that.createdAt,_that.expiresAt,_that.creator,_that.topic,_that.opponentName,_that.opponentGuestTag,_that.duelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ChallengeStatus status,  bool creatorPresent,  DateTime createdAt,  DateTime expiresAt,  DuelPlayer creator,  DuelTopic topic,  String? opponentName,  String? opponentGuestTag,  String? duelId)  $default,) {final _that = this;
switch (_that) {
case _DuelChallenge():
return $default(_that.id,_that.status,_that.creatorPresent,_that.createdAt,_that.expiresAt,_that.creator,_that.topic,_that.opponentName,_that.opponentGuestTag,_that.duelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ChallengeStatus status,  bool creatorPresent,  DateTime createdAt,  DateTime expiresAt,  DuelPlayer creator,  DuelTopic topic,  String? opponentName,  String? opponentGuestTag,  String? duelId)?  $default,) {final _that = this;
switch (_that) {
case _DuelChallenge() when $default != null:
return $default(_that.id,_that.status,_that.creatorPresent,_that.createdAt,_that.expiresAt,_that.creator,_that.topic,_that.opponentName,_that.opponentGuestTag,_that.duelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelChallenge implements DuelChallenge {
  const _DuelChallenge({required this.id, required this.status, required this.creatorPresent, required this.createdAt, required this.expiresAt, required this.creator, required this.topic, this.opponentName, this.opponentGuestTag, this.duelId});
  factory _DuelChallenge.fromJson(Map<String, dynamic> json) => _$DuelChallengeFromJson(json);

@override final  String id;
@override final  ChallengeStatus status;
@override final  bool creatorPresent;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  DuelPlayer creator;
@override final  DuelTopic topic;
@override final  String? opponentName;
@override final  String? opponentGuestTag;
@override final  String? duelId;

/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelChallengeCopyWith<_DuelChallenge> get copyWith => __$DuelChallengeCopyWithImpl<_DuelChallenge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelChallengeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelChallenge&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.creatorPresent, creatorPresent) || other.creatorPresent == creatorPresent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName)&&(identical(other.opponentGuestTag, opponentGuestTag) || other.opponentGuestTag == opponentGuestTag)&&(identical(other.duelId, duelId) || other.duelId == duelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,creatorPresent,createdAt,expiresAt,creator,topic,opponentName,opponentGuestTag,duelId);

@override
String toString() {
  return 'DuelChallenge(id: $id, status: $status, creatorPresent: $creatorPresent, createdAt: $createdAt, expiresAt: $expiresAt, creator: $creator, topic: $topic, opponentName: $opponentName, opponentGuestTag: $opponentGuestTag, duelId: $duelId)';
}


}

/// @nodoc
abstract mixin class _$DuelChallengeCopyWith<$Res> implements $DuelChallengeCopyWith<$Res> {
  factory _$DuelChallengeCopyWith(_DuelChallenge value, $Res Function(_DuelChallenge) _then) = __$DuelChallengeCopyWithImpl;
@override @useResult
$Res call({
 String id, ChallengeStatus status, bool creatorPresent, DateTime createdAt, DateTime expiresAt, DuelPlayer creator, DuelTopic topic, String? opponentName, String? opponentGuestTag, String? duelId
});


@override $DuelPlayerCopyWith<$Res> get creator;@override $DuelTopicCopyWith<$Res> get topic;

}
/// @nodoc
class __$DuelChallengeCopyWithImpl<$Res>
    implements _$DuelChallengeCopyWith<$Res> {
  __$DuelChallengeCopyWithImpl(this._self, this._then);

  final _DuelChallenge _self;
  final $Res Function(_DuelChallenge) _then;

/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? creatorPresent = null,Object? createdAt = null,Object? expiresAt = null,Object? creator = null,Object? topic = null,Object? opponentName = freezed,Object? opponentGuestTag = freezed,Object? duelId = freezed,}) {
  return _then(_DuelChallenge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChallengeStatus,creatorPresent: null == creatorPresent ? _self.creatorPresent : creatorPresent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as DuelPlayer,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DuelTopic,opponentName: freezed == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String?,opponentGuestTag: freezed == opponentGuestTag ? _self.opponentGuestTag : opponentGuestTag // ignore: cast_nullable_to_non_nullable
as String?,duelId: freezed == duelId ? _self.duelId : duelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get creator {
  
  return $DuelPlayerCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of DuelChallenge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<$Res> get topic {
  
  return $DuelTopicCopyWith<$Res>(_self.topic, (value) {
    return _then(_self.copyWith(topic: value));
  });
}
}

// dart format on
