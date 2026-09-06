// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BestCategoryEntry {

 String get subcategoryId; String get name; String get emoji; String get plateColor; int get levelsCleared; int get levelCount; int get starsEarned; int get accuracyPercent;
/// Create a copy of BestCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BestCategoryEntryCopyWith<BestCategoryEntry> get copyWith => _$BestCategoryEntryCopyWithImpl<BestCategoryEntry>(this as BestCategoryEntry, _$identity);

  /// Serializes this BestCategoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BestCategoryEntry&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.accuracyPercent, accuracyPercent) || other.accuracyPercent == accuracyPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subcategoryId,name,emoji,plateColor,levelsCleared,levelCount,starsEarned,accuracyPercent);

@override
String toString() {
  return 'BestCategoryEntry(subcategoryId: $subcategoryId, name: $name, emoji: $emoji, plateColor: $plateColor, levelsCleared: $levelsCleared, levelCount: $levelCount, starsEarned: $starsEarned, accuracyPercent: $accuracyPercent)';
}


}

/// @nodoc
abstract mixin class $BestCategoryEntryCopyWith<$Res>  {
  factory $BestCategoryEntryCopyWith(BestCategoryEntry value, $Res Function(BestCategoryEntry) _then) = _$BestCategoryEntryCopyWithImpl;
@useResult
$Res call({
 String subcategoryId, String name, String emoji, String plateColor, int levelsCleared, int levelCount, int starsEarned, int accuracyPercent
});




}
/// @nodoc
class _$BestCategoryEntryCopyWithImpl<$Res>
    implements $BestCategoryEntryCopyWith<$Res> {
  _$BestCategoryEntryCopyWithImpl(this._self, this._then);

  final BestCategoryEntry _self;
  final $Res Function(BestCategoryEntry) _then;

/// Create a copy of BestCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subcategoryId = null,Object? name = null,Object? emoji = null,Object? plateColor = null,Object? levelsCleared = null,Object? levelCount = null,Object? starsEarned = null,Object? accuracyPercent = null,}) {
  return _then(_self.copyWith(
subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,levelCount: null == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,accuracyPercent: null == accuracyPercent ? _self.accuracyPercent : accuracyPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BestCategoryEntry].
extension BestCategoryEntryPatterns on BestCategoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BestCategoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BestCategoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BestCategoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _BestCategoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BestCategoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BestCategoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subcategoryId,  String name,  String emoji,  String plateColor,  int levelsCleared,  int levelCount,  int starsEarned,  int accuracyPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BestCategoryEntry() when $default != null:
return $default(_that.subcategoryId,_that.name,_that.emoji,_that.plateColor,_that.levelsCleared,_that.levelCount,_that.starsEarned,_that.accuracyPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subcategoryId,  String name,  String emoji,  String plateColor,  int levelsCleared,  int levelCount,  int starsEarned,  int accuracyPercent)  $default,) {final _that = this;
switch (_that) {
case _BestCategoryEntry():
return $default(_that.subcategoryId,_that.name,_that.emoji,_that.plateColor,_that.levelsCleared,_that.levelCount,_that.starsEarned,_that.accuracyPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subcategoryId,  String name,  String emoji,  String plateColor,  int levelsCleared,  int levelCount,  int starsEarned,  int accuracyPercent)?  $default,) {final _that = this;
switch (_that) {
case _BestCategoryEntry() when $default != null:
return $default(_that.subcategoryId,_that.name,_that.emoji,_that.plateColor,_that.levelsCleared,_that.levelCount,_that.starsEarned,_that.accuracyPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BestCategoryEntry implements BestCategoryEntry {
  const _BestCategoryEntry({required this.subcategoryId, required this.name, required this.emoji, required this.plateColor, required this.levelsCleared, required this.levelCount, required this.starsEarned, required this.accuracyPercent});
  factory _BestCategoryEntry.fromJson(Map<String, dynamic> json) => _$BestCategoryEntryFromJson(json);

@override final  String subcategoryId;
@override final  String name;
@override final  String emoji;
@override final  String plateColor;
@override final  int levelsCleared;
@override final  int levelCount;
@override final  int starsEarned;
@override final  int accuracyPercent;

/// Create a copy of BestCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BestCategoryEntryCopyWith<_BestCategoryEntry> get copyWith => __$BestCategoryEntryCopyWithImpl<_BestCategoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BestCategoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BestCategoryEntry&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.plateColor, plateColor) || other.plateColor == plateColor)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.accuracyPercent, accuracyPercent) || other.accuracyPercent == accuracyPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subcategoryId,name,emoji,plateColor,levelsCleared,levelCount,starsEarned,accuracyPercent);

@override
String toString() {
  return 'BestCategoryEntry(subcategoryId: $subcategoryId, name: $name, emoji: $emoji, plateColor: $plateColor, levelsCleared: $levelsCleared, levelCount: $levelCount, starsEarned: $starsEarned, accuracyPercent: $accuracyPercent)';
}


}

/// @nodoc
abstract mixin class _$BestCategoryEntryCopyWith<$Res> implements $BestCategoryEntryCopyWith<$Res> {
  factory _$BestCategoryEntryCopyWith(_BestCategoryEntry value, $Res Function(_BestCategoryEntry) _then) = __$BestCategoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String subcategoryId, String name, String emoji, String plateColor, int levelsCleared, int levelCount, int starsEarned, int accuracyPercent
});




}
/// @nodoc
class __$BestCategoryEntryCopyWithImpl<$Res>
    implements _$BestCategoryEntryCopyWith<$Res> {
  __$BestCategoryEntryCopyWithImpl(this._self, this._then);

  final _BestCategoryEntry _self;
  final $Res Function(_BestCategoryEntry) _then;

/// Create a copy of BestCategoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subcategoryId = null,Object? name = null,Object? emoji = null,Object? plateColor = null,Object? levelsCleared = null,Object? levelCount = null,Object? starsEarned = null,Object? accuracyPercent = null,}) {
  return _then(_BestCategoryEntry(
subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,plateColor: null == plateColor ? _self.plateColor : plateColor // ignore: cast_nullable_to_non_nullable
as String,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,levelCount: null == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,accuracyPercent: null == accuracyPercent ? _self.accuracyPercent : accuracyPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProfileSummary {

 String get username; String get avatarEmoji;/// "🇵🇰 Islamabad".
 String get cityLabel;/// "Joined Mar 2026".
 String get joinedLabel; String get leagueEmoji; String get leagueName; int get dayStreak; int get playerLevel; String get rankTitle; int get xpIntoLevel; int get xpToNextLevel; int get totalPoints; int get totalLevels; int get accuracyPercent; int get badgeCount; List<AppBadge> get recentBadges; List<BestCategoryEntry> get bestCategories;
/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileSummaryCopyWith<ProfileSummary> get copyWith => _$ProfileSummaryCopyWithImpl<ProfileSummary>(this as ProfileSummary, _$identity);

  /// Serializes this ProfileSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileSummary&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.cityLabel, cityLabel) || other.cityLabel == cityLabel)&&(identical(other.joinedLabel, joinedLabel) || other.joinedLabel == joinedLabel)&&(identical(other.leagueEmoji, leagueEmoji) || other.leagueEmoji == leagueEmoji)&&(identical(other.leagueName, leagueName) || other.leagueName == leagueName)&&(identical(other.dayStreak, dayStreak) || other.dayStreak == dayStreak)&&(identical(other.playerLevel, playerLevel) || other.playerLevel == playerLevel)&&(identical(other.rankTitle, rankTitle) || other.rankTitle == rankTitle)&&(identical(other.xpIntoLevel, xpIntoLevel) || other.xpIntoLevel == xpIntoLevel)&&(identical(other.xpToNextLevel, xpToNextLevel) || other.xpToNextLevel == xpToNextLevel)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.totalLevels, totalLevels) || other.totalLevels == totalLevels)&&(identical(other.accuracyPercent, accuracyPercent) || other.accuracyPercent == accuracyPercent)&&(identical(other.badgeCount, badgeCount) || other.badgeCount == badgeCount)&&const DeepCollectionEquality().equals(other.recentBadges, recentBadges)&&const DeepCollectionEquality().equals(other.bestCategories, bestCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,avatarEmoji,cityLabel,joinedLabel,leagueEmoji,leagueName,dayStreak,playerLevel,rankTitle,xpIntoLevel,xpToNextLevel,totalPoints,totalLevels,accuracyPercent,badgeCount,const DeepCollectionEquality().hash(recentBadges),const DeepCollectionEquality().hash(bestCategories));

@override
String toString() {
  return 'ProfileSummary(username: $username, avatarEmoji: $avatarEmoji, cityLabel: $cityLabel, joinedLabel: $joinedLabel, leagueEmoji: $leagueEmoji, leagueName: $leagueName, dayStreak: $dayStreak, playerLevel: $playerLevel, rankTitle: $rankTitle, xpIntoLevel: $xpIntoLevel, xpToNextLevel: $xpToNextLevel, totalPoints: $totalPoints, totalLevels: $totalLevels, accuracyPercent: $accuracyPercent, badgeCount: $badgeCount, recentBadges: $recentBadges, bestCategories: $bestCategories)';
}


}

/// @nodoc
abstract mixin class $ProfileSummaryCopyWith<$Res>  {
  factory $ProfileSummaryCopyWith(ProfileSummary value, $Res Function(ProfileSummary) _then) = _$ProfileSummaryCopyWithImpl;
@useResult
$Res call({
 String username, String avatarEmoji, String cityLabel, String joinedLabel, String leagueEmoji, String leagueName, int dayStreak, int playerLevel, String rankTitle, int xpIntoLevel, int xpToNextLevel, int totalPoints, int totalLevels, int accuracyPercent, int badgeCount, List<AppBadge> recentBadges, List<BestCategoryEntry> bestCategories
});




}
/// @nodoc
class _$ProfileSummaryCopyWithImpl<$Res>
    implements $ProfileSummaryCopyWith<$Res> {
  _$ProfileSummaryCopyWithImpl(this._self, this._then);

  final ProfileSummary _self;
  final $Res Function(ProfileSummary) _then;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? avatarEmoji = null,Object? cityLabel = null,Object? joinedLabel = null,Object? leagueEmoji = null,Object? leagueName = null,Object? dayStreak = null,Object? playerLevel = null,Object? rankTitle = null,Object? xpIntoLevel = null,Object? xpToNextLevel = null,Object? totalPoints = null,Object? totalLevels = null,Object? accuracyPercent = null,Object? badgeCount = null,Object? recentBadges = null,Object? bestCategories = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,cityLabel: null == cityLabel ? _self.cityLabel : cityLabel // ignore: cast_nullable_to_non_nullable
as String,joinedLabel: null == joinedLabel ? _self.joinedLabel : joinedLabel // ignore: cast_nullable_to_non_nullable
as String,leagueEmoji: null == leagueEmoji ? _self.leagueEmoji : leagueEmoji // ignore: cast_nullable_to_non_nullable
as String,leagueName: null == leagueName ? _self.leagueName : leagueName // ignore: cast_nullable_to_non_nullable
as String,dayStreak: null == dayStreak ? _self.dayStreak : dayStreak // ignore: cast_nullable_to_non_nullable
as int,playerLevel: null == playerLevel ? _self.playerLevel : playerLevel // ignore: cast_nullable_to_non_nullable
as int,rankTitle: null == rankTitle ? _self.rankTitle : rankTitle // ignore: cast_nullable_to_non_nullable
as String,xpIntoLevel: null == xpIntoLevel ? _self.xpIntoLevel : xpIntoLevel // ignore: cast_nullable_to_non_nullable
as int,xpToNextLevel: null == xpToNextLevel ? _self.xpToNextLevel : xpToNextLevel // ignore: cast_nullable_to_non_nullable
as int,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,totalLevels: null == totalLevels ? _self.totalLevels : totalLevels // ignore: cast_nullable_to_non_nullable
as int,accuracyPercent: null == accuracyPercent ? _self.accuracyPercent : accuracyPercent // ignore: cast_nullable_to_non_nullable
as int,badgeCount: null == badgeCount ? _self.badgeCount : badgeCount // ignore: cast_nullable_to_non_nullable
as int,recentBadges: null == recentBadges ? _self.recentBadges : recentBadges // ignore: cast_nullable_to_non_nullable
as List<AppBadge>,bestCategories: null == bestCategories ? _self.bestCategories : bestCategories // ignore: cast_nullable_to_non_nullable
as List<BestCategoryEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileSummary].
extension ProfileSummaryPatterns on ProfileSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProfileSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String avatarEmoji,  String cityLabel,  String joinedLabel,  String leagueEmoji,  String leagueName,  int dayStreak,  int playerLevel,  String rankTitle,  int xpIntoLevel,  int xpToNextLevel,  int totalPoints,  int totalLevels,  int accuracyPercent,  int badgeCount,  List<AppBadge> recentBadges,  List<BestCategoryEntry> bestCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that.username,_that.avatarEmoji,_that.cityLabel,_that.joinedLabel,_that.leagueEmoji,_that.leagueName,_that.dayStreak,_that.playerLevel,_that.rankTitle,_that.xpIntoLevel,_that.xpToNextLevel,_that.totalPoints,_that.totalLevels,_that.accuracyPercent,_that.badgeCount,_that.recentBadges,_that.bestCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String avatarEmoji,  String cityLabel,  String joinedLabel,  String leagueEmoji,  String leagueName,  int dayStreak,  int playerLevel,  String rankTitle,  int xpIntoLevel,  int xpToNextLevel,  int totalPoints,  int totalLevels,  int accuracyPercent,  int badgeCount,  List<AppBadge> recentBadges,  List<BestCategoryEntry> bestCategories)  $default,) {final _that = this;
switch (_that) {
case _ProfileSummary():
return $default(_that.username,_that.avatarEmoji,_that.cityLabel,_that.joinedLabel,_that.leagueEmoji,_that.leagueName,_that.dayStreak,_that.playerLevel,_that.rankTitle,_that.xpIntoLevel,_that.xpToNextLevel,_that.totalPoints,_that.totalLevels,_that.accuracyPercent,_that.badgeCount,_that.recentBadges,_that.bestCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String avatarEmoji,  String cityLabel,  String joinedLabel,  String leagueEmoji,  String leagueName,  int dayStreak,  int playerLevel,  String rankTitle,  int xpIntoLevel,  int xpToNextLevel,  int totalPoints,  int totalLevels,  int accuracyPercent,  int badgeCount,  List<AppBadge> recentBadges,  List<BestCategoryEntry> bestCategories)?  $default,) {final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that.username,_that.avatarEmoji,_that.cityLabel,_that.joinedLabel,_that.leagueEmoji,_that.leagueName,_that.dayStreak,_that.playerLevel,_that.rankTitle,_that.xpIntoLevel,_that.xpToNextLevel,_that.totalPoints,_that.totalLevels,_that.accuracyPercent,_that.badgeCount,_that.recentBadges,_that.bestCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileSummary extends ProfileSummary {
  const _ProfileSummary({required this.username, required this.avatarEmoji, required this.cityLabel, required this.joinedLabel, required this.leagueEmoji, required this.leagueName, required this.dayStreak, required this.playerLevel, required this.rankTitle, required this.xpIntoLevel, required this.xpToNextLevel, required this.totalPoints, required this.totalLevels, required this.accuracyPercent, required this.badgeCount, required final  List<AppBadge> recentBadges, required final  List<BestCategoryEntry> bestCategories}): _recentBadges = recentBadges,_bestCategories = bestCategories,super._();
  factory _ProfileSummary.fromJson(Map<String, dynamic> json) => _$ProfileSummaryFromJson(json);

@override final  String username;
@override final  String avatarEmoji;
/// "🇵🇰 Islamabad".
@override final  String cityLabel;
/// "Joined Mar 2026".
@override final  String joinedLabel;
@override final  String leagueEmoji;
@override final  String leagueName;
@override final  int dayStreak;
@override final  int playerLevel;
@override final  String rankTitle;
@override final  int xpIntoLevel;
@override final  int xpToNextLevel;
@override final  int totalPoints;
@override final  int totalLevels;
@override final  int accuracyPercent;
@override final  int badgeCount;
 final  List<AppBadge> _recentBadges;
@override List<AppBadge> get recentBadges {
  if (_recentBadges is EqualUnmodifiableListView) return _recentBadges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentBadges);
}

 final  List<BestCategoryEntry> _bestCategories;
@override List<BestCategoryEntry> get bestCategories {
  if (_bestCategories is EqualUnmodifiableListView) return _bestCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bestCategories);
}


/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileSummaryCopyWith<_ProfileSummary> get copyWith => __$ProfileSummaryCopyWithImpl<_ProfileSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileSummary&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.cityLabel, cityLabel) || other.cityLabel == cityLabel)&&(identical(other.joinedLabel, joinedLabel) || other.joinedLabel == joinedLabel)&&(identical(other.leagueEmoji, leagueEmoji) || other.leagueEmoji == leagueEmoji)&&(identical(other.leagueName, leagueName) || other.leagueName == leagueName)&&(identical(other.dayStreak, dayStreak) || other.dayStreak == dayStreak)&&(identical(other.playerLevel, playerLevel) || other.playerLevel == playerLevel)&&(identical(other.rankTitle, rankTitle) || other.rankTitle == rankTitle)&&(identical(other.xpIntoLevel, xpIntoLevel) || other.xpIntoLevel == xpIntoLevel)&&(identical(other.xpToNextLevel, xpToNextLevel) || other.xpToNextLevel == xpToNextLevel)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.totalLevels, totalLevels) || other.totalLevels == totalLevels)&&(identical(other.accuracyPercent, accuracyPercent) || other.accuracyPercent == accuracyPercent)&&(identical(other.badgeCount, badgeCount) || other.badgeCount == badgeCount)&&const DeepCollectionEquality().equals(other._recentBadges, _recentBadges)&&const DeepCollectionEquality().equals(other._bestCategories, _bestCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,avatarEmoji,cityLabel,joinedLabel,leagueEmoji,leagueName,dayStreak,playerLevel,rankTitle,xpIntoLevel,xpToNextLevel,totalPoints,totalLevels,accuracyPercent,badgeCount,const DeepCollectionEquality().hash(_recentBadges),const DeepCollectionEquality().hash(_bestCategories));

@override
String toString() {
  return 'ProfileSummary(username: $username, avatarEmoji: $avatarEmoji, cityLabel: $cityLabel, joinedLabel: $joinedLabel, leagueEmoji: $leagueEmoji, leagueName: $leagueName, dayStreak: $dayStreak, playerLevel: $playerLevel, rankTitle: $rankTitle, xpIntoLevel: $xpIntoLevel, xpToNextLevel: $xpToNextLevel, totalPoints: $totalPoints, totalLevels: $totalLevels, accuracyPercent: $accuracyPercent, badgeCount: $badgeCount, recentBadges: $recentBadges, bestCategories: $bestCategories)';
}


}

