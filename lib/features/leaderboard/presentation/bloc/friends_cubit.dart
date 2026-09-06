import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/friend.dart';

part 'friends_state.dart';

/// Owns S-31 — friend requests and the friends list.
///
/// Accept/decline are mocked as local list edits: there is no real backend
/// to notify, so the only observable effect is the row leaving the
/// "Requests" section (plan 003, Scope).
class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit(this._repository) : super(const FriendsInitial());

  final LeaderboardRepository _repository;

  Future<void> load() async {
    emit(const FriendsLoading());
    try {
      final friends = await _repository.fetchFriends();
      if (isClosed) return;
      emit(FriendsLoaded(friends));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(FriendsError(error));
    }
  }

  void respondToRequest(String friendId, {required bool accept}) {
    final current = state;
    if (current is! FriendsLoaded) return;
    emit(
      FriendsLoaded([
        for (final friend in current.friends)
          if (friend.id != friendId) friend,
      ]),
    );
  }
}
