import 'package:country_picker/country_picker.dart';

/// S-25's country lookups, keyed by the `profiles.country_code` a real
/// backend actually stores.
///
/// Backed by `country_picker`'s bundled ISO-3166 dataset rather than a
/// hand-typed list, since S-25's picker now offers every country, not a
/// fixed handful (plan 015) — every other avatar-rendering surface
/// (leaderboard, profile) that resolves a stored `country_code` back to a
/// name still goes through this one lookup, so widening the picker needed no
/// change anywhere else.
abstract final class CountryDirectory {
  static final CountryService _service = CountryService();

  static String nameFor(String code) => _service.findByCode(code)?.name ?? code;

  /// Regional-indicator flag emoji, a pure function of any ISO-3166 alpha-2
  /// code — not a dataset lookup, so a code the dataset doesn't recognise
  /// still renders a flag rather than falling back to a placeholder.
  static String flagFor(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🏳️';
    const base = 0x1F1E6;
    const aCode = 0x41;
    final first = base + (upper.codeUnitAt(0) - aCode);
    final second = base + (upper.codeUnitAt(1) - aCode);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
