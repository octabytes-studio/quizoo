import 'package:equatable/equatable.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';

/// What the arena's sticky composer bar offers — derived in
/// `DuelArenaReady.composerState` (plan 017, Phase 8).
sealed class ComposerState extends Equatable {
  const ComposerState();

  @override
  List<Object?> get props => const [];
}

/// "＋ Create challenge".
final class ComposerCreate extends ComposerState {
  const ComposerCreate();
}

/// The 2-minute creation cool-off runs [until] (server time).
final class ComposerCooldown extends ComposerState {
  const ComposerCooldown(this.until);

  final DateTime until;

  @override
  List<Object?> get props => [until];
}

/// The viewer's own [challenge] is open.
final class ComposerOwnOpen extends ComposerState {
  const ComposerOwnOpen(this.challenge);

  final DuelChallenge challenge;

  @override
  List<Object?> get props => [challenge];
}

/// Guests can't create challenges (Decision 4).
final class ComposerSignIn extends ComposerState {
  const ComposerSignIn();
}

/// The viewer is already in duel [duelId].
final class ComposerInDuel extends ComposerState {
  const ComposerInDuel(this.duelId);

  final String duelId;

  @override
  List<Object?> get props => [duelId];
}
