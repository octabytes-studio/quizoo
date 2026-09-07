import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

part 'duel_play_state.dart';

/// S-40 — the duel's play surface.
///
/// **The withheld-correctness rule**, the whole architectural point of this
/// Cubit (plan 004, Research findings): a player's own answer never turns
/// green or red the instant they lock it in. [DuelPlayRound.revealedOpponentAnswerIndex]
/// is the mechanism — it is `null`, not merely unused, on every state emitted
/// before both sides have answered, so there is no field anywhere on the
/// public state a widget could read to leak the verdict early. The opponent's
/// real chosen index and correctness live only in this Cubit's private
/// fields ([_pendingOpponentAnswerIndex]) until [_resolveRound] fires, which
/// only happens once [DuelPlayRound.playerHasAnswered] **and**
/// [DuelPlayRound.opponentHasAnswered] are both true.
///
/// The opponent is a scripted bot — a fixed timing table keyed by
/// [DuelEloBand], never a second live client (plan 004, Scope) — but the rule
/// is implemented as a real state transition regardless, because that
/// discipline is what a real multiplayer session would require and the bible
/// is explicit the mock should honour it faithfully.
class DuelPlayCubit extends Cubit<DuelPlayState> {
  DuelPlayCubit(this._repository, {Random? random})
    : _random = random ?? Random(),
      super(const DuelPlayLoading());

  final DuelRepository _repository;
  final Random _random;

  static const int totalRounds = DuelApi.roundCount;
  static const Duration secondsPerRound = Duration(seconds: 15);

  /// How long the reveal (correct/wrong colours) stays up before the next
  /// round begins, or the duel ends.
  static const Duration revealDelay = Duration(milliseconds: 1800);

  /// §14: "winner takes 200 🪙" — quoted verbatim from S-38's own row.
  static const int rewardCoinsVictory = 200;
  static const int rewardCoinsDefeat = 40;

  /// A plausible baseline while there is no real ranked ladder to read from.
  static const int _playerBaseElo = 1200;

  Timer? _clock;
  Timer? _botTimer;
  Timer? _advanceTimer;

  List<Question> _questions = const [];
  DuelOpponent? _opponent;
  final List<DuelRoundRecord> _history = [];

  /// The opponent's real answer, held privately until both sides have
  /// answered — see the class doc's withheld-correctness rule.
  int? _pendingOpponentAnswerIndex;
  int _pendingOpponentAnswerSeconds = 0;
  int _playerAnswerSecondsLeft = 0;

  Future<void> start(DuelOpponent opponent) async {
    _opponent = opponent;
    emit(const DuelPlayLoading());
    try {
      _questions = await _repository.fetchRoundQuestions();
    } on ApiException catch (error) {
      if (!isClosed) emit(DuelPlayFailed(error));
      return;
    }
    if (isClosed) return;
    if (_questions.isEmpty) {
      emit(const DuelPlayFailed(ApiException.network()));
      return;
    }
    _history.clear();
    _beginRound(1);
  }

  void _beginRound(int roundNumber) {
    final question = _questions[(roundNumber - 1) % _questions.length];
    emit(
      DuelPlayRound(
        opponent: _opponent!,
        roundNumber: roundNumber,
        totalRounds: totalRounds,
        question: question,
        secondsRemaining: secondsPerRound.inSeconds,
        secondsTotal: secondsPerRound.inSeconds,
        history: List.unmodifiable(_history),
      ),
    );
    _startClock();
    _scheduleBotAnswer(question);
  }

  // ------------------------------------------------------------------ clock

