# Real Achievements & Badges

> Source spec: provided inline in conversation (`/do-plan` command args,
> 2026-09-19). The user wants the achievements/badges feature to be fully
> real: every badge's unlock criteria evaluated and granted server-side in
> Supabase, on completion of the actual gameplay milestone it names — not
> mocked, not manually seeded.
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full. Code may have moved on since it was
written (dated 2026-09-19), so spot-check the referenced files, function
definitions, and row counts still match before you begin — this plan was
grounded by live-querying the Supabase project (`list_tables`,
`pg_get_functiondef` on every relevant function) and reading every file
under `lib/features/achievements/`, `lib/features/duel/`, `lib/features/daily/`,
and `lib/features/quiz_result/`. Backend function bodies quoted below are
verbatim from the live database as of that date.

**This plan is bigger than it first looks.** Only 3 of 14 catalogued badges
are actually wired up server-side today; the other 11 have real criteria
sitting unused in the database. Execute this in the phase order below —
each phase is independently shippable and later phases depend on earlier
ones (the Flutter wiring in Phase 3 needs the RPC response shapes Phase 1
produces; the progress-hint work in Phase 4 is purely additive and can slip
without blocking the others).

## Objective

Every one of the 14 rows in `public.achievements` should unlock for a real
player the moment they satisfy its `criteria` JSONB — server-side, so it
can't be spoofed from the client — and grant its `coin_reward`/`gem_reward`
exactly once. The badge-unlocked celebration screen should fire for badges
earned via level play, duels, *and* the daily challenge (today it only
fires for level play). Every locked badge in the Achievements grid should
show a real "how close are you" hint, not just the one badge that has one
today. Players who already met a badge's criteria before this ships should
receive it immediately, not have to re-earn it.

## Scope

**In scope:**
- A generic, criteria-driven Postgres evaluation engine covering all 14
  badges, replacing/extending the existing partial `_check_level_achievements`.
- Wiring that engine into every relevant gameplay hook: level completion,
  bot duels, and the daily challenge / streak touch.
- A one-time backfill so existing player history is evaluated retroactively.
- Threading each hook's `newlyEarnedBadgeIds` result through the Flutter
  data layer for duels and the daily challenge (level play already does this).
- A shared "celebrate one or more newly-earned badges" navigation helper,
  used by level-complete, duel-result, and daily-result screens, replacing
  today's "only the first badge, only after a level" behavior.
- A real "closest progress" hint for all 14 badges in `AchievementsApi`
  (today only `badge_category_king` has one).
- Deleting the two now-fully-dead mock fixtures this audit reconfirms are
  unused (`core/mock/mock_badges.dart`, `core/mock/mock_api.dart`).

**Out of scope:**
- Adding new badges beyond the 14 already seeded in `public.achievements`.
- Real human matchmaking for Duel (badge_duelist counts *bot* duel wins
  today, per the existing `submit_bot_duel` design — untouched by this plan).
- Push notifications / in-app-notification rows when a badge unlocks (the
  `app_notifications` table's `kind` check constraint doesn't include an
  achievement kind today; adding one is a separate, explicit decision).
- Any change to the reward *amounts* (`coin_reward`/`gem_reward` columns) —
  this plan grants exactly what's already seeded.
- Admin/CMS tooling for authoring a 15th badge (the generic evaluator makes
  this easier later, but building an authoring UI is not part of this plan).

## Research findings

### The schema already exists and is mostly right

`public.achievements` (14 rows) and `public.user_achievements` are already
live:

```
achievements(id text pk, name, emoji, description, gradient_from, gradient_to,
  category text check in (skill,streak,social,rare), rarity_percent numeric,
  coin_reward int, gem_reward int, criteria jsonb)

user_achievements(user_id uuid, achievement_id text, progress jsonb default '{}',
  unlocked_at timestamptz null, primary key (user_id, achievement_id))
```

RLS: `achievements` is `select`-only to everyone; `user_achievements` is
`select`-only to its own `user_id` — **there is no insert/update policy for
the `authenticated` role on `user_achievements` at all.** Every write today
happens through a `security definer` function, which bypasses RLS. This
plan's new logic must follow the same pattern — do not add a client-writable
policy.

The `progress jsonb default '{}'` column already exists and is unused today
except as a container. This plan uses it as the running-counter store for
every stateful criterion (see Design overview) instead of adding new tables.

### The 14 criteria, verbatim from the live DB

```
badge_sharpshooter   {"type":"level_flawless"}                                  — LIVE (server-checked)
badge_on_fire        {"type":"in_level_streak","streak":10}                     — LIVE (server-checked)
badge_boss_slayer    {"type":"boss_clear"}                                      — LIVE (server-checked)
badge_duelist        {"type":"duel_wins","count":10}                            — LIVE (server-checked, ad hoc)
badge_week_warrior   {"type":"daily_streak","days":7}                           — UNIMPLEMENTED
badge_big_brain      {"type":"category_flawless_count","count":10,"category_slug":"iq"} — UNIMPLEMENTED
badge_category_king  {"type":"category_three_star_sweep"}                       — UNIMPLEMENTED (client only computes a progress *hint*, never grants)
badge_centurion      {"type":"cross_level_correct_streak","count":100}          — UNIMPLEMENTED
badge_flawless       {"type":"perfect_week"}                                    — UNIMPLEMENTED
badge_globetrotter   {"type":"category_coverage","count":"all"}                 — UNIMPLEMENTED
badge_night_owl      {"type":"midnight_streak","nights":5}                      — UNIMPLEMENTED
badge_quick_draw     {"type":"avg_answer_seconds_under","seconds":3}            — UNIMPLEMENTED
badge_rocket         {"type":"avg_answer_seconds_under","seconds":2}            — UNIMPLEMENTED
badge_scholar        {"type":"subcategory_level20_count","count":5}            — UNIMPLEMENTED
```

Only **2 rows** exist in `user_achievements` today (both `badge_on_fire`,
manually/organically earned by real test accounts) — confirming nothing
else has ever actually granted a badge, despite the catalogue's rarity
percentages implying otherwise.

