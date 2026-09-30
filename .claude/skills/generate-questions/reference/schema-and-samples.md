# Quizoo question schema & content-calibration reference

Static reference data, captured from the live Quizoo Supabase project and the
Flutter `Question` domain model (`lib/features/quiz_play/domain/question.dart`)
on 2026-09-12. `SKILL.md` points here so the skill never has to re-read the
Flutter source or re-derive the schema at run time. If the live schema ever
changes, update this file — don't silently drift from it.

## Table: `questions` — the only table this skill writes to

| Column | Type | Rule |
|---|---|---|
| `id` | uuid | Generate with `gen_random_uuid()`. |
| `subcategory_id` | uuid | FK → `subcategories.id`. Must already exist — this skill never creates categories/subcategories. |
| `kind` | text | One of `text`, `image`, `audio`, `figure`. **This skill only ever writes `text`.** Image/audio/figure questions need real media assets and are out of scope. |
| `difficulty` | smallint | Legacy 1–5 scale, still required (`check (difficulty between 1 and 5)`). Must agree with `difficulty_tier_id` — see the mapping table below. |
| `difficulty_tier_id` | uuid | FK → `difficulty_tiers.id`. Resolve with a subquery on `code` (`(select id from difficulty_tiers where code = 'easy')`) — **never hardcode the UUID**, it can differ per environment. |
| `language_code` | text | FK → `languages.code`. **Must exactly equal the `language_code` of `subcategory_id`'s own category.** A DB trigger (`enforce_question_language_match`) rejects a mismatch at insert time with a hard error. |
| `status` | text | One of `draft`, `live`, `suspended`. Use `live`: the user's review of `review.md` *is* the approval gate, and running the SQL script is their explicit "save" action, so there's no reason to land it as `draft`. |
| `source` | text | One of `manual`, `ai_batch`, `legacy_migrated`. Always `ai_batch` for this skill's output. |
| `options` | jsonb | JSON array of strings. Length must be exactly **4** for `kind = 'text'` (a DB check constraint enforces this; `image` kind takes 3, not used here). |
| `correct_index` | smallint | 0–3, index into `options`. Check constraint: `between 0 and 3`. |
| `explanation` | text | Required, not optional. One sentence shown after every answer, right or wrong — per the domain model's own doc comment, "the single feature that turns a quiz into learning." |
| `prompt` | text | The question text itself. |
| `tts_excluded` | boolean | `false`. (Only set `true` for questions that lean on visuals a voice can't describe — never applies to `kind = 'text'`.) |
| `media_url`, `figure_svg`, `valid_until` | — | Leave `NULL` / omit — not used by `kind = 'text'`. |
| `seen_count`, `correct_count`, `avg_answer_ms`, `created_at` | — | Leave to column defaults — omit from the INSERT column list. |

## Table: `difficulty_tiers` (3 fixed rows) — the Easy/Medium/Hard mapping

| `code` | `label` | seconds/question | levels | questions/level | legacy `difficulty` int |
|---|---|---|---|---|---|
| `easy` | Easy | 20 | 1–10 | 10 | 1 |
| `medium` | Medium | 15 | 11–20 | 15 | 2 |
| `hard` | Hard | 10 | 21–30 | 20 | 3 |

## Table: `languages` — fallback snapshot only (prefer a live query when possible)

| `code` | name | native_name | `is_rtl` | `is_active` (as of 2026-09-12) |
|---|---|---|---|---|
| `en` | English | English | false | true |
| `ur` | Urdu | اردو | true | true |
| `hi` | Hindi | हिन्दी | false | false |
| `ar` | Arabic | العربية | true | false |
| `fr` | French | Français | false | false |
| `es` | Spanish | Español | false | false |

For an RTL language (`ur`, `ar`), the app renders option badges as **ا ب ج د**
instead of **A B C D** (`Question.urduKeys` in the domain model). Use the same
badges in `review.md` for an RTL-language batch, and write the actual
prompt/options/explanation text natively in that language and script — not a
literal word-for-word translation, and never mixed with English filler.

## Categories/subcategories are owned per-language, not shared/translated

Each language owns its **own** `categories` and `subcategories` rows — e.g.
the Urdu "Solar System" subcategory is a distinct row (distinct UUID) from
the English one, not a translation joined to it. Never assume a subcategory
id from one language applies to another, and never mix languages within one
generation batch.

## UI length guidance (soft, not a DB constraint)

The question card truncates the prompt at **3 lines with an ellipsis**
(`quiz_play_screen.dart`), and the app's real seed content keeps things short.
Match that style:
- Prompt: one clear sentence, ideally under ~110 characters.
- Each option: a short phrase, ideally under ~40 characters.

## Content-quality rules

- Exactly one unambiguous correct answer; three plausible-but-wrong
  distractors. Avoid "all of the above" / "none of the above" — awkward in a
  timed four-button UI.
- Vary `correct_index` across the batch — roughly even across 0–3, not
  sequential or patterned (don't let the correct answer always land on B).
- No duplicate or near-duplicate questions within one batch. If existing
  prompts for the same subcategory/language were fetched via MCP, don't
  repeat those facts either.
- Prefer evergreen facts. Avoid anything that reads as "currently"/"as of
  now" true unless pinned to a specific year/edition that makes it a fixed
  historical fact (e.g. "hosted the 1994 World Cup" is fine; "is currently
  ranked #1" is not).
- General-audience appropriate: no offensive, adult, or political-controversy
  content.
- The `explanation` should add one genuine extra detail, not just restate the
  correct option in different words (see the samples below for the pattern).

## Difficulty calibration + real sample questions (3 per tier)

These are **live, real rows** from Quizoo's own seed content (Football and
Solar System subcategories, English) — kept here purely to calibrate tone,
length, and how much harder each tier should feel. **Never re-output these
exact questions** as "new" generated content; they already exist in the
database.

### Easy (`easy`) — common knowledge; wrong options are obviously wrong
1. "Which nation has won the most World Cups?" — A) Germany B) Italy **C) Brazil ✓** D) Argentina
   *Brazil, with five. They are also the only team to have played in every tournament.*
