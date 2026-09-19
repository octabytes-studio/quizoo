-- Plan 014: Real Achievements & Badges — Phase 1
-- Generic criteria-driven evaluator + reward mechanics, wired into the three
-- gameplay hooks that can unlock a badge (level completion, bot duels, the
-- daily streak touch). Replaces the partial `_check_level_achievements` and
-- `submit_bot_duel`'s inline one-off badge_duelist check.

-- ---------------------------------------------------------------------------
-- 1. Idempotent unlock + reward grant
-- ---------------------------------------------------------------------------
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

  perform public._grant_currency(
    p_user_id, 'coins', v_reward.coin_reward, 'achievement_unlocked', null
  );
  if v_reward.gem_reward > 0 then
    perform public._grant_currency(
      p_user_id, 'gems', v_reward.gem_reward, 'achievement_unlocked', null
    );
  end if;
  return true;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Running-counter store for stateful criteria
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 3. The generic evaluator
-- ---------------------------------------------------------------------------
create or replace function public._evaluate_achievements(
  p_user_id uuid, p_event text, p_context jsonb
) returns text[]
language plpgsql security definer set search_path = public as $$
declare
  v_row record;
  v_newly text[] := '{}';

  -- level_attempt context
  v_is_flawless boolean := coalesce((p_context->>'isFlawless')::boolean, false);
  v_is_complete boolean := coalesce((p_context->>'isComplete')::boolean, false);
  v_is_boss boolean := coalesce((p_context->>'isBoss')::boolean, false);
  v_longest_streak int := coalesce((p_context->>'longestStreak')::int, 0);
  v_subcategory_id uuid := (p_context->>'subcategoryId')::uuid;
  v_level int := (p_context->>'level')::int;
  v_stars int := (p_context->>'stars')::int;
  v_ending text := p_context->>'ending';
  v_correctness_pattern jsonb := p_context->'correctnessPattern';
  v_correct_seconds_sum int := coalesce((p_context->>'correctSecondsSum')::int, 0);
  v_correct_seconds_count int := coalesce((p_context->>'correctSecondsCount')::int, 0);
  v_answered_count int := coalesce((p_context->>'answeredCount')::int, 0);
  v_local_hour int := (p_context->>'localHour')::int;
  v_total_bot_wins int := coalesce((p_context->>'totalBotWins')::int, 0);

  -- scratch, reused across branches
  v_count int;
  v_total int;
  v_streak int;
  v_reached boolean;
  v_best int;
  v_best_avg numeric;
  v_avg numeric;
  v_today date := (now() at time zone 'utc')::date;
  v_last_date date;
  v_category_id uuid;
  v_category_slug text;
  v_i int;
  v_correct boolean;
