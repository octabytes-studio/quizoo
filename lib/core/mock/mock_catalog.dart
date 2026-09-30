import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/models/subcategory.dart';

/// The taxonomy fixture every browse surface in plan 002 reads.
///
/// Home, Search and Browse all list the same categories and topics, so the
/// fixture lives in `core/mock/` rather than in whichever feature happened to
/// need it first (CLAUDE.md §2's 3+ bar). Only `*_api.dart` files touch it —
/// a repository or Cubit reaching in here directly would be skipping the
/// boundary the mock exists to exercise.
///
/// **Scope, stated honestly** (plan 002, Assumption 4): two categories are
/// fleshed out — Sports, because nearly every frame in the design bible uses
/// it, and Science, which proves a second gradient pairing and carries the
/// image questions. Football is the one topic with real levels behind it.
/// Everything else is a "New" tile with no content, which is a deliberate
/// mock-data shortcut and not a claim about content completeness.
abstract final class MockCatalog {
  static const String sportsId = 'cat_sports';
  static const String scienceId = 'cat_science';

  /// The one topic with twenty playable levels behind it.
  static const String footballId = 'sub_football';

  /// The topic that carries the image questions (S-15).
  static const String solarSystemId = 'sub_solar_system';

  /// Where a brand-new player starts: level 1 of Football, nothing cleared.
  static const int guestLevelsCleared = 0;

  /// Where the bible's own screens put the player: mid-Football, level 12.
  static const int signedInLevelsCleared = 11;

  static const List<Category> categories = [
    Category(
      id: sportsId,
      name: 'Sports',
      emoji: '⚽',
      colorFrom: '#FF8A24',
      colorTo: '#FF3D6E',
      order: 0,
      subcategoryCount: 8,
      questionCount: 3200,
    ),
    Category(
      id: scienceId,
      name: 'Science',
      emoji: '🔬',
      colorFrom: '#2BB3FF',
      colorTo: '#7B4DFF',
      order: 1,
      subcategoryCount: 5,
      questionCount: 1980,
    ),
    Category(
      id: 'cat_general',
      name: 'General',
      emoji: '🌍',
      colorFrom: '#12C79B',
      colorTo: '#7BE495',
      order: 2,
      subcategoryCount: 4,
      questionCount: 1600,
    ),
    Category(
      id: 'cat_iq',
      name: 'IQ',
      emoji: '🧠',
      colorFrom: '#7B4DFF',
      colorTo: '#2BB3FF',
      order: 3,
      subcategoryCount: 3,
      questionCount: 900,
    ),
    Category(
      id: 'cat_maths',
      name: 'Maths',
      emoji: '🔢',
      colorFrom: '#FFC61A',
      colorTo: '#FF8A24',
      order: 4,
      subcategoryCount: 3,
      questionCount: 860,
    ),
    Category(
      id: 'cat_islam',
      name: 'Islam',
      emoji: '🕌',
      colorFrom: '#12C79B',
      colorTo: '#2BB3FF',
      order: 5,
      subcategoryCount: 3,
      questionCount: 740,
    ),
  ];

  /// How many players each category shows in its S-07 header.
  static const Map<String, int> categoryPlayerCounts = {
    sportsId: 128000,
    scienceId: 96400,
    'cat_general': 141200,
    'cat_iq': 88700,
    'cat_maths': 51300,
    'cat_islam': 63900,
  };

