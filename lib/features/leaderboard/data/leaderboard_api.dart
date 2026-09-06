import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/features/leaderboard/domain/friend.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_scope.dart';
import 'package:quizoo/features/leaderboard/domain/league_standing.dart';

/// One fixture player's scores across every period, so switching Week/Month/
/// All-time re-slices *this* roster rather than hitting a fresh query.
class _RosterPlayer {
  const _RosterPlayer({
    required this.id,
    required this.name,
    required this.emoji,
    required this.location,
    required this.isFriend,
    required this.week,
    required this.month,
    required this.allTime,
  });

  final String id;
  final String name;
  final String emoji;

  /// "🇵🇰 Lahore" — flag plus city.
  final String location;
  final bool isFriend;
  final int week;
  final int month;
  final int allTime;

  int scoreFor(LeaderboardPeriod period) => switch (period) {
    LeaderboardPeriod.week => week,
    LeaderboardPeriod.month => month,
    LeaderboardPeriod.allTime => allTime,
  };

  bool get isPakistan => location.startsWith('🇵🇰');
}

/// The mocked leaderboard, league and friends endpoints.
class LeaderboardApi extends MockApi {
  LeaderboardApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  static const List<_RosterPlayer> _roster = [
    _RosterPlayer(
      id: 'p_danish',
      name: 'Danish M.',
      emoji: '🐯',
      location: '🇵🇰 Karachi',
      isFriend: true,
      week: 168000,
      month: 612000,
      allTime: 2840000,
    ),
    _RosterPlayer(
      id: 'p_ayesha',
      name: 'Ayesha K.',
      emoji: '🦊',
      location: '🇵🇰 Lahore',
      isFriend: true,
      week: 142000,
      month: 705000,
      allTime: 3120000,
    ),
    _RosterPlayer(
      id: 'p_zara',
      name: 'Zara N.',
      emoji: '🐨',
      location: '🇮🇳 Delhi',
      isFriend: true,
      week: 131000,
      month: 588000,
      allTime: 2510000,
    ),
    _RosterPlayer(
      id: 'p_hamza',
      name: 'Hamza A.',
      emoji: '🐸',
      location: '🇵🇰 Lahore',
      isFriend: false,
      week: 128400,
      month: 402000,
      allTime: 1980000,
    ),
    _RosterPlayer(
      id: 'p_sara',
      name: 'Sara V.',
      emoji: '🦉',
      location: '🇮🇳 Mumbai',
      isFriend: false,
      week: 124910,
      month: 560000,
      allTime: 2960000,
    ),
    _RosterPlayer(
      id: 'p_omar',
      name: 'Omar F.',
      emoji: '🐧',
      location: '🇦🇪 Dubai',
      isFriend: false,
      week: 121300,
      month: 300000,
      allTime: 1400000,
    ),
    _RosterPlayer(
      id: 'p_lucia',
      name: 'Lucia R.',
      emoji: '🐢',
      location: '🇪🇸 Madrid',
      isFriend: false,
      week: 119880,
      month: 275000,
      allTime: 1120000,
    ),
    _RosterPlayer(
      id: 'p_bilal',
      name: 'Bilal R.',
      emoji: '🐯',
      location: '🇵🇰 Islamabad',
      isFriend: false,
      week: 98200,
      month: 340000,
      allTime: 1560000,
    ),
    _RosterPlayer(
      id: 'p_hina',
      name: 'Hina S.',
      emoji: '🐰',
      location: '🇵🇰 Karachi',
      isFriend: false,
      week: 91200,
      month: 410000,
      allTime: 2100000,
    ),
    _RosterPlayer(
      id: 'p_faisal',
      name: 'Faisal T.',
      emoji: '🦁',
      location: '🇵🇰 Lahore',
      isFriend: false,
      week: 76500,
      month: 210000,
      allTime: 980000,
    ),
  ];

  /// Rank / score / "Top N%" for the player's own row, per scope × period —
  /// this small fixture roster cannot itself simulate a 400-player field, so
  /// the self row's numbers are looked up rather than computed from it.
  static const Map<LeaderboardScope, Map<LeaderboardPeriod, (int, int, int)>>
  _selfStats = {
    LeaderboardScope.global: {
      LeaderboardPeriod.week: (412, 18420, 3),
      LeaderboardPeriod.month: (1204, 61000, 4),
      LeaderboardPeriod.allTime: (8830, 268000, 6),
    },
    LeaderboardScope.country: {
      LeaderboardPeriod.week: (89, 18420, 5),
      LeaderboardPeriod.month: (240, 61000, 6),
      LeaderboardPeriod.allTime: (1650, 268000, 8),
    },
    LeaderboardScope.friends: {
      LeaderboardPeriod.week: (4, 18420, 100),
      LeaderboardPeriod.month: (3, 61000, 75),
      LeaderboardPeriod.allTime: (4, 268000, 100),
    },
  };

