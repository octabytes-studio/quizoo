import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/avatars_repository.dart';
import 'package:quizoo/features/auth/domain/avatar_option.dart';

part 'avatar_picker_state.dart';

/// Owns S-25's live avatar list — sourced from `avatar_options` where
/// `is_active = true` rather than the old hardcoded `MockPlayer.
/// avatarChoices` list, so adding an avatar needs a Supabase table edit, not
/// an app release (plan 015).
class AvatarPickerCubit extends Cubit<AvatarPickerState> {
  AvatarPickerCubit(this._repository) : super(const AvatarPickerLoading());

  final AvatarsRepository _repository;

  Future<void> load() async {
    emit(const AvatarPickerLoading());
    try {
      final avatars = await _repository.fetchActiveAvatars();
      if (isClosed) return;
      emit(AvatarPickerLoaded(avatars));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(AvatarPickerError(error));
    }
  }
}
