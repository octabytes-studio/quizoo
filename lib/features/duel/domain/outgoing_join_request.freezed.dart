// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outgoing_join_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OutgoingJoinRequest {

 String get requestId; String get challengeId;@JsonKey(unknownEnumValue: JoinRequestStatus.unavailable) JoinRequestStatus get status; int? get position; DateTime? get expiresAt; DateTime? get retryAfter; String? get reason;
/// Create a copy of OutgoingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingJoinRequestCopyWith<OutgoingJoinRequest> get copyWith => _$OutgoingJoinRequestCopyWithImpl<OutgoingJoinRequest>(this as OutgoingJoinRequest, _$identity);

  /// Serializes this OutgoingJoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.position, position) || other.position == position)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,challengeId,status,position,expiresAt,retryAfter,reason);

@override
String toString() {
  return 'OutgoingJoinRequest(requestId: $requestId, challengeId: $challengeId, status: $status, position: $position, expiresAt: $expiresAt, retryAfter: $retryAfter, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $OutgoingJoinRequestCopyWith<$Res>  {
  factory $OutgoingJoinRequestCopyWith(OutgoingJoinRequest value, $Res Function(OutgoingJoinRequest) _then) = _$OutgoingJoinRequestCopyWithImpl;
@useResult
$Res call({
 String requestId, String challengeId,@JsonKey(unknownEnumValue: JoinRequestStatus.unavailable) JoinRequestStatus status, int? position, DateTime? expiresAt, DateTime? retryAfter, String? reason
});




}
/// @nodoc
class _$OutgoingJoinRequestCopyWithImpl<$Res>
    implements $OutgoingJoinRequestCopyWith<$Res> {
  _$OutgoingJoinRequestCopyWithImpl(this._self, this._then);

  final OutgoingJoinRequest _self;
  final $Res Function(OutgoingJoinRequest) _then;

/// Create a copy of OutgoingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? challengeId = null,Object? status = null,Object? position = freezed,Object? expiresAt = freezed,Object? retryAfter = freezed,Object? reason = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JoinRequestStatus,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,retryAfter: freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OutgoingJoinRequest].
extension OutgoingJoinRequestPatterns on OutgoingJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutgoingJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutgoingJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutgoingJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _OutgoingJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutgoingJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OutgoingJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  String challengeId, @JsonKey(unknownEnumValue: JoinRequestStatus.unavailable)  JoinRequestStatus status,  int? position,  DateTime? expiresAt,  DateTime? retryAfter,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingJoinRequest() when $default != null:
return $default(_that.requestId,_that.challengeId,_that.status,_that.position,_that.expiresAt,_that.retryAfter,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  String challengeId, @JsonKey(unknownEnumValue: JoinRequestStatus.unavailable)  JoinRequestStatus status,  int? position,  DateTime? expiresAt,  DateTime? retryAfter,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _OutgoingJoinRequest():
return $default(_that.requestId,_that.challengeId,_that.status,_that.position,_that.expiresAt,_that.retryAfter,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  String challengeId, @JsonKey(unknownEnumValue: JoinRequestStatus.unavailable)  JoinRequestStatus status,  int? position,  DateTime? expiresAt,  DateTime? retryAfter,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingJoinRequest() when $default != null:
return $default(_that.requestId,_that.challengeId,_that.status,_that.position,_that.expiresAt,_that.retryAfter,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutgoingJoinRequest extends OutgoingJoinRequest {
  const _OutgoingJoinRequest({required this.requestId, required this.challengeId, @JsonKey(unknownEnumValue: JoinRequestStatus.unavailable) required this.status, this.position, this.expiresAt, this.retryAfter, this.reason}): super._();
  factory _OutgoingJoinRequest.fromJson(Map<String, dynamic> json) => _$OutgoingJoinRequestFromJson(json);

@override final  String requestId;
@override final  String challengeId;
@override@JsonKey(unknownEnumValue: JoinRequestStatus.unavailable) final  JoinRequestStatus status;
@override final  int? position;
@override final  DateTime? expiresAt;
@override final  DateTime? retryAfter;
@override final  String? reason;

/// Create a copy of OutgoingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingJoinRequestCopyWith<_OutgoingJoinRequest> get copyWith => __$OutgoingJoinRequestCopyWithImpl<_OutgoingJoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutgoingJoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.position, position) || other.position == position)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,challengeId,status,position,expiresAt,retryAfter,reason);

@override
String toString() {
  return 'OutgoingJoinRequest(requestId: $requestId, challengeId: $challengeId, status: $status, position: $position, expiresAt: $expiresAt, retryAfter: $retryAfter, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$OutgoingJoinRequestCopyWith<$Res> implements $OutgoingJoinRequestCopyWith<$Res> {
  factory _$OutgoingJoinRequestCopyWith(_OutgoingJoinRequest value, $Res Function(_OutgoingJoinRequest) _then) = __$OutgoingJoinRequestCopyWithImpl;
@override @useResult
$Res call({
 String requestId, String challengeId,@JsonKey(unknownEnumValue: JoinRequestStatus.unavailable) JoinRequestStatus status, int? position, DateTime? expiresAt, DateTime? retryAfter, String? reason
});




}
/// @nodoc
class __$OutgoingJoinRequestCopyWithImpl<$Res>
    implements _$OutgoingJoinRequestCopyWith<$Res> {
  __$OutgoingJoinRequestCopyWithImpl(this._self, this._then);

  final _OutgoingJoinRequest _self;
  final $Res Function(_OutgoingJoinRequest) _then;

/// Create a copy of OutgoingJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? challengeId = null,Object? status = null,Object? position = freezed,Object? expiresAt = freezed,Object? retryAfter = freezed,Object? reason = freezed,}) {
  return _then(_OutgoingJoinRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JoinRequestStatus,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,retryAfter: freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
