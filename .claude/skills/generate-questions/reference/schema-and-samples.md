# Quizoo question schema & content-calibration reference

Static reference data, captured from the live Quizoo Supabase project and the
Flutter `Question` domain model (`lib/features/quiz_play/domain/question.dart`)
on 2026-09-12, extended for image/figure questions on 2026-10-05. `SKILL.md`
points here so the skill never has to re-read the Flutter source or re-derive
the schema at run time. If the live schema ever changes, update this file —
don't silently drift from it.

## Table: `questions` — the only table this skill writes to

| Column | Type | Rule |
|---|---|---|
| `id` | uuid | Generate with `gen_random_uuid()` for `text`/`figure` rows. For `image` rows, use the **pre-generated UUID that matches the storage object path** — do not let the DB regenerate it. |
| `subcategory_id` | uuid | FK → `subcategories.id`. Must already exist — this skill never creates categories/subcategories. |
| `kind` | text | One of `text`, `image`, `audio`, `figure`. This skill writes `text` (default mode), `image` (`-mode image`/`all`), and `figure` (`-mode pattern`/`all`). `audio` is out of scope. |
| `difficulty` | smallint | Legacy 1–5 scale, still required (`check (difficulty between 1 and 5)`). Must agree with `difficulty_tier_id` — see the mapping table below. |
| `difficulty_tier_id` | uuid | FK → `difficulty_tiers.id`. Resolve with a subquery on `code` (`(select id from difficulty_tiers where code = 'easy')`) — **never hardcode the UUID**, it can differ per environment. |
| `language_code` | text | FK → `languages.code`. **Must exactly equal the `language_code` of `subcategory_id`'s own category.** A DB trigger (`enforce_question_language_match`) rejects a mismatch at insert time with a hard error. |
| `status` | text | One of `draft`, `live`, `suspended`. Defaults: `live` for `text` rows (review is the gate, as before); **`draft` for `image`/`figure` rows** until the app can render `media_url` / `figure_svg` in play mode — `live` only if the user explicitly overrides at Step 5. `start_level_attempt` and the daily-challenge generator only deal `live` rows. |
| `source` | text | One of `manual`, `ai_batch`, `legacy_migrated`. Always `ai_batch` for this skill's output. |
| `options` | jsonb | JSON array of strings. Length is **exactly 4** for every kind **except `image`, which must be exactly 3** (DB check constraint: `case when kind = 'image' then 3 else 4 end`). |
| `correct_index` | smallint | 0–3 (check constraint). Realistically `image` rows use 0–2 (three options). |
| `media_url` | text | For `kind = 'image'`: the **uploaded public Supabase Storage URL** — `<project_url>/storage/v1/object/public/question-media/<language_code>/<question_id>.<jpg|png>`. NULL for every other kind. **Never a source-site hotlink.** |
| `figure_svg` | text | For `kind = 'figure'`: the self-contained inline SVG markup for the pattern question (see § "Pattern (figure) authoring spec"). NULL for every other kind. |
| `explanation` | text | Required, not optional. One sentence shown after every answer, right or wrong — per the domain model's own doc comment, "the single feature that turns a quiz into learning." |
| `prompt` | text | The question text itself. |
| `tts_excluded` | boolean | `false` for text. For images: `false` when the prompt **and all three options are fully speakable** (e.g. "Which country's flag is this?" + country names); `true` when the answer hinges on visual distinctions speech can't carry. For `figure`: `true` by default (the answer lives in the artwork; spoken option labels like "A/B/C/D" are meaningless without sight). |
| `valid_until` | — | Leave NULL — not used by this skill. |
| `seen_count`, `correct_count`, `avg_answer_ms`, `created_at` | — | Leave to column defaults — omit from the INSERT column list. |

### Storage conventions (mirrors `generate-audios`)

- Bucket: `question-media` (public, already exists).
- Object path: `<language_code>/<question_id>.<ext>`, e.g.
  `en/6f1c...e9.jpg` — same shape as `question-audio`'s
  `<language_code>/<id>.mp3`.
