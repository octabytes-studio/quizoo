// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_currency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerCurrency {

/// Lemon pill. Buys power-ups.
 int get coins;/// Sky pill. Premium currency.
 int get gems;/// Raspberry pill. Spent on a failed level, refilled on a timer.
 int get hearts; int get maxHearts;/// When the next heart returns. Null when the player is already full.
 DateTime? get heartRefillAt;
/// Create a copy of PlayerCurrency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerCurrencyCopyWith<PlayerCurrency> get copyWith => _$PlayerCurrencyCopyWithImpl<PlayerCurrency>(this as PlayerCurrency, _$identity);

  /// Serializes this PlayerCurrency to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerCurrency&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.gems, gems) || other.gems == gems)&&(identical(other.hearts, hearts) || other.hearts == hearts)&&(identical(other.maxHearts, maxHearts) || other.maxHearts == maxHearts)&&(identical(other.heartRefillAt, heartRefillAt) || other.heartRefillAt == heartRefillAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,coins,gems,hearts,maxHearts,heartRefillAt);

@override
String toString() {
  return 'PlayerCurrency(coins: $coins, gems: $gems, hearts: $hearts, maxHearts: $maxHearts, heartRefillAt: $heartRefillAt)';
}


}

/// @nodoc
abstract mixin class $PlayerCurrencyCopyWith<$Res>  {
  factory $PlayerCurrencyCopyWith(PlayerCurrency value, $Res Function(PlayerCurrency) _then) = _$PlayerCurrencyCopyWithImpl;
@useResult
$Res call({
 int coins, int gems, int hearts, int maxHearts, DateTime? heartRefillAt
});




}
/// @nodoc
class _$PlayerCurrencyCopyWithImpl<$Res>
    implements $PlayerCurrencyCopyWith<$Res> {
  _$PlayerCurrencyCopyWithImpl(this._self, this._then);

  final PlayerCurrency _self;
  final $Res Function(PlayerCurrency) _then;

/// Create a copy of PlayerCurrency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coins = null,Object? gems = null,Object? hearts = null,Object? maxHearts = null,Object? heartRefillAt = freezed,}) {
  return _then(_self.copyWith(
coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,gems: null == gems ? _self.gems : gems // ignore: cast_nullable_to_non_nullable
as int,hearts: null == hearts ? _self.hearts : hearts // ignore: cast_nullable_to_non_nullable
as int,maxHearts: null == maxHearts ? _self.maxHearts : maxHearts // ignore: cast_nullable_to_non_nullable
as int,heartRefillAt: freezed == heartRefillAt ? _self.heartRefillAt : heartRefillAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerCurrency].
extension PlayerCurrencyPatterns on PlayerCurrency {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerCurrency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerCurrency() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerCurrency value)  $default,){
final _that = this;
switch (_that) {
case _PlayerCurrency():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerCurrency value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerCurrency() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int coins,  int gems,  int hearts,  int maxHearts,  DateTime? heartRefillAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerCurrency() when $default != null:
return $default(_that.coins,_that.gems,_that.hearts,_that.maxHearts,_that.heartRefillAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int coins,  int gems,  int hearts,  int maxHearts,  DateTime? heartRefillAt)  $default,) {final _that = this;
switch (_that) {
case _PlayerCurrency():
return $default(_that.coins,_that.gems,_that.hearts,_that.maxHearts,_that.heartRefillAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int coins,  int gems,  int hearts,  int maxHearts,  DateTime? heartRefillAt)?  $default,) {final _that = this;
switch (_that) {
case _PlayerCurrency() when $default != null:
return $default(_that.coins,_that.gems,_that.hearts,_that.maxHearts,_that.heartRefillAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerCurrency extends PlayerCurrency {
  const _PlayerCurrency({this.coins = 0, this.gems = 0, this.hearts = 5, this.maxHearts = 5, this.heartRefillAt}): super._();
  factory _PlayerCurrency.fromJson(Map<String, dynamic> json) => _$PlayerCurrencyFromJson(json);

/// Lemon pill. Buys power-ups.
@override@JsonKey() final  int coins;
/// Sky pill. Premium currency.
@override@JsonKey() final  int gems;
/// Raspberry pill. Spent on a failed level, refilled on a timer.
@override@JsonKey() final  int hearts;
@override@JsonKey() final  int maxHearts;
/// When the next heart returns. Null when the player is already full.
@override final  DateTime? heartRefillAt;

/// Create a copy of PlayerCurrency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerCurrencyCopyWith<_PlayerCurrency> get copyWith => __$PlayerCurrencyCopyWithImpl<_PlayerCurrency>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerCurrencyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerCurrency&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.gems, gems) || other.gems == gems)&&(identical(other.hearts, hearts) || other.hearts == hearts)&&(identical(other.maxHearts, maxHearts) || other.maxHearts == maxHearts)&&(identical(other.heartRefillAt, heartRefillAt) || other.heartRefillAt == heartRefillAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,coins,gems,hearts,maxHearts,heartRefillAt);

@override
String toString() {
  return 'PlayerCurrency(coins: $coins, gems: $gems, hearts: $hearts, maxHearts: $maxHearts, heartRefillAt: $heartRefillAt)';
}


}

/// @nodoc
abstract mixin class _$PlayerCurrencyCopyWith<$Res> implements $PlayerCurrencyCopyWith<$Res> {
  factory _$PlayerCurrencyCopyWith(_PlayerCurrency value, $Res Function(_PlayerCurrency) _then) = __$PlayerCurrencyCopyWithImpl;
@override @useResult
$Res call({
 int coins, int gems, int hearts, int maxHearts, DateTime? heartRefillAt
});




}
/// @nodoc
class __$PlayerCurrencyCopyWithImpl<$Res>
    implements _$PlayerCurrencyCopyWith<$Res> {
  __$PlayerCurrencyCopyWithImpl(this._self, this._then);

  final _PlayerCurrency _self;
  final $Res Function(_PlayerCurrency) _then;

/// Create a copy of PlayerCurrency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? coins = null,Object? gems = null,Object? hearts = null,Object? maxHearts = null,Object? heartRefillAt = freezed,}) {
  return _then(_PlayerCurrency(
coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,gems: null == gems ? _self.gems : gems // ignore: cast_nullable_to_non_nullable
as int,hearts: null == hearts ? _self.hearts : hearts // ignore: cast_nullable_to_non_nullable
as int,maxHearts: null == maxHearts ? _self.maxHearts : maxHearts // ignore: cast_nullable_to_non_nullable
as int,heartRefillAt: freezed == heartRefillAt ? _self.heartRefillAt : heartRefillAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
