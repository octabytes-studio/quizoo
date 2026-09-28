// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_duel_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LiveDuelSnapshot {

 DateTime get serverNow; String get duelId; LiveDuelStatus get status; DuelSide get mySide; bool get isRanked; String get origin; DuelTopic get topic; DuelPlayer get me; DuelPlayer get opponent; DuelConfig get config; int get currentRound; List<DuelRoundRecord> get history; int get myScore; int get opponentScore; LiveDuelRoundState? get round; LiveDuelOutcome? get result;
/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveDuelSnapshotCopyWith<LiveDuelSnapshot> get copyWith => _$LiveDuelSnapshotCopyWithImpl<LiveDuelSnapshot>(this as LiveDuelSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveDuelSnapshot&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.duelId, duelId) || other.duelId == duelId)&&(identical(other.status, status) || other.status == status)&&(identical(other.mySide, mySide) || other.mySide == mySide)&&(identical(other.isRanked, isRanked) || other.isRanked == isRanked)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.me, me) || other.me == me)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.config, config) || other.config == config)&&(identical(other.currentRound, currentRound) || other.currentRound == currentRound)&&const DeepCollectionEquality().equals(other.history, history)&&(identical(other.myScore, myScore) || other.myScore == myScore)&&(identical(other.opponentScore, opponentScore) || other.opponentScore == opponentScore)&&(identical(other.round, round) || other.round == round)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,serverNow,duelId,status,mySide,isRanked,origin,topic,me,opponent,config,currentRound,const DeepCollectionEquality().hash(history),myScore,opponentScore,round,result);

@override
String toString() {
  return 'LiveDuelSnapshot(serverNow: $serverNow, duelId: $duelId, status: $status, mySide: $mySide, isRanked: $isRanked, origin: $origin, topic: $topic, me: $me, opponent: $opponent, config: $config, currentRound: $currentRound, history: $history, myScore: $myScore, opponentScore: $opponentScore, round: $round, result: $result)';
}


}

/// @nodoc
abstract mixin class $LiveDuelSnapshotCopyWith<$Res>  {
  factory $LiveDuelSnapshotCopyWith(LiveDuelSnapshot value, $Res Function(LiveDuelSnapshot) _then) = _$LiveDuelSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime serverNow, String duelId, LiveDuelStatus status, DuelSide mySide, bool isRanked, String origin, DuelTopic topic, DuelPlayer me, DuelPlayer opponent, DuelConfig config, int currentRound, List<DuelRoundRecord> history, int myScore, int opponentScore, LiveDuelRoundState? round, LiveDuelOutcome? result
});


