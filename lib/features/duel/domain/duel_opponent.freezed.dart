// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_opponent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelOpponent {

 String get id; String get name; String get avatarEmoji; int get elo; bool get isBot;
/// Create a copy of DuelOpponent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelOpponentCopyWith<DuelOpponent> get copyWith => _$DuelOpponentCopyWithImpl<DuelOpponent>(this as DuelOpponent, _$identity);

  /// Serializes this DuelOpponent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelOpponent&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.elo, elo) || other.elo == elo)&&(identical(other.isBot, isBot) || other.isBot == isBot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarEmoji,elo,isBot);

@override
String toString() {
  return 'DuelOpponent(id: $id, name: $name, avatarEmoji: $avatarEmoji, elo: $elo, isBot: $isBot)';
}


}

/// @nodoc
abstract mixin class $DuelOpponentCopyWith<$Res>  {
  factory $DuelOpponentCopyWith(DuelOpponent value, $Res Function(DuelOpponent) _then) = _$DuelOpponentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String avatarEmoji, int elo, bool isBot
});




}
/// @nodoc
class _$DuelOpponentCopyWithImpl<$Res>
    implements $DuelOpponentCopyWith<$Res> {
  _$DuelOpponentCopyWithImpl(this._self, this._then);

  final DuelOpponent _self;
  final $Res Function(DuelOpponent) _then;

/// Create a copy of DuelOpponent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatarEmoji = null,Object? elo = null,Object? isBot = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,elo: null == elo ? _self.elo : elo // ignore: cast_nullable_to_non_nullable
as int,isBot: null == isBot ? _self.isBot : isBot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelOpponent].
extension DuelOpponentPatterns on DuelOpponent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelOpponent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelOpponent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelOpponent value)  $default,){
final _that = this;
switch (_that) {
case _DuelOpponent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelOpponent value)?  $default,){
final _that = this;
switch (_that) {
case _DuelOpponent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String avatarEmoji,  int elo,  bool isBot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelOpponent() when $default != null:
return $default(_that.id,_that.name,_that.avatarEmoji,_that.elo,_that.isBot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String avatarEmoji,  int elo,  bool isBot)  $default,) {final _that = this;
switch (_that) {
case _DuelOpponent():
return $default(_that.id,_that.name,_that.avatarEmoji,_that.elo,_that.isBot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String avatarEmoji,  int elo,  bool isBot)?  $default,) {final _that = this;
switch (_that) {
case _DuelOpponent() when $default != null:
return $default(_that.id,_that.name,_that.avatarEmoji,_that.elo,_that.isBot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelOpponent extends DuelOpponent {
  const _DuelOpponent({required this.id, required this.name, required this.avatarEmoji, required this.elo, this.isBot = true}): super._();
  factory _DuelOpponent.fromJson(Map<String, dynamic> json) => _$DuelOpponentFromJson(json);

@override final  String id;
@override final  String name;
@override final  String avatarEmoji;
@override final  int elo;
@override@JsonKey() final  bool isBot;

/// Create a copy of DuelOpponent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelOpponentCopyWith<_DuelOpponent> get copyWith => __$DuelOpponentCopyWithImpl<_DuelOpponent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelOpponentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelOpponent&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.elo, elo) || other.elo == elo)&&(identical(other.isBot, isBot) || other.isBot == isBot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarEmoji,elo,isBot);

@override
String toString() {
  return 'DuelOpponent(id: $id, name: $name, avatarEmoji: $avatarEmoji, elo: $elo, isBot: $isBot)';
}


}

/// @nodoc
abstract mixin class _$DuelOpponentCopyWith<$Res> implements $DuelOpponentCopyWith<$Res> {
  factory _$DuelOpponentCopyWith(_DuelOpponent value, $Res Function(_DuelOpponent) _then) = __$DuelOpponentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String avatarEmoji, int elo, bool isBot
});




}
/// @nodoc
class __$DuelOpponentCopyWithImpl<$Res>
    implements _$DuelOpponentCopyWith<$Res> {
  __$DuelOpponentCopyWithImpl(this._self, this._then);

  final _DuelOpponent _self;
  final $Res Function(_DuelOpponent) _then;

/// Create a copy of DuelOpponent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarEmoji = null,Object? elo = null,Object? isBot = null,}) {
  return _then(_DuelOpponent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,elo: null == elo ? _self.elo : elo // ignore: cast_nullable_to_non_nullable
as int,isBot: null == isBot ? _self.isBot : isBot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
