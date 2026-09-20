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
  }) = _AvatarOption;

  factory AvatarOption.fromJson(Map<String, dynamic> json) =>
      _$AvatarOptionFromJson(json);
}
