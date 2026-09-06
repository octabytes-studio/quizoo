import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/features/home/domain/home_content.dart';

/// Home's mocked endpoints.
///
/// Split in two on purpose, because §01's timing contract is a two-stage
/// paint: *"Splash → Home ≤ 1.2 s — home renders from cache; network fills the
/// popular rail after."* [fetchCachedHome] is the local read, effectively
/// instant; [fetchPopularRail] is the network leg that lands afterwards.
class HomeApi extends MockApi {
  HomeApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// What a real client would have in local storage already.
  static const Duration cacheLatency = Duration(milliseconds: 40);

  /// The taxonomy, wallet and in-progress level, served from cache.
  ///
  /// [isSignedIn] decides the two things that actually differ between S-04 and
  /// S-05: whether there is a wallet and a level in progress at all. It is a
  /// parameter rather than a second endpoint because a real backend would
  /// answer the same route differently for an anonymous caller.
  Future<HomeContent> fetchCachedHome({required bool isSignedIn}) => respond(
    latency: cacheLatency,
    () => HomeContent(
      categories: MockCatalog.categories,
      subcategories: isSignedIn
          ? MockCatalog.subcategories
          : MockCatalog.asGuest(MockCatalog.subcategories),
      currency: isSignedIn ? MockPlayer.currency : null,
      daily: isSignedIn
          ? const DailyChallengePreview(minutesRemaining: 252)
          : null,
      continueEntry: isSignedIn ? _continueEntry : null,
    ),
  );

  /// The merchandised rail, which arrives after the first paint.
  Future<List<PopularQuiz>> fetchPopularRail() => respond(() => _popular);

  static ContinueEntry get _continueEntry {
    final football = MockCatalog.subcategoryById(MockCatalog.footballId);
    return ContinueEntry(
      subcategoryId: football.id,
      subcategoryName: football.name,
      emoji: football.emoji,
      plateColor: football.plateColor,
      levelNumber: football.levelsCleared + 1,
      points: 2140,
      livesLeft: 3,
    );
  }

  static const List<PopularQuiz> _popular = [
    PopularQuiz(
      id: 'pq_football',
      subcategoryId: MockCatalog.footballId,
      title: 'Football Legends',
      emoji: '⚽',
      colorFrom: '#FF8A24',
      colorTo: '#FF3D6E',
      playedCount: 84200,
      isHot: true,
    ),
    PopularQuiz(
      id: 'pq_pattern_logic',
      subcategoryId: 'sub_pattern_logic',
      title: 'IQ: Pattern Logic',
      emoji: '🧠',
      colorFrom: '#7B4DFF',
      colorTo: '#2BB3FF',
      playedCount: 61700,
    ),
    PopularQuiz(
      id: 'pq_flags',
      subcategoryId: 'sub_flags',
      title: 'Flags of the World',
      emoji: '🌍',
      colorFrom: '#12C79B',
      colorTo: '#7BE495',
      playedCount: 52400,
    ),
    PopularQuiz(
      id: 'pq_solar_system',
      subcategoryId: MockCatalog.solarSystemId,
      title: 'Solar System',
      emoji: '🪐',
      colorFrom: '#2BB3FF',
      colorTo: '#7B4DFF',
      playedCount: 38100,
    ),
  ];

  /// Everything Search filters over — the taxonomy, not a server query.
  ///
  /// The bible specifies search as "local-first from the cached taxonomy so it
  /// works offline", so this reads the same fixture Home does.
  Future<List<PopularQuiz>> fetchTrendingSearches() =>
      respond(latency: cacheLatency, () => _popular);
}