### What's already wired, verbatim

`_check_level_achievements(p_user_id uuid, p_is_flawless boolean, p_longest_streak integer, p_is_boss boolean, p_is_complete boolean) returns text[]`,
called once at the very end of `submit_level_attempt`, after
`level_progress`/`score_events`/currency/XP/streak have all already been
committed for this attempt:

```sql
for v_id in select id from public.achievements
  where (criteria ->> 'type') in ('level_flawless','in_level_streak','boss_clear')
loop
  if (v_id = 'badge_sharpshooter' and p_is_flawless)
     or (v_id = 'badge_on_fire' and p_longest_streak >= 10)
     or (v_id = 'badge_boss_slayer' and p_is_boss)
  then
    insert into user_achievements (user_id, achievement_id, unlocked_at)
    values (p_user_id, v_id, now())
    on conflict (user_id, achievement_id) do nothing;
    if found then
      v_newly_unlocked := array_append(v_newly_unlocked, v_id);
      perform _grant_currency(p_user_id, 'coins', (select coin_reward ...), 'achievement_unlocked', null);
    end if;
  end if;
end loop;
```

`submit_bot_duel` has its own **inline, one-off** copy of this pattern for
`badge_duelist` (>= 10 bot wins), duplicating the insert/grant logic rather
than reusing `_check_level_achievements`. `_touch_daily_streak` (called
from both `submit_level_attempt` and `play_daily_challenge`, right after it
updates `profiles.streak_days`) has **no achievement check at all** — this
is why `badge_week_warrior` is unimplemented despite its exact source of
truth (`profiles.streak_days`) already being maintained correctly.

`submit_level_attempt` already computes, as local variables, everything
several of the unimplemented criteria need: `v_longest_streak` (per-attempt),
`v_correct_count`/`v_question_count`, `v_is_flawless`, `v_attempt.is_boss`,
`v_attempt.subcategory_id`/`v_attempt.level`, and — inside its per-answer
loop — `v_answer ->> 'secondsLeft'` against `v_seconds_total`
(`get_difficulty_for_level(level).seconds_per_question`), which is exactly
what an "average seconds per correct answer" computation needs.

### The Flutter side already has the plumbing for one badge at a time

`quiz_result`: `LevelResult.newlyEarnedBadgeIds` ← `quiz_result_api.dart`
reads it straight off `submit_level_attempt`'s response. `QuizResultCompleted.badgeToCelebrate`
is `result.newlyEarnedBadgeIds.firstOrNull` — **only the first badge in the
list ever gets a celebration**, silently dropping any others.
`level_complete_screen.dart`'s `_runChain()` (a `StatefulWidget`,
`initState` → `addPostFrameCallback`) awaits a 2.6s payout animation, then
`context.push(AppRoutes.badgeUnlockedPath(badgeId))` if there is one, then
chains into the save-progress sheet offer. This chain-runner pattern is
exactly what Phase 3 needs to replicate for duel and daily results.

`duel`: `submit_bot_duel`'s jsonb response **already includes**
`newlyEarnedBadgeIds`, but `DuelApi.submitBotDuel` (`duel_api.dart:113-117`)
constructs a `BotDuelRecord` with only `eloBefore`/`eloAfter`/`coinsEarned` —
the badge ids are silently discarded. `DuelResult` (`duel_result.dart`) has
no such field either, and `DuelResultScreen` is a plain `StatelessWidget`
with no chain-runner — it never navigates anywhere on its own.

`daily`: `play_daily_challenge` doesn't compute or return badge ids at all
today (not even a stub key). `DailyApi.play`/`DailyRepository.playToday`/
`DailyResult` have no such field. `DailyResultScreen` is also a plain
`StatelessWidget` with no chain-runner.

### The one existing progress-hint is a good template, not yet generalized

`AchievementsApi.fetchAll()` already joins `achievements` ⟕ `user_achievements`
for the caller and maps `isLocked = unlockedAt == null` — this part is
fully real. `_categoryKingProgress()` is the **only** per-badge "closest"
resolver implemented; it queries `level_progress` for 3-starred level-20
clears grouped by category, picks the player's best category, and returns
a `_ClosestProgress` (group label, fraction label, 0..1 progress, next
action label, next subcategory id) that maps directly onto
`BadgeProgress`'s nullable fields. Every other locked badge renders with
all of those fields `null` (the UI already handles this gracefully — see
`badge_detail_dialog.dart`).

### Testing conventions confirmed

`test/features/achievements/achievements_cubit_test.dart` uses `bloc_test` +
`mocktail`, mocking `AchievementsRepository` directly (not `AchievementsApi`)
— matches CLAUDE.md §11. There is no SQL/pgTAP test harness anywhere in
`supabase/` — backend function correctness in this repo is verified by
direct SQL execution against the live/branch database, not automated tests;
this plan's Testing strategy follows that existing convention rather than
inventing a new one.

## Assumptions & open questions

Confirmed via the interactive session (recommended option chosen for all):

- **Backfill on launch**: yes — a one-time migration evaluates every
  existing user's history and grants already-earned badges immediately.
- **Progress hints**: build a real "closest" hint for all 14 badges, not
  just Category King.
- **Celebration triggers**: wire Duel and Daily Challenge results into the
  Badge Unlocked screen, not just level completion.
- **Multiple simultaneous unlocks**: queue and show each one's celebration
  screen back-to-back.
- **Centurion's cross-level streak**: one lifetime running counter, reset
  only by a wrong answer or a non-`finished` attempt ending.
- **Quick Draw / Rocket**: averaged per single finished attempt (over
  correctly-answered questions only), not a lifetime average.
- **Globetrotter**: bar is "one finished level attempt in every active
  category," not full mastery.
- **Evaluator design**: one generic, criteria-driven function, not bespoke
  checks scattered across hook points.
- **Perfect Week**: 7 *consecutive calendar days*, each with ≥1 flawless
  level attempt.
- **Night Owl**: 5 distinct (not necessarily consecutive) nights, each
  qualifying by having ≥1 answer submitted between 00:00–02:59 **device
  local time**.
