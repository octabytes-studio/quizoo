// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelResult {

 DuelPlayer get me; DuelPlayer get opponent; int get playerRoundsWon; int get opponentRoundsWon; double get playerAverageAnswerSeconds; double get opponentAverageAnswerSeconds; int get eloBefore; int get eloAfter; int get rewardCoins; List<String> get newlyEarnedBadgeIds; String? get duelId; bool get isBot; DuelTopic? get topic; bool get isRanked; int get xpEarned; DuelEndReason get endReason;
/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelResultCopyWith<DuelResult> get copyWith => _$DuelResultCopyWithImpl<DuelResult>(this as DuelResult, _$identity);

  /// Serializes this DuelResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelResult&&(identical(other.me, me) || other.me == me)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.playerRoundsWon, playerRoundsWon) || other.playerRoundsWon == playerRoundsWon)&&(identical(other.opponentRoundsWon, opponentRoundsWon) || other.opponentRoundsWon == opponentRoundsWon)&&(identical(other.playerAverageAnswerSeconds, playerAverageAnswerSeconds) || other.playerAverageAnswerSeconds == playerAverageAnswerSeconds)&&(identical(other.opponentAverageAnswerSeconds, opponentAverageAnswerSeconds) || other.opponentAverageAnswerSeconds == opponentAverageAnswerSeconds)&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.rewardCoins, rewardCoins) || other.rewardCoins == rewardCoins)&&const DeepCollectionEquality().equals(other.newlyEarnedBadgeIds, newlyEarnedBadgeIds)&&(identical(other.duelId, duelId) || other.duelId == duelId)&&(identical(other.isBot, isBot) || other.isBot == isBot)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.isRanked, isRanked) || other.isRanked == isRanked)&&(identical(other.xpEarned, xpEarned) || other.xpEarned == xpEarned)&&(identical(other.endReason, endReason) || other.endReason == endReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,me,opponent,playerRoundsWon,opponentRoundsWon,playerAverageAnswerSeconds,opponentAverageAnswerSeconds,eloBefore,eloAfter,rewardCoins,const DeepCollectionEquality().hash(newlyEarnedBadgeIds),duelId,isBot,topic,isRanked,xpEarned,endReason);

@override
String toString() {
  return 'DuelResult(me: $me, opponent: $opponent, playerRoundsWon: $playerRoundsWon, opponentRoundsWon: $opponentRoundsWon, playerAverageAnswerSeconds: $playerAverageAnswerSeconds, opponentAverageAnswerSeconds: $opponentAverageAnswerSeconds, eloBefore: $eloBefore, eloAfter: $eloAfter, rewardCoins: $rewardCoins, newlyEarnedBadgeIds: $newlyEarnedBadgeIds, duelId: $duelId, isBot: $isBot, topic: $topic, isRanked: $isRanked, xpEarned: $xpEarned, endReason: $endReason)';
}


}

