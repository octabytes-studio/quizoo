part of 'safety_cubit.dart';

/// The player-actions sheet's states (CLAUDE.md §3).
sealed class SafetyState extends Equatable {
  const SafetyState();

  @override
  List<Object?> get props => const [];
}

/// Nothing in flight — the sheet shows its report/block choices.
final class SafetyIdle extends SafetyState {
  const SafetyIdle();
}

/// A report/block/unblock is on the wire; further taps are ignored.
final class SafetyBusy extends SafetyState {
  const SafetyBusy();
}

/// The action landed; the sheet confirms and closes.
final class SafetyDone extends SafetyState {
  const SafetyDone(this.outcome);

  final SafetyOutcome outcome;

  @override
  List<Object?> get props => [outcome];
}

/// The action failed; the sheet stays open with an error and can retry.
final class SafetyFailed extends SafetyState {
  const SafetyFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
