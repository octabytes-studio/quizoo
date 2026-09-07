import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/shop/data/shop_repository.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';

part 'shop_state.dart';

/// Owns S-36's wallet, power-up inventory and coin-pack list.
///
/// Purchases resolve synchronously and return whether they succeeded, so the
/// screen can show its own snackbar off the result rather than the cubit
/// reaching for `AppSnackbar` itself (CLAUDE.md §3: a Cubit is pure Dart, no
/// widget imports).
class ShopCubit extends Cubit<ShopState> {
  ShopCubit(this._repository) : super(const ShopInitial());

  final ShopRepository _repository;

  Future<void> load() async {
    emit(const ShopLoading());
    try {
      emit(ShopLoaded(content: await _repository.fetchShop()));
    } on ApiException catch (error) {
      emit(ShopError(error));
    }
  }

  /// Buys one [powerUp]. False (and no state change) when the wallet can't
  /// cover it — a "not enough coins/gems" toast is the caller's job.
  bool buyPowerUp(PowerUp powerUp) {
    final current = state;
    if (current is! ShopLoaded) return false;
    final content = current.content;

    final coinsCost = powerUp.costCoins;
    if (coinsCost != null) {
      if (content.coins < coinsCost) return false;
      emit(
        ShopLoaded(
          content: content.copyWith(
            coins: content.coins - coinsCost,
            inventory: content.inventory.grant(powerUp),
          ),
        ),
      );
      return true;
    }

    final gemsCost = powerUp.costGems;
    if (gemsCost != null) {
      if (content.gems < gemsCost) return false;
      emit(
        ShopLoaded(
          content: content.copyWith(
            gems: content.gems - gemsCost,
            inventory: content.inventory.grant(powerUp),
          ),
        ),
      );
      return true;
    }
    return false;
  }

  /// S-37's payout, applied once the rewarded-ad dialog reports success.
  void creditRewardedAd(int coins) {
    final current = state;
    if (current is! ShopLoaded) return;
    emit(
      ShopLoaded(
        content: current.content.copyWith(
          coins: current.content.coins + coins,
          freeAdsWatchedToday: current.content.freeAdsWatchedToday + 1,
        ),
      ),
    );
  }
}
