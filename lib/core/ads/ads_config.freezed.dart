// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ads_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdsConfig {

/// Master switch for every interstitial, banner and native ad.
 bool get enabled;/// `AdPlacement.id`s that are switched off.
 Set<String> get disabledPlacements;/// Eligible breaks after install that never show an interstitial.
 int get interstitialGraceBreaks;/// At most one interstitial per this many eligible breaks.
 int get interstitialEveryNBreaks;/// Minimum seconds since the last full-screen ad of any kind.
 int get interstitialMinGapSeconds;/// Most interstitials shown in one app process.
 int get interstitialSessionCap;/// Home's first native row comes after this many category sections.
 int get homeNativeFirstSection;/// Then one more per this many sections.
 int get homeNativeEverySections;/// Most native rows on Home.
 int get homeNativeMax;/// Ranks' native row comes after this many list rows.
 int get ranksNativeAfterRow;
/// Create a copy of AdsConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdsConfigCopyWith<AdsConfig> get copyWith => _$AdsConfigCopyWithImpl<AdsConfig>(this as AdsConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdsConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.disabledPlacements, disabledPlacements)&&(identical(other.interstitialGraceBreaks, interstitialGraceBreaks) || other.interstitialGraceBreaks == interstitialGraceBreaks)&&(identical(other.interstitialEveryNBreaks, interstitialEveryNBreaks) || other.interstitialEveryNBreaks == interstitialEveryNBreaks)&&(identical(other.interstitialMinGapSeconds, interstitialMinGapSeconds) || other.interstitialMinGapSeconds == interstitialMinGapSeconds)&&(identical(other.interstitialSessionCap, interstitialSessionCap) || other.interstitialSessionCap == interstitialSessionCap)&&(identical(other.homeNativeFirstSection, homeNativeFirstSection) || other.homeNativeFirstSection == homeNativeFirstSection)&&(identical(other.homeNativeEverySections, homeNativeEverySections) || other.homeNativeEverySections == homeNativeEverySections)&&(identical(other.homeNativeMax, homeNativeMax) || other.homeNativeMax == homeNativeMax)&&(identical(other.ranksNativeAfterRow, ranksNativeAfterRow) || other.ranksNativeAfterRow == ranksNativeAfterRow));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(disabledPlacements),interstitialGraceBreaks,interstitialEveryNBreaks,interstitialMinGapSeconds,interstitialSessionCap,homeNativeFirstSection,homeNativeEverySections,homeNativeMax,ranksNativeAfterRow);

@override
String toString() {
  return 'AdsConfig(enabled: $enabled, disabledPlacements: $disabledPlacements, interstitialGraceBreaks: $interstitialGraceBreaks, interstitialEveryNBreaks: $interstitialEveryNBreaks, interstitialMinGapSeconds: $interstitialMinGapSeconds, interstitialSessionCap: $interstitialSessionCap, homeNativeFirstSection: $homeNativeFirstSection, homeNativeEverySections: $homeNativeEverySections, homeNativeMax: $homeNativeMax, ranksNativeAfterRow: $ranksNativeAfterRow)';
}


}

