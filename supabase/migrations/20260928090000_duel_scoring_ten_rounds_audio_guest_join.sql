-- ============================================================================
-- 20260928090000_duel_scoring_ten_rounds_audio_guest_join.sql
--
-- Duel fixes requested after the first real plays of plan 017:
--   1. Scoring: every correct answer is one point for the player who gave it
--      (both players can score on the same question). The winner has more
--      correct answers; equal counts are a draw. Previously a round went only
--      to the FASTER correct answer, so a player could answer correctly and
--      still score nothing. duels.p1_rounds / p2_rounds (and every payload's
--      p1Rounds / p2Rounds / myScore / opponentScore) now hold these points.
--      A forfeit awards each unplayed round as a point to the player who
--      stayed.
--   2. Ten questions per duel (was 5). min_topic_questions rises to 10 so the
--      topic picker only offers topics that can fill a whole duel.
--   3. Read-aloud: get_duel_round / get_duel_state questions now carry the
--      question's pre-generated narration (audioUrl) and ttsExcluded, the same
--      clips play mode uses.
--   4. Guests can no longer join a challenge (request_duel_join raises
--      'guest_cannot_join'); Quick match stays open to them.
-- Round time stays 15 s.
-- ============================================================================

begin;

update public.app_settings
  set value = value || '{"rounds": 10, "min_topic_questions": 10}'::jsonb,
      updated_at = now()
  where key = 'duel_config';

create or replace function public._duel_question_json(p_question_id uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'prompt', q.prompt,
    'options', q.options,
    'kind', q.kind,
    'mediaUrl', q.media_url,
    -- Read-aloud (2026-09-28): the same pre-generated narration play mode
    -- uses. Never the answer.
    'audioUrl', q.audio_url,
    'ttsExcluded', coalesce(q.tts_excluded, false)
  )
  from public.questions q
  where q.id = p_question_id;
$$;

create or replace function public._duel_resolve_round(p_duel_id uuid, p_round smallint)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_d public.duels;
  v_r public.duel_rounds;
  v_correct smallint;
  v_p1_ok boolean;
  v_p2_ok boolean;
  v_outcome text;
  v_payload jsonb;
begin
  select * into v_d from public.duels where id = p_duel_id for update;
  if not found or v_d.status <> 'active' then
    return null;
  end if;

  select * into v_r from public.duel_rounds
    where duel_id = p_duel_id and round = p_round
    for update;
  if not found or v_r.resolved_at is not null or v_r.starts_at is null then
    return null;
  end if;

  if v_r.p1_locked_at is null then
    v_r.p1_locked_at := now();
    v_r.p1_choice := null;
    v_r.p1_ms := null;
  end if;
  if v_r.p2_locked_at is null then
    v_r.p2_locked_at := now();
    v_r.p2_choice := null;
    v_r.p2_ms := null;
  end if;

  select correct_index into v_correct from public.questions where id = v_r.question_id;

  v_p1_ok := v_r.p1_choice is not null and v_r.p1_choice = v_correct;
  v_p2_ok := v_r.p2_choice is not null and v_r.p2_choice = v_correct;

  -- Scoring (2026-09-28): every correct answer is one point for that
  -- player -- both can score on the same question, speed no longer decides
  -- it. `outcome` records who alone got it right ('draw' = both or neither).
  v_outcome := case
    when v_p1_ok and not v_p2_ok then 'p1'
    when v_p2_ok and not v_p1_ok then 'p2'
    else 'draw'
  end;

  update public.duel_rounds set
    p1_choice = v_r.p1_choice, p1_ms = v_r.p1_ms, p1_locked_at = v_r.p1_locked_at,
    p2_choice = v_r.p2_choice, p2_ms = v_r.p2_ms, p2_locked_at = v_r.p2_locked_at,
    outcome = v_outcome,
    resolved_at = now()
    where duel_id = p_duel_id and round = p_round;

  update public.duels set
    p1_rounds = p1_rounds + v_p1_ok::integer,
    p2_rounds = p2_rounds + v_p2_ok::integer
    where id = p_duel_id
    returning * into v_d;

  -- Anti-repeat bookkeeping, same upsert shape as start_level_attempt.
  insert into public.user_question_history (user_id, question_id, times_seen, first_seen_at, last_seen_at)
  select u.user_id, v_r.question_id, 1, now(), now()
  from unnest(array[v_d.p1, v_d.p2]) as u (user_id)
  on conflict (user_id, question_id)
  do update set times_seen = user_question_history.times_seen + 1,
                last_seen_at = now();

  v_payload := jsonb_build_object(
    'round', p_round,
    'outcome', v_outcome,
    'correctIndex', v_correct,
    'p1Choice', v_r.p1_choice,
    'p2Choice', v_r.p2_choice,
    'p1Ms', v_r.p1_ms,
    'p2Ms', v_r.p2_ms,
    'p1Rounds', v_d.p1_rounds,
    'p2Rounds', v_d.p2_rounds
  );
  perform public._duel_room_send(p_duel_id, 'round_result', v_payload);

  if p_round < public._duel_round_count(p_duel_id) then
    perform public._duel_start_round(
      p_duel_id, (p_round + 1)::smallint,
      public._duel_cfg_int('reveal_seconds') * interval '1 second'
    );
  else
    perform public._duel_finish(p_duel_id, 'completed', null);
  end if;

  return v_payload;
