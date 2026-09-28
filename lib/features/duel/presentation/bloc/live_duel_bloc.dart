import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_audio.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_room_event.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/duel/domain/duel_side.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/live_duel_outcome.dart';
import 'package:quizoo/features/duel/domain/live_duel_round_state.dart';
import 'package:quizoo/features/duel/domain/live_duel_snapshot.dart';

part 'live_duel_event.dart';
part 'live_duel_state.dart';

/// S-40 — a live, server-refereed duel against a real player (plan 017,
/// "Live duel protocol").
///
/// **Snapshot + deltas.** [LiveDuelStarted] loads `get_duel_state`, joins the
/// room channel and marks this player ready; from then on the room's
/// broadcasts drive the state, and any channel re-subscribe or app resume
/// refetches the snapshot and reconciles, so a missed broadcast heals
/// itself.
///
/// **Server time is the only time.** Every countdown reads the shared
/// [ServerClock]; the question is fetched just before the round's server
/// `startsAt` (the server refuses earlier — plan 017, A2), and the player's
/// own answer time is measured from the moment the question was shown with
/// [ServerClock.localNow] differences (A3). A reconnect resumes against the
/// real server deadline rather than a fresh clock (A4).
///
/// **Sound.** With a [DuelAudio], each question is read aloud as it appears
/// and play mode's tick / correct / wrong / next chimes play, behind the
/// player's own persisted speaker toggle ([LiveDuelAudioToggled]).
///
/// **Withheld correctness.** The correct index and the opponent's choice only
/// ever reach [LiveDuelRound] from a `RoundResolved`; before that the client
/// simply does not have them.
///
/// Pure Dart — no widgets, no navigation (CLAUDE.md §3).
class LiveDuelBloc extends Bloc<LiveDuelEvent, LiveDuelState> {
  LiveDuelBloc(
    this._repository,
    this._clock, {
    required this.duelId,
    this._audio,
    this.languageCode = 'en',
  }) : super(const LiveDuelConnecting()) {
    on<LiveDuelStarted>(_onStarted);
    on<LiveDuelServerEvent>(_onServerEvent);
    on<LiveDuelTicked>(_onTicked);
    on<LiveDuelAnswerSelected>(_onAnswerSelected);
    on<LiveDuelQuitConfirmed>(_onQuitConfirmed);
    on<LiveDuelResumed>(_onResumed);
    on<LiveDuelAudioToggled>(_onAudioToggled);
  }

  final LiveDuelRepository _repository;
  final ServerClock _clock;
  final String duelId;

  /// Read-aloud + sound effects; null plays nothing (tests).
  final DuelAudio? _audio;

  /// The duel's content language — which narration voice to use.
  final String languageCode;

  /// How often the screen's clocks advance.
  static const Duration tickInterval = Duration(milliseconds: 100);

  /// The question is fetched this long before the round's server start (the
  /// server accepts it from 500 ms before).
  static const Duration fetchLead = Duration(milliseconds: 300);

  /// A `too_early` answer (question fetch or timeout claim) is retried after
  /// this long.
  static const Duration tooEarlyRetry = Duration(milliseconds: 250);

  /// Any other failed fetch/claim is retried after this long.
  static const Duration errorRetry = Duration(seconds: 1);

  /// The client claims a timed-out round this long after its deadline.
  static const Duration claimGrace = Duration(seconds: 1);

  /// Still unresolved this long after the deadline → refetch the snapshot.
  static const Duration unresolvedReconcileAfter = Duration(seconds: 3);

  /// An answer is retried this many times on a network error.
  static const int submitRetries = 2;
  static const Duration submitRetryDelay = Duration(milliseconds: 250);

  /// After "Leave", the snapshot is refetched if `duel_end` hasn't arrived.
  static const Duration quitReconcileDelay = Duration(seconds: 3);

  Timer? _ticker;
  StreamSubscription<DuelRoomEvent>? _room;
  bool _started = false;

  // Who is who — set by the first snapshot.
  _Cast? _cast;
  DuelConfig _config = DuelConfig.fallback;
  int _roundSeconds = DuelConfig.fallback.roundSeconds;
  int _totalRounds = DuelConfig.fallback.rounds;
  final List<DuelRoundRecord> _history = [];
  int _myScore = 0;
  int _opponentScore = 0;
  bool _opponentOnline = true;
  DateTime? _opponentOfflineSince;

  // The round on screen (server instants) and when its question appeared
  // (local instant — the answer stopwatch).
  DateTime? _roundStartsAt;
  DateTime? _roundDeadline;
  DateTime? _questionShownAt;

  /// The next round, once `round_start` announced it.
  _ScheduledRound? _scheduled;

