import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/settings/data/notifications_repository.dart';
import 'package:quizoo/features/settings/domain/app_notification.dart';

part 'notifications_state.dart';

/// Owns S-44's list.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsInitial());

  final NotificationsRepository _repository;

  Future<void> load() async {
    emit(const NotificationsLoading());
    try {
      emit(NotificationsLoaded(await _repository.fetchAll()));
    } on ApiException catch (error) {
      emit(NotificationsError(error));
    }
  }

  void markAllRead() {
    if (state is! NotificationsLoaded) return;
    emit(NotificationsLoaded(_repository.markAllRead()));
  }

  /// Resolves the challenge row. Navigating into the duel itself is the
  /// screen's job — this only updates the list underneath it.
  void acceptChallenge(String id) {
    if (state is! NotificationsLoaded) return;
    emit(NotificationsLoaded(_repository.acceptChallenge(id)));
  }
}
