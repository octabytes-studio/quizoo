import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_audio.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_elo_band.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
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
///
/// Plan 017 extends the same discipline to the correct answer itself: the
/// round's full [Question] (with its `correctIndex`) stays private in
/// [_currentQuestion], and the state carries only a [DuelQuestion] — the
/// shape a live duel's client gets — plus
/// [DuelPlayRound.revealedCorrectIndex], set only on the reveal.
class DuelPlayCubit extends Cubit<DuelPlayState> {
  DuelPlayCubit(this._repository, {Random? random, this._audio})
    : _random = random ?? Random(),
      super(const DuelPlayLoading());

  final DuelRepository _repository;
  final Random _random;

  /// Read-aloud + sound effects, as in play mode; null plays nothing
  /// (tests).
  final DuelAudio? _audio;

  static const int totalRounds = DuelApi.roundCount;
  static const Duration secondsPerRound = Duration(seconds: 15);

  /// How long the reveal (correct/wrong colours) stays up before the next
  /// round begins, or the duel ends.
  static const Duration revealDelay = Duration(milliseconds: 1800);

  /// §14: "winner takes 200 🪙" — quoted verbatim from S-38's own row.
  static const int rewardCoinsVictory = 200;
  static const int rewardCoinsDefeat = 40;

  Timer? _clock;
  Timer? _botTimer;
  Timer? _advanceTimer;

  List<Question> _questions = const [];

  /// The round being played, correct index included — never on the state.
  Question? _currentQuestion;
  DuelPlayer? _opponent;
  DuelPlayer? _me;
  DuelTopic? _topic;
  final List<DuelRoundRecord> _history = [];

  /// The opponent's real answer, held privately until both sides have
  /// answered — see the class doc's withheld-correctness rule.
  int? _pendingOpponentAnswerIndex;
  int _pendingOpponentAnswerSeconds = 0;
  int _playerAnswerSecondsLeft = 0;

  Future<void> start(
    DuelPlayer opponent, {
    required DuelPlayer me,
    required DuelTopic topic,
    required String languageCode,
  }) async {
    _opponent = opponent;
    _me = me;
    _topic = topic;
    emit(const DuelPlayLoading());
    try {
      _questions = await _repository.fetchRoundQuestions(
        subcategoryId: topic.id,
        languageCode: languageCode,
      );
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

  /// A design-review deep link reached the bot duel with no topic to draw
  /// questions from — there is nothing to play.
  void failWithoutTopic() => emit(
    const DuelPlayFailed(
      ApiException('No duel topic', code: 'ERR_DUEL_NO_TOPIC'),
    ),
  );

  void _beginRound(int roundNumber) {
    final question = _questions[(roundNumber - 1) % _questions.length];
    _currentQuestion = question;
    if (roundNumber > 1) _audio?.nextQuestion();
    emit(
      DuelPlayRound(
        me: _me!,
        opponent: _opponent!,
        roundNumber: roundNumber,
        totalRounds: totalRounds,
        question: DuelQuestion(
          text: question.text,
          options: question.options,
          audioUrl: question.audioUrl,
          ttsExcluded: question.ttsExcluded,
        ),
        secondsRemaining: secondsPerRound.inSeconds,
        secondsTotal: secondsPerRound.inSeconds,
        history: List.unmodifiable(_history),
        isAudioOn: _audio?.isOn ?? false,
      ),
    );
    _audio?.questionShown(
      audioUrl: question.audioUrl,
      ttsExcluded: question.ttsExcluded,
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
      _audio?.answerLocked();
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
    _audio?.answerLocked();
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
    final question = _currentQuestion;
    if (current is! DuelPlayRound || question == null) return;
    if (!current.playerHasAnswered || !current.opponentHasAnswered) return;

    _stopClock();
    _botTimer?.cancel();

    final correctIndex = question.correctIndex;
    final playerCorrect =
        current.playerAnswerIndex != null &&
        current.playerAnswerIndex == correctIndex;
    final opponentCorrect = _pendingOpponentAnswerIndex == correctIndex;

    // Scoring: every correct answer is a point for whoever gave it — both
    // sides can score on the same question; speed never takes it away.
    final outcome = switch ((playerCorrect, opponentCorrect)) {
      (true, false) => RoundOutcome.playerWon,
      (false, true) => RoundOutcome.opponentWon,
      _ => RoundOutcome.draw,
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
    _audio?.revealed(correct: playerCorrect);

    emit(
      current.copyWith(
        isRevealed: true,
        revealedOpponentAnswerIndex: revealedOpponentIndex,
        revealedCorrectIndex: correctIndex,
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
      unawaited(_finish());
      return;
    }
    _beginRound(finishedRound + 1);
  }

  /// Persists the result via `submit_bot_duel` (plan 006 Phase 5 — the only
  /// change this Cubit makes to the duel flow) and uses the server's
  /// authoritative ELO/coins rather than the client-computed guess. Falls
  /// back to that same guess if the call fails, so a network hiccup does not
  /// strand the player on a frozen play surface.
  Future<void> _finish() async {
    _audio?.stopAll();
    // Points — one per correct answer (equal points are a draw).
    final playerWon = _history.where((round) => round.playerCorrect).length;
    final opponentWon = _history.where((round) => round.opponentCorrect).length;
    final isVictory = playerWon > opponentWon;

    final baseElo = _me!.elo;
    var eloBefore = baseElo;
    var eloAfter = baseElo + (isVictory ? 18 : -12);
    var coinsEarned = isVictory ? rewardCoinsVictory : rewardCoinsDefeat;
    var newlyEarnedBadgeIds = const <String>[];

    try {
      final record = await _repository.submitBotDuel(
        opponentElo: _opponent!.elo,
        playerRoundsWon: playerWon,
        opponentRoundsWon: opponentWon,
        rounds: _history,
        subcategoryId: _topic?.id,
      );
      eloBefore = record.eloBefore;
      eloAfter = record.eloAfter;
      coinsEarned = record.coinsEarned;
      newlyEarnedBadgeIds = record.newlyEarnedBadgeIds;
    } on ApiException {
      // Keep the client-computed estimate above — the play surface still
      // needs to end on something.
    }
    if (isClosed) return;

    final result = DuelResult(
      me: _me!,
      opponent: _opponent!,
      topic: _topic,
      playerRoundsWon: playerWon,
      opponentRoundsWon: opponentWon,
      playerAverageAnswerSeconds: _average(
        _history.map((round) => round.playerAnswerSeconds),
      ),
      opponentAverageAnswerSeconds: _average(
        _history.map((round) => round.opponentAnswerSeconds),
      ),
      eloBefore: eloBefore,
      eloAfter: eloAfter,
      rewardCoins: coinsEarned,
      newlyEarnedBadgeIds: newlyEarnedBadgeIds,
    );
    emit(DuelPlayEnded(result));
  }

  static double _average(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  /// The speaker toggle: flips and persists the read-aloud / sound effects
  /// preference.
  void toggleAudio() {
    final audio = _audio;
    if (audio == null) return;
    final current = state;
    final clockRunning =
        current is DuelPlayRound &&
        !current.playerHasAnswered &&
        !current.isRevealed;
    final on = audio.toggle(clockRunning: clockRunning);
    if (current is DuelPlayRound) emit(current.copyWith(isAudioOn: on));
  }

  @override
  Future<void> close() {
    _stopClock();
    _botTimer?.cancel();
    _advanceTimer?.cancel();
    final audio = _audio;
    if (audio != null) unawaited(audio.dispose());
    return super.close();
  }
}
