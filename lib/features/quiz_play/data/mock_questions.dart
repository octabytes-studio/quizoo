import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// The authored question pool every mock level is dealt from.
///
/// **A deliberate mock-data shortcut, stated plainly** (plan 002, Assumption
/// 4): the real product is 20 levels × 20 questions per topic. Authoring 400
/// unique questions is content work, not design work, so this file holds a
/// pool of hand-written questions and [MockQuestions.forLevel] deals twenty
/// from it, shuffled deterministically per level. Two levels therefore share
/// questions. That is a fixture, not a claim about content completeness.
abstract final class MockQuestions {
  /// Every level is twenty questions (§19).
  static const int questionsPerLevel = 20;

  /// The pool for the one topic with real levels behind it.
  static const List<Question> football = [
    Question(
      id: 'q_fb_ucl',
      subcategoryId: MockCatalog.footballId,
      difficulty: 2,
      text: 'Which club has won the most UEFA Champions League titles?',
      options: ['AC Milan', 'Real Madrid', 'Bayern Munich', 'Liverpool'],
      correctIndex: 1,
      explanation:
          "15 titles. Real Madrid's most recent came in 2024 — more than "
          "double the next club's tally.",
    ),
    Question(
      id: 'q_fb_ballondor',
      subcategoryId: MockCatalog.footballId,
      difficulty: 2,
      text: 'Who has won the most Ballon d\'Or awards?',
      options: ['Cristiano Ronaldo', 'Lionel Messi', 'Michel Platini', 'Pelé'],
      correctIndex: 1,
      explanation:
          'Messi has eight; Ronaldo has five. Pelé never won one — the award '
          'was European-players-only for most of his career.',
    ),
    Question(
      id: 'q_fb_wc1994',
      subcategoryId: MockCatalog.footballId,
      difficulty: 2,
      text: 'Which country hosted the 1994 FIFA World Cup?',
      options: ['Mexico', 'USA', 'Italy', 'France'],
      correctIndex: 1,
      explanation:
          'The USA. It still holds the highest average attendance of any '
          'World Cup, nearly 69,000 a game.',
    ),
    Question(
      id: 'q_fb_wc_most',
      subcategoryId: MockCatalog.footballId,
      difficulty: 1,
      text: 'Which nation has won the most World Cups?',
      options: ['Germany', 'Italy', 'Brazil', 'Argentina'],
      correctIndex: 2,
      explanation:
          'Brazil, with five. They are also the only team to have played in '
          'every tournament.',
    ),
    Question(
      id: 'q_fb_offside',
      subcategoryId: MockCatalog.footballId,
      difficulty: 1,
      text: 'How many players are on the pitch per team at kick-off?',
      options: ['9', '10', '11', '12'],
      correctIndex: 2,
      explanation:
          'Eleven, one of whom must be the goalkeeper. A team drops to nine '
          'before the match is abandoned.',
    ),
    Question(
      id: 'q_fb_premier_first',
      subcategoryId: MockCatalog.footballId,
      difficulty: 3,
      text: 'Who won the first ever Premier League season, in 1992–93?',
      options: [
        'Manchester United',
        'Arsenal',
        'Blackburn Rovers',
        'Aston Villa',
      ],
      correctIndex: 0,
      explanation:
          "Manchester United, ending a 26-year wait for a league title. They'd "
          'go on to win 13 of the first 21.',
    ),
    Question(
      id: 'q_fb_golden_boot',
      subcategoryId: MockCatalog.footballId,
      difficulty: 3,
      text: 'What is awarded to the top scorer at a World Cup?',
      options: ['Golden Ball', 'Golden Boot', 'Golden Glove', 'Bronze Ball'],
      correctIndex: 1,
      explanation:
          'The Golden Boot. The Golden Ball goes to the best player and the '
          'Golden Glove to the best goalkeeper.',
    ),
    Question(
      id: 'q_fb_maracana',
      subcategoryId: MockCatalog.footballId,
      difficulty: 3,
      text: 'In which city is the Maracanã stadium?',
      options: ['São Paulo', 'Buenos Aires', 'Rio de Janeiro', 'Lisbon'],
      correctIndex: 2,
      explanation:
          'Rio de Janeiro. Its 1950 World Cup final drew a crowd officially '
          'recorded at 173,850.',
    ),
    Question(
      id: 'q_fb_hattrick',
      subcategoryId: MockCatalog.footballId,
      difficulty: 1,
      text: 'How many goals make a hat-trick?',
      options: ['2', '3', '4', '5'],
      correctIndex: 1,
      explanation:
          'Three in one match. The term was borrowed from cricket, where a '
          'bowler taking three wickets won a hat.',
    ),
    Question(
      id: 'q_fb_captain_2014',
      subcategoryId: MockCatalog.footballId,
      difficulty: 4,
      text: 'Which club plays its home games at the Camp Nou?',
      options: ['Real Madrid', 'Barcelona', 'Valencia', 'Sevilla'],
      correctIndex: 1,
      explanation:
          "Barcelona. It is Europe's largest stadium, seating just under "
          '100,000.',
    ),
    Question(
      id: 'q_fb_red_card',
      subcategoryId: MockCatalog.footballId,
      difficulty: 2,
      text: 'What does a second yellow card in one match result in?',
      options: ['A penalty', 'A red card', 'A warning', 'A free kick'],
      correctIndex: 1,
      explanation:
          'A red card, and the player leaves the pitch. Their team plays on '
          'with ten and cannot replace them.',
    ),
    Question(
      id: 'q_fb_var',
      subcategoryId: MockCatalog.footballId,
      difficulty: 4,
      text: 'What does VAR stand for?',
      options: [
        'Video Assistant Referee',
        'Verified Action Review',
        'Visual Angle Replay',
        'Video Appeal Ruling',
      ],
      correctIndex: 0,
      explanation:
          'Video Assistant Referee, first used at a World Cup in 2018.',
    ),
    Question(
      id: 'q_fb_penalty_distance',
      subcategoryId: MockCatalog.footballId,
      difficulty: 4,
      text: 'How far is the penalty spot from the goal line?',
      options: ['10 yards', '11 yards', '12 yards', '14 yards'],
      correctIndex: 2,
      explanation:
          'Twelve yards, about 11 metres — unchanged since the penalty kick '
          'was introduced in 1891.',
    ),
    Question(
      id: 'q_fb_treble',
      subcategoryId: MockCatalog.footballId,
      difficulty: 5,
      text: 'A "continental treble" means winning which three in one season?',
      options: [
        'League, domestic cup, continental cup',
        'League, super cup, world cup',
        'Three consecutive leagues',
        'Cup, super cup, shield',
      ],
      correctIndex: 0,
      explanation:
          'The league, the main domestic cup and the continental competition '
          '— all in a single season.',
    ),
    Question(
      id: 'q_fb_keeper_gloves',
      subcategoryId: MockCatalog.footballId,
      difficulty: 5,
      text: 'Where may a goalkeeper legally handle the ball?',
      options: [
        'Anywhere in their own half',
        'Inside their own penalty area',
        'Inside the six-yard box only',
        'Anywhere on the pitch',
      ],
      correctIndex: 1,
      explanation:
          'Only inside their own penalty area. Handling it outside is a free '
          'kick, and often a red card.',
    ),
  ];