- **Scholar**: any finished attempt at level 20 (any star count) in 5
  distinct subcategories — not a 3-star requirement.

Still open / assumed without asking (flagged here for review before or
during implementation, since none of these materially changes scope —
they're implementation-detail defaults a reviewer may want to override):

1. **Quick Draw/Rocket require a *finished* attempt.** The criteria text
   doesn't say so explicitly, but every other level-triggered badge gates
   on `p_is_complete`; an incomplete/quit attempt still having "fast"
   answers before running out of hearts seems like the wrong thing to
   reward. Assumed: yes, gate on `is_complete`.
2. **Perfect Week's "day" boundary is UTC**, matching the existing
   `_touch_daily_streak`'s own `(now() at time zone 'utc')::date` — even
   though Night Owl explicitly uses device-local time per the confirmed
   answer above. These two badges use different clocks on purpose: Night
   Owl is inherently about the player's own night, Perfect Week is a
   day-counter like the existing streak machinery it sits next to.
3. **Night Owl's "night" bucket key is the server's UTC calendar date**,
   not the device's local calendar date, even though the *hour* check is
   device-local. A local midnight that straddles a UTC day boundary could
   in rare cases undercount two real local nights as one UTC-dated night.
   This is a cosmetic badge; the plan accepts this edge case rather than
   also threading a device-local date string through the RPC.
4. **Category King's "sweep" only re-checks the category the just-played
   subcategory belongs to**, not every category the player has ever
   touched — cheaper, and mathematically equivalent (no other category
   could have newly become swept by this attempt).
5. **The backfill assigns `unlocked_at` a best-effort historical
   timestamp** where cheaply derivable (e.g., the `created_at` of the
   qualifying `level_attempts`/`duels` row), and `now()` where a true
   historical moment isn't well-defined (e.g., Centurion's exact 100th
   correct answer requires a full chronological replay — see Phase 2).
   A reviewer who wants every backfilled `unlocked_at` to be `now()`
   uniformly (simpler, but loses "earned 3 weeks ago" framing) can trade
   simplicity for accuracy per-criterion during implementation.
6. **`badge_sharpshooter`'s progress hint has no natural fraction** (its
   criteria has no count) — Phase 4 gives it a "your best clear was N/M
   correct" hint instead of a X/Y count, same shape as today's fields but
   filled from the player's best (not-yet-flawless) attempt.

## Design overview

### Backend: one generic evaluator, three call sites

A single new function replaces ad hoc checks and centralizes unlock +
reward logic:

```sql
-- Idempotent unlock: returns true only the first time this user/achievement
-- pair transitions to unlocked. Grants coin_reward/gem_reward exactly once.
-- Does not touch `progress` — callers update that separately when relevant.
create or replace function public._unlock_achievement(
  p_user_id uuid, p_achievement_id text
) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_reward record;
begin
  insert into public.user_achievements (user_id, achievement_id, unlocked_at)
  values (p_user_id, p_achievement_id, now())
  on conflict (user_id, achievement_id) do update
    set unlocked_at = now()
    where public.user_achievements.unlocked_at is null;

  if not found then
    return false;
  end if;

  select coin_reward, gem_reward into v_reward
    from public.achievements where id = p_achievement_id;
  perform public._grant_currency(p_user_id, 'coins', v_reward.coin_reward, 'achievement_unlocked', null);
  if v_reward.gem_reward > 0 then
    perform public._grant_currency(p_user_id, 'gems', v_reward.gem_reward, 'achievement_unlocked', null);
  end if;
  return true;
end;
$$;

-- Merges a jsonb fragment into user_achievements.progress for a not-yet-
-- unlocked row, creating it if needed. Used by every stateful counter below.
create or replace function public._bump_achievement_progress(
  p_user_id uuid, p_achievement_id text, p_progress jsonb
) returns void
language sql security definer set search_path = public as $$
  insert into public.user_achievements (user_id, achievement_id, progress)
  values (p_user_id, p_achievement_id, p_progress)
  on conflict (user_id, achievement_id) do update
    set progress = p_progress
    where public.user_achievements.unlocked_at is null;
$$;

-- The evaluator. p_event in ('level_attempt','duel_result','streak_touch').
-- p_context's shape depends on p_event (see call sites below). Only
-- evaluates achievements not already unlocked for this user, and only the
-- criteria types relevant to p_event (cheap short-circuit per branch).
create or replace function public._evaluate_achievements(
  p_user_id uuid, p_event text, p_context jsonb
) returns text[]
language plpgsql security definer set search_path = public as $$
declare
  v_row record;
  v_newly text[] := '{}';
  -- level_attempt context locals
  ...
begin
  for v_row in
    select a.* from public.achievements a
    left join public.user_achievements ua
      on ua.user_id = p_user_id and ua.achievement_id = a.id
    where ua.unlocked_at is null
  loop
    case v_row.criteria ->> 'type'
      when 'level_flawless' then
        if p_event = 'level_attempt' and (p_context->>'isFlawless')::boolean then
          if public._unlock_achievement(p_user_id, v_row.id) then
            v_newly := array_append(v_newly, v_row.id);
          end if;
        end if;
      when 'in_level_streak' then
        -- unchanged from today, plus tracks a "best ever" progress counter
        -- for Phase 4's hint even before it's unlocked.
        ...
      when 'boss_clear' then ...
      when 'category_flawless_count' then ... -- badge_big_brain, see below
      when 'category_three_star_sweep' then ... -- badge_category_king
      when 'cross_level_correct_streak' then ... -- badge_centurion
      when 'perfect_week' then ... -- badge_flawless
      when 'category_coverage' then ... -- badge_globetrotter
      when 'midnight_streak' then ... -- badge_night_owl
      when 'avg_answer_seconds_under' then ... -- badge_quick_draw / badge_rocket
      when 'subcategory_level20_count' then ... -- badge_scholar
      when 'duel_wins' then
        if p_event = 'duel_result' then ... end if;
      when 'daily_streak' then
        if p_event = 'streak_touch' then ... end if;
      else null; -- forward-compatible: an unrecognized future type is a no-op, not an error
    end case;
  end loop;
  return v_newly;
end;
$$;
```

