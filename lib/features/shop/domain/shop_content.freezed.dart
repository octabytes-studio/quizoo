// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopContent {

 int get coins; int get gems; int get freeAdsWatchedToday; int get freeAdsPerDay; int get freeCoinsReward; PowerUpInventory get inventory; List<CoinPack> get coinPacks;
/// Create a copy of ShopContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopContentCopyWith<ShopContent> get copyWith => _$ShopContentCopyWithImpl<ShopContent>(this as ShopContent, _$identity);

  /// Serializes this ShopContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopContent&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.gems, gems) || other.gems == gems)&&(identical(other.freeAdsWatchedToday, freeAdsWatchedToday) || other.freeAdsWatchedToday == freeAdsWatchedToday)&&(identical(other.freeAdsPerDay, freeAdsPerDay) || other.freeAdsPerDay == freeAdsPerDay)&&(identical(other.freeCoinsReward, freeCoinsReward) || other.freeCoinsReward == freeCoinsReward)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&const DeepCollectionEquality().equals(other.coinPacks, coinPacks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,coins,gems,freeAdsWatchedToday,freeAdsPerDay,freeCoinsReward,inventory,const DeepCollectionEquality().hash(coinPacks));

@override
String toString() {
  return 'ShopContent(coins: $coins, gems: $gems, freeAdsWatchedToday: $freeAdsWatchedToday, freeAdsPerDay: $freeAdsPerDay, freeCoinsReward: $freeCoinsReward, inventory: $inventory, coinPacks: $coinPacks)';
}


}

/// @nodoc
abstract mixin class $ShopContentCopyWith<$Res>  {
  factory $ShopContentCopyWith(ShopContent value, $Res Function(ShopContent) _then) = _$ShopContentCopyWithImpl;
@useResult
$Res call({
 int coins, int gems, int freeAdsWatchedToday, int freeAdsPerDay, int freeCoinsReward, PowerUpInventory inventory, List<CoinPack> coinPacks
});


$PowerUpInventoryCopyWith<$Res> get inventory;

}
/// @nodoc
class _$ShopContentCopyWithImpl<$Res>
    implements $ShopContentCopyWith<$Res> {
  _$ShopContentCopyWithImpl(this._self, this._then);

  final ShopContent _self;
  final $Res Function(ShopContent) _then;

/// Create a copy of ShopContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coins = null,Object? gems = null,Object? freeAdsWatchedToday = null,Object? freeAdsPerDay = null,Object? freeCoinsReward = null,Object? inventory = null,Object? coinPacks = null,}) {
  return _then(_self.copyWith(
coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,gems: null == gems ? _self.gems : gems // ignore: cast_nullable_to_non_nullable
as int,freeAdsWatchedToday: null == freeAdsWatchedToday ? _self.freeAdsWatchedToday : freeAdsWatchedToday // ignore: cast_nullable_to_non_nullable
as int,freeAdsPerDay: null == freeAdsPerDay ? _self.freeAdsPerDay : freeAdsPerDay // ignore: cast_nullable_to_non_nullable
as int,freeCoinsReward: null == freeCoinsReward ? _self.freeCoinsReward : freeCoinsReward // ignore: cast_nullable_to_non_nullable
as int,inventory: null == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as PowerUpInventory,coinPacks: null == coinPacks ? _self.coinPacks : coinPacks // ignore: cast_nullable_to_non_nullable
as List<CoinPack>,
  ));
}
/// Create a copy of ShopContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PowerUpInventoryCopyWith<$Res> get inventory {
  
  return $PowerUpInventoryCopyWith<$Res>(_self.inventory, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShopContent].