$DuelTopicCopyWith<$Res> get topic;$DuelPlayerCopyWith<$Res> get me;$DuelPlayerCopyWith<$Res> get opponent;$DuelConfigCopyWith<$Res> get config;$LiveDuelRoundStateCopyWith<$Res>? get round;$LiveDuelOutcomeCopyWith<$Res>? get result;

}
/// @nodoc
class _$LiveDuelSnapshotCopyWithImpl<$Res>
    implements $LiveDuelSnapshotCopyWith<$Res> {
  _$LiveDuelSnapshotCopyWithImpl(this._self, this._then);

  final LiveDuelSnapshot _self;
  final $Res Function(LiveDuelSnapshot) _then;

/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverNow = null,Object? duelId = null,Object? status = null,Object? mySide = null,Object? isRanked = null,Object? origin = null,Object? topic = null,Object? me = null,Object? opponent = null,Object? config = null,Object? currentRound = null,Object? history = null,Object? myScore = null,Object? opponentScore = null,Object? round = freezed,Object? result = freezed,}) {
  return _then(_self.copyWith(
serverNow: null == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime,duelId: null == duelId ? _self.duelId : duelId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LiveDuelStatus,mySide: null == mySide ? _self.mySide : mySide // ignore: cast_nullable_to_non_nullable
as DuelSide,isRanked: null == isRanked ? _self.isRanked : isRanked // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DuelTopic,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as DuelPlayer,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as DuelPlayer,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as DuelConfig,currentRound: null == currentRound ? _self.currentRound : currentRound // ignore: cast_nullable_to_non_nullable
as int,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<DuelRoundRecord>,myScore: null == myScore ? _self.myScore : myScore // ignore: cast_nullable_to_non_nullable
as int,opponentScore: null == opponentScore ? _self.opponentScore : opponentScore // ignore: cast_nullable_to_non_nullable
as int,round: freezed == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as LiveDuelRoundState?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as LiveDuelOutcome?,
  ));
}
/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<$Res> get topic {
  
  return $DuelTopicCopyWith<$Res>(_self.topic, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get me {
  
  return $DuelPlayerCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get opponent {
  
  return $DuelPlayerCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelConfigCopyWith<$Res> get config {
  
  return $DuelConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveDuelRoundStateCopyWith<$Res>? get round {
    if (_self.round == null) {
    return null;
  }

  return $LiveDuelRoundStateCopyWith<$Res>(_self.round!, (value) {
    return _then(_self.copyWith(round: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveDuelOutcomeCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $LiveDuelOutcomeCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveDuelSnapshot].
extension LiveDuelSnapshotPatterns on LiveDuelSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveDuelSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveDuelSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveDuelSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _LiveDuelSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveDuelSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _LiveDuelSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime serverNow,  String duelId,  LiveDuelStatus status,  DuelSide mySide,  bool isRanked,  String origin,  DuelTopic topic,  DuelPlayer me,  DuelPlayer opponent,  DuelConfig config,  int currentRound,  List<DuelRoundRecord> history,  int myScore,  int opponentScore,  LiveDuelRoundState? round,  LiveDuelOutcome? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveDuelSnapshot() when $default != null:
return $default(_that.serverNow,_that.duelId,_that.status,_that.mySide,_that.isRanked,_that.origin,_that.topic,_that.me,_that.opponent,_that.config,_that.currentRound,_that.history,_that.myScore,_that.opponentScore,_that.round,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime serverNow,  String duelId,  LiveDuelStatus status,  DuelSide mySide,  bool isRanked,  String origin,  DuelTopic topic,  DuelPlayer me,  DuelPlayer opponent,  DuelConfig config,  int currentRound,  List<DuelRoundRecord> history,  int myScore,  int opponentScore,  LiveDuelRoundState? round,  LiveDuelOutcome? result)  $default,) {final _that = this;
switch (_that) {
case _LiveDuelSnapshot():
return $default(_that.serverNow,_that.duelId,_that.status,_that.mySide,_that.isRanked,_that.origin,_that.topic,_that.me,_that.opponent,_that.config,_that.currentRound,_that.history,_that.myScore,_that.opponentScore,_that.round,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime serverNow,  String duelId,  LiveDuelStatus status,  DuelSide mySide,  bool isRanked,  String origin,  DuelTopic topic,  DuelPlayer me,  DuelPlayer opponent,  DuelConfig config,  int currentRound,  List<DuelRoundRecord> history,  int myScore,  int opponentScore,  LiveDuelRoundState? round,  LiveDuelOutcome? result)?  $default,) {final _that = this;
switch (_that) {
case _LiveDuelSnapshot() when $default != null:
return $default(_that.serverNow,_that.duelId,_that.status,_that.mySide,_that.isRanked,_that.origin,_that.topic,_that.me,_that.opponent,_that.config,_that.currentRound,_that.history,_that.myScore,_that.opponentScore,_that.round,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _LiveDuelSnapshot extends LiveDuelSnapshot {
  const _LiveDuelSnapshot({required this.serverNow, required this.duelId, required this.status, required this.mySide, required this.isRanked, required this.origin, required this.topic, required this.me, required this.opponent, required this.config, required this.currentRound, required final  List<DuelRoundRecord> history, required this.myScore, required this.opponentScore, this.round, this.result}): _history = history,super._();
  

@override final  DateTime serverNow;
@override final  String duelId;
@override final  LiveDuelStatus status;
@override final  DuelSide mySide;
@override final  bool isRanked;
@override final  String origin;
@override final  DuelTopic topic;
@override final  DuelPlayer me;
@override final  DuelPlayer opponent;
@override final  DuelConfig config;
@override final  int currentRound;
 final  List<DuelRoundRecord> _history;
@override List<DuelRoundRecord> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

@override final  int myScore;
@override final  int opponentScore;
@override final  LiveDuelRoundState? round;
@override final  LiveDuelOutcome? result;

/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveDuelSnapshotCopyWith<_LiveDuelSnapshot> get copyWith => __$LiveDuelSnapshotCopyWithImpl<_LiveDuelSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveDuelSnapshot&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.duelId, duelId) || other.duelId == duelId)&&(identical(other.status, status) || other.status == status)&&(identical(other.mySide, mySide) || other.mySide == mySide)&&(identical(other.isRanked, isRanked) || other.isRanked == isRanked)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.me, me) || other.me == me)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.config, config) || other.config == config)&&(identical(other.currentRound, currentRound) || other.currentRound == currentRound)&&const DeepCollectionEquality().equals(other._history, _history)&&(identical(other.myScore, myScore) || other.myScore == myScore)&&(identical(other.opponentScore, opponentScore) || other.opponentScore == opponentScore)&&(identical(other.round, round) || other.round == round)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,serverNow,duelId,status,mySide,isRanked,origin,topic,me,opponent,config,currentRound,const DeepCollectionEquality().hash(_history),myScore,opponentScore,round,result);

@override
String toString() {
  return 'LiveDuelSnapshot(serverNow: $serverNow, duelId: $duelId, status: $status, mySide: $mySide, isRanked: $isRanked, origin: $origin, topic: $topic, me: $me, opponent: $opponent, config: $config, currentRound: $currentRound, history: $history, myScore: $myScore, opponentScore: $opponentScore, round: $round, result: $result)';
}


}

/// @nodoc
abstract mixin class _$LiveDuelSnapshotCopyWith<$Res> implements $LiveDuelSnapshotCopyWith<$Res> {
  factory _$LiveDuelSnapshotCopyWith(_LiveDuelSnapshot value, $Res Function(_LiveDuelSnapshot) _then) = __$LiveDuelSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime serverNow, String duelId, LiveDuelStatus status, DuelSide mySide, bool isRanked, String origin, DuelTopic topic, DuelPlayer me, DuelPlayer opponent, DuelConfig config, int currentRound, List<DuelRoundRecord> history, int myScore, int opponentScore, LiveDuelRoundState? round, LiveDuelOutcome? result
});


@override $DuelTopicCopyWith<$Res> get topic;@override $DuelPlayerCopyWith<$Res> get me;@override $DuelPlayerCopyWith<$Res> get opponent;@override $DuelConfigCopyWith<$Res> get config;@override $LiveDuelRoundStateCopyWith<$Res>? get round;@override $LiveDuelOutcomeCopyWith<$Res>? get result;

}
/// @nodoc
class __$LiveDuelSnapshotCopyWithImpl<$Res>
    implements _$LiveDuelSnapshotCopyWith<$Res> {
  __$LiveDuelSnapshotCopyWithImpl(this._self, this._then);

  final _LiveDuelSnapshot _self;
  final $Res Function(_LiveDuelSnapshot) _then;

/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverNow = null,Object? duelId = null,Object? status = null,Object? mySide = null,Object? isRanked = null,Object? origin = null,Object? topic = null,Object? me = null,Object? opponent = null,Object? config = null,Object? currentRound = null,Object? history = null,Object? myScore = null,Object? opponentScore = null,Object? round = freezed,Object? result = freezed,}) {
  return _then(_LiveDuelSnapshot(
serverNow: null == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime,duelId: null == duelId ? _self.duelId : duelId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LiveDuelStatus,mySide: null == mySide ? _self.mySide : mySide // ignore: cast_nullable_to_non_nullable
as DuelSide,isRanked: null == isRanked ? _self.isRanked : isRanked // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DuelTopic,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as DuelPlayer,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as DuelPlayer,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as DuelConfig,currentRound: null == currentRound ? _self.currentRound : currentRound // ignore: cast_nullable_to_non_nullable
as int,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<DuelRoundRecord>,myScore: null == myScore ? _self.myScore : myScore // ignore: cast_nullable_to_non_nullable
as int,opponentScore: null == opponentScore ? _self.opponentScore : opponentScore // ignore: cast_nullable_to_non_nullable
as int,round: freezed == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as LiveDuelRoundState?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as LiveDuelOutcome?,
  ));
}

/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<$Res> get topic {
  
  return $DuelTopicCopyWith<$Res>(_self.topic, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get me {
  
  return $DuelPlayerCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get opponent {
  
  return $DuelPlayerCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelConfigCopyWith<$Res> get config {
  
  return $DuelConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveDuelRoundStateCopyWith<$Res>? get round {
    if (_self.round == null) {
    return null;
  }

  return $LiveDuelRoundStateCopyWith<$Res>(_self.round!, (value) {
    return _then(_self.copyWith(round: value));
  });
}/// Create a copy of LiveDuelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveDuelOutcomeCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $LiveDuelOutcomeCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
