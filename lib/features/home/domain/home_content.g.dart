// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PopularQuiz _$PopularQuizFromJson(Map<String, dynamic> json) => _PopularQuiz(
  id: json['id'] as String,
  subcategoryId: json['subcategoryId'] as String,
  title: json['title'] as String,
  emoji: json['emoji'] as String,
  colorFrom: json['colorFrom'] as String,
  colorTo: json['colorTo'] as String,
  playedCount: (json['playedCount'] as num?)?.toInt() ?? 0,
  isHot: json['isHot'] as bool? ?? false,
);

Map<String, dynamic> _$PopularQuizToJson(_PopularQuiz instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subcategoryId': instance.subcategoryId,
      'title': instance.title,
      'emoji': instance.emoji,
      'colorFrom': instance.colorFrom,
      'colorTo': instance.colorTo,
      'playedCount': instance.playedCount,
      'isHot': instance.isHot,
    };

_ContinueEntry _$ContinueEntryFromJson(Map<String, dynamic> json) =>
    _ContinueEntry(
      subcategoryId: json['subcategoryId'] as String,
      subcategoryName: json['subcategoryName'] as String,
      emoji: json['emoji'] as String,
      plateColor: json['plateColor'] as String,
      levelNumber: (json['levelNumber'] as num).toInt(),
      points: (json['points'] as num?)?.toInt() ?? 0,
      livesLeft: (json['livesLeft'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$ContinueEntryToJson(_ContinueEntry instance) =>
    <String, dynamic>{
      'subcategoryId': instance.subcategoryId,
      'subcategoryName': instance.subcategoryName,
      'emoji': instance.emoji,
      'plateColor': instance.plateColor,
      'levelNumber': instance.levelNumber,
      'points': instance.points,
      'livesLeft': instance.livesLeft,
    };

_DailyChallengePreview _$DailyChallengePreviewFromJson(
  Map<String, dynamic> json,
) => _DailyChallengePreview(
  questionCount: (json['questionCount'] as num?)?.toInt() ?? 10,
  minutesRemaining: (json['minutesRemaining'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DailyChallengePreviewToJson(
  _DailyChallengePreview instance,
) => <String, dynamic>{
  'questionCount': instance.questionCount,
  'minutesRemaining': instance.minutesRemaining,
};

_HomeContent _$HomeContentFromJson(Map<String, dynamic> json) => _HomeContent(
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  subcategories:
      (json['subcategories'] as List<dynamic>?)
          ?.map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  popular:
      (json['popular'] as List<dynamic>?)
          ?.map((e) => PopularQuiz.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  continueEntry: json['continueEntry'] == null
      ? null
      : ContinueEntry.fromJson(json['continueEntry'] as Map<String, dynamic>),
  daily: json['daily'] == null
      ? null
      : DailyChallengePreview.fromJson(json['daily'] as Map<String, dynamic>),
  currency: json['currency'] == null
      ? null
      : PlayerCurrency.fromJson(json['currency'] as Map<String, dynamic>),
  dayStreak: (json['dayStreak'] as num?)?.toInt() ?? 0,
  playerLevel: (json['playerLevel'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HomeContentToJson(_HomeContent instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'subcategories': instance.subcategories,
      'popular': instance.popular,
      'continueEntry': instance.continueEntry,
      'daily': instance.daily,
      'currency': instance.currency,
      'dayStreak': instance.dayStreak,
      'playerLevel': instance.playerLevel,
    };
