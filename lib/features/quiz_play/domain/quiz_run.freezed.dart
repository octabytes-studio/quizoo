// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnsweredQuestion {

 Question get question; AnswerOutcome get outcome;/// What the player picked, or null on a timeout or skip.
 int? get chosenIndex;/// Seconds left on the clock when they answered — the speed bonus's input.
 int get secondsLeft;/// Points this question added to the running total.
 int get pointsEarned;
/// Create a copy of AnsweredQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnsweredQuestionCopyWith<AnsweredQuestion> get copyWith => _$AnsweredQuestionCopyWithImpl<AnsweredQuestion>(this as AnsweredQuestion, _$identity);

  /// Serializes this AnsweredQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnsweredQuestion&&(identical(other.question, question) || other.question == question)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.chosenIndex, chosenIndex) || other.chosenIndex == chosenIndex)&&(identical(other.secondsLeft, secondsLeft) || other.secondsLeft == secondsLeft)&&(identical(other.pointsEarned, pointsEarned) || other.pointsEarned == pointsEarned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,outcome,chosenIndex,secondsLeft,pointsEarned);

@override
String toString() {
  return 'AnsweredQuestion(question: $question, outcome: $outcome, chosenIndex: $chosenIndex, secondsLeft: $secondsLeft, pointsEarned: $pointsEarned)';
}


}

