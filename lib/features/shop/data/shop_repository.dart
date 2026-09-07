import 'package:quizoo/features/shop/data/shop_api.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';

/// The only thing that talks to [ShopApi].
class ShopRepository {
  ShopRepository(this._api);

  final ShopApi _api;

  Future<ShopContent> fetchShop() => _api.fetchShop();
}
