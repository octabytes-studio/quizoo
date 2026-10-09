-- Deliver real question media to every play surface: the hosted image URL
-- (questions.media_url) and the pattern artwork (questions.figure_svg).
--   * start_level_attempt / get_daily_challenge_questions feed level + daily
--     play (QuizPlayApi) — 'imageAsset' becomes 'mediaUrl', plus 'figureSvg'.
--   * _duel_question_json feeds both duel variants (DuelQuestion).

CREATE OR REPLACE FUNCTION public.start_level_attempt(p_subcategory_id uuid, p_level smallint, p_locale text DEFAULT 'en'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

  if p_level > 1
     and not public._is_pro(v_user_id)
     and not exists (
       select 1 from public.level_progress lp
       where lp.user_id = v_user_id
         and lp.subcategory_id = p_subcategory_id
         and lp.level in (p_level, p_level - 1)
         and lp.completed_at is not null
     ) then
    raise exception 'level_locked';
  end if;

  select coalesce(
    v_tier.override_questions_per_level,
    (select (value #>> '{}')::int from public.app_settings where key = 'questions_per_level'),
    20
  ) into v_n;

  insert into public.level_attempts (user_id, subcategory_id, level, seed, locale, is_boss, seconds_per_question)
  values (v_user_id, p_subcategory_id, p_level, v_seed, p_locale, v_is_boss, v_tier.seconds_per_question)
  returning id into v_attempt_id;

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
    v_padded := true;
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
      'mediaUrl', q.media_url,
      'figureSvg', q.figure_svg,
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

CREATE OR REPLACE FUNCTION public.get_daily_challenge_questions(p_language_code text DEFAULT 'en'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      'mediaUrl', q.media_url,
      'figureSvg', q.figure_svg,
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
$function$;

CREATE OR REPLACE FUNCTION public._duel_question_json(p_question_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'prompt', q.prompt,
    'options', q.options,
    'kind', q.kind,
    'mediaUrl', q.media_url,
    'figureSvg', q.figure_svg,
    -- Read-aloud (2026-09-28): the same pre-generated narration play mode
    -- uses. Never the answer.
    'audioUrl', q.audio_url,
    'ttsExcluded', coalesce(q.tts_excluded, false)
  )
  from public.questions q
  where q.id = p_question_id;
$function$;