/// @nodoc
abstract mixin class $AdsConfigCopyWith<$Res>  {
  factory $AdsConfigCopyWith(AdsConfig value, $Res Function(AdsConfig) _then) = _$AdsConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, Set<String> disabledPlacements, int interstitialGraceBreaks, int interstitialEveryNBreaks, int interstitialMinGapSeconds, int interstitialSessionCap, int homeNativeFirstSection, int homeNativeEverySections, int homeNativeMax, int ranksNativeAfterRow
});




}
/// @nodoc
class _$AdsConfigCopyWithImpl<$Res>
    implements $AdsConfigCopyWith<$Res> {
  _$AdsConfigCopyWithImpl(this._self, this._then);

  final AdsConfig _self;
  final $Res Function(AdsConfig) _then;

/// Create a copy of AdsConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? disabledPlacements = null,Object? interstitialGraceBreaks = null,Object? interstitialEveryNBreaks = null,Object? interstitialMinGapSeconds = null,Object? interstitialSessionCap = null,Object? homeNativeFirstSection = null,Object? homeNativeEverySections = null,Object? homeNativeMax = null,Object? ranksNativeAfterRow = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,disabledPlacements: null == disabledPlacements ? _self.disabledPlacements : disabledPlacements // ignore: cast_nullable_to_non_nullable
as Set<String>,interstitialGraceBreaks: null == interstitialGraceBreaks ? _self.interstitialGraceBreaks : interstitialGraceBreaks // ignore: cast_nullable_to_non_nullable
as int,interstitialEveryNBreaks: null == interstitialEveryNBreaks ? _self.interstitialEveryNBreaks : interstitialEveryNBreaks // ignore: cast_nullable_to_non_nullable
as int,interstitialMinGapSeconds: null == interstitialMinGapSeconds ? _self.interstitialMinGapSeconds : interstitialMinGapSeconds // ignore: cast_nullable_to_non_nullable
as int,interstitialSessionCap: null == interstitialSessionCap ? _self.interstitialSessionCap : interstitialSessionCap // ignore: cast_nullable_to_non_nullable
as int,homeNativeFirstSection: null == homeNativeFirstSection ? _self.homeNativeFirstSection : homeNativeFirstSection // ignore: cast_nullable_to_non_nullable
as int,homeNativeEverySections: null == homeNativeEverySections ? _self.homeNativeEverySections : homeNativeEverySections // ignore: cast_nullable_to_non_nullable
as int,homeNativeMax: null == homeNativeMax ? _self.homeNativeMax : homeNativeMax // ignore: cast_nullable_to_non_nullable
as int,ranksNativeAfterRow: null == ranksNativeAfterRow ? _self.ranksNativeAfterRow : ranksNativeAfterRow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdsConfig].
extension AdsConfigPatterns on AdsConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdsConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdsConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdsConfig value)  $default,){
final _that = this;
switch (_that) {
case _AdsConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdsConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AdsConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  Set<String> disabledPlacements,  int interstitialGraceBreaks,  int interstitialEveryNBreaks,  int interstitialMinGapSeconds,  int interstitialSessionCap,  int homeNativeFirstSection,  int homeNativeEverySections,  int homeNativeMax,  int ranksNativeAfterRow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdsConfig() when $default != null:
return $default(_that.enabled,_that.disabledPlacements,_that.interstitialGraceBreaks,_that.interstitialEveryNBreaks,_that.interstitialMinGapSeconds,_that.interstitialSessionCap,_that.homeNativeFirstSection,_that.homeNativeEverySections,_that.homeNativeMax,_that.ranksNativeAfterRow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  Set<String> disabledPlacements,  int interstitialGraceBreaks,  int interstitialEveryNBreaks,  int interstitialMinGapSeconds,  int interstitialSessionCap,  int homeNativeFirstSection,  int homeNativeEverySections,  int homeNativeMax,  int ranksNativeAfterRow)  $default,) {final _that = this;
switch (_that) {
case _AdsConfig():
return $default(_that.enabled,_that.disabledPlacements,_that.interstitialGraceBreaks,_that.interstitialEveryNBreaks,_that.interstitialMinGapSeconds,_that.interstitialSessionCap,_that.homeNativeFirstSection,_that.homeNativeEverySections,_that.homeNativeMax,_that.ranksNativeAfterRow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  Set<String> disabledPlacements,  int interstitialGraceBreaks,  int interstitialEveryNBreaks,  int interstitialMinGapSeconds,  int interstitialSessionCap,  int homeNativeFirstSection,  int homeNativeEverySections,  int homeNativeMax,  int ranksNativeAfterRow)?  $default,) {final _that = this;
switch (_that) {
case _AdsConfig() when $default != null:
return $default(_that.enabled,_that.disabledPlacements,_that.interstitialGraceBreaks,_that.interstitialEveryNBreaks,_that.interstitialMinGapSeconds,_that.interstitialSessionCap,_that.homeNativeFirstSection,_that.homeNativeEverySections,_that.homeNativeMax,_that.ranksNativeAfterRow);case _:
  return null;

}
}

}

/// @nodoc


class _AdsConfig implements AdsConfig {
  const _AdsConfig({this.enabled = true, final  Set<String> disabledPlacements = const <String>{}, this.interstitialGraceBreaks = 2, this.interstitialEveryNBreaks = 2, this.interstitialMinGapSeconds = 120, this.interstitialSessionCap = 8, this.homeNativeFirstSection = 2, this.homeNativeEverySections = 5, this.homeNativeMax = 2, this.ranksNativeAfterRow = 5}): _disabledPlacements = disabledPlacements;
  

/// Master switch for every interstitial, banner and native ad.
@override@JsonKey() final  bool enabled;
/// `AdPlacement.id`s that are switched off.
 final  Set<String> _disabledPlacements;
/// `AdPlacement.id`s that are switched off.
@override@JsonKey() Set<String> get disabledPlacements {
  if (_disabledPlacements is EqualUnmodifiableSetView) return _disabledPlacements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_disabledPlacements);
}

/// Eligible breaks after install that never show an interstitial.
@override@JsonKey() final  int interstitialGraceBreaks;
/// At most one interstitial per this many eligible breaks.
@override@JsonKey() final  int interstitialEveryNBreaks;
/// Minimum seconds since the last full-screen ad of any kind.
@override@JsonKey() final  int interstitialMinGapSeconds;
/// Most interstitials shown in one app process.
@override@JsonKey() final  int interstitialSessionCap;
/// Home's first native row comes after this many category sections.
@override@JsonKey() final  int homeNativeFirstSection;
/// Then one more per this many sections.
@override@JsonKey() final  int homeNativeEverySections;
/// Most native rows on Home.
@override@JsonKey() final  int homeNativeMax;
/// Ranks' native row comes after this many list rows.
@override@JsonKey() final  int ranksNativeAfterRow;

/// Create a copy of AdsConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdsConfigCopyWith<_AdsConfig> get copyWith => __$AdsConfigCopyWithImpl<_AdsConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdsConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._disabledPlacements, _disabledPlacements)&&(identical(other.interstitialGraceBreaks, interstitialGraceBreaks) || other.interstitialGraceBreaks == interstitialGraceBreaks)&&(identical(other.interstitialEveryNBreaks, interstitialEveryNBreaks) || other.interstitialEveryNBreaks == interstitialEveryNBreaks)&&(identical(other.interstitialMinGapSeconds, interstitialMinGapSeconds) || other.interstitialMinGapSeconds == interstitialMinGapSeconds)&&(identical(other.interstitialSessionCap, interstitialSessionCap) || other.interstitialSessionCap == interstitialSessionCap)&&(identical(other.homeNativeFirstSection, homeNativeFirstSection) || other.homeNativeFirstSection == homeNativeFirstSection)&&(identical(other.homeNativeEverySections, homeNativeEverySections) || other.homeNativeEverySections == homeNativeEverySections)&&(identical(other.homeNativeMax, homeNativeMax) || other.homeNativeMax == homeNativeMax)&&(identical(other.ranksNativeAfterRow, ranksNativeAfterRow) || other.ranksNativeAfterRow == ranksNativeAfterRow));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(_disabledPlacements),interstitialGraceBreaks,interstitialEveryNBreaks,interstitialMinGapSeconds,interstitialSessionCap,homeNativeFirstSection,homeNativeEverySections,homeNativeMax,ranksNativeAfterRow);

@override
String toString() {
  return 'AdsConfig(enabled: $enabled, disabledPlacements: $disabledPlacements, interstitialGraceBreaks: $interstitialGraceBreaks, interstitialEveryNBreaks: $interstitialEveryNBreaks, interstitialMinGapSeconds: $interstitialMinGapSeconds, interstitialSessionCap: $interstitialSessionCap, homeNativeFirstSection: $homeNativeFirstSection, homeNativeEverySections: $homeNativeEverySections, homeNativeMax: $homeNativeMax, ranksNativeAfterRow: $ranksNativeAfterRow)';
}


}

