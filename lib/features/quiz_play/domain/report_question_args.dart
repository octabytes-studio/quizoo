/// Everything S-51 needs to file a report about one specific question
/// (plan 025).
///
/// Lives in `quiz_play`'s **domain** layer, not beside the screen, because
/// `features/quiz_result` also builds one (the failed-result review list) and
/// must not import another feature's presentation layer (CLAUDE.md §10).
class ReportQuestionArgs {
  const ReportQuestionArgs({
    required this.questionId,
    required this.questionText,
    required this.topicLabel,
    required this.languageCode,
  });

  /// `questions.id` — what the submitted report points at.
  final String questionId;

  /// The question's prompt, quoted in the sheet so the reporter can confirm
  /// what they are flagging.
  final String questionText;

  /// "Football · Level 12" (or the daily label) — human context for the
  /// sheet, never sent to the server.
  final String topicLabel;

  /// The content language the question was served in, stored as the report's
  /// `locale`.
  final String languageCode;
}
