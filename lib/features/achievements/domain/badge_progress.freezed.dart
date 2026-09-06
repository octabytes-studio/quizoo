// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BadgeProgress {

 AppBadge get badge; BadgeCategory get category;/// "SPORTS · CLOSEST" — meaningful only for a locked badge.
 String? get closestGroupLabel;/// "3 / 8 TOPICS".
 String? get closestFractionLabel;/// 0…1, the thin progress bar under [closestFractionLabel].
 double? get closestProgress;/// "Next up: Hockey — you're on Level 2 of 20."
 String? get nextActionLabel;/// The subcategory the detail dialog's CTA deep-links into.
 String? get nextSubcategoryId; int? get rewardCoins;
/// Create a copy of BadgeProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeProgressCopyWith<BadgeProgress> get copyWith => _$BadgeProgressCopyWithImpl<BadgeProgress>(this as BadgeProgress, _$identity);

  /// Serializes this BadgeProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadgeProgress&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.category, category) || other.category == category)&&(identical(other.closestGroupLabel, closestGroupLabel) || other.closestGroupLabel == closestGroupLabel)&&(identical(other.closestFractionLabel, closestFractionLabel) || other.closestFractionLabel == closestFractionLabel)&&(identical(other.closestProgress, closestProgress) || other.closestProgress == closestProgress)&&(identical(other.nextActionLabel, nextActionLabel) || other.nextActionLabel == nextActionLabel)&&(identical(other.nextSubcategoryId, nextSubcategoryId) || other.nextSubcategoryId == nextSubcategoryId)&&(identical(other.rewardCoins, rewardCoins) || other.rewardCoins == rewardCoins));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,badge,category,closestGroupLabel,closestFractionLabel,closestProgress,nextActionLabel,nextSubcategoryId,rewardCoins);

@override
String toString() {
  return 'BadgeProgress(badge: $badge, category: $category, closestGroupLabel: $closestGroupLabel, closestFractionLabel: $closestFractionLabel, closestProgress: $closestProgress, nextActionLabel: $nextActionLabel, nextSubcategoryId: $nextSubcategoryId, rewardCoins: $rewardCoins)';
}


}