  /// The pool behind the topic that carries the image questions (S-15).
  static const List<Question> solarSystem = [
    Question(
      id: 'q_ss_largest',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 1,
      text: 'Which is the largest planet in the Solar System?',
      options: ['Saturn', 'Jupiter', 'Earth', 'Mars'],
      correctIndex: 1,
      explanation:
          'Jupiter — more than twice as massive as every other planet in the '
          'Solar System put together.',
    ),
    Question(
      id: 'q_ss_landmark',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 2,
      text: 'Which planet is this?',
      options: ['Saturn', 'Uranus', 'Neptune'],
      correctIndex: 0,
      explanation:
          "Saturn. Its rings are mostly water ice, and they're only about ten "
          'metres thick.',
      hasImage: true,
      imageEmoji: '🪐',
      imageColorFrom: '#FFC61A',
      imageColorTo: '#FF8A24',
    ),
    Question(
      id: 'q_ss_red',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 1,
      text: 'Which planet is known as the Red Planet?',
      options: ['Venus', 'Mars', 'Mercury', 'Jupiter'],
      correctIndex: 1,
      explanation:
          'Mars. The colour comes from iron oxide — rust — across its surface.',
    ),
    Question(
      id: 'q_ss_shortest_day',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 3,
      text: 'Which planet has the shortest day in the Solar System?',
      options: ['Mercury', 'Jupiter', 'Earth', 'Venus'],
      correctIndex: 1,
      explanation:
          'Jupiter turns once in under ten hours, despite being the largest '
          'planet.',
    ),
    Question(
      id: 'q_ss_moon_image',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 2,
      text: 'Which body is shown here?',
      options: ['The Moon', 'Europa', 'Titan'],
      correctIndex: 0,
      explanation:
          "Earth's Moon. It is drifting away from us at about 3.8 cm a year.",
      hasImage: true,
      imageEmoji: '🌕',
      imageColorFrom: '#2BB3FF',
      imageColorTo: '#7B4DFF',
    ),
    Question(
      id: 'q_ss_hottest',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 4,
      text: 'Which is the hottest planet in the Solar System?',
      options: ['Mercury', 'Venus', 'Mars', 'Jupiter'],
      correctIndex: 1,
      explanation:
          'Venus, at about 465°C. Its thick carbon-dioxide atmosphere traps '
          'more heat than Mercury gets from being closer to the Sun.',
    ),
    Question(
      id: 'q_ss_rings',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 3,
      text: 'How many planets in the Solar System have ring systems?',
      options: ['One', 'Two', 'Four', 'Eight'],
      correctIndex: 2,
      explanation:
          "Four — Jupiter, Saturn, Uranus and Neptune. Saturn's are simply the "
          'only ones bright enough to see easily.',
    ),
    Question(
      id: 'q_ss_asteroid_belt',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 4,
      text: 'The asteroid belt lies between which two planets?',
      options: [
        'Earth and Mars',
        'Mars and Jupiter',
        'Jupiter and Saturn',
        'Venus and Earth',
      ],
      correctIndex: 1,
      explanation:
          "Mars and Jupiter. Everything in it together weighs less than Earth's "
          'Moon.',
    ),
    Question(
      id: 'q_ss_sun_type',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 5,
      text: 'What type of star is the Sun?',
      options: ['Red giant', 'White dwarf', 'Yellow dwarf', 'Blue supergiant'],
      correctIndex: 2,
      explanation:
          'A yellow dwarf, or G-type main-sequence star — about halfway '
          'through its life.',
    ),
    Question(
      id: 'q_ss_broken_image',
      subcategoryId: MockCatalog.solarSystemId,
      difficulty: 3,
      text: 'Which planet is closest to the Sun?',
      options: ['Mercury', 'Venus', 'Earth'],
      correctIndex: 0,
      explanation: 'Mercury, though it is not the hottest — Venus takes that.',
      hasImage: true,
      // No emoji and a path that does not resolve: this fixture exists to
      // exercise the S-15 requirement that a failed image degrades to the
      // text-only layout rather than a broken box.
      imageAsset: 'assets/mock/missing_landmark.png',
    ),
  ];

