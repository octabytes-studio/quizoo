import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';

part 'daily_result_state.dart';

/// Owns S-28. There is nothing to pass in through a route `extra` — unlike
/// the level-result flow, there is no prior play screen in this plan's scope,
/// so this Cubit both plays and scores today's challenge.
class DailyResultCubit extends Cubit<DailyResultState> {
  DailyResultCubit(this._repository) : super(const DailyResultLoading());

  final DailyRepository _repository;

  Future<void> play({required String languageCode}) async {
    emit(const DailyResultLoading());
    try {
      final result = await _repository.playToday(languageCode: languageCode);
      if (isClosed) return;
      emit(DailyResultLoaded(result));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(DailyResultError(error));
    }
  }
}
