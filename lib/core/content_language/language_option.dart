import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_option.freezed.dart';
part 'language_option.g.dart';

/// One row of the `languages` table — a language the content-language
/// pickers (S-03, S-25, Edit Profile, Home's pills) can offer.
///
/// Cosmetic-only fields the table doesn't carry (flag emoji, a Latin-vs-native
/// script hint, the display quiz count) stay as small local lookups keyed by
/// [code] — `languageFlags` for the flag — not here (plan 007, Assumption #8).
@freezed
abstract class LanguageOption with _$LanguageOption {
  const factory LanguageOption({
    required String code,
    required String name,
    required String nativeName,
    required bool isRtl,
    required int sortOrder,
  }) = _LanguageOption;

  factory LanguageOption.fromJson(Map<String, dynamic> json) =>
      _$LanguageOptionFromJson(json);
}
