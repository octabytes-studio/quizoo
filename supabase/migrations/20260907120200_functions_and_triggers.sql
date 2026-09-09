-- ============================================================================
-- Quizoo — Functions & triggers
--
-- Every formula in this file is transcribed verbatim from the Flutter app's
-- own mock scoring engine — lib/features/quiz_play/domain/scoring.dart — so
-- the server's authoritative score agrees with what the client already shows
-- the player mid-run. That file's doc comment says it plainly: "the server
-- recomputes every submitted level from the answer log; the client's own
-- total is display only." This is that recomputation, made real.
--
-- Naming convention: SQL functions the client calls directly via
-- `supabase.rpc(...)` are unprefixed (start_level_attempt,
-- submit_level_attempt, ...). Internal helpers other functions call are
-- prefixed `_` and are not granted to `authenticated`.
-- ============================================================================

-- ============================================================================
-- IDENTITY: new-user bootstrap
-- ============================================================================

create or replace function public._handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, is_guest, locale)
  values (
    new.id,
    -- Supabase marks an anonymous sign-in with is_anonymous on auth.users
    -- (or, on older Postgres images, no identity row at all).
    coalesce(new.is_anonymous, false) or new.email is null,
    coalesce(new.raw_user_meta_data ->> 'locale', 'en')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public._handle_new_user();

-- ============================================================================
-- PROGRESSION MATH (Scoring, transcribed 1:1)
-- ============================================================================

-- xpToNext(n) = 300 + 100n — cost, in XP, to go from player_level n to n+1.
create or replace function public._xp_for_level(p_level integer)
returns integer
language sql immutable
as $$
  select 300 + 100 * p_level;
$$;

-- Inverts the above over a total XP figure. Player levels are small
-- (low hundreds at most for the lifetime of an account), so a loop is both
-- simpler and cheaper than a closed-form quadratic solve with rounding edge
-- cases.
create or replace function public._player_level_from_xp(p_total_xp integer)
returns table (player_level integer, xp_into_level integer, xp_to_next_level integer)
language plpgsql immutable
as $$
declare
  v_level integer := 1;
  v_remaining integer := greatest(p_total_xp, 0);
  v_cost integer;
begin
  loop
    v_cost := public._xp_for_level(v_level);
    exit when v_remaining < v_cost;
    v_remaining := v_remaining - v_cost;
    v_level := v_level + 1;
  end loop;
  return query select v_level, v_remaining, v_cost;
end;
$$;

create or replace function public._rank_title_for_level(p_level integer)
returns text
language sql stable
as $$
  select title from public.rank_titles
  where p_level between min_level and max_level
  order by min_level desc
  limit 1;
$$;

-- §19's level table: 1-5 warm-up/30s, 6-10 steady/25s, 11-15 sharp/20s,
-- 16-20 brutal/15s. Pure functions of the level number — mirrors
-- MockCatalog.bandFor/secondsFor exactly, which is why there is no `levels`
-- catalogue table: nothing about a level's timing needs to be stored.
create or replace function public._difficulty_band_for_level(p_level smallint)
returns text
language sql immutable
as $$
  select case
    when p_level <= 5 then 'warmUp'
    when p_level <= 10 then 'steady'
    when p_level <= 15 then 'sharp'
    else 'brutal'
  end;
$$;

create or replace function public._seconds_for_level(p_level smallint)
returns smallint
language sql immutable
as $$
  select case public._difficulty_band_for_level(p_level)
    when 'warmUp' then 30
    when 'steady' then 25
    when 'sharp' then 20
    else 15
  end::smallint;
$$;

-- The question-difficulty band (1-5 scale on questions.difficulty) a level
-- draws its 20 questions from — §19's "difficulty 1-2 / 2-3 / 3-4 / 4-5"
-- pools, one step per difficulty band.
create or replace function public._question_difficulty_range(p_level smallint)
returns smallint[]
language sql immutable
as $$
  select case public._difficulty_band_for_level(p_level)
    when 'warmUp' then array[1, 2]::smallint[]
    when 'steady' then array[2, 3]::smallint[]
    when 'sharp' then array[3, 4]::smallint[]
    else array[4, 5]::smallint[]
  end;
$$;

create or replace function public._speed_bonus(p_seconds_left integer, p_seconds_total integer)
returns integer
language sql immutable
as $$
  select case when p_seconds_total <= 0 then 0
    else greatest(0, least(100, round(100.0 * p_seconds_left / p_seconds_total)))
  end::integer;
$$;

-- diffMult = 1 + (level - 1) * 0.05 — L1 = 1.00 ... L20 = 1.95.
create or replace function public._difficulty_multiplier(p_level integer)
returns numeric
language sql immutable
as $$
  select 1 + (p_level - 1) * 0.05;
$$;

-- Streak ladder: 3+ -> x1.2, 5+ -> x1.5, 8+ -> x1.8, 12+ -> x2.0.
create or replace function public._streak_multiplier(p_streak integer)
returns numeric
language sql immutable
as $$
  select case
    when p_streak >= 12 then 2.0
    when p_streak >= 8 then 1.8
    when p_streak >= 5 then 1.5
    when p_streak >= 3 then 1.2
    else 1.0
  end;
$$;

-- stars: 12-15 correct -> 1, 16-19 -> 2, 20 -> 3.
create or replace function public._stars_for(p_correct_count integer)
returns smallint
language sql immutable
as $$
  select case
    when p_correct_count >= 20 then 3
    when p_correct_count >= 16 then 2
    when p_correct_count >= 12 then 1
    else 0
  end::smallint;
$$;

-- ============================================================================
-- WALLET
-- ============================================================================

-- The only place profiles.coins/gems/hearts ever change, and the only place
-- that writes wallet_ledger. Every caller in this file goes through this
-- function rather than touching profiles directly, which is what makes the
-- ledger complete by construction rather than by convention.
create or replace function public._grant_currency(
  p_user_id uuid,
  p_currency text,
  p_delta integer,
  p_reason text,
  p_ref_id uuid default null
)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if p_delta = 0 then
    return;
  end if;

  insert into public.wallet_ledger (user_id, currency, delta, reason, ref_id)
  values (p_user_id, p_currency, p_delta, p_reason, p_ref_id);

  if p_currency = 'coins' then
    update public.profiles set coins = greatest(0, coins + p_delta) where id = p_user_id;
  elsif p_currency = 'gems' then
    update public.profiles set gems = greatest(0, gems + p_delta) where id = p_user_id;
  elsif p_currency = 'hearts' then
    update public.profiles
      set hearts = least(max_hearts, greatest(0, hearts + p_delta)),
          hearts_updated_at = case when p_delta < 0 then now() else hearts_updated_at end
      where id = p_user_id;
  end if;
end;
$$;

-- Lazy heart refill: one heart every 20 minutes (Design Bible's shop copy
-- and MockPlayer's own "next heart in 28 min" fixture both imply a per-heart
-- timer, not a full-wallet cooldown), capped at max_hearts. Called before
-- any function reads or spends hearts, so the stored value is never stale by
-- more than the caller's own request.
create or replace function public._settle_hearts(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_row public.profiles%rowtype;
  v_refill_minutes constant integer := 20;
  v_elapsed_minutes integer;
  v_gained integer;
begin
  select * into v_row from public.profiles where id = p_user_id for update;
  if v_row.hearts >= v_row.max_hearts then
    return;
  end if;

  v_elapsed_minutes := floor(extract(epoch from (now() - v_row.hearts_updated_at)) / 60);
  v_gained := floor(v_elapsed_minutes::numeric / v_refill_minutes);
  if v_gained <= 0 then
    return;
  end if;

  update public.profiles
    set hearts = least(max_hearts, hearts + v_gained),
        hearts_updated_at = hearts_updated_at + make_interval(mins => v_gained * v_refill_minutes)
    where id = p_user_id;
end;
$$;

-- ============================================================================
-- STREAK
-- ============================================================================

-- Shared by submit_level_attempt and play_daily_challenge — either kind of
-- play keeps the day streak alive, matching StreakStatus being read from one
-- shared source rather than two independent streak counters.
create or replace function public._touch_daily_streak(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_last date;
  v_today date := (now() at time zone 'utc')::date;
begin
  select last_played_on into v_last from public.profiles where id = p_user_id for update;

  if v_last = v_today then
    return; -- already played today, streak unchanged
  elsif v_last = v_today - 1 then
    update public.profiles set streak_days = streak_days + 1, last_played_on = v_today
      where id = p_user_id;
  elsif v_last is not null and v_last < v_today - 1 then
    -- Gap of 2+ days: spend a freeze if one is held, otherwise the streak
    -- resets to 1 (today).
    update public.profiles
      set streak_days = case when streak_freezes > 0 then streak_days + 1 else 1 end,
          streak_freezes = case when streak_freezes > 0 then streak_freezes - 1 else streak_freezes end,
          last_played_on = v_today
      where id = p_user_id;
  else
    -- v_last is null: first-ever play.
    update public.profiles set streak_days = 1, last_played_on = v_today where id = p_user_id;
  end if;
end;
$$;

-- ============================================================================
-- ACHIEVEMENTS
-- ============================================================================

-- A small, honest rule engine matching the exact subset the mock phase
-- implements (QuizResultApi._badgesFor): flawless, a 10+ streak inside a
-- level, and clearing a boss level. Extend the `when` list as criteria->>
-- 'type' grows; every branch is idempotent via the ON CONFLICT DO NOTHING.
create or replace function public._check_level_achievements(
  p_user_id uuid,
  p_is_flawless boolean,
  p_longest_streak integer,
  p_is_boss boolean,
  p_is_complete boolean
)
returns text[]
language plpgsql security definer
set search_path = public
as $$
declare
  v_newly_unlocked text[] := '{}';
  v_id text;
begin
  if not p_is_complete then
    return v_newly_unlocked;
  end if;

  for v_id in
    select id from public.achievements
    where (criteria ->> 'type') in ('level_flawless', 'in_level_streak', 'boss_clear')
  loop
    if (
      (v_id = 'badge_sharpshooter' and p_is_flawless)
      or (v_id = 'badge_on_fire' and p_longest_streak >= 10)
      or (v_id = 'badge_boss_slayer' and p_is_boss)
    ) then
      insert into public.user_achievements (user_id, achievement_id, unlocked_at)
      values (p_user_id, v_id, now())
      on conflict (user_id, achievement_id) do nothing;

      if found then
        v_newly_unlocked := array_append(v_newly_unlocked, v_id);
        perform public._grant_currency(
          p_user_id, 'coins',
          (select coin_reward from public.achievements where id = v_id),
          'achievement_unlocked', null
        );
      end if;
    end if;
  end loop;

  return v_newly_unlocked;
end;
$$;

-- ============================================================================
-- CATALOG COUNTERS
-- ============================================================================

-- One function backs triggers on two different tables (questions and
-- subcategories), each supplying a NEW/OLD row of a different shape.
-- PL/pgSQL resolves record field access (new.foo) at the moment that line
-- actually runs, not when the function is defined — so every field access
-- below is confined to the tg_table_name branch where that field actually
-- exists on the row, rather than referenced unconditionally at the top
-- (that was the original bug: `new.category_id` doesn't exist on a
-- `questions` row, and `new.subcategory_id` doesn't exist on a
-- `subcategories` row, so whichever table's trigger fired second raised
-- "record ... has no field ...").
create or replace function public._refresh_category_counts()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_subcategory_id uuid;
  v_category_ids uuid[];
begin
  if tg_table_name = 'questions' then
    v_subcategory_id := coalesce(new.subcategory_id, old.subcategory_id);

    update public.subcategories s
      set question_count = (
        select count(*) from public.questions q
        where q.subcategory_id = s.id and q.status = 'live'
      )
    where s.id = v_subcategory_id;

    select array_agg(distinct category_id) into v_category_ids
      from public.subcategories where id = v_subcategory_id;

  elsif tg_table_name = 'subcategories' then
    -- array, not a single id, so a category reassignment (rare, but
    -- possible via an admin edit) recomputes both the old and new parent.
    v_category_ids := array_remove(array[new.category_id, old.category_id], null);
  end if;

  if v_category_ids is not null then
    update public.categories c
      set subcategory_count = (
        select count(*) from public.subcategories s
        where s.category_id = c.id and s.is_active = true
      ),
      question_count = (
        select coalesce(sum(s.question_count), 0) from public.subcategories s
        where s.category_id = c.id
      )
    where c.id = any(v_category_ids);
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists refresh_counts_on_subcategory on public.subcategories;
create trigger refresh_counts_on_subcategory
  after insert or update or delete on public.subcategories
  for each row execute function public._refresh_category_counts();

drop trigger if exists refresh_counts_on_question on public.questions;
create trigger refresh_counts_on_question
  after insert or update or delete on public.questions
  for each row execute function public._refresh_category_counts();

-- ============================================================================
-- GAMEPLAY: start-level / submit-level
--
-- These two RPCs are what the start-level and submit-level Edge Functions
-- call (see plan 005's "Data model / API changes" for the Edge Function's
-- thin wrapper contract). They are also safe to expose directly to
-- `authenticated` via supabase.rpc(...) if the Edge Function layer is
-- skipped for v1 — the tamper-resistance lives here, not in the Edge
-- Function.
-- ============================================================================

-- ── A deliberate, flagged deviation from the Design Bible's literal RLS note
-- ("never ship correct_index to the client before submission") — see plan
-- 005's "Assumptions & open questions" for the full reasoning. Summary: the
-- app's `Question.correctIndex` domain model field is `required` and used
-- for the client's immediate right/wrong feedback the moment a player taps
-- an option (§01 Pillar 02, and the whole point of §01's "no blocking
-- network mid-level" contract — one fetch per level, zero further round
-- trips). Hiding correct_index would mean either a per-question network call
-- (breaking that contract) or a shuffle-token scheme whose added protection
-- is marginal for a single-player, no-real-money-stakes game. So: this
-- function ships correct_index, options in stored (unshuffled) order, and
-- anti-cheat instead rests on submit_level_attempt() independently
-- re-deriving correctness from question_i18n rather than trusting anything
-- the client reports as "correct", plus the `flagged`/`avg_answer_ms`
-- statistical signals daily-rollover accumulates. If a future feature raises
-- the stakes (real-money tournaments, a competitive ranked ladder with
-- prizes), revisit with a shuffle-token or per-question-RPC design instead.
create or replace function public.start_level_attempt(
  p_subcategory_id uuid,
  p_level smallint,
  p_locale text default 'en'
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt_id uuid;
  v_seed text := encode(extensions.gen_random_bytes(16), 'hex');
  v_range smallint[] := public._question_difficulty_range(p_level);
  v_questions jsonb;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  perform public._settle_hearts(v_user_id);

  if (select hearts from public.profiles where id = v_user_id) <= 0 then
    raise exception 'out_of_hearts' using errcode = 'P0001';
  end if;

  -- Twenty questions from the level's difficulty band. `seed` is kept on the
  -- row for traceability/replay-debugging, not because submit needs to
  -- reconstruct a shuffle — there isn't one; see the function comment above.
  select jsonb_agg(row) into v_questions
  from (
    select jsonb_build_object(
      'id', q.id,
      'subcategoryId', q.subcategory_id,
      'difficulty', q.difficulty,
      'text', qi.prompt,
      'options', qi.options,
      'correctIndex', qi.correct_index,
      'explanation', qi.explanation,
      'hasImage', q.kind = 'image',
      'imageAsset', q.media_url
    ) as row
    from public.questions q
    join public.question_i18n qi on qi.question_id = q.id and qi.locale = p_locale
    where q.subcategory_id = p_subcategory_id
      and q.status = 'live'
      and q.difficulty between v_range[1] and v_range[2]
    order by md5(v_seed || q.id::text)
    limit 20
  ) sub;

  insert into public.level_attempts (user_id, subcategory_id, level, seed, locale, is_boss)
  values (v_user_id, p_subcategory_id, p_level, v_seed, p_locale, p_level % 5 = 0)
  returning id into v_attempt_id;

  perform public._grant_currency(v_user_id, 'hearts', -1, 'level_attempt_start', v_attempt_id);

  update public.questions set seen_count = seen_count + 1
    where id in (select (row ->> 'id')::uuid from jsonb_array_elements(v_questions) row);

  return jsonb_build_object(
    'attemptId', v_attempt_id,
    'secondsPerQuestion', public._seconds_for_level(p_level),
    'isBoss', p_level % 5 = 0,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
end;
$$;

-- p_answers shape (as sent by the client, one entry per question reached):
--   [{"questionId": uuid, "chosenIndex": int|null, "secondsLeft": int,
--     "action": "answered" | "timedOut" | "skipped"}]
-- "action" distinguishes *why* chosenIndex might be null (or, for
-- "answered", carries the player's pick) — it is trusted, because it only
-- ever affects which questions cost a heart, a low-stakes, client-observed
-- timing detail (see plan 005's Assumptions). Whether an "answered" entry
-- was *correct* is never trusted from the client: this function looks up
-- question_i18n.correct_index itself for every question id and compares.
-- p_ending: 'finished' | 'outOfHearts' | 'quit'
create or replace function public.submit_level_attempt(
  p_attempt_id uuid,
  p_answers jsonb,
  p_used_power_up boolean,
  p_ending text
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt public.level_attempts%rowtype;
  v_seconds_total integer;
  v_answer jsonb;
  v_correct_index smallint;
  v_is_correct boolean;
  v_streak integer := 0;
  v_longest_streak integer := 0;
  v_correct_count integer := 0;
  v_score integer := 0;
  v_line_score integer;
  v_stars smallint;
  v_is_complete boolean;
  v_is_flawless boolean;
  v_question_count integer;
  v_is_first_clear boolean;
  v_xp integer;
  v_coins integer;
  v_new_badges text[];
  v_level_row public.level_progress%rowtype;
  v_result jsonb;
begin
  select * into v_attempt from public.level_attempts where id = p_attempt_id for update;
  if v_attempt.user_id is null then
    raise exception 'attempt_not_found';
  end if;
  if v_attempt.user_id <> v_user_id then
    raise exception 'not_your_attempt';
  end if;
  if v_attempt.server_score is not null then
    raise exception 'attempt_already_submitted';
  end if;

  v_seconds_total := public._seconds_for_level(v_attempt.level);
  v_question_count := jsonb_array_length(p_answers);
  v_is_complete := p_ending = 'finished';

  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    v_is_correct := false;

    if v_answer ->> 'action' = 'answered' and v_answer ->> 'chosenIndex' is not null then
      select correct_index into v_correct_index from public.question_i18n
        where question_id = (v_answer ->> 'questionId')::uuid and locale = v_attempt.locale;

      update public.questions set correct_count = correct_count + 1
        where id = (v_answer ->> 'questionId')::uuid
        and v_correct_index = (v_answer ->> 'chosenIndex')::smallint;

      v_is_correct := v_correct_index is not null
        and v_correct_index = (v_answer ->> 'chosenIndex')::smallint;
    end if;

    if v_is_correct then
      v_streak := v_streak + 1;
      v_longest_streak := greatest(v_longest_streak, v_streak);
      v_correct_count := v_correct_count + 1;
      v_line_score := round(
        (100 + public._speed_bonus((v_answer ->> 'secondsLeft')::integer, v_seconds_total))
        * public._difficulty_multiplier(v_attempt.level)
        * public._streak_multiplier(v_streak - 1) -- multiplier is the run BEFORE this answer
      );
      v_score := v_score + v_line_score;
    else
      v_streak := 0;
    end if;
  end loop;

  v_is_flawless := v_is_complete and v_question_count = 20 and v_correct_count = 20;
  v_stars := case when v_is_complete then public._stars_for(v_correct_count) else 0 end;

  -- Clean-run / flawless / boss bonuses (Scoring.breakdown), added on top of
  -- the per-question total accumulated above.
  if v_is_complete then
    if not p_used_power_up then
      v_score := v_score + 250; -- cleanRunBonus
    end if;
    if v_is_flawless then
      v_score := v_score + 1000; -- flawlessBonus
    end if;
    if v_attempt.is_boss then
      v_score := v_score * 2; -- bossMultiplier, applied to the running subtotal
    end if;
  end if;

  select * into v_level_row from public.level_progress
    where user_id = v_user_id and subcategory_id = v_attempt.subcategory_id
      and level = v_attempt.level
    for update;
  v_is_first_clear := v_is_complete and (v_level_row.completed_at is null);

  v_xp := case when v_is_complete then
    100 + 10 * v_attempt.level
      + case v_stars when 3 then 200 when 2 then 100 else 0 end
      + case when v_is_first_clear then 150 else 0 end
    else 0 end;

  v_coins := case when v_is_complete then
    (60 + 10 * v_attempt.level + v_stars * 20) * (case when v_attempt.is_boss then 2 else 1 end)
    else 0 end;

  update public.level_attempts set
    answers = p_answers,
    client_score = null,
    server_score = v_score,
    correct_count = v_correct_count,
    stars = v_stars,
    used_power_up = p_used_power_up,
    ending = p_ending
  where id = p_attempt_id;

  insert into public.level_progress (user_id, subcategory_id, level, best_score, stars, attempts, completed_at, last_played_at)
  values (v_user_id, v_attempt.subcategory_id, v_attempt.level, v_score, v_stars, 1,
          case when v_is_complete then now() else null end, now())
  on conflict (user_id, subcategory_id, level) do update set
    best_score = greatest(public.level_progress.best_score, excluded.best_score),
    stars = greatest(public.level_progress.stars, excluded.stars),
    attempts = public.level_progress.attempts + 1,
    completed_at = coalesce(public.level_progress.completed_at, excluded.completed_at),
    last_played_at = now();

  if v_is_complete then
    insert into public.score_events (user_id, subcategory_id, category_id, country_code, points, source)
    select v_user_id, v_attempt.subcategory_id, s.category_id, p.country_code, v_score, 'level'
    from public.subcategories s, public.profiles p
    where s.id = v_attempt.subcategory_id and p.id = v_user_id;

    update public.subcategories set play_count = play_count + 1 where id = v_attempt.subcategory_id;

    perform public._grant_currency(v_user_id, 'coins', v_coins, 'level_reward', p_attempt_id);
    update public.profiles set xp = xp + v_xp where id = v_user_id;

    select player_level, xp_into_level, xp_to_next_level into v_level_row.level, v_level_row.stars, v_level_row.attempts
      from public._player_level_from_xp((select xp from public.profiles where id = v_user_id));
    update public.profiles set player_level = v_level_row.level where id = v_user_id;

    perform public._touch_daily_streak(v_user_id);

    -- Weekly league points mirror score_events for whichever cohort the
    -- player is currently in (a no-op until daily-rollover has assigned one).
    update public.league_memberships lm
      set points = lm.points + v_score
      from public.league_cohorts lc
      where lm.cohort_id = lc.id and lm.user_id = v_user_id
        and lc.week_start = date_trunc('week', now())::date;
  end if;

  v_new_badges := public._check_level_achievements(v_user_id, v_is_flawless, v_longest_streak, v_attempt.is_boss, v_is_complete);

  select jsonb_build_object(
    'isFirstClear', v_is_first_clear,
    'finalScore', v_score,
    'stars', v_stars,
    'coinsEarned', v_coins,
    'xpEarned', v_xp,
    'playerLevel', p.player_level,
    'newlyEarnedBadgeIds', to_jsonb(v_new_badges)
  ) into v_result
  from public.profiles p where p.id = v_user_id;

  return v_result;
end;
$$;

-- ============================================================================
-- DAILY CHALLENGE
-- ============================================================================

create or replace function public.play_daily_challenge(p_answer_pattern boolean[])
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := (now() at time zone 'utc')::date;
  v_challenge public.daily_challenges%rowtype;
  v_correct_count integer;
  v_total_count integer;
  v_coins integer;
  v_bucket integer;
  v_histogram jsonb;
begin
  select * into v_challenge from public.daily_challenges where challenge_date = v_today for update;
  if v_challenge.challenge_date is null then
    raise exception 'no_challenge_today';
  end if;

  if exists (select 1 from public.daily_attempts where user_id = v_user_id and challenge_date = v_today) then
    raise exception 'already_played_today';
  end if;

  v_total_count := array_length(p_answer_pattern, 1);
  select count(*) into v_correct_count from unnest(p_answer_pattern) as correct where correct;
  v_coins := case when v_correct_count > 0 then v_challenge.coin_reward else 0 end;
  v_bucket := least(4, v_correct_count / 2); -- 0-2,3-4,5-6,7-8,9-10 -> buckets 0..4

  insert into public.daily_attempts (user_id, challenge_date, correct_count, total_count, answer_pattern, coins_earned)
  values (v_user_id, v_today, v_correct_count, v_total_count, p_answer_pattern, v_coins);

  update public.daily_challenges
    set score_histogram = jsonb_set(
      score_histogram, array[v_bucket::text],
      to_jsonb(coalesce((score_histogram ->> v_bucket::text)::integer, 0) + 1)
    )
    where challenge_date = v_today
    returning score_histogram into v_histogram;

  perform public._grant_currency(v_user_id, 'coins', v_coins, 'daily_reward', null);

  if v_correct_count > 0 then
    perform public._touch_daily_streak(v_user_id);
    insert into public.score_events (user_id, points, source)
    values (v_user_id, v_coins, 'daily');
  end if;

  return jsonb_build_object(
    'correctCount', v_correct_count,
    'totalCount', v_total_count,
    'coinsEarned', v_coins,
    'distribution', v_histogram,
    'streakNow', (select streak_days from public.profiles where id = v_user_id)
  );
end;
$$;

-- ============================================================================
-- DUELS
-- ============================================================================

-- Guards duels' answer-array update policy: a participant may only ever
-- change *their own* answers column, never the opponent's, never the
-- rounds/winner/status columns directly (those are resolve_duel's job).
create or replace function public._guard_duel_answer_update()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() = old.p1 and new.p2_answers is distinct from old.p2_answers then
    raise exception 'cannot modify opponent answers';
  end if;
  if auth.uid() = old.p2 and new.p1_answers is distinct from old.p1_answers then
    raise exception 'cannot modify opponent answers';
  end if;
  if new.p1_rounds <> old.p1_rounds or new.p2_rounds <> old.p2_rounds
     or new.status <> old.status or new.winner is distinct from old.winner then
    raise exception 'rounds/status/winner are server-only';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_duel_answer_update on public.duels;
create trigger guard_duel_answer_update
  before update on public.duels
  for each row execute function public._guard_duel_answer_update();

-- Submits the caller's answer for one round of a duel they are in. When both
-- sides have answered the round (or the round's clock already expired
-- client-side), resolve_duel_round scores it. The Edge Function layer
-- (resolve-duel) is what broadcasts the reveal over Realtime — this function
-- only persists state.
create or replace function public.submit_duel_answer(
  p_duel_id uuid,
  p_round smallint,
  p_chosen_index smallint,
  p_answered_at_ms integer
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_duel public.duels%rowtype;
  v_is_p1 boolean;
  v_entry jsonb;
begin
  select * into v_duel from public.duels where id = p_duel_id for update;
  if v_duel.id is null or v_duel.status <> 'active' or v_user_id not in (v_duel.p1, v_duel.p2) then
    raise exception 'invalid_duel';
  end if;

  v_is_p1 := v_user_id = v_duel.p1;
  v_entry := jsonb_build_object('round', p_round, 'chosenIndex', p_chosen_index, 'answeredAtMs', p_answered_at_ms);

  if v_is_p1 then
    update public.duels set p1_answers = p1_answers || v_entry where id = p_duel_id;
  else
    update public.duels set p2_answers = p2_answers || v_entry where id = p_duel_id;
  end if;

  return public.resolve_duel_round(p_duel_id, p_round);
end;
$$;

-- Idempotent: safe to call after every answer submission and after a
-- round-timer expiry. Only writes a verdict once both sides have an entry
-- for the round (or the caller passes a forced expiry — left to the Edge
-- Function to decide when to call this after a 10s timeout with one side
-- silent).
create or replace function public.resolve_duel_round(p_duel_id uuid, p_round smallint)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_duel public.duels%rowtype;
  v_question_id uuid;
  v_correct_index smallint;
  v_p1_entry jsonb;
  v_p2_entry jsonb;
  v_p1_correct boolean;
  v_p2_correct boolean;
  v_outcome text;
begin
  select * into v_duel from public.duels where id = p_duel_id for update;
  v_question_id := v_duel.question_ids[p_round];

  select correct_index into v_correct_index from public.question_i18n
    where question_id = v_question_id and locale = 'en';

  select e into v_p1_entry from jsonb_array_elements(v_duel.p1_answers) e
    where (e ->> 'round')::smallint = p_round limit 1;
  select e into v_p2_entry from jsonb_array_elements(v_duel.p2_answers) e
    where (e ->> 'round')::smallint = p_round limit 1;

  if v_p1_entry is null or v_p2_entry is null then
    return jsonb_build_object('resolved', false); -- still waiting on one side
  end if;

  v_p1_correct := (v_p1_entry ->> 'chosenIndex')::smallint = v_correct_index;
  v_p2_correct := (v_p2_entry ->> 'chosenIndex')::smallint = v_correct_index;

  if v_p1_correct and not v_p2_correct then
    v_outcome := 'p1';
  elsif v_p2_correct and not v_p1_correct then
    v_outcome := 'p2';
  elsif v_p1_correct and v_p2_correct then
    -- Both correct: the faster answer wins the round.
    v_outcome := case when (v_p1_entry ->> 'answeredAtMs')::integer <= (v_p2_entry ->> 'answeredAtMs')::integer
      then 'p1' else 'p2' end;
  else
    v_outcome := 'draw';
  end if;

  update public.duels set
    p1_rounds = p1_rounds + (case when v_outcome = 'p1' then 1 else 0 end),
    p2_rounds = p2_rounds + (case when v_outcome = 'p2' then 1 else 0 end)
  where id = p_duel_id;

  if p_round >= 5 then
    perform public.resolve_duel(p_duel_id);
  end if;

  return jsonb_build_object(
    'resolved', true, 'round', p_round, 'outcome', v_outcome,
    'correctIndex', v_correct_index
  );
end;
$$;

-- Final settlement: ELO (K=32), payouts, achievements. Safe to call more
-- than once — a completed duel is a no-op on a second call.
create or replace function public.resolve_duel(p_duel_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_duel public.duels%rowtype;
  v_p1_elo integer; v_p2_elo integer;
  v_winner uuid; v_loser uuid;
  v_expected_p1 numeric;
  v_p1_score numeric; -- 1 win, 0.5 draw, 0 loss
  v_p1_new integer; v_p2_new integer;
  k constant integer := 32;
begin
  select * into v_duel from public.duels where id = p_duel_id for update;
  if v_duel.status = 'complete' then
    return jsonb_build_object('alreadyResolved', true);
  end if;

  select elo into v_p1_elo from public.profiles where id = v_duel.p1;
  v_p2_elo := case when v_duel.is_bot then v_p1_elo else
    (select elo from public.profiles where id = v_duel.p2) end;

  v_p1_score := case
    when v_duel.p1_rounds > v_duel.p2_rounds then 1
    when v_duel.p1_rounds < v_duel.p2_rounds then 0
    else 0.5
  end;
  v_expected_p1 := 1.0 / (1 + power(10, (v_p2_elo - v_p1_elo) / 400.0));
  v_p1_new := round(v_p1_elo + k * (v_p1_score - v_expected_p1));
  v_p2_new := round(v_p2_elo + k * ((1 - v_p1_score) - (1 - v_expected_p1)));

  update public.profiles set elo = v_p1_new where id = v_duel.p1;
  if not v_duel.is_bot then
    update public.profiles set elo = v_p2_new where id = v_duel.p2;
  end if;

  if v_duel.p1_rounds > v_duel.p2_rounds then
    v_winner := v_duel.p1; v_loser := v_duel.p2;
  elsif v_duel.p2_rounds > v_duel.p1_rounds then
    v_winner := v_duel.p2; v_loser := v_duel.p1;
  end if;

  update public.duels set
    status = 'complete', winner = v_winner,
    p1_elo_before = v_p1_elo, p2_elo_before = v_p2_elo,
    p1_elo_after = v_p1_new, p2_elo_after = v_p2_new
  where id = p_duel_id;

  -- Payout: winner +200 coins +250 XP, loser +40 coins +80 XP (§24). A draw
  -- pays neither side the winner bonus; both get the loser's consolation.
  if v_winner = v_duel.p1 then
    perform public._grant_currency(v_duel.p1, 'coins', 200, 'duel_win', p_duel_id);
    update public.profiles set xp = xp + 250 where id = v_duel.p1;
    if not v_duel.is_bot then
      perform public._grant_currency(v_duel.p2, 'coins', 40, 'duel_loss', p_duel_id);
      update public.profiles set xp = xp + 80 where id = v_duel.p2;
    end if;
  elsif v_winner = v_duel.p2 then
    if not v_duel.is_bot then
      perform public._grant_currency(v_duel.p2, 'coins', 200, 'duel_win', p_duel_id);
      update public.profiles set xp = xp + 250 where id = v_duel.p2;
    end if;
    perform public._grant_currency(v_duel.p1, 'coins', 40, 'duel_loss', p_duel_id);
    update public.profiles set xp = xp + 80 where id = v_duel.p1;
  end if;

  return jsonb_build_object(
    'winner', v_winner, 'p1Rounds', v_duel.p1_rounds, 'p2Rounds', v_duel.p2_rounds,
    'p1EloAfter', v_p1_new, 'p2EloAfter', v_p2_new
  );
end;
$$;

-- Bot-duel settlement — the only duel shape the Flutter app currently plays
-- (`DuelPlayCubit` simulates all five rounds, and the bot, entirely
-- client-side; `MatchmakingCubit` only ever calls `fetchBotOpponent`, never
-- a real-opponent path — see plan 006's Research findings). Rather than
-- route a single-client bot duel through the full `duels` +
-- `submit_duel_answer` + `resolve_duel_round` machinery above (built for
-- real two-client realtime play, per Design Bible §24), this is a single
-- RPC the client calls once, after `DuelPlayCubit._finish()`, with the
-- already-played round history — it persists the result, updates ELO/
-- currency, and checks duel-related achievements. `p_rounds` shape:
-- [{"roundNumber": int, "playerCorrect": bool, "playerAnswerSeconds": int}],
-- matching `DuelRoundRecord` minus the opponent's own fields (a bot has no
-- profile row to protect, so its half of the round isn't re-verified
-- server-side the way a real opponent's would need to be — see the note in
-- plan 006 on why this function is explicitly bot-only and must not be
-- reused for a real-opponent duel without adding that verification).
create or replace function public.submit_bot_duel(
  p_opponent_elo integer,
  p_player_rounds_won smallint,
  p_opponent_rounds_won smallint,
  p_rounds jsonb
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_duel_id uuid;
  v_p1_elo integer;
  v_is_victory boolean := p_player_rounds_won > p_opponent_rounds_won;
  v_expected numeric;
  v_score numeric;
  v_elo_after integer;
  v_coins integer;
  v_xp integer;
  v_longest_streak integer := 0;
  v_streak integer := 0;
  v_round jsonb;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select elo into v_p1_elo from public.profiles where id = v_user_id;

  v_score := case when v_is_victory then 1
    when p_player_rounds_won = p_opponent_rounds_won then 0.5
    else 0 end;
  v_expected := 1.0 / (1 + power(10, (p_opponent_elo - v_p1_elo) / 400.0));
  -- Half the normal K for a bot opponent — keeps ranked ELO movement mostly
  -- driven by real opponents once those exist, without leaving bot duels
  -- worth nothing.
  v_elo_after := round(v_p1_elo + 16 * (v_score - v_expected));

  v_coins := case when v_is_victory then 200 else 40 end;
  v_xp := case when v_is_victory then 250 else 80 end;

  insert into public.duels (
    p1, is_bot, question_ids, p1_rounds, p2_rounds, winner, status,
    p1_elo_before, p1_elo_after
  ) values (
    v_user_id, true, '{}', p_player_rounds_won, p_opponent_rounds_won,
    case when v_is_victory then v_user_id else null end, 'complete',
    v_p1_elo, v_elo_after
  ) returning id into v_duel_id;

  update public.profiles set elo = v_elo_after where id = v_user_id;
  perform public._grant_currency(v_user_id, 'coins', v_coins, 'duel_bot_result', v_duel_id);
  update public.profiles set xp = xp + v_xp where id = v_user_id;

  for v_round in select * from jsonb_array_elements(p_rounds) loop
    if (v_round ->> 'playerCorrect')::boolean then
      v_streak := v_streak + 1;
      v_longest_streak := greatest(v_longest_streak, v_streak);
    else
      v_streak := 0;
    end if;
  end loop;

  -- badge_duelist: 10 duel wins. Checked (and, if newly met, inserted) here
  -- rather than in _check_level_achievements, which is level-attempt-shaped.
  if v_is_victory
     and (select count(*) from public.duels where p1 = v_user_id and is_bot and winner = v_user_id) >= 10
     and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'badge_duelist')
  then
    insert into public.user_achievements (user_id, achievement_id, unlocked_at)
    values (v_user_id, 'badge_duelist', now());
    perform public._grant_currency(v_user_id, 'coins',
      (select coin_reward from public.achievements where id = 'badge_duelist'),
      'achievement_unlocked', null);
  end if;

  return jsonb_build_object(
    'duelId', v_duel_id,
    'isVictory', v_is_victory,
    'eloBefore', v_p1_elo,
    'eloAfter', v_elo_after,
    'coinsEarned', v_coins,
    'xpEarned', v_xp,
    'newlyEarnedBadgeIds', case
      when exists (select 1 from public.user_achievements
                   where user_id = v_user_id and achievement_id = 'badge_duelist'
                   and unlocked_at >= now() - interval '5 seconds')
      then jsonb_build_array('badge_duelist')
      else '[]'::jsonb
    end
  );
end;
$$;

grant execute on function public.submit_bot_duel(integer, smallint, smallint, jsonb) to authenticated;

-- ============================================================================
-- SHOP: free coins for a watched rewarded ad
--
-- The design bible is explicit that a client-claimed ad reward is trivially
-- spoofed and names a real server-to-server ad-network postback
-- (`ad-reward`, one of the seven Edge Functions) as the hardened answer.
-- That postback needs a URL registered in each ad network's own dashboard
-- and is meaningfully more setup than v1 needs to ship with — see plan 006's
-- Assumptions for the trade-off. This function is the pragmatic middle
-- ground: called by the client immediately after the Google Mobile Ads SDK's
-- own `onUserEarnedReward` callback fires (which happens only after a real
-- ad genuinely finished playing — the SDK itself is the anti-fraud boundary
-- for *whether an ad played*; this function's job is only to cap *how many
-- times a day* that can be cashed in, which a purely client-side counter
-- cannot enforce since the app can be killed and relaunched to reset one).
-- ============================================================================

create or replace function public.claim_ad_reward()
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_free_ads_per_day constant integer := 3; -- keep in sync with Remote Config's ad cap, doc 02
  v_reward_coins constant integer := 50;
  v_watched_today integer;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select count(*) into v_watched_today from public.wallet_ledger
    where user_id = v_user_id and reason = 'ad_reward'
      and created_at >= date_trunc('day', now() at time zone 'utc');

  if v_watched_today >= v_free_ads_per_day then
    raise exception 'ad_cap_reached';
  end if;

  perform public._grant_currency(v_user_id, 'coins', v_reward_coins, 'ad_reward', null);

  return jsonb_build_object(
    'coinsEarned', v_reward_coins,
    'freeAdsWatchedToday', v_watched_today + 1,
    'freeAdsPerDay', v_free_ads_per_day
  );
end;
$$;

grant execute on function public.claim_ad_reward() to authenticated;

-- ============================================================================
-- LEADERBOARDS: materialized views
--
-- One row per (user, category, subcategory, country) tuple per window,
-- carrying global / country / category / subcategory rank so a single view
-- serves every LeaderboardScope × the category board, with the client
-- choosing which rank_* column to read. Refresh cadence: see
-- docs/backend/01-supabase-project-setup.md's pg_cron section — weekly every
-- 2 minutes (Design Bible §23), monthly/all-time every 15.
-- ============================================================================

create materialized view public.lb_weekly as
select
  user_id, subcategory_id, category_id, country_code,
  sum(points) as points,
  rank() over (partition by subcategory_id order by sum(points) desc) as rank_subcategory,
  rank() over (partition by category_id order by sum(points) desc) as rank_category,
  rank() over (partition by country_code order by sum(points) desc) as rank_country,
  rank() over (order by sum(points) desc) as rank_global
from public.score_events
where occurred_at >= date_trunc('week', now())
group by user_id, subcategory_id, category_id, country_code;

create unique index lb_weekly_pk on public.lb_weekly (user_id, subcategory_id, category_id, country_code);

create materialized view public.lb_monthly as
select
  user_id, subcategory_id, category_id, country_code,
  sum(points) as points,
  rank() over (partition by subcategory_id order by sum(points) desc) as rank_subcategory,
  rank() over (partition by category_id order by sum(points) desc) as rank_category,
  rank() over (partition by country_code order by sum(points) desc) as rank_country,
  rank() over (order by sum(points) desc) as rank_global
from public.score_events
where occurred_at >= date_trunc('month', now())
group by user_id, subcategory_id, category_id, country_code;

create unique index lb_monthly_pk on public.lb_monthly (user_id, subcategory_id, category_id, country_code);

create materialized view public.lb_alltime as
select
  user_id, subcategory_id, category_id, country_code,
  sum(points) as points,
  rank() over (partition by subcategory_id order by sum(points) desc) as rank_subcategory,
  rank() over (partition by category_id order by sum(points) desc) as rank_category,
  rank() over (partition by country_code order by sum(points) desc) as rank_country,
  rank() over (order by sum(points) desc) as rank_global
from public.score_events
group by user_id, subcategory_id, category_id, country_code;

create unique index lb_alltime_pk on public.lb_alltime (user_id, subcategory_id, category_id, country_code);

-- Materialized views have no RLS of their own — grant read to authenticated
-- and rely on the fact that score_events carries nothing sensitive.
grant select on public.lb_weekly, public.lb_monthly, public.lb_alltime to authenticated, anon;

create or replace function public._refresh_leaderboards()
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  refresh materialized view concurrently public.lb_weekly;
  refresh materialized view concurrently public.lb_monthly;
  refresh materialized view concurrently public.lb_alltime;
end;
$$;

select cron.schedule('refresh-lb-weekly', '*/2 * * * *', $$select public._refresh_leaderboards();$$);

-- ============================================================================
-- SCHEDULED: daily-rollover (pg_cron, 00:00 UTC)
-- ============================================================================

create or replace function public._daily_rollover()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_next_date date := (now() at time zone 'utc')::date + 1;
  v_question_ids uuid[];
begin
  -- 1. Build tomorrow's daily challenge: 10 live questions spread across
  --    categories, same for every player worldwide.
  if not exists (select 1 from public.daily_challenges where challenge_date = v_next_date) then
    select array_agg(id) into v_question_ids from (
      select id from public.questions where status = 'live' order by random() limit 10
    ) sub;
    insert into public.daily_challenges (challenge_date, question_ids)
    values (v_next_date, v_question_ids);
  end if;

  -- 2. Recalibrate question difficulty from live pass rates (seen_count /
  --    correct_count accumulated by submit_level_attempt's answer log).
  update public.questions
    set difficulty = least(5, greatest(1, round(
      5 - 4.0 * nullif(correct_count, 0) / nullif(seen_count, 0)
    )))
    where seen_count > 50; -- only recalibrate once a question has enough samples

  -- 3. Assign any player with no current-week cohort into a league cohort
  --    of their tier, capped at 30 members, creating a new cohort as needed.
  perform public._assign_weekly_league_cohorts();

  -- 4. Promote/relegate last week's cohorts (top 10 up a tier, bottom 5
  --    down), then update profiles.league to match.
  perform public._settle_weekly_leagues();
end;
$$;

create or replace function public._assign_weekly_league_cohorts()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_week date := date_trunc('week', now())::date;
  v_profile record;
  v_cohort_id uuid;
begin
  for v_profile in
    select p.id, p.league from public.profiles p
    where not exists (
      select 1 from public.league_memberships lm
      join public.league_cohorts lc on lc.id = lm.cohort_id
      where lm.user_id = p.id and lc.week_start = v_week
    )
  loop
    select lc.id into v_cohort_id from public.league_cohorts lc
      where lc.tier = v_profile.league and lc.week_start = v_week
      and (select count(*) from public.league_memberships where cohort_id = lc.id) < 30
      limit 1;

    if v_cohort_id is null then
      insert into public.league_cohorts (tier, week_start) values (v_profile.league, v_week)
        returning id into v_cohort_id;
    end if;

    insert into public.league_memberships (cohort_id, user_id) values (v_cohort_id, v_profile.id)
      on conflict do nothing;
  end loop;
end;
$$;

create or replace function public._settle_weekly_leagues()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_last_week date := date_trunc('week', now())::date - 7;
  v_tiers text[] := array['bronze', 'silver', 'gold', 'platinum', 'diamond'];
  v_cohort record;
  v_member record;
  v_rank integer;
  v_size integer;
begin
  for v_cohort in select * from public.league_cohorts where week_start = v_last_week loop
    v_size := (select count(*) from public.league_memberships where cohort_id = v_cohort.id);
    v_rank := 0;
    for v_member in
      select user_id from public.league_memberships
      where cohort_id = v_cohort.id order by points desc
    loop
      v_rank := v_rank + 1;
      if v_rank <= 10 and array_position(v_tiers, v_cohort.tier) < array_length(v_tiers, 1) then
        update public.profiles set league = v_tiers[array_position(v_tiers, v_cohort.tier) + 1]
          where id = v_member.user_id;
      elsif v_rank > v_size - 5 and array_position(v_tiers, v_cohort.tier) > 1 then
        update public.profiles set league = v_tiers[array_position(v_tiers, v_cohort.tier) - 1]
          where id = v_member.user_id;
      end if;
    end loop;
  end loop;
end;
$$;

select cron.schedule('daily-rollover', '0 0 * * *', $$select public._daily_rollover();$$);

-- ============================================================================
-- GRANTS
--
-- RPCs the client calls directly. Everything else in this file (the `_`
-- prefixed helpers) is internal and intentionally has no grant to
-- `authenticated` — only the functions below are meant to be reachable via
-- supabase.rpc(...) or an Edge Function running as the caller's own JWT.
-- ============================================================================

grant execute on function public.start_level_attempt(uuid, smallint, text) to authenticated;
grant execute on function public.submit_level_attempt(uuid, jsonb, boolean, text) to authenticated;
grant execute on function public.play_daily_challenge(boolean[]) to authenticated;
grant execute on function public.submit_duel_answer(uuid, smallint, smallint, integer) to authenticated;
grant execute on function public.resolve_duel_round(uuid, smallint) to authenticated;
grant execute on function public.resolve_duel(uuid) to authenticated;
