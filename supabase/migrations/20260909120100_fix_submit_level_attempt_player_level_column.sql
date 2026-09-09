-- ============================================================================
-- Fix: submit_level_attempt() selected a non-existent `level` column from
-- _player_level_from_xp()'s result set (that function's table returns
-- `player_level`, not `level`) — "column level does not exist" (42703) on
-- every completed level attempt, right after xp/coins are awarded.
-- ============================================================================

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