  /// Opponent locks for a round this client has not entered yet.
  final Map<int, AnswerLocked> _earlyOpponentLocks = {};

  // In-flight guards and retry instants (local clock).
  bool _fetching = false;
  DateTime? _fetchRetryAt;
  int? _closedRound;
  bool _claiming = false;
  DateTime? _claimRetryAt;
  int? _claimedRound;
  int? _lateReconciledRound;
  bool _reconciling = false;
  bool _readyMarked = false;
  bool _channelDropped = false;
  bool _quitRequested = false;
  DateTime? _quitReconcileAt;
  DateTime? _nextHeartbeatAt;
  DateTime? _revealedAt;
  DuelResult? _pendingResult;

  bool get _isTerminal =>
      state is LiveDuelEnded ||
      state is LiveDuelAbandoned ||
      state is LiveDuelFailed;

  int get _roundMs => _roundSeconds * 1000;

  // ---------------------------------------------------------------- start

  Future<void> _onStarted(
    LiveDuelStarted event,
    Emitter<LiveDuelState> emit,
  ) async {
    if (_started) return;
    _started = true;

    final LiveDuelSnapshot snapshot;
    try {
      snapshot = await _repository.fetchState(duelId);
    } on ApiException catch (error) {
      emit(LiveDuelFailed(error));
      return;
    }
    if (isClosed) return;

    _room = _repository
        .roomEvents(duelId, opponentId: snapshot.opponent.id)
        .listen(
          (roomEvent) {
            if (!isClosed) add(LiveDuelServerEvent(roomEvent));
          },
          onError: (Object _) {
            if (!isClosed) {
              add(
                const LiveDuelServerEvent(
                  RoomChannelStatusChanged(isLive: false),
                ),
              );
            }
          },
        );

    _applySnapshot(snapshot, emit);
    if (_isTerminal) return;
    final audio = _audio;
    if (audio != null) unawaited(audio.prepare(languageCode));

    _ticker = Timer.periodic(tickInterval, (_) {
      if (!isClosed) add(const LiveDuelTicked());
    });
    await _markReady(emit);
  }

  Future<void> _markReady(Emitter<LiveDuelState> emit) async {
    try {
      final status = await _repository.markReady(duelId);
      _readyMarked = true;
      // Both are ready and round 1 is already scheduled — possibly before
      // this client's room channel was listening, so ask for it.
      if (status == LiveDuelStatus.active && _isWaitingForOpponent) {
        await _reconcile(emit);
      }
    } on ApiException {
      // Retried on the next heartbeat while the intro is still waiting.
    }
  }

  /// The intro with no round 1 scheduled yet.
  bool get _isWaitingForOpponent {
    final current = state;
    return current is LiveDuelIntro &&
        current.startsAt == null &&
        _scheduled == null;
  }

  // -------------------------------------------------------- server events

  Future<void> _onServerEvent(
    LiveDuelServerEvent event,
    Emitter<LiveDuelState> emit,
  ) async {
    if (_cast == null || _isTerminal) return;
    switch (event.event) {
      case final RoundScheduled scheduled:
        await _onRoundScheduled(scheduled, emit);
      case final AnswerLocked locked:
        _onAnswerLocked(locked, emit);
      case final RoundResolved resolved:
        await _onRoundResolved(resolved, emit);
      case final DuelFinished finished:
        _onDuelFinished(finished, emit);
      case RematchUpdate():
        // The result screen's business (DuelRematchCubit).
        return;
      case RoomChannelStatusChanged(:final isLive):
        if (!isLive) {
          _channelDropped = true;
          return;
        }
        final waiting = _readyMarked && _isWaitingForOpponent;
        if (_channelDropped || waiting) {
          _channelDropped = false;
          await _reconcile(emit);
        }
      case OpponentPresenceChanged(:final online):
        _onPresence(online: online, emit: emit);
    }
  }

  Future<void> _onRoundScheduled(
    RoundScheduled event,
    Emitter<LiveDuelState> emit,
  ) async {
    _roundSeconds = event.roundSeconds;
    _totalRounds = event.totalRounds;
    final current = state;

    if (current is LiveDuelRound) {
      if (event.round == current.roundNumber) {
        _roundStartsAt = event.startsAt;
        _roundDeadline = event.deadline;
        return;
      }
      if (event.round < current.roundNumber) return;
      _scheduled = _ScheduledRound(
        round: event.round,
        startsAt: event.startsAt,
        deadline: event.deadline,
      );
      if (current.isRevealed) {
        emit(current.copyWith(nextRoundAt: event.startsAt));
      } else {
        // This round's `round_result` never arrived — heal from the snapshot.
        await _reconcile(emit);
      }
      return;
    }

    if (current is LiveDuelIntro) {
      _scheduled = _ScheduledRound(
        round: event.round,
        startsAt: event.startsAt,
        deadline: event.deadline,
      );
      emit(_intro(startsAt: event.startsAt, now: _clock.now()));
    }
  }

