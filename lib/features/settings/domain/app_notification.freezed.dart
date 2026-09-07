// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppNotification {

 String get id; NotificationKind get kind; String get title; String get body; String get timeLabel; bool get isRead;/// Set only on [NotificationKind.duelChallenge] — the friend whose
/// "Accept" pill starts the duel.
 String? get challengerName; String? get challengerAvatarEmoji; int? get challengerElo;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.timeLabel, timeLabel) || other.timeLabel == timeLabel)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.challengerName, challengerName) || other.challengerName == challengerName)&&(identical(other.challengerAvatarEmoji, challengerAvatarEmoji) || other.challengerAvatarEmoji == challengerAvatarEmoji)&&(identical(other.challengerElo, challengerElo) || other.challengerElo == challengerElo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,body,timeLabel,isRead,challengerName,challengerAvatarEmoji,challengerElo);

@override
String toString() {
  return 'AppNotification(id: $id, kind: $kind, title: $title, body: $body, timeLabel: $timeLabel, isRead: $isRead, challengerName: $challengerName, challengerAvatarEmoji: $challengerAvatarEmoji, challengerElo: $challengerElo)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
 String id, NotificationKind kind, String title, String body, String timeLabel, bool isRead, String? challengerName, String? challengerAvatarEmoji, int? challengerElo
});




}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? body = null,Object? timeLabel = null,Object? isRead = null,Object? challengerName = freezed,Object? challengerAvatarEmoji = freezed,Object? challengerElo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NotificationKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,timeLabel: null == timeLabel ? _self.timeLabel : timeLabel // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,challengerName: freezed == challengerName ? _self.challengerName : challengerName // ignore: cast_nullable_to_non_nullable
as String?,challengerAvatarEmoji: freezed == challengerAvatarEmoji ? _self.challengerAvatarEmoji : challengerAvatarEmoji // ignore: cast_nullable_to_non_nullable
as String?,challengerElo: freezed == challengerElo ? _self.challengerElo : challengerElo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  NotificationKind kind,  String title,  String body,  String timeLabel,  bool isRead,  String? challengerName,  String? challengerAvatarEmoji,  int? challengerElo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.body,_that.timeLabel,_that.isRead,_that.challengerName,_that.challengerAvatarEmoji,_that.challengerElo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  NotificationKind kind,  String title,  String body,  String timeLabel,  bool isRead,  String? challengerName,  String? challengerAvatarEmoji,  int? challengerElo)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.id,_that.kind,_that.title,_that.body,_that.timeLabel,_that.isRead,_that.challengerName,_that.challengerAvatarEmoji,_that.challengerElo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  NotificationKind kind,  String title,  String body,  String timeLabel,  bool isRead,  String? challengerName,  String? challengerAvatarEmoji,  int? challengerElo)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.body,_that.timeLabel,_that.isRead,_that.challengerName,_that.challengerAvatarEmoji,_that.challengerElo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppNotification extends AppNotification {
  const _AppNotification({required this.id, required this.kind, required this.title, required this.body, required this.timeLabel, this.isRead = false, this.challengerName, this.challengerAvatarEmoji, this.challengerElo}): super._();
  factory _AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

@override final  String id;
@override final  NotificationKind kind;
@override final  String title;
@override final  String body;
@override final  String timeLabel;
@override@JsonKey() final  bool isRead;
/// Set only on [NotificationKind.duelChallenge] — the friend whose
/// "Accept" pill starts the duel.
@override final  String? challengerName;
@override final  String? challengerAvatarEmoji;
@override final  int? challengerElo;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.timeLabel, timeLabel) || other.timeLabel == timeLabel)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.challengerName, challengerName) || other.challengerName == challengerName)&&(identical(other.challengerAvatarEmoji, challengerAvatarEmoji) || other.challengerAvatarEmoji == challengerAvatarEmoji)&&(identical(other.challengerElo, challengerElo) || other.challengerElo == challengerElo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,body,timeLabel,isRead,challengerName,challengerAvatarEmoji,challengerElo);

@override
String toString() {
  return 'AppNotification(id: $id, kind: $kind, title: $title, body: $body, timeLabel: $timeLabel, isRead: $isRead, challengerName: $challengerName, challengerAvatarEmoji: $challengerAvatarEmoji, challengerElo: $challengerElo)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, NotificationKind kind, String title, String body, String timeLabel, bool isRead, String? challengerName, String? challengerAvatarEmoji, int? challengerElo
});




}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? body = null,Object? timeLabel = null,Object? isRead = null,Object? challengerName = freezed,Object? challengerAvatarEmoji = freezed,Object? challengerElo = freezed,}) {
  return _then(_AppNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NotificationKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,timeLabel: null == timeLabel ? _self.timeLabel : timeLabel // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,challengerName: freezed == challengerName ? _self.challengerName : challengerName // ignore: cast_nullable_to_non_nullable
as String?,challengerAvatarEmoji: freezed == challengerAvatarEmoji ? _self.challengerAvatarEmoji : challengerAvatarEmoji // ignore: cast_nullable_to_non_nullable
as String?,challengerElo: freezed == challengerElo ? _self.challengerElo : challengerElo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