  Future<List<LeaderboardEntry>> fetchRoster({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) => respond(() {
    final filtered =
        _roster.where((player) {
            return switch (scope) {
              LeaderboardScope.global => true,
              LeaderboardScope.country => player.isPakistan,
              LeaderboardScope.friends => player.isFriend,
            };
          }).toList()
          ..sort((a, b) => b.scoreFor(period).compareTo(a.scoreFor(period)));

    return [
      for (final (index, player) in filtered.indexed)
        LeaderboardEntry(
          rank: index + 1,
          playerId: player.id,
          name: player.name,
          avatarEmoji: player.emoji,
          score: player.scoreFor(period),
          locationLabel: player.location,
          rankDelta: _rankDeltaFor(index, period),
        ),
    ];
  });

  Future<LeaderboardEntry> fetchSelfEntry({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) => respond(() {
    final (rank, score, topPercent) = _selfStats[scope]![period]!;
    return LeaderboardEntry(
      rank: rank,
      playerId: 'self',
      name: 'You',
      avatarEmoji: '🐼',
      score: score,
      locationLabel: '🇵🇰 Islamabad',
      rankDelta: 27,
      isSelf: true,
      topPercent: topPercent,
    );
  });

  static const List<(String, String, String, int, int, int)> _categoryRoster = [
    ('p_danish', 'Danish M.', '🐯', 32400, 20, 58),
    ('p_ayesha', 'Ayesha K.', '🦊', 31120, 20, 55),
    ('p_zara', 'Zara N.', '🐨', 29880, 19, 52),
    ('p_omar', 'Omar F.', '🐧', 27410, 18, 49),
  ];

  Future<List<LeaderboardEntry>> fetchCategoryRoster(String subcategoryId) =>
      respond(() {
        final subcategory = _subcategoryOrFallback(subcategoryId);
        return [
          for (final (index, row) in _categoryRoster.indexed)
            LeaderboardEntry(
              rank: index + 1,
              playerId: row.$1,
              name: row.$2,
              avatarEmoji: row.$3,
              score: row.$4,
              levelsCleared: row.$5,
              levelCount: subcategory.levelCount,
              starsEarned: row.$6,
            ),
        ];
      });

  /// "You're #{rank} in {country}" + "{points} points from the top 10".
  Future<(int, int, String)> fetchCategoryHeader(String subcategoryId) =>
      respond(() => (12, 1240, 'Pakistan'));

  static const List<Friend> _friends = [
    Friend(
      id: 'p_hina',
      name: 'Hina S.',
      avatarEmoji: '🐰',
      status: FriendStatus.pending,
      subtitle: 'Level 22 · Gold League',
    ),
    Friend(
      id: 'p_danish',
      name: 'Danish M.',
      avatarEmoji: '🐯',
      status: FriendStatus.online,
      subtitle: '🟢 Playing Cricket now',
    ),
    Friend(
      id: 'p_ayesha',
      name: 'Ayesha K.',
      avatarEmoji: '🦊',
      status: FriendStatus.offline,
      subtitle: 'Last seen 2h ago · 142k pts',
    ),
    Friend(
      id: 'p_zara',
      name: 'Zara N.',
      avatarEmoji: '🐨',
      status: FriendStatus.offline,
      subtitle: 'Last seen yesterday · 131k pts',
    ),
  ];

  Future<List<Friend>> fetchFriends() => respond(() => _friends);

  static const List<(String, String, String, int)> _leagueNeighbors = [
    ('p_ayesha', 'Ayesha K.', '🦊', 9120),
    ('self', 'You', '🐼', 8980),
    ('p_bilal', 'Bilal R.', '🐯', 8740),
  ];

  Future<List<LeagueStanding>> fetchLeagueNeighbors() => respond(
    () => [
      for (final (index, row) in _leagueNeighbors.indexed)
        LeagueStanding(
          rank: 28 + index,
          playerId: row.$1,
          name: row.$2,
          avatarEmoji: row.$3,
          points: row.$4,
          isSelf: row.$1 == 'self',
        ),
    ],
  );

  /// A small, deterministic ▲/▼/— spread so the list does not read as every
  /// row climbing or every row falling.
  static int _rankDeltaFor(int index, LeaderboardPeriod period) {
    final seed = (index * 7 + period.index * 3) % 5;
    return seed - 2;
  }

  static Subcategory _subcategoryOrFallback(String id) {
    try {
      return MockCatalog.subcategoryById(id);
    } on StateError {
      return MockCatalog.subcategoryById(MockCatalog.footballId);
    }
  }
}
