// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelConfig {

 int get challengeTtlSeconds; int get cooldownSeconds; int get joinWindowSeconds; int get lobbyHeartbeatSeconds; int get mmHeartbeatSeconds; int get botAfterSeconds; int get bandStepSeconds; int get rounds; int get roundSeconds; int get revealSeconds; int get introSeconds; int get duelHeartbeatSeconds; int get rematchWindowSeconds; bool get presenceEnabled; int get winCoins;
/// Create a copy of DuelConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelConfigCopyWith<DuelConfig> get copyWith => _$DuelConfigCopyWithImpl<DuelConfig>(this as DuelConfig, _$identity);

  /// Serializes this DuelConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelConfig&&(identical(other.challengeTtlSeconds, challengeTtlSeconds) || other.challengeTtlSeconds == challengeTtlSeconds)&&(identical(other.cooldownSeconds, cooldownSeconds) || other.cooldownSeconds == cooldownSeconds)&&(identical(other.joinWindowSeconds, joinWindowSeconds) || other.joinWindowSeconds == joinWindowSeconds)&&(identical(other.lobbyHeartbeatSeconds, lobbyHeartbeatSeconds) || other.lobbyHeartbeatSeconds == lobbyHeartbeatSeconds)&&(identical(other.mmHeartbeatSeconds, mmHeartbeatSeconds) || other.mmHeartbeatSeconds == mmHeartbeatSeconds)&&(identical(other.botAfterSeconds, botAfterSeconds) || other.botAfterSeconds == botAfterSeconds)&&(identical(other.bandStepSeconds, bandStepSeconds) || other.bandStepSeconds == bandStepSeconds)&&(identical(other.rounds, rounds) || other.rounds == rounds)&&(identical(other.roundSeconds, roundSeconds) || other.roundSeconds == roundSeconds)&&(identical(other.revealSeconds, revealSeconds) || other.revealSeconds == revealSeconds)&&(identical(other.introSeconds, introSeconds) || other.introSeconds == introSeconds)&&(identical(other.duelHeartbeatSeconds, duelHeartbeatSeconds) || other.duelHeartbeatSeconds == duelHeartbeatSeconds)&&(identical(other.rematchWindowSeconds, rematchWindowSeconds) || other.rematchWindowSeconds == rematchWindowSeconds)&&(identical(other.presenceEnabled, presenceEnabled) || other.presenceEnabled == presenceEnabled)&&(identical(other.winCoins, winCoins) || other.winCoins == winCoins));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeTtlSeconds,cooldownSeconds,joinWindowSeconds,lobbyHeartbeatSeconds,mmHeartbeatSeconds,botAfterSeconds,bandStepSeconds,rounds,roundSeconds,revealSeconds,introSeconds,duelHeartbeatSeconds,rematchWindowSeconds,presenceEnabled,winCoins);

@override
String toString() {
  return 'DuelConfig(challengeTtlSeconds: $challengeTtlSeconds, cooldownSeconds: $cooldownSeconds, joinWindowSeconds: $joinWindowSeconds, lobbyHeartbeatSeconds: $lobbyHeartbeatSeconds, mmHeartbeatSeconds: $mmHeartbeatSeconds, botAfterSeconds: $botAfterSeconds, bandStepSeconds: $bandStepSeconds, rounds: $rounds, roundSeconds: $roundSeconds, revealSeconds: $revealSeconds, introSeconds: $introSeconds, duelHeartbeatSeconds: $duelHeartbeatSeconds, rematchWindowSeconds: $rematchWindowSeconds, presenceEnabled: $presenceEnabled, winCoins: $winCoins)';
}


}

