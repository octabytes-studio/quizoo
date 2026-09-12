-- ============================================================================
-- 20260910090300_ladder_rpc_rewrite.sql
--
-- Plan .claude/plans/007-difficulty-ladder-language-question-bank.md, Phase 1.
--
-- Rewrites start_level_attempt/submit_level_attempt onto the 50-level/5-tier
-- ladder (20260910090000) and the per-language question bank with anti-repeat
-- tracking (20260910090100/20260910090200), replacing the 4-band/20-level
-- hardcoded functions and the question_i18n-keyed grading they used before.
--
-- Signatures are unchanged on both functions -- the Flutter call sites
-- (quiz_play_api.dart) need no RPC-name or param change, only new fields in
-- the response shape they already parse loosely as a Map.
--
-- Per plan 007's Assumption #2 (explicit human sign-off obtained before this
-- file was written): correct_index stays on start_level_attempt's response,
-- exactly as before. submit_level_attempt re-deriving correctness
-- server-side, never trusting the client's own claim, remains the actual
-- anti-cheat boundary -- this migration does not attempt the source spec's
-- "hide correct_index" requirement.
-- ============================================================================

begin;

alter table questions add column if not exists tts_excluded boolean not null default false;

-- The old 4-band/20-level ladder this migration replaces. Nothing calls
-- these once start_level_attempt/submit_level_attempt are rewritten below —
-- left defined, they'd be exactly the hardcoded-ladder duplication this plan
-- exists to eliminate (plan 007, Research findings).
drop function if exists public._question_difficulty_range(smallint);
drop function if exists public._seconds_for_level(smallint);
drop function if exists public._difficulty_band_for_level(smallint);

-- ---------------------------------------------------------------------------
-- start_level_attempt: tier/boss lookup now comes from difficulty_tiers via
-- get_difficulty_for_level()/is_boss_level() instead of the old 4-band
-- functions; questions come from the per-language anti-repeat pool
-- (get_level_questions()'s ranking rule, inlined here per Assumption #4)
-- instead of a live shuffle over questions/question_i18n with no history
-- tracking. level_attempts.id is created first and reused as the same id in
-- level_attempt_question_sets -- one attempt concept, not two.
-- ---------------------------------------------------------------------------
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

  perform public._settle_hearts(v_user_id);

  if (select hearts from public.profiles where id = v_user_id) <= 0 then
    raise exception 'out_of_hearts' using errcode = 'P0001';
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

  insert into public.level_attempts (user_id, subcategory_id, level, seed, locale, is_boss)
  values (v_user_id, p_subcategory_id, p_level, v_seed, p_locale, v_is_boss)
  returning id into v_attempt_id;

  perform public._grant_currency(v_user_id, 'hearts', -1, 'level_attempt_start', v_attempt_id);

  -- Anti-repeat ranked pool: never-seen first (nulls first), then oldest-seen
  -- first once every question in the pool has been seen at least once — see
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
      'ttsExcluded', q.tts_excluded
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
$$;

-- ---------------------------------------------------------------------------
-- _stars_for: percentage bands replace the old fixed-count-of-20 breakpoints,
-- so a level with a different questions_per_level than 20 (a tier override,
-- or app_settings.questions_per_level edited live) can still reach 3 stars.
-- At N=20 this reproduces the exact old 12/16/20 breakpoints (60%/80%/100%),
-- so today's behaviour is unchanged.
-- ---------------------------------------------------------------------------
drop function if exists public._stars_for(integer);

create or replace function public._stars_for(p_correct_count integer, p_total_count integer)
returns smallint
language sql immutable
as $$
  select case
    when p_total_count <= 0 then 0::smallint
    when p_correct_count >= p_total_count then 3::smallint
    when p_correct_count::numeric / p_total_count >= 0.8 then 2::smallint
    when p_correct_count::numeric / p_total_count >= 0.6 then 1::smallint
    else 0::smallint
  end;
$$;

-- ---------------------------------------------------------------------------
-- submit_level_attempt: grades by question_id via
-- level_attempt_question_sets/questions.correct_index instead of
-- question_i18n keyed by (question_id, locale); seconds-per-question comes
-- from the resolved tier instead of the old 4-band function; the flawless
-- check drops the hardcoded 20; stars are now percentage-based; graded_at is
-- written on the matching level_attempt_question_sets row.
-- ---------------------------------------------------------------------------
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

  v_seconds_total := (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question;
  v_question_count := jsonb_array_length(p_answers);
  v_is_complete := p_ending = 'finished';

  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    v_is_correct := false;

    if v_answer ->> 'action' = 'answered' and v_answer ->> 'chosenIndex' is not null then
      -- Graded via level_attempt_question_sets, not a bare by-id lookup on
      -- questions: this confirms the submitted question_id was actually part
      -- of *this* attempt's served set, so a client can't use submit as an
      -- oracle to probe correct_index for questions it was never dealt.
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

  v_is_flawless := v_is_complete and v_question_count > 0 and v_correct_count = v_question_count;
  v_stars := case when v_is_complete then public._stars_for(v_correct_count, v_question_count) else 0 end;

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

-- Signatures unchanged, but re-granted for clarity/idempotency.
grant execute on function public.start_level_attempt(uuid, smallint, text) to authenticated;
grant execute on function public.submit_level_attempt(uuid, jsonb, boolean, text) to authenticated;

commit;