  /// Every topic in the app, in the order its category lists them.
  ///
  /// `levelsCleared` here is the **signed-in** player's progress; a guest
  /// sees the same list with progress zeroed — see [asGuest].
  static const List<Subcategory> subcategories = [
    // ---------------------------------------------------------- Sports
    Subcategory(
      id: footballId,
      categoryId: sportsId,
      name: 'Football',
      emoji: '⚽',
      plateColor: '#FFE9D6',
      questionCount: 400,
      levelsCleared: signedInLevelsCleared,
      bestScore: 18420,
      starsEarned: 28,
    ),
    Subcategory(
      id: 'sub_cricket',
      categoryId: sportsId,
      name: 'Cricket',
      emoji: '🏏',
      plateColor: '#DDF1FF',
      questionCount: 400,
      levelsCleared: 20,
      bestScore: 21050,
      starsEarned: 54,
    ),
    Subcategory(
      id: 'sub_hockey',
      categoryId: sportsId,
      name: 'Hockey',
      emoji: '🏒',
      plateColor: '#E4F7F1',
      questionCount: 380,
      levelsCleared: 2,
      bestScore: 3120,
      starsEarned: 4,
    ),
    Subcategory(
      id: 'sub_basketball',
      categoryId: sportsId,
      name: 'Basketball',
      emoji: '🏀',
      plateColor: '#FFE4EC',
      questionCount: 360,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_tennis',
      categoryId: sportsId,
      name: 'Tennis',
      emoji: '🎾',
      plateColor: '#FFF4D6',
      questionCount: 340,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_olympics',
      categoryId: sportsId,
      name: 'Olympics',
      emoji: '🏅',
      plateColor: '#EDE8FA',
      questionCount: 320,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_formula1',
      categoryId: sportsId,
      name: 'Formula 1',
      emoji: '🏎️',
      plateColor: '#E4F7F1',
      questionCount: 300,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_boxing',
      categoryId: sportsId,
      name: 'Boxing & MMA',
      emoji: '🥊',
      plateColor: '#DDF1FF',
      questionCount: 280,
    ),

    // --------------------------------------------------------- Science
    Subcategory(
      id: solarSystemId,
      categoryId: scienceId,
      name: 'Solar System',
      emoji: '🪐',
      groupName: 'Astronomy',
      plateColor: '#DDF1FF',
      questionCount: 400,
      levelsCleared: 3,
      bestScore: 5240,
      starsEarned: 7,
    ),
    Subcategory(
      id: 'sub_space_exploration',
      categoryId: scienceId,
      name: 'Space Exploration',
      emoji: '🔭',
      groupName: 'Astronomy',
      plateColor: '#EDE8FA',
      questionCount: 400,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_stars_galaxies',
      categoryId: scienceId,
      name: 'Stars & Galaxies',
      emoji: '☀️',
      groupName: 'Astronomy',
      plateColor: '#FFF4D6',
      questionCount: 380,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_biology',
      categoryId: scienceId,
      name: 'Biology',
      emoji: '🧬',
      groupName: 'Life sciences',
      plateColor: '#E4F7F1',
      questionCount: 420,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_chemistry',
      categoryId: scienceId,
      name: 'Chemistry',
      emoji: '🧪',
      groupName: 'Physical sciences',
      plateColor: '#FFE4EC',
      questionCount: 380,
    ),

    // --------------------------------------------------------- General
    Subcategory(
      id: 'sub_world_facts',
      categoryId: 'cat_general',
      name: 'World Facts',
      emoji: '🌍',
      plateColor: '#FFE9D6',
      questionCount: 460,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_flags',
      categoryId: 'cat_general',
      name: 'Flags',
      emoji: '🚩',
      plateColor: '#DDF1FF',
      questionCount: 400,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_movies',
      categoryId: 'cat_general',
      name: 'Movies',
      emoji: '🎬',
      plateColor: '#FFE4EC',
      questionCount: 380,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_capitals',
      categoryId: 'cat_general',
      name: 'Capitals',
      emoji: '🏙️',
      plateColor: '#EDE8FA',
      questionCount: 360,
      isNew: true,
    ),

    // -------------------------------------------------------------- IQ
    Subcategory(
      id: 'sub_pattern_logic',
      categoryId: 'cat_iq',
      name: 'Pattern Logic',
      emoji: '🧩',
      plateColor: '#FFF4D6',
      questionCount: 320,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_lateral',
      categoryId: 'cat_iq',
      name: 'Lateral Thinking',
      emoji: '💡',
      plateColor: '#EDE8FA',
      questionCount: 300,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_memory',
      categoryId: 'cat_iq',
      name: 'Memory',
      emoji: '🧠',
      plateColor: '#DDF1FF',
      questionCount: 280,
    ),

    // ----------------------------------------------------------- Maths
    Subcategory(
      id: 'sub_mental_maths',
      categoryId: 'cat_maths',
      name: 'Mental Maths',
      emoji: '🔢',
      plateColor: '#FFF4D6',
      questionCount: 320,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_geometry',
      categoryId: 'cat_maths',
      name: 'Geometry',
      emoji: '📐',
      plateColor: '#E4F7F1',
      questionCount: 280,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_number_theory',
      categoryId: 'cat_maths',
      name: 'Number Theory',
      emoji: '➗',
      plateColor: '#FFE9D6',
      questionCount: 260,
    ),

    // ----------------------------------------------------------- Islam
    Subcategory(
      id: 'sub_seerah',
      categoryId: 'cat_islam',
      name: 'Seerah',
      emoji: '🕌',
      plateColor: '#E4F7F1',
      questionCount: 300,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_quran',
      categoryId: 'cat_islam',
      name: 'Quran',
      emoji: '📖',
      plateColor: '#EDE8FA',
      questionCount: 260,
      isNew: true,
    ),
    Subcategory(
      id: 'sub_history_islam',
      categoryId: 'cat_islam',
      name: 'Islamic History',
      emoji: '🏛️',
      plateColor: '#FFF4D6',
      questionCount: 180,
    ),
  ];

