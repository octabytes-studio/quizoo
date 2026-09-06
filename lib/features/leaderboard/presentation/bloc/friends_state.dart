part of 'friends_cubit.dart';

/// S-31's states (CLAUDE.md §3).
sealed class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => const [];
}

final class FriendsInitial extends FriendsState {
  const FriendsInitial();
}

final class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

final class FriendsLoaded extends FriendsState {
  const FriendsLoaded(this.friends);

  final List<Friend> friends;

  List<Friend> get requests => [
    for (final f in friends)
      if (f.status == FriendStatus.pending) f,
  ];

  List<Friend> get accepted =>
      [
        for (final f in friends)
          if (f.status != FriendStatus.pending) f,
      ]..sort((a, b) {
        if (a.status == b.status) return 0;
        return a.status == FriendStatus.online ? -1 : 1;
      });

  @override
  List<Object?> get props => [friends];
}

final class FriendsError extends FriendsState {
  const FriendsError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
