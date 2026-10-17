import 'package:quizoo/core/format/country_directory.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/domain/friend.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_scope.dart';
import 'package:quizoo/features/leaderboard/domain/league_standing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real leaderboard, league and friends endpoints.
///
/// Global/country boards read `lb_{period}_totals` (one real per-player
/// total, added in `20260908090000_leaderboard_totals.sql` — the functions
/// migration's own `lb_weekly`/`lb_monthly`/`lb_alltime` group by
/// `(user, subcategory, category, country)`, the right grain for the
/// category board but not for a genuine global total). The friends board has
/// no materialized view at all (plan 006, Design overview) — a friends list
/// is small enough to aggregate live.
/// What one `profiles` row contributes to a leaderboard, league or friends
/// row (plan 023, 6.8).
typedef _ProfileRow = ({
  String name,
  String avatar,
  String? location,
  bool isPro,
});

class LeaderboardApi {
  LeaderboardApi(this._client);

  final SupabaseClient _client;

  static const int _rosterLimit = 50;

  /// Drops every entry whose player the viewer has blocked (plan 025) —
  /// applied to the global/country, category and friends rosters alike, so a
  /// blocked player is invisible on every board their blocker can open.
  /// Pure and public so the filter is unit-testable without a Supabase mock.
  static List<LeaderboardEntry> withoutBlocked(
    List<LeaderboardEntry> entries,
    Set<String> blockedIds,
  ) => [
    for (final entry in entries)
      if (!blockedIds.contains(entry.playerId)) entry,
  ];

  String _viewFor(LeaderboardPeriod period) => switch (period) {
    LeaderboardPeriod.week => 'lb_weekly_totals',
    LeaderboardPeriod.month => 'lb_monthly_totals',
    LeaderboardPeriod.allTime => 'lb_alltime_totals',
  };

