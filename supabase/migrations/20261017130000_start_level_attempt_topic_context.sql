-- ============================================================================
-- 20261017130000_start_level_attempt_topic_context.sql
--
-- Plan: .claude/plans/025-app-review-readiness-fixes.md (Phase 3.1)
--
-- `start_level_attempt` now returns `categoryId` and `subcategoryName` (the
-- localized display name for the attempt's locale, falling back to the
-- English slug) alongside its existing keys, so the play surface and the
-- countdown no longer need the stale 26-entry MockCatalog fixture to label a
-- topic. The body below is the live definition from
-- 20261006210547_play_question_media_and_figure_payloads.sql with exactly
-- those two keys added — level-lock, question selection, attempt row and
-- history behavior are untouched.
--
-- Rollback: re-apply the body from
-- 20261006210547_play_question_media_and_figure_payloads.sql. The client
-- parses the missing keys as empty strings during the transition (plan 025).
-- ============================================================================

begin;

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
    'categoryId', (
      select s.category_id from public.subcategories s
       where s.id = p_subcategory_id
    ),
    -- Localized display name, not the English slug: Arabic/Urdu/Hindi
    -- subcategory slugs are English (e.g. 'abbasid-caliphate') while
    -- taxonomy_i18n carries the name for the attempt's locale.
    'subcategoryName', coalesce(
      (
        select t.name from public.taxonomy_i18n t
         where t.entity_type = 'subcategory'
           and t.entity_id = p_subcategory_id
           and t.locale = p_locale
      ),
      (select s.slug from public.subcategories s
        where s.id = p_subcategory_id),
      ''
    ),
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
end;
$function$;

commit;
