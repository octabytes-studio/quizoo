-- ============================================================================
-- Quizoo — seed data
--
-- Loads the same taxonomy, badges, and sample questions already hardcoded in
-- the Flutter app's mock layer (lib/core/mock/mock_catalog.dart,
-- mock_badges.dart, lib/features/quiz_play/data/mock_questions.dart), so the
-- app renders identically to the mock build the moment it's pointed at a
-- real backend — same 6 categories, same 26 subcategories, same "Football"
-- and "Solar System" topics with real playable content, same 12 badges.
--
-- Run after the three migrations. Safe to re-run — every insert is
-- idempotent (ON CONFLICT DO NOTHING / DO UPDATE on the natural key).
--
-- Everything below marked "PLACEHOLDER" is a deliberate stand-in for a table
-- the Design Bible names but whose exact content isn't in the trimmed DDL
-- excerpt this seed was written from (rank titles, most of the 14-category /
-- 85-subcategory / 400-question-each catalogue). Replace with the real
-- content pipeline's output — see docs/backend/README.md.
-- ============================================================================

begin;

-- ============================================================================
-- CATEGORIES (mock_catalog.dart's MockCatalog.categories, verbatim)
-- ============================================================================

insert into public.categories (id, slug, emoji, color_from, color_to, sort_order, subcategory_count, question_count)
values
  ('00000000-0000-4000-8000-000000000001', 'sports',  '⚽', '#FF8A24', '#FF3D6E', 0, 8, 3200),
  ('00000000-0000-4000-8000-000000000002', 'science', '🔬', '#2BB3FF', '#7B4DFF', 1, 5, 1980),
  ('00000000-0000-4000-8000-000000000003', 'general', '🌍', '#12C79B', '#7BE495', 2, 4, 1600),
  ('00000000-0000-4000-8000-000000000004', 'iq',      '🧠', '#7B4DFF', '#2BB3FF', 3, 3, 900),
  ('00000000-0000-4000-8000-000000000005', 'maths',   '🔢', '#FFC61A', '#FF8A24', 4, 3, 860),
  ('00000000-0000-4000-8000-000000000006', 'islam',   '🕌', '#12C79B', '#2BB3FF', 5, 3, 740)
on conflict (id) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
values
  ('category', '00000000-0000-4000-8000-000000000001', 'en', 'Sports'),
  ('category', '00000000-0000-4000-8000-000000000002', 'en', 'Science'),
  ('category', '00000000-0000-4000-8000-000000000003', 'en', 'General'),
  ('category', '00000000-0000-4000-8000-000000000004', 'en', 'IQ'),
  ('category', '00000000-0000-4000-8000-000000000005', 'en', 'Maths'),
  ('category', '00000000-0000-4000-8000-000000000006', 'en', 'Islam')
on conflict (entity_type, entity_id, locale) do nothing;

-- ============================================================================
-- SUBCATEGORIES (mock_catalog.dart's MockCatalog.subcategories, verbatim
-- ids/emoji/plate colors/question counts; is_new/is_locked flags match too)
-- ============================================================================

insert into public.subcategories
  (id, category_id, slug, emoji, plate_color, group_name, question_count, is_new, is_locked)
values
  -- Sports
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000001', 'football',    '⚽',  '#FFE9D6', '', 400, false, false),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000001', 'cricket',      '🏏', '#DDF1FF', '', 400, false, false),
  ('00000000-0000-4000-8000-000000000103', '00000000-0000-4000-8000-000000000001', 'hockey',       '🏒', '#E4F7F1', '', 380, false, false),
  ('00000000-0000-4000-8000-000000000104', '00000000-0000-4000-8000-000000000001', 'basketball',   '🏀', '#FFE4EC', '', 360, true,  false),
  ('00000000-0000-4000-8000-000000000105', '00000000-0000-4000-8000-000000000001', 'tennis',       '🎾', '#FFF4D6', '', 340, true,  false),
  ('00000000-0000-4000-8000-000000000106', '00000000-0000-4000-8000-000000000001', 'olympics',     '🏅', '#EDE8FA', '', 320, true,  false),
  ('00000000-0000-4000-8000-000000000107', '00000000-0000-4000-8000-000000000001', 'formula1',     '🏎️', '#E4F7F1', '', 300, true,  false),
  ('00000000-0000-4000-8000-000000000108', '00000000-0000-4000-8000-000000000001', 'boxing-mma',   '🥊', '#DDF1FF', '', 280, false, true),

  -- Science
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000002', 'solar-system',      '🪐', '#DDF1FF', 'Astronomy',      400, false, false),
  ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000002', 'space-exploration', '🔭', '#EDE8FA', 'Astronomy',      400, true,  false),
  ('00000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-000000000002', 'stars-galaxies',    '☀️', '#FFF4D6', 'Astronomy',      380, true,  false),
  ('00000000-0000-4000-8000-000000000204', '00000000-0000-4000-8000-000000000002', 'biology',           '🧬', '#E4F7F1', 'Life sciences',  420, true,  false),
  ('00000000-0000-4000-8000-000000000205', '00000000-0000-4000-8000-000000000002', 'chemistry',         '🧪', '#FFE4EC', 'Physical sciences', 380, false, true),

  -- General
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000003', 'world-facts', '🌍', '#FFE9D6', '', 460, true, false),
  ('00000000-0000-4000-8000-000000000302', '00000000-0000-4000-8000-000000000003', 'flags',       '🚩', '#DDF1FF', '', 400, true, false),
  ('00000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-000000000003', 'movies',      '🎬', '#FFE4EC', '', 380, true, false),
  ('00000000-0000-4000-8000-000000000304', '00000000-0000-4000-8000-000000000003', 'capitals',    '🏙️', '#EDE8FA', '', 360, true, false),

  -- IQ
  ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000004', 'pattern-logic',    '🧩', '#FFF4D6', '', 320, true,  false),
  ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000004', 'lateral-thinking', '💡', '#EDE8FA', '', 300, true,  false),
  ('00000000-0000-4000-8000-000000000403', '00000000-0000-4000-8000-000000000004', 'memory',           '🧠', '#DDF1FF', '', 280, false, true),

  -- Maths
  ('00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000005', 'mental-maths',  '🔢', '#FFF4D6', '', 320, true,  false),
  ('00000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-000000000005', 'geometry',      '📐', '#E4F7F1', '', 280, true,  false),
  ('00000000-0000-4000-8000-000000000503', '00000000-0000-4000-8000-000000000005', 'number-theory', '➗', '#FFE9D6', '', 260, false, true),

  -- Islam
  ('00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000006', 'seerah',          '🕌', '#E4F7F1', '', 300, true,  false),
  ('00000000-0000-4000-8000-000000000602', '00000000-0000-4000-8000-000000000006', 'quran',           '📖', '#EDE8FA', '', 260, true,  false),
  ('00000000-0000-4000-8000-000000000603', '00000000-0000-4000-8000-000000000006', 'islamic-history', '🏛️', '#FFF4D6', '', 180, false, true)
on conflict (id) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
values
  ('subcategory', '00000000-0000-4000-8000-000000000101', 'en', 'Football'),
  ('subcategory', '00000000-0000-4000-8000-000000000102', 'en', 'Cricket'),
  ('subcategory', '00000000-0000-4000-8000-000000000103', 'en', 'Hockey'),
  ('subcategory', '00000000-0000-4000-8000-000000000104', 'en', 'Basketball'),
  ('subcategory', '00000000-0000-4000-8000-000000000105', 'en', 'Tennis'),
  ('subcategory', '00000000-0000-4000-8000-000000000106', 'en', 'Olympics'),
  ('subcategory', '00000000-0000-4000-8000-000000000107', 'en', 'Formula 1'),
  ('subcategory', '00000000-0000-4000-8000-000000000108', 'en', 'Boxing & MMA'),
  ('subcategory', '00000000-0000-4000-8000-000000000201', 'en', 'Solar System'),
  ('subcategory', '00000000-0000-4000-8000-000000000202', 'en', 'Space Exploration'),
  ('subcategory', '00000000-0000-4000-8000-000000000203', 'en', 'Stars & Galaxies'),
  ('subcategory', '00000000-0000-4000-8000-000000000204', 'en', 'Biology'),
  ('subcategory', '00000000-0000-4000-8000-000000000205', 'en', 'Chemistry'),
  ('subcategory', '00000000-0000-4000-8000-000000000301', 'en', 'World Facts'),
  ('subcategory', '00000000-0000-4000-8000-000000000302', 'en', 'Flags'),
  ('subcategory', '00000000-0000-4000-8000-000000000303', 'en', 'Movies'),
  ('subcategory', '00000000-0000-4000-8000-000000000304', 'en', 'Capitals'),
  ('subcategory', '00000000-0000-4000-8000-000000000401', 'en', 'Pattern Logic'),
  ('subcategory', '00000000-0000-4000-8000-000000000402', 'en', 'Lateral Thinking'),
  ('subcategory', '00000000-0000-4000-8000-000000000403', 'en', 'Memory'),
  ('subcategory', '00000000-0000-4000-8000-000000000501', 'en', 'Mental Maths'),
  ('subcategory', '00000000-0000-4000-8000-000000000502', 'en', 'Geometry'),
  ('subcategory', '00000000-0000-4000-8000-000000000503', 'en', 'Number Theory'),
  ('subcategory', '00000000-0000-4000-8000-000000000601', 'en', 'Seerah'),
  ('subcategory', '00000000-0000-4000-8000-000000000602', 'en', 'Quran'),
  ('subcategory', '00000000-0000-4000-8000-000000000603', 'en', 'Islamic History')
on conflict (entity_type, entity_id, locale) do nothing;

-- PLACEHOLDER: the Design Bible specifies 14 categories / ~85 subcategories
-- / 400 questions each (34k per language). Only the 6 categories / 26
-- subcategories the current mock UI already renders are seeded here — the
-- remaining 8 categories and their subcategories are a content-authoring
-- task (§21's "question authoring pipeline"), not a schema task. Add them as
-- more insert blocks in this same shape once content exists.

-- ============================================================================
-- QUESTIONS — Football (lib/features/quiz_play/data/mock_questions.dart's
-- MockQuestions.football, all 15, verbatim text/options/explanations)
-- ============================================================================

insert into public.questions (id, subcategory_id, kind, difficulty, status)
values
  ('00000000-0000-4000-8000-0000000f0001', '00000000-0000-4000-8000-000000000101', 'text', 2, 'live'),
  ('00000000-0000-4000-8000-0000000f0002', '00000000-0000-4000-8000-000000000101', 'text', 2, 'live'),
  ('00000000-0000-4000-8000-0000000f0003', '00000000-0000-4000-8000-000000000101', 'text', 2, 'live'),
  ('00000000-0000-4000-8000-0000000f0004', '00000000-0000-4000-8000-000000000101', 'text', 1, 'live'),
  ('00000000-0000-4000-8000-0000000f0005', '00000000-0000-4000-8000-000000000101', 'text', 1, 'live'),
  ('00000000-0000-4000-8000-0000000f0006', '00000000-0000-4000-8000-000000000101', 'text', 3, 'live'),
  ('00000000-0000-4000-8000-0000000f0007', '00000000-0000-4000-8000-000000000101', 'text', 3, 'live'),
  ('00000000-0000-4000-8000-0000000f0008', '00000000-0000-4000-8000-000000000101', 'text', 3, 'live'),
  ('00000000-0000-4000-8000-0000000f0009', '00000000-0000-4000-8000-000000000101', 'text', 1, 'live'),
  ('00000000-0000-4000-8000-0000000f0010', '00000000-0000-4000-8000-000000000101', 'text', 4, 'live'),
  ('00000000-0000-4000-8000-0000000f0011', '00000000-0000-4000-8000-000000000101', 'text', 2, 'live'),
  ('00000000-0000-4000-8000-0000000f0012', '00000000-0000-4000-8000-000000000101', 'text', 4, 'live'),
  ('00000000-0000-4000-8000-0000000f0013', '00000000-0000-4000-8000-000000000101', 'text', 4, 'live'),
  ('00000000-0000-4000-8000-0000000f0014', '00000000-0000-4000-8000-000000000101', 'text', 5, 'live'),
  ('00000000-0000-4000-8000-0000000f0015', '00000000-0000-4000-8000-000000000101', 'text', 5, 'live')
on conflict (id) do nothing;

insert into public.question_i18n (question_id, locale, prompt, options, correct_index, explanation, review_state)
values
  ('00000000-0000-4000-8000-0000000f0001', 'en', 'Which club has won the most UEFA Champions League titles?',
   '["AC Milan","Real Madrid","Bayern Munich","Liverpool"]', 1,
   E'15 titles. Real Madrid''s most recent came in 2024 — more than double the next club''s tally.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0002', 'en', E'Who has won the most Ballon d''Or awards?',
   '["Cristiano Ronaldo","Lionel Messi","Michel Platini","Pelé"]', 1,
   E'Messi has eight; Ronaldo has five. Pelé never won one — the award was European-players-only for most of his career.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0003', 'en', 'Which country hosted the 1994 FIFA World Cup?',
   '["Mexico","USA","Italy","France"]', 1,
   'The USA. It still holds the highest average attendance of any World Cup, nearly 69,000 a game.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0004', 'en', 'Which nation has won the most World Cups?',
   '["Germany","Italy","Brazil","Argentina"]', 2,
   'Brazil, with five. They are also the only team to have played in every tournament.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0005', 'en', 'How many players are on the pitch per team at kick-off?',
   '["9","10","11","12"]', 2,
   'Eleven, one of whom must be the goalkeeper. A team drops to nine before the match is abandoned.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0006', 'en', 'Who won the first ever Premier League season, in 1992–93?',
   '["Manchester United","Arsenal","Blackburn Rovers","Aston Villa"]', 0,
   E'Manchester United, ending a 26-year wait for a league title. They''d go on to win 13 of the first 21.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0007', 'en', 'What is awarded to the top scorer at a World Cup?',
   '["Golden Ball","Golden Boot","Golden Glove","Bronze Ball"]', 1,
   'The Golden Boot. The Golden Ball goes to the best player and the Golden Glove to the best goalkeeper.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0008', 'en', 'In which city is the Maracanã stadium?',
   '["São Paulo","Buenos Aires","Rio de Janeiro","Lisbon"]', 2,
   'Rio de Janeiro. Its 1950 World Cup final drew a crowd officially recorded at 173,850.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0009', 'en', 'How many goals make a hat-trick?',
   '["2","3","4","5"]', 1,
   'Three in one match. The term was borrowed from cricket, where a bowler taking three wickets won a hat.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0010', 'en', 'Which club plays its home games at the Camp Nou?',
   '["Real Madrid","Barcelona","Valencia","Sevilla"]', 1,
   E'Barcelona. It is Europe''s largest stadium, seating just under 100,000.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0011', 'en', 'What does a second yellow card in one match result in?',
   '["A penalty","A red card","A warning","A free kick"]', 1,
   'A red card, and the player leaves the pitch. Their team plays on with ten and cannot replace them.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0012', 'en', 'What does VAR stand for?',
   '["Video Assistant Referee","Verified Action Review","Visual Angle Replay","Video Appeal Ruling"]', 0,
   'Video Assistant Referee, first used at a World Cup in 2018.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0013', 'en', 'How far is the penalty spot from the goal line?',
   '["10 yards","11 yards","12 yards","14 yards"]', 2,
   'Twelve yards, about 11 metres — unchanged since the penalty kick was introduced in 1891.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0014', 'en', E'A "continental treble" means winning which three in one season?',
   '["League, domestic cup, continental cup","League, super cup, world cup","Three consecutive leagues","Cup, super cup, shield"]', 0,
   'The league, the main domestic cup and the continental competition — all in a single season.', 'approved'),
  ('00000000-0000-4000-8000-0000000f0015', 'en', 'Where may a goalkeeper legally handle the ball?',
   '["Anywhere in their own half","Inside their own penalty area","Inside the six-yard box only","Anywhere on the pitch"]', 1,
   'Only inside their own penalty area. Handling it outside is a free kick, and often a red card.', 'approved')
on conflict (question_id, locale) do nothing;

-- ============================================================================
-- QUESTIONS — Solar System (MockQuestions.solarSystem, all 9 text/image
-- questions, plus the Urdu RTL proof question)
-- ============================================================================

insert into public.questions (id, subcategory_id, kind, difficulty, status, media_url)
values
  ('00000000-0000-4000-8000-0000000a0001', '00000000-0000-4000-8000-000000000201', 'text',  1, 'live', null),
  ('00000000-0000-4000-8000-0000000a0002', '00000000-0000-4000-8000-000000000201', 'image', 2, 'live', null),
  ('00000000-0000-4000-8000-0000000a0003', '00000000-0000-4000-8000-000000000201', 'text',  1, 'live', null),
  ('00000000-0000-4000-8000-0000000a0004', '00000000-0000-4000-8000-000000000201', 'text',  3, 'live', null),
  ('00000000-0000-4000-8000-0000000a0005', '00000000-0000-4000-8000-000000000201', 'image', 2, 'live', null),
  ('00000000-0000-4000-8000-0000000a0006', '00000000-0000-4000-8000-000000000201', 'text',  4, 'live', null),
  ('00000000-0000-4000-8000-0000000a0007', '00000000-0000-4000-8000-000000000201', 'text',  3, 'live', null),
  ('00000000-0000-4000-8000-0000000a0008', '00000000-0000-4000-8000-000000000201', 'text',  4, 'live', null),
  ('00000000-0000-4000-8000-0000000a0009', '00000000-0000-4000-8000-000000000201', 'text',  5, 'live', null)
on conflict (id) do nothing;

insert into public.question_i18n (question_id, locale, prompt, options, correct_index, explanation, review_state)
values
  ('00000000-0000-4000-8000-0000000a0001', 'en', 'Which is the largest planet in the Solar System?',
   '["Saturn","Jupiter","Earth","Mars"]', 1,
   'Jupiter — more than twice as massive as every other planet in the Solar System put together.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0002', 'en', 'Which planet is this?',
   '["Saturn","Uranus","Neptune"]', 0,
   E'Saturn. Its rings are mostly water ice, and they''re only about ten metres thick.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0003', 'en', 'Which planet is known as the Red Planet?',
   '["Venus","Mars","Mercury","Jupiter"]', 1,
   'Mars. The colour comes from iron oxide — rust — across its surface.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0004', 'en', 'Which planet has the shortest day in the Solar System?',
   '["Mercury","Jupiter","Earth","Venus"]', 1,
   'Jupiter turns once in under ten hours, despite being the largest planet.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0005', 'en', 'Which body is shown here?',
   '["The Moon","Europa","Titan"]', 0,
   E'Earth''s Moon. It is drifting away from us at about 3.8 cm a year.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0006', 'en', 'Which is the hottest planet in the Solar System?',
   '["Mercury","Venus","Mars","Jupiter"]', 1,
   'Venus, at about 465°C. Its thick carbon-dioxide atmosphere traps more heat than Mercury gets from being closer to the Sun.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0007', 'en', 'How many planets in the Solar System have ring systems?',
   '["One","Two","Four","Eight"]', 2,
   E'Four — Jupiter, Saturn, Uranus and Neptune. Saturn''s are simply the only ones bright enough to see easily.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0008', 'en', 'The asteroid belt lies between which two planets?',
   '["Earth and Mars","Mars and Jupiter","Jupiter and Saturn","Venus and Earth"]', 1,
   E'Mars and Jupiter. Everything in it together weighs less than Earth''s Moon.', 'approved'),
  ('00000000-0000-4000-8000-0000000a0009', 'en', 'What type of star is the Sun?',
   '["Red giant","White dwarf","Yellow dwarf","Blue supergiant"]', 2,
   'A yellow dwarf, or G-type main-sequence star — about halfway through its life.', 'approved')
on conflict (question_id, locale) do nothing;

-- The Urdu RTL proof question — a second locale row on a question that also
-- has an English row, exactly like the app's mock: it is Question `sub`
-- content, translated, not a separate question.
insert into public.question_i18n (question_id, locale, prompt, options, correct_index, explanation, review_state)
values
  ('00000000-0000-4000-8000-0000000a0001', 'ur', 'نظامِ شمسی میں سب سے بڑا سیارہ کون سا ہے؟',
   '["زحل","مشتری","زمین","مریخ"]', 1,
   'مشتری — یہ باقی تمام سیاروں کے مجموعے سے بھی دوگنا بھاری ہے۔', 'approved')
on conflict (question_id, locale) do nothing;

-- ============================================================================
-- ACHIEVEMENTS (core/mock/mock_badges.dart's MockBadges.all, all 12, verbatim
-- name/emoji/description/gradient/rarity). `criteria` encodes only the rules
-- the mock phase actually implements server-side (see
-- functions_and_triggers.sql's _check_level_achievements); the rest carry a
-- best-effort machine-checkable shape as a starting point — most will need a
-- real rule written once the feature they depend on (duels, streak, IQ
-- category tracking) has real data to evaluate against.
-- ============================================================================

insert into public.achievements (id, name, emoji, description, gradient_from, gradient_to, category, rarity_percent, coin_reward, criteria)
values
  ('badge_sharpshooter', 'Sharpshooter', '🎯', 'Finish a level with 20/20 correct answers.', '#FFD84D', '#F0A500', 'skill', 4.0, 500, '{"type":"level_flawless"}'),
  ('badge_night_owl', 'Night Owl', '🌙', 'Play after midnight five nights in a row.', '#7B4DFF', '#2BB3FF', 'streak', 18.0, 300, '{"type":"midnight_streak","nights":5}'),
  ('badge_quick_draw', 'Quick Draw', '⚡', 'Average under 3 seconds per answer in a level.', '#12C79B', '#7BE495', 'skill', 22.0, 300, '{"type":"avg_answer_seconds_under","seconds":3}'),
  ('badge_week_warrior', 'Week Warrior', '🔥', 'Complete every daily challenge for 7 days straight.', '#FF8A24', '#FF3D6E', 'streak', 15.0, 400, '{"type":"daily_streak","days":7}'),
  ('badge_big_brain', 'Big Brain', '🧠', 'Score 100% on ten different IQ levels.', '#2BB3FF', '#7B4DFF', 'skill', 9.0, 500, '{"type":"category_flawless_count","category_slug":"iq","count":10}'),
  ('badge_category_king', 'Category King', '👑', 'Reach Level 20 with three stars in every subcategory of a single category.', '#7B4DFF', '#2BB3FF', 'rare', 2.1, 2000, '{"type":"category_three_star_sweep"}'),
  ('badge_centurion', 'Centurion', '💯', 'Answer 100 questions correctly in a row across any levels.', '#FF8A24', '#FF3D6E', 'skill', 4.5, 1500, '{"type":"cross_level_correct_streak","count":100}'),
  ('badge_globetrotter', 'Globetrotter', '🌍', 'Play at least one level in every category.', '#12C79B', '#2BB3FF', 'social', 8.0, 1200, '{"type":"category_coverage","count":"all"}'),
  ('badge_duelist', 'Duelist', '⚔️', 'Win 10 duels against other players.', '#FF3D6E', '#7B4DFF', 'social', 6.3, 1000, '{"type":"duel_wins","count":10}'),
  ('badge_scholar', 'Scholar', '🦉', 'Reach Level 20 in five different subcategories.', '#2BB3FF', '#12C79B', 'skill', 3.2, 1800, '{"type":"subcategory_level20_count","count":5}'),
  ('badge_rocket', 'Rocket', '🚀', 'Finish a whole level averaging under 2 seconds per answer.', '#FFC61A', '#FF8A24', 'skill', 12.0, 1000, '{"type":"avg_answer_seconds_under","seconds":2}'),
  ('badge_flawless', 'Flawless', '💎', 'Complete a perfect week — every daily challenge, zero wrong answers.', '#2BB3FF', '#7B4DFF', 'rare', 1.8, 2500, '{"type":"perfect_week"}'),
  -- Not in the mock's fixed 12, but referenced by _check_level_achievements
  -- (QuizResultApi._badgesFor in the mock build unlocks these two too):
  ('badge_on_fire', 'On Fire', '🔥', 'Hit a 10-answer streak inside a single level.', '#FF8A24', '#FF3D6E', 'skill', 20.0, 200, '{"type":"in_level_streak","streak":10}'),
  ('badge_boss_slayer', 'Boss Slayer', '👹', 'Clear a boss level (every 5th level).', '#7B4DFF', '#2BB3FF', 'skill', 25.0, 200, '{"type":"boss_clear"}')
on conflict (id) do nothing;

-- ============================================================================
-- RANK TITLES — PLACEHOLDER. Only the level-12 fixture the app's own mock
-- data (MockPlayer.rankTitle = 'Curious Mind') and the design bible's home
-- screen mock ("Level 12 · Curious Mind") confirm is levels 10-14. Every
-- other band below is invented to fill the ladder and MUST be replaced with
-- the real table from Design Bible §19 "Scoring & progression math" before
-- shipping — the shape (contiguous, non-overlapping bands) is what matters
-- for the schema; the words are not authoritative.
-- ============================================================================

insert into public.rank_titles (min_level, max_level, title) values
  (1, 4, 'Rookie'),
  (5, 9, 'Apprentice'),
  (10, 14, 'Curious Mind'),
  (15, 19, 'Sharp Mind'),
  (20, 29, 'Trivia Ace'),
  (30, 39, 'Quiz Master'),
  (40, 59, 'Grandmaster'),
  (60, 99, 'Legend'),
  (100, 999, 'Quizoo Icon')
on conflict (min_level) do nothing;

-- ============================================================================
-- STREAK MILESTONES (daily_api.dart's fixture StreakStatus.milestones)
-- ============================================================================

insert into public.streak_milestones (days, reward_label, coin_reward, gem_reward) values
  (14, '1,000 🪙', 1000, 0),
  (30, '10 💎 + badge', 0, 10)
on conflict (days) do nothing;

-- ============================================================================
-- TODAY'S DAILY CHALLENGE — so the app has one to show immediately after
-- connecting. daily-rollover (functions_and_triggers.sql) takes over from
-- here every night at 00:00 UTC.
-- ============================================================================

insert into public.daily_challenges (challenge_date, question_ids, title, seconds_per_question, coin_reward, xp_reward)
select
  (now() at time zone 'utc')::date,
  array_agg(id),
  'Mixed Bag', 20, 300, 500
from (
  select id from public.questions where status = 'live' order by random() limit 10
) sub
on conflict (challenge_date) do nothing;

commit;
