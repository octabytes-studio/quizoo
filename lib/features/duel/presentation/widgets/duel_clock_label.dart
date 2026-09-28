import 'package:intl/intl.dart';
import 'package:quizoo/core/format/app_format.dart';

/// How the arena prints a countdown (plan 017): "4:12" for a challenge's
/// time left or the creation cool-off, whole seconds for the short ones.
///
/// Both round **up**, so a countdown never reads "0:00" or "0s" while time
/// actually remains. Locale-aware digits, like every other number
/// ([AppFormat]).
extension DuelClockLabel on Duration {
  /// Whole seconds left, rounded up.
  int get secondsUp {
    if (this <= Duration.zero) return 0;
    return (inMilliseconds / Duration.millisecondsPerSecond).ceil();
  }

  /// "m:ss" — minutes, then zero-padded seconds.
  String clockLabel(String localeName) {
    final total = secondsUp;
    final minutes = total ~/ Duration.secondsPerMinute;
    final seconds = total % Duration.secondsPerMinute;
    return '${AppFormat.plain(minutes, localeName)}:'
        '${NumberFormat('00', localeName).format(seconds)}';
  }
}
