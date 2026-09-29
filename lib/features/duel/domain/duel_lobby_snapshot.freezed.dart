// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_lobby_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelLobbySnapshot {

 DateTime get serverNow; DuelConfig get config; DuelLobbyMe get me; List<DuelChallenge> get challenges; List<DuelChallenge> get recentlyEnded; List<OutgoingJoinRequest> get myRequests; IncomingJoinRequest? get incoming;
/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelLobbySnapshotCopyWith<DuelLobbySnapshot> get copyWith => _$DuelLobbySnapshotCopyWithImpl<DuelLobbySnapshot>(this as DuelLobbySnapshot, _$identity);

  /// Serializes this DuelLobbySnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelLobbySnapshot&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.config, config) || other.config == config)&&(identical(other.me, me) || other.me == me)&&const DeepCollectionEquality().equals(other.challenges, challenges)&&const DeepCollectionEquality().equals(other.recentlyEnded, recentlyEnded)&&const DeepCollectionEquality().equals(other.myRequests, myRequests)&&(identical(other.incoming, incoming) || other.incoming == incoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverNow,config,me,const DeepCollectionEquality().hash(challenges),const DeepCollectionEquality().hash(recentlyEnded),const DeepCollectionEquality().hash(myRequests),incoming);

@override
String toString() {
  return 'DuelLobbySnapshot(serverNow: $serverNow, config: $config, me: $me, challenges: $challenges, recentlyEnded: $recentlyEnded, myRequests: $myRequests, incoming: $incoming)';
}


}

/// @nodoc
abstract mixin class $DuelLobbySnapshotCopyWith<$Res>  {
  factory $DuelLobbySnapshotCopyWith(DuelLobbySnapshot value, $Res Function(DuelLobbySnapshot) _then) = _$DuelLobbySnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime serverNow, DuelConfig config, DuelLobbyMe me, List<DuelChallenge> challenges, List<DuelChallenge> recentlyEnded, List<OutgoingJoinRequest> myRequests, IncomingJoinRequest? incoming
});


$DuelConfigCopyWith<$Res> get config;$DuelLobbyMeCopyWith<$Res> get me;$IncomingJoinRequestCopyWith<$Res>? get incoming;

}
/// @nodoc
class _$DuelLobbySnapshotCopyWithImpl<$Res>
    implements $DuelLobbySnapshotCopyWith<$Res> {
  _$DuelLobbySnapshotCopyWithImpl(this._self, this._then);

  final DuelLobbySnapshot _self;
  final $Res Function(DuelLobbySnapshot) _then;

/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverNow = null,Object? config = null,Object? me = null,Object? challenges = null,Object? recentlyEnded = null,Object? myRequests = null,Object? incoming = freezed,}) {
  return _then(_self.copyWith(
serverNow: null == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as DuelConfig,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as DuelLobbyMe,challenges: null == challenges ? _self.challenges : challenges // ignore: cast_nullable_to_non_nullable
as List<DuelChallenge>,recentlyEnded: null == recentlyEnded ? _self.recentlyEnded : recentlyEnded // ignore: cast_nullable_to_non_nullable
as List<DuelChallenge>,myRequests: null == myRequests ? _self.myRequests : myRequests // ignore: cast_nullable_to_non_nullable
as List<OutgoingJoinRequest>,incoming: freezed == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as IncomingJoinRequest?,
  ));
}
/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelConfigCopyWith<$Res> get config {
  
  return $DuelConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelLobbyMeCopyWith<$Res> get me {
  
  return $DuelLobbyMeCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncomingJoinRequestCopyWith<$Res>? get incoming {
    if (_self.incoming == null) {
    return null;
  }

  return $IncomingJoinRequestCopyWith<$Res>(_self.incoming!, (value) {
    return _then(_self.copyWith(incoming: value));
  });
}
}


/// Adds pattern-matching-related methods to [DuelLobbySnapshot].
extension DuelLobbySnapshotPatterns on DuelLobbySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelLobbySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelLobbySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelLobbySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _DuelLobbySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelLobbySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _DuelLobbySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime serverNow,  DuelConfig config,  DuelLobbyMe me,  List<DuelChallenge> challenges,  List<DuelChallenge> recentlyEnded,  List<OutgoingJoinRequest> myRequests,  IncomingJoinRequest? incoming)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelLobbySnapshot() when $default != null:
return $default(_that.serverNow,_that.config,_that.me,_that.challenges,_that.recentlyEnded,_that.myRequests,_that.incoming);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime serverNow,  DuelConfig config,  DuelLobbyMe me,  List<DuelChallenge> challenges,  List<DuelChallenge> recentlyEnded,  List<OutgoingJoinRequest> myRequests,  IncomingJoinRequest? incoming)  $default,) {final _that = this;
switch (_that) {
case _DuelLobbySnapshot():
return $default(_that.serverNow,_that.config,_that.me,_that.challenges,_that.recentlyEnded,_that.myRequests,_that.incoming);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime serverNow,  DuelConfig config,  DuelLobbyMe me,  List<DuelChallenge> challenges,  List<DuelChallenge> recentlyEnded,  List<OutgoingJoinRequest> myRequests,  IncomingJoinRequest? incoming)?  $default,) {final _that = this;
switch (_that) {
case _DuelLobbySnapshot() when $default != null:
return $default(_that.serverNow,_that.config,_that.me,_that.challenges,_that.recentlyEnded,_that.myRequests,_that.incoming);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelLobbySnapshot implements DuelLobbySnapshot {
  const _DuelLobbySnapshot({required this.serverNow, required this.config, required this.me, final  List<DuelChallenge> challenges = const [], final  List<DuelChallenge> recentlyEnded = const [], final  List<OutgoingJoinRequest> myRequests = const [], this.incoming}): _challenges = challenges,_recentlyEnded = recentlyEnded,_myRequests = myRequests;
  factory _DuelLobbySnapshot.fromJson(Map<String, dynamic> json) => _$DuelLobbySnapshotFromJson(json);

@override final  DateTime serverNow;
@override final  DuelConfig config;
@override final  DuelLobbyMe me;
 final  List<DuelChallenge> _challenges;
@override@JsonKey() List<DuelChallenge> get challenges {
  if (_challenges is EqualUnmodifiableListView) return _challenges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_challenges);
}

 final  List<DuelChallenge> _recentlyEnded;
@override@JsonKey() List<DuelChallenge> get recentlyEnded {
  if (_recentlyEnded is EqualUnmodifiableListView) return _recentlyEnded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentlyEnded);
}

 final  List<OutgoingJoinRequest> _myRequests;
@override@JsonKey() List<OutgoingJoinRequest> get myRequests {
  if (_myRequests is EqualUnmodifiableListView) return _myRequests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_myRequests);
}

