// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LeaderboardEntry {

 int get rank; String get playerId; String get name; String get avatarEmoji; int get score;/// "🇵🇰 Lahore" — flag plus city, as the bible always prints them
/// together. Null on a category board, which has no location line.
 String? get locationLabel;/// Positive = climbed, negative = dropped, zero = unchanged. Null when
/// there is no prior-period rank to compare against (a category board).
 int? get rankDelta;/// Set only on the player's own row.
 bool get isSelf;/// A Quizoo Pro member (plan 023) — drives the crown and the tick. From
/// `profiles.is_pro`, written only by the server.
 bool get isPro;/// "Top N%", shown only on the self row of a global/country board.
 int? get topPercent;/// Category-board-only progress line: "{levelsCleared}/{levelCount}
/// levels · {starsEarned} ⭐".
 int? get levelsCleared; int? get levelCount; int? get starsEarned;
/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaderboardEntryCopyWith<LeaderboardEntry> get copyWith => _$LeaderboardEntryCopyWithImpl<LeaderboardEntry>(this as LeaderboardEntry, _$identity);

  /// Serializes this LeaderboardEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaderboardEntry&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.score, score) || other.score == score)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel)&&(identical(other.rankDelta, rankDelta) || other.rankDelta == rankDelta)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf)&&(identical(other.isPro, isPro) || other.isPro == isPro)&&(identical(other.topPercent, topPercent) || other.topPercent == topPercent)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,playerId,name,avatarEmoji,score,locationLabel,rankDelta,isSelf,isPro,topPercent,levelsCleared,levelCount,starsEarned);

@override
String toString() {
  return 'LeaderboardEntry(rank: $rank, playerId: $playerId, name: $name, avatarEmoji: $avatarEmoji, score: $score, locationLabel: $locationLabel, rankDelta: $rankDelta, isSelf: $isSelf, isPro: $isPro, topPercent: $topPercent, levelsCleared: $levelsCleared, levelCount: $levelCount, starsEarned: $starsEarned)';
}


}

/// @nodoc
abstract mixin class $LeaderboardEntryCopyWith<$Res>  {
  factory $LeaderboardEntryCopyWith(LeaderboardEntry value, $Res Function(LeaderboardEntry) _then) = _$LeaderboardEntryCopyWithImpl;
@useResult
$Res call({
 int rank, String playerId, String name, String avatarEmoji, int score, String? locationLabel, int? rankDelta, bool isSelf, bool isPro, int? topPercent, int? levelsCleared, int? levelCount, int? starsEarned
});




}
/// @nodoc
class _$LeaderboardEntryCopyWithImpl<$Res>
    implements $LeaderboardEntryCopyWith<$Res> {
  _$LeaderboardEntryCopyWithImpl(this._self, this._then);

  final LeaderboardEntry _self;
  final $Res Function(LeaderboardEntry) _then;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? playerId = null,Object? name = null,Object? avatarEmoji = null,Object? score = null,Object? locationLabel = freezed,Object? rankDelta = freezed,Object? isSelf = null,Object? isPro = null,Object? topPercent = freezed,Object? levelsCleared = freezed,Object? levelCount = freezed,Object? starsEarned = freezed,}) {
  return _then(_self.copyWith(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,rankDelta: freezed == rankDelta ? _self.rankDelta : rankDelta // ignore: cast_nullable_to_non_nullable
as int?,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,topPercent: freezed == topPercent ? _self.topPercent : topPercent // ignore: cast_nullable_to_non_nullable
as int?,levelsCleared: freezed == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int?,levelCount: freezed == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int?,starsEarned: freezed == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaderboardEntry].
extension LeaderboardEntryPatterns on LeaderboardEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaderboardEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaderboardEntry value)  $default,){
final _that = this;
switch (_that) {
case _LeaderboardEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaderboardEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String playerId,  String name,  String avatarEmoji,  int score,  String? locationLabel,  int? rankDelta,  bool isSelf,  bool isPro,  int? topPercent,  int? levelsCleared,  int? levelCount,  int? starsEarned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that.rank,_that.playerId,_that.name,_that.avatarEmoji,_that.score,_that.locationLabel,_that.rankDelta,_that.isSelf,_that.isPro,_that.topPercent,_that.levelsCleared,_that.levelCount,_that.starsEarned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String playerId,  String name,  String avatarEmoji,  int score,  String? locationLabel,  int? rankDelta,  bool isSelf,  bool isPro,  int? topPercent,  int? levelsCleared,  int? levelCount,  int? starsEarned)  $default,) {final _that = this;
switch (_that) {
case _LeaderboardEntry():
return $default(_that.rank,_that.playerId,_that.name,_that.avatarEmoji,_that.score,_that.locationLabel,_that.rankDelta,_that.isSelf,_that.isPro,_that.topPercent,_that.levelsCleared,_that.levelCount,_that.starsEarned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String playerId,  String name,  String avatarEmoji,  int score,  String? locationLabel,  int? rankDelta,  bool isSelf,  bool isPro,  int? topPercent,  int? levelsCleared,  int? levelCount,  int? starsEarned)?  $default,) {final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that.rank,_that.playerId,_that.name,_that.avatarEmoji,_that.score,_that.locationLabel,_that.rankDelta,_that.isSelf,_that.isPro,_that.topPercent,_that.levelsCleared,_that.levelCount,_that.starsEarned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeaderboardEntry extends LeaderboardEntry {
  const _LeaderboardEntry({required this.rank, required this.playerId, required this.name, required this.avatarEmoji, required this.score, this.locationLabel, this.rankDelta, this.isSelf = false, this.isPro = false, this.topPercent, this.levelsCleared, this.levelCount, this.starsEarned}): super._();
  factory _LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);

@override final  int rank;
@override final  String playerId;
@override final  String name;
@override final  String avatarEmoji;
@override final  int score;
/// "🇵🇰 Lahore" — flag plus city, as the bible always prints them
/// together. Null on a category board, which has no location line.
@override final  String? locationLabel;
/// Positive = climbed, negative = dropped, zero = unchanged. Null when
/// there is no prior-period rank to compare against (a category board).
@override final  int? rankDelta;
/// Set only on the player's own row.
@override@JsonKey() final  bool isSelf;
/// A Quizoo Pro member (plan 023) — drives the crown and the tick. From
/// `profiles.is_pro`, written only by the server.
@override@JsonKey() final  bool isPro;
/// "Top N%", shown only on the self row of a global/country board.
@override final  int? topPercent;
/// Category-board-only progress line: "{levelsCleared}/{levelCount}
/// levels · {starsEarned} ⭐".
@override final  int? levelsCleared;
@override final  int? levelCount;
@override final  int? starsEarned;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaderboardEntryCopyWith<_LeaderboardEntry> get copyWith => __$LeaderboardEntryCopyWithImpl<_LeaderboardEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeaderboardEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaderboardEntry&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarEmoji, avatarEmoji) || other.avatarEmoji == avatarEmoji)&&(identical(other.score, score) || other.score == score)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel)&&(identical(other.rankDelta, rankDelta) || other.rankDelta == rankDelta)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf)&&(identical(other.isPro, isPro) || other.isPro == isPro)&&(identical(other.topPercent, topPercent) || other.topPercent == topPercent)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.levelCount, levelCount) || other.levelCount == levelCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,playerId,name,avatarEmoji,score,locationLabel,rankDelta,isSelf,isPro,topPercent,levelsCleared,levelCount,starsEarned);