begin
  for v_row in
    select a.*, ua.progress as ua_progress
    from public.achievements a
    left join public.user_achievements ua
      on ua.user_id = p_user_id and ua.achievement_id = a.id
    where ua.unlocked_at is null
  loop
    case v_row.criteria ->> 'type'

      when 'level_flawless' then
        if p_event = 'level_attempt' and v_is_flawless then
          if public._unlock_achievement(p_user_id, v_row.id) then
            v_newly := array_append(v_newly, v_row.id);
          end if;
        end if;

      when 'in_level_streak' then
        if p_event = 'level_attempt' then
          v_best := greatest(coalesce((v_row.ua_progress->>'best')::int, 0), v_longest_streak);
          perform public._bump_achievement_progress(
            p_user_id, v_row.id, jsonb_build_object('best', v_best)
          );
          if v_longest_streak >= (v_row.criteria->>'streak')::int then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'boss_clear' then
        if p_event = 'level_attempt' and v_is_complete and v_is_boss then
          if public._unlock_achievement(p_user_id, v_row.id) then
            v_newly := array_append(v_newly, v_row.id);
          end if;
        end if;

      when 'category_flawless_count' then
        if p_event = 'level_attempt' and v_is_flawless then
          select c.slug into v_category_slug
          from public.subcategories s
          join public.categories c on c.id = s.category_id
          where s.id = v_subcategory_id;

          if v_category_slug = (v_row.criteria->>'category_slug') then
            v_count := coalesce((v_row.ua_progress->>'count')::int, 0) + 1;
            perform public._bump_achievement_progress(
              p_user_id, v_row.id, jsonb_build_object('count', v_count)
            );
            if v_count >= (v_row.criteria->>'count')::int then
              if public._unlock_achievement(p_user_id, v_row.id) then
                v_newly := array_append(v_newly, v_row.id);
              end if;
            end if;
          end if;
        end if;

      when 'category_three_star_sweep' then
        if p_event = 'level_attempt' and v_level = 20 and v_stars = 3 then
          select s.category_id into v_category_id
          from public.subcategories s where s.id = v_subcategory_id;

          if v_category_id is not null then
            select count(*) into v_total
            from public.subcategories
            where category_id = v_category_id and is_active;

            select count(*) into v_count
            from public.subcategories s
            join public.level_progress lp
              on lp.subcategory_id = s.id and lp.user_id = p_user_id
              and lp.level = 20 and lp.stars = 3
            where s.category_id = v_category_id and s.is_active;

            if v_total > 0 and v_count >= v_total then
              if public._unlock_achievement(p_user_id, v_row.id) then
                v_newly := array_append(v_newly, v_row.id);
              end if;
            end if;
          end if;
        end if;

      when 'cross_level_correct_streak' then
        if p_event = 'level_attempt' then
          v_streak := coalesce((v_row.ua_progress->>'streak')::int, 0);
          v_reached := false;
          for v_i in 0 .. coalesce(jsonb_array_length(v_correctness_pattern), 0) - 1 loop
            v_correct := coalesce((v_correctness_pattern->>v_i)::boolean, false);
            if v_correct then
              v_streak := v_streak + 1;
            else
              v_streak := 0;
            end if;
            if v_streak >= (v_row.criteria->>'count')::int then
              v_reached := true;
            end if;
          end loop;
          if v_ending <> 'finished' then
            v_streak := 0;
          end if;
          perform public._bump_achievement_progress(
            p_user_id, v_row.id, jsonb_build_object('streak', v_streak)
          );
          if v_reached then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'perfect_week' then
        if p_event = 'level_attempt' and v_is_flawless then
          v_last_date := nullif(v_row.ua_progress->>'lastDate', '')::date;
          if v_last_date = v_today then
            v_streak := coalesce((v_row.ua_progress->>'streak')::int, 1);
          elsif v_last_date = v_today - 1 then
            v_streak := coalesce((v_row.ua_progress->>'streak')::int, 0) + 1;
          else
            v_streak := 1;
          end if;
          perform public._bump_achievement_progress(
            p_user_id, v_row.id,
            jsonb_build_object('streak', v_streak, 'lastDate', v_today)
          );
          if v_streak >= 7 then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'category_coverage' then
        if p_event = 'level_attempt' and v_is_complete then
          select count(distinct s.category_id) into v_count
          from public.level_attempts la
          join public.subcategories s on s.id = la.subcategory_id
          where la.user_id = p_user_id and la.ending = 'finished';

          select count(*) into v_total from public.categories where is_active;

          if v_total > 0 and v_count >= v_total then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'midnight_streak' then
        if p_event = 'level_attempt' and v_local_hour is not null
           and v_local_hour between 0 and 2 and v_answered_count > 0
        then
          v_last_date := nullif(v_row.ua_progress->>'lastNightDate', '')::date;
          if v_last_date is null or v_last_date <> v_today then
            v_count := coalesce((v_row.ua_progress->>'nights')::int, 0) + 1;
            perform public._bump_achievement_progress(
              p_user_id, v_row.id,
              jsonb_build_object('nights', v_count, 'lastNightDate', v_today)
            );
            if v_count >= (v_row.criteria->>'nights')::int then
              if public._unlock_achievement(p_user_id, v_row.id) then
                v_newly := array_append(v_newly, v_row.id);
              end if;
            end if;
          end if;
        end if;

      when 'avg_answer_seconds_under' then
        if p_event = 'level_attempt' and v_is_complete and v_correct_seconds_count > 0 then
          v_avg := v_correct_seconds_sum::numeric / v_correct_seconds_count;
          v_best_avg := v_row.ua_progress->>'bestAvgSeconds';
          if v_best_avg is null or v_avg < v_best_avg then
            perform public._bump_achievement_progress(
              p_user_id, v_row.id, jsonb_build_object('bestAvgSeconds', v_avg)
            );
          end if;
          if v_avg <= (v_row.criteria->>'seconds')::numeric then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'subcategory_level20_count' then
        if p_event = 'level_attempt' and v_is_complete and v_level = 20 then
          select count(distinct subcategory_id) into v_count
          from public.level_progress
          where user_id = p_user_id and level = 20 and completed_at is not null;

          if v_count >= (v_row.criteria->>'count')::int then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'duel_wins' then
        if p_event = 'duel_result' then
          perform public._bump_achievement_progress(
            p_user_id, v_row.id, jsonb_build_object('wins', v_total_bot_wins)
          );
          if v_total_bot_wins >= (v_row.criteria->>'count')::int then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      when 'daily_streak' then
        if p_event = 'streak_touch' then
          select streak_days into v_count from public.profiles where id = p_user_id;
          if v_count >= (v_row.criteria->>'days')::int then
            if public._unlock_achievement(p_user_id, v_row.id) then
              v_newly := array_append(v_newly, v_row.id);
            end if;
          end if;
        end if;

      else
        null; -- forward-compatible: an unrecognized future type is a no-op
    end case;
  end loop;

  return v_newly;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Call site: _touch_daily_streak now returns newly-earned badge ids