@override final  IncomingJoinRequest? incoming;

/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelLobbySnapshotCopyWith<_DuelLobbySnapshot> get copyWith => __$DuelLobbySnapshotCopyWithImpl<_DuelLobbySnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelLobbySnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelLobbySnapshot&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.config, config) || other.config == config)&&(identical(other.me, me) || other.me == me)&&const DeepCollectionEquality().equals(other._challenges, _challenges)&&const DeepCollectionEquality().equals(other._recentlyEnded, _recentlyEnded)&&const DeepCollectionEquality().equals(other._myRequests, _myRequests)&&(identical(other.incoming, incoming) || other.incoming == incoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverNow,config,me,const DeepCollectionEquality().hash(_challenges),const DeepCollectionEquality().hash(_recentlyEnded),const DeepCollectionEquality().hash(_myRequests),incoming);

@override
String toString() {
  return 'DuelLobbySnapshot(serverNow: $serverNow, config: $config, me: $me, challenges: $challenges, recentlyEnded: $recentlyEnded, myRequests: $myRequests, incoming: $incoming)';
}


}

/// @nodoc
abstract mixin class _$DuelLobbySnapshotCopyWith<$Res> implements $DuelLobbySnapshotCopyWith<$Res> {
  factory _$DuelLobbySnapshotCopyWith(_DuelLobbySnapshot value, $Res Function(_DuelLobbySnapshot) _then) = __$DuelLobbySnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime serverNow, DuelConfig config, DuelLobbyMe me, List<DuelChallenge> challenges, List<DuelChallenge> recentlyEnded, List<OutgoingJoinRequest> myRequests, IncomingJoinRequest? incoming
});


@override $DuelConfigCopyWith<$Res> get config;@override $DuelLobbyMeCopyWith<$Res> get me;@override $IncomingJoinRequestCopyWith<$Res>? get incoming;

}
/// @nodoc
class __$DuelLobbySnapshotCopyWithImpl<$Res>
    implements _$DuelLobbySnapshotCopyWith<$Res> {
  __$DuelLobbySnapshotCopyWithImpl(this._self, this._then);

  final _DuelLobbySnapshot _self;
  final $Res Function(_DuelLobbySnapshot) _then;

/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverNow = null,Object? config = null,Object? me = null,Object? challenges = null,Object? recentlyEnded = null,Object? myRequests = null,Object? incoming = freezed,}) {
  return _then(_DuelLobbySnapshot(
serverNow: null == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as DuelConfig,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as DuelLobbyMe,challenges: null == challenges ? _self._challenges : challenges // ignore: cast_nullable_to_non_nullable
as List<DuelChallenge>,recentlyEnded: null == recentlyEnded ? _self._recentlyEnded : recentlyEnded // ignore: cast_nullable_to_non_nullable
as List<DuelChallenge>,myRequests: null == myRequests ? _self._myRequests : myRequests // ignore: cast_nullable_to_non_nullable
as List<OutgoingJoinRequest>,incoming: freezed == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as IncomingJoinRequest?,
  ));
}

/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelConfigCopyWith<$Res> get config {
  
  return $DuelConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelLobbyMeCopyWith<$Res> get me {
  
  return $DuelLobbyMeCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of DuelLobbySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncomingJoinRequestCopyWith<$Res>? get incoming {
    if (_self.incoming == null) {
    return null;
  }

  return $IncomingJoinRequestCopyWith<$Res>(_self.incoming!, (value) {
    return _then(_self.copyWith(incoming: value));
  });
}
}

// dart format on
