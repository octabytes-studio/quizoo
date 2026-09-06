// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'streak_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreakDay {

 String get label; StreakDayMark get mark;
/// Create a copy of StreakDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakDayCopyWith<StreakDay> get copyWith => _$StreakDayCopyWithImpl<StreakDay>(this as StreakDay, _$identity);

  /// Serializes this StreakDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakDay&&(identical(other.label, label) || other.label == label)&&(identical(other.mark, mark) || other.mark == mark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,mark);

@override
String toString() {
  return 'StreakDay(label: $label, mark: $mark)';
}


}

/// @nodoc
abstract mixin class $StreakDayCopyWith<$Res>  {
  factory $StreakDayCopyWith(StreakDay value, $Res Function(StreakDay) _then) = _$StreakDayCopyWithImpl;
@useResult
$Res call({
 String label, StreakDayMark mark
});




}
/// @nodoc
class _$StreakDayCopyWithImpl<$Res>
    implements $StreakDayCopyWith<$Res> {
  _$StreakDayCopyWithImpl(this._self, this._then);

  final StreakDay _self;
  final $Res Function(StreakDay) _then;

/// Create a copy of StreakDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? mark = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as StreakDayMark,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakDay].
extension StreakDayPatterns on StreakDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakDay value)  $default,){
final _that = this;
switch (_that) {
case _StreakDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakDay value)?  $default,){
final _that = this;
switch (_that) {
case _StreakDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  StreakDayMark mark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakDay() when $default != null:
return $default(_that.label,_that.mark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  StreakDayMark mark)  $default,) {final _that = this;
switch (_that) {
case _StreakDay():
return $default(_that.label,_that.mark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  StreakDayMark mark)?  $default,) {final _that = this;
switch (_that) {
case _StreakDay() when $default != null:
return $default(_that.label,_that.mark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakDay implements StreakDay {
  const _StreakDay({required this.label, required this.mark});
  factory _StreakDay.fromJson(Map<String, dynamic> json) => _$StreakDayFromJson(json);

@override final  String label;
@override final  StreakDayMark mark;

/// Create a copy of StreakDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakDayCopyWith<_StreakDay> get copyWith => __$StreakDayCopyWithImpl<_StreakDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakDay&&(identical(other.label, label) || other.label == label)&&(identical(other.mark, mark) || other.mark == mark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,mark);

@override
String toString() {
  return 'StreakDay(label: $label, mark: $mark)';
}


}

/// @nodoc
abstract mixin class _$StreakDayCopyWith<$Res> implements $StreakDayCopyWith<$Res> {
  factory _$StreakDayCopyWith(_StreakDay value, $Res Function(_StreakDay) _then) = __$StreakDayCopyWithImpl;
@override @useResult
$Res call({
 String label, StreakDayMark mark
});




}
/// @nodoc
class __$StreakDayCopyWithImpl<$Res>
    implements _$StreakDayCopyWith<$Res> {
  __$StreakDayCopyWithImpl(this._self, this._then);

  final _StreakDay _self;
  final $Res Function(_StreakDay) _then;

/// Create a copy of StreakDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? mark = null,}) {
  return _then(_StreakDay(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as StreakDayMark,
  ));
}


}


/// @nodoc
mixin _$Milestone {

 String get title; int get daysAway; String get rewardLabel;
/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MilestoneCopyWith<Milestone> get copyWith => _$MilestoneCopyWithImpl<Milestone>(this as Milestone, _$identity);

  /// Serializes this Milestone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Milestone&&(identical(other.title, title) || other.title == title)&&(identical(other.daysAway, daysAway) || other.daysAway == daysAway)&&(identical(other.rewardLabel, rewardLabel) || other.rewardLabel == rewardLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,daysAway,rewardLabel);

@override
String toString() {
  return 'Milestone(title: $title, daysAway: $daysAway, rewardLabel: $rewardLabel)';
}


}

/// @nodoc
abstract mixin class $MilestoneCopyWith<$Res>  {
  factory $MilestoneCopyWith(Milestone value, $Res Function(Milestone) _then) = _$MilestoneCopyWithImpl;
@useResult
$Res call({
 String title, int daysAway, String rewardLabel
});




}
/// @nodoc
class _$MilestoneCopyWithImpl<$Res>
    implements $MilestoneCopyWith<$Res> {
  _$MilestoneCopyWithImpl(this._self, this._then);

  final Milestone _self;
  final $Res Function(Milestone) _then;

/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? daysAway = null,Object? rewardLabel = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,daysAway: null == daysAway ? _self.daysAway : daysAway // ignore: cast_nullable_to_non_nullable
as int,rewardLabel: null == rewardLabel ? _self.rewardLabel : rewardLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Milestone].
extension MilestonePatterns on Milestone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Milestone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Milestone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Milestone value)  $default,){
final _that = this;
switch (_that) {
case _Milestone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Milestone value)?  $default,){
final _that = this;
switch (_that) {
case _Milestone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int daysAway,  String rewardLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Milestone() when $default != null:
return $default(_that.title,_that.daysAway,_that.rewardLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int daysAway,  String rewardLabel)  $default,) {final _that = this;
switch (_that) {
case _Milestone():
return $default(_that.title,_that.daysAway,_that.rewardLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int daysAway,  String rewardLabel)?  $default,) {final _that = this;
switch (_that) {
case _Milestone() when $default != null:
return $default(_that.title,_that.daysAway,_that.rewardLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Milestone implements Milestone {
  const _Milestone({required this.title, required this.daysAway, required this.rewardLabel});
  factory _Milestone.fromJson(Map<String, dynamic> json) => _$MilestoneFromJson(json);

@override final  String title;
@override final  int daysAway;
@override final  String rewardLabel;

/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MilestoneCopyWith<_Milestone> get copyWith => __$MilestoneCopyWithImpl<_Milestone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MilestoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Milestone&&(identical(other.title, title) || other.title == title)&&(identical(other.daysAway, daysAway) || other.daysAway == daysAway)&&(identical(other.rewardLabel, rewardLabel) || other.rewardLabel == rewardLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,daysAway,rewardLabel);

@override
String toString() {
  return 'Milestone(title: $title, daysAway: $daysAway, rewardLabel: $rewardLabel)';
}


}

/// @nodoc
abstract mixin class _$MilestoneCopyWith<$Res> implements $MilestoneCopyWith<$Res> {
  factory _$MilestoneCopyWith(_Milestone value, $Res Function(_Milestone) _then) = __$MilestoneCopyWithImpl;
@override @useResult
$Res call({
 String title, int daysAway, String rewardLabel
});




}
/// @nodoc
class __$MilestoneCopyWithImpl<$Res>
    implements _$MilestoneCopyWith<$Res> {
  __$MilestoneCopyWithImpl(this._self, this._then);

  final _Milestone _self;
  final $Res Function(_Milestone) _then;

/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? daysAway = null,Object? rewardLabel = null,}) {
  return _then(_Milestone(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,daysAway: null == daysAway ? _self.daysAway : daysAway // ignore: cast_nullable_to_non_nullable
as int,rewardLabel: null == rewardLabel ? _self.rewardLabel : rewardLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StreakStatus {

 int get currentStreak; int get freezesLeft; List<StreakDay> get days; List<Milestone> get milestones;
/// Create a copy of StreakStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakStatusCopyWith<StreakStatus> get copyWith => _$StreakStatusCopyWithImpl<StreakStatus>(this as StreakStatus, _$identity);

  /// Serializes this StreakStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakStatus&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.freezesLeft, freezesLeft) || other.freezesLeft == freezesLeft)&&const DeepCollectionEquality().equals(other.days, days)&&const DeepCollectionEquality().equals(other.milestones, milestones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentStreak,freezesLeft,const DeepCollectionEquality().hash(days),const DeepCollectionEquality().hash(milestones));

@override
String toString() {
  return 'StreakStatus(currentStreak: $currentStreak, freezesLeft: $freezesLeft, days: $days, milestones: $milestones)';
}


}

/// @nodoc
abstract mixin class $StreakStatusCopyWith<$Res>  {
  factory $StreakStatusCopyWith(StreakStatus value, $Res Function(StreakStatus) _then) = _$StreakStatusCopyWithImpl;
@useResult
$Res call({
 int currentStreak, int freezesLeft, List<StreakDay> days, List<Milestone> milestones
});




}
/// @nodoc
class _$StreakStatusCopyWithImpl<$Res>
    implements $StreakStatusCopyWith<$Res> {
  _$StreakStatusCopyWithImpl(this._self, this._then);

  final StreakStatus _self;
  final $Res Function(StreakStatus) _then;

/// Create a copy of StreakStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStreak = null,Object? freezesLeft = null,Object? days = null,Object? milestones = null,}) {
  return _then(_self.copyWith(
currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,freezesLeft: null == freezesLeft ? _self.freezesLeft : freezesLeft // ignore: cast_nullable_to_non_nullable
as int,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<StreakDay>,milestones: null == milestones ? _self.milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<Milestone>,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakStatus].
extension StreakStatusPatterns on StreakStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakStatus value)  $default,){
final _that = this;
switch (_that) {
case _StreakStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakStatus value)?  $default,){
final _that = this;
switch (_that) {
case _StreakStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStreak,  int freezesLeft,  List<StreakDay> days,  List<Milestone> milestones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakStatus() when $default != null:
return $default(_that.currentStreak,_that.freezesLeft,_that.days,_that.milestones);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStreak,  int freezesLeft,  List<StreakDay> days,  List<Milestone> milestones)  $default,) {final _that = this;
switch (_that) {
case _StreakStatus():
return $default(_that.currentStreak,_that.freezesLeft,_that.days,_that.milestones);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStreak,  int freezesLeft,  List<StreakDay> days,  List<Milestone> milestones)?  $default,) {final _that = this;
switch (_that) {
case _StreakStatus() when $default != null:
return $default(_that.currentStreak,_that.freezesLeft,_that.days,_that.milestones);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakStatus implements StreakStatus {
  const _StreakStatus({required this.currentStreak, required this.freezesLeft, required final  List<StreakDay> days, required final  List<Milestone> milestones}): _days = days,_milestones = milestones;
  factory _StreakStatus.fromJson(Map<String, dynamic> json) => _$StreakStatusFromJson(json);

@override final  int currentStreak;
@override final  int freezesLeft;
 final  List<StreakDay> _days;
@override List<StreakDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

 final  List<Milestone> _milestones;
@override List<Milestone> get milestones {
  if (_milestones is EqualUnmodifiableListView) return _milestones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_milestones);
}


/// Create a copy of StreakStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakStatusCopyWith<_StreakStatus> get copyWith => __$StreakStatusCopyWithImpl<_StreakStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakStatus&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.freezesLeft, freezesLeft) || other.freezesLeft == freezesLeft)&&const DeepCollectionEquality().equals(other._days, _days)&&const DeepCollectionEquality().equals(other._milestones, _milestones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentStreak,freezesLeft,const DeepCollectionEquality().hash(_days),const DeepCollectionEquality().hash(_milestones));

@override
String toString() {
  return 'StreakStatus(currentStreak: $currentStreak, freezesLeft: $freezesLeft, days: $days, milestones: $milestones)';
}


}

/// @nodoc
abstract mixin class _$StreakStatusCopyWith<$Res> implements $StreakStatusCopyWith<$Res> {
  factory _$StreakStatusCopyWith(_StreakStatus value, $Res Function(_StreakStatus) _then) = __$StreakStatusCopyWithImpl;
@override @useResult
$Res call({
 int currentStreak, int freezesLeft, List<StreakDay> days, List<Milestone> milestones
});




}
/// @nodoc
class __$StreakStatusCopyWithImpl<$Res>
    implements _$StreakStatusCopyWith<$Res> {
  __$StreakStatusCopyWithImpl(this._self, this._then);

  final _StreakStatus _self;
  final $Res Function(_StreakStatus) _then;

/// Create a copy of StreakStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStreak = null,Object? freezesLeft = null,Object? days = null,Object? milestones = null,}) {
  return _then(_StreakStatus(
currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,freezesLeft: null == freezesLeft ? _self.freezesLeft : freezesLeft // ignore: cast_nullable_to_non_nullable
as int,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<StreakDay>,milestones: null == milestones ? _self._milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<Milestone>,
  ));
}


}

// dart format on
