import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

part 'bot_rematch_state.dart';

/// S-41's "Rematch" after a practice-bot duel (plan 017, Phase 11): a bot
/// duel has no one to hand-shake with, so a rematch is simply a freshly
/// dealt bot near the player's new ELO, in the same topic.
class BotRematchCubit extends Cubit<BotRematchState> {
  BotRematchCubit(this._repository, {required this.previous})
    : super(const BotRematchIdle());

  final DuelRepository _repository;

  /// The bot duel just finished.
  final DuelResult previous;

  /// Deals the next bot for a duel in [topic].
  Future<void> rematch(DuelTopic topic) async {
    final current = state;
    final busy = switch (current) {
      BotRematchLoading() || BotRematchFound() => true,
      BotRematchIdle() || BotRematchFailed() => false,
    };
    if (busy) return;

    // The next duel starts from where this one left the player.
    final me = previous.me.copyWith(elo: previous.eloAfter);
    emit(const BotRematchLoading());
    try {
      final opponent = await _repository.fetchBotOpponent(playerElo: me.elo);
      if (isClosed) return;
      emit(BotRematchFound(me: me, opponent: opponent, topic: topic));
    } on ApiException catch (error) {
      if (!isClosed) emit(BotRematchFailed(error));
    }
  }
}