- Public URL:
  `<project_url>/storage/v1/object/public/question-media/<language_code>/<question_id>.<ext>`
- Uploads go through `scripts/upload_question_media.py` with the project's
  `service_role` key (`x-upsert: true`, so a rerun is safe). The skill never
  touches the key value itself.
- Only JPEG/PNG are accepted (the future `Image.network` render has no SVG
  decoder; webp is also avoided for parity). Pattern SVGs are **not**
  uploaded — they live inline in `figure_svg`.

## Table: `difficulty_tiers` (3 fixed rows) — the Easy/Medium/Hard mapping

| `code` | `label` | seconds/question | levels | questions/level | legacy `difficulty` int |
|---|---|---|---|---|---|
| `easy` | Easy | 20 | 1–10 | 10 | 1 |
| `medium` | Medium | 15 | 11–20 | 15 | 2 |
| `hard` | Hard | 10 | 21–30 | 20 | 3 |

## Table: `languages` — fallback snapshot only (prefer a live query when possible)

| `code` | name | native_name | `is_rtl` | `is_active` (as of 2026-10-05) |
|---|---|---|---|---|
| `en` | English | English | false | true |
| `ur` | Urdu | اردو | true | true |
| `hi` | Hindi | हिन्दी | false | false |
| `ar` | Arabic | العربية | true | false |
| `fr` | French | Français | false | false |
| `es` | Spanish | Español | false | false |

For an RTL language (`ur`, `ar`), the app renders option badges as **ا ب ج د**
instead of **A B C D** (`Question.urduKeys` in the domain model). Use the same
badges in `review.html` for an RTL-language batch, and write the actual
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
- Image prompts must not restate what the image shows in a way that gives the
  answer away ("Which country's flag is shown?" is fine; "Which Asian island
  nation's flag is shown?" leaks).
- Pattern prompts are short ("Which figure completes the pattern?") because
  the work is in the artwork.

## Content-quality rules

- Exactly one unambiguous correct answer; plausible-but-wrong distractors.
  Avoid "all of the above" / "none of the above" — awkward in a timed
  four-button UI.
- Vary `correct_index` across the batch — roughly even across the allowed
  range (0–3, or 0–2 for image rows), not sequential or patterned.
- No duplicate or near-duplicate questions within one batch. If existing
  prompts for the same subcategory/language were fetched via MCP, don't
  repeat those facts either.
- For image runs, additionally: never reuse an existing `media_url` in the
  same subcategory; never reuse the same image twice in one batch.
- For pattern runs, additionally: never reuse the same underlying rule twice
  (in the batch or, insofar as existing `figure` prompts show, in the DB).
- Prefer evergreen facts. Avoid anything that reads as "currently"/"as of
  now" true unless pinned to a specific year/edition that makes it a fixed
  historical fact (e.g. "hosted the 1994 World Cup" is fine; "is currently
  ranked #1" is not).
- General-audience appropriate: no offensive, adult, or political-controversy
  content.
- The `explanation` should add one genuine extra detail, not just restate the
  correct option in different words (see the samples below for the pattern).
- Image licenses: **PD/CC0 only** (see `image-sources.md`). No logos,
  trademarks, currency, private individuals, or overlaid text.

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

## Image-question authoring samples (not in the DB — for calibration only)

Remember: image rows have **three** options, not four, and `correct_index`
must be 0–2. The prompt must not name the answer. Source/license is recorded
in `review.html`, never in the prompt/explanation.

1. *(subject: Taj Mahal, Wikimedia Commons PD)*
   - Prompt: "In which Indian city does this monument stand?"
   - Options: A) Delhi B) **Agra ✓** C) Jaipur
   - Explanation: "The Taj Mahal sits on the south bank of the Yamuna in Agra, built by Shah Jahan as a mausoleum for Mumtaz Mahal."
