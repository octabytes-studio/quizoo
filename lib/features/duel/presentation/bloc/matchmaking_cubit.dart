import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/data/matchmaking_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/matchmaking_ticket.dart';

part 'matchmaking_state.dart';

/// S-39 — quick match in one topic (plan 017, Phase 9).
///
/// [start] joins the server queue, then three things run until the player
/// is paired or gives up:
/// - a **1 s ticker** that recomputes the elapsed time (from the server's
///   `queuedAt` via the shared [ServerClock]) and the band-widen countdown;
/// - a **heartbeat** every `config.mmHeartbeatSeconds`, counted by that same
///   ticker. It keeps the queue row fresh, lets the server retry pairing with
///   the widened band, and brings back the new band and `botAvailable`. A
///   failed heartbeat is retried on the very next tick. `not_in_queue`
///   re-joins once;
/// - a `duelStarts()` subscription, so a pairing made by *another* player's
///   heartbeat lands immediately instead of on our next heartbeat.
///
/// After `config.botAfterSeconds` the server offers the labelled practice
/// bot. [playBot] takes it, and [keepSearching] snoozes the offer for another
/// `botAfterSeconds` while the search goes on underneath.
///
/// Leaving the queue: [cancel] (the ✕) leaves explicitly. [close] leaves
/// fire-and-forget unless the queue row is already gone: after
/// [MatchmakingFound] the server removed it when it created the duel, and
/// after [MatchmakingBotReady] [playBot] already left.
class MatchmakingCubit extends Cubit<MatchmakingState> {
  MatchmakingCubit(
    this._repository,
    this._botRepository,
    this._clock, {
    required this.topic,
    this.config = DuelConfig.fallback,
  }) : super(const MatchmakingJoining());

  final MatchmakingRepository _repository;
  final DuelRepository _botRepository;
  final ServerClock _clock;

  /// The topic the player picked. The server's own copy (on the ticket) is
  /// what [MatchmakingSearching.topic] shows once queued.
  final DuelTopic topic;

  /// Supplies `mmHeartbeatSeconds`, `botAfterSeconds` and `bandStepSeconds`.
  final DuelConfig config;

  /// `matchmaking_heartbeat`'s error when the queue row is gone.
  static const String notInQueueCode = 'not_in_queue';

  Timer? _ticker;
  StreamSubscription<String>? _duelStarts;

  /// The latest queued ticket (from `join` or a heartbeat).
  MatchmakingQueued? _ticket;

  int _secondsSinceHeartbeat = 0;
  bool _heartbeatInFlight = false;
  bool _retryHeartbeat = false;

  /// Set once a `not_in_queue` re-join has been tried; cleared by the next
  /// successful heartbeat. A second `not_in_queue` before then means
  /// something is really wrong, so the search fails instead of looping.
  bool _rejoinAttempted = false;

  /// [playBot] is in flight — heartbeats pause so they can't re-join the
  /// queue it just left.
  bool _startingBot = false;

  /// Elapsed second until which "Keep searching" hides the bot offer.
  int? _botOfferSnoozedUntil;

  /// True once [cancel] or [playBot] has left the queue (or [close] has
  /// started to), so it's never left twice.
  bool _hasLeft = false;

  /// Joins the queue and starts the ticker, heartbeat and inbox listener.
  /// Also the retry from [MatchmakingFailed].
  Future<void> start() async {
    if (state is! MatchmakingJoining && state is! MatchmakingFailed) return;
    _duelStarts ??= _repository.duelStarts().listen(
      _onDuelStarted,
      // A dropped inbox isn't fatal — the heartbeat still reports a pairing.
      onError: (Object _) {},
    );
    if (state is MatchmakingFailed) emit(const MatchmakingJoining());
    _hasLeft = false;
    try {
      final ticket = await _repository.join(topic.id);
      if (isClosed) {
        // Closed while joining: the join still landed, so undo it.
        if (ticket is MatchmakingQueued) unawaited(_leaveQuietly());
        return;
      }
      if (state is! MatchmakingJoining) return; // a duel_start beat us.
      _applyTicket(ticket);
    } on ApiException catch (error) {
      if (isClosed || state is! MatchmakingJoining) return;
      emit(MatchmakingFailed(error));
    }
  }

  /// Takes the labelled practice bot: leaves the queue, then fetches a bot
  /// near the player's ELO.
  ///
  /// On an [ApiException] the player stays searching. If the bot fetch
  /// failed after the queue was already left, the next tick's heartbeat hits
  /// `not_in_queue` and re-joins.
  Future<void> playBot() async {
    final current = state;
    if (current is! MatchmakingSearching || _startingBot) return;
    _startingBot = true;
    _emitSearching();
    try {
      await _repository.leave();
      _hasLeft = true;
      final opponent = await _botRepository.fetchBotOpponent(
        playerElo: current.me.elo,
      );
      if (isClosed) return;
      final latest = state;
      // A real opponent's duel_start won the race — that duel exists now.
      if (latest is! MatchmakingSearching) return;
      _stop();
      emit(
        MatchmakingBotReady(
          me: latest.me,
          // Never a secret bot (bible §14), whatever the server sent.
          opponent: opponent.copyWith(isBot: true),
          topic: latest.topic,
        ),
      );
    } on ApiException {
      if (isClosed) return;
      _startingBot = false;
      if (state is! MatchmakingSearching) return;
      if (_hasLeft) {
        // Left on purpose, so this is a fresh re-join, not a repeat one.
        _hasLeft = false;
        _rejoinAttempted = false;
        _retryHeartbeat = true;
      }
      _emitSearching();
    }
  }