  void _onAnswerLocked(AnswerLocked event, Emitter<LiveDuelState> emit) {
    // This player's own lock is already on screen.
    if (event.userId == _cast!.me.id) return;
    final current = state;
    if (current is LiveDuelRound && event.round == current.roundNumber) {
      if (current.isRevealed || current.opponentLocked) return;
      emit(
        current.copyWith(
          opponentLocked: true,
          opponentSeconds: _secondsFor(event.ms),
        ),
      );
    } else if (current is! LiveDuelRound || event.round > current.roundNumber) {
      // The opponent is a beat ahead of this client entering the round.
      _earlyOpponentLocks[event.round] = event;
    }
  }

  Future<void> _onRoundResolved(
    RoundResolved event,
    Emitter<LiveDuelState> emit,
  ) async {
    final side = _cast!.mySide;
    final opponentSide = side.other;
    _myScore = event.roundsOf(side);
    _opponentScore = event.roundsOf(opponentSide);
    _history
      ..removeWhere((round) => round.roundNumber == event.round)
      ..add(
        DuelRoundRecord.live(
          roundNumber: event.round,
          outcome: _outcomeFor(event.outcome, side),
          correctIndex: event.correctIndex,
          roundSeconds: _roundSeconds,
          playerChoice: event.choiceOf(side),
          opponentChoice: event.choiceOf(opponentSide),
          playerMs: event.msOf(side),
          opponentMs: event.msOf(opponentSide),
        ),
      )
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    final current = state;
    if (current is LiveDuelRound && current.roundNumber == event.round) {
      _revealedAt = _clock.localNow();
      _audio?.revealed(correct: event.choiceOf(side) == event.correctIndex);
      emit(
        current.copyWith(
          isRevealed: true,
          correctIndex: event.correctIndex,
          opponentChoice: event.choiceOf(opponentSide),
          myLocked: true,
          myChoice: event.choiceOf(side),
          mySeconds: current.mySeconds ?? _secondsFor(event.msOf(side)),
          opponentLocked: true,
          opponentSeconds: _secondsFor(event.msOf(opponentSide)),
          myScore: _myScore,
          opponentScore: _opponentScore,
          history: List.unmodifiable(_history),
        ),
      );
    } else if (current is LiveDuelIntro ||
        (current is LiveDuelRound && event.round > current.roundNumber)) {
      // Rounds went by that this client never saw — catch up.
      await _reconcile(emit);
    }
  }

  void _onDuelFinished(DuelFinished event, Emitter<LiveDuelState> emit) {
    if (event.isAbandoned) {
      _abandon(event.cause ?? 'abandoned', emit);
      return;
    }
    final result = _resultFromBroadcast(event);
    // Let the last round's reveal stay up for its full beat first.
    final revealedAt = _revealedAt;
    final current = state;
    final holdReveal =
        !_quitRequested &&
        current is LiveDuelRound &&
        current.isRevealed &&
        revealedAt != null &&
        _clock.localNow().difference(revealedAt) < _revealHold;
    if (holdReveal) {
      _pendingResult = result;
      return;
    }
    _finish(result, emit);
  }

  void _onPresence({
    required bool online,
    required Emitter<LiveDuelState> emit,
  }) {
    _opponentOnline = online;
    _opponentOfflineSince = online ? null : _clock.now();
    final current = state;
    if (current is LiveDuelRound) {
      emit(
        current.copyWith(
          opponentOnline: online,
          opponentOfflineSince: _opponentOfflineSince,
          opponentReconnectSeconds: online ? null : 0,
        ),
      );
    }
  }

  // ----------------------------------------------------------------- tick

  Future<void> _onTicked(
    LiveDuelTicked event,
    Emitter<LiveDuelState> emit,
  ) async {
    if (_cast == null || _isTerminal) return;
    final localNow = _clock.localNow();
    final now = _clock.now();

    final pending = _pendingResult;
    if (pending != null) {
      final revealedAt = _revealedAt;
      if (revealedAt == null ||
          localNow.difference(revealedAt) >= _revealHold) {
        _finish(pending, emit);
      }
      return;
    }

    final quitCheckAt = _quitReconcileAt;
    if (quitCheckAt != null && !localNow.isBefore(quitCheckAt)) {
      _quitReconcileAt = null;
      await _reconcile(emit);
      return;
    }

    if (await _heartbeatIfDue(localNow, emit)) return;

    final current = state;
    if (current is LiveDuelIntro) {
      await _tickIntro(current, now, emit);
    } else if (current is LiveDuelRound) {
      await _tickRound(current, now, localNow, emit);
    }
  }