/// @nodoc
abstract mixin class $DuelResultCopyWith<$Res>  {
  factory $DuelResultCopyWith(DuelResult value, $Res Function(DuelResult) _then) = _$DuelResultCopyWithImpl;
@useResult
$Res call({
 DuelPlayer me, DuelPlayer opponent, int playerRoundsWon, int opponentRoundsWon, double playerAverageAnswerSeconds, double opponentAverageAnswerSeconds, int eloBefore, int eloAfter, int rewardCoins, List<String> newlyEarnedBadgeIds, String? duelId, bool isBot, DuelTopic? topic, bool isRanked, int xpEarned, DuelEndReason endReason
});


$DuelPlayerCopyWith<$Res> get me;$DuelPlayerCopyWith<$Res> get opponent;$DuelTopicCopyWith<$Res>? get topic;

}
/// @nodoc
class _$DuelResultCopyWithImpl<$Res>
    implements $DuelResultCopyWith<$Res> {
  _$DuelResultCopyWithImpl(this._self, this._then);

  final DuelResult _self;
  final $Res Function(DuelResult) _then;

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? me = null,Object? opponent = null,Object? playerRoundsWon = null,Object? opponentRoundsWon = null,Object? playerAverageAnswerSeconds = null,Object? opponentAverageAnswerSeconds = null,Object? eloBefore = null,Object? eloAfter = null,Object? rewardCoins = null,Object? newlyEarnedBadgeIds = null,Object? duelId = freezed,Object? isBot = null,Object? topic = freezed,Object? isRanked = null,Object? xpEarned = null,Object? endReason = null,}) {
  return _then(_self.copyWith(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as DuelPlayer,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as DuelPlayer,playerRoundsWon: null == playerRoundsWon ? _self.playerRoundsWon : playerRoundsWon // ignore: cast_nullable_to_non_nullable
as int,opponentRoundsWon: null == opponentRoundsWon ? _self.opponentRoundsWon : opponentRoundsWon // ignore: cast_nullable_to_non_nullable
as int,playerAverageAnswerSeconds: null == playerAverageAnswerSeconds ? _self.playerAverageAnswerSeconds : playerAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,opponentAverageAnswerSeconds: null == opponentAverageAnswerSeconds ? _self.opponentAverageAnswerSeconds : opponentAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,rewardCoins: null == rewardCoins ? _self.rewardCoins : rewardCoins // ignore: cast_nullable_to_non_nullable
as int,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self.newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,duelId: freezed == duelId ? _self.duelId : duelId // ignore: cast_nullable_to_non_nullable
as String?,isBot: null == isBot ? _self.isBot : isBot // ignore: cast_nullable_to_non_nullable
as bool,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DuelTopic?,isRanked: null == isRanked ? _self.isRanked : isRanked // ignore: cast_nullable_to_non_nullable
as bool,xpEarned: null == xpEarned ? _self.xpEarned : xpEarned // ignore: cast_nullable_to_non_nullable
as int,endReason: null == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as DuelEndReason,
  ));
}
/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get me {
  
  return $DuelPlayerCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get opponent {
  
  return $DuelPlayerCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $DuelTopicCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}
}


