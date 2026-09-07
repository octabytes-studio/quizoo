import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_state.dart';

/// Whether the app is pretending to be offline.
///
/// App-root like [ThemeCubit] and [LocaleCubit], for the same reason
/// (CLAUDE.md §3): the debug "Simulate offline" toggle in Settings (plan 001's
/// Assumption 7) and Home's offline variant (S-46) are on different routes,
/// so the flag has to live above both.
///
/// There is no real `connectivity_plus` package behind this (plan 004's
/// Assumption 5) — it is a manual toggle, not a read of the device's actual
/// network state.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit() : super(const ConnectivityOnline());

  void setOffline(bool isOffline) => emit(
    isOffline ? const ConnectivityOffline() : const ConnectivityOnline(),
  );

  void toggle() => setOffline(state is ConnectivityOnline);
}
