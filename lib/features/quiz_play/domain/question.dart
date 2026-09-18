import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';
part 'question.g.dart';

/// One question in a level.
///
/// Kept local to `quiz_play` rather than promoted to `core/models/`: plan
/// 003's stats and profile screens need aggregates, not raw questions, so
/// nothing else consumes this shape yet (CLAUDE.md §2's 3+ bar).
@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required String subcategoryId,

    /// 1–5, which is what §19's level table draws its pool from.
    required int difficulty,
    required String text,

    /// Four options, or three when [hasImage] — the media plate takes the
    /// room the fourth would need.
    required List<String> options,
    required int correctIndex,

    /// The one-sentence explanation shown on **every** verdict, right or
    /// wrong. The bible calls it "the single feature that turns a quiz into
    /// learning", so it is required, not optional.
    required String explanation,

    /// Renders the 132px media plate above the question box (S-15).
    @Default(false) bool hasImage,

    /// The emoji standing in for real artwork.
    ///
    /// There is no image CDN in this phase, so an "image question" is an
    /// emoji on a gradient plate. [imageAsset] is the hook a real asset drops
    /// into, and the plate falls back to the text-only layout when it is
    /// missing or fails to decode.
    String? imageEmoji,
    String? imageAsset,

    /// Start of the media plate's gradient, as `#RRGGBB`.
    @Default('#2BB3FF') String imageColorFrom,
    @Default('#7B4DFF') String imageColorTo,

    /// True when this question should skip TTS read-aloud (e.g. it leans on
    /// a figure/image the voice can't describe). Sourced from
    /// `questions.tts_excluded`.
    @Default(false) bool ttsExcluded,

    /// The pre-generated narration clip for this question, or `null` when
    /// none has been generated yet. Sourced from `questions.audio_url`.
    String? audioUrl,
  }) = _Question;

  const Question._();

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  String get correctAnswer => options[correctIndex];

  /// The A/B/C/D badges, or their Urdu equivalents under an RTL locale.
  static const List<String> latinKeys = ['A', 'B', 'C', 'D'];
  static const List<String> urduKeys = ['ا', 'ب', 'ج', 'د'];
}
