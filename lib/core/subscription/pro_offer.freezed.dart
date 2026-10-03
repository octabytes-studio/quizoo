// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pro_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProOffer {

 ProPlan get plan;/// RevenueCat package identifier (`$rc_monthly` …) — the purchase key.
 String get packageId;/// Store-formatted price, e.g. `$4.99` / `4,99 US$`.
 String get priceLabel; double get price; String get currencyCode;/// Non-null only when the product carries a free trial, in whole days.
 int? get trialDays;/// Yearly only: the monthly-equivalent price (`$Y per month`), so the
/// plan card can show the saving. Null when the currency or the monthly
/// price is not known.
 String? get perMonthLabel;
/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProOfferCopyWith<ProOffer> get copyWith => _$ProOfferCopyWithImpl<ProOffer>(this as ProOffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProOffer&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.priceLabel, priceLabel) || other.priceLabel == priceLabel)&&(identical(other.price, price) || other.price == price)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&(identical(other.perMonthLabel, perMonthLabel) || other.perMonthLabel == perMonthLabel));
}


@override
int get hashCode => Object.hash(runtimeType,plan,packageId,priceLabel,price,currencyCode,trialDays,perMonthLabel);

@override
String toString() {
  return 'ProOffer(plan: $plan, packageId: $packageId, priceLabel: $priceLabel, price: $price, currencyCode: $currencyCode, trialDays: $trialDays, perMonthLabel: $perMonthLabel)';
}


}

/// @nodoc
abstract mixin class $ProOfferCopyWith<$Res>  {
  factory $ProOfferCopyWith(ProOffer value, $Res Function(ProOffer) _then) = _$ProOfferCopyWithImpl;
@useResult
$Res call({
 ProPlan plan, String packageId, String priceLabel, double price, String currencyCode, int? trialDays, String? perMonthLabel
});




}
/// @nodoc
class _$ProOfferCopyWithImpl<$Res>
    implements $ProOfferCopyWith<$Res> {
  _$ProOfferCopyWithImpl(this._self, this._then);

  final ProOffer _self;
  final $Res Function(ProOffer) _then;

/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? packageId = null,Object? priceLabel = null,Object? price = null,Object? currencyCode = null,Object? trialDays = freezed,Object? perMonthLabel = freezed,}) {
  return _then(_self.copyWith(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as ProPlan,packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as String,priceLabel: null == priceLabel ? _self.priceLabel : priceLabel // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,trialDays: freezed == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int?,perMonthLabel: freezed == perMonthLabel ? _self.perMonthLabel : perMonthLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProOffer].
extension ProOfferPatterns on ProOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProOffer value)  $default,){
final _that = this;
switch (_that) {
case _ProOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProOffer value)?  $default,){
final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProPlan plan,  String packageId,  String priceLabel,  double price,  String currencyCode,  int? trialDays,  String? perMonthLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
return $default(_that.plan,_that.packageId,_that.priceLabel,_that.price,_that.currencyCode,_that.trialDays,_that.perMonthLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProPlan plan,  String packageId,  String priceLabel,  double price,  String currencyCode,  int? trialDays,  String? perMonthLabel)  $default,) {final _that = this;
switch (_that) {
case _ProOffer():
return $default(_that.plan,_that.packageId,_that.priceLabel,_that.price,_that.currencyCode,_that.trialDays,_that.perMonthLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProPlan plan,  String packageId,  String priceLabel,  double price,  String currencyCode,  int? trialDays,  String? perMonthLabel)?  $default,) {final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
return $default(_that.plan,_that.packageId,_that.priceLabel,_that.price,_that.currencyCode,_that.trialDays,_that.perMonthLabel);case _:
  return null;

}
}

}

/// @nodoc


class _ProOffer implements ProOffer {
  const _ProOffer({required this.plan, required this.packageId, required this.priceLabel, required this.price, required this.currencyCode, this.trialDays, this.perMonthLabel});
  

@override final  ProPlan plan;
/// RevenueCat package identifier (`$rc_monthly` …) — the purchase key.
@override final  String packageId;
/// Store-formatted price, e.g. `$4.99` / `4,99 US$`.
@override final  String priceLabel;
@override final  double price;
@override final  String currencyCode;
/// Non-null only when the product carries a free trial, in whole days.
@override final  int? trialDays;
/// Yearly only: the monthly-equivalent price (`$Y per month`), so the
/// plan card can show the saving. Null when the currency or the monthly
/// price is not known.
@override final  String? perMonthLabel;

/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProOfferCopyWith<_ProOffer> get copyWith => __$ProOfferCopyWithImpl<_ProOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProOffer&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.priceLabel, priceLabel) || other.priceLabel == priceLabel)&&(identical(other.price, price) || other.price == price)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&(identical(other.perMonthLabel, perMonthLabel) || other.perMonthLabel == perMonthLabel));
}


@override
int get hashCode => Object.hash(runtimeType,plan,packageId,priceLabel,price,currencyCode,trialDays,perMonthLabel);

@override
String toString() {
  return 'ProOffer(plan: $plan, packageId: $packageId, priceLabel: $priceLabel, price: $price, currencyCode: $currencyCode, trialDays: $trialDays, perMonthLabel: $perMonthLabel)';
}


}

/// @nodoc
abstract mixin class _$ProOfferCopyWith<$Res> implements $ProOfferCopyWith<$Res> {
  factory _$ProOfferCopyWith(_ProOffer value, $Res Function(_ProOffer) _then) = __$ProOfferCopyWithImpl;
@override @useResult
$Res call({
 ProPlan plan, String packageId, String priceLabel, double price, String currencyCode, int? trialDays, String? perMonthLabel
});




}
/// @nodoc
class __$ProOfferCopyWithImpl<$Res>
    implements _$ProOfferCopyWith<$Res> {
  __$ProOfferCopyWithImpl(this._self, this._then);

  final _ProOffer _self;
  final $Res Function(_ProOffer) _then;

/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? packageId = null,Object? priceLabel = null,Object? price = null,Object? currencyCode = null,Object? trialDays = freezed,Object? perMonthLabel = freezed,}) {
  return _then(_ProOffer(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as ProPlan,packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as String,priceLabel: null == priceLabel ? _self.priceLabel : priceLabel // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,trialDays: freezed == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int?,perMonthLabel: freezed == perMonthLabel ? _self.perMonthLabel : perMonthLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