-- ---------------------------------------------------------------------------
drop function if exists public._touch_daily_streak(uuid);

create function public._touch_daily_streak(p_user_id uuid)
returns text[]
language plpgsql security definer set search_path = public as $$
declare
  v_last date;
  v_today date := (now() at time zone 'utc')::date;
begin
  select last_played_on into v_last from public.profiles where id = p_user_id for update;

  if v_last = v_today then
    return '{}'::text[]; -- already played today, streak unchanged
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

  return public._evaluate_achievements(p_user_id, 'streak_touch', '{}'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Call site: submit_level_attempt — new p_local_hour param, richer context
-- ---------------------------------------------------------------------------
drop function if exists public.submit_level_attempt(uuid, jsonb, boolean, text);

create function public.submit_level_attempt(
  p_attempt_id uuid,
  p_answers jsonb,
  p_used_power_up boolean,
  p_ending text,
  p_local_hour smallint default null
)
returns jsonb
language plpgsql security definer set search_path = public as $$
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

  v_seconds_total := (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question;
  v_question_count := jsonb_array_length(p_answers);
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
$$;

-- ---------------------------------------------------------------------------
-- 6. Call site: submit_bot_duel — badge_duelist moves into the evaluator
-- ---------------------------------------------------------------------------
create or replace function public.submit_bot_duel(
  p_opponent_elo integer, p_player_rounds_won smallint,
  p_opponent_rounds_won smallint, p_rounds jsonb
)
returns jsonb
language plpgsql security definer set search_path = public as $$
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
  v_total_bot_wins integer;
  v_new_badges text[];
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

  v_total_bot_wins := (
    select count(*) from public.duels
    where p1 = v_user_id and is_bot and winner = v_user_id
  );
  v_new_badges := public._evaluate_achievements(
    v_user_id, 'duel_result', jsonb_build_object('totalBotWins', v_total_bot_wins)
  );

  return jsonb_build_object(
    'duelId', v_duel_id,
    'isVictory', v_is_victory,
    'eloBefore', v_p1_elo,
    'eloAfter', v_elo_after,
    'coinsEarned', v_coins,
    'xpEarned', v_xp,
    'newlyEarnedBadgeIds', to_jsonb(v_new_badges)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Call site: play_daily_challenge — gains newlyEarnedBadgeIds
-- ---------------------------------------------------------------------------
create or replace function public.play_daily_challenge(
  p_answer_pattern boolean[], p_language_code text default 'en'::text
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := (now() at time zone 'utc')::date;
  v_challenge public.daily_challenges%rowtype;
  v_correct_count integer;
  v_total_count integer;
  v_coins integer;
  v_bucket integer;
  v_histogram jsonb;
  v_new_badges text[] := '{}';
begin
  select * into v_challenge from public.daily_challenges
    where challenge_date = v_today and language_code = p_language_code for update;
  if v_challenge.challenge_date is null then
    raise exception 'no_challenge_today';
  end if;

  if exists (select 1 from public.daily_attempts where user_id = v_user_id and challenge_date = v_today) then
    raise exception 'already_played_today';
  end if;

  v_total_count := array_length(p_answer_pattern, 1);
  select count(*) into v_correct_count from unnest(p_answer_pattern) as correct where correct;
  v_coins := case when v_correct_count > 0 then v_challenge.coin_reward else 0 end;
  v_bucket := least(4, v_correct_count / 2);

  insert into public.daily_attempts (user_id, challenge_date, language_code, correct_count, total_count, answer_pattern, coins_earned)
  values (v_user_id, v_today, p_language_code, v_correct_count, v_total_count, p_answer_pattern, v_coins);

  update public.daily_challenges
    set score_histogram = jsonb_set(
      score_histogram, array[v_bucket::text],
      to_jsonb(coalesce((score_histogram ->> v_bucket::text)::integer, 0) + 1)
    )
    where challenge_date = v_today and language_code = p_language_code
    returning score_histogram into v_histogram;

  perform public._grant_currency(v_user_id, 'coins', v_coins, 'daily_reward', null);

  if v_correct_count > 0 then
    v_new_badges := public._touch_daily_streak(v_user_id);
    insert into public.score_events (user_id, points, source)
    values (v_user_id, v_coins, 'daily');
  end if;

  return jsonb_build_object(
    'correctCount', v_correct_count,
    'totalCount', v_total_count,
    'coinsEarned', v_coins,
    'distribution', v_histogram,
    'streakNow', (select streak_days from public.profiles where id = v_user_id),
    'newlyEarnedBadgeIds', to_jsonb(v_new_badges)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 8. Drop the superseded partial checker
-- ---------------------------------------------------------------------------
drop function if exists public._check_level_achievements(uuid, boolean, integer, boolean, boolean);