/// @nodoc
abstract mixin class $BadgeProgressCopyWith<$Res>  {
  factory $BadgeProgressCopyWith(BadgeProgress value, $Res Function(BadgeProgress) _then) = _$BadgeProgressCopyWithImpl;
@useResult
$Res call({
 AppBadge badge, BadgeCategory category, String? closestGroupLabel, String? closestFractionLabel, double? closestProgress, String? nextActionLabel, String? nextSubcategoryId, int? rewardCoins
});


$AppBadgeCopyWith<$Res> get badge;

}
/// @nodoc
class _$BadgeProgressCopyWithImpl<$Res>
    implements $BadgeProgressCopyWith<$Res> {
  _$BadgeProgressCopyWithImpl(this._self, this._then);

  final BadgeProgress _self;
  final $Res Function(BadgeProgress) _then;

/// Create a copy of BadgeProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? badge = null,Object? category = null,Object? closestGroupLabel = freezed,Object? closestFractionLabel = freezed,Object? closestProgress = freezed,Object? nextActionLabel = freezed,Object? nextSubcategoryId = freezed,Object? rewardCoins = freezed,}) {
  return _then(_self.copyWith(
badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as AppBadge,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BadgeCategory,closestGroupLabel: freezed == closestGroupLabel ? _self.closestGroupLabel : closestGroupLabel // ignore: cast_nullable_to_non_nullable
as String?,closestFractionLabel: freezed == closestFractionLabel ? _self.closestFractionLabel : closestFractionLabel // ignore: cast_nullable_to_non_nullable
as String?,closestProgress: freezed == closestProgress ? _self.closestProgress : closestProgress // ignore: cast_nullable_to_non_nullable
as double?,nextActionLabel: freezed == nextActionLabel ? _self.nextActionLabel : nextActionLabel // ignore: cast_nullable_to_non_nullable
as String?,nextSubcategoryId: freezed == nextSubcategoryId ? _self.nextSubcategoryId : nextSubcategoryId // ignore: cast_nullable_to_non_nullable
as String?,rewardCoins: freezed == rewardCoins ? _self.rewardCoins : rewardCoins // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of BadgeProgress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBadgeCopyWith<$Res> get badge {
  
  return $AppBadgeCopyWith<$Res>(_self.badge, (value) {
    return _then(_self.copyWith(badge: value));
  });
}
}


/// Adds pattern-matching-related methods to [BadgeProgress].
extension BadgeProgressPatterns on BadgeProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BadgeProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BadgeProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BadgeProgress value)  $default,){
final _that = this;
switch (_that) {
case _BadgeProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BadgeProgress value)?  $default,){
final _that = this;
switch (_that) {
case _BadgeProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppBadge badge,  BadgeCategory category,  String? closestGroupLabel,  String? closestFractionLabel,  double? closestProgress,  String? nextActionLabel,  String? nextSubcategoryId,  int? rewardCoins)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BadgeProgress() when $default != null:
return $default(_that.badge,_that.category,_that.closestGroupLabel,_that.closestFractionLabel,_that.closestProgress,_that.nextActionLabel,_that.nextSubcategoryId,_that.rewardCoins);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppBadge badge,  BadgeCategory category,  String? closestGroupLabel,  String? closestFractionLabel,  double? closestProgress,  String? nextActionLabel,  String? nextSubcategoryId,  int? rewardCoins)  $default,) {final _that = this;
switch (_that) {
case _BadgeProgress():
return $default(_that.badge,_that.category,_that.closestGroupLabel,_that.closestFractionLabel,_that.closestProgress,_that.nextActionLabel,_that.nextSubcategoryId,_that.rewardCoins);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppBadge badge,  BadgeCategory category,  String? closestGroupLabel,  String? closestFractionLabel,  double? closestProgress,  String? nextActionLabel,  String? nextSubcategoryId,  int? rewardCoins)?  $default,) {final _that = this;
switch (_that) {
case _BadgeProgress() when $default != null:
return $default(_that.badge,_that.category,_that.closestGroupLabel,_that.closestFractionLabel,_that.closestProgress,_that.nextActionLabel,_that.nextSubcategoryId,_that.rewardCoins);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BadgeProgress extends BadgeProgress {
  const _BadgeProgress({required this.badge, required this.category, this.closestGroupLabel, this.closestFractionLabel, this.closestProgress, this.nextActionLabel, this.nextSubcategoryId, this.rewardCoins}): super._();
  factory _BadgeProgress.fromJson(Map<String, dynamic> json) => _$BadgeProgressFromJson(json);

@override final  AppBadge badge;
@override final  BadgeCategory category;
/// "SPORTS · CLOSEST" — meaningful only for a locked badge.
@override final  String? closestGroupLabel;
/// "3 / 8 TOPICS".
@override final  String? closestFractionLabel;
/// 0…1, the thin progress bar under [closestFractionLabel].
@override final  double? closestProgress;
/// "Next up: Hockey — you're on Level 2 of 20."
@override final  String? nextActionLabel;
/// The subcategory the detail dialog's CTA deep-links into.
@override final  String? nextSubcategoryId;
@override final  int? rewardCoins;

/// Create a copy of BadgeProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeProgressCopyWith<_BadgeProgress> get copyWith => __$BadgeProgressCopyWithImpl<_BadgeProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BadgeProgress&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.category, category) || other.category == category)&&(identical(other.closestGroupLabel, closestGroupLabel) || other.closestGroupLabel == closestGroupLabel)&&(identical(other.closestFractionLabel, closestFractionLabel) || other.closestFractionLabel == closestFractionLabel)&&(identical(other.closestProgress, closestProgress) || other.closestProgress == closestProgress)&&(identical(other.nextActionLabel, nextActionLabel) || other.nextActionLabel == nextActionLabel)&&(identical(other.nextSubcategoryId, nextSubcategoryId) || other.nextSubcategoryId == nextSubcategoryId)&&(identical(other.rewardCoins, rewardCoins) || other.rewardCoins == rewardCoins));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,badge,category,closestGroupLabel,closestFractionLabel,closestProgress,nextActionLabel,nextSubcategoryId,rewardCoins);

@override
String toString() {
  return 'BadgeProgress(badge: $badge, category: $category, closestGroupLabel: $closestGroupLabel, closestFractionLabel: $closestFractionLabel, closestProgress: $closestProgress, nextActionLabel: $nextActionLabel, nextSubcategoryId: $nextSubcategoryId, rewardCoins: $rewardCoins)';
}


}

/// @nodoc
abstract mixin class _$BadgeProgressCopyWith<$Res> implements $BadgeProgressCopyWith<$Res> {
  factory _$BadgeProgressCopyWith(_BadgeProgress value, $Res Function(_BadgeProgress) _then) = __$BadgeProgressCopyWithImpl;
@override @useResult
$Res call({
 AppBadge badge, BadgeCategory category, String? closestGroupLabel, String? closestFractionLabel, double? closestProgress, String? nextActionLabel, String? nextSubcategoryId, int? rewardCoins
});


@override $AppBadgeCopyWith<$Res> get badge;

}
/// @nodoc
class __$BadgeProgressCopyWithImpl<$Res>
    implements _$BadgeProgressCopyWith<$Res> {
  __$BadgeProgressCopyWithImpl(this._self, this._then);

  final _BadgeProgress _self;
  final $Res Function(_BadgeProgress) _then;

/// Create a copy of BadgeProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? badge = null,Object? category = null,Object? closestGroupLabel = freezed,Object? closestFractionLabel = freezed,Object? closestProgress = freezed,Object? nextActionLabel = freezed,Object? nextSubcategoryId = freezed,Object? rewardCoins = freezed,}) {
  return _then(_BadgeProgress(
badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as AppBadge,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BadgeCategory,closestGroupLabel: freezed == closestGroupLabel ? _self.closestGroupLabel : closestGroupLabel // ignore: cast_nullable_to_non_nullable
as String?,closestFractionLabel: freezed == closestFractionLabel ? _self.closestFractionLabel : closestFractionLabel // ignore: cast_nullable_to_non_nullable
as String?,closestProgress: freezed == closestProgress ? _self.closestProgress : closestProgress // ignore: cast_nullable_to_non_nullable
as double?,nextActionLabel: freezed == nextActionLabel ? _self.nextActionLabel : nextActionLabel // ignore: cast_nullable_to_non_nullable
as String?,nextSubcategoryId: freezed == nextSubcategoryId ? _self.nextSubcategoryId : nextSubcategoryId // ignore: cast_nullable_to_non_nullable
as String?,rewardCoins: freezed == rewardCoins ? _self.rewardCoins : rewardCoins // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of BadgeProgress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBadgeCopyWith<$Res> get badge {
  
  return $AppBadgeCopyWith<$Res>(_self.badge, (value) {
    return _then(_self.copyWith(badge: value));
  });
}
}

// dart format on