end;
$$;

create or replace function public._duel_finish(p_duel_id uuid, p_reason text, p_forfeited_by uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_d public.duels;
  v_present text;
  v_unresolved integer;
  v_winner uuid;
  v_s1 numeric;
  v_e1 numeric;
  v_k integer;
  v_rage integer;
  v_f1 integer;
  v_f2 integer;
  v_elo1 integer;
  v_elo2 integer;
  v_d1 integer := 0;
  v_d2 integer := 0;
  v_c1 integer;
  v_c2 integer;
  v_x1 integer;
  v_x2 integer;
  v_why1 text;
  v_why2 text;
  v_b1 text[];
  v_b2 text[];
begin
  select * into v_d from public.duels where id = p_duel_id for update;
  if not found or v_d.status not in ('active', 'pending') then
    return;
  end if;

  -- Forfeit: every unresolved round goes to the player who stayed.
  if p_reason = 'forfeit' then
    if p_forfeited_by = v_d.p1 then
      v_present := 'p2';
    elsif p_forfeited_by = v_d.p2 then
      v_present := 'p1';
    else
      raise exception 'not_a_participant';
    end if;

    -- Scoring (2026-09-28): a point per correct answer, so each round
    -- that never got played is one point for the player who stayed.
    select count(*)::integer into v_unresolved
      from public.duel_rounds
      where duel_id = p_duel_id and resolved_at is null;

    update public.duel_rounds
      set outcome = v_present, resolved_at = now()
      where duel_id = p_duel_id and resolved_at is null;

    update public.duels set
      p1_rounds = p1_rounds + case when v_present = 'p1' then v_unresolved else 0 end,
      p2_rounds = p2_rounds + case when v_present = 'p2' then v_unresolved else 0 end
      where id = p_duel_id
      returning * into v_d;
  end if;

  -- Winner by points (correct answers); tie = draw.
  v_winner := case
    when v_d.p1_rounds > v_d.p2_rounds then v_d.p1
    when v_d.p2_rounds > v_d.p1_rounds then v_d.p2
  end;
  v_s1 := case when v_winner = v_d.p1 then 1 when v_winner = v_d.p2 then 0 else 0.5 end;

  v_elo1 := coalesce(v_d.p1_elo_before, 1200);
  v_elo2 := coalesce(v_d.p2_elo_before, 1200);

  if v_d.is_ranked then
    v_k := (v_cfg ->> 'elo_k')::integer;
    v_e1 := 1.0 / (1 + power(10::numeric, (v_elo2 - v_elo1) / 400.0));
    v_d1 := round(v_k * (v_s1 - v_e1));
    v_d2 := round(v_k * ((1 - v_s1) - (1 - v_e1)));

    -- Rage-quit rule: >= N forfeits in 24 h (including this one) -> no gain.
    v_rage := (v_cfg ->> 'rage_quit_forfeits_per_day')::integer;
    v_f1 := (select count(*) from public.duels
             where forfeited_by = v_d.p1 and ended_at > now() - interval '24 hours')
            + case when p_forfeited_by = v_d.p1 then 1 else 0 end;
    v_f2 := (select count(*) from public.duels
             where forfeited_by = v_d.p2 and ended_at > now() - interval '24 hours')
            + case when p_forfeited_by = v_d.p2 then 1 else 0 end;
    if v_f1 >= v_rage and v_d1 > 0 then
      v_d1 := 0;
    end if;
    if v_f2 >= v_rage and v_d2 > 0 then
      v_d2 := 0;
    end if;

    -- Relative update: preserves any ELO change made elsewhere meanwhile.
    if v_d1 <> 0 then
      update public.profiles set elo = elo + v_d1 where id = v_d.p1;
    end if;
    if v_d2 <> 0 then
      update public.profiles set elo = elo + v_d2 where id = v_d.p2;
    end if;
  end if;

  -- Payouts (A6: a draw pays both the consolation).
  if v_winner is null then
    v_c1 := (v_cfg ->> 'reward_draw_coins')::integer;  v_x1 := (v_cfg ->> 'reward_draw_xp')::integer;
    v_c2 := v_c1;                                       v_x2 := v_x1;
    v_why1 := 'duel_draw';                              v_why2 := 'duel_draw';
  elsif v_winner = v_d.p1 then
    v_c1 := (v_cfg ->> 'reward_win_coins')::integer;   v_x1 := (v_cfg ->> 'reward_win_xp')::integer;
    v_c2 := (v_cfg ->> 'reward_loss_coins')::integer;  v_x2 := (v_cfg ->> 'reward_loss_xp')::integer;
    v_why1 := 'duel_win';                               v_why2 := 'duel_loss';
  else
    v_c1 := (v_cfg ->> 'reward_loss_coins')::integer;  v_x1 := (v_cfg ->> 'reward_loss_xp')::integer;
    v_c2 := (v_cfg ->> 'reward_win_coins')::integer;   v_x2 := (v_cfg ->> 'reward_win_xp')::integer;
    v_why1 := 'duel_loss';                              v_why2 := 'duel_win';
  end if;

  perform public._grant_currency(v_d.p1, 'coins', v_c1, v_why1, p_duel_id);
  update public.profiles set xp = xp + v_x1 where id = v_d.p1;
  perform public._grant_currency(v_d.p2, 'coins', v_c2, v_why2, p_duel_id);
  update public.profiles set xp = xp + v_x2 where id = v_d.p2;

  -- Persist BEFORE achievements, so this win is counted.
  update public.duels set
    status = 'complete',
    end_reason = p_reason,
    winner = v_winner,
    forfeited_by = case when p_reason = 'forfeit' then p_forfeited_by end,
    p1_elo_after = v_elo1 + v_d1,
    p2_elo_after = v_elo2 + v_d2,
    p1_coins = v_c1,
    p2_coins = v_c2,
    p1_xp = v_x1,
    p2_xp = v_x2,
    ended_at = now()
    where id = p_duel_id;

  v_b1 := public._duel_check_achievements(v_d.p1);
  v_b2 := public._duel_check_achievements(v_d.p2);
  update public.duels set p1_badge_ids = v_b1, p2_badge_ids = v_b2 where id = p_duel_id;

  -- Free both players.
  perform public._duel_lock_pair(v_d.p1, v_d.p2);
  update public.duel_player_state
    set current_duel_id = null, updated_at = now()
    where user_id in (v_d.p1, v_d.p2) and current_duel_id = p_duel_id;

  -- The "In progress" card goes away (trigger broadcasts challenge_remove).
  if v_d.challenge_id is not null
     and exists (select 1 from public.duel_challenges where id = v_d.challenge_id) then
    perform public._duel_delete_challenge(v_d.challenge_id, 'challenge_gone');
  end if;

  perform public._duel_room_send(p_duel_id, 'duel_end', public._duel_end_payload(p_duel_id));
end;
$$;

create or replace function public.request_duel_join(p_challenge_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_c public.duel_challenges;
  v_state public.duel_player_state;
  v_profile public.profiles;
  v_player jsonb;
  v_r public.duel_join_requests;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  -- Guests may watch the arena and use Quick match, but joining someone's
  -- challenge needs an account (2026-09-28).
  if exists (select 1 from public.profiles where id = v_me and is_guest) then
    raise exception 'guest_cannot_join';
  end if;

  select * into v_c from public.duel_challenges where id = p_challenge_id;
  if not found or v_c.status <> 'open' or v_c.expires_at <= now() then
    raise exception 'challenge_unavailable';
  end if;
  if v_c.creator_id = v_me then
    raise exception 'own_challenge';
  end if;
  if not v_c.creator_present then
    raise exception 'creator_away';
  end if;

  v_state := public._duel_state_lock(v_me);
  if v_state.current_duel_id is not null then
    raise exception 'already_in_duel';
  end if;

  -- Re-check under the challenge lock (serialises requests per challenge).
  select * into v_c from public.duel_challenges where id = p_challenge_id for update;
  if not found or v_c.status <> 'open' or v_c.expires_at <= now() then
    raise exception 'challenge_unavailable';
  end if;
  if not v_c.creator_present then
    raise exception 'creator_away';
  end if;

  if exists (
    select 1 from public.duel_join_requests
    where challenge_id = p_challenge_id and requester_id = v_me
      and status in ('queued', 'pending')
  ) then
    raise exception 'already_requested';
  end if;

  if exists (
    select 1 from public.duel_join_requests
    where challenge_id = p_challenge_id and requester_id = v_me
      and retry_after > now()
  ) then
    raise exception 'retry_later';
  end if;

  if (select count(*) from public.duel_join_requests
      where requester_id = v_me and status in ('queued', 'pending'))
     >= (v_cfg ->> 'join_max_outstanding')::integer then
    raise exception 'too_many_requests';
  end if;

  perform public._duel_rate_hit(
    v_me, 'join', (v_cfg ->> 'join_rate_max')::integer,
    (v_cfg ->> 'join_rate_window_seconds')::integer * interval '1 second', 'rate_limited'
  );

  if (select count(*) from public.duel_join_requests
      where challenge_id = p_challenge_id and status in ('queued', 'pending'))
     >= (v_cfg ->> 'join_queue_cap')::integer then
    raise exception 'challenge_busy';
  end if;

  select * into v_profile from public.profiles where id = v_me;
  v_player := public._duel_player_json(v_me, v_c.subcategory_id);

  insert into public.duel_join_requests (
    challenge_id, creator_id, requester_id, status,
    requester_name, requester_guest_tag, requester_is_guest, requester_avatar,
    requester_elo, requester_league, requester_topic_level
  ) values (
    p_challenge_id, v_c.creator_id, v_me, 'queued',
    v_player ->> 'name', v_player ->> 'guestTag', v_profile.is_guest, v_player ->> 'avatar',
    (v_player ->> 'elo')::integer, v_player ->> 'league', (v_player ->> 'topicLevel')::smallint
  )
  returning * into v_r;

  -- Before promoting: promotion skips requesters not seen on the arena.
  update public.duel_player_state
    set lobby_seen_at = now(), updated_at = now()
    where user_id = v_me;

  perform public._duel_promote_next_request(p_challenge_id);

  select * into v_r from public.duel_join_requests where id = v_r.id;
  return public._duel_request_status_payload(v_r, null)
         || jsonb_build_object('serverNow', now());
end;
$$;

commit;
