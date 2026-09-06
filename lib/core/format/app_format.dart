import 'package:intl/intl.dart';

/// Locale-aware formatting for the numbers and clock times the bible prints
/// as part of its copy.
///
/// Two rules from the design bible drive this:
///
/// * **Numerals switch to Eastern Arabic under Urdu** (§16, S-16). That is
///   `NumberFormat`'s job, not a manual digit-substitution table, so a score
///   reads `1,340` in English and `۱٬۳۴۰` in Urdu from the same call.
/// * **Refill times are stated as a clock time, not a relative countdown**
///   (§09, S-19) — "the next one lands at 10:14" stays true if the app is
///   backgrounded, where "in 28 minutes" silently rots.
abstract final class AppFormat {
  /// A grouped integer — score, points, coins, XP.
  static String number(int value, String localeName) =>
      NumberFormat.decimalPattern(localeName).format(value);

  /// A bare integer with no grouping — a question index, a level number, a
  /// heart count. Still locale-aware, so Urdu gets Eastern Arabic digits.
  static String plain(int value, String localeName) =>
      NumberFormat('0', localeName).format(value);

  /// A compact play count — `84.2k`, `1.3M`.
  static String compact(int value, String localeName) =>
      NumberFormat.compact(locale: localeName).format(value);

  /// A wall-clock time, for S-19's heart-refill line.
  static String clock(DateTime value, String localeName) =>
      DateFormat.jm(localeName).format(value);

  /// A coarse "4h 12m" duration, for the daily challenge's remaining window.
  static String remaining(Duration value, String localeName) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '${plain(minutes, localeName)}m';
    return '${plain(hours, localeName)}h ${plain(minutes, localeName)}m';
  }

  /// A multiplier printed to one decimal — `1.5`, `1.55`.
  static String multiplier(double value, String localeName) =>
      NumberFormat('0.##', localeName).format(value);
}