  Future<List<LeaderboardEntry>> fetchRoster({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) async {
    try {
      if (scope == LeaderboardScope.friends) {
        return _friendsRoster(period);
      }

      final userId = _client.auth.currentUser?.id;
      var query = _client
          .from(_viewFor(period))
          .select('user_id, country_code, points, rank_global, rank_country');

      if (scope == LeaderboardScope.country) {
        final myCountry = userId == null
            ? null
            : (await _client
                      .from('profiles')
                      .select('country_code')
                      .eq('id', userId)
                      .maybeSingle())?['country_code']
                  as String?;
        if (myCountry == null) return const [];
        query = query.eq('country_code', myCountry);
      }

      final rows = await query
          .order(
            scope == LeaderboardScope.country ? 'rank_country' : 'rank_global',
            ascending: true,
          )
          .limit(_rosterLimit);

      final profiles = await _profilesFor([
        for (final row in rows) row['user_id'] as String,
      ]);
      // Plan 025: a blocked player is hidden from the blocker's board. The
      // filter runs after the server's limit, so a blocked player in the top
      // 50 simply leaves one fewer row rather than pulling #51 in.
      final blocked = await _blockedIds();

      return withoutBlocked([
        for (final row in rows)
          _entryFromTotalsRow(
            row,
            scope: scope,
            profile: profiles[row['user_id']],
            selfId: userId,
          ),
      ], blocked);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<LeaderboardEntry> fetchSelfEntry({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ApiException(
          'Not signed in',
          kind: ApiErrorKind.unauthorized,
        );
      }

      if (scope == LeaderboardScope.friends) {
        final roster = await _friendsRoster(period);
        final self = roster.where((entry) => entry.isSelf).firstOrNull;
        if (self != null) return self;
        return _selfProfileEntry(userId, rank: 0, score: 0, topPercent: 100);
      }

      final row = await _client
          .from(_viewFor(period))
          .select('user_id, country_code, points, rank_global, rank_country')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        return _selfProfileEntry(userId, rank: 0, score: 0, topPercent: 100);
      }

      final rank = scope == LeaderboardScope.country
          ? row['rank_country'] as int
          : row['rank_global'] as int;
      final totalRow = await _client
          .from(_viewFor(period))
          .select('user_id')
          .maybeEq(
            scope == LeaderboardScope.country ? 'country_code' : null,
            row['country_code'],
          );
      final total = totalRow.length;
      final topPercent = total == 0 ? 100 : ((rank / total) * 100).ceil();

      return _selfProfileEntry(
        userId,
        rank: rank,
        score: row['points'] as int,
        topPercent: topPercent.clamp(1, 100),
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException.fromSupabase(error);
    }
  }

  Future<List<LeaderboardEntry>> fetchCategoryRoster(
    String subcategoryId,
  ) async {
    try {
      final rows = await _client
          .from('lb_alltime')
          .select('user_id, points, rank_subcategory')
          .eq('subcategory_id', subcategoryId)
          .order('rank_subcategory', ascending: true)
          .limit(_rosterLimit);

      final userIds = [for (final row in rows) row['user_id'] as String];
      final profiles = await _profilesFor(userIds);
      final progress = await _client
          .from('level_progress')
          .select('user_id, stars, completed_at')
          .eq('subcategory_id', subcategoryId)
          .inFilter('user_id', userIds);

      final clearedByUser = <String, int>{};
      final starsByUser = <String, int>{};
      for (final row in progress) {
        final userId = row['user_id'] as String;
        if (row['completed_at'] != null) {
          clearedByUser[userId] = (clearedByUser[userId] ?? 0) + 1;
        }
        starsByUser[userId] =
            (starsByUser[userId] ?? 0) + (row['stars'] as int? ?? 0);
      }

      // Plan 025: the viewer's blocked players never appear on any board.
      final blocked = await _blockedIds();

      return withoutBlocked([
        for (final row in rows)
          LeaderboardEntry(
            rank: row['rank_subcategory'] as int,
            playerId: row['user_id'] as String,
            name: profiles[row['user_id']]?.name ?? '—',
            avatarEmoji: profiles[row['user_id']]?.avatar ?? '🐼',
            isPro: profiles[row['user_id']]?.isPro ?? false,
            score: row['points'] as int,
            levelsCleared: clearedByUser[row['user_id']] ?? 0,
            levelCount: LadderConfigRepository.fallbackTotalLevels,
            starsEarned: starsByUser[row['user_id']] ?? 0,
          ),
      ], blocked);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// "You're #{rank} in {country}" + "{points} points from the top 10".
  Future<(int, int, String)> fetchCategoryHeader(String subcategoryId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return (0, 0, '');

      final selfRow = await _client
          .from('lb_alltime')
          .select('points, rank_subcategory')
          .eq('subcategory_id', subcategoryId)
          .eq('user_id', userId)
          .maybeSingle();
      if (selfRow == null) return (0, 0, '');

      final tenthRow = await _client
          .from('lb_alltime')
          .select('points')
          .eq('subcategory_id', subcategoryId)
          .eq('rank_subcategory', 10)
          .maybeSingle();

      final profileRow = await _client
          .from('profiles')
          .select('country_code')
          .eq('id', userId)
          .maybeSingle();
      final countryCode = profileRow?['country_code'] as String?;

      final pointsFromTop =
          ((tenthRow?['points'] as int?) ?? (selfRow['points'] as int)) -
          (selfRow['points'] as int);

      return (
        selfRow['rank_subcategory'] as int,
        pointsFromTop.abs(),
        countryCode == null ? '' : CountryDirectory.nameFor(countryCode),
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<List<Friend>> fetchFriends() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const [];

      final rows = await _client
          .from('friendships')
          .select('requester_id, addressee_id, status')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId');

      final otherIds = [
        for (final row in rows)
          row['requester_id'] == userId
              ? row['addressee_id'] as String
              : row['requester_id'] as String,
      ];
      final profiles = await _profilesFor(otherIds);

      return [
        for (final row in rows)
          _friendFromRow(row, userId: userId, profiles: profiles),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<List<LeagueStanding>> fetchLeagueNeighbors() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const [];

      final now = DateTime.now().toUtc();
      final weekStart = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final membershipRow = await _client
          .from('league_memberships')
          .select('cohort_id, league_cohorts!inner(week_start)')
          .eq('user_id', userId)
          .eq(
            'league_cohorts.week_start',
            weekStart.toIso8601String().split('T').first,
          )
          .maybeSingle();
      if (membershipRow == null) return const [];
      final cohortId = membershipRow['cohort_id'] as String;

      final rows = await _client
          .from('league_memberships')
          .select('user_id, points')
          .eq('cohort_id', cohortId)
          .order('points', ascending: false);

      final userIds = [for (final row in rows) row['user_id'] as String];
      final profiles = await _profilesFor(userIds);
      final selfIndex = rows.indexWhere((row) => row['user_id'] == userId);
      final lo = (selfIndex - 2).clamp(0, rows.length);
      final hi = (selfIndex + 3).clamp(0, rows.length);

      return [
        for (var index = lo; index < hi; index++)
          LeagueStanding(
            rank: index + 1,
            playerId: rows[index]['user_id'] as String,
            name: profiles[rows[index]['user_id']]?.name ?? '—',
            avatarEmoji: profiles[rows[index]['user_id']]?.avatar ?? '🐼',
            isPro: profiles[rows[index]['user_id']]?.isPro ?? false,
            points: rows[index]['points'] as int,
            isSelf: rows[index]['user_id'] == userId,
          ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  // ------------------------------------------------------------- internals

  /// The viewer's own block list (plan 025). RLS only exposes rows where the
  /// caller is the blocker, so this needs no extra filter — and the blocked
  /// side is never queried by a client.
  Future<Set<String>> _blockedIds() async {
    final rows = await _client.from('user_blocks').select('blocked_id');
    return {for (final row in rows) row['blocked_id'] as String};
  }

  Future<List<LeaderboardEntry>> _friendsRoster(
    LeaderboardPeriod period,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final friendshipRows = await _client
        .from('friendships')
        .select('requester_id, addressee_id')
        .eq('status', 'accepted')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId');

    final ids = {
      userId,
      for (final row in friendshipRows)
        row['requester_id'] == userId
            ? row['addressee_id'] as String
            : row['requester_id'] as String,
    }.toList();

    final since = switch (period) {
      LeaderboardPeriod.week => _startOfWeekUtc(),
      LeaderboardPeriod.month => _startOfMonthUtc(),
      LeaderboardPeriod.allTime => null,
    };

    var query = _client
        .from('score_events')
        .select('user_id, points')
        .inFilter('user_id', ids);
    if (since != null) {
      query = query.gte('occurred_at', since.toIso8601String());
    }
    final rows = await query;

    final totals = <String, int>{for (final id in ids) id: 0};
    for (final row in rows) {
      final id = row['user_id'] as String;
      totals[id] = (totals[id] ?? 0) + (row['points'] as int);
    }

    final profiles = await _profilesFor(ids);
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Plan 025: a blocked friend is hidden from the friends board too.
    final blocked = await _blockedIds();

    return withoutBlocked([
      for (final (index, entry) in ranked.indexed)
        LeaderboardEntry(
          rank: index + 1,
          playerId: entry.key,
          name: profiles[entry.key]?.name ?? '—',
          avatarEmoji: profiles[entry.key]?.avatar ?? '🐼',
          isPro: profiles[entry.key]?.isPro ?? false,
          score: entry.value,
          isSelf: entry.key == userId,
        ),
    ], blocked);
  }

  Future<LeaderboardEntry> _selfProfileEntry(
    String userId, {
    required int rank,
    required int score,
    required int topPercent,
  }) async {
    final profile = await _profilesFor([userId]);
    return LeaderboardEntry(
      rank: rank,
      playerId: userId,
      name: profile[userId]?.name ?? 'You',
      avatarEmoji: profile[userId]?.avatar ?? '🐼',
      isPro: profile[userId]?.isPro ?? false,
      score: score,
      locationLabel: profile[userId]?.location,
      isSelf: true,
      topPercent: topPercent,
    );
  }

  LeaderboardEntry _entryFromTotalsRow(
    Map<String, dynamic> row, {
    required LeaderboardScope scope,
    required _ProfileRow? profile,
    required String? selfId,
  }) {
    final userId = row['user_id'] as String;
    return LeaderboardEntry(
      rank: scope == LeaderboardScope.country
          ? row['rank_country'] as int
          : row['rank_global'] as int,
      playerId: userId,
      name: profile?.name ?? '—',
      avatarEmoji: profile?.avatar ?? '🐼',
      isPro: profile?.isPro ?? false,
      score: row['points'] as int,
      locationLabel: profile?.location,
      isSelf: userId == selfId,
    );
  }

  Friend _friendFromRow(
    Map<String, dynamic> row, {
    required String userId,
    required Map<String, _ProfileRow> profiles,
  }) {
    final isRequester = row['requester_id'] == userId;
    final otherId = isRequester
        ? row['addressee_id'] as String
        : row['requester_id'] as String;
    final status = row['status'] as String;
    final profile = profiles[otherId];

    final friendStatus = status == 'pending' && !isRequester
        ? FriendStatus.pending
        : FriendStatus.offline;

    return Friend(
      id: otherId,
      name: profile?.name ?? '—',
      avatarEmoji: profile?.avatar ?? '🐼',
      isPro: profile?.isPro ?? false,
      status: friendStatus,
      subtitle: friendStatus == FriendStatus.pending
          ? 'Wants to be friends'
          : 'Offline',
    );
  }

  /// The one profile lookup behind every leaderboard, league and friends
  /// row. A named record (plan 023, 6.8) rather than a positional one, since
  /// the Pro flag makes four fields and `$4` is unreadable.
  Future<Map<String, _ProfileRow>> _profilesFor(List<String> userIds) async {
    if (userIds.isEmpty) return const {};
    final rows = await _client
        .from('profiles')
        .select('id, username, avatar_key, country_code, is_pro')
        .inFilter('id', userIds.toSet().toList());

    return {
      for (final row in rows)
        row['id'] as String: (
          name: row['username'] as String? ?? '—',
          avatar: row['avatar_key'] as String? ?? '🐼',
          location: _locationLabel(row['country_code'] as String?),
          isPro: row['is_pro'] as bool? ?? false,
        ),
    };
  }

  /// "🇵🇰 Pakistan" — flag plus the player's real, currently-selected
  /// country. Never a city: `profiles.city` isn't a field players actually
  /// set today, so showing it renders leftover seed/mock data instead of
  /// something a real player chose.
  static String? _locationLabel(String? countryCode) {
    if (countryCode == null) return null;
    final flag = CountryDirectory.flagFor(countryCode);
    return '$flag ${CountryDirectory.nameFor(countryCode)}';
  }

  static DateTime _startOfWeekUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  static DateTime _startOfMonthUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month);
  }
}

extension _MaybeEq<T> on PostgrestFilterBuilder<T> {
  /// `.eq(column, value)` only when [column] is non-null — used where a
  /// count-all-rows query is sometimes scoped to a country, sometimes not.
  PostgrestFilterBuilder<T> maybeEq(String? column, Object? value) =>
      column == null ? this : eq(column, value as Object);
}
