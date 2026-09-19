-- get_daily_challenge_questions: hands the caller today's real ten questions
-- to play. Until now `DailyApi.play` fabricated a random client-side answer
-- pattern and submitted it straight to `play_daily_challenge` — there was no
-- way to actually see or answer the day's questions. This closes that gap.
--
-- Mirrors `play_daily_challenge`'s own `no_challenge_today` /
-- `already_played_today` guards so the play screen can react to those
-- exact identifiers before ever calling the RPC that scores an attempt.
create or replace function public.get_daily_challenge_questions(
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
  v_questions jsonb;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select * into v_challenge from public.daily_challenges
    where challenge_date = v_today and language_code = p_language_code;
  if v_challenge.challenge_date is null then
    raise exception 'no_challenge_today';
  end if;

  if exists (
    select 1 from public.daily_attempts
    where user_id = v_user_id and challenge_date = v_today
  ) then
    raise exception 'already_played_today';
  end if;

  select jsonb_agg(jsonb_build_object(
      'id', q.id,
      'text', q.prompt,
      'options', q.options,
      'correctIndex', q.correct_index
    ) order by ord.i) into v_questions
  from unnest(v_challenge.question_ids) with ordinality as ord(qid, i)
  join public.questions q on q.id = ord.qid;

  return jsonb_build_object(
    'secondsPerQuestion', v_challenge.seconds_per_question,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
end;
$$;

grant execute on function public.get_daily_challenge_questions(text) to authenticated;
