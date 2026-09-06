import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// How a player signed in.
///
/// The bible offers exactly three routes (S-24) and the profile screen needs
/// to know which one it came from, because a vendor sign-in already carries a
/// display name while email does not.
enum AuthProvider {
  /// Continue with Google.
  google,

  /// Continue with Apple.
  apple,

  /// Continue with Email — the only route that pushes S-25.
  email,
}

/// A signed-in player.
///
/// Mocked end to end in this phase: there is no token, no refresh, no network
/// call. Only the shape is real, so the screens above it are written against
/// the model a real client would hand them (plan 002, Scope).
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String displayName,
    required AuthProvider provider,

    /// The avatar the player picked on S-25, or the mascot they start with.
    @Default('🐼') String avatarEmoji,
    String? email,
    String? countryName,
    String? countryFlag,

    /// False until the player has been through S-25. A vendor sign-in skips
    /// it, so most users are complete the moment they arrive.
    @Default(true) bool isProfileComplete,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
