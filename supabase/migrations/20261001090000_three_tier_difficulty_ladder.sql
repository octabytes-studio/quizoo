-- ============================================================================
-- 20261001090000_three_tier_difficulty_ladder.sql
--
-- Plan: .claude/plans/020-three-tier-difficulty-ladder.md
--
-- Collapses the ladder from 5 tiers / 50 levels / flat 20 questions per
-- level to 3 tiers / 30 levels with per-tier question counts and timers:
--
--   Easy   1-10  10 questions  20s/question
--   Medium 11-20 15 questions  15s/question
--   Hard   21-30 20 questions  10s/question
--
-- Steps (see plan Phase 1):
--   A. Upsert easy/medium/hard difficulty_tiers rows with the new shape.
--   B. Re-home the 8 live expert/master seed questions (and any
--      level_attempt_question_sets rows, defensively -- none exist live) to
--      hard, then delete the expert/master tier rows.
--   C. Add level_attempts.seconds_per_question, recording the clock an
--      attempt was actually played under so a mid-flight timer change can't
--      distort grading. Backfilled from the OLD 5-tier ladder (every live
--      row today is level 1-10, i.e. 30s).
--   D. Tighten the three level-range check constraints from 1-50 to 1-30.
--      Phase 0 confirmed no live row is above level 30.
--   E. submit_level_attempt: derive the seconds-per-question from the
--      attempt's own recorded clock (falling back to the current tier for
--      pre-migration rows with a null clock), and derive the question count
--      from the served question set rather than trusting the client's
--      answers array length (plan Open question 2).
--   F. v_thin_question_pools: the "thin pool" threshold becomes per-tier
--      (override_questions_per_level * 3) instead of the global default.
--   G. Refresh app_settings descriptions to describe the new per-tier
--      overrides.
--
-- start_level_attempt and submit_level_attempt are rewritten from their live
-- bodies (fetched via Phase 0 pre-flight; submit_level_attempt's live
-- signature carries a 5th `p_local_hour smallint default null` parameter
-- added by 20260919194353_real_achievement_engine.sql, newer than the
-- signature this plan was drafted against). Every other line of both
-- functions is byte-identical to the live bodies.
--
-- Rollback: re-upsert the 5-tier rows from 20260910090000_difficulty_ladder_v2.sql,
-- widen the three constraints back to 1-50, and restore both RPC bodies from
-- 20260917100200_start_level_attempt_audio_url.sql /
-- 20260919194353_real_achievement_engine.sql. Re-homed expert/master
-- questions can stay on hard. level_attempts.seconds_per_question is
-- harmless to keep.
--
-- Never `supabase db push` -- apply via MCP apply_migration or
-- `supabase db query --linked -f`, matching plans 007/017/020.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- A. Tier rows: easy/medium/hard get the new seconds, ranges and per-tier
--    question counts. Ids are stable (on conflict do update), so existing FKs
--    from questions/level_attempt_question_sets to these three rows keep working.
-- ----------------------------------------------------------------------------
insert into public.difficulty_tiers
  (code, label, seconds_per_question, level_start, level_end, sort_order, override_questions_per_level)
values
  ('easy',   'Easy',   20, 1,  10, 1, 10),
  ('medium', 'Medium', 15, 11, 20, 2, 15),
  ('hard',   'Hard',   10, 21, 30, 3, 20)
on conflict (code) do update set
  label = excluded.label,
  seconds_per_question = excluded.seconds_per_question,
  level_start = excluded.level_start,
  level_end = excluded.level_end,
  sort_order = excluded.sort_order,
  override_questions_per_level = excluded.override_questions_per_level;

-- ----------------------------------------------------------------------------
-- B. Retire expert/master: re-home their questions (and, defensively, any
--    level_attempt_question_sets rows -- none exist live) to hard, then
--    delete the two tier rows. trg_enforce_question_language_match only
--    fires on language_code/subcategory_id changes, so re-tiering the
--    questions doesn't trip it.
-- ----------------------------------------------------------------------------
update public.questions q
   set difficulty_tier_id = (select id from public.difficulty_tiers where code = 'hard'),
       difficulty = 3
 where q.difficulty_tier_id in (select id from public.difficulty_tiers where code in ('expert', 'master'));