/// @nodoc
abstract mixin class $DuelConfigCopyWith<$Res>  {
  factory $DuelConfigCopyWith(DuelConfig value, $Res Function(DuelConfig) _then) = _$DuelConfigCopyWithImpl;
@useResult
$Res call({
 int challengeTtlSeconds, int cooldownSeconds, int joinWindowSeconds, int lobbyHeartbeatSeconds, int mmHeartbeatSeconds, int botAfterSeconds, int bandStepSeconds, int rounds, int roundSeconds, int revealSeconds, int introSeconds, int duelHeartbeatSeconds, int rematchWindowSeconds, bool presenceEnabled, int winCoins
});




}
/// @nodoc
class _$DuelConfigCopyWithImpl<$Res>
    implements $DuelConfigCopyWith<$Res> {
  _$DuelConfigCopyWithImpl(this._self, this._then);

  final DuelConfig _self;
  final $Res Function(DuelConfig) _then;

/// Create a copy of DuelConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeTtlSeconds = null,Object? cooldownSeconds = null,Object? joinWindowSeconds = null,Object? lobbyHeartbeatSeconds = null,Object? mmHeartbeatSeconds = null,Object? botAfterSeconds = null,Object? bandStepSeconds = null,Object? rounds = null,Object? roundSeconds = null,Object? revealSeconds = null,Object? introSeconds = null,Object? duelHeartbeatSeconds = null,Object? rematchWindowSeconds = null,Object? presenceEnabled = null,Object? winCoins = null,}) {
  return _then(_self.copyWith(
challengeTtlSeconds: null == challengeTtlSeconds ? _self.challengeTtlSeconds : challengeTtlSeconds // ignore: cast_nullable_to_non_nullable
as int,cooldownSeconds: null == cooldownSeconds ? _self.cooldownSeconds : cooldownSeconds // ignore: cast_nullable_to_non_nullable
as int,joinWindowSeconds: null == joinWindowSeconds ? _self.joinWindowSeconds : joinWindowSeconds // ignore: cast_nullable_to_non_nullable
as int,lobbyHeartbeatSeconds: null == lobbyHeartbeatSeconds ? _self.lobbyHeartbeatSeconds : lobbyHeartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,mmHeartbeatSeconds: null == mmHeartbeatSeconds ? _self.mmHeartbeatSeconds : mmHeartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,botAfterSeconds: null == botAfterSeconds ? _self.botAfterSeconds : botAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,bandStepSeconds: null == bandStepSeconds ? _self.bandStepSeconds : bandStepSeconds // ignore: cast_nullable_to_non_nullable
as int,rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as int,roundSeconds: null == roundSeconds ? _self.roundSeconds : roundSeconds // ignore: cast_nullable_to_non_nullable
as int,revealSeconds: null == revealSeconds ? _self.revealSeconds : revealSeconds // ignore: cast_nullable_to_non_nullable
as int,introSeconds: null == introSeconds ? _self.introSeconds : introSeconds // ignore: cast_nullable_to_non_nullable
as int,duelHeartbeatSeconds: null == duelHeartbeatSeconds ? _self.duelHeartbeatSeconds : duelHeartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,rematchWindowSeconds: null == rematchWindowSeconds ? _self.rematchWindowSeconds : rematchWindowSeconds // ignore: cast_nullable_to_non_nullable
as int,presenceEnabled: null == presenceEnabled ? _self.presenceEnabled : presenceEnabled // ignore: cast_nullable_to_non_nullable
as bool,winCoins: null == winCoins ? _self.winCoins : winCoins // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelConfig].
extension DuelConfigPatterns on DuelConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelConfig value)  $default,){
final _that = this;
switch (_that) {
case _DuelConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DuelConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int challengeTtlSeconds,  int cooldownSeconds,  int joinWindowSeconds,  int lobbyHeartbeatSeconds,  int mmHeartbeatSeconds,  int botAfterSeconds,  int bandStepSeconds,  int rounds,  int roundSeconds,  int revealSeconds,  int introSeconds,  int duelHeartbeatSeconds,  int rematchWindowSeconds,  bool presenceEnabled,  int winCoins)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelConfig() when $default != null:
return $default(_that.challengeTtlSeconds,_that.cooldownSeconds,_that.joinWindowSeconds,_that.lobbyHeartbeatSeconds,_that.mmHeartbeatSeconds,_that.botAfterSeconds,_that.bandStepSeconds,_that.rounds,_that.roundSeconds,_that.revealSeconds,_that.introSeconds,_that.duelHeartbeatSeconds,_that.rematchWindowSeconds,_that.presenceEnabled,_that.winCoins);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int challengeTtlSeconds,  int cooldownSeconds,  int joinWindowSeconds,  int lobbyHeartbeatSeconds,  int mmHeartbeatSeconds,  int botAfterSeconds,  int bandStepSeconds,  int rounds,  int roundSeconds,  int revealSeconds,  int introSeconds,  int duelHeartbeatSeconds,  int rematchWindowSeconds,  bool presenceEnabled,  int winCoins)  $default,) {final _that = this;
switch (_that) {
case _DuelConfig():
return $default(_that.challengeTtlSeconds,_that.cooldownSeconds,_that.joinWindowSeconds,_that.lobbyHeartbeatSeconds,_that.mmHeartbeatSeconds,_that.botAfterSeconds,_that.bandStepSeconds,_that.rounds,_that.roundSeconds,_that.revealSeconds,_that.introSeconds,_that.duelHeartbeatSeconds,_that.rematchWindowSeconds,_that.presenceEnabled,_that.winCoins);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int challengeTtlSeconds,  int cooldownSeconds,  int joinWindowSeconds,  int lobbyHeartbeatSeconds,  int mmHeartbeatSeconds,  int botAfterSeconds,  int bandStepSeconds,  int rounds,  int roundSeconds,  int revealSeconds,  int introSeconds,  int duelHeartbeatSeconds,  int rematchWindowSeconds,  bool presenceEnabled,  int winCoins)?  $default,) {final _that = this;
switch (_that) {
case _DuelConfig() when $default != null:
return $default(_that.challengeTtlSeconds,_that.cooldownSeconds,_that.joinWindowSeconds,_that.lobbyHeartbeatSeconds,_that.mmHeartbeatSeconds,_that.botAfterSeconds,_that.bandStepSeconds,_that.rounds,_that.roundSeconds,_that.revealSeconds,_that.introSeconds,_that.duelHeartbeatSeconds,_that.rematchWindowSeconds,_that.presenceEnabled,_that.winCoins);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelConfig implements DuelConfig {
  const _DuelConfig({this.challengeTtlSeconds = 300, this.cooldownSeconds = 120, this.joinWindowSeconds = 5, this.lobbyHeartbeatSeconds = 10, this.mmHeartbeatSeconds = 3, this.botAfterSeconds = 30, this.bandStepSeconds = 5, this.rounds = 10, this.roundSeconds = 15, this.revealSeconds = 2, this.introSeconds = 3, this.duelHeartbeatSeconds = 5, this.rematchWindowSeconds = 30, this.presenceEnabled = true, this.winCoins = 200});
  factory _DuelConfig.fromJson(Map<String, dynamic> json) => _$DuelConfigFromJson(json);

@override@JsonKey() final  int challengeTtlSeconds;
@override@JsonKey() final  int cooldownSeconds;
@override@JsonKey() final  int joinWindowSeconds;
@override@JsonKey() final  int lobbyHeartbeatSeconds;
@override@JsonKey() final  int mmHeartbeatSeconds;
@override@JsonKey() final  int botAfterSeconds;
@override@JsonKey() final  int bandStepSeconds;
@override@JsonKey() final  int rounds;
@override@JsonKey() final  int roundSeconds;
@override@JsonKey() final  int revealSeconds;
@override@JsonKey() final  int introSeconds;
@override@JsonKey() final  int duelHeartbeatSeconds;
@override@JsonKey() final  int rematchWindowSeconds;
@override@JsonKey() final  bool presenceEnabled;
@override@JsonKey() final  int winCoins;

/// Create a copy of DuelConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelConfigCopyWith<_DuelConfig> get copyWith => __$DuelConfigCopyWithImpl<_DuelConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelConfig&&(identical(other.challengeTtlSeconds, challengeTtlSeconds) || other.challengeTtlSeconds == challengeTtlSeconds)&&(identical(other.cooldownSeconds, cooldownSeconds) || other.cooldownSeconds == cooldownSeconds)&&(identical(other.joinWindowSeconds, joinWindowSeconds) || other.joinWindowSeconds == joinWindowSeconds)&&(identical(other.lobbyHeartbeatSeconds, lobbyHeartbeatSeconds) || other.lobbyHeartbeatSeconds == lobbyHeartbeatSeconds)&&(identical(other.mmHeartbeatSeconds, mmHeartbeatSeconds) || other.mmHeartbeatSeconds == mmHeartbeatSeconds)&&(identical(other.botAfterSeconds, botAfterSeconds) || other.botAfterSeconds == botAfterSeconds)&&(identical(other.bandStepSeconds, bandStepSeconds) || other.bandStepSeconds == bandStepSeconds)&&(identical(other.rounds, rounds) || other.rounds == rounds)&&(identical(other.roundSeconds, roundSeconds) || other.roundSeconds == roundSeconds)&&(identical(other.revealSeconds, revealSeconds) || other.revealSeconds == revealSeconds)&&(identical(other.introSeconds, introSeconds) || other.introSeconds == introSeconds)&&(identical(other.duelHeartbeatSeconds, duelHeartbeatSeconds) || other.duelHeartbeatSeconds == duelHeartbeatSeconds)&&(identical(other.rematchWindowSeconds, rematchWindowSeconds) || other.rematchWindowSeconds == rematchWindowSeconds)&&(identical(other.presenceEnabled, presenceEnabled) || other.presenceEnabled == presenceEnabled)&&(identical(other.winCoins, winCoins) || other.winCoins == winCoins));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeTtlSeconds,cooldownSeconds,joinWindowSeconds,lobbyHeartbeatSeconds,mmHeartbeatSeconds,botAfterSeconds,bandStepSeconds,rounds,roundSeconds,revealSeconds,introSeconds,duelHeartbeatSeconds,rematchWindowSeconds,presenceEnabled,winCoins);

@override
String toString() {
  return 'DuelConfig(challengeTtlSeconds: $challengeTtlSeconds, cooldownSeconds: $cooldownSeconds, joinWindowSeconds: $joinWindowSeconds, lobbyHeartbeatSeconds: $lobbyHeartbeatSeconds, mmHeartbeatSeconds: $mmHeartbeatSeconds, botAfterSeconds: $botAfterSeconds, bandStepSeconds: $bandStepSeconds, rounds: $rounds, roundSeconds: $roundSeconds, revealSeconds: $revealSeconds, introSeconds: $introSeconds, duelHeartbeatSeconds: $duelHeartbeatSeconds, rematchWindowSeconds: $rematchWindowSeconds, presenceEnabled: $presenceEnabled, winCoins: $winCoins)';
}


}

/// @nodoc
abstract mixin class _$DuelConfigCopyWith<$Res> implements $DuelConfigCopyWith<$Res> {
  factory _$DuelConfigCopyWith(_DuelConfig value, $Res Function(_DuelConfig) _then) = __$DuelConfigCopyWithImpl;
@override @useResult
$Res call({
 int challengeTtlSeconds, int cooldownSeconds, int joinWindowSeconds, int lobbyHeartbeatSeconds, int mmHeartbeatSeconds, int botAfterSeconds, int bandStepSeconds, int rounds, int roundSeconds, int revealSeconds, int introSeconds, int duelHeartbeatSeconds, int rematchWindowSeconds, bool presenceEnabled, int winCoins
});




}
/// @nodoc
class __$DuelConfigCopyWithImpl<$Res>
    implements _$DuelConfigCopyWith<$Res> {
  __$DuelConfigCopyWithImpl(this._self, this._then);

  final _DuelConfig _self;
  final $Res Function(_DuelConfig) _then;

/// Create a copy of DuelConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeTtlSeconds = null,Object? cooldownSeconds = null,Object? joinWindowSeconds = null,Object? lobbyHeartbeatSeconds = null,Object? mmHeartbeatSeconds = null,Object? botAfterSeconds = null,Object? bandStepSeconds = null,Object? rounds = null,Object? roundSeconds = null,Object? revealSeconds = null,Object? introSeconds = null,Object? duelHeartbeatSeconds = null,Object? rematchWindowSeconds = null,Object? presenceEnabled = null,Object? winCoins = null,}) {
  return _then(_DuelConfig(
challengeTtlSeconds: null == challengeTtlSeconds ? _self.challengeTtlSeconds : challengeTtlSeconds // ignore: cast_nullable_to_non_nullable
as int,cooldownSeconds: null == cooldownSeconds ? _self.cooldownSeconds : cooldownSeconds // ignore: cast_nullable_to_non_nullable
as int,joinWindowSeconds: null == joinWindowSeconds ? _self.joinWindowSeconds : joinWindowSeconds // ignore: cast_nullable_to_non_nullable
as int,lobbyHeartbeatSeconds: null == lobbyHeartbeatSeconds ? _self.lobbyHeartbeatSeconds : lobbyHeartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,mmHeartbeatSeconds: null == mmHeartbeatSeconds ? _self.mmHeartbeatSeconds : mmHeartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,botAfterSeconds: null == botAfterSeconds ? _self.botAfterSeconds : botAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,bandStepSeconds: null == bandStepSeconds ? _self.bandStepSeconds : bandStepSeconds // ignore: cast_nullable_to_non_nullable
as int,rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as int,roundSeconds: null == roundSeconds ? _self.roundSeconds : roundSeconds // ignore: cast_nullable_to_non_nullable
as int,revealSeconds: null == revealSeconds ? _self.revealSeconds : revealSeconds // ignore: cast_nullable_to_non_nullable
as int,introSeconds: null == introSeconds ? _self.introSeconds : introSeconds // ignore: cast_nullable_to_non_nullable
as int,duelHeartbeatSeconds: null == duelHeartbeatSeconds ? _self.duelHeartbeatSeconds : duelHeartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,rematchWindowSeconds: null == rematchWindowSeconds ? _self.rematchWindowSeconds : rematchWindowSeconds // ignore: cast_nullable_to_non_nullable
as int,presenceEnabled: null == presenceEnabled ? _self.presenceEnabled : presenceEnabled // ignore: cast_nullable_to_non_nullable
as bool,winCoins: null == winCoins ? _self.winCoins : winCoins // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
