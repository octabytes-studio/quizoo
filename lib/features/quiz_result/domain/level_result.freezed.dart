// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LevelResult {

 QuizRun get run;/// 0…3 (§19). Never shown on a failed run — there is nothing to grey out.
 int get stars; int get finalScore; int get coinsEarned; int get xpEarned;/// Where the player's XP bar sits after this run.
 int get playerLevel; int get xpIntoLevel; int get xpToNextLevel;/// True the first time this level is cleared, which pays a bonus.
 bool get isFirstClear;/// Badge ids newly earned by this run. The result screen pushes S-23's
/// route for the first of them — it never imports `features/achievements`
/// (plan 001's no-cross-feature-orchestration rule).
 List<String> get newlyEarnedBadgeIds;/// True when S-24 is allowed to appear after this run: a successful first
/// level, a guest, and not already offered.
 bool get shouldOfferSaveProgress;/// True when this run was played on the ladder's last level (30), so
/// there is no next level to offer.
 bool get isFinalLevel;/// True when this run just mastered the topic: the final level, cleared,
/// for the first time. Drives the Topic Mastered push (plan 020).
 bool get unlocksMastery;
/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelResultCopyWith<LevelResult> get copyWith => _$LevelResultCopyWithImpl<LevelResult>(this as LevelResult, _$identity);

  /// Serializes this LevelResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelResult&&(identical(other.run, run) || other.run == run)&&(identical(other.stars, stars) || other.stars == stars)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.coinsEarned, coinsEarned) || other.coinsEarned == coinsEarned)&&(identical(other.xpEarned, xpEarned) || other.xpEarned == xpEarned)&&(identical(other.playerLevel, playerLevel) || other.playerLevel == playerLevel)&&(identical(other.xpIntoLevel, xpIntoLevel) || other.xpIntoLevel == xpIntoLevel)&&(identical(other.xpToNextLevel, xpToNextLevel) || other.xpToNextLevel == xpToNextLevel)&&(identical(other.isFirstClear, isFirstClear) || other.isFirstClear == isFirstClear)&&const DeepCollectionEquality().equals(other.newlyEarnedBadgeIds, newlyEarnedBadgeIds)&&(identical(other.shouldOfferSaveProgress, shouldOfferSaveProgress) || other.shouldOfferSaveProgress == shouldOfferSaveProgress)&&(identical(other.isFinalLevel, isFinalLevel) || other.isFinalLevel == isFinalLevel)&&(identical(other.unlocksMastery, unlocksMastery) || other.unlocksMastery == unlocksMastery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,run,stars,finalScore,coinsEarned,xpEarned,playerLevel,xpIntoLevel,xpToNextLevel,isFirstClear,const DeepCollectionEquality().hash(newlyEarnedBadgeIds),shouldOfferSaveProgress,isFinalLevel,unlocksMastery);

@override
String toString() {
  return 'LevelResult(run: $run, stars: $stars, finalScore: $finalScore, coinsEarned: $coinsEarned, xpEarned: $xpEarned, playerLevel: $playerLevel, xpIntoLevel: $xpIntoLevel, xpToNextLevel: $xpToNextLevel, isFirstClear: $isFirstClear, newlyEarnedBadgeIds: $newlyEarnedBadgeIds, shouldOfferSaveProgress: $shouldOfferSaveProgress, isFinalLevel: $isFinalLevel, unlocksMastery: $unlocksMastery)';
}


}