update public.level_attempt_question_sets s
   set difficulty_tier_id = (select id from public.difficulty_tiers where code = 'hard')
 where s.difficulty_tier_id in (select id from public.difficulty_tiers where code in ('expert', 'master'));

delete from public.difficulty_tiers where code in ('expert', 'master');

-- ----------------------------------------------------------------------------
-- C. Record the clock per attempt.
-- ----------------------------------------------------------------------------
alter table public.level_attempts add column if not exists seconds_per_question smallint;

-- Backfill from the OLD (5-tier) ladder the attempt was actually played
-- under -- every live row today is level 1-10, i.e. 30s.
update public.level_attempts set seconds_per_question = case
    when level <= 10 then 30
    when level <= 20 then 25
    when level <= 30 then 20
    when level <= 40 then 15
    else 10
  end
 where seconds_per_question is null;

-- ----------------------------------------------------------------------------
-- D. Tighten the three level-range constraints from 1-50 to 1-30. Fails the
--    whole transaction if any row is above 30 (none live, per Phase 0).
-- ----------------------------------------------------------------------------
alter table public.level_progress drop constraint if exists level_progress_level_range;
alter table public.level_progress add constraint level_progress_level_range check (level between 1 and 30);

alter table public.level_attempts drop constraint if exists level_attempts_level_range;
alter table public.level_attempts add constraint level_attempts_level_range check (level between 1 and 30);

alter table public.level_attempt_question_sets drop constraint if exists level_attempt_question_sets_level_check;
alter table public.level_attempt_question_sets add constraint level_attempt_question_sets_level_range check (level between 1 and 30);

