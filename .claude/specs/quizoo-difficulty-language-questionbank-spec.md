# Change Request: 50-Level Difficulty Ladder, Anti-Repeat Question Bank, Countdown/Read-Aloud Gameplay & Multi-Language Content Model

**Project:** Quizoo · **Status:** Ready for implementation · **Author:** Claude (cloud session), drafted without a live Supabase connection — see "Before you run anything" below.

**Companion files (delivered alongside this document):**
- `supabase/migrations/0003_difficulty_ladder_v2.sql`
- `supabase/migrations/0004_multilingual_content_model.sql`
- `supabase/migrations/0005_question_bank_and_anti_repeat.sql`

This is one spec covering all four requested changes, because they touch the same tables and the same level-start flow — specifying them separately would mean re-explaining the same schema three times.

---

## 0. Before you run anything

This session has no live connection to your Supabase project (no MCP server here). Every script below was written carefully and reasoned through, but **not executed against your actual schema**. Before applying any of it:

1. Have your Supabase-MCP-connected agent inspect the live schema first — specifically `categories`, `subcategories`, `questions`, `taxonomy_i18n`, `question_i18n`, `level_progress`, `level_attempts`, and whether `difficulty_tiers` / `ai_providers` / `generated_question_sets` already exist (i.e., whether migrations `0001`/`0002` from the earlier AI-questions spec were actually applied — you told me you're not sure).
2. Reconcile any column-name differences between what's assumed here and what actually exists — the scripts use `IF NOT EXISTS` / existence-checked constraints throughout specifically so mismatches fail loudly instead of silently, but they can't catch everything.
3. Run against a staging project or a Supabase branch first, not production directly.
4. Take a snapshot/backup before running against production.

---

## 1. Decisions locked before writing this spec

Three questions were resolved with you directly before touching schema, because getting them wrong meant redoing the data model:

1. **Difficulty ladder shape:** bounded at **50 levels total**, not the unbounded "Master (L41+, infinite)" tier from `realtime-ai-questions-spec.md`. Each of the 5 tiers gets exactly 10 levels. This **supersedes** that earlier spec's §2.

2. **Question sourcing model:** the **curated question bank with per-user anti-repeat tracking is now the primary runtime source** — not live per-attempt AI generation. Solo levels draw from a stored, growing pool of authored questions; AI generation (if used) becomes an **offline/batch content-authoring tool**, never called during gameplay. This **supersedes** that earlier spec's §1.2 and §3.

3. **Migration status unknown:** every script here is defensive/idempotent so it's safe whether `0001`/`0002` were applied or not.

**Naming the new difficulty tier:** you asked me to suggest a name, and to reorder if I judge "Expert" sounds like the hardest tier. In standard skill-progression naming (novice → apprentice → expert → **master**, used across games, martial arts, and certifications), "Master" reads as *beyond* expert — someone who has mastered the subject, not merely someone highly skilled. So: **Expert keeps its current position** (4th, 15s), and the new hardest tier is named **Master** (5th, 10s). This also matches the name already chosen for this exact tier in the earlier AI-questions spec, so there's no unexplained rename floating around your codebase.

---

## 2. Difficulty & level restructuring

### 2.1 The ladder

| Tier | Code | Seconds/question | Levels | Boss level |
|---|---|---|---|---|
| 1 | `easy` | 30s | 1–10 | 10 |
| 2 | `medium` | 25s | 11–20 | 20 |
| 3 | `hard` | 20s | 21–30 | 30 |
| 4 | `expert` | 15s | 31–40 | 40 |
| 5 | `master` | 10s | 41–50 | 50 |

**50 levels total per subcategory** (up from 20). Stored in `difficulty_tiers` (migration `0003`) — not hardcoded in the app — so retuning a tier's seconds, or inserting a new tier between two existing ones, is a Supabase table edit, not an app release. `get_difficulty_for_level(level)` (SQL function) is the single source of truth the app and backend both read.

**Boss levels** are simply the last level of each tier — 10/20/30/40/50 — read from `is_boss_level(level)`, driven by `app_settings.boss_level_interval` (seeded to 10). Replace any hardcoded `level IN (5,10,15,20)` boss check in `submit-level` with a call to this function.

### 2.2 Why bounded, and what it simplifies

Because the ladder is finite, several things that the earlier (unbounded) spec had to solve for become unnecessary:

- **No infinite-scroll level map.** The level map can render all 50 nodes directly (or 50 nodes with 5 collapsible tier headers) — no rolling-window pagination logic needed.
- **No score-multiplier freeze.** The earlier spec froze `diffMult` at level 40's value to stop an unbounded ladder from producing absurd multipliers at, say, level 500. With a hard ceiling at level 50, the plain formula is safe on its own:
  ```
  diffMult = 1 + (level - 1) * 0.05     -- max x3.45 at level 50
  ```
  **If that freeze was already applied to `submit-level`, it needs to be reverted** — left in place, it would cap every Master-tier level (41–50) at x2.95 instead of the correct, slightly higher value, silently under-scoring your best players. See the migration file's closing comment for the exact before/after.
- **Simple sequential unlocking, unchanged.** Level *N* unlocks when level *N−1* is completed — same as before, all the way to 50, then it stops.

### 2.3 Questions per level: a setting, not a hardcoded 20

Requirement 2 asked for this explicitly, and it's addressed as part of §3 below (same `app_settings.questions_per_level` table serves both). Editable live from the Supabase dashboard, takes effect on the very next level start, no redeploy.

---

## 3. Question bank & anti-repeat algorithm

### 3.1 The model

Every (subcategory, difficulty tier, language) has a **growing pool of authored questions** stored in `questions`. Your stated target is hundreds to thousands of questions per pool over time. When a player starts a level, the backend picks `N` questions from that pool **for that specific user**, strongly preferring ones they haven't seen — and when they've seen everything, preferring the ones they saw *longest ago* rather than the ones they just saw a minute earlier.

This is tracked per user in a new table, `user_question_history` (one row per user × question, with `times_seen` and `last_seen_at`), and every attempt's exact served-question-set is recorded in `level_attempt_question_sets` so grading later can look up the real answer key without ever having shipped it to the client.

### 3.2 The algorithm

The entire "don't repeat" requirement collapses into **one ordering rule**, implemented in the `get_level_questions()` SQL function (migration `0005`):

> Order the eligible question pool by `last_seen_at ASC NULLS FIRST` (a never-seen question sorts before any seen one), take the top `N`.

That single rule handles both edge cases you described, with no special "pool exhausted" branch:

- **Normal case** — plenty of unseen questions: the never-seen ones (`last_seen_at IS NULL`) always sort first, so a player essentially never repeats a question while fresh ones remain.
- **Edge case — power user has seen everything in a pool:** once every question has a `last_seen_at`, the same ordering rule just serves the *least recently seen* ones first. There's no explicit "reset" step — it's a continuous rotation, always cycling back to whatever's gone longest without being shown. This is what you described as "allowed to rotate and show same questions at random" — except it's not random, it's the *oldest* repeats first, which feels far less repetitive in practice than true randomness would.
- **Edge case — pool smaller than N** (e.g. a level needs 20 but only 12 questions exist for that subcategory/tier/language): the ranked pool is **tiled** with modulo indexing (`((n-1) % pool_size) + 1`) so the level still gets exactly N questions, cycling through the available ones evenly rather than erroring or under-filling. The served set is flagged `is_repeat_padded = true` for observability (see §3.4).

After serving, `user_question_history` is upserted for every question shown (`times_seen += 1`, `last_seen_at = now()`), and `level_attempt_question_sets` records the exact ordered array of `question_ids` served, tagged with an `attempt_id`.

### 3.3 Configuring N

`app_settings.questions_per_level` (jsonb, seeded to `20`) is the global default — editable directly in the Supabase table editor, live, no redeploy. `difficulty_tiers.override_questions_per_level` lets you set a *different* N for one specific tier if you ever want e.g. shorter Master-tier levels — leave it `null` to fall back to the global default.

### 3.4 Watching for thin pools

`v_thin_question_pools` (a view, migration `0005`) surfaces every (subcategory, difficulty tier, language) combination with fewer than 3× the default questions-per-level worth of live questions — i.e., pools where repeats are already common or imminent. Query it periodically to see exactly where to prioritize authoring more content, rather than guessing.

### 3.5 Anti-cheat, preserved

The client never receives `correct_index` — `get_level_questions()` returns only `prompt` and `options`. The answer key lives in `questions` (never exposed to clients via RLS) and is looked up server-side by `submit-level` via the `question_ids` array recorded in `level_attempt_question_sets`. **Grade by matching each submitted answer to its `question_id` explicitly — never by array position** — `question_ids`/`options` order isn't guaranteed to correspond to submission order.

### 3.6 What happens to the AI-generation infrastructure from the earlier spec

Nothing needs to be torn down — it's repurposed, not discarded. `ai_providers`, the multi-provider fallback chain, the prompt contract (`prompt.ts`), and the JSON-shape validation from `realtime-ai-questions-spec.md` §3 are exactly the right tools for **filling the pool**, just triggered differently:

- **Before:** `generate-questions` was called live, once per level attempt, by the client.
- **Now:** the same generation logic runs as an **offline/batch job** — call it manually (an admin action, a CLI script, or a scheduled `pg_cron` job) for a given `(subcategory_id, difficulty_tier_id, language_code, count)`, and it writes candidate questions into `questions` with `status = 'draft'`, `source = 'ai_batch'`. A human reviews and flips qualifying rows to `status = 'live'` before they can ever be served (`get_level_questions()` only selects `status = 'live'`). This keeps the review gate the earlier spec already recommended for sensitive categories (Religion, etc.) — now applied to *all* AI-assisted content, since curated content is the primary path rather than a fallback.
- This is a light rename/retarget of the existing Edge Function's trigger, not a rewrite of its core generation logic — out of scope to fully re-spec here, but flagged so nothing gets silently orphaned.

---

## 4. Countdown, read-aloud & animated reveal

*(This section restates and slightly adapts §5 of `realtime-ai-questions-spec.md` — the design itself is unaffected by the question-sourcing pivot above, it just calls a different endpoint to get its questions.)*

### 4.1 Package

**`flutter_tts`** (pub.dev, free, MIT). Wraps `AVSpeechSynthesizer` (iOS) / Android's `TextToSpeech` engine — no API key, no network call, no server-side TTS needed. Supports English and Urdu now; Hindi, Arabic and French later via the same API (a locale string + authored content in that language, not new integration work) — ties directly into §5's multi-language model.

Handle `setLanguage` failure (some Android devices lack a voice pack for a given locale) by falling back to silent mode — skip straight to showing answers and starting the timer — rather than blocking the question screen.

### 4.2 Sequencing

1. Player taps a level → **3…2…1 countdown shows immediately.** In parallel, the app calls `rpc('get_level_questions', { p_subcategory_id, p_level, p_language_code })` (§3) as soon as the countdown starts — don't wait for it to finish before requesting.
2. If the response hasn't arrived by the time the countdown ends, navigate to the question screen anyway and show a skeleton loader in place of the question card/options until the payload lands. Don't block navigation on the network call.
3. Once questions are in hand and Q1 is showing:
   - **Audio on:** start TTS reading the question prompt aloud. On the "speech complete" callback, *then* start the per-question timer and reveal the answer options with a staggered entrance animation (fade + slide-up, ~70–90ms stagger per option).
   - **Audio off:** skip TTS entirely, reveal all options immediately, start the timer immediately — exactly like today's flow.
4. **Speaker icon** sits in the gameplay HUD. Tapping it flips a local (device-only, not server-side) audio preference that persists across sessions. Toggling off **mid-speech** stops TTS immediately (`flutter_tts.stop()`) and, if options haven't revealed yet, reveals them right away instead of waiting for a speech-complete callback that will now never fire.

### 4.3 Bloc/state notes

Add a `QuestionPhase` enum (`speaking → revealing → answering → answered`) driven by `flutter_tts`'s completion callback, not a widget-level `FutureBuilder` — this survives rebuilds the same way the existing `Ticker`-based timer does. **The timer only starts on entering `answering`**, never on question load — this is a behavior change from a design where the timer started immediately.

### 4.4 One content caveat carried forward

A question whose text would give away or garble the answer if read aloud (e.g. "which of these is spelled correctly") should be excluded from TTS regardless of the user's audio toggle. Add a `questions.tts_excluded boolean default false` flag (or reuse `subcategories.ai_generation_allowed`-style per-subcategory flagging for whole spelling-format subcategories) and check it client-side before invoking TTS.

---

## 5. Multi-language content model

### 5.1 The model: languages own content, they don't translate it

`categories`, `subcategories`, and `questions` are each **scoped to exactly one language** — not a shared row translated via an i18n join table. A French player and an English player see entirely independent category lists, subcategory lists, and question pools; there is no assumption that "Geography" in French is the same underlying row as "Geography" in English, just relabeled. This is a deliberate structural change from the Design Bible baseline's `taxonomy_i18n`/`question_i18n` translation-join pattern, per your explicit instruction that you don't want auto-translation and do want genuinely separate authored content per language.

- **`languages`** (new table): `code` (PK, ISO 639-1), `name`, `native_name`, `is_rtl`, `is_active`, `sort_order`. Seeded with `en` and `ur` active, `hi`/`ar`/`fr`/`es` present but inactive (scaffolded, ready to switch on the moment real content exists for them — no schema change needed to add a language, just author its content and flip `is_active`).
- **`categories`**: `language_code` FK added, `UNIQUE(language_code, slug)`. Every category belongs to exactly one language.
- **`subcategories`**: unchanged shape, but its language is now implicitly whatever language its parent `category_id` belongs to — no separate column needed, which makes it structurally impossible for a subcategory to disagree with its own category about language.
- **`questions`**: `language_code` FK added directly (plus `difficulty_tier_id`, `status`, `source`, `kind`, `options`, `correct_index`, `explanation` — folding in what used to live in `question_i18n`). Each row is standalone, complete content for one language. A trigger (`enforce_question_language_match`) rejects any insert/update where a question's `language_code` doesn't match its own subcategory's language, so this can't silently drift.

### 5.2 App-side behavior

Switching the app's language is switching which `language_code` the category/subcategory/question queries filter on — nothing more exotic than that. Because `subcategory_id` is itself language-scoped, a user's level progress in, say, French Geography and English Geography are naturally two separate `level_progress` rows against two different `subcategory_id`s — exactly matching your description of switching languages and finding a different, independently-progressed set of categories and subcategories.

### 5.3 Migrating existing EN/UR content

Two paths, and which one applies depends on something this session couldn't check (no live DB access):

- **If `categories`/`subcategories`/`questions` currently hold only placeholder/seed data** (plausible — the app hasn't launched, and the Design Bible describes the 14-categories/85-subcategories/400-questions target as a plan, not confirmed-seeded content): migration `0004` alone is enough. It backfills existing rows as `language_code = 'en'`, and you author real Urdu (and later Hindi/Arabic/French/Spanish) content directly in the new per-language shape.
- **If there's real, already-authored Urdu content sitting in `taxonomy_i18n`/`question_i18n` from before this change:** migration `0004` includes a commented-out template for pulling that content out into standalone per-language rows, deliberately left as a template rather than a run-it-blind script — this session doesn't know the actual column shape of those tables in your live project. Have your Supabase-MCP-connected agent confirm the real column names first (`select column_name from information_schema.columns where table_name = 'taxonomy_i18n'`), adapt the template, then run it.
- Either way, don't drop `taxonomy_i18n`/`question_i18n` yet — leave them in place as deprecated until you've confirmed nothing else reads them, then remove in a later cleanup migration.

---

## 6. Consolidated data model reference

- **New:** `languages`, `difficulty_tiers`, `app_settings`, `user_question_history`, `level_attempt_question_sets`, `v_thin_question_pools` (view).
- **Altered:** `categories` (+`language_code`) · `subcategories` (+`ai_generation_allowed`) · `questions` (+`language_code`, +`difficulty_tier_id`, +`status`, +`source`, +`kind`, +`options`, +`correct_index`, +`explanation`) · `level_progress` / `level_attempts` (level check constraint rebounded to `1..50`).
- **Deprecated, not dropped yet:** `taxonomy_i18n`, `question_i18n` (see §5.3) · `generated_question_sets`, `ai_providers`, `question_generation_logs` from the earlier spec are **kept** but repurposed per §3.6, not deprecated.

---

## 7. RLS & access summary

| Table | Client access | Notes |
|---|---|---|
| `languages`, `difficulty_tiers`, `app_settings` | `select` for everyone | Non-secret; the app needs these up front to render the level map and language picker |
| `categories`, `subcategories` | `select` for everyone (filtered by `language_code` client-side) | |
| `questions` | **none directly** | Client only ever receives sanitized question data via `get_level_questions()`, never a raw table query — this is the answer key |
| `user_question_history` | `select` own rows only | No client insert/update — only the SECURITY DEFINER function writes |
| `level_attempt_question_sets` | `select` own rows only | Same — written only by `get_level_questions()` / `submit-level` |

`get_level_questions()` is `SECURITY DEFINER`, so it can read the full `questions` table and write to the two tracking tables even though `authenticated` clients are locked out of doing either directly.

---

## 8. API / RPC contract

**Call:** `supabase.rpc('get_level_questions', { p_subcategory_id: uuid, p_level: int, p_language_code: text })`

Fired the moment the 3-2-1 countdown starts (§4.2).

**Response (rows):**
```json
[
  { "attempt_id": "uuid", "question_id": "uuid", "display_order": 1, "prompt": "...", "options": ["...", "...", "...", "..."] },
  { "attempt_id": "uuid", "question_id": "uuid", "display_order": 2, "prompt": "...", "options": ["...", "...", "...", "..."] }
]
```
Every row shares the same `attempt_id` — that's what the client echoes back on `submit-level` along with the player's answers (matched by `question_id`, not position) so the server can grade against `level_attempt_question_sets.question_ids` / `questions.correct_index`.

**Errors:** function raises (surfaces as a Postgres error via the RPC call) on: no authenticated user, no difficulty tier configured for the given level, or zero live questions for that subcategory/tier/language combination — the last one means that pool needs content before it can be played, which `v_thin_question_pools` should have already flagged.

---

## 9. Touch points in existing functions (not rewritten here)

- **`start-level`** — its "pick questions" responsibility moves entirely to `get_level_questions()`; either becomes a thin wrapper calling it, or the app calls it directly.
- **`submit-level`** — must read the answer key via `level_attempt_question_sets.question_ids` → `questions.correct_index` instead of the earlier spec's `generated_question_sets`; must revert the diffMult freeze (§2.2); must use `is_boss_level(level)`.
- **`matchmake` / `resolve-duel`** — out of scope for this change request's four points, but flagged: if duels should keep showing both players an identical set (per the earlier spec's decision), they need their own selection call scoped to whichever player initiates, and a design choice on whether "seen" history should be shared or per-player for duel fairness. Worth a short follow-up spec before touching duel code.

---

## 10. Rollout steps

1. Confirm baseline schema is applied (Design Bible §23), and check whether `0001`/`0002` from the earlier AI-questions spec were applied (§0).
2. Run `0003_difficulty_ladder_v2.sql`, then `0004_multilingual_content_model.sql`, then `0005_question_bank_and_anti_repeat.sql`, in that order, against a staging project/branch first.
3. Revert the `submit-level` diffMult freeze if it was applied (§2.2's closing note).
4. Author or migrate initial EN + UR content into the new per-language `questions` shape (§5.3) — enough per (subcategory, tier) to comfortably clear `v_thin_question_pools`'s threshold before relying on it for real players.
5. Wire the Flutter level-start flow to call `get_level_questions` instead of the old question-fetch path, and implement `flutter_tts` per §4.
6. Smoke test across a few levels spanning different tiers (e.g. 5, 25, 45) and confirm: no `correct_index` in the client response, a row lands in both `level_attempt_question_sets` and `user_question_history`, and replaying the same level shows different questions until the pool is exhausted.
7. Query `v_thin_question_pools` before wide content authoring begins, to prioritize where to write more questions first.

---

## 11. Open risks & recommendations

- **Guest/anonymous users and history persistence.** If guest play uses Supabase anonymous auth, `user_question_history` is keyed to that anonymous `auth.uid()`, which persists across app restarts on the same device but is lost on reinstall or device switch (until/unless the guest later links to a permanent account, which preserves the same UID and thus their history). Worth deciding whether that's acceptable or whether guest history should be device-keyed some other way.
- **Content volume is now load-bearing, not a fallback.** Because the curated pool is the *primary* runtime source rather than a fallback behind live AI generation, the anti-repeat system is only as good as how many questions actually exist per (subcategory, tier, language) — `v_thin_question_pools` exists specifically so this doesn't go unnoticed until players complain.
- **Duels weren't part of this change request** but do touch the same tables (§9) — recommend a short, focused follow-up before implementing duel question selection, rather than guessing at the fairness tradeoffs here.
- **Language rollout order.** Hindi/Arabic/French/Spanish are schema-ready (`languages` rows exist, inactive) but need real authored categories/subcategories/questions before `is_active` should flip to `true` — flipping it early would show players an empty or near-empty content tree.

---

## 12. Explicitly out of scope

- Rewriting `start-level`, `submit-level`, `matchmake`, `resolve-duel` in full — §9 lists the exact touch points instead.
- Retiring or dropping `taxonomy_i18n`/`question_i18n`, `generated_question_sets`/`ai_providers` — all deprecated-or-repurposed, not removed, pending verification.
- A duel-specific anti-repeat/fairness design (§11).
- An admin UI for content authoring/review beyond the Supabase table editor.