/// Adds pattern-matching-related methods to [DuelResult].
extension DuelResultPatterns on DuelResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelResult value)  $default,){
final _that = this;
switch (_that) {
case _DuelResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelResult value)?  $default,){
final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DuelPlayer me,  DuelPlayer opponent,  int playerRoundsWon,  int opponentRoundsWon,  double playerAverageAnswerSeconds,  double opponentAverageAnswerSeconds,  int eloBefore,  int eloAfter,  int rewardCoins,  List<String> newlyEarnedBadgeIds,  String? duelId,  bool isBot,  DuelTopic? topic,  bool isRanked,  int xpEarned,  DuelEndReason endReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
return $default(_that.me,_that.opponent,_that.playerRoundsWon,_that.opponentRoundsWon,_that.playerAverageAnswerSeconds,_that.opponentAverageAnswerSeconds,_that.eloBefore,_that.eloAfter,_that.rewardCoins,_that.newlyEarnedBadgeIds,_that.duelId,_that.isBot,_that.topic,_that.isRanked,_that.xpEarned,_that.endReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DuelPlayer me,  DuelPlayer opponent,  int playerRoundsWon,  int opponentRoundsWon,  double playerAverageAnswerSeconds,  double opponentAverageAnswerSeconds,  int eloBefore,  int eloAfter,  int rewardCoins,  List<String> newlyEarnedBadgeIds,  String? duelId,  bool isBot,  DuelTopic? topic,  bool isRanked,  int xpEarned,  DuelEndReason endReason)  $default,) {final _that = this;
switch (_that) {
case _DuelResult():
return $default(_that.me,_that.opponent,_that.playerRoundsWon,_that.opponentRoundsWon,_that.playerAverageAnswerSeconds,_that.opponentAverageAnswerSeconds,_that.eloBefore,_that.eloAfter,_that.rewardCoins,_that.newlyEarnedBadgeIds,_that.duelId,_that.isBot,_that.topic,_that.isRanked,_that.xpEarned,_that.endReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DuelPlayer me,  DuelPlayer opponent,  int playerRoundsWon,  int opponentRoundsWon,  double playerAverageAnswerSeconds,  double opponentAverageAnswerSeconds,  int eloBefore,  int eloAfter,  int rewardCoins,  List<String> newlyEarnedBadgeIds,  String? duelId,  bool isBot,  DuelTopic? topic,  bool isRanked,  int xpEarned,  DuelEndReason endReason)?  $default,) {final _that = this;
switch (_that) {
case _DuelResult() when $default != null:
return $default(_that.me,_that.opponent,_that.playerRoundsWon,_that.opponentRoundsWon,_that.playerAverageAnswerSeconds,_that.opponentAverageAnswerSeconds,_that.eloBefore,_that.eloAfter,_that.rewardCoins,_that.newlyEarnedBadgeIds,_that.duelId,_that.isBot,_that.topic,_that.isRanked,_that.xpEarned,_that.endReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelResult extends DuelResult {
  const _DuelResult({required this.me, required this.opponent, required this.playerRoundsWon, required this.opponentRoundsWon, required this.playerAverageAnswerSeconds, required this.opponentAverageAnswerSeconds, required this.eloBefore, required this.eloAfter, required this.rewardCoins, final  List<String> newlyEarnedBadgeIds = const [], this.duelId, this.isBot = true, this.topic, this.isRanked = true, this.xpEarned = 0, this.endReason = DuelEndReason.completed}): _newlyEarnedBadgeIds = newlyEarnedBadgeIds,super._();
  factory _DuelResult.fromJson(Map<String, dynamic> json) => _$DuelResultFromJson(json);

@override final  DuelPlayer me;
@override final  DuelPlayer opponent;
@override final  int playerRoundsWon;
@override final  int opponentRoundsWon;
@override final  double playerAverageAnswerSeconds;
@override final  double opponentAverageAnswerSeconds;
@override final  int eloBefore;
@override final  int eloAfter;
@override final  int rewardCoins;
 final  List<String> _newlyEarnedBadgeIds;
@override@JsonKey() List<String> get newlyEarnedBadgeIds {
  if (_newlyEarnedBadgeIds is EqualUnmodifiableListView) return _newlyEarnedBadgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newlyEarnedBadgeIds);
}

@override final  String? duelId;
@override@JsonKey() final  bool isBot;
@override final  DuelTopic? topic;
@override@JsonKey() final  bool isRanked;
@override@JsonKey() final  int xpEarned;
@override@JsonKey() final  DuelEndReason endReason;

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelResultCopyWith<_DuelResult> get copyWith => __$DuelResultCopyWithImpl<_DuelResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelResult&&(identical(other.me, me) || other.me == me)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.playerRoundsWon, playerRoundsWon) || other.playerRoundsWon == playerRoundsWon)&&(identical(other.opponentRoundsWon, opponentRoundsWon) || other.opponentRoundsWon == opponentRoundsWon)&&(identical(other.playerAverageAnswerSeconds, playerAverageAnswerSeconds) || other.playerAverageAnswerSeconds == playerAverageAnswerSeconds)&&(identical(other.opponentAverageAnswerSeconds, opponentAverageAnswerSeconds) || other.opponentAverageAnswerSeconds == opponentAverageAnswerSeconds)&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.rewardCoins, rewardCoins) || other.rewardCoins == rewardCoins)&&const DeepCollectionEquality().equals(other._newlyEarnedBadgeIds, _newlyEarnedBadgeIds)&&(identical(other.duelId, duelId) || other.duelId == duelId)&&(identical(other.isBot, isBot) || other.isBot == isBot)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.isRanked, isRanked) || other.isRanked == isRanked)&&(identical(other.xpEarned, xpEarned) || other.xpEarned == xpEarned)&&(identical(other.endReason, endReason) || other.endReason == endReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,me,opponent,playerRoundsWon,opponentRoundsWon,playerAverageAnswerSeconds,opponentAverageAnswerSeconds,eloBefore,eloAfter,rewardCoins,const DeepCollectionEquality().hash(_newlyEarnedBadgeIds),duelId,isBot,topic,isRanked,xpEarned,endReason);