  /// Sends the duel heartbeat on its cadence; while the intro is still
  /// waiting for the opponent it also retries "ready" or polls the snapshot,
  /// in case round 1's broadcast was missed. Returns true when it took over
  /// this tick.
  Future<bool> _heartbeatIfDue(
    DateTime localNow,
    Emitter<LiveDuelState> emit,
  ) async {
    final interval = Duration(
      seconds: math.max(1, _config.duelHeartbeatSeconds),
    );
    final due = _nextHeartbeatAt;
    if (due == null) {
      _nextHeartbeatAt = localNow.add(interval);
      return false;
    }
    if (localNow.isBefore(due)) return false;
    _nextHeartbeatAt = localNow.add(interval);
    unawaited(_beat());
    if (!_isWaitingForOpponent) return false;
    if (_readyMarked) {
      await _reconcile(emit);
    } else {
      await _markReady(emit);
    }
    return true;
  }

  Future<void> _beat() async {
    try {
      await _repository.heartbeat(duelId);
    } on ApiException {
      // The next beat tries again; the server forfeits only after 30 s.
    }
  }

  Future<void> _tickIntro(
    LiveDuelIntro current,
    DateTime now,
    Emitter<LiveDuelState> emit,
  ) async {
    final scheduled = _scheduled;
    if (scheduled != null && _isDue(scheduled.startsAt, now)) {
      _enterRound(scheduled, emit);
      await _fetchQuestion(emit);
      return;
    }
    final next = _intro(startsAt: current.startsAt, now: now);
    if (next.secondsToStart != current.secondsToStart) emit(next);
  }

  Future<void> _tickRound(
    LiveDuelRound current,
    DateTime now,
    DateTime localNow,
    Emitter<LiveDuelState> emit,
  ) async {
    // The next round's start: leave the reveal and fetch its question.
    final scheduled = _scheduled;
    if (scheduled != null &&
        scheduled.round > current.roundNumber &&
        _isDue(scheduled.startsAt, now)) {
      _enterRound(scheduled, emit);
      await _fetchQuestion(emit);
      return;
    }

    var next = current;

    final since = _opponentOfflineSince;
    if (!current.opponentOnline && since != null) {
      final offlineSeconds = math.max(0, now.difference(since).inSeconds);
      if (offlineSeconds != current.opponentReconnectSeconds) {
        next = next.copyWith(opponentReconnectSeconds: offlineSeconds);
      }
    }

    if (current.isRevealed) {
      if (next != current) emit(next);
      return;
    }

    // The round clock — and the automatic timeout lock at zero.
    if (current.question != null && _questionShownAt != null) {
      final seconds = _secondsLeft(now, localNow);
      if (seconds != current.secondsRemaining) {
        next = next.copyWith(secondsRemaining: seconds);
      }
      if (seconds == 0 && !current.myLocked) {
        next = next.copyWith(myLocked: true, mySeconds: _roundSeconds);
        _audio?.answerLocked();
        unawaited(
          _submit(current.roundNumber, choice: null, clientMs: _roundMs),
        );
      }
    }
    if (next != current) emit(next);

    // Past the deadline with no result: claim the timeout.
    final deadline = _roundDeadline;
    if (deadline != null) {
      final claimRetryAt = _claimRetryAt;
      if (!_claiming &&
          _claimedRound != current.roundNumber &&
          !now.isBefore(deadline.add(claimGrace)) &&
          (claimRetryAt == null || !localNow.isBefore(claimRetryAt))) {
        unawaited(_claim(current.roundNumber));
      }
      // Still nothing well after the claim — the broadcast was lost.
      if (_lateReconciledRound != current.roundNumber &&
          !now.isBefore(deadline.add(unresolvedReconcileAfter))) {
        _lateReconciledRound = current.roundNumber;
        await _reconcile(emit);
        return;
      }
    }

    // The question, at the round's start (retrying after failures).
    if (current.question == null &&
        !_fetching &&
        _closedRound != current.roundNumber) {
      final startsAt = _roundStartsAt;
      final retryAt = _fetchRetryAt;
      final due = startsAt == null || _isDue(startsAt, now);
      if (due && (retryAt == null || !localNow.isBefore(retryAt))) {
        await _fetchQuestion(emit);
      }
    }
  }

  bool _isDue(DateTime startsAt, DateTime now) =>
      !now.isBefore(startsAt.subtract(fetchLead));