2. *(subject: Saturn, NASA image library)*
   - Prompt: "Which planet is shown here?"
   - Options: A) Jupiter B) **Saturn ✓** C) Neptune
   - Explanation: "Saturn's rings are mostly water ice and span about 280,000 km, yet are only around ten metres thick on average."
3. *(subject: Japan flag, FlagCDN)*
   - Prompt: "Which country's flag is this?"
   - Options: A) South Korea B) **Japan ✓** C) Bangladesh
   - Explanation: "Japan's flag shows a red sun disc, the Hinomaru, on white — officially adopted in 1999."

Distractor discipline for image questions: all three options must be
visually plausible *as answers* but only one can match the image; avoid the
"obviously wrong third option" trap, and never make two options that are the
same country/object.

## Pattern (`figure`) authoring spec (not in the DB — for calibration only)

Pattern questions are stored as `kind = 'figure'` with the artwork inline in
`figure_svg`, and **four** text options (the DB's constraint for non-image
kinds). The artwork itself contains the four candidate figures labelled
A–D (ا–د for RTL), and the text options are simply those labels. The
`explanation` states the rule.

### Required SVG properties

- Root element with explicit dimensions and a viewBox, e.g.
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360" width="640" height="360" role="img">`.
- Self-contained: shapes + text only; **no** `<script>`, `<image>`, external
  fonts, external stylesheets, or network references. Presentation attributes
  or a small inline `<style>` are fine.
- Neutral background (the app plate may add its own gradient behind it) —
  either a plain light rect or transparent.
- The full puzzle lives in one SVG: the sequence/matrix on the left/top and
  the four labelled options (A–D) in a row below or beside it. Labels must
  be inside the artwork and match the text options exactly.
- Keep it compact — target **< ~10 KB** per file. Prefer double quotes in
  attributes and avoid apostrophes (simplifies SQL string escaping, though
  `'` must still be doubled as `''` in `questions.sql`).
- Ensure the correct option is visually unambiguous once the rule is
  understood, and that wrong options each violate exactly one aspect of the
  rule (not "random noise").
- Never copy a known copyrighted puzzle (Raven's Progressive Matrices,
  published IQ-test items, other apps' patterns). Every artwork in a batch
  is an original design.

### Example (Easy — sequence completion, correct option B)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360" width="640" height="360" role="img">
  <rect width="640" height="360" fill="#F5F7FA"/>
  <g fill="none" stroke="#2BB3FF" stroke-width="6" stroke-linejoin="round">
    <path d="M60 150 L100 90 L140 150 Z"/>
    <path d="M180 90 h80 v60 h-80 Z"/>
    <circle cx="400" cy="120" r="40"/>
    <path d="M520 150 L560 90 L600 150 Z"/>
  </g>
  <g fill="none" stroke="#7B4DFF" stroke-width="6">
    <path d="M120 290 l30 -52 l30 52 Z"/>
    <path d="M280 238 h60 v104 h-60 Z"/>
    <circle cx="440" cy="290" r="34"/>
    <path d="M560 290 l30 -26 l30 26 l-30 26 Z"/>
  </g>
  <g fill="#1B2430" font-family="sans-serif" font-size="28" text-anchor="middle">
    <text x="150" y="340">A</text>
    <text x="310" y="340">B</text>
    <text x="480" y="340">C</text>
    <text x="590" y="340">D</text>
  </g>
</svg>
```

- Prompt: "Which figure continues the sequence?"
- Options: A) A B) **B ✓** C) C D) D
- Explanation: "The shapes repeat triangle → square → circle, so after the fourth figure restarts the cycle the next shape is the square."

(The example above is a throwaway calibration sketch — do not reuse it.
Real batches vary the rule, the correct option, and the visual vocabulary;
Easy uses one obvious rule, Medium combines two (e.g. shape + rotation),
Hard uses multi-step or lateral rules that are still unambiguously
solvable.)