/// @nodoc
abstract mixin class $LevelResultCopyWith<$Res>  {
  factory $LevelResultCopyWith(LevelResult value, $Res Function(LevelResult) _then) = _$LevelResultCopyWithImpl;
@useResult
$Res call({
 QuizRun run, int stars, int finalScore, int coinsEarned, int xpEarned, int playerLevel, int xpIntoLevel, int xpToNextLevel, bool isFirstClear, List<String> newlyEarnedBadgeIds, bool shouldOfferSaveProgress, bool isFinalLevel, bool unlocksMastery
});


$QuizRunCopyWith<$Res> get run;

}
/// @nodoc
class _$LevelResultCopyWithImpl<$Res>
    implements $LevelResultCopyWith<$Res> {
  _$LevelResultCopyWithImpl(this._self, this._then);

  final LevelResult _self;
  final $Res Function(LevelResult) _then;

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? run = null,Object? stars = null,Object? finalScore = null,Object? coinsEarned = null,Object? xpEarned = null,Object? playerLevel = null,Object? xpIntoLevel = null,Object? xpToNextLevel = null,Object? isFirstClear = null,Object? newlyEarnedBadgeIds = null,Object? shouldOfferSaveProgress = null,Object? isFinalLevel = null,Object? unlocksMastery = null,}) {
  return _then(_self.copyWith(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as QuizRun,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as int,finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int,coinsEarned: null == coinsEarned ? _self.coinsEarned : coinsEarned // ignore: cast_nullable_to_non_nullable
as int,xpEarned: null == xpEarned ? _self.xpEarned : xpEarned // ignore: cast_nullable_to_non_nullable
as int,playerLevel: null == playerLevel ? _self.playerLevel : playerLevel // ignore: cast_nullable_to_non_nullable
as int,xpIntoLevel: null == xpIntoLevel ? _self.xpIntoLevel : xpIntoLevel // ignore: cast_nullable_to_non_nullable
as int,xpToNextLevel: null == xpToNextLevel ? _self.xpToNextLevel : xpToNextLevel // ignore: cast_nullable_to_non_nullable
as int,isFirstClear: null == isFirstClear ? _self.isFirstClear : isFirstClear // ignore: cast_nullable_to_non_nullable
as bool,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self.newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,shouldOfferSaveProgress: null == shouldOfferSaveProgress ? _self.shouldOfferSaveProgress : shouldOfferSaveProgress // ignore: cast_nullable_to_non_nullable
as bool,isFinalLevel: null == isFinalLevel ? _self.isFinalLevel : isFinalLevel // ignore: cast_nullable_to_non_nullable
as bool,unlocksMastery: null == unlocksMastery ? _self.unlocksMastery : unlocksMastery // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizRunCopyWith<$Res> get run {
  
  return $QuizRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}


/// Adds pattern-matching-related methods to [LevelResult].
extension LevelResultPatterns on LevelResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelResult value)  $default,){
final _that = this;
switch (_that) {
case _LevelResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelResult value)?  $default,){
final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QuizRun run,  int stars,  int finalScore,  int coinsEarned,  int xpEarned,  int playerLevel,  int xpIntoLevel,  int xpToNextLevel,  bool isFirstClear,  List<String> newlyEarnedBadgeIds,  bool shouldOfferSaveProgress,  bool isFinalLevel,  bool unlocksMastery)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
return $default(_that.run,_that.stars,_that.finalScore,_that.coinsEarned,_that.xpEarned,_that.playerLevel,_that.xpIntoLevel,_that.xpToNextLevel,_that.isFirstClear,_that.newlyEarnedBadgeIds,_that.shouldOfferSaveProgress,_that.isFinalLevel,_that.unlocksMastery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QuizRun run,  int stars,  int finalScore,  int coinsEarned,  int xpEarned,  int playerLevel,  int xpIntoLevel,  int xpToNextLevel,  bool isFirstClear,  List<String> newlyEarnedBadgeIds,  bool shouldOfferSaveProgress,  bool isFinalLevel,  bool unlocksMastery)  $default,) {final _that = this;
switch (_that) {
case _LevelResult():
return $default(_that.run,_that.stars,_that.finalScore,_that.coinsEarned,_that.xpEarned,_that.playerLevel,_that.xpIntoLevel,_that.xpToNextLevel,_that.isFirstClear,_that.newlyEarnedBadgeIds,_that.shouldOfferSaveProgress,_that.isFinalLevel,_that.unlocksMastery);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QuizRun run,  int stars,  int finalScore,  int coinsEarned,  int xpEarned,  int playerLevel,  int xpIntoLevel,  int xpToNextLevel,  bool isFirstClear,  List<String> newlyEarnedBadgeIds,  bool shouldOfferSaveProgress,  bool isFinalLevel,  bool unlocksMastery)?  $default,) {final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
return $default(_that.run,_that.stars,_that.finalScore,_that.coinsEarned,_that.xpEarned,_that.playerLevel,_that.xpIntoLevel,_that.xpToNextLevel,_that.isFirstClear,_that.newlyEarnedBadgeIds,_that.shouldOfferSaveProgress,_that.isFinalLevel,_that.unlocksMastery);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelResult extends LevelResult {
  const _LevelResult({required this.run, required this.stars, required this.finalScore, required this.coinsEarned, required this.xpEarned, required this.playerLevel, required this.xpIntoLevel, required this.xpToNextLevel, this.isFirstClear = false, final  List<String> newlyEarnedBadgeIds = const [], this.shouldOfferSaveProgress = false, this.isFinalLevel = false, this.unlocksMastery = false}): _newlyEarnedBadgeIds = newlyEarnedBadgeIds,super._();
  factory _LevelResult.fromJson(Map<String, dynamic> json) => _$LevelResultFromJson(json);

@override final  QuizRun run;
/// 0…3 (§19). Never shown on a failed run — there is nothing to grey out.
@override final  int stars;
@override final  int finalScore;
@override final  int coinsEarned;
@override final  int xpEarned;
/// Where the player's XP bar sits after this run.
@override final  int playerLevel;
@override final  int xpIntoLevel;
@override final  int xpToNextLevel;
/// True the first time this level is cleared, which pays a bonus.
@override@JsonKey() final  bool isFirstClear;
/// Badge ids newly earned by this run. The result screen pushes S-23's
/// route for the first of them — it never imports `features/achievements`
/// (plan 001's no-cross-feature-orchestration rule).
 final  List<String> _newlyEarnedBadgeIds;
/// Badge ids newly earned by this run. The result screen pushes S-23's
/// route for the first of them — it never imports `features/achievements`
/// (plan 001's no-cross-feature-orchestration rule).
@override@JsonKey() List<String> get newlyEarnedBadgeIds {
  if (_newlyEarnedBadgeIds is EqualUnmodifiableListView) return _newlyEarnedBadgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newlyEarnedBadgeIds);
}

/// True when S-24 is allowed to appear after this run: a successful first
/// level, a guest, and not already offered.
@override@JsonKey() final  bool shouldOfferSaveProgress;
/// True when this run was played on the ladder's last level (30), so
/// there is no next level to offer.
@override@JsonKey() final  bool isFinalLevel;
/// True when this run just mastered the topic: the final level, cleared,
/// for the first time. Drives the Topic Mastered push (plan 020).
@override@JsonKey() final  bool unlocksMastery;

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelResultCopyWith<_LevelResult> get copyWith => __$LevelResultCopyWithImpl<_LevelResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelResult&&(identical(other.run, run) || other.run == run)&&(identical(other.stars, stars) || other.stars == stars)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.coinsEarned, coinsEarned) || other.coinsEarned == coinsEarned)&&(identical(other.xpEarned, xpEarned) || other.xpEarned == xpEarned)&&(identical(other.playerLevel, playerLevel) || other.playerLevel == playerLevel)&&(identical(other.xpIntoLevel, xpIntoLevel) || other.xpIntoLevel == xpIntoLevel)&&(identical(other.xpToNextLevel, xpToNextLevel) || other.xpToNextLevel == xpToNextLevel)&&(identical(other.isFirstClear, isFirstClear) || other.isFirstClear == isFirstClear)&&const DeepCollectionEquality().equals(other._newlyEarnedBadgeIds, _newlyEarnedBadgeIds)&&(identical(other.shouldOfferSaveProgress, shouldOfferSaveProgress) || other.shouldOfferSaveProgress == shouldOfferSaveProgress)&&(identical(other.isFinalLevel, isFinalLevel) || other.isFinalLevel == isFinalLevel)&&(identical(other.unlocksMastery, unlocksMastery) || other.unlocksMastery == unlocksMastery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,run,stars,finalScore,coinsEarned,xpEarned,playerLevel,xpIntoLevel,xpToNextLevel,isFirstClear,const DeepCollectionEquality().hash(_newlyEarnedBadgeIds),shouldOfferSaveProgress,isFinalLevel,unlocksMastery);

