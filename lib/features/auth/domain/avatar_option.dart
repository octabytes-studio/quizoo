import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_option.freezed.dart';
part 'avatar_option.g.dart';

/// One row of the `avatar_options` table — an avatar S-25's picker can offer.
@freezed
abstract class AvatarOption with _$AvatarOption {
  const factory AvatarOption({
    required String id,
    required String emoji,
    required int sortOrder,

    /// A Quizoo Pro-only avatar (plan 023, benefit 7). The server refuses
    /// `avatar_key` changes to one of these for a free player
    /// (`pro_avatar_required`); the picker merely shows the lock.
    @Default(false) bool isPro,
  }) = _AvatarOption;

  factory AvatarOption.fromJson(Map<String, dynamic> json) =>
      _$AvatarOptionFromJson(json);
}
