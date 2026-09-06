import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/profile/data/profile_repository.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';

part 'profile_state.dart';

/// Owns S-32.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileInitial());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      final summary = await _repository.fetchSummary();
      if (isClosed) return;
      emit(ProfileLoaded(summary));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(ProfileError(error));
    }
  }
}
