import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';

part 'matchmaking_state.dart';

/// S-39 — owns the search clock and the ELO band it widens.
///
/// **"Cancel — play a bot instead" is offered from frame one**, not only
/// after the timeout (plan 004, Research findings flags this reading of the
/// bible's mockup explicitly). [playBotInstead] and the ~20s auto-offer both
/// resolve to exactly the same [MatchmakingFound] state.
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(this._repository, {required this.playerElo})
    : super(const MatchmakingSearching(elapsedSeconds: 0, widenings: 0));

  final DuelRepository _repository;
  final int playerElo;

  /// Auto-offers a bot after this long (§14).
  static const Duration autoBotTimeout = Duration(seconds: 20);

  /// The ELO band widens this often while searching.
  static const Duration widenInterval = Duration(seconds: 6);

  Timer? _ticker;

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    final current = state;
    if (current is! MatchmakingSearching) return;
    final elapsed = current.elapsedSeconds + 1;
    if (elapsed >= autoBotTimeout.inSeconds) {
      playBotInstead();
      return;
    }
    emit(
      MatchmakingSearching(
        elapsedSeconds: elapsed,
        widenings: elapsed ~/ widenInterval.inSeconds,
      ),
    );
  }

  /// Ends the search immediately with an explicitly-labelled bot — never a
  /// secret one (§14).
  ///
  /// The ticker is only stopped on success. A connection hiccup (`MockApi`'s
  /// own occasional simulated failure) leaves the player still searching
  /// rather than crashing the screen — the running ticker's next timeout, or
  /// another tap, gets another attempt.
  Future<void> playBotInstead() async {
    if (state is MatchmakingFound) return;
    try {
      final opponent = await _repository.fetchBotOpponent(playerElo: playerElo);
      if (isClosed) return;
      _ticker?.cancel();
      emit(MatchmakingFound(opponent));
    } on ApiException {
      // Stays searching — see the doc above.
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