Each `when` branch's real body is specified per-badge below; the sketch
above is the file's skeleton (this is exactly how much SQL a plan should
contain — the implementer fills in each case using the per-badge design
that follows, not from scratch).

**Per-badge evaluation, one at a time:**

- **`badge_sharpshooter`** (`level_flawless`) — unchanged logic, ported
  into the new branch: `p_context->>'isFlawless'`.
- **`badge_on_fire`** (`in_level_streak: 10`) — unchanged unlock condition
  (`p_context->>'longestStreak' >= 10`). Additionally now calls
  `_bump_achievement_progress(user_id, 'badge_on_fire', jsonb_build_object('best', greatest(current_best, p_context->>'longestStreak')))` every attempt, purely so Phase 4 can show "best streak: 7/10" while locked.
- **`badge_boss_slayer`** (`boss_clear`) — unchanged (`p_context->>'isBoss'`).
- **`badge_big_brain`** (`category_flawless_count: 10, category_slug: "iq"`)
  — only relevant when `p_event='level_attempt'` and `isFlawless` and the
  attempt's subcategory belongs to a category whose `slug` matches
  `criteria->>'category_slug'` (join `subcategories`→`categories` on
  `p_context->>'subcategoryId'`). Bump `progress.count` by 1; unlock when
  it reaches `(criteria->>'count')::int`.
