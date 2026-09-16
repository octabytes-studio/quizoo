// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryDetail {

 Category get category; List<Subcategory> get topics;/// The "128k players" half of the header meta line. It is not on
/// [Category] because it is a live engagement figure, not taxonomy.
 int get playerCount;/// Total stars across every topic in this category — the header's ⭐
/// stat chip (plan 009). The rank chip alongside it is a follow-up
/// (plan 009, open question 4): a category leaderboard read this phase
/// does not add.
 int get starsEarned;/// Total levels cleared across every topic — the header's 🏁 stat chip.
 int get levelsCleared;/// "Pick up where you left" — the topic in this category the player is
/// currently on (plan 009, assumption 5). Null when nothing in the
/// category has been started, which is when the resume card is absent
/// entirely rather than an empty shell.
 Subcategory? get resumeTopic;
/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryDetailCopyWith<CategoryDetail> get copyWith => _$CategoryDetailCopyWithImpl<CategoryDetail>(this as CategoryDetail, _$identity);

  /// Serializes this CategoryDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryDetail&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.resumeTopic, resumeTopic) || other.resumeTopic == resumeTopic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(topics),playerCount,starsEarned,levelsCleared,resumeTopic);

@override
String toString() {
  return 'CategoryDetail(category: $category, topics: $topics, playerCount: $playerCount, starsEarned: $starsEarned, levelsCleared: $levelsCleared, resumeTopic: $resumeTopic)';
}


}

