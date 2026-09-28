import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_room_event.dart';

part 'duel_rematch_state.dart';

/// S-41's rematch handshake for a finished live duel (plan 017, Phase 11).
///
/// A rematch needs both players to ask: the first `request_duel_rematch`
/// leaves this side [RematchWaiting] and tells the opponent through the room
/// channel ([RematchOffered] on their side); the second creates the new duel
/// ([RematchStarting]). The new duel's id arrives from whichever lands first —
/// the RPC's own response, the room's `rematch {status: started}`, or the
/// inbox's `duel_start`.
///
/// Everything expires after [window] (the server enforces the same
/// `rematch_window`), and leaving the screen ([close]) tells the opponent
/// this side has gone.
class DuelRematchCubit extends Cubit<DuelRematchState> {
  DuelRematchCubit(
    this._repository, {
    required this.duelId,
    required this.opponent,
    required Duration window,
  }) : super(const RematchIdle()) {
    _roomSubscription = _repository.roomEvents(duelId).listen(_onRoomEvent);
    _startsSubscription = _repository.duelStarts().listen(_onStarted);
    _windowTimer = Timer(window, _onWindowClosed);
  }

  final LiveDuelRepository _repository;

  /// The finished duel the rematch is asked for.
  final String duelId;

  /// Who the rematch would be against — only their requests count as an
  /// offer.
  final DuelPlayer opponent;

  StreamSubscription<DuelRoomEvent>? _roomSubscription;
  StreamSubscription<String>? _startsSubscription;
  Timer? _windowTimer;
  bool _requesting = false;

  /// Asks for a rematch — or, when the opponent already asked, starts it.
  Future<void> request() async {
    final current = state;
    final canAsk = switch (current) {
      RematchIdle() || RematchOffered() => true,
      RematchWaiting() || RematchStarting() || RematchUnavailable() => false,
    };
    if (!canAsk || _requesting) return;

    _requesting = true;
    try {
      final response = await _repository.requestRematch(duelId);
      if (isClosed || state is RematchStarting) return;
      final newDuelId = response.duelId;
      switch (response.status) {
        case RematchStatus.started when newDuelId != null:
          _start(newDuelId);
        case RematchStatus.started || RematchStatus.requested:
          // An opponent's decline or the window can land while the request
          // is in flight; those win.
          if (state is! RematchUnavailable) emit(const RematchWaiting());
        case RematchStatus.declined:
          _makeUnavailable();
      }
    } on ApiException {
      // `rematch_unavailable` (the window closed, the opponent is already
      // in another duel) or a transport failure — either way there is
      // nothing left to wait for.
      if (!isClosed) _makeUnavailable();
    } finally {
      _requesting = false;
    }
  }

  /// Accepts the opponent's offer — the same call as asking, which the
  /// server turns into a new duel because both sides have now asked.
  Future<void> accept() => request();

  void _onRoomEvent(DuelRoomEvent event) {
    if (event is! RematchUpdate) return;
    switch (event.status) {
      case RematchStatus.requested:
        if (event.requestedBy == opponent.id && state is RematchIdle) {
          emit(const RematchOffered());
        }
      case RematchStatus.declined:
        _makeUnavailable();
      case RematchStatus.started:
        final newDuelId = event.duelId;
        if (newDuelId != null) _start(newDuelId);
    }
  }

  void _onStarted(String newDuelId) {
    // The inbox's `duel_start` for the rematch; ignore the finished duel's
    // own echo, if one arrives late.
    if (newDuelId != duelId) _start(newDuelId);
  }

  void _onWindowClosed() => _makeUnavailable();

  void _start(String newDuelId) {
    if (isClosed || state is RematchStarting) return;
    _windowTimer?.cancel();
    emit(RematchStarting(newDuelId));
  }

  /// Anything but a started rematch becomes unavailable.
  void _makeUnavailable() {
    if (isClosed || state is RematchStarting) return;
    _windowTimer?.cancel();
    emit(const RematchUnavailable());
  }

  /// Leaving the result screen declines — fire-and-forget, so the opponent's
  /// button flips to "{name} has left" — unless the rematch already started.
  @override
  Future<void> close() {
    _windowTimer?.cancel();
    unawaited(_roomSubscription?.cancel());
    unawaited(_startsSubscription?.cancel());
    if (state is! RematchStarting) {
      _repository.declineRematch(duelId).ignore();
    }
    return super.close();
  }
}
