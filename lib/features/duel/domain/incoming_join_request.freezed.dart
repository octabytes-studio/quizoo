// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incoming_join_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IncomingJoinRequest {

 String get requestId; String get challengeId; DuelPlayer get requester; DateTime get expiresAt; int get queuedCount;
/// Create a copy of IncomingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomingJoinRequestCopyWith<IncomingJoinRequest> get copyWith => _$IncomingJoinRequestCopyWithImpl<IncomingJoinRequest>(this as IncomingJoinRequest, _$identity);

  /// Serializes this IncomingJoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomingJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.queuedCount, queuedCount) || other.queuedCount == queuedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,challengeId,requester,expiresAt,queuedCount);

@override
String toString() {
  return 'IncomingJoinRequest(requestId: $requestId, challengeId: $challengeId, requester: $requester, expiresAt: $expiresAt, queuedCount: $queuedCount)';
}


}

/// @nodoc
abstract mixin class $IncomingJoinRequestCopyWith<$Res>  {
  factory $IncomingJoinRequestCopyWith(IncomingJoinRequest value, $Res Function(IncomingJoinRequest) _then) = _$IncomingJoinRequestCopyWithImpl;
@useResult
$Res call({
 String requestId, String challengeId, DuelPlayer requester, DateTime expiresAt, int queuedCount
});


$DuelPlayerCopyWith<$Res> get requester;

}
/// @nodoc
class _$IncomingJoinRequestCopyWithImpl<$Res>
    implements $IncomingJoinRequestCopyWith<$Res> {
  _$IncomingJoinRequestCopyWithImpl(this._self, this._then);

  final IncomingJoinRequest _self;
  final $Res Function(IncomingJoinRequest) _then;

/// Create a copy of IncomingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? challengeId = null,Object? requester = null,Object? expiresAt = null,Object? queuedCount = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,requester: null == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as DuelPlayer,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,queuedCount: null == queuedCount ? _self.queuedCount : queuedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of IncomingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get requester {
  
  return $DuelPlayerCopyWith<$Res>(_self.requester, (value) {
    return _then(_self.copyWith(requester: value));
  });
}
}


/// Adds pattern-matching-related methods to [IncomingJoinRequest].
extension IncomingJoinRequestPatterns on IncomingJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncomingJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncomingJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncomingJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _IncomingJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncomingJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _IncomingJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  String challengeId,  DuelPlayer requester,  DateTime expiresAt,  int queuedCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomingJoinRequest() when $default != null:
return $default(_that.requestId,_that.challengeId,_that.requester,_that.expiresAt,_that.queuedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  String challengeId,  DuelPlayer requester,  DateTime expiresAt,  int queuedCount)  $default,) {final _that = this;
switch (_that) {
case _IncomingJoinRequest():
return $default(_that.requestId,_that.challengeId,_that.requester,_that.expiresAt,_that.queuedCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  String challengeId,  DuelPlayer requester,  DateTime expiresAt,  int queuedCount)?  $default,) {final _that = this;
switch (_that) {
case _IncomingJoinRequest() when $default != null:
return $default(_that.requestId,_that.challengeId,_that.requester,_that.expiresAt,_that.queuedCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IncomingJoinRequest implements IncomingJoinRequest {
  const _IncomingJoinRequest({required this.requestId, required this.challengeId, required this.requester, required this.expiresAt, this.queuedCount = 0});
  factory _IncomingJoinRequest.fromJson(Map<String, dynamic> json) => _$IncomingJoinRequestFromJson(json);

@override final  String requestId;
@override final  String challengeId;
@override final  DuelPlayer requester;
@override final  DateTime expiresAt;
@override@JsonKey() final  int queuedCount;

/// Create a copy of IncomingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomingJoinRequestCopyWith<_IncomingJoinRequest> get copyWith => __$IncomingJoinRequestCopyWithImpl<_IncomingJoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncomingJoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomingJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.queuedCount, queuedCount) || other.queuedCount == queuedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,challengeId,requester,expiresAt,queuedCount);

@override
String toString() {
  return 'IncomingJoinRequest(requestId: $requestId, challengeId: $challengeId, requester: $requester, expiresAt: $expiresAt, queuedCount: $queuedCount)';
}


}

/// @nodoc
abstract mixin class _$IncomingJoinRequestCopyWith<$Res> implements $IncomingJoinRequestCopyWith<$Res> {
  factory _$IncomingJoinRequestCopyWith(_IncomingJoinRequest value, $Res Function(_IncomingJoinRequest) _then) = __$IncomingJoinRequestCopyWithImpl;
@override @useResult
$Res call({
 String requestId, String challengeId, DuelPlayer requester, DateTime expiresAt, int queuedCount
});


@override $DuelPlayerCopyWith<$Res> get requester;

}
/// @nodoc
class __$IncomingJoinRequestCopyWithImpl<$Res>
    implements _$IncomingJoinRequestCopyWith<$Res> {
  __$IncomingJoinRequestCopyWithImpl(this._self, this._then);

  final _IncomingJoinRequest _self;
  final $Res Function(_IncomingJoinRequest) _then;

/// Create a copy of IncomingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? challengeId = null,Object? requester = null,Object? expiresAt = null,Object? queuedCount = null,}) {
  return _then(_IncomingJoinRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,requester: null == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as DuelPlayer,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,queuedCount: null == queuedCount ? _self.queuedCount : queuedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of IncomingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get requester {
  
  return $DuelPlayerCopyWith<$Res>(_self.requester, (value) {
    return _then(_self.copyWith(requester: value));
  });
}
}

// dart format on
