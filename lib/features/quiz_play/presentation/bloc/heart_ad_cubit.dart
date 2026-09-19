import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/features/quiz_play/data/rewarded_ad_service.dart';

part 'heart_ad_state.dart';

/// Owns S-19's "watch an ad for 1 ❤️" button.
///
/// Nothing loads until the player taps — [watch] is the one entry point,
/// and it does the whole load→show round trip: ready → loading → (playing →
/// succeeded) or straight to failed if the load itself fails. `QuizPlayCubit`
/// never knows an ad is in flight — it only learns the outcome via
/// `grantHeartFromAd()`, called by the dialog on [HeartAdSucceeded].
class HeartAdCubit extends Cubit<HeartAdState> {
  HeartAdCubit(this._service) : super(const HeartAdReady());

  final RewardedAdService _service;

  /// Valid from [HeartAdReady] or [HeartAdFailed] — tapping "Watch ad" again
  /// after a failure retries from scratch rather than needing a separate
  /// retry action, so the button is never permanently dead.
  Future<void> watch() async {
    if (state is! HeartAdReady && state is! HeartAdFailed) return;

    emit(const HeartAdLoading());
    final loaded = await _service.load();
    if (isClosed) return;
    if (!loaded) {
      emit(const HeartAdFailed());
      return;
    }

    emit(const HeartAdPlaying());
    final earned = await _service.show();
    if (isClosed) return;
    emit(earned ? const HeartAdSucceeded() : const HeartAdFailed());
  }

  @override
  Future<void> close() {
    unawaited(_service.dispose());
    return super.close();
  }
}
