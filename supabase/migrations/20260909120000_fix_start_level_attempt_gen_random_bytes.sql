-- ============================================================================
-- Fix: start_level_attempt() called gen_random_bytes() unqualified, but the
-- function runs with `set search_path = public` (security definer) while
-- pgcrypto is installed in the `extensions` schema (Supabase's default
-- location, not public). Result: "function gen_random_bytes(integer) does
-- not exist" on every start_level_attempt call. Schema-qualifying the call
-- fixes it without widening the security-definer function's search_path.
-- ============================================================================

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
