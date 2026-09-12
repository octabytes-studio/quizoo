import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/daily/data/daily_repository.dart';
import 'package:quizoo/features/daily/domain/daily_challenge.dart';
import 'package:quizoo/features/daily/domain/streak_status.dart';

part 'daily_state.dart';

/// Owns S-27 — today's challenge card plus the streak/milestones card.
class DailyCubit extends Cubit<DailyState> {
  DailyCubit(this._repository) : super(const DailyInitial());

  final DailyRepository _repository;

  Future<void> load({required String languageCode}) async {
    emit(const DailyLoading());
    try {
      final challenge = await _repository.fetchToday(
        languageCode: languageCode,
      );
      final streak = await _repository.fetchStreak();
      if (isClosed) return;
      emit(DailyLoaded(challenge: challenge, streak: streak));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(DailyError(error));
    }
  }
}