@override
String toString() {
  return 'DuelResult(me: $me, opponent: $opponent, playerRoundsWon: $playerRoundsWon, opponentRoundsWon: $opponentRoundsWon, playerAverageAnswerSeconds: $playerAverageAnswerSeconds, opponentAverageAnswerSeconds: $opponentAverageAnswerSeconds, eloBefore: $eloBefore, eloAfter: $eloAfter, rewardCoins: $rewardCoins, newlyEarnedBadgeIds: $newlyEarnedBadgeIds, duelId: $duelId, isBot: $isBot, topic: $topic, isRanked: $isRanked, xpEarned: $xpEarned, endReason: $endReason)';
}


}

/// @nodoc
abstract mixin class _$DuelResultCopyWith<$Res> implements $DuelResultCopyWith<$Res> {
  factory _$DuelResultCopyWith(_DuelResult value, $Res Function(_DuelResult) _then) = __$DuelResultCopyWithImpl;
@override @useResult
$Res call({
 DuelPlayer me, DuelPlayer opponent, int playerRoundsWon, int opponentRoundsWon, double playerAverageAnswerSeconds, double opponentAverageAnswerSeconds, int eloBefore, int eloAfter, int rewardCoins, List<String> newlyEarnedBadgeIds, String? duelId, bool isBot, DuelTopic? topic, bool isRanked, int xpEarned, DuelEndReason endReason
});


@override $DuelPlayerCopyWith<$Res> get me;@override $DuelPlayerCopyWith<$Res> get opponent;@override $DuelTopicCopyWith<$Res>? get topic;

}
/// @nodoc
class __$DuelResultCopyWithImpl<$Res>
    implements _$DuelResultCopyWith<$Res> {
  __$DuelResultCopyWithImpl(this._self, this._then);

  final _DuelResult _self;
  final $Res Function(_DuelResult) _then;

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? me = null,Object? opponent = null,Object? playerRoundsWon = null,Object? opponentRoundsWon = null,Object? playerAverageAnswerSeconds = null,Object? opponentAverageAnswerSeconds = null,Object? eloBefore = null,Object? eloAfter = null,Object? rewardCoins = null,Object? newlyEarnedBadgeIds = null,Object? duelId = freezed,Object? isBot = null,Object? topic = freezed,Object? isRanked = null,Object? xpEarned = null,Object? endReason = null,}) {
  return _then(_DuelResult(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as DuelPlayer,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as DuelPlayer,playerRoundsWon: null == playerRoundsWon ? _self.playerRoundsWon : playerRoundsWon // ignore: cast_nullable_to_non_nullable
as int,opponentRoundsWon: null == opponentRoundsWon ? _self.opponentRoundsWon : opponentRoundsWon // ignore: cast_nullable_to_non_nullable
as int,playerAverageAnswerSeconds: null == playerAverageAnswerSeconds ? _self.playerAverageAnswerSeconds : playerAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,opponentAverageAnswerSeconds: null == opponentAverageAnswerSeconds ? _self.opponentAverageAnswerSeconds : opponentAverageAnswerSeconds // ignore: cast_nullable_to_non_nullable
as double,eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,rewardCoins: null == rewardCoins ? _self.rewardCoins : rewardCoins // ignore: cast_nullable_to_non_nullable
as int,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self._newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,duelId: freezed == duelId ? _self.duelId : duelId // ignore: cast_nullable_to_non_nullable
as String?,isBot: null == isBot ? _self.isBot : isBot // ignore: cast_nullable_to_non_nullable
as bool,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DuelTopic?,isRanked: null == isRanked ? _self.isRanked : isRanked // ignore: cast_nullable_to_non_nullable
as bool,xpEarned: null == xpEarned ? _self.xpEarned : xpEarned // ignore: cast_nullable_to_non_nullable
as int,endReason: null == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as DuelEndReason,
  ));
}

/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get me {
  
  return $DuelPlayerCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<$Res> get opponent {
  
  return $DuelPlayerCopyWith<$Res>(_self.opponent, (value) {
    return _then(_self.copyWith(opponent: value));
  });
}/// Create a copy of DuelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuelTopicCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $DuelTopicCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}
}

// dart format on
