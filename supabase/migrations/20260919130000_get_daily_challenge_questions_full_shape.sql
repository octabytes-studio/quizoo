-- Widens get_daily_challenge_questions to the exact same question shape
-- start_level_attempt returns (id/subcategoryId/difficulty/text/options/
-- correctIndex/explanation/hasImage/imageAsset/ttsExcluded/audioUrl).
--
-- The daily challenge now plays through the same QuizPlayCubit/QuizPlayScreen
-- arena as a normal level (design decision: one play surface, not two), so
-- its questions need to map onto the exact same `Question` domain model —
-- media, TTS narration and all — not the trimmed id/text/options/correctIndex
-- shape the original migration returned.
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