@override
String toString() {
  return 'LevelResult(run: $run, stars: $stars, finalScore: $finalScore, coinsEarned: $coinsEarned, xpEarned: $xpEarned, playerLevel: $playerLevel, xpIntoLevel: $xpIntoLevel, xpToNextLevel: $xpToNextLevel, isFirstClear: $isFirstClear, newlyEarnedBadgeIds: $newlyEarnedBadgeIds, shouldOfferSaveProgress: $shouldOfferSaveProgress, isFinalLevel: $isFinalLevel, unlocksMastery: $unlocksMastery)';
}


}

/// @nodoc
abstract mixin class _$LevelResultCopyWith<$Res> implements $LevelResultCopyWith<$Res> {
  factory _$LevelResultCopyWith(_LevelResult value, $Res Function(_LevelResult) _then) = __$LevelResultCopyWithImpl;
@override @useResult
$Res call({
 QuizRun run, int stars, int finalScore, int coinsEarned, int xpEarned, int playerLevel, int xpIntoLevel, int xpToNextLevel, bool isFirstClear, List<String> newlyEarnedBadgeIds, bool shouldOfferSaveProgress, bool isFinalLevel, bool unlocksMastery
});


@override $QuizRunCopyWith<$Res> get run;

}
/// @nodoc
class __$LevelResultCopyWithImpl<$Res>
    implements _$LevelResultCopyWith<$Res> {
  __$LevelResultCopyWithImpl(this._self, this._then);

  final _LevelResult _self;
  final $Res Function(_LevelResult) _then;

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? run = null,Object? stars = null,Object? finalScore = null,Object? coinsEarned = null,Object? xpEarned = null,Object? playerLevel = null,Object? xpIntoLevel = null,Object? xpToNextLevel = null,Object? isFirstClear = null,Object? newlyEarnedBadgeIds = null,Object? shouldOfferSaveProgress = null,Object? isFinalLevel = null,Object? unlocksMastery = null,}) {
  return _then(_LevelResult(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as QuizRun,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as int,finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int,coinsEarned: null == coinsEarned ? _self.coinsEarned : coinsEarned // ignore: cast_nullable_to_non_nullable
as int,xpEarned: null == xpEarned ? _self.xpEarned : xpEarned // ignore: cast_nullable_to_non_nullable
as int,playerLevel: null == playerLevel ? _self.playerLevel : playerLevel // ignore: cast_nullable_to_non_nullable
as int,xpIntoLevel: null == xpIntoLevel ? _self.xpIntoLevel : xpIntoLevel // ignore: cast_nullable_to_non_nullable
as int,xpToNextLevel: null == xpToNextLevel ? _self.xpToNextLevel : xpToNextLevel // ignore: cast_nullable_to_non_nullable
as int,isFirstClear: null == isFirstClear ? _self.isFirstClear : isFirstClear // ignore: cast_nullable_to_non_nullable
as bool,newlyEarnedBadgeIds: null == newlyEarnedBadgeIds ? _self._newlyEarnedBadgeIds : newlyEarnedBadgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,shouldOfferSaveProgress: null == shouldOfferSaveProgress ? _self.shouldOfferSaveProgress : shouldOfferSaveProgress // ignore: cast_nullable_to_non_nullable
as bool,isFinalLevel: null == isFinalLevel ? _self.isFinalLevel : isFinalLevel // ignore: cast_nullable_to_non_nullable
as bool,unlocksMastery: null == unlocksMastery ? _self.unlocksMastery : unlocksMastery // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizRunCopyWith<$Res> get run {
  
  return $QuizRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}

// dart format on