  /// Hides the bot offer for another `config.botAfterSeconds`.
  void keepSearching() {
    final current = state;
    if (current is! MatchmakingSearching || !current.showBotOffer) return;
    _botOfferSnoozedUntil = current.elapsedSeconds + config.botAfterSeconds;
    _emitSearching();
  }

  /// The ✕: stops everything and leaves the queue.
  Future<void> cancel() async {
    _stop();
    if (!_shouldLeave) return;
    _hasLeft = true;
    await _leaveQuietly();
  }

  @override
  Future<void> close() {
    _stop();
    if (_shouldLeave) {
      _hasLeft = true;
      unawaited(_leaveQuietly());
    }
    return super.close();
  }

  // ---------------------------------------------------------------- internals

  /// Found: the server deleted the queue row in `_duel_create`. BotReady:
  /// [playBot] already left. Either way a leave would be a pointless no-op.
  bool get _shouldLeave =>
      !_hasLeft && state is! MatchmakingFound && state is! MatchmakingBotReady;

  /// Still searching, and nothing else (a bot start, a close) owns the
  /// outcome.
  bool get _isSearchingLive =>
      !isClosed && !_startingBot && state is MatchmakingSearching;

  void _applyTicket(MatchmakingTicket ticket) {
    switch (ticket) {
      case MatchmakingMatched(:final duelId):
        _found(duelId);
      case final MatchmakingQueued queued:
        // A re-join starts a new wait, so an old snooze no longer applies.
        if (_ticket != null && _ticket!.queuedAt != queued.queuedAt) {
          _botOfferSnoozedUntil = null;
        }
        _ticket = queued;
        _ticker ??= Timer.periodic(
          const Duration(seconds: 1),
          (_) => _onTick(),
        );
        _emitSearching();
    }
  }

  void _onTick() {
    if (isClosed || state is! MatchmakingSearching) return;
    _emitSearching();
    if (_startingBot) return;
    _secondsSinceHeartbeat++;
    if (_retryHeartbeat ||
        _secondsSinceHeartbeat >= max(1, config.mmHeartbeatSeconds)) {
      unawaited(_heartbeat());
    }
  }

  Future<void> _heartbeat() async {
    if (_heartbeatInFlight) return;
    _heartbeatInFlight = true;
    _secondsSinceHeartbeat = 0;
    _retryHeartbeat = false;
    try {
      final ticket = await _repository.heartbeat();
      if (!_isSearchingLive) return;
      _rejoinAttempted = false;
      _applyTicket(ticket);
    } on ApiException catch (error) {
      if (!_isSearchingLive) return;
      if (error.code == notInQueueCode) {
        await _rejoin(error);
      } else {
        // Network blip or server hiccup: keep searching, try next tick.
        _retryHeartbeat = true;
      }
    } finally {
      _heartbeatInFlight = false;
    }
  }

  Future<void> _rejoin(ApiException notInQueue) async {
    if (_rejoinAttempted) {
      _fail(notInQueue);
      return;
    }
    _rejoinAttempted = true;
    try {
      final ticket = await _repository.join(topic.id);
      if (isClosed) {
        if (ticket is MatchmakingQueued) unawaited(_leaveQuietly());
        return;
      }
      if (!_isSearchingLive) return;
      _applyTicket(ticket);
    } on ApiException catch (error) {
      if (!_isSearchingLive) return;
      _fail(error);
    }
  }

  void _onDuelStarted(String duelId) {
    if (isClosed) return;
    _found(duelId);
  }

  void _found(String duelId) {
    if (state is MatchmakingFound || state is MatchmakingBotReady) return;
    _stop();
    emit(MatchmakingFound(duelId));
  }

  void _fail(ApiException error) {
    _stopTicker();
    emit(MatchmakingFailed(error));
  }

  void _emitSearching() {
    final ticket = _ticket;
    if (ticket == null || isClosed) return;
    final now = _clock.now();
    final elapsed = max(0, now.difference(ticket.queuedAt).inSeconds);
    final step = config.bandStepSeconds;
    final botAvailableAt = ticket.botAvailableAt;
    emit(
      MatchmakingSearching(
        me: ticket.me,
        topic: ticket.topic,
        elapsedSeconds: elapsed,
        bandMin: ticket.bandMin,
        bandMax: ticket.bandMax,
        secondsToNextWiden: step > 0 ? step - elapsed % step : 0,
        // The server's flag, or its own "available from" instant passing
        // between heartbeats — so the offer appears on time, not up to one
        // heartbeat late.
        botAvailable:
            ticket.botAvailable ||
            (botAvailableAt != null && !now.isBefore(botAvailableAt)),
        botOfferSnoozedUntil: _botOfferSnoozedUntil,
        isStartingBot: _startingBot,
      ),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _stop() {
    _stopTicker();
    final subscription = _duelStarts;
    _duelStarts = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  Future<void> _leaveQuietly() async {
    try {
      await _repository.leave();
    } on ApiException {
      // The sweeper drops stale queue rows (12 s without a heartbeat).
    }
  }
}