@override
String toString() {
  return 'LeaderboardEntry(rank: $rank, playerId: $playerId, name: $name, avatarEmoji: $avatarEmoji, score: $score, locationLabel: $locationLabel, rankDelta: $rankDelta, isSelf: $isSelf, isPro: $isPro, topPercent: $topPercent, levelsCleared: $levelsCleared, levelCount: $levelCount, starsEarned: $starsEarned)';
}


}

/// @nodoc
abstract mixin class _$LeaderboardEntryCopyWith<$Res> implements $LeaderboardEntryCopyWith<$Res> {
  factory _$LeaderboardEntryCopyWith(_LeaderboardEntry value, $Res Function(_LeaderboardEntry) _then) = __$LeaderboardEntryCopyWithImpl;
@override @useResult
$Res call({
 int rank, String playerId, String name, String avatarEmoji, int score, String? locationLabel, int? rankDelta, bool isSelf, bool isPro, int? topPercent, int? levelsCleared, int? levelCount, int? starsEarned
});




}
/// @nodoc
class __$LeaderboardEntryCopyWithImpl<$Res>
    implements _$LeaderboardEntryCopyWith<$Res> {
  __$LeaderboardEntryCopyWithImpl(this._self, this._then);

  final _LeaderboardEntry _self;
  final $Res Function(_LeaderboardEntry) _then;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? playerId = null,Object? name = null,Object? avatarEmoji = null,Object? score = null,Object? locationLabel = freezed,Object? rankDelta = freezed,Object? isSelf = null,Object? isPro = null,Object? topPercent = freezed,Object? levelsCleared = freezed,Object? levelCount = freezed,Object? starsEarned = freezed,}) {
  return _then(_LeaderboardEntry(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarEmoji: null == avatarEmoji ? _self.avatarEmoji : avatarEmoji // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,rankDelta: freezed == rankDelta ? _self.rankDelta : rankDelta // ignore: cast_nullable_to_non_nullable
as int?,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,topPercent: freezed == topPercent ? _self.topPercent : topPercent // ignore: cast_nullable_to_non_nullable
as int?,levelsCleared: freezed == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int?,levelCount: freezed == levelCount ? _self.levelCount : levelCount // ignore: cast_nullable_to_non_nullable
as int?,starsEarned: freezed == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
