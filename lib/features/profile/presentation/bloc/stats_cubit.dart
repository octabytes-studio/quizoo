import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/stats_summary.dart';

part 'stats_state.dart';

/// Owns S-35.
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._repository) : super(const StatsInitial());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(const StatsLoading());
    try {
      final stats = await _repository.fetchStats();
      if (isClosed) return;
      emit(StatsLoaded(stats));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(StatsError(error));
    }
  }
}