  /// Whole seconds left on the round clock: the player's own stopwatch from
  /// the question's display, never past the server's deadline (A4).
  int _secondsLeft(DateTime now, DateTime localNow) {
    final shownAt = _questionShownAt;
    if (shownAt == null) return _roundSeconds;
    var remainingMs = _roundMs - localNow.difference(shownAt).inMilliseconds;
    final deadline = _roundDeadline;
    if (deadline != null) {
      remainingMs = math.min(
        remainingMs,
        deadline.difference(now).inMilliseconds,
      );
    }
    return remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
  }

  void _enterRound(_ScheduledRound scheduled, Emitter<LiveDuelState> emit) {
    _scheduled = null;
    _resetRoundTracking(
      startsAt: scheduled.startsAt,
      deadline: scheduled.deadline,
    );
    final early = _earlyOpponentLocks.remove(scheduled.round);
    if (scheduled.round > 1) _audio?.nextQuestion();
    emit(
      _freshRound(
        roundNumber: scheduled.round,
        opponentLocked: early != null,
        opponentSeconds: early == null ? null : _secondsFor(early.ms),
      ),
    );
  }

  void _resetRoundTracking({DateTime? startsAt, DateTime? deadline}) {
    _roundStartsAt = startsAt;
    _roundDeadline = deadline;
    _questionShownAt = null;
    _fetchRetryAt = null;
    _closedRound = null;
    _claimRetryAt = null;
    _claimedRound = null;
    _revealedAt = null;
  }

