part of 'connectivity_cubit.dart';

/// [ConnectivityCubit]'s two states (CLAUDE.md §3).
sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  bool get isOffline => this is ConnectivityOffline;

  @override
  List<Object?> get props => const [];
}

final class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

final class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}
