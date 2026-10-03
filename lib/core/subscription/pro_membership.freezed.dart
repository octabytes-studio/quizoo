// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pro_membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProMembership {

/// Null only while just the local cache is known.
 ProPlan? get plan;/// Null for a lifetime purchase.
 DateTime? get expiresAt;/// False for lifetime and for a subscription the player has cancelled.
 bool get willRenew;/// The introductory free-trial window, if the store says so.
 bool get isTrial;/// Billing recovery / grace period — RevenueCat
/// `billing_issues_detected_at`.
 bool get hasBillingIssue;/// The store's own "manage this subscription" page, when the SDK
/// reported one. Hidden on the membership screen when null or when the
/// plan is lifetime.
 String? get managementUrl;
/// Create a copy of ProMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProMembershipCopyWith<ProMembership> get copyWith => _$ProMembershipCopyWithImpl<ProMembership>(this as ProMembership, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProMembership&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.willRenew, willRenew) || other.willRenew == willRenew)&&(identical(other.isTrial, isTrial) || other.isTrial == isTrial)&&(identical(other.hasBillingIssue, hasBillingIssue) || other.hasBillingIssue == hasBillingIssue)&&(identical(other.managementUrl, managementUrl) || other.managementUrl == managementUrl));
}


@override
int get hashCode => Object.hash(runtimeType,plan,expiresAt,willRenew,isTrial,hasBillingIssue,managementUrl);

@override
String toString() {
  return 'ProMembership(plan: $plan, expiresAt: $expiresAt, willRenew: $willRenew, isTrial: $isTrial, hasBillingIssue: $hasBillingIssue, managementUrl: $managementUrl)';
}


}

/// @nodoc
abstract mixin class $ProMembershipCopyWith<$Res>  {
  factory $ProMembershipCopyWith(ProMembership value, $Res Function(ProMembership) _then) = _$ProMembershipCopyWithImpl;
@useResult
$Res call({
 ProPlan? plan, DateTime? expiresAt, bool willRenew, bool isTrial, bool hasBillingIssue, String? managementUrl
});




}
/// @nodoc
class _$ProMembershipCopyWithImpl<$Res>
    implements $ProMembershipCopyWith<$Res> {
  _$ProMembershipCopyWithImpl(this._self, this._then);

  final ProMembership _self;
  final $Res Function(ProMembership) _then;

/// Create a copy of ProMembership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = freezed,Object? expiresAt = freezed,Object? willRenew = null,Object? isTrial = null,Object? hasBillingIssue = null,Object? managementUrl = freezed,}) {
  return _then(_self.copyWith(
plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as ProPlan?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,isTrial: null == isTrial ? _self.isTrial : isTrial // ignore: cast_nullable_to_non_nullable
as bool,hasBillingIssue: null == hasBillingIssue ? _self.hasBillingIssue : hasBillingIssue // ignore: cast_nullable_to_non_nullable
as bool,managementUrl: freezed == managementUrl ? _self.managementUrl : managementUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProMembership].
extension ProMembershipPatterns on ProMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProMembership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProMembership value)  $default,){
final _that = this;
switch (_that) {
case _ProMembership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProMembership value)?  $default,){
final _that = this;
switch (_that) {
case _ProMembership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProPlan? plan,  DateTime? expiresAt,  bool willRenew,  bool isTrial,  bool hasBillingIssue,  String? managementUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProMembership() when $default != null:
return $default(_that.plan,_that.expiresAt,_that.willRenew,_that.isTrial,_that.hasBillingIssue,_that.managementUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProPlan? plan,  DateTime? expiresAt,  bool willRenew,  bool isTrial,  bool hasBillingIssue,  String? managementUrl)  $default,) {final _that = this;
switch (_that) {
case _ProMembership():
return $default(_that.plan,_that.expiresAt,_that.willRenew,_that.isTrial,_that.hasBillingIssue,_that.managementUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProPlan? plan,  DateTime? expiresAt,  bool willRenew,  bool isTrial,  bool hasBillingIssue,  String? managementUrl)?  $default,) {final _that = this;
switch (_that) {
case _ProMembership() when $default != null:
return $default(_that.plan,_that.expiresAt,_that.willRenew,_that.isTrial,_that.hasBillingIssue,_that.managementUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ProMembership implements ProMembership {
  const _ProMembership({this.plan, this.expiresAt, this.willRenew = false, this.isTrial = false, this.hasBillingIssue = false, this.managementUrl});
  

/// Null only while just the local cache is known.
@override final  ProPlan? plan;
/// Null for a lifetime purchase.
@override final  DateTime? expiresAt;
/// False for lifetime and for a subscription the player has cancelled.
@override@JsonKey() final  bool willRenew;
/// The introductory free-trial window, if the store says so.
@override@JsonKey() final  bool isTrial;
/// Billing recovery / grace period — RevenueCat
/// `billing_issues_detected_at`.
@override@JsonKey() final  bool hasBillingIssue;
/// The store's own "manage this subscription" page, when the SDK
/// reported one. Hidden on the membership screen when null or when the
/// plan is lifetime.
@override final  String? managementUrl;

/// Create a copy of ProMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProMembershipCopyWith<_ProMembership> get copyWith => __$ProMembershipCopyWithImpl<_ProMembership>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProMembership&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.willRenew, willRenew) || other.willRenew == willRenew)&&(identical(other.isTrial, isTrial) || other.isTrial == isTrial)&&(identical(other.hasBillingIssue, hasBillingIssue) || other.hasBillingIssue == hasBillingIssue)&&(identical(other.managementUrl, managementUrl) || other.managementUrl == managementUrl));
}


@override
int get hashCode => Object.hash(runtimeType,plan,expiresAt,willRenew,isTrial,hasBillingIssue,managementUrl);

@override
String toString() {
  return 'ProMembership(plan: $plan, expiresAt: $expiresAt, willRenew: $willRenew, isTrial: $isTrial, hasBillingIssue: $hasBillingIssue, managementUrl: $managementUrl)';
}


}

/// @nodoc
abstract mixin class _$ProMembershipCopyWith<$Res> implements $ProMembershipCopyWith<$Res> {
  factory _$ProMembershipCopyWith(_ProMembership value, $Res Function(_ProMembership) _then) = __$ProMembershipCopyWithImpl;
@override @useResult
$Res call({
 ProPlan? plan, DateTime? expiresAt, bool willRenew, bool isTrial, bool hasBillingIssue, String? managementUrl
});




}
/// @nodoc
class __$ProMembershipCopyWithImpl<$Res>
    implements _$ProMembershipCopyWith<$Res> {
  __$ProMembershipCopyWithImpl(this._self, this._then);

  final _ProMembership _self;
  final $Res Function(_ProMembership) _then;

/// Create a copy of ProMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = freezed,Object? expiresAt = freezed,Object? willRenew = null,Object? isTrial = null,Object? hasBillingIssue = null,Object? managementUrl = freezed,}) {
  return _then(_ProMembership(
plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as ProPlan?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,isTrial: null == isTrial ? _self.isTrial : isTrial // ignore: cast_nullable_to_non_nullable
as bool,hasBillingIssue: null == hasBillingIssue ? _self.hasBillingIssue : hasBillingIssue // ignore: cast_nullable_to_non_nullable
as bool,managementUrl: freezed == managementUrl ? _self.managementUrl : managementUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