  Future<void> _fetchQuestion(Emitter<LiveDuelState> emit) async {
    final current = state;
    if (current is! LiveDuelRound || current.question != null || _fetching) {
      return;
    }
    final round = current.roundNumber;
    _fetching = true;
    try {
      final fetched = await _repository.fetchRound(duelId, round);
      final latest = state;
      if (isClosed ||
          latest is! LiveDuelRound ||
          latest.roundNumber != round ||
          latest.question != null) {
        return;
      }
      _roundStartsAt = fetched.startsAt;
      _roundDeadline = fetched.deadline;
      _questionShownAt = _clock.localNow();
      emit(
        latest.copyWith(
          question: fetched.question,
          secondsRemaining: _secondsLeft(_clock.now(), _clock.localNow()),
        ),
      );
      if (!latest.myLocked) {
        _audio?.questionShown(
          audioUrl: fetched.question.audioUrl,
          ttsExcluded: fetched.question.ttsExcluded,
        );
      }
    } on ApiException catch (error) {
      switch (error.code) {
        case 'too_early':
          _fetchRetryAt = _clock.localNow().add(tooEarlyRetry);
        case 'round_closed':
          // The round is over — its `round_result` resolves the screen.
          _closedRound = round;
        default:
          _fetchRetryAt = _clock.localNow().add(errorRetry);
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _claim(int round) async {
    _claiming = true;
    try {
      await _repository.claimTimeout(duelId, round);
      _claimedRound = round;
    } on ApiException catch (error) {
      if (error.code == 'too_early') {
        _claimRetryAt = _clock.localNow().add(tooEarlyRetry);
      } else if (_isTransient(error)) {
        _claimRetryAt = _clock.localNow().add(errorRetry);
      } else {
        // Refused for good (already resolved, duel over) — the snapshot
        // reconcile after the deadline settles the screen.
        _claimedRound = round;
      }
    } finally {
      _claiming = false;
    }
  }

  // --------------------------------------------------------------- answer

  Future<void> _onAnswerSelected(
    LiveDuelAnswerSelected event,
    Emitter<LiveDuelState> emit,
  ) async {
    final current = state;
    if (current is! LiveDuelRound) return;
    final question = current.question;
    final shownAt = _questionShownAt;
    if (question == null ||
        shownAt == null ||
        current.myLocked ||
        current.isRevealed) {
      return;
    }
    if (event.index < 0 || event.index >= question.options.length) return;

    final clientMs = _clock
        .localNow()
        .difference(shownAt)
        .inMilliseconds
        .clamp(0, _roundMs);
    emit(
      current.copyWith(
        myLocked: true,
        myChoice: event.index,
        mySeconds: (clientMs / 1000).round(),
      ),
    );
    _audio?.answerLocked();
    await _submit(current.roundNumber, choice: event.index, clientMs: clientMs);
  }

  /// Locks the answer server-side, retrying [submitRetries] times on a
  /// network error while the round is still open.
  Future<void> _submit(
    int round, {
    required int? choice,
    required int clientMs,
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        await _repository.submitAnswer(
          duelId,
          round: round,
          choice: choice,
          clientMs: clientMs,
        );
        return;
      } on ApiException catch (error) {
        // Already locked, or too late — `round_result` settles it either way.
        if (error.code == 'already_answered' || error.code == 'round_closed') {
          return;
        }
        final deadline = _roundDeadline;
        final beforeDeadline =
            deadline == null || _clock.now().isBefore(deadline);
        if (!_isTransient(error) ||
            !beforeDeadline ||
            attempt >= submitRetries ||
            isClosed) {
          return;
        }
      }
      await Future<void>.delayed(submitRetryDelay);
      if (isClosed) return;
    }
  }

  static bool _isTransient(ApiException error) =>
      error.kind == ApiErrorKind.network ||
      error.kind == ApiErrorKind.timeout ||
      error.kind == ApiErrorKind.unknown;

  // ---------------------------------------------------------------- sound

  void _onAudioToggled(
    LiveDuelAudioToggled event,
    Emitter<LiveDuelState> emit,
  ) {
    final audio = _audio;
    if (audio == null) return;
    final current = state;
    final clockRunning =
        current is LiveDuelRound &&
        current.question != null &&
        !current.myLocked &&
        !current.isRevealed;
    final on = audio.toggle(clockRunning: clockRunning);
    if (current is LiveDuelRound) emit(current.copyWith(isAudioOn: on));
  }

  // ------------------------------------------------------- quit / resume

  Future<void> _onQuitConfirmed(
    LiveDuelQuitConfirmed event,
    Emitter<LiveDuelState> emit,
  ) async {
    if (_isTerminal) return;
    _quitRequested = true;
    try {
      await _repository.leave(duelId);
    } on ApiException {
      // The reconcile below reads whatever the server decided.
    }
    if (isClosed || _isTerminal) return;
    // `duel_end` normally lands first; if it never does, ask.
    _quitReconcileAt = _clock.localNow().add(quitReconcileDelay);
  }

  Future<void> _onResumed(
    LiveDuelResumed event,
    Emitter<LiveDuelState> emit,
  ) async {
    if (_cast == null) return;
    await _reconcile(emit);
  }

  // ------------------------------------------------------------ snapshot

  Future<void> _reconcile(Emitter<LiveDuelState> emit) async {
    if (_reconciling || _isTerminal) return;
    _reconciling = true;
    try {
      final snapshot = await _repository.fetchState(duelId);
      if (isClosed || _isTerminal) return;
      _applySnapshot(snapshot, emit);
    } on ApiException {
      // Transient — the next drop, resume or deadline check tries again.
    } finally {
      _reconciling = false;
    }
  }

  /// Builds (or reconciles) the screen from a snapshot, never regressing
  /// what this client already shows for the same round.
  void _applySnapshot(LiveDuelSnapshot snapshot, Emitter<LiveDuelState> emit) {
    _cast = _Cast(
      mySide: snapshot.mySide,
      me: snapshot.me,
      opponent: snapshot.opponent,
      topic: snapshot.topic,
      isRanked: snapshot.isRanked,
    );
    _config = snapshot.config;
    _roundSeconds = snapshot.config.roundSeconds;
    _totalRounds = snapshot.config.rounds;
    _history
      ..clear()
      ..addAll(snapshot.history)
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    _myScore = snapshot.myScore;
    _opponentScore = snapshot.opponentScore;

    final outcome = snapshot.result;
    if (snapshot.status == LiveDuelStatus.abandoned ||
        outcome?.reason == 'abandoned') {
      _abandon(outcome?.cause ?? 'abandoned', emit);
      return;
    }
    if (!snapshot.isLive) {
      _finish(_resultFromSnapshot(snapshot, outcome), emit);
      return;
    }

    final round = snapshot.round;
    final now = _clock.now();
    final current = state;
    if (snapshot.status == LiveDuelStatus.pending || round == null) {
      _scheduled = null;
      emit(_intro(startsAt: null, now: now));
      return;
    }

    final startsAt = round.startsAt;
    final beforeStart =
        round.question == null && startsAt != null && !_isDue(startsAt, now);

    // Round 1 is scheduled but hasn't begun: the intro's countdown.
    if (beforeStart && round.number == 1 && current is! LiveDuelRound) {
      _scheduled = _ScheduledRound(
        round: 1,
        startsAt: startsAt,
        deadline: round.deadline,
      );
      emit(_intro(startsAt: startsAt, now: now));
      return;
    }

    // Between rounds: keep the previous reveal up until the next one starts.
    if (beforeStart &&
        current is LiveDuelRound &&
        current.isRevealed &&
        current.roundNumber == round.number - 1) {
      _scheduled = _ScheduledRound(
        round: round.number,
        startsAt: startsAt,
        deadline: round.deadline,
      );
      emit(
        current.copyWith(
          nextRoundAt: startsAt,
          myScore: _myScore,
          opponentScore: _opponentScore,
          history: List.unmodifiable(_history),
        ),
      );
      return;
    }

    // The round already on screen: merge, never regress.
    if (current is LiveDuelRound && current.roundNumber == round.number) {
      _roundStartsAt = startsAt ?? _roundStartsAt;
      _roundDeadline = round.deadline ?? _roundDeadline;
      var next = current.copyWith(
        myScore: _myScore,
        opponentScore: _opponentScore,
        history: List.unmodifiable(_history),
        myLocked: current.myLocked || round.myLocked,
        myChoice: current.myChoice ?? round.myChoice,
        mySeconds:
            current.mySeconds ??
            (round.myLocked ? _secondsFor(round.myMs) : null),
        opponentLocked: current.opponentLocked || round.opponentLocked,
        opponentSeconds:
            current.opponentSeconds ??
            (round.opponentLocked ? _secondsFor(round.opponentMs) : null),
      );
      final question = round.question;
      if (current.question == null && question != null) {
        _questionShownAt = _resumedShownAt(startsAt);
        next = next.copyWith(
          question: question,
          secondsRemaining: _secondsLeft(now, _clock.localNow()),
        );
      }
      emit(next);
      return;
    }

    // Anything else: rebuild the round from the snapshot.
    final scheduled = _scheduled;
    if (scheduled != null && scheduled.round <= round.number) {
      _scheduled = null;
    }
    _resetRoundTracking(startsAt: startsAt, deadline: round.deadline);
    _rebuildRound(round, emit);
  }

  void _rebuildRound(LiveDuelRoundState round, Emitter<LiveDuelState> emit) {
    final question = round.question;
    if (question != null) {
      _questionShownAt = _resumedShownAt(round.startsAt);
    }
    final early = _earlyOpponentLocks.remove(round.number);
    final opponentLocked = round.opponentLocked || early != null;
    final fresh = _freshRound(
      roundNumber: round.number,
      opponentLocked: opponentLocked,
      opponentSeconds: round.opponentLocked
          ? _secondsFor(round.opponentMs)
          : (early == null ? null : _secondsFor(early.ms)),
    );
    emit(
      fresh.copyWith(
        question: question,
        secondsRemaining: question == null
            ? _roundSeconds
            : _secondsLeft(_clock.now(), _clock.localNow()),
        myLocked: round.myLocked,
        myChoice: round.myChoice,
        mySeconds: round.myLocked ? _secondsFor(round.myMs) : null,
      ),
    );
  }

  /// A question seen again after a reconnect keeps the round's real clock:
  /// the stopwatch is backdated to the round's server start (A4).
  DateTime _resumedShownAt(DateTime? startsAt) {
    final localNow = _clock.localNow();
    if (startsAt == null) return localNow;
    final sinceStart = _clock.now().difference(startsAt);
    return sinceStart.isNegative ? localNow : localNow.subtract(sinceStart);
  }

  // ------------------------------------------------------------- builders

  LiveDuelIntro _intro({required DateTime? startsAt, required DateTime now}) {
    final cast = _cast!;
    return LiveDuelIntro(
      me: cast.me,
      opponent: cast.opponent,
      topic: cast.topic,
      isRanked: cast.isRanked,
      startsAt: startsAt,
      now: now,
    );
  }

  LiveDuelRound _freshRound({
    required int roundNumber,
    bool opponentLocked = false,
    int? opponentSeconds,
  }) {
    final cast = _cast!;
    final since = _opponentOfflineSince;
    return LiveDuelRound(
      me: cast.me,
      opponent: cast.opponent,
      topic: cast.topic,
      isRanked: cast.isRanked,
      roundNumber: roundNumber,
      totalRounds: _totalRounds,
      secondsRemaining: _roundSeconds,
      secondsTotal: _roundSeconds,
      myScore: _myScore,
      opponentScore: _opponentScore,
      history: List.unmodifiable(_history),
      opponentLocked: opponentLocked,
      opponentSeconds: opponentSeconds,
      opponentOnline: _opponentOnline,
      opponentOfflineSince: since,
      opponentReconnectSeconds: since == null
          ? null
          : math.max(0, _clock.now().difference(since).inSeconds),
      isAudioOn: _audio?.isOn ?? false,
    );
  }

  int _secondsFor(int? ms) => ms == null ? _roundSeconds : (ms / 1000).round();

  Duration get _revealHold =>
      Duration(seconds: math.max(0, _config.revealSeconds));

  static RoundOutcome _outcomeFor(
    RoundSideOutcome outcome,
    DuelSide mySide,
  ) => switch (outcome) {
    RoundSideOutcome.draw => RoundOutcome.draw,
    RoundSideOutcome.p1 =>
      mySide == DuelSide.p1 ? RoundOutcome.playerWon : RoundOutcome.opponentWon,
    RoundSideOutcome.p2 =>
      mySide == DuelSide.p2 ? RoundOutcome.playerWon : RoundOutcome.opponentWon,
  };

  DuelResult _resultFromBroadcast(DuelFinished event) {
    final cast = _cast!;
    final side = cast.mySide;
    final mine = event.resultOf(side);
    return DuelResult(
      me: cast.me,
      opponent: cast.opponent,
      playerRoundsWon: event.roundsOf(side),
      opponentRoundsWon: event.roundsOf(side.other),
      playerAverageAnswerSeconds: _averageSeconds(
        event.avgMsOf(side),
        _history.map((round) => round.playerAnswerSeconds),
      ),
      opponentAverageAnswerSeconds: _averageSeconds(
        event.avgMsOf(side.other),
        _history.map((round) => round.opponentAnswerSeconds),
      ),
      eloBefore: mine?.eloBefore ?? cast.me.elo,
      eloAfter: mine?.eloAfter ?? cast.me.elo,
      rewardCoins: mine?.coins ?? 0,
      xpEarned: mine?.xp ?? 0,
      newlyEarnedBadgeIds: mine?.badgeIds ?? const [],
      duelId: duelId,
      isBot: false,
      topic: cast.topic,
      isRanked: event.isRanked,
      endReason: switch (event.forfeitedBy) {
        null => DuelEndReason.completed,
        final id when id == cast.me.id => DuelEndReason.youForfeited,
        _ => DuelEndReason.opponentForfeited,
      },
    );
  }

  DuelResult _resultFromSnapshot(
    LiveDuelSnapshot snapshot,
    LiveDuelOutcome? outcome,
  ) {
    final settled =
        outcome != null && (outcome.eloBefore != 0 || outcome.eloAfter != 0);
    return DuelResult(
      me: snapshot.me,
      opponent: snapshot.opponent,
      playerRoundsWon: snapshot.myScore,
      opponentRoundsWon: snapshot.opponentScore,
      playerAverageAnswerSeconds: _averageSeconds(
        outcome?.myAvgMs,
        _history.map((round) => round.playerAnswerSeconds),
      ),
      opponentAverageAnswerSeconds: _averageSeconds(
        outcome?.opponentAvgMs,
        _history.map((round) => round.opponentAnswerSeconds),
      ),
      eloBefore: settled ? outcome.eloBefore : snapshot.me.elo,
      eloAfter: settled ? outcome.eloAfter : snapshot.me.elo,
      rewardCoins: outcome?.coins ?? 0,
      xpEarned: outcome?.xp ?? 0,
      newlyEarnedBadgeIds: outcome?.badgeIds ?? const [],
      duelId: duelId,
      isBot: false,
      topic: snapshot.topic,
      isRanked: snapshot.isRanked,
      endReason: outcome == null
          ? DuelEndReason.completed
          : outcome.youForfeited
          ? DuelEndReason.youForfeited
          : outcome.opponentForfeited
          ? DuelEndReason.opponentForfeited
          : DuelEndReason.completed,
    );
  }

  static double _averageSeconds(double? averageMs, Iterable<int> fallback) {
    if (averageMs != null) return averageMs / 1000;
    final seconds = fallback.toList();
    if (seconds.isEmpty) return 0;
    return seconds.reduce((a, b) => a + b) / seconds.length;
  }

  // -------------------------------------------------------------- endings

  void _finish(DuelResult result, Emitter<LiveDuelState> emit) {
    _pendingResult = null;
    _stopTicker();
    _audio?.stopAll();
    emit(LiveDuelEnded(result));
  }

  void _abandon(String cause, Emitter<LiveDuelState> emit) {
    _pendingResult = null;
    _stopTicker();
    _audio?.stopAll();
    emit(LiveDuelAbandoned(cause, byMe: _quitRequested));
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() async {
    _stopTicker();
    await _room?.cancel();
    await _audio?.dispose();
    return super.close();
  }
}

/// Who is who in this duel, from the snapshot.
class _Cast {
  const _Cast({
    required this.mySide,
    required this.me,
    required this.opponent,
    required this.topic,
    required this.isRanked,
  });

  final DuelSide mySide;
  final DuelPlayer me;
  final DuelPlayer opponent;
  final DuelTopic topic;
  final bool isRanked;
}

/// A round the server announced (`round_start`) that this client has not
/// entered yet.
class _ScheduledRound {
  const _ScheduledRound({
    required this.round,
    required this.startsAt,
    required this.deadline,
  });

  final int round;
  final DateTime startsAt;
  final DateTime? deadline;
}