extension ShopContentPatterns on ShopContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopContent value)  $default,){
final _that = this;
switch (_that) {
case _ShopContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopContent value)?  $default,){
final _that = this;
switch (_that) {
case _ShopContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int coins,  int gems,  int freeAdsWatchedToday,  int freeAdsPerDay,  int freeCoinsReward,  PowerUpInventory inventory,  List<CoinPack> coinPacks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopContent() when $default != null:
return $default(_that.coins,_that.gems,_that.freeAdsWatchedToday,_that.freeAdsPerDay,_that.freeCoinsReward,_that.inventory,_that.coinPacks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int coins,  int gems,  int freeAdsWatchedToday,  int freeAdsPerDay,  int freeCoinsReward,  PowerUpInventory inventory,  List<CoinPack> coinPacks)  $default,) {final _that = this;
switch (_that) {
case _ShopContent():
return $default(_that.coins,_that.gems,_that.freeAdsWatchedToday,_that.freeAdsPerDay,_that.freeCoinsReward,_that.inventory,_that.coinPacks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int coins,  int gems,  int freeAdsWatchedToday,  int freeAdsPerDay,  int freeCoinsReward,  PowerUpInventory inventory,  List<CoinPack> coinPacks)?  $default,) {final _that = this;
switch (_that) {
case _ShopContent() when $default != null:
return $default(_that.coins,_that.gems,_that.freeAdsWatchedToday,_that.freeAdsPerDay,_that.freeCoinsReward,_that.inventory,_that.coinPacks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopContent extends ShopContent {
  const _ShopContent({required this.coins, required this.gems, required this.freeAdsWatchedToday, required this.freeAdsPerDay, required this.freeCoinsReward, required this.inventory, required final  List<CoinPack> coinPacks}): _coinPacks = coinPacks,super._();
  factory _ShopContent.fromJson(Map<String, dynamic> json) => _$ShopContentFromJson(json);

@override final  int coins;
@override final  int gems;
@override final  int freeAdsWatchedToday;
@override final  int freeAdsPerDay;
@override final  int freeCoinsReward;
@override final  PowerUpInventory inventory;
 final  List<CoinPack> _coinPacks;
@override List<CoinPack> get coinPacks {
  if (_coinPacks is EqualUnmodifiableListView) return _coinPacks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coinPacks);
}


/// Create a copy of ShopContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopContentCopyWith<_ShopContent> get copyWith => __$ShopContentCopyWithImpl<_ShopContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopContent&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.gems, gems) || other.gems == gems)&&(identical(other.freeAdsWatchedToday, freeAdsWatchedToday) || other.freeAdsWatchedToday == freeAdsWatchedToday)&&(identical(other.freeAdsPerDay, freeAdsPerDay) || other.freeAdsPerDay == freeAdsPerDay)&&(identical(other.freeCoinsReward, freeCoinsReward) || other.freeCoinsReward == freeCoinsReward)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&const DeepCollectionEquality().equals(other._coinPacks, _coinPacks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,coins,gems,freeAdsWatchedToday,freeAdsPerDay,freeCoinsReward,inventory,const DeepCollectionEquality().hash(_coinPacks));

@override
String toString() {
  return 'ShopContent(coins: $coins, gems: $gems, freeAdsWatchedToday: $freeAdsWatchedToday, freeAdsPerDay: $freeAdsPerDay, freeCoinsReward: $freeCoinsReward, inventory: $inventory, coinPacks: $coinPacks)';
}


}

/// @nodoc
abstract mixin class _$ShopContentCopyWith<$Res> implements $ShopContentCopyWith<$Res> {
  factory _$ShopContentCopyWith(_ShopContent value, $Res Function(_ShopContent) _then) = __$ShopContentCopyWithImpl;
@override @useResult
$Res call({
 int coins, int gems, int freeAdsWatchedToday, int freeAdsPerDay, int freeCoinsReward, PowerUpInventory inventory, List<CoinPack> coinPacks
});


@override $PowerUpInventoryCopyWith<$Res> get inventory;

}
/// @nodoc
class __$ShopContentCopyWithImpl<$Res>
    implements _$ShopContentCopyWith<$Res> {
  __$ShopContentCopyWithImpl(this._self, this._then);

  final _ShopContent _self;
  final $Res Function(_ShopContent) _then;

/// Create a copy of ShopContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? coins = null,Object? gems = null,Object? freeAdsWatchedToday = null,Object? freeAdsPerDay = null,Object? freeCoinsReward = null,Object? inventory = null,Object? coinPacks = null,}) {
  return _then(_ShopContent(
coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,gems: null == gems ? _self.gems : gems // ignore: cast_nullable_to_non_nullable
as int,freeAdsWatchedToday: null == freeAdsWatchedToday ? _self.freeAdsWatchedToday : freeAdsWatchedToday // ignore: cast_nullable_to_non_nullable
as int,freeAdsPerDay: null == freeAdsPerDay ? _self.freeAdsPerDay : freeAdsPerDay // ignore: cast_nullable_to_non_nullable
as int,freeCoinsReward: null == freeCoinsReward ? _self.freeCoinsReward : freeCoinsReward // ignore: cast_nullable_to_non_nullable
as int,inventory: null == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as PowerUpInventory,coinPacks: null == coinPacks ? _self._coinPacks : coinPacks // ignore: cast_nullable_to_non_nullable
as List<CoinPack>,
  ));
}

/// Create a copy of ShopContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PowerUpInventoryCopyWith<$Res> get inventory {
  
  return $PowerUpInventoryCopyWith<$Res>(_self.inventory, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}

// dart format on
