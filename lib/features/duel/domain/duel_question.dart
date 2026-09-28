import 'package:freezed_annotation/freezed_annotation.dart';

part 'duel_question.freezed.dart';
part 'duel_question.g.dart';

/// A duel round's question, as the player sees it.
///
/// **There is no `correctIndex` here, by construction** (plan 017, A2): a
/// live duel's answer only ever arrives in the round's `round_result`, after
/// both sides have locked in, so nothing a widget holds can leak it early.
/// The bot duel keeps its full `Question` private inside `DuelPlayCubit` and
/// hands the screen this shape too.
@freezed
abstract class DuelQuestion with _$DuelQuestion {
  const factory DuelQuestion({
    @JsonKey(name: 'prompt') required String text,
    required List<String> options,
    @Default('text') String kind,
    String? mediaUrl,

    /// The question's pre-generated narration clip (the same one play mode
    /// reads aloud), or null when none exists yet.
    String? audioUrl,

    /// True when this question should never be read aloud.
    @Default(false) bool ttsExcluded,
  }) = _DuelQuestion;

  factory DuelQuestion.fromJson(Map<String, dynamic> json) =>
      _$DuelQuestionFromJson(json);
}