/// @nodoc
abstract mixin class _$ProfileSummaryCopyWith<$Res> implements $ProfileSummaryCopyWith<$Res> {
  factory _$ProfileSummaryCopyWith(_ProfileSummary value, $Res Function(_ProfileSummary) _then) = __$ProfileSummaryCopyWithImpl;
@override @useResult
$Res call({
 String username, String avatarEmoji, String cityLabel, String joinedLabel, String leagueEmoji, String leagueName, int dayStreak, int playerLevel, String rankTitle, int xpIntoLevel, int xpToNextLevel, int totalPoints, int totalLevels, int accuracyPercent, int badgeCount, List<AppBadge> recentBadges, List<BestCategoryEntry> bestCategories
});




}
/// @nodoc
class __$ProfileSummaryCopyWithImpl<$Res>
    implements _$ProfileSummaryCopyWith<$Res> {
  __$ProfileSummaryCopyWithImpl(this._self, this._then);

  final _ProfileSummary _self;
  final $Res Function(_ProfileSummary) _then;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? avatarEmoji = null,Object? cityLabel = null,Object? joinedLabel = null,Object? leagueEmoji = null,Object? leagueName = null,Object? dayStreak = null,Object? playerLevel = null,Object? rankTitle = null,Object? xpIntoLevel = null,Object? xpToNextLevel = null,Object? totalPoints = null,Object? totalLevels = null,Object? accuracyPercent = null,Object? badgeCount = null,Object? recentBadges = null,Object? bestCategories = null,}) {
  return _then(_ProfileSummary(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,cityLabel: null == cityLabel ? _self.cityLabel : cityLabel // ignore: cast_nullable_to_non_nullable
as String,joinedLabel: null == joinedLabel ? _self.joinedLabel : joinedLabel // ignore: cast_nullable_to_non_nullable
as String,leagueEmoji: null == leagueEmoji ? _self.leagueEmoji : leagueEmoji // ignore: cast_nullable_to_non_nullable
as String,leagueName: null == leagueName ? _self.leagueName : leagueName // ignore: cast_nullable_to_non_nullable
as String,dayStreak: null == dayStreak ? _self.dayStreak : dayStreak // ignore: cast_nullable_to_non_nullable
as int,playerLevel: null == playerLevel ? _self.playerLevel : playerLevel // ignore: cast_nullable_to_non_nullable
as int,rankTitle: null == rankTitle ? _self.rankTitle : rankTitle // ignore: cast_nullable_to_non_nullable
as String,xpIntoLevel: null == xpIntoLevel ? _self.xpIntoLevel : xpIntoLevel // ignore: cast_nullable_to_non_nullable
as int,xpToNextLevel: null == xpToNextLevel ? _self.xpToNextLevel : xpToNextLevel // ignore: cast_nullable_to_non_nullable
as int,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,totalLevels: null == totalLevels ? _self.totalLevels : totalLevels // ignore: cast_nullable_to_non_nullable
as int,accuracyPercent: null == accuracyPercent ? _self.accuracyPercent : accuracyPercent // ignore: cast_nullable_to_non_nullable
as int,badgeCount: null == badgeCount ? _self.badgeCount : badgeCount // ignore: cast_nullable_to_non_nullable
as int,recentBadges: null == recentBadges ? _self._recentBadges : recentBadges // ignore: cast_nullable_to_non_nullable
as List<AppBadge>,bestCategories: null == bestCategories ? _self._bestCategories : bestCategories // ignore: cast_nullable_to_non_nullable
as List<BestCategoryEntry>,
  ));
}


}

// dart format on
