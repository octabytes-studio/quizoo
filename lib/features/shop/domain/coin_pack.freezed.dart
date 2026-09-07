// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coin_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoinPack {

 String get id; int get coins; String get priceLabel;/// "+20%", "+50%" — zero means no bonus badge at all.
 int get bonusPercent;/// The bible's middle, most-favourable pack — the one the grid highlights.
 bool get isHighlighted;
/// Create a copy of CoinPack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoinPackCopyWith<CoinPack> get copyWith => _$CoinPackCopyWithImpl<CoinPack>(this as CoinPack, _$identity);

  /// Serializes this CoinPack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoinPack&&(identical(other.id, id) || other.id == id)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.priceLabel, priceLabel) || other.priceLabel == priceLabel)&&(identical(other.bonusPercent, bonusPercent) || other.bonusPercent == bonusPercent)&&(identical(other.isHighlighted, isHighlighted) || other.isHighlighted == isHighlighted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,coins,priceLabel,bonusPercent,isHighlighted);

@override
String toString() {
  return 'CoinPack(id: $id, coins: $coins, priceLabel: $priceLabel, bonusPercent: $bonusPercent, isHighlighted: $isHighlighted)';
}


}

/// @nodoc
abstract mixin class $CoinPackCopyWith<$Res>  {
  factory $CoinPackCopyWith(CoinPack value, $Res Function(CoinPack) _then) = _$CoinPackCopyWithImpl;
@useResult
$Res call({
 String id, int coins, String priceLabel, int bonusPercent, bool isHighlighted
});




}
/// @nodoc
class _$CoinPackCopyWithImpl<$Res>
    implements $CoinPackCopyWith<$Res> {
  _$CoinPackCopyWithImpl(this._self, this._then);

  final CoinPack _self;
  final $Res Function(CoinPack) _then;

/// Create a copy of CoinPack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? coins = null,Object? priceLabel = null,Object? bonusPercent = null,Object? isHighlighted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,priceLabel: null == priceLabel ? _self.priceLabel : priceLabel // ignore: cast_nullable_to_non_nullable
as String,bonusPercent: null == bonusPercent ? _self.bonusPercent : bonusPercent // ignore: cast_nullable_to_non_nullable
as int,isHighlighted: null == isHighlighted ? _self.isHighlighted : isHighlighted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CoinPack].
extension CoinPackPatterns on CoinPack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoinPack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoinPack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoinPack value)  $default,){
final _that = this;
switch (_that) {
case _CoinPack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoinPack value)?  $default,){
final _that = this;
switch (_that) {
case _CoinPack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int coins,  String priceLabel,  int bonusPercent,  bool isHighlighted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoinPack() when $default != null:
return $default(_that.id,_that.coins,_that.priceLabel,_that.bonusPercent,_that.isHighlighted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int coins,  String priceLabel,  int bonusPercent,  bool isHighlighted)  $default,) {final _that = this;
switch (_that) {
case _CoinPack():
return $default(_that.id,_that.coins,_that.priceLabel,_that.bonusPercent,_that.isHighlighted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int coins,  String priceLabel,  int bonusPercent,  bool isHighlighted)?  $default,) {final _that = this;
switch (_that) {
case _CoinPack() when $default != null:
return $default(_that.id,_that.coins,_that.priceLabel,_that.bonusPercent,_that.isHighlighted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoinPack implements CoinPack {
  const _CoinPack({required this.id, required this.coins, required this.priceLabel, this.bonusPercent = 0, this.isHighlighted = false});
  factory _CoinPack.fromJson(Map<String, dynamic> json) => _$CoinPackFromJson(json);

@override final  String id;
@override final  int coins;
@override final  String priceLabel;
/// "+20%", "+50%" — zero means no bonus badge at all.
@override@JsonKey() final  int bonusPercent;
/// The bible's middle, most-favourable pack — the one the grid highlights.
@override@JsonKey() final  bool isHighlighted;

/// Create a copy of CoinPack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoinPackCopyWith<_CoinPack> get copyWith => __$CoinPackCopyWithImpl<_CoinPack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoinPackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoinPack&&(identical(other.id, id) || other.id == id)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.priceLabel, priceLabel) || other.priceLabel == priceLabel)&&(identical(other.bonusPercent, bonusPercent) || other.bonusPercent == bonusPercent)&&(identical(other.isHighlighted, isHighlighted) || other.isHighlighted == isHighlighted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,coins,priceLabel,bonusPercent,isHighlighted);

@override
String toString() {
  return 'CoinPack(id: $id, coins: $coins, priceLabel: $priceLabel, bonusPercent: $bonusPercent, isHighlighted: $isHighlighted)';
}


}

/// @nodoc
abstract mixin class _$CoinPackCopyWith<$Res> implements $CoinPackCopyWith<$Res> {
  factory _$CoinPackCopyWith(_CoinPack value, $Res Function(_CoinPack) _then) = __$CoinPackCopyWithImpl;
@override @useResult
$Res call({
 String id, int coins, String priceLabel, int bonusPercent, bool isHighlighted
});




}
/// @nodoc
class __$CoinPackCopyWithImpl<$Res>
    implements _$CoinPackCopyWith<$Res> {
  __$CoinPackCopyWithImpl(this._self, this._then);

  final _CoinPack _self;
  final $Res Function(_CoinPack) _then;

/// Create a copy of CoinPack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? coins = null,Object? priceLabel = null,Object? bonusPercent = null,Object? isHighlighted = null,}) {
  return _then(_CoinPack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,priceLabel: null == priceLabel ? _self.priceLabel : priceLabel // ignore: cast_nullable_to_non_nullable
as String,bonusPercent: null == bonusPercent ? _self.bonusPercent : bonusPercent // ignore: cast_nullable_to_non_nullable
as int,isHighlighted: null == isHighlighted ? _self.isHighlighted : isHighlighted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