/// @nodoc
abstract mixin class $CategoryDetailCopyWith<$Res>  {
  factory $CategoryDetailCopyWith(CategoryDetail value, $Res Function(CategoryDetail) _then) = _$CategoryDetailCopyWithImpl;
@useResult
$Res call({
 Category category, List<Subcategory> topics, int playerCount, int starsEarned, int levelsCleared, Subcategory? resumeTopic
});


$CategoryCopyWith<$Res> get category;$SubcategoryCopyWith<$Res>? get resumeTopic;

}
/// @nodoc
class _$CategoryDetailCopyWithImpl<$Res>
    implements $CategoryDetailCopyWith<$Res> {
  _$CategoryDetailCopyWithImpl(this._self, this._then);

  final CategoryDetail _self;
  final $Res Function(CategoryDetail) _then;

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? topics = null,Object? playerCount = null,Object? starsEarned = null,Object? levelsCleared = null,Object? resumeTopic = freezed,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,resumeTopic: freezed == resumeTopic ? _self.resumeTopic : resumeTopic // ignore: cast_nullable_to_non_nullable
as Subcategory?,
  ));
}
/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubcategoryCopyWith<$Res>? get resumeTopic {
    if (_self.resumeTopic == null) {
    return null;
  }

  return $SubcategoryCopyWith<$Res>(_self.resumeTopic!, (value) {
    return _then(_self.copyWith(resumeTopic: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryDetail].
extension CategoryDetailPatterns on CategoryDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryDetail value)  $default,){
final _that = this;
switch (_that) {
case _CategoryDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Category category,  List<Subcategory> topics,  int playerCount,  int starsEarned,  int levelsCleared,  Subcategory? resumeTopic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
return $default(_that.category,_that.topics,_that.playerCount,_that.starsEarned,_that.levelsCleared,_that.resumeTopic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Category category,  List<Subcategory> topics,  int playerCount,  int starsEarned,  int levelsCleared,  Subcategory? resumeTopic)  $default,) {final _that = this;
switch (_that) {
case _CategoryDetail():
return $default(_that.category,_that.topics,_that.playerCount,_that.starsEarned,_that.levelsCleared,_that.resumeTopic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Category category,  List<Subcategory> topics,  int playerCount,  int starsEarned,  int levelsCleared,  Subcategory? resumeTopic)?  $default,) {final _that = this;
switch (_that) {
case _CategoryDetail() when $default != null:
return $default(_that.category,_that.topics,_that.playerCount,_that.starsEarned,_that.levelsCleared,_that.resumeTopic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryDetail implements CategoryDetail {
  const _CategoryDetail({required this.category, final  List<Subcategory> topics = const [], this.playerCount = 0, this.starsEarned = 0, this.levelsCleared = 0, this.resumeTopic}): _topics = topics;
  factory _CategoryDetail.fromJson(Map<String, dynamic> json) => _$CategoryDetailFromJson(json);

@override final  Category category;
 final  List<Subcategory> _topics;
@override@JsonKey() List<Subcategory> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

/// The "128k players" half of the header meta line. It is not on
/// [Category] because it is a live engagement figure, not taxonomy.
@override@JsonKey() final  int playerCount;
/// Total stars across every topic in this category — the header's ⭐
/// stat chip (plan 009). The rank chip alongside it is a follow-up
/// (plan 009, open question 4): a category leaderboard read this phase
/// does not add.
@override@JsonKey() final  int starsEarned;
/// Total levels cleared across every topic — the header's 🏁 stat chip.
@override@JsonKey() final  int levelsCleared;
/// "Pick up where you left" — the topic in this category the player is
/// currently on (plan 009, assumption 5). Null when nothing in the
/// category has been started, which is when the resume card is absent
/// entirely rather than an empty shell.
@override final  Subcategory? resumeTopic;

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryDetailCopyWith<_CategoryDetail> get copyWith => __$CategoryDetailCopyWithImpl<_CategoryDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryDetail&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount)&&(identical(other.starsEarned, starsEarned) || other.starsEarned == starsEarned)&&(identical(other.levelsCleared, levelsCleared) || other.levelsCleared == levelsCleared)&&(identical(other.resumeTopic, resumeTopic) || other.resumeTopic == resumeTopic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_topics),playerCount,starsEarned,levelsCleared,resumeTopic);

@override
String toString() {
  return 'CategoryDetail(category: $category, topics: $topics, playerCount: $playerCount, starsEarned: $starsEarned, levelsCleared: $levelsCleared, resumeTopic: $resumeTopic)';
}


}

/// @nodoc
abstract mixin class _$CategoryDetailCopyWith<$Res> implements $CategoryDetailCopyWith<$Res> {
  factory _$CategoryDetailCopyWith(_CategoryDetail value, $Res Function(_CategoryDetail) _then) = __$CategoryDetailCopyWithImpl;
@override @useResult
$Res call({
 Category category, List<Subcategory> topics, int playerCount, int starsEarned, int levelsCleared, Subcategory? resumeTopic
});


@override $CategoryCopyWith<$Res> get category;@override $SubcategoryCopyWith<$Res>? get resumeTopic;

}
/// @nodoc
class __$CategoryDetailCopyWithImpl<$Res>
    implements _$CategoryDetailCopyWith<$Res> {
  __$CategoryDetailCopyWithImpl(this._self, this._then);

  final _CategoryDetail _self;
  final $Res Function(_CategoryDetail) _then;

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? topics = null,Object? playerCount = null,Object? starsEarned = null,Object? levelsCleared = null,Object? resumeTopic = freezed,}) {
  return _then(_CategoryDetail(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,starsEarned: null == starsEarned ? _self.starsEarned : starsEarned // ignore: cast_nullable_to_non_nullable
as int,levelsCleared: null == levelsCleared ? _self.levelsCleared : levelsCleared // ignore: cast_nullable_to_non_nullable
as int,resumeTopic: freezed == resumeTopic ? _self.resumeTopic : resumeTopic // ignore: cast_nullable_to_non_nullable
as Subcategory?,
  ));
}

/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CategoryDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubcategoryCopyWith<$Res>? get resumeTopic {
    if (_self.resumeTopic == null) {
    return null;
  }

  return $SubcategoryCopyWith<$Res>(_self.resumeTopic!, (value) {
    return _then(_self.copyWith(resumeTopic: value));
  });
}
}

// dart format on
