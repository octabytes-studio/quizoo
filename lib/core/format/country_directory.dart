/// The small, fixed country list S-25 offers (`MockPlayer.countries`), now
/// keyed by the `profiles.country_code` a real backend actually stores.
///
/// Kept as a pure Dart lookup rather than a query — this is UI copy, not
/// data, matching plan 006's leaderboard Design overview's own call on flag
/// formatting.
abstract final class CountryDirectory {
  static const Map<String, String> _names = {
    'PK': 'Pakistan',
    'GB': 'United Kingdom',
    'US': 'United States',
    'IN': 'India',
    'SA': 'Saudi Arabia',
    'AE': 'United Arab Emirates',
  };

  static String nameFor(String code) => _names[code.toUpperCase()] ?? code;

  /// Regional-indicator flag emoji, a pure function of any ISO-3166 alpha-2
  /// code — not limited to [_names]'s six, so a country outside the picker's
  /// fixed list (a future locale, a different signup path) still renders a
  /// flag rather than falling back to a placeholder.
  static String flagFor(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🏳️';
    const base = 0x1F1E6;
    const aCode = 0x41;
    final first = base + (upper.codeUnitAt(0) - aCode);
    final second = base + (upper.codeUnitAt(1) - aCode);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  static String? codeFor(String name) {
    for (final entry in _names.entries) {
      if (entry.value == name) return entry.key;
    }
    return null;
  }
}
