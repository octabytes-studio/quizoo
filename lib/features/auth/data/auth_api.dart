import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';

/// The mocked identity endpoint.
///
/// Every method returns the shape a real client would, over the same
/// simulated latency and occasional failure as every other mock API (see
/// [MockApi]). Nothing here reaches a network, holds a token, or knows what
/// OAuth is — plan 002 mocks the flow deliberately, and only this file
/// changes when a real backend lands.
class AuthApi extends MockApi {
  AuthApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// Signs in through a vendor. The player arrives with a profile already
  /// filled in, which is why S-24's Google/Apple buttons never push S-25.
  Future<AuthUser> signInWithVendor(AuthProvider provider) => respond(
    () => AuthUser(
      id: 'user_${provider.name}',
      displayName: MockPlayer.name,
      provider: provider,
      email: '${MockPlayer.name.toLowerCase()}@example.com',
      countryName: MockPlayer.countries.first.$2,
      countryFlag: MockPlayer.countries.first.$1,
    ),
  );

  /// Starts the email route. The account exists but has no profile yet, so
  /// the caller is expected to send the player to S-25.
  Future<AuthUser> startEmailSignIn() => respond(
    () => const AuthUser(
      id: 'user_email',
      displayName: '',
      provider: AuthProvider.email,
      isProfileComplete: false,
    ),
  );

  /// Completes S-25.
  Future<AuthUser> createProfile({
    required String username,
    required String email,
    required String avatarEmoji,
    required String countryName,
    required String countryFlag,
  }) => respond(
    () => AuthUser(
      id: 'user_email',
      displayName: username,
      provider: AuthProvider.email,
      avatarEmoji: avatarEmoji,
      email: email,
      countryName: countryName,
      countryFlag: countryFlag,
    ),
  );

  /// The mocked live availability check on S-25's username field.
  ///
  /// A fixed denylist stands in for a real lookup, which is enough to
  /// exercise both branches of the field's UI.
  Future<bool> isUsernameAvailable(String username) => respond(
    () => !MockPlayer.takenUsernames.contains(username.toLowerCase()),
  );
}
