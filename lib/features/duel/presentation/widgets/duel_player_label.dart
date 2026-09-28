import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// How a [DuelPlayer] is named and badged on every duel surface (plan 017).
extension DuelPlayerLabel on DuelPlayer {
  static const Map<String, String> _leagueEmojis = {
    'bronze': '🥉',
    'silver': '🥈',
    'gold': '🥇',
    'platinum': '💎',
    'diamond': '👑',
  };

  /// The username, or "Guest {tag}" for a guest (plan 017, Decision 4).
  String displayName(AppLocalizations l10n) =>
      name ?? l10n.duelGuestName(guestTag ?? '');

  /// The league's medal emoji.
  String get leagueEmoji => _leagueEmojis[league] ?? '🥉';

  /// The league name, capitalised ("gold" → "Gold").
  String get leagueName => league.isEmpty
      ? league
      : '${league[0].toUpperCase()}${league.substring(1)}';
}
