// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duel_side_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuelSideResult {

 int get eloBefore; int get eloAfter; int get coins; int get xp; List<String> get badgeIds;
/// Create a copy of DuelSideResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuelSideResultCopyWith<DuelSideResult> get copyWith => _$DuelSideResultCopyWithImpl<DuelSideResult>(this as DuelSideResult, _$identity);

  /// Serializes this DuelSideResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuelSideResult&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.xp, xp) || other.xp == xp)&&const DeepCollectionEquality().equals(other.badgeIds, badgeIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eloBefore,eloAfter,coins,xp,const DeepCollectionEquality().hash(badgeIds));

@override
String toString() {
  return 'DuelSideResult(eloBefore: $eloBefore, eloAfter: $eloAfter, coins: $coins, xp: $xp, badgeIds: $badgeIds)';
}


}

/// @nodoc
abstract mixin class $DuelSideResultCopyWith<$Res>  {
  factory $DuelSideResultCopyWith(DuelSideResult value, $Res Function(DuelSideResult) _then) = _$DuelSideResultCopyWithImpl;
@useResult
$Res call({
 int eloBefore, int eloAfter, int coins, int xp, List<String> badgeIds
});




}
/// @nodoc
class _$DuelSideResultCopyWithImpl<$Res>
    implements $DuelSideResultCopyWith<$Res> {
  _$DuelSideResultCopyWithImpl(this._self, this._then);

  final DuelSideResult _self;
  final $Res Function(DuelSideResult) _then;

/// Create a copy of DuelSideResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eloBefore = null,Object? eloAfter = null,Object? coins = null,Object? xp = null,Object? badgeIds = null,}) {
  return _then(_self.copyWith(
eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,badgeIds: null == badgeIds ? _self.badgeIds : badgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DuelSideResult].
extension DuelSideResultPatterns on DuelSideResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuelSideResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuelSideResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuelSideResult value)  $default,){
final _that = this;
switch (_that) {
case _DuelSideResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuelSideResult value)?  $default,){
final _that = this;
switch (_that) {
case _DuelSideResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int eloBefore,  int eloAfter,  int coins,  int xp,  List<String> badgeIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuelSideResult() when $default != null:
return $default(_that.eloBefore,_that.eloAfter,_that.coins,_that.xp,_that.badgeIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int eloBefore,  int eloAfter,  int coins,  int xp,  List<String> badgeIds)  $default,) {final _that = this;
switch (_that) {
case _DuelSideResult():
return $default(_that.eloBefore,_that.eloAfter,_that.coins,_that.xp,_that.badgeIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int eloBefore,  int eloAfter,  int coins,  int xp,  List<String> badgeIds)?  $default,) {final _that = this;
switch (_that) {
case _DuelSideResult() when $default != null:
return $default(_that.eloBefore,_that.eloAfter,_that.coins,_that.xp,_that.badgeIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuelSideResult implements DuelSideResult {
  const _DuelSideResult({required this.eloBefore, required this.eloAfter, this.coins = 0, this.xp = 0, final  List<String> badgeIds = const []}): _badgeIds = badgeIds;
  factory _DuelSideResult.fromJson(Map<String, dynamic> json) => _$DuelSideResultFromJson(json);

@override final  int eloBefore;
@override final  int eloAfter;
@override@JsonKey() final  int coins;
@override@JsonKey() final  int xp;
 final  List<String> _badgeIds;
@override@JsonKey() List<String> get badgeIds {
  if (_badgeIds is EqualUnmodifiableListView) return _badgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badgeIds);
}


/// Create a copy of DuelSideResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuelSideResultCopyWith<_DuelSideResult> get copyWith => __$DuelSideResultCopyWithImpl<_DuelSideResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuelSideResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuelSideResult&&(identical(other.eloBefore, eloBefore) || other.eloBefore == eloBefore)&&(identical(other.eloAfter, eloAfter) || other.eloAfter == eloAfter)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.xp, xp) || other.xp == xp)&&const DeepCollectionEquality().equals(other._badgeIds, _badgeIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eloBefore,eloAfter,coins,xp,const DeepCollectionEquality().hash(_badgeIds));

@override
String toString() {
  return 'DuelSideResult(eloBefore: $eloBefore, eloAfter: $eloAfter, coins: $coins, xp: $xp, badgeIds: $badgeIds)';
}


}

/// @nodoc
abstract mixin class _$DuelSideResultCopyWith<$Res> implements $DuelSideResultCopyWith<$Res> {
  factory _$DuelSideResultCopyWith(_DuelSideResult value, $Res Function(_DuelSideResult) _then) = __$DuelSideResultCopyWithImpl;
@override @useResult
$Res call({
 int eloBefore, int eloAfter, int coins, int xp, List<String> badgeIds
});




}
/// @nodoc
class __$DuelSideResultCopyWithImpl<$Res>
    implements _$DuelSideResultCopyWith<$Res> {
  __$DuelSideResultCopyWithImpl(this._self, this._then);

  final _DuelSideResult _self;
  final $Res Function(_DuelSideResult) _then;

/// Create a copy of DuelSideResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eloBefore = null,Object? eloAfter = null,Object? coins = null,Object? xp = null,Object? badgeIds = null,}) {
  return _then(_DuelSideResult(
eloBefore: null == eloBefore ? _self.eloBefore : eloBefore // ignore: cast_nullable_to_non_nullable
as int,eloAfter: null == eloAfter ? _self.eloAfter : eloAfter // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,badgeIds: null == badgeIds ? _self._badgeIds : badgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