  /// The same taxonomy with every trace of progress removed.
  ///
  /// A guest on first launch has started nothing, so their tiles read "20
  /// levels" with no progress bar — which is exactly what S-04's frame shows.
  /// [Subcategory.isNew] is deliberately left alone: it marks content that is
  /// new *to the catalogue*, not content this player has not tried, and
  /// flipping it here would label every topic "New" on first launch.
  static List<Subcategory> asGuest(List<Subcategory> source) => [
    for (final subcategory in source)
      subcategory.copyWith(levelsCleared: 0, bestScore: 0, starsEarned: 0),
  ];

  static List<Subcategory> forCategory(String categoryId) => [
    for (final subcategory in subcategories)
      if (subcategory.categoryId == categoryId) subcategory,
  ];

  static Category categoryById(String id) =>
      categories.firstWhere((category) => category.id == id);

  static Subcategory subcategoryById(String id) =>
      subcategories.firstWhere((subcategory) => subcategory.id == id);

  /// The thirty levels behind [subcategory], built from the 30-level ladder.
  ///
  /// Bands, clocks, question counts and boss placement are derived rather
  /// than typed out thirty times: levels 1–10 are Easy at 20s/10 questions,
  /// 11–20 Medium at 15s/15 questions, 21–30 Hard at 10s/20 questions, and
  /// every tenth level is a boss.
  static List<Level> levelsFor(Subcategory subcategory) => [
    for (var number = 1; number <= subcategory.levelCount; number++)
      _level(subcategory, number),
  ];

  static Level _level(Subcategory subcategory, int number) {
    final cleared = number <= subcategory.levelsCleared;
    final isCurrent = number == subcategory.levelsCleared + 1;
    return Level(
      id: levelId(subcategory.id, number),
      subcategoryId: subcategory.id,
      number: number,
      difficultyBand: bandFor(number),
      secondsPerQuestion: secondsFor(number),
      questionCount: questionsFor(number),
      status: cleared
          ? LevelStatus.done
          : isCurrent
          ? LevelStatus.current
          : LevelStatus.locked,
      isBoss: number % 10 == 0,
      // A deterministic but uneven star spread, so the map does not read as a
      // column of identical three-star nodes.
      starsEarned: cleared ? 2 + (number % 3 == 0 ? 1 : 0) : 0,
      bestScore: cleared ? 1600 + number * 140 : 0,
    );
  }

  /// The level's stable id — `sub_football::12`.
  static String levelId(String subcategoryId, int number) =>
      '$subcategoryId::$number';

  /// Splits a [levelId] back into its topic and number.
  static (String subcategoryId, int number) parseLevelId(String levelId) {
    final parts = levelId.split('::');
    return (parts.first, int.tryParse(parts.last) ?? 1);
  }

  /// The 30-level, 3-tier ladder (`difficulty_tiers`): 1–10 Easy, 11–20
  /// Medium, 21–30 Hard.
  static DifficultyBand bandFor(int levelNumber) => switch (levelNumber) {
    <= 10 => DifficultyBand.warmUp,
    <= 20 => DifficultyBand.steady,
    _ => DifficultyBand.sharp,
  };

  /// The clock tightens with the band: 20 → 15 → 10 seconds.
  static int secondsFor(int levelNumber) => switch (bandFor(levelNumber)) {
    DifficultyBand.warmUp => 20,
    DifficultyBand.steady => 15,
    DifficultyBand.sharp => 10,
  };

  /// Questions per level grow with the band: 10 → 15 → 20.
  static int questionsFor(int levelNumber) => switch (bandFor(levelNumber)) {
    DifficultyBand.warmUp => 10,
    DifficultyBand.steady => 15,
    DifficultyBand.sharp => 20,
  };
}
