-- ============================================================================
-- 20260910090500_language_scope_daily_and_duels.sql
--
-- Closes two gaps plan 007 flagged but deliberately left out of its own
-- scope: the daily challenge and the (currently unreachable from the app,
-- but still live) real-opponent duel-resolution path both still picked/graded
-- questions with no regard for language, either mixing every language's
-- content into one global pool (_daily_rollover) or reading the deprecated
-- question_i18n table directly (resolve_duel_round).
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- daily_challenges: "same ten for every player worldwide" (the schema's own
-- old comment) no longer holds once content is language-scoped -- an
-- English-only pool can't serve a Urdu player's daily challenge without
-- either mixing languages into one set or leaving non-English players with
-- no challenge at all. One row per (date, active language) instead of one
-- global row per date.
-- ---------------------------------------------------------------------------
alter table daily_attempts drop constraint if exists daily_attempts_challenge_date_fkey;

alter table daily_challenges add column if not exists language_code text;
update daily_challenges set language_code = 'en' where language_code is null;
alter table daily_challenges alter column language_code set not null;

alter table daily_challenges drop constraint if exists daily_challenges_pkey;
alter table daily_challenges add constraint daily_challenges_pkey primary key (challenge_date, language_code);

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'daily_challenges_language_fk') then
    alter table daily_challenges add constraint daily_challenges_language_fk
      foreign key (language_code) references languages(code);
  end if;
end $$;

-- daily_attempts needs to know which language's row a player attempted, to
-- satisfy the new composite FK. "Already played today" stays keyed by
-- (user_id, challenge_date) alone (pkey unchanged) -- switching the app's
-- active language mid-day must not let someone play the same day twice.
alter table daily_attempts add column if not exists language_code text;
update daily_attempts set language_code = 'en' where language_code is null;
alter table daily_attempts alter column language_code set not null;
alter table daily_attempts add constraint daily_attempts_challenge_fkey
  foreign key (challenge_date, language_code) references daily_challenges (challenge_date, language_code);

-- ---------------------------------------------------------------------------
-- _daily_rollover: one challenge per active language instead of one global
-- row drawn from every language's questions mixed together.
-- ---------------------------------------------------------------------------
create or replace function public._daily_rollover()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_next_date date := (now() at time zone 'utc')::date + 1;
  v_language record;
  v_question_ids uuid[];
begin
  -- 1. Build tomorrow's daily challenge: 10 live questions in each active
  --    language, same set for every player of that language worldwide.
  for v_language in select code from public.languages where is_active loop
    if not exists (
      select 1 from public.daily_challenges
      where challenge_date = v_next_date and language_code = v_language.code
    ) then
      select array_agg(id) into v_question_ids from (
        select id from public.questions
        where status = 'live' and language_code = v_language.code
        order by random() limit 10
      ) sub;
      if v_question_ids is not null and array_length(v_question_ids, 1) > 0 then
        insert into public.daily_challenges (challenge_date, language_code, question_ids)
        values (v_next_date, v_language.code, v_question_ids);
      end if;
    end if;
  end loop;

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

-- ---------------------------------------------------------------------------
-- play_daily_challenge: needs to know which language's challenge the caller
-- is playing, since challenge_date alone no longer identifies one row.
-- Signature changes (new param), so the old 1-arg overload is dropped rather
-- than left dangling.
-- ---------------------------------------------------------------------------
drop function if exists public.play_daily_challenge(boolean[]);

create or replace function public.play_daily_challenge(
  p_answer_pattern boolean[],
  p_language_code text default 'en'
)
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
  v_bucket := least(4, v_correct_count / 2); -- 0-2,3-4,5-6,7-8,9-10 -> buckets 0..4

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

grant execute on function public.play_daily_challenge(boolean[], text) to authenticated;

-- ---------------------------------------------------------------------------
-- resolve_duel_round: grades from questions.correct_index directly instead
-- of the deprecated question_i18n keyed by a hardcoded locale = 'en' --
-- every question row now carries its own language natively, so there is no
-- longer a separate locale to join against. (This path has no caller in the
-- current app -- MatchmakingCubit only ever calls fetchBotOpponent, never a
-- real-opponent match -- but it is live, callable SQL, not dead code, and
-- deserves the same fix as everything else that touched question_i18n.)
-- ---------------------------------------------------------------------------
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

  select correct_index into v_correct_index from public.questions
    where id = v_question_id;

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

commit;
