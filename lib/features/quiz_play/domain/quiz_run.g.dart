// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnsweredQuestion _$AnsweredQuestionFromJson(Map<String, dynamic> json) =>
    _AnsweredQuestion(
      question: Question.fromJson(json['question'] as Map<String, dynamic>),
      outcome: $enumDecode(_$AnswerOutcomeEnumMap, json['outcome']),
      chosenIndex: (json['chosenIndex'] as num?)?.toInt(),
      secondsLeft: (json['secondsLeft'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AnsweredQuestionToJson(_AnsweredQuestion instance) =>
    <String, dynamic>{
      'question': instance.question,
      'outcome': _$AnswerOutcomeEnumMap[instance.outcome]!,
      'chosenIndex': instance.chosenIndex,
      'secondsLeft': instance.secondsLeft,
      'pointsEarned': instance.pointsEarned,
    };

const _$AnswerOutcomeEnumMap = {
  AnswerOutcome.correct: 'correct',
  AnswerOutcome.wrong: 'wrong',
  AnswerOutcome.timedOut: 'timedOut',
  AnswerOutcome.skipped: 'skipped',
};

_QuizRun _$QuizRunFromJson(Map<String, dynamic> json) => _QuizRun(
  attemptId: json['attemptId'] as String,
  levelId: json['levelId'] as String,
  subcategoryId: json['subcategoryId'] as String,
  subcategoryName: json['subcategoryName'] as String,
  categoryId: json['categoryId'] as String,
  levelNumber: (json['levelNumber'] as num).toInt(),
  secondsPerQuestion: (json['secondsPerQuestion'] as num).toInt(),
  startedAt: DateTime.parse(json['startedAt'] as String),
  answers:
      (json['answers'] as List<dynamic>?)
          ?.map((e) => AnsweredQuestion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  score: (json['score'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  heartsRemaining: (json['heartsRemaining'] as num?)?.toInt() ?? 3,
  questionCount: (json['questionCount'] as num?)?.toInt() ?? 20,
  isBoss: json['isBoss'] as bool? ?? false,
  isDaily: json['isDaily'] as bool? ?? false,
  usedPowerUp: json['usedPowerUp'] as bool? ?? false,
  ending:
      $enumDecodeNullable(_$RunEndingEnumMap, json['ending']) ??
      RunEnding.inProgress,
  finishedAt: json['finishedAt'] == null
      ? null
      : DateTime.parse(json['finishedAt'] as String),
);

Map<String, dynamic> _$QuizRunToJson(_QuizRun instance) => <String, dynamic>{
  'attemptId': instance.attemptId,
  'levelId': instance.levelId,
  'subcategoryId': instance.subcategoryId,
  'subcategoryName': instance.subcategoryName,
  'categoryId': instance.categoryId,
  'levelNumber': instance.levelNumber,
  'secondsPerQuestion': instance.secondsPerQuestion,
  'startedAt': instance.startedAt.toIso8601String(),
  'answers': instance.answers,
  'score': instance.score,
  'longestStreak': instance.longestStreak,
  'currentStreak': instance.currentStreak,
  'heartsRemaining': instance.heartsRemaining,
  'questionCount': instance.questionCount,
  'isBoss': instance.isBoss,
  'isDaily': instance.isDaily,
  'usedPowerUp': instance.usedPowerUp,
  'ending': _$RunEndingEnumMap[instance.ending]!,
  'finishedAt': instance.finishedAt?.toIso8601String(),
};

const _$RunEndingEnumMap = {
  RunEnding.inProgress: 'inProgress',
  RunEnding.finished: 'finished',
  RunEnding.outOfHearts: 'outOfHearts',
  RunEnding.quit: 'quit',
};