/// @nodoc
abstract mixin class $AnsweredQuestionCopyWith<$Res>  {
  factory $AnsweredQuestionCopyWith(AnsweredQuestion value, $Res Function(AnsweredQuestion) _then) = _$AnsweredQuestionCopyWithImpl;
@useResult
$Res call({
 Question question, AnswerOutcome outcome, int? chosenIndex, int secondsLeft, int pointsEarned
});


$QuestionCopyWith<$Res> get question;

}
/// @nodoc
class _$AnsweredQuestionCopyWithImpl<$Res>
    implements $AnsweredQuestionCopyWith<$Res> {
  _$AnsweredQuestionCopyWithImpl(this._self, this._then);

  final AnsweredQuestion _self;
  final $Res Function(AnsweredQuestion) _then;

/// Create a copy of AnsweredQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = null,Object? outcome = null,Object? chosenIndex = freezed,Object? secondsLeft = null,Object? pointsEarned = null,}) {
  return _then(_self.copyWith(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Question,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AnswerOutcome,chosenIndex: freezed == chosenIndex ? _self.chosenIndex : chosenIndex // ignore: cast_nullable_to_non_nullable
as int?,secondsLeft: null == secondsLeft ? _self.secondsLeft : secondsLeft // ignore: cast_nullable_to_non_nullable
as int,pointsEarned: null == pointsEarned ? _self.pointsEarned : pointsEarned // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AnsweredQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionCopyWith<$Res> get question {
  
  return $QuestionCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}
}


/// Adds pattern-matching-related methods to [AnsweredQuestion].
extension AnsweredQuestionPatterns on AnsweredQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnsweredQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnsweredQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnsweredQuestion value)  $default,){
final _that = this;
switch (_that) {
case _AnsweredQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnsweredQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _AnsweredQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Question question,  AnswerOutcome outcome,  int? chosenIndex,  int secondsLeft,  int pointsEarned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnsweredQuestion() when $default != null:
return $default(_that.question,_that.outcome,_that.chosenIndex,_that.secondsLeft,_that.pointsEarned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Question question,  AnswerOutcome outcome,  int? chosenIndex,  int secondsLeft,  int pointsEarned)  $default,) {final _that = this;
switch (_that) {
case _AnsweredQuestion():
return $default(_that.question,_that.outcome,_that.chosenIndex,_that.secondsLeft,_that.pointsEarned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Question question,  AnswerOutcome outcome,  int? chosenIndex,  int secondsLeft,  int pointsEarned)?  $default,) {final _that = this;
switch (_that) {
case _AnsweredQuestion() when $default != null:
return $default(_that.question,_that.outcome,_that.chosenIndex,_that.secondsLeft,_that.pointsEarned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnsweredQuestion extends AnsweredQuestion {
  const _AnsweredQuestion({required this.question, required this.outcome, this.chosenIndex, this.secondsLeft = 0, this.pointsEarned = 0}): super._();
  factory _AnsweredQuestion.fromJson(Map<String, dynamic> json) => _$AnsweredQuestionFromJson(json);

@override final  Question question;
@override final  AnswerOutcome outcome;
/// What the player picked, or null on a timeout or skip.
@override final  int? chosenIndex;
/// Seconds left on the clock when they answered — the speed bonus's input.
@override@JsonKey() final  int secondsLeft;
/// Points this question added to the running total.
@override@JsonKey() final  int pointsEarned;

/// Create a copy of AnsweredQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnsweredQuestionCopyWith<_AnsweredQuestion> get copyWith => __$AnsweredQuestionCopyWithImpl<_AnsweredQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnsweredQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnsweredQuestion&&(identical(other.question, question) || other.question == question)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.chosenIndex, chosenIndex) || other.chosenIndex == chosenIndex)&&(identical(other.secondsLeft, secondsLeft) || other.secondsLeft == secondsLeft)&&(identical(other.pointsEarned, pointsEarned) || other.pointsEarned == pointsEarned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,outcome,chosenIndex,secondsLeft,pointsEarned);

@override
String toString() {
  return 'AnsweredQuestion(question: $question, outcome: $outcome, chosenIndex: $chosenIndex, secondsLeft: $secondsLeft, pointsEarned: $pointsEarned)';
}


}

/// @nodoc
abstract mixin class _$AnsweredQuestionCopyWith<$Res> implements $AnsweredQuestionCopyWith<$Res> {
  factory _$AnsweredQuestionCopyWith(_AnsweredQuestion value, $Res Function(_AnsweredQuestion) _then) = __$AnsweredQuestionCopyWithImpl;
@override @useResult
$Res call({
 Question question, AnswerOutcome outcome, int? chosenIndex, int secondsLeft, int pointsEarned
});


@override $QuestionCopyWith<$Res> get question;

}
/// @nodoc
class __$AnsweredQuestionCopyWithImpl<$Res>
    implements _$AnsweredQuestionCopyWith<$Res> {
  __$AnsweredQuestionCopyWithImpl(this._self, this._then);

  final _AnsweredQuestion _self;
  final $Res Function(_AnsweredQuestion) _then;

/// Create a copy of AnsweredQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = null,Object? outcome = null,Object? chosenIndex = freezed,Object? secondsLeft = null,Object? pointsEarned = null,}) {
  return _then(_AnsweredQuestion(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Question,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AnswerOutcome,chosenIndex: freezed == chosenIndex ? _self.chosenIndex : chosenIndex // ignore: cast_nullable_to_non_nullable
as int?,secondsLeft: null == secondsLeft ? _self.secondsLeft : secondsLeft // ignore: cast_nullable_to_non_nullable
as int,pointsEarned: null == pointsEarned ? _self.pointsEarned : pointsEarned // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AnsweredQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionCopyWith<$Res> get question {
  
  return $QuestionCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}
}


/// @nodoc
mixin _$QuizRun {

 String get levelId; String get subcategoryId; String get subcategoryName; String get categoryId; int get levelNumber; int get secondsPerQuestion; DateTime get startedAt; List<AnsweredQuestion> get answers; int get score; int get longestStreak; int get currentStreak; int get heartsRemaining; int get questionCount; bool get isBoss;/// True once any power-up has been fired, which forfeits the clean-run
/// bonus (§19).
 bool get usedPowerUp; RunEnding get ending; DateTime? get finishedAt;
/// Create a copy of QuizRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizRunCopyWith<QuizRun> get copyWith => _$QuizRunCopyWithImpl<QuizRun>(this as QuizRun, _$identity);

  /// Serializes this QuizRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizRun&&(identical(other.levelId, levelId) || other.levelId == levelId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.levelNumber, levelNumber) || other.levelNumber == levelNumber)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&const DeepCollectionEquality().equals(other.answers, answers)&&(identical(other.score, score) || other.score == score)&&(identical(other.longestStreak, longestStreak) || other.longestStreak == longestStreak)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.heartsRemaining, heartsRemaining) || other.heartsRemaining == heartsRemaining)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.isBoss, isBoss) || other.isBoss == isBoss)&&(identical(other.usedPowerUp, usedPowerUp) || other.usedPowerUp == usedPowerUp)&&(identical(other.ending, ending) || other.ending == ending)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,levelId,subcategoryId,subcategoryName,categoryId,levelNumber,secondsPerQuestion,startedAt,const DeepCollectionEquality().hash(answers),score,longestStreak,currentStreak,heartsRemaining,questionCount,isBoss,usedPowerUp,ending,finishedAt);

@override
String toString() {
  return 'QuizRun(levelId: $levelId, subcategoryId: $subcategoryId, subcategoryName: $subcategoryName, categoryId: $categoryId, levelNumber: $levelNumber, secondsPerQuestion: $secondsPerQuestion, startedAt: $startedAt, answers: $answers, score: $score, longestStreak: $longestStreak, currentStreak: $currentStreak, heartsRemaining: $heartsRemaining, questionCount: $questionCount, isBoss: $isBoss, usedPowerUp: $usedPowerUp, ending: $ending, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class $QuizRunCopyWith<$Res>  {
  factory $QuizRunCopyWith(QuizRun value, $Res Function(QuizRun) _then) = _$QuizRunCopyWithImpl;
@useResult
$Res call({
 String levelId, String subcategoryId, String subcategoryName, String categoryId, int levelNumber, int secondsPerQuestion, DateTime startedAt, List<AnsweredQuestion> answers, int score, int longestStreak, int currentStreak, int heartsRemaining, int questionCount, bool isBoss, bool usedPowerUp, RunEnding ending, DateTime? finishedAt
});




}
/// @nodoc
class _$QuizRunCopyWithImpl<$Res>
    implements $QuizRunCopyWith<$Res> {
  _$QuizRunCopyWithImpl(this._self, this._then);

  final QuizRun _self;
  final $Res Function(QuizRun) _then;

/// Create a copy of QuizRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? levelId = null,Object? subcategoryId = null,Object? subcategoryName = null,Object? categoryId = null,Object? levelNumber = null,Object? secondsPerQuestion = null,Object? startedAt = null,Object? answers = null,Object? score = null,Object? longestStreak = null,Object? currentStreak = null,Object? heartsRemaining = null,Object? questionCount = null,Object? isBoss = null,Object? usedPowerUp = null,Object? ending = null,Object? finishedAt = freezed,}) {
  return _then(_self.copyWith(
levelId: null == levelId ? _self.levelId : levelId // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,subcategoryName: null == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,levelNumber: null == levelNumber ? _self.levelNumber : levelNumber // ignore: cast_nullable_to_non_nullable
as int,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<AnsweredQuestion>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,longestStreak: null == longestStreak ? _self.longestStreak : longestStreak // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,heartsRemaining: null == heartsRemaining ? _self.heartsRemaining : heartsRemaining // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,isBoss: null == isBoss ? _self.isBoss : isBoss // ignore: cast_nullable_to_non_nullable
as bool,usedPowerUp: null == usedPowerUp ? _self.usedPowerUp : usedPowerUp // ignore: cast_nullable_to_non_nullable
as bool,ending: null == ending ? _self.ending : ending // ignore: cast_nullable_to_non_nullable
as RunEnding,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizRun].
extension QuizRunPatterns on QuizRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizRun value)  $default,){
final _that = this;
switch (_that) {
case _QuizRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizRun value)?  $default,){
final _that = this;
switch (_that) {
case _QuizRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String levelId,  String subcategoryId,  String subcategoryName,  String categoryId,  int levelNumber,  int secondsPerQuestion,  DateTime startedAt,  List<AnsweredQuestion> answers,  int score,  int longestStreak,  int currentStreak,  int heartsRemaining,  int questionCount,  bool isBoss,  bool usedPowerUp,  RunEnding ending,  DateTime? finishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizRun() when $default != null:
return $default(_that.levelId,_that.subcategoryId,_that.subcategoryName,_that.categoryId,_that.levelNumber,_that.secondsPerQuestion,_that.startedAt,_that.answers,_that.score,_that.longestStreak,_that.currentStreak,_that.heartsRemaining,_that.questionCount,_that.isBoss,_that.usedPowerUp,_that.ending,_that.finishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String levelId,  String subcategoryId,  String subcategoryName,  String categoryId,  int levelNumber,  int secondsPerQuestion,  DateTime startedAt,  List<AnsweredQuestion> answers,  int score,  int longestStreak,  int currentStreak,  int heartsRemaining,  int questionCount,  bool isBoss,  bool usedPowerUp,  RunEnding ending,  DateTime? finishedAt)  $default,) {final _that = this;
switch (_that) {
case _QuizRun():
return $default(_that.levelId,_that.subcategoryId,_that.subcategoryName,_that.categoryId,_that.levelNumber,_that.secondsPerQuestion,_that.startedAt,_that.answers,_that.score,_that.longestStreak,_that.currentStreak,_that.heartsRemaining,_that.questionCount,_that.isBoss,_that.usedPowerUp,_that.ending,_that.finishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String levelId,  String subcategoryId,  String subcategoryName,  String categoryId,  int levelNumber,  int secondsPerQuestion,  DateTime startedAt,  List<AnsweredQuestion> answers,  int score,  int longestStreak,  int currentStreak,  int heartsRemaining,  int questionCount,  bool isBoss,  bool usedPowerUp,  RunEnding ending,  DateTime? finishedAt)?  $default,) {final _that = this;
switch (_that) {
case _QuizRun() when $default != null:
return $default(_that.levelId,_that.subcategoryId,_that.subcategoryName,_that.categoryId,_that.levelNumber,_that.secondsPerQuestion,_that.startedAt,_that.answers,_that.score,_that.longestStreak,_that.currentStreak,_that.heartsRemaining,_that.questionCount,_that.isBoss,_that.usedPowerUp,_that.ending,_that.finishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizRun extends QuizRun {
  const _QuizRun({required this.levelId, required this.subcategoryId, required this.subcategoryName, required this.categoryId, required this.levelNumber, required this.secondsPerQuestion, required this.startedAt, final  List<AnsweredQuestion> answers = const [], this.score = 0, this.longestStreak = 0, this.currentStreak = 0, this.heartsRemaining = 3, this.questionCount = 20, this.isBoss = false, this.usedPowerUp = false, this.ending = RunEnding.inProgress, this.finishedAt}): _answers = answers,super._();
  factory _QuizRun.fromJson(Map<String, dynamic> json) => _$QuizRunFromJson(json);

@override final  String levelId;
@override final  String subcategoryId;
@override final  String subcategoryName;
@override final  String categoryId;
@override final  int levelNumber;
@override final  int secondsPerQuestion;
@override final  DateTime startedAt;
 final  List<AnsweredQuestion> _answers;
@override@JsonKey() List<AnsweredQuestion> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

@override@JsonKey() final  int score;
@override@JsonKey() final  int longestStreak;
@override@JsonKey() final  int currentStreak;
@override@JsonKey() final  int heartsRemaining;
@override@JsonKey() final  int questionCount;
@override@JsonKey() final  bool isBoss;
/// True once any power-up has been fired, which forfeits the clean-run
/// bonus (§19).
@override@JsonKey() final  bool usedPowerUp;
@override@JsonKey() final  RunEnding ending;
@override final  DateTime? finishedAt;

/// Create a copy of QuizRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizRunCopyWith<_QuizRun> get copyWith => __$QuizRunCopyWithImpl<_QuizRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizRunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizRun&&(identical(other.levelId, levelId) || other.levelId == levelId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.levelNumber, levelNumber) || other.levelNumber == levelNumber)&&(identical(other.secondsPerQuestion, secondsPerQuestion) || other.secondsPerQuestion == secondsPerQuestion)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&const DeepCollectionEquality().equals(other._answers, _answers)&&(identical(other.score, score) || other.score == score)&&(identical(other.longestStreak, longestStreak) || other.longestStreak == longestStreak)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.heartsRemaining, heartsRemaining) || other.heartsRemaining == heartsRemaining)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.isBoss, isBoss) || other.isBoss == isBoss)&&(identical(other.usedPowerUp, usedPowerUp) || other.usedPowerUp == usedPowerUp)&&(identical(other.ending, ending) || other.ending == ending)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,levelId,subcategoryId,subcategoryName,categoryId,levelNumber,secondsPerQuestion,startedAt,const DeepCollectionEquality().hash(_answers),score,longestStreak,currentStreak,heartsRemaining,questionCount,isBoss,usedPowerUp,ending,finishedAt);

@override
String toString() {
  return 'QuizRun(levelId: $levelId, subcategoryId: $subcategoryId, subcategoryName: $subcategoryName, categoryId: $categoryId, levelNumber: $levelNumber, secondsPerQuestion: $secondsPerQuestion, startedAt: $startedAt, answers: $answers, score: $score, longestStreak: $longestStreak, currentStreak: $currentStreak, heartsRemaining: $heartsRemaining, questionCount: $questionCount, isBoss: $isBoss, usedPowerUp: $usedPowerUp, ending: $ending, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class _$QuizRunCopyWith<$Res> implements $QuizRunCopyWith<$Res> {
  factory _$QuizRunCopyWith(_QuizRun value, $Res Function(_QuizRun) _then) = __$QuizRunCopyWithImpl;
@override @useResult
$Res call({
 String levelId, String subcategoryId, String subcategoryName, String categoryId, int levelNumber, int secondsPerQuestion, DateTime startedAt, List<AnsweredQuestion> answers, int score, int longestStreak, int currentStreak, int heartsRemaining, int questionCount, bool isBoss, bool usedPowerUp, RunEnding ending, DateTime? finishedAt
});




}
/// @nodoc
class __$QuizRunCopyWithImpl<$Res>
    implements _$QuizRunCopyWith<$Res> {
  __$QuizRunCopyWithImpl(this._self, this._then);

  final _QuizRun _self;
  final $Res Function(_QuizRun) _then;

/// Create a copy of QuizRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? levelId = null,Object? subcategoryId = null,Object? subcategoryName = null,Object? categoryId = null,Object? levelNumber = null,Object? secondsPerQuestion = null,Object? startedAt = null,Object? answers = null,Object? score = null,Object? longestStreak = null,Object? currentStreak = null,Object? heartsRemaining = null,Object? questionCount = null,Object? isBoss = null,Object? usedPowerUp = null,Object? ending = null,Object? finishedAt = freezed,}) {
  return _then(_QuizRun(
levelId: null == levelId ? _self.levelId : levelId // ignore: cast_nullable_to_non_nullable
as String,subcategoryId: null == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String,subcategoryName: null == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,levelNumber: null == levelNumber ? _self.levelNumber : levelNumber // ignore: cast_nullable_to_non_nullable
as int,secondsPerQuestion: null == secondsPerQuestion ? _self.secondsPerQuestion : secondsPerQuestion // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<AnsweredQuestion>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,longestStreak: null == longestStreak ? _self.longestStreak : longestStreak // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,heartsRemaining: null == heartsRemaining ? _self.heartsRemaining : heartsRemaining // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,isBoss: null == isBoss ? _self.isBoss : isBoss // ignore: cast_nullable_to_non_nullable
as bool,usedPowerUp: null == usedPowerUp ? _self.usedPowerUp : usedPowerUp // ignore: cast_nullable_to_non_nullable
as bool,ending: null == ending ? _self.ending : ending // ignore: cast_nullable_to_non_nullable
as RunEnding,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