- **`badge_category_king`** (`category_three_star_sweep`) — only relevant
  when this attempt just made `level_progress` show `level=20, stars=3`
  for `p_context->>'subcategoryId'` (i.e. `p_context->>'level' = 20` and
  `p_context->>'stars' = 3`, both already known to the caller). Then check:
  every *active* subcategory in that subcategory's category has a
  `level_progress` row for this user with `level=20 and stars=3`. If so,
  unlock. (This subsumes and should replace `AchievementsApi._categoryKingProgress`'s
  query shape as the source of truth for *granting*; Phase 4 keeps a
  client-side query for the *hint* since the hint needs the player's
  *closest*, not-yet-swept category, which is a different query than "is
  any category fully swept".)
- **`badge_centurion`** (`cross_level_correct_streak: 100`) — needs the
  in-order correctness of *this* attempt's answers plus the stored running
  streak. `submit_level_attempt` must build and pass
  `p_context->'correctnessPattern'` — a JSON array of booleans, one per
  *answered* question, true if correct, in question order (assumed:
  skipped/timed-out questions count as a break, same as a wrong answer).
  The branch: read `(progress->>'streak')::int` (default 0), walk the
  array incrementing on `true` and resetting to 0 on `false`, then — if
  `p_context->>'ending' != 'finished'` — force it to 0 regardless of how
  the walk ended (an abandoned attempt breaks the streak even if its last
  answered question was correct). Store the result back via
  `_bump_achievement_progress`; unlock if it ever reached 100 during the
  walk (not just where it ended — a player could pass through 100 mid
  attempt and then abandon, which should still count).
- **`badge_flawless`** (`perfect_week`) — only relevant when `isFlawless`
  and `p_event='level_attempt'`. Progress shape:
  `{"streak": n, "lastDate": "YYYY-MM-DD"}` (UTC date, matching
  `_touch_daily_streak`'s clock — see Assumption 2). If `lastDate` is
  yesterday, `streak += 1`; if `lastDate` is today, no change (already
  counted); otherwise reset `streak = 1`. Unlock at `streak >= 7`.
- **`badge_globetrotter`** (`category_coverage: "all"`) — only relevant
  when `p_event='level_attempt'` and `isComplete`. Aggregate query, no
  stored progress needed: `count(distinct s.category_id) from level_attempts la join subcategories s on s.id=la.subcategory_id where la.user_id=p_user_id and la.ending='finished'` compared against `count(*) from categories where is_active`. Unlock when equal.
- **`badge_night_owl`** (`midnight_streak: 5`) — relevant on *every*
  `level_attempt` event (does not require `isComplete`) when
  `p_context->>'localHour'` is between 0 and 2 inclusive and at least one
  answer in the attempt has `action = 'answered'`. Progress shape:
  `{"nights": n, "lastNightDate": "YYYY-MM-DD"}` (server UTC date, per
  Assumption 3). If `lastNightDate` isn't today, `nights += 1` and update
  `lastNightDate`; unlock at `nights >= 5`.
- **`badge_quick_draw`** / **`badge_rocket`** (`avg_answer_seconds_under: 3 / 2`)
  — only relevant when `p_event='level_attempt'` and `isComplete`.
  `submit_level_attempt` must accumulate, during its existing per-answer
  loop, `v_correct_seconds_sum := v_correct_seconds_sum + (v_seconds_total - coalesce((v_answer->>'secondsLeft')::int, 0))` and `v_correct_seconds_count := v_correct_seconds_count + 1` whenever `v_is_correct`, and pass both into `p_context`. Branch: `avg := correctSecondsSum::numeric / nullif(correctSecondsCount,0)`; if `avg <= (criteria->>'seconds')::numeric` then unlock. Also `_bump_achievement_progress` with `{"bestAvgSeconds": least(prev, avg)}` for Phase 4's hint, run for every completed attempt regardless of whether it crosses the threshold.
- **`badge_scholar`** (`subcategory_level20_count: 5`) — only relevant
  when `p_event='level_attempt'`, `isComplete`, and `level = 20`. Aggregate,
  no stored progress: `count(distinct subcategory_id) from level_progress where user_id=p_user_id and level=20 and completed_at is not null` compared to `(criteria->>'count')::int`.
- **`badge_duelist`** (`duel_wins: 10`) — moves out of `submit_bot_duel`'s
  inline copy into this branch, evaluated when `p_event='duel_result'`.
  `p_context->>'totalBotWins'` is computed by the caller (same query
  `submit_bot_duel` already runs today). Also bumps
  `_bump_achievement_progress(user_id, 'badge_duelist', jsonb_build_object('wins', totalBotWins))` for Phase 4.
- **`badge_week_warrior`** (`daily_streak: 7`) — evaluated when
  `p_event='streak_touch'`, reading `profiles.streak_days` directly
  (already authoritative, no new tracking needed): unlock when
  `streak_days >= (criteria->>'days')::int`.

### Backend: the three call sites

1. **`submit_level_attempt`** — after its existing `level_progress` upsert
   and `_touch_daily_streak` call, replace the single
   `_check_level_achievements(...)` call with:
   ```sql
   v_new_badges := public._evaluate_achievements(v_user_id, 'level_attempt', jsonb_build_object(
     'subcategoryId', v_attempt.subcategory_id,
     'level', v_attempt.level,
     'stars', v_stars,
     'isComplete', v_is_complete,
     'isFlawless', v_is_flawless,
     'isBoss', v_attempt.is_boss,
     'ending', p_ending,
     'longestStreak', v_longest_streak,
     'correctnessPattern', to_jsonb(v_correctness_pattern),
     'correctSecondsSum', v_correct_seconds_sum,
     'correctSecondsCount', v_correct_seconds_count,
     'localHour', p_local_hour
   ));
   ```
   plus merge in whatever `_touch_daily_streak` itself now returns (see
   point 3). Requires three new local variables (`v_correctness_pattern
   boolean[] := '{}'`, `v_correct_seconds_sum integer := 0`,
   `v_correct_seconds_count integer := 0`), populated inside the existing
   per-answer loop, and **one new parameter**:
   `p_local_hour smallint default null` appended to `submit_level_attempt`'s
   signature (backward compatible — existing callers that don't pass it
   keep working; Phase 3 updates the one real caller).
2. **`submit_bot_duel`** — replace the inline `badge_duelist` block with:
   ```sql
   v_total_bot_wins := (select count(*) from public.duels where p1 = v_user_id and is_bot and winner = v_user_id);
   v_new_badges := public._evaluate_achievements(v_user_id, 'duel_result', jsonb_build_object('totalBotWins', v_total_bot_wins));
   ```
   (note: this count must be taken *after* this duel's row is inserted,
   same ordering the existing inline check already uses).
3. **`_touch_daily_streak`** — change its return type from `void` to
   `text[]`; right after it updates `streak_days`, call
   `public._evaluate_achievements(p_user_id, 'streak_touch', '{}'::jsonb)`
   and return the result. Update both call sites
   (`submit_level_attempt`, `play_daily_challenge`) to capture this
   return value and append it into their own `v_new_badges` array before
   returning it in their jsonb result. `play_daily_challenge` needs a new
   `'newlyEarnedBadgeIds'` key added to its final `jsonb_build_object(...)`
   (it returns nothing badge-related today).

### Backend: backfill

A separate migration, run once, that grants every badge whose criteria a
user's *existing* history already satisfies, with a best-effort historical
`unlocked_at` (Assumption 5). With only 28 profiles today, a straightforward
per-user `for ... loop` in PL/pgSQL is fast enough — no need for a
set-based rewrite of the evaluator. Sketch:

```sql
do $$
declare v_profile record;
begin
  for v_profile in select id from public.profiles loop
    -- Simple aggregate badges: run each as a one-shot check against full
    -- history, calling _unlock_achievement directly (bypassing the
    -- per-event evaluator, since there's no single "event" for backfill).
    -- e.g. globetrotter, scholar, week_warrior, duelist, boss_slayer,
    -- sharpshooter, on_fire (max longest-streak across all level_attempts'
    -- stored `answers`), big_brain, category_king.

    -- Centurion and Night Owl and Perfect Week need a *chronological*
    -- replay per user (order by created_at) since they're about streaks
    -- over time, not a single aggregate — loop that user's level_attempts
    -- in order, replaying the same walk the live evaluator does per
    -- attempt, tracking running state locally in the PL/pgSQL block
    -- (not via user_achievements.progress, to avoid firing currency
    -- grants mid-replay — grant once at the end if the threshold was
    -- ever crossed).
  end loop;
end $$;
```

The full per-badge backfill queries mirror the live-evaluator logic above,
sourced from `level_attempts`/`level_progress`/`duels`/`profiles` directly.
This is real implementation work (roughly one query or small loop per
badge) — the algorithm per badge is fully specified above; writing out
all ~14 backfill queries verbatim here would just be redundant with that
section.

### Flutter: threading badge ids through Duel and Daily

- **`DuelApi.submitBotDuel`**: read `response['newlyEarnedBadgeIds']` and
  add it to `BotDuelRecord` (new `List<String> newlyEarnedBadgeIds` field,
  defaulting to `const []` if the key is missing for any reason).
- **`DuelResult`** (freezed domain model): add
  `@Default([]) List<String> newlyEarnedBadgeIds`. `DuelRepository`
  (wherever it constructs `DuelResult` from `BotDuelRecord` — in
  `duel_play_cubit.dart`'s `_finish()`) passes `record.newlyEarnedBadgeIds`
  through (empty list on the client-computed-estimate fallback path, since
  that path means the RPC call itself failed).
- **`DailyApi.play`**: read `response['newlyEarnedBadgeIds']` into
  `DailyPlayOutcome` (new field, same default-empty pattern).
- **`DailyResult`**: add `@Default([]) List<String> newlyEarnedBadgeIds`;
  `DailyRepository.playToday` threads it through from `DailyPlayOutcome`.
- **`quiz_play_api.dart`** (wherever `submit_level_attempt` is invoked —
  the level-play submit path, separate from `_submitDaily`): add
  `'p_local_hour': DateTime.now().hour` to the RPC's `params` map. This is
  the one new client-supplied input the backend design above needs.

### Flutter: queueing celebrations across three flows

New shared helper, `lib/core/navigation/badge_celebration.dart` — belongs
in `core/` per CLAUDE.md §2 (reused by 3 features: quiz_result, duel,
daily) and §10 (cross-feature reuse goes through `core/`):

```dart
/// Pushes S-23 once per id in [badgeIds], in order, awaiting each screen's
/// dismissal before pushing the next. A no-op for an empty list.
Future<void> celebrateBadges(
  BuildContext context,
  List<String> badgeIds,
) async {
  for (final badgeId in badgeIds) {
    if (!context.mounted) return;
    await context.push(AppRoutes.badgeUnlockedPath(badgeId));
  }
}
```

- **`level_complete_screen.dart`**: replace the single
  `if (badgeId != null) await context.push(...)` block in `_runChain()`
  with `await celebrateBadges(context, widget.state.result.newlyEarnedBadgeIds);`.
  Remove `QuizResultCompleted.badgeToCelebrate` (no longer used anywhere —
  confirm via grep before deleting).
- **`duel_result_screen.dart`**: currently a `StatelessWidget` with no
  chain-runner. Convert to the same `StatefulWidget` + `initState` +
  `addPostFrameCallback` pattern as `level_complete_screen.dart`, calling
  `celebrateBadges(context, result.newlyEarnedBadgeIds)` after the screen's
  own entrance animation/payout beat (match whatever delay, if any, this
  screen already uses before it's interactive — currently none, so this
  can fire immediately post-frame). The fallback `_fallback` `DuelResult`
  (used only by the dev screen index) naturally has an empty badge list,
  so no celebration fires there.
- **`daily_result_screen.dart`**: same conversion — `StatefulWidget`,
  `initState` → `celebrateBadges(context, result.newlyEarnedBadgeIds)`.
  `DailyResult.preview()` (dev screen index) also naturally has an empty
  list.

### Flutter: real progress hints for all 14 badges

`AchievementsApi` grows a dispatch keyed by `criteria->>'type'` (fetched
alongside each row, since `fetchAll()` already selects `criteria` — wait,
today it doesn't select `criteria`, only the display columns; **add
`criteria` to the `select()`** so the client can dispatch without a second
round trip per badge). Replace the single `row['id'] == 'badge_category_king' ? categoryKing : null` ternary with a
`switch` over `row['criteria']['type']`, one resolver method per type,
each returning the same `_ClosestProgress?` shape `_categoryKingProgress`
already returns today:

- `level_flawless` (sharpshooter): best existing attempt's
  `correct_count`/`question_count` fraction, from the player's single
  best (highest-accuracy, not-yet-3-star) `level_attempts` row.
- `in_level_streak` (on_fire), `avg_answer_seconds_under` (quick_draw/
  rocket), `duel_wins` (duelist): read straight from
  `user_achievements.progress` for that `(user_id, achievement_id)` —
  these are exactly the counters Phase 1's evaluator now maintains even
  while locked.
- `boss_clear`: no fraction (binary) — `nextActionLabel` only.
- `category_flawless_count` (big_brain), `cross_level_correct_streak`
  (centurion), `perfect_week` (flawless), `midnight_streak` (night_owl):
  same — read from `progress`.
- `category_three_star_sweep` (category_king): keep the existing
  `_categoryKingProgress()` query as-is (it already computes the right
  "closest, not-yet-swept category" shape; this is a *different* question
  than "is any category fully swept," so it isn't replaceable by reading
  `progress`).
- `category_coverage` (globetrotter): live aggregate — categories covered
  vs. total active categories (same query the evaluator uses to grant it,
  reused here purely for the count, no unlock side effect from a `select`).
- `subcategory_level20_count` (scholar): live aggregate — distinct
  subcategories with a finished level-20 attempt, vs. the criteria count.
- `daily_streak` (week_warrior): `profiles.streak_days` vs. criteria days
  — already fetched elsewhere in the app; one more small query here.

Each resolver's `nextActionLabel` copy is new user-facing string content —
14 short strings (one per badge, whether locked or not — reuse the
existing group/fraction/action label three-line shape). Add these to
`AppLocalizations` (`l10n/app_localizations_en.arb` / `_ur.arb`) rather
than hardcoding English strings in the API layer, matching how
`badgeUnlockedEyebrow` etc. are already externalized.

### Cleanup while in this area

- `lib/core/mock/mock_badges.dart` and `lib/core/mock/mock_api.dart`:
  reconfirmed dead (no imports found anywhere in `lib/` beyond their own
  declarations) — delete both, and remove them from `MOCKED_FEATURES.md`'s
  table once this plan ships (that file is a living audit, not a spec, so
  updating it is a natural side effect of executing this plan, not a
  separate task).

## Implementation steps

**Phase 1 — Backend evaluator, unlock/reward mechanics, and the 3 call sites**
- [ ] Add `_unlock_achievement(uuid, text) returns boolean` (idempotent
      unlock + reward grant, per Design overview).
- [ ] Add `_bump_achievement_progress(uuid, text, jsonb) returns void`.
- [ ] Add `_evaluate_achievements(uuid, text, jsonb) returns text[]` with
      all 14 `case` branches per the per-badge design above.
- [ ] Modify `submit_level_attempt`: add `p_local_hour smallint default null`
      parameter; add `v_correctness_pattern boolean[]`,
      `v_correct_seconds_sum integer`, `v_correct_seconds_count integer`
      locals populated in the existing per-answer loop; replace the
      `_check_level_achievements(...)` call with the `_evaluate_achievements(..., 'level_attempt', ...)` call shown above; merge in `_touch_daily_streak`'s
      new return value.
- [ ] Modify `submit_bot_duel`: compute `v_total_bot_wins` (existing
      query, unchanged), replace the inline `badge_duelist` block with
      the `_evaluate_achievements(..., 'duel_result', ...)` call.
- [ ] Modify `_touch_daily_streak`: change return type `void` → `text[]`,
      call `_evaluate_achievements(..., 'streak_touch', '{}')` at the end.
- [ ] Modify `play_daily_challenge`: capture `_touch_daily_streak`'s new
      return value (only called when `v_correct_count > 0`, matching its
      existing gate), add `'newlyEarnedBadgeIds'` to the final
      `jsonb_build_object`.
- [ ] Drop `_check_level_achievements` once nothing references it (or
      keep it only if some other caller turns up during implementation
      that this research didn't find — re-grep before dropping).
- [ ] Ship as one migration file,
      `supabase/migrations/<timestamp>_real_achievement_engine.sql`.

**Phase 2 — Backfill**
- [ ] Write the one-time backfill migration per the Design overview's
      sketch — one query/loop per badge, sourced from existing history
      tables, granting with a best-effort historical `unlocked_at`.
- [ ] Ship as its own migration file (separate from Phase 1's, so it's
      easy to see in `list_migrations` history that it was a one-time
      data fix, not schema/logic) — 
      `supabase/migrations/<timestamp>_backfill_achievement_history.sql`.
- [ ] After applying, spot-check via SQL: `select achievement_id, count(*) from user_achievements where unlocked_at is not null group by 1 order by 1;`
      against what's plausible for the current 28-profile dataset (e.g.
      `badge_on_fire` should show at least the 2 pre-existing rows still
      present, unchanged).

**Phase 3 — Flutter data-layer wiring**
- [ ] `duel_api.dart`: add `newlyEarnedBadgeIds` to `BotDuelRecord`.
- [ ] `duel_result.dart`: add `@Default([]) List<String> newlyEarnedBadgeIds`
      to `DuelResult`; regenerate freezed/json_serializable output.
- [ ] `duel_play_cubit.dart`: thread `record.newlyEarnedBadgeIds` into the
      constructed `DuelResult` in `_finish()`.
- [ ] `daily_api.dart`: add `newlyEarnedBadgeIds` to `DailyPlayOutcome`.
- [ ] `daily_result.dart`: add `@Default([]) List<String> newlyEarnedBadgeIds`
      to `DailyResult`; regenerate freezed/json_serializable output.
- [ ] `daily_repository.dart`: thread it through `playToday`.
- [ ] Locate the level-play `submit_level_attempt` RPC call (in
      `quiz_play_api.dart` or wherever it lives — re-verify exact file
      during implementation, separate from `_submitDaily`'s
      `play_daily_challenge` call) and add `'p_local_hour': DateTime.now().hour`
      to its params.

**Phase 4 — Celebration queueing**
- [ ] Add `lib/core/navigation/badge_celebration.dart` with
      `celebrateBadges(BuildContext, List<String>)` per Design overview.
- [ ] `level_complete_screen.dart`: swap single-badge push for
      `celebrateBadges(context, widget.state.result.newlyEarnedBadgeIds)`.
- [ ] Remove `QuizResultCompleted.badgeToCelebrate` after confirming
      nothing else references it.
- [ ] Convert `duel_result_screen.dart` to a `StatefulWidget` with the
      same `initState`/`addPostFrameCallback` chain-runner shape as
      `level_complete_screen.dart`, calling `celebrateBadges`.
- [ ] Convert `daily_result_screen.dart` the same way.

**Phase 5 — Progress hints for all 14 badges**
- [ ] `achievements_api.dart`: add `criteria` to the `fetchAll()` select.
- [ ] Replace the single `categoryKing` ternary with a dispatch over
      `criteria['type']`, implementing each resolver per the Design
      overview (several are a straight `progress` jsonb read; a few are
      live aggregate queries; `category_three_star_sweep` keeps its
      existing query as-is).
- [ ] Add the ~14 new `nextActionLabel` strings to
      `l10n/app_localizations_en.arb` and `_ur.arb`, regenerate
      localizations.

**Phase 6 — Cleanup**
- [ ] Re-grep for any reference to `MockBadges`/`core/mock/mock_badges.dart`
      and `MockApi`/`core/mock/mock_api.dart`; if genuinely zero, delete
      both files.
- [ ] Update `MOCKED_FEATURES.md`'s `core/` table row for
      `mock_badges.dart` (remove it — no longer "dead code to delete
      later," now actually deleted) and its Achievements-adjacent rows
      once this feature is real end-to-end.

## Data model / API changes

**Schema**: no new tables. No new columns except one new optional RPC
parameter (`submit_level_attempt.p_local_hour smallint default null`).
`user_achievements.progress` (already existing, currently unused) becomes
load-bearing.

**Function signature changes**:
- `submit_level_attempt(p_attempt_id uuid, p_answers jsonb, p_used_power_up boolean, p_ending text, p_local_hour smallint default null)` — new trailing optional param, backward compatible.
- `_touch_daily_streak(p_user_id uuid) returns text[]` — return type changes from `void`; both existing call sites need a one-line update to capture and merge it.
- `submit_bot_duel`, `play_daily_challenge`: same input signatures, `play_daily_challenge`'s returned jsonb gains a `newlyEarnedBadgeIds` key (additive, non-breaking for any caller that ignores unknown keys — which `DailyApi.play` currently does).

**New functions**: `_unlock_achievement`, `_bump_achievement_progress`, `_evaluate_achievements` (all `security definer`, `public` schema, following existing naming convention of a leading underscore for internal helpers vs. the public RPC surface).

**Removed function**: `_check_level_achievements` (superseded).

**Dart model changes**: `BotDuelRecord`, `DuelResult`, `DailyPlayOutcome`, `DailyResult` each gain `List<String> newlyEarnedBadgeIds` (default `[]`). `BadgeProgress`/`AppBadge` (core/models) are unchanged — they already have every field Phase 5 needs.

## Dependencies

N/A — no new packages. Everything needed (`freezed`, `bloc_test`, `mocktail`, `supabase_flutter`) is already in `pubspec.yaml`.

## Testing strategy

**Backend** (matches this repo's existing convention — no pgTAP/SQL test
harness exists in `supabase/`; verification is manual SQL against a
Supabase branch, same as every prior backend-touching plan in this repo):
- Before merging Phase 1, create a Supabase branch (`create_branch`),
  apply the migration, and manually drive each of the 14 criteria via
  direct RPC calls / seeded rows, confirming: (a) the right
  `user_achievements` row appears with the right `unlocked_at`, (b)
  `wallet_ledger` shows exactly one `achievement_unlocked` grant per
  badge (not double-granted on a second qualifying event), (c) an
  already-unlocked achievement's `_evaluate_achievements` branch is a
  true no-op (no duplicate ledger row, no error).
- Confirm the backfill migration (Phase 2) is idempotent — running it
  twice against the same branch produces no duplicate grants (the `where
  ua.unlocked_at is null` guard and `_unlock_achievement`'s own
  conflict-safe insert should already guarantee this; verify it directly).
- `get_advisors` (security + performance) after both migrations, before
  merging to the main project.

**Flutter** (per CLAUDE.md §11, matching `achievements_cubit_test.dart`'s
existing `bloc_test` + `mocktail` style):
- `AchievementsCubit`/`BadgeUnlockedCubit`: no state-shape change from
  this plan, existing tests should keep passing unmodified; add one new
  case to the existing success-path test confirming a badge's
  `closestGroupLabel`/`closestFractionLabel` are populated for a
  non-category-king locked badge once Phase 5 lands (currently only
  category_king is exercised).
- `DuelPlayCubit`: extend its existing `bloc_test` suite with a case
  where `submitBotDuel` returns a `BotDuelRecord` carrying
  `newlyEarnedBadgeIds`, asserting the emitted `DuelResult` carries them
  through unchanged.
- New repository test for `AchievementsRepository`/`AchievementsApi`'s
  progress-hint dispatch: mock the Supabase client (`mocktail`, matching
  existing API-layer test conventions elsewhere in this repo) for at
  least one `progress`-jsonb-backed badge and one live-aggregate badge,
  confirming the right `BadgeProgress` fields come back.
- Widget test for `duel_result_screen.dart`/`daily_result_screen.dart`'s
  new chain-runner: confirm `celebrateBadges` is invoked with the
  result's badge list post-frame (matches CLAUDE.md §11's "non-trivial
  conditional rendering" bar loosely — this is new navigational
  behavior, not just rendering, but the same bar for "worth a test"
  applies).

## Edge cases & error handling

- **Multiple badges unlock from one action** (e.g. a boss-level flawless
  clear could unlock Boss Slayer, Sharpshooter, and push Centurion over
  100 simultaneously): `_evaluate_achievements` returns all of them in one
  array; `celebrateBadges` queues them in the array's order (the order
  the `for v_row in select ...` loop naturally produces — not
  significant, but stable within a single call since there's no explicit
  `order by`; add one if a deterministic celebration order matters to the
  product).
- **A wrong answer that also ends the attempt** (out of hearts mid-streak):
  Centurion's walk must still process the correct answers *before* the
  fatal wrong one, then force-reset at the end because `p_ending != 'finished'` — covered explicitly in the per-badge design above.
- **A guest (unauthenticated) player**: `AchievementsApi.fetchAll()`
  already handles `userId == null` by skipping the unlocked-rows query
  entirely (existing behavior, unaffected by this plan). The backend
  evaluator is never invoked for a guest since `submit_level_attempt`
  requires `auth.uid()` to resolve a real attempt row.
- **Backfill running against a user with zero history**: every branch's
  aggregate queries naturally degrade to zero/empty (same defensive
  pattern `profile_api.dart` already uses elsewhere in this codebase) —
  no badge unlocks, no error.
- **`play_daily_challenge`'s existing early exit when `v_correct_count = 0`** (no `_touch_daily_streak` call at all in that branch) means Week
  Warrior cannot be evaluated on a zero-correct daily attempt — correct,
  since the streak itself isn't touched in that case either.
- **A player who already had `badge_on_fire` manually seeded** (the 2
  existing rows): the backfill's `_unlock_achievement`-style guards
  (`where unlocked_at is null`) mean these rows are left untouched, not
  overwritten with a new `unlocked_at`.

## Acceptance criteria

- [ ] All 14 badges in `public.achievements` have a live server-side path
      to `unlocked_at` being set for real gameplay, verified by manually
      driving each criterion on a Supabase branch.
- [ ] `wallet_ledger` shows exactly one `achievement_unlocked` grant per
      `(user, achievement)` pair, ever — no double-grants on repeated
      qualifying events after the first unlock.
- [ ] Finishing a level, winning a bot duel, and completing the daily
      challenge each correctly surface `newlyEarnedBadgeIds` in their
      RPC/API response, and each screen's chain-runner celebrates every
      id in that list, in order.
- [ ] The Achievements grid shows a non-null "closest progress" hint for
      every currently-locked badge that has one meaningful to show
      (binary criteria like Boss Slayer still show only a next-action
      label, per Design overview — that's expected, not a bug).
- [ ] Running the backfill migration against the live 28-profile dataset
      grants at least the two pre-existing `badge_on_fire` rows'
      equivalent (they stay as-is) and does not error or duplicate.
- [ ] `dart analyze` is clean and every new/changed Cubit/repository has
      the CLAUDE.md §11-required test coverage.

## Risks & rollout notes

- **Migration ordering**: Phase 1 and Phase 2 must be applied to the live
  project in order (evaluator logic before backfill, since the backfill
  reuses the same per-badge semantics conceptually, and ideally the exact
  helper functions where a badge's logic is a pure aggregate — e.g. call
  `_unlock_achievement` directly from the backfill rather than
  reimplementing the insert/grant pattern a third time).
- **`submit_level_attempt` is a hot, frequently-touched function** (per
  CLAUDE.md §10, migrations to it should be additive where possible) —
  this plan's new parameter is optional/trailing and the new locals are
  purely additive, so existing callers and behavior are unaffected until
  Phase 3's client update ships; the two changes can safely land in
  either order without breaking the other.
- **Reward economy impact**: backfilling could grant a meaningful one-time
  coin windfall to existing accounts (14 badges × their `coin_reward`
  values, for whichever subset each player already qualifies for) — this
  is presumably desired (the whole point of "backfill on launch"), but
  worth flagging before applying to production since it's real currency,
  not cosmetic.
- **No rollback path for a bad backfill grant** beyond manually deleting
  the offending `user_achievements` rows and reversing the corresponding
  `wallet_ledger` entries — test thoroughly on a branch first (Testing
  strategy above already calls for this).
- **Docs to update post-implementation**: `MOCKED_FEATURES.md`'s
  Achievements-related rows should be removed/updated once this ships
  (Phase 6 already covers this).