/// @nodoc
abstract mixin class _$AdsConfigCopyWith<$Res> implements $AdsConfigCopyWith<$Res> {
  factory _$AdsConfigCopyWith(_AdsConfig value, $Res Function(_AdsConfig) _then) = __$AdsConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, Set<String> disabledPlacements, int interstitialGraceBreaks, int interstitialEveryNBreaks, int interstitialMinGapSeconds, int interstitialSessionCap, int homeNativeFirstSection, int homeNativeEverySections, int homeNativeMax, int ranksNativeAfterRow
});




}
/// @nodoc
class __$AdsConfigCopyWithImpl<$Res>
    implements _$AdsConfigCopyWith<$Res> {
  __$AdsConfigCopyWithImpl(this._self, this._then);

  final _AdsConfig _self;
  final $Res Function(_AdsConfig) _then;

/// Create a copy of AdsConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? disabledPlacements = null,Object? interstitialGraceBreaks = null,Object? interstitialEveryNBreaks = null,Object? interstitialMinGapSeconds = null,Object? interstitialSessionCap = null,Object? homeNativeFirstSection = null,Object? homeNativeEverySections = null,Object? homeNativeMax = null,Object? ranksNativeAfterRow = null,}) {
  return _then(_AdsConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,disabledPlacements: null == disabledPlacements ? _self._disabledPlacements : disabledPlacements // ignore: cast_nullable_to_non_nullable
as Set<String>,interstitialGraceBreaks: null == interstitialGraceBreaks ? _self.interstitialGraceBreaks : interstitialGraceBreaks // ignore: cast_nullable_to_non_nullable
as int,interstitialEveryNBreaks: null == interstitialEveryNBreaks ? _self.interstitialEveryNBreaks : interstitialEveryNBreaks // ignore: cast_nullable_to_non_nullable
as int,interstitialMinGapSeconds: null == interstitialMinGapSeconds ? _self.interstitialMinGapSeconds : interstitialMinGapSeconds // ignore: cast_nullable_to_non_nullable
as int,interstitialSessionCap: null == interstitialSessionCap ? _self.interstitialSessionCap : interstitialSessionCap // ignore: cast_nullable_to_non_nullable
as int,homeNativeFirstSection: null == homeNativeFirstSection ? _self.homeNativeFirstSection : homeNativeFirstSection // ignore: cast_nullable_to_non_nullable
as int,homeNativeEverySections: null == homeNativeEverySections ? _self.homeNativeEverySections : homeNativeEverySections // ignore: cast_nullable_to_non_nullable
as int,homeNativeMax: null == homeNativeMax ? _self.homeNativeMax : homeNativeMax // ignore: cast_nullable_to_non_nullable
as int,ranksNativeAfterRow: null == ranksNativeAfterRow ? _self.ranksNativeAfterRow : ranksNativeAfterRow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