-- ----------------------------------------------------------------------------
-- start_level_attempt: rewritten from the live body (Phase 0). One change:
-- the level_attempts insert also writes seconds_per_question.
-- ----------------------------------------------------------------------------
create or replace function public.start_level_attempt(p_subcategory_id uuid, p_level smallint, p_locale text default 'en'::text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_attempt_id uuid;
  v_seed text := encode(extensions.gen_random_bytes(16), 'hex');
  v_tier public.difficulty_tiers;
  v_is_boss boolean;
  v_n int;
  v_pool_ids uuid[];
  v_pool_size int;
  v_padded boolean := false;
  v_questions jsonb;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select * into v_tier from public.get_difficulty_for_level(p_level);
  if v_tier.id is null then
    raise exception 'no difficulty tier configured for level %', p_level;
  end if;
  v_is_boss := public.is_boss_level(p_level);

  select coalesce(
    v_tier.override_questions_per_level,
    (select (value #>> '{}')::int from public.app_settings where key = 'questions_per_level'),
    20
  ) into v_n;

  insert into public.level_attempts (user_id, subcategory_id, level, seed, locale, is_boss, seconds_per_question)
  values (v_user_id, p_subcategory_id, p_level, v_seed, p_locale, v_is_boss, v_tier.seconds_per_question)
  returning id into v_attempt_id;

  -- Anti-repeat ranked pool: never-seen first (nulls first), then oldest-seen
  -- first once every question in the pool has been seen at least once -- see
  -- get_level_questions()'s doc comment (20260910090200) for the full
  -- reasoning; inlined here rather than called, so there is exactly one path
  -- that starts a level.
  select array_agg(id) into v_pool_ids
  from (
    select q.id
    from public.questions q
    left join public.user_question_history h
      on h.question_id = q.id and h.user_id = v_user_id
    where q.subcategory_id = p_subcategory_id
      and q.difficulty_tier_id = v_tier.id
      and q.language_code = p_locale
      and q.status = 'live'
    order by h.last_seen_at asc nulls first, random()
  ) ranked;

  v_pool_size := coalesce(array_length(v_pool_ids, 1), 0);
  if v_pool_size = 0 then
    raise exception 'no live questions for subcategory %, tier %, language %',
      p_subcategory_id, v_tier.code, p_locale;
  end if;
  if v_pool_size < v_n then
    v_padded := true; -- pool smaller than N -- tiled below, repeats unavoidable
  end if;

  select jsonb_agg(row order by random()) into v_questions
  from (
    select jsonb_build_object(
      'id', q.id,
      'subcategoryId', q.subcategory_id,
      'difficulty', q.difficulty,
      'text', q.prompt,
      'options', q.options,
      'correctIndex', q.correct_index,
      'explanation', q.explanation,
      'hasImage', q.kind = 'image',
      'imageAsset', q.media_url,
      'ttsExcluded', q.tts_excluded,
      'audioUrl', q.audio_url
    ) as row
    from (
      select v_pool_ids[((n - 1) % v_pool_size) + 1] as qid
      from generate_series(1, v_n) as n
    ) numbered
    join public.questions q on q.id = numbered.qid
  ) sub;

  insert into public.level_attempt_question_sets
    (id, user_id, subcategory_id, difficulty_tier_id, level, language_code, question_ids, is_repeat_padded)
  select v_attempt_id, v_user_id, p_subcategory_id, v_tier.id, p_level, p_locale,
         array_agg((row ->> 'id')::uuid), v_padded
  from jsonb_array_elements(v_questions) row;

  -- Deduplicated before the upsert: a padded (thin-pool) level can serve the
  -- same question_id more than once in v_questions, and Postgres's ON
  -- CONFLICT DO UPDATE raises "command cannot affect row a second time" if
  -- the same conflict target repeats within one statement's row source.
  insert into public.user_question_history (user_id, question_id, times_seen, first_seen_at, last_seen_at)
  select v_user_id, qid, 1, now(), now()
  from (
    select distinct (row ->> 'id')::uuid as qid
    from jsonb_array_elements(v_questions) row
  ) distinct_qids
  on conflict (user_id, question_id)
  do update set times_seen   = user_question_history.times_seen + 1,
                last_seen_at = now();

  update public.questions set seen_count = seen_count + 1
    where id in (select (row ->> 'id')::uuid from jsonb_array_elements(v_questions) row);

  return jsonb_build_object(
    'attemptId', v_attempt_id,
    'secondsPerQuestion', v_tier.seconds_per_question,
    'isBoss', v_is_boss,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
end;
$function$;

grant execute on function public.start_level_attempt(uuid, smallint, text) to authenticated;

-- ----------------------------------------------------------------------------
-- submit_level_attempt: rewritten from the live body (Phase 0), which carries
-- a p_local_hour param not present in the plan's assumed signature. Exactly
-- two changes from the live body:
--   1. v_seconds_total comes from the attempt's own recorded clock first
--      (falls back to the current tier for pre-migration rows).
--   2. v_question_count comes from the served question set, not the length
--      of the client-sent answers array (plan Open question 2).
-- ----------------------------------------------------------------------------
create or replace function public.submit_level_attempt(p_attempt_id uuid, p_answers jsonb, p_used_power_up boolean, p_ending text, p_local_hour smallint default null::smallint)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
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
  v_daily_new_badges text[] := '{}';
  v_correctness_pattern boolean[] := '{}';
  v_correct_seconds_sum integer := 0;
  v_correct_seconds_count integer := 0;
  v_answered_count integer := 0;
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

  v_seconds_total := coalesce(
    v_attempt.seconds_per_question,
    (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question
  );

  select coalesce(array_length(s.question_ids, 1), jsonb_array_length(p_answers))
    into v_question_count
    from public.level_attempt_question_sets s where s.id = p_attempt_id;
  v_question_count := coalesce(v_question_count, jsonb_array_length(p_answers));

  v_is_complete := p_ending = 'finished';

  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    v_is_correct := false;

    if v_answer ->> 'action' = 'answered' and v_answer ->> 'chosenIndex' is not null then
      select q.correct_index into v_correct_index
      from public.level_attempt_question_sets s
      join public.questions q on q.id = (v_answer ->> 'questionId')::uuid
      where s.id = p_attempt_id
        and (v_answer ->> 'questionId')::uuid = any (s.question_ids);

      update public.questions set correct_count = correct_count + 1
        where id = (v_answer ->> 'questionId')::uuid
        and v_correct_index = (v_answer ->> 'chosenIndex')::smallint;

      v_is_correct := v_correct_index is not null
        and v_correct_index = (v_answer ->> 'chosenIndex')::smallint;
    end if;

    if v_answer ->> 'action' = 'answered' then
      v_answered_count := v_answered_count + 1;
    end if;
    v_correctness_pattern := array_append(v_correctness_pattern, v_is_correct);

    if v_is_correct then
      v_streak := v_streak + 1;
      v_longest_streak := greatest(v_longest_streak, v_streak);
      v_correct_count := v_correct_count + 1;
      v_line_score := round(
        (100 + public._speed_bonus((v_answer ->> 'secondsLeft')::integer, v_seconds_total))
        * public._difficulty_multiplier(v_attempt.level)
        * public._streak_multiplier(v_streak - 1)
      );
      v_score := v_score + v_line_score;
      v_correct_seconds_sum := v_correct_seconds_sum
        + (v_seconds_total - coalesce((v_answer ->> 'secondsLeft')::int, 0));
      v_correct_seconds_count := v_correct_seconds_count + 1;
    else
      v_streak := 0;
    end if;
  end loop;

  v_is_flawless := v_is_complete and v_question_count > 0 and v_correct_count = v_question_count;
  v_stars := case when v_is_complete then public._stars_for(v_correct_count, v_question_count) else 0 end;

  if v_is_complete then
    if not p_used_power_up then
      v_score := v_score + 250;
    end if;
    if v_is_flawless then
      v_score := v_score + 1000;
    end if;
    if v_attempt.is_boss then
      v_score := v_score * 2;
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

  update public.level_attempt_question_sets set graded_at = now() where id = p_attempt_id;

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

    v_daily_new_badges := public._touch_daily_streak(v_user_id);

    update public.league_memberships lm
      set points = lm.points + v_score
      from public.league_cohorts lc
      where lm.cohort_id = lc.id and lm.user_id = v_user_id
        and lc.week_start = date_trunc('week', now())::date;
  end if;

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
    'answeredCount', v_answered_count,
    'localHour', p_local_hour
  ));
  v_new_badges := array_cat(v_new_badges, v_daily_new_badges);

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
$function$;

grant execute on function public.submit_level_attempt(uuid, jsonb, boolean, text, smallint) to authenticated;

-- ----------------------------------------------------------------------------
-- F. v_thin_question_pools: threshold becomes per-tier
--    (override_questions_per_level, falling back to the global default * 3).
--    Column names and order unchanged (create or replace view can't rename
--    or drop columns).
-- ----------------------------------------------------------------------------
create or replace view public.v_thin_question_pools as
select
  sc.id as subcategory_id,
  sc.slug as subcategory_slug,
  dt.code as difficulty_code,
  q.language_code,
  count(*) as live_question_count,
  coalesce(
    dt.override_questions_per_level,
    (select (app_settings.value #>> '{}')::integer from public.app_settings where app_settings.key = 'questions_per_level'),
    20
  ) * 3 as recommended_minimum
from public.questions q
  join public.subcategories sc on sc.id = q.subcategory_id
  join public.difficulty_tiers dt on dt.id = q.difficulty_tier_id
where q.status = 'live'
group by sc.id, sc.slug, dt.code, dt.override_questions_per_level, q.language_code
having count(*) < coalesce(
    dt.override_questions_per_level,
    (select (app_settings.value #>> '{}')::integer from public.app_settings where app_settings.key = 'questions_per_level'),
    20
  ) * 3
order by count(*);

-- ----------------------------------------------------------------------------
-- G. Settings copy.
-- ----------------------------------------------------------------------------
update public.app_settings set description =
  'Fallback questions per level attempt when a tier has no override_questions_per_level. Tiers override it: Easy 10 / Medium 15 / Hard 20.'
 where key = 'questions_per_level';
update public.app_settings set description =
  'Every Nth level is a boss level (double payout). With 10-level tiers this lands boss levels on 10/20/30 -- the last level of every tier.'
 where key = 'boss_level_interval';

commit;
