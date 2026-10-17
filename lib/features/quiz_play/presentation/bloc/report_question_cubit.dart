import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/report_question_args.dart';
import 'package:quizoo/features/quiz_play/domain/report_reason.dart';

part 'report_question_state.dart';

/// Owns S-51's submission.
///
/// The sheet itself keeps its own selected-reason index (ephemeral UI state,
/// see `ReportQuestionSheet`); everything with a server round trip — the
/// sending flag, the success the screen pops on, the failure it keeps the
/// sheet open for — is here.
class ReportQuestionCubit extends Cubit<ReportQuestionState> {
  ReportQuestionCubit(this._repository, {required this.args})
    : super(const ReportQuestionIdle());

  final QuizPlayRepository _repository;

  /// The question (and its context) this sheet will report.
  final ReportQuestionArgs args;

  Future<void> submit(ReportReason reason) async {
    // A second tap while the insert is in flight (or after it landed) must
    // not file the same report twice.
    if (state is! ReportQuestionIdle) return;
    emit(const ReportQuestionSending());
    try {
      await _repository.reportQuestion(
        questionId: args.questionId,
        reasonCode: reason.code,
        locale: args.languageCode,
      );
      if (isClosed) return;
      emit(const ReportQuestionSent());
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(ReportQuestionFailed(error));
    }
  }
}
