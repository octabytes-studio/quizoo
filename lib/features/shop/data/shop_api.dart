import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/shop/domain/coin_pack.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real shop endpoint — coins/gems/free-ad count come from Postgres;
/// [CoinPack]'s catalogue is still a fixed list, not yet read from Firebase
/// Remote Config (plan 006's Design overview calls for `coin_pack_ids` +
/// `in_app_purchase`'s live store pricing) — wiring a real purchase flow
/// needs `in_app_purchase` added, a `verify-purchase` Edge Function deployed,
/// and testing against a real store sandbox on a physical device, none of
/// which this pass can do or verify. [inventory] is left on the same fixed
/// `MockPlayer` counts the mock always used, for the same reason plan 006's
/// power-up-as-wallet-currency migration is not applied here: `quiz_play`'s
/// own Cubit still spends power-ups as pure client-side, per-run state with
/// no wallet round trip at all — wiring a real inventory here without also
/// changing `QuizPlayCubit` to spend against it would just make the two
/// disagree. Both are flagged, unresolved follow-ups, not silent gaps.
class ShopApi {
  ShopApi(this._client);

  final SupabaseClient _client;

  static const int _freeAdsPerDay = 3;
  static const int _freeCoinsReward = 50;

  static const List<CoinPack> _coinPacks = [
    CoinPack(id: 'pack_small', coins: 500, priceLabel: '\$0.99'),
    CoinPack(
      id: 'pack_medium',
      coins: 2800,
      priceLabel: '\$4.99',
      bonusPercent: 20,
      isHighlighted: true,
    ),
    CoinPack(
      id: 'pack_large',
      coins: 6500,
      priceLabel: '\$9.99',
      bonusPercent: 50,
    ),
  ];

  Future<ShopContent> fetchShop() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ApiException(
          'Not signed in',
          kind: ApiErrorKind.unauthorized,
        );
      }

      final profileRow = await _client
          .from('profiles')
          .select('coins, gems')
          .eq('id', userId)
          .single();

      final todayStart = DateTime.now().toUtc();
      final adRows = await _client
          .from('wallet_ledger')
          .select('id')
          .eq('user_id', userId)
          .eq('reason', 'ad_reward')
          .gte(
            'created_at',
            DateTime.utc(
              todayStart.year,
              todayStart.month,
              todayStart.day,
            ).toIso8601String(),
          );

      return ShopContent(
        coins: profileRow['coins'] as int,
        gems: profileRow['gems'] as int,
        freeAdsWatchedToday: adRows.length,
        freeAdsPerDay: _freeAdsPerDay,
        freeCoinsReward: _freeCoinsReward,
        inventory: const PowerUpInventory(
          fiftyFifty: MockPlayer.fiftyFiftyCount,
          addTime: MockPlayer.addTimeCount,
          skip: MockPlayer.skipCount,
        ),
        coinPacks: _coinPacks,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }
}
