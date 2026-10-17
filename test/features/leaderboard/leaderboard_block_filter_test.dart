import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_api.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';

/// The pure half of the plan-025 block filter: `LeaderboardApi` runs it over
/// the global/country, category and friends rosters alike, so one test per
/// shape of input covers every board.
void main() {
  LeaderboardEntry entry(String id, int rank) => LeaderboardEntry(
    rank: rank,
    playerId: id,
    name: id,
    avatarEmoji: '🐼',
    score: 100 - rank,
  );

  group('LeaderboardApi.withoutBlocked', () {
    test('drops the viewer-blocked players and keeps everyone else', () {
      final entries = [
        entry('self', 1),
        entry('user_a', 2),
        entry('user_b', 3),
      ];

      final filtered = LeaderboardApi.withoutBlocked(entries, {'user_a'});

      expect(filtered.map((e) => e.playerId), ['self', 'user_b']);
    });

    test('an empty block list keeps the roster unchanged', () {
      final entries = [entry('self', 1), entry('user_a', 2)];

      expect(LeaderboardApi.withoutBlocked(entries, const {}), entries);
    });

    test('blocking everyone yields an empty roster, never an error', () {
      final entries = [entry('user_a', 1), entry('user_b', 2)];

      expect(
        LeaderboardApi.withoutBlocked(entries, {'user_a', 'user_b'}),
        isEmpty,
      );
    });
  });
}