  void _startClock() {
    var elapsed = Duration.zero;
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      elapsed += const Duration(milliseconds: 100);
      _onTick(elapsed);
    });
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  void _onTick(Duration elapsed) {
    final current = state;
    if (current is! DuelPlayRound || current.playerHasAnswered) return;

    final remainingMs = secondsPerRound.inMilliseconds - elapsed.inMilliseconds;
    final seconds = remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
    if (seconds == current.secondsRemaining) return;

    if (seconds <= 0) {
      _stopClock();
      _playerAnswerSecondsLeft = 0;
      emit(current.copyWith(secondsRemaining: 0, playerHasAnswered: true));
      _maybeResolve();
      return;
    }
    emit(current.copyWith(secondsRemaining: seconds));
  }

  // ----------------------------------------------------------------- player

  /// The player picked [optionIndex]. Locked, but **not** revealed — see the
  /// class doc.
  void answer(int optionIndex) {
    final current = state;
    if (current is! DuelPlayRound || current.playerHasAnswered) return;
    _stopClock();
    _playerAnswerSecondsLeft = current.secondsRemaining;
    emit(
      current.copyWith(playerAnswerIndex: optionIndex, playerHasAnswered: true),
    );
    _maybeResolve();
  }

  // ---------------------------------------------------------------- opponent

  void _scheduleBotAnswer(Question question) {
    _botTimer?.cancel();
    final band = _opponent!.eloBand;
    final base = band.averageAnswerTime.inMilliseconds;
    final jitter = (base * 0.4).round().clamp(1, base);
    final delayMs = (base + _random.nextInt(jitter * 2 + 1) - jitter).clamp(
      400,
      secondsPerRound.inMilliseconds - 200,
    );
    _botTimer = Timer(
      Duration(milliseconds: delayMs),
      () => _onOpponentAnswered(question, delayMs),
    );
  }

  void _onOpponentAnswered(Question question, int delayMs) {
    final current = state;
    if (current is! DuelPlayRound || current.opponentHasAnswered) return;

    final band = _opponent!.eloBand;
    final isCorrect = _random.nextDouble() < band.accuracy;
    _pendingOpponentAnswerIndex = isCorrect
        ? question.correctIndex
        : _firstWrongOptionIndex(question);
    _pendingOpponentAnswerSeconds =
        ((secondsPerRound.inMilliseconds - delayMs) / 1000).round();

    emit(
      current.copyWith(
        opponentHasAnswered: true,
        opponentAnswerSecondsElapsed: (delayMs / 1000).round(),
      ),
    );
    _maybeResolve();
  }

  static int _firstWrongOptionIndex(Question question) {
    for (var index = 0; index < question.options.length; index++) {
      if (index != question.correctIndex) return index;
    }
    return 0;
  }

  // ------------------------------------------------------------- resolution

  /// Reveals the round **only** once both sides have answered.
  void _maybeResolve() {
    final current = state;
    if (current is! DuelPlayRound) return;
    if (!current.playerHasAnswered || !current.opponentHasAnswered) return;

    _stopClock();
    _botTimer?.cancel();

    final playerCorrect =
        current.playerAnswerIndex != null &&
        current.playerAnswerIndex == current.question.correctIndex;
    final opponentCorrect =
        _pendingOpponentAnswerIndex == current.question.correctIndex;

    final outcome = switch ((playerCorrect, opponentCorrect)) {
      (true, false) => RoundOutcome.playerWon,
      (false, true) => RoundOutcome.opponentWon,
      (false, false) => RoundOutcome.draw,
      // Both right: the faster answer (more seconds left) takes the round.
      (true, true) =>
        _playerAnswerSecondsLeft >= _pendingOpponentAnswerSeconds
            ? RoundOutcome.playerWon
            : RoundOutcome.opponentWon,
    };

    _history.add(
      DuelRoundRecord(
        roundNumber: current.roundNumber,
        playerCorrect: playerCorrect,
        opponentCorrect: opponentCorrect,
        playerAnswerSeconds:
            secondsPerRound.inSeconds - _playerAnswerSecondsLeft,
        opponentAnswerSeconds:
            secondsPerRound.inSeconds - _pendingOpponentAnswerSeconds,
        outcome: outcome,
      ),
    );

    final revealedOpponentIndex = _pendingOpponentAnswerIndex;
    _pendingOpponentAnswerIndex = null;

    emit(
      current.copyWith(
        isRevealed: true,
        revealedOpponentAnswerIndex: revealedOpponentIndex,
        history: List.unmodifiable(_history),
      ),
    );

    final finishedRound = current.roundNumber;
    _advanceTimer?.cancel();
    _advanceTimer = Timer(revealDelay, () => _advance(finishedRound));
  }

  void _advance(int finishedRound) {
    if (isClosed) return;
    if (finishedRound >= totalRounds) {
      _finish();
      return;
    }
    _beginRound(finishedRound + 1);
  }

  void _finish() {
    final playerWon = _history
        .where((round) => round.outcome == RoundOutcome.playerWon)
        .length;
    final opponentWon = _history
        .where((round) => round.outcome == RoundOutcome.opponentWon)
        .length;
    final isVictory = playerWon > opponentWon;

    final result = DuelResult(
      opponent: _opponent!,
      playerRoundsWon: playerWon,
      opponentRoundsWon: opponentWon,
      playerAverageAnswerSeconds: _average(
        _history.map((round) => round.playerAnswerSeconds),
      ),
      opponentAverageAnswerSeconds: _average(
        _history.map((round) => round.opponentAnswerSeconds),
      ),
      eloBefore: _playerBaseElo,
      eloAfter: _playerBaseElo + (isVictory ? 18 : -12),
      rewardCoins: isVictory ? rewardCoinsVictory : rewardCoinsDefeat,
    );
    emit(DuelPlayEnded(result));
  }

  static double _average(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  Future<void> close() {
    _stopClock();
    _botTimer?.cancel();
    _advanceTimer?.cancel();
    return super.close();
  }
}
