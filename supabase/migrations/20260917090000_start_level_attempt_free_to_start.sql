-- ============================================================================
-- 20260917090000_start_level_attempt_free_to_start.sql
--
-- Design bible §20 (Economy): "Max 5, refills 1 per 30 minutes. Starting a
-- level is free; each wrong answer costs one. Running out is the only way
-- to fail." start_level_attempt (20260910090300) instead spent and gated on
-- a heart before a single question was ever dealt -- a level start has
-- never cost a mistake, so nothing about opening one should require having
-- one in reserve. That deviation is also what made starting a level a dead
-- end for real players: the account's hearts are otherwise untouched by
-- anything today (the mid-level "wrong answer costs a heart" wall the
-- bible describes is QuizPlayCubit's own per-run heartsRemaining counter,
-- never wired to profiles.hearts), so once this spend emptied the account
-- there was no in-app action that ever put a heart back except waiting out
-- the timer -- see the "out_of_hearts" bug this migration follows up on.
--
-- Signature and every other line of start_level_attempt are unchanged; this
-- migration only drops the three hearts-related statements (settle, gate,
-- spend).
-- ============================================================================

begin;

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

grant execute on function public.start_level_attempt(uuid, smallint, text) to authenticated;

commit;
