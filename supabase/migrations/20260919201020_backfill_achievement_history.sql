-- Plan 014: Real Achievements & Badges — Phase 2 (backfill)
--
-- One-time grant pass over existing history. Rather than 14 separate ad hoc
-- aggregate queries, this chronologically replays each user's real
-- level_attempts through the same _evaluate_achievements() engine Phase 1
-- added and verified — this reconstructs every stateful counter (on_fire's
-- best streak, centurion's cross-level counter, big_brain's flawless count,
-- perfect_week's day streak, category_king's sweep) exactly as it would have
-- accumulated had the engine been live all along, with zero duplicated
-- logic to drift out of sync with the live evaluator.
--
-- night_owl cannot be backfilled: its criterion needs the player's
-- device-local hour at the moment of a historical attempt, which was never
-- recorded before this plan added `p_local_hour`. Every player starts at
-- nights=0 for real, going forward.
--
-- unlocked_at is `now()` for every backfilled grant (not backdated) — the
-- plan's Assumption 5 explicitly allows trading "earned N weeks ago" framing
-- for implementation simplicity here.
--
-- Idempotent: re-running is a guaranteed no-op (verified on the live
-- project) since every grant path routes through _unlock_achievement's own
-- `where unlocked_at is null` guard.
do $$
declare
  v_user record;
  v_attempt record;
  v_answer jsonb;
  v_seconds_total integer;
  v_correct_index smallint;
  v_is_correct boolean;
  v_streak integer;
  v_longest_streak integer;
  v_correct_count integer;
  v_question_count integer;
  v_is_complete boolean;
  v_is_flawless boolean;
  v_correctness_pattern boolean[];
  v_correct_seconds_sum integer;
  v_correct_seconds_count integer;
  v_answered_count integer;
  v_total_bot_wins integer;
  v_discard text[];
begin
  for v_user in select id from public.profiles loop
    for v_attempt in
      select * from public.level_attempts
      where user_id = v_user.id and server_score is not null
      order by created_at asc
    loop
      v_seconds_total := (public.get_difficulty_for_level(v_attempt.level)).seconds_per_question;
      v_question_count := jsonb_array_length(v_attempt.answers);
      v_is_complete := v_attempt.ending = 'finished';
      v_streak := 0;
      v_longest_streak := 0;
      v_correct_count := 0;
      v_correctness_pattern := '{}';
      v_correct_seconds_sum := 0;
      v_correct_seconds_count := 0;
      v_answered_count := 0;

      for v_answer in select * from jsonb_array_elements(v_attempt.answers)
      loop
        v_is_correct := false;
        if v_answer ->> 'action' = 'answered' and v_answer ->> 'chosenIndex' is not null then
          select q.correct_index into v_correct_index
          from public.questions q where q.id = (v_answer ->> 'questionId')::uuid;
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
          v_correct_seconds_sum := v_correct_seconds_sum
            + (v_seconds_total - coalesce((v_answer ->> 'secondsLeft')::int, 0));
          v_correct_seconds_count := v_correct_seconds_count + 1;
        else
          v_streak := 0;
        end if;
      end loop;

      v_is_flawless := v_is_complete and v_question_count > 0 and v_correct_count = v_question_count;

      v_discard := public._evaluate_achievements(v_user.id, 'level_attempt', jsonb_build_object(
        'subcategoryId', v_attempt.subcategory_id,
        'level', v_attempt.level,
        'stars', v_attempt.stars,
        'isComplete', v_is_complete,
        'isFlawless', v_is_flawless,
        'isBoss', v_attempt.is_boss,
        'ending', v_attempt.ending,
        'longestStreak', v_longest_streak,
        'correctnessPattern', to_jsonb(v_correctness_pattern),
        'correctSecondsSum', v_correct_seconds_sum,
        'correctSecondsCount', v_correct_seconds_count,
        'answeredCount', v_answered_count,
        'localHour', null
      ));
    end loop;

    v_total_bot_wins := (
      select count(*) from public.duels
      where p1 = v_user.id and is_bot and winner = v_user.id
    );
    if v_total_bot_wins > 0 then
      v_discard := public._evaluate_achievements(
        v_user.id, 'duel_result', jsonb_build_object('totalBotWins', v_total_bot_wins)
      );
    end if;

    v_discard := public._evaluate_achievements(v_user.id, 'streak_touch', '{}'::jsonb);
  end loop;
end;
$$;