  /// The Urdu question used to prove S-16's RTL layout on real content.
  ///
  /// Only one is authored: the RTL proof needs a real Nastaliq question with
  /// real Urdu options, not a translated set — translation is content work
  /// deferred with the rest of the Urdu catalogue (plan 001, Assumption 5).
  static const Question urduSample = Question(
    id: 'q_ur_largest_planet',
    subcategoryId: MockCatalog.solarSystemId,
    difficulty: 1,
    text: 'نظامِ شمسی میں سب سے بڑا سیارہ کون سا ہے؟',
    options: ['زحل', 'مشتری', 'زمین', 'مریخ'],
    correctIndex: 1,
    explanation: 'مشتری — یہ باقی تمام سیاروں کے مجموعے سے بھی دوگنا بھاری ہے۔',
  );

  /// The pool a topic draws from, or an empty list for a topic with no
  /// content behind it yet.
  static List<Question> poolFor(String subcategoryId) =>
      switch (subcategoryId) {
        MockCatalog.footballId => football,
        MockCatalog.solarSystemId => solarSystem,
        _ => const [],
      };

  /// Twenty questions for [levelNumber] of [subcategoryId].
  ///
  /// Deterministic per level — the same level always deals the same twenty in
  /// the same order, so a replay is comparable and a test is repeatable.
  /// Harder levels start deeper into the pool, which is a crude stand-in for
  /// §19's "difficulty 1–2 / 2–3 / 3–4 / 4–5" pools.
  static List<Question> forLevel({
    required String subcategoryId,
    required int levelNumber,
    String languageCode = 'en',
  }) {
    final pool = poolFor(subcategoryId);
    if (pool.isEmpty) return const [];

    final ordered = [...pool]
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    final offset = (levelNumber - 1) * 3;

    final questions = [
      for (var index = 0; index < questionsPerLevel; index++)
        ordered[(offset + index) % ordered.length],
    ];

    // Under Urdu, the first question is the authored Nastaliq one so S-16 has
    // real RTL content to render rather than English in a mirrored layout.
    if (languageCode == 'ur') {
      return [urduSample, ...questions.skip(1)];
    }
    return questions;
  }
}
