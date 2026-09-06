import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_repository.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';

part 'quiz_result_state.dart';

/// Owns S-21 and S-22, and decides what happens after them.
///
/// The run arrives through the route's `extra`, not from a second fetch — the
/// app already holds every answer in memory, and asking a mock backend to
/// hand it back would be theatre.
///
/// **The post-completion chain** is decided here and executed by the screen as
/// route pushes only. This Cubit never imports `features/achievements` or
/// `features/leaderboard`; it exposes booleans and ids, and the screen pushes
/// the reserved routes. If plan 003 has not landed, those pushes reach 001's
/// placeholder — an expected state, not a break.
class QuizResultCubit extends Cubit<QuizResultState> {
  QuizResultCubit(this._repository) : super(const QuizResultLoading());

  final QuizResultRepository _repository;

  Future<void> submit(QuizRun run, {required bool isGuest}) async {
    emit(const QuizResultLoading());
    try {
      final result = await _repository.submit(run, isGuest: isGuest);
      if (isClosed) return;
      emit(
        // Which screen renders is the run's own ending, not a flag passed in:
        // finishing all twenty with a heart is a completion, and everything
        // else — hearts gone, or walked away — is not.
        result.run.isComplete
            ? QuizResultCompleted(result)
            : QuizResultFailed(result),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(QuizResultError(error));
    }
  }

  /// Records that S-24 has been offered, so it appears at most once.
  void markSaveProgressShown() {
    _repository.markSaveProgressShown();
    final current = state;
    if (current is! QuizResultCompleted) return;
    emit(
      QuizResultCompleted(
        current.result.copyWith(shouldOfferSaveProgress: false),
      ),
    );
  }
}
