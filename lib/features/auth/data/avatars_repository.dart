import 'package:quizoo/features/auth/data/avatars_api.dart';
import 'package:quizoo/features/auth/domain/avatar_option.dart';

/// The only thing that talks to [AvatarsApi].
class AvatarsRepository {
  AvatarsRepository(this._api);

  final AvatarsApi _api;

  Future<List<AvatarOption>> fetchActiveAvatars() => _api.fetchActiveAvatars();
}
