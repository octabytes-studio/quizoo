// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelPlayer {

 String get id; String? get name;@JsonKey(name: 'avatar') String get avatarEmoji; int get elo; bool get isGuest; String? get guestTag; String get league; int get topicLevel; bool get isBot;
/// Create a copy of DuelPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelPlayerCopyWith<DuelPlayer> get copyWith => _$DuelPlayerCopyWithImpl<DuelPlayer>(this as DuelPlayer, _$identity);

  /// Serializes this DuelPlayer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelPlayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.elo, elo) || other.elo == elo)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.guestTag, guestTag) || other.guestTag == guestTag)&&(identical(other.league, league) || other.league == league)&&(identical(other.topicLevel, topicLevel) || other.topicLevel == topicLevel)&&(identical(other.isBot, isBot) || other.isBot == isBot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarEmoji,elo,isGuest,guestTag,league,topicLevel,isBot);

@override
String toString() {
  return 'DuelPlayer(id: $id, name: $name, avatarEmoji: $avatarEmoji, elo: $elo, isGuest: $isGuest, guestTag: $guestTag, league: $league, topicLevel: $topicLevel, isBot: $isBot)';
}


}

/// @nodoc
abstract mixin class $DuelPlayerCopyWith<$Res>  {
  factory $DuelPlayerCopyWith(DuelPlayer value, $Res Function(DuelPlayer) _then) = _$DuelPlayerCopyWithImpl;
@useResult
$Res call({
 String id, String? name,@JsonKey(name: 'avatar') String avatarEmoji, int elo, bool isGuest, String? guestTag, String league, int topicLevel, bool isBot
});




}
/// @nodoc
class _$DuelPlayerCopyWithImpl<$Res>
    implements $DuelPlayerCopyWith<$Res> {
  _$DuelPlayerCopyWithImpl(this._self, this._then);

  final DuelPlayer _self;
  final $Res Function(DuelPlayer) _then;

/// Create a copy of DuelPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? avatarEmoji = null,Object? elo = null,Object? isGuest = null,Object? guestTag = freezed,Object? league = null,Object? topicLevel = null,Object? isBot = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,elo: null == elo ? _self.elo : elo // ignore: cast_nullable_to_non_nullable
as int,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,guestTag: freezed == guestTag ? _self.guestTag : guestTag // ignore: cast_nullable_to_non_nullable
as String?,league: null == league ? _self.league : league // ignore: cast_nullable_to_non_nullable
as String,topicLevel: null == topicLevel ? _self.topicLevel : topicLevel // ignore: cast_nullable_to_non_nullable
as int,isBot: null == isBot ? _self.isBot : isBot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelPlayer].
extension DuelPlayerPatterns on DuelPlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelPlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelPlayer value)  $default,){
final _that = this;
switch (_that) {
case _DuelPlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _DuelPlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name, @JsonKey(name: 'avatar')  String avatarEmoji,  int elo,  bool isGuest,  String? guestTag,  String league,  int topicLevel,  bool isBot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelPlayer() when $default != null:
return $default(_that.id,_that.name,_that.avatarEmoji,_that.elo,_that.isGuest,_that.guestTag,_that.league,_that.topicLevel,_that.isBot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name, @JsonKey(name: 'avatar')  String avatarEmoji,  int elo,  bool isGuest,  String? guestTag,  String league,  int topicLevel,  bool isBot)  $default,) {final _that = this;
switch (_that) {
case _DuelPlayer():
return $default(_that.id,_that.name,_that.avatarEmoji,_that.elo,_that.isGuest,_that.guestTag,_that.league,_that.topicLevel,_that.isBot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name, @JsonKey(name: 'avatar')  String avatarEmoji,  int elo,  bool isGuest,  String? guestTag,  String league,  int topicLevel,  bool isBot)?  $default,) {final _that = this;
switch (_that) {
case _DuelPlayer() when $default != null:
return $default(_that.id,_that.name,_that.avatarEmoji,_that.elo,_that.isGuest,_that.guestTag,_that.league,_that.topicLevel,_that.isBot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelPlayer extends DuelPlayer {
  const _DuelPlayer({required this.id, required this.name, @JsonKey(name: 'avatar') required this.avatarEmoji, required this.elo, this.isGuest = false, this.guestTag, this.league = 'bronze', this.topicLevel = 0, this.isBot = false}): super._();
  factory _DuelPlayer.fromJson(Map<String, dynamic> json) => _$DuelPlayerFromJson(json);

@override final  String id;
@override final  String? name;
@override@JsonKey(name: 'avatar') final  String avatarEmoji;
@override final  int elo;
@override@JsonKey() final  bool isGuest;
@override final  String? guestTag;
@override@JsonKey() final  String league;
@override@JsonKey() final  int topicLevel;
@override@JsonKey() final  bool isBot;

/// Create a copy of DuelPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelPlayerCopyWith<_DuelPlayer> get copyWith => __$DuelPlayerCopyWithImpl<_DuelPlayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelPlayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelPlayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.elo, elo) || other.elo == elo)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.guestTag, guestTag) || other.guestTag == guestTag)&&(identical(other.league, league) || other.league == league)&&(identical(other.topicLevel, topicLevel) || other.topicLevel == topicLevel)&&(identical(other.isBot, isBot) || other.isBot == isBot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarEmoji,elo,isGuest,guestTag,league,topicLevel,isBot);

@override
String toString() {
  return 'DuelPlayer(id: $id, name: $name, avatarEmoji: $avatarEmoji, elo: $elo, isGuest: $isGuest, guestTag: $guestTag, league: $league, topicLevel: $topicLevel, isBot: $isBot)';
}


}

/// @nodoc
abstract mixin class _$DuelPlayerCopyWith<$Res> implements $DuelPlayerCopyWith<$Res> {
  factory _$DuelPlayerCopyWith(_DuelPlayer value, $Res Function(_DuelPlayer) _then) = __$DuelPlayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name,@JsonKey(name: 'avatar') String avatarEmoji, int elo, bool isGuest, String? guestTag, String league, int topicLevel, bool isBot
});




}
/// @nodoc
class __$DuelPlayerCopyWithImpl<$Res>
    implements _$DuelPlayerCopyWith<$Res> {
  __$DuelPlayerCopyWithImpl(this._self, this._then);

  final _DuelPlayer _self;
  final $Res Function(_DuelPlayer) _then;

/// Create a copy of DuelPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? avatarEmoji = null,Object? elo = null,Object? isGuest = null,Object? guestTag = freezed,Object? league = null,Object? topicLevel = null,Object? isBot = null,}) {
  return _then(_DuelPlayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,elo: null == elo ? _self.elo : elo // ignore: cast_nullable_to_non_nullable
as int,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,guestTag: freezed == guestTag ? _self.guestTag : guestTag // ignore: cast_nullable_to_non_nullable
as String?,league: null == league ? _self.league : league // ignore: cast_nullable_to_non_nullable
as String,topicLevel: null == topicLevel ? _self.topicLevel : topicLevel // ignore: cast_nullable_to_non_nullable
as int,isBot: null == isBot ? _self.isBot : isBot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