2. "How many players are on the pitch per team at kick-off?" — A) 9 B) 10 **C) 11 ✓** D) 12
   *Eleven, one of whom must be the goalkeeper. A team drops to nine before the match is abandoned.*
3. "Which planet is known as the Red Planet?" — A) Venus **B) Mars ✓** C) Mercury D) Jupiter
   *Mars. The colour comes from iron oxide — rust — across its surface.*

### Medium (`medium`) — known by regular fans/hobbyists; plausible distractors
1. "Which club has won the most UEFA Champions League titles?" — A) AC Milan **B) Real Madrid ✓** C) Bayern Munich D) Liverpool
   *15 titles. Real Madrid's most recent came in 2024 — more than double the next club's tally.*
2. "Who has won the most Ballon d'Or awards?" — A) Cristiano Ronaldo **B) Lionel Messi ✓** C) Michel Platini D) Pelé
   *Messi has eight; Ronaldo has five. Pelé never won one — the award was European-players-only for most of his career.*
3. "Which country hosted the 1994 FIFA World Cup?" — A) Mexico **B) USA ✓** C) Italy D) France
   *The USA. It still holds the highest average attendance of any World Cup, nearly 69,000 a game.*

### Hard (`hard`) — the top tier: dedicated-enthusiast recall through niche/technical
facts — specific dates, named events, records, precise numbers, rules, and
terminology up through genuinely obscure trivia. Since Hard is now the summit
of the ladder (plan 020 retired the old Expert/Master tiers into it), its
range is wider than Easy/Medium's: draw from the full span below rather than
only its easiest end.
1. "Who won the first ever Premier League season, in 1992–93?" — **A) Manchester United ✓** B) Arsenal C) Blackburn Rovers D) Aston Villa
   *Manchester United, ending a 26-year wait for a league title. They'd go on to win 13 of the first 21.*
2. "What is awarded to the top scorer at a World Cup?" — A) Golden Ball **B) Golden Boot ✓** C) Golden Glove D) Bronze Ball
   *The Golden Boot. The Golden Ball goes to the best player and the Golden Glove to the best goalkeeper.*
3. "In which city is the Maracanã stadium?" — A) São Paulo B) Buenos Aires **C) Rio de Janeiro ✓** D) Lisbon
   *Rio de Janeiro. Its 1950 World Cup final drew a crowd officially recorded at 173,850.*
4. "What does VAR stand for?" — **A) Video Assistant Referee ✓** B) Verified Action Review C) Visual Angle Replay D) Video Appeal Ruling
   *Video Assistant Referee, first used at a World Cup in 2018.*
5. "A \"continental treble\" means winning which three in one season?" — **A) League, domestic cup, continental cup ✓** B) League, super cup, world cup C) Three consecutive leagues D) Cup, super cup, shield
   *The league, the main domestic cup and the continental competition — all in a single season.*
6. "Where may a goalkeeper legally handle the ball?" — A) Anywhere in their own half **B) Inside their own penalty area ✓** C) Inside the six-yard box only D) Anywhere on the pitch
   *Only inside their own penalty area. Handling it outside is a free kick, and often a red card.*
