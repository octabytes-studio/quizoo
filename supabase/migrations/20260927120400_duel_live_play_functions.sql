-- ============================================================================
-- 20260927120400_duel_live_play_functions.sql
--
-- Plan 017, Phase 5: server-refereed live duels + bot-duel fixes.
--
-- Protocol: _duel_create -> duels.status 'pending' + N duel_rounds rows
-- (question ids only) -> duel_start to both inboxes. Both clients
-- get_duel_state -> subscribe duel:<id> -> mark_duel_ready. Both ready ->
-- 'active' + round_start (never the question text). Each client fetches the
-- round's question with get_duel_round at the round's start (refused before
-- starts_at - 500 ms), answers with submit_duel_answer (server-bounded
-- timing), answer_locked tells the opponent "answered in Xs" without the
-- choice. Both locked (or deadline passed: claim_duel_round_timeout / the
-- sweeper) -> _duel_resolve_round -> round_result -> next round after the
-- reveal, or _duel_finish -> duel_end.
--
-- Timing rule (plan A3): effective_ms = clamp(greatest(client_ms,
-- server_elapsed_ms - latency_allowance_ms), min_answer_ms, round_ms).
--
-- Deviations from the plan's Phase 5 checklist (flagged in the report):
--   * _duel_create stores question_ids = '{}' on the duels row instead of
--     the picked ids. duels_select_participant (kept by Phase 1) lets a
--     participant SELECT their duels row, and questions_select_live exposes
--     prompt/options/correct_index for any live question id -- storing the
--     ids there would let a modified client read all five questions (and
--     their answers) at duel creation, defeating A2. The ids live only in
--     the server-only duel_rounds table. Round count = count(duel_rounds).
--   * _duel_check_achievements is a thin wrapper around the existing generic
--     achievement engine (_evaluate_achievements, plan 014) rather than a
--     re-implementation: it counts ALL duel wins (bot + live, which fixes
--     defect 2) and passes the count under the engine's existing context key
--     'totalBotWins' (plus 'totalDuelWins' for forward compatibility).
--   * Extra payload keys: duel_end adds p1Id / p2Id; rematch events carry
--     all of {status, requestedBy, by, duelId} (nulls where n/a);
--     get_duel_state.result adds `cause`, and its config adds introSeconds /
--     duelHeartbeatSeconds / rematchWindowSeconds; duel_heartbeat adds
--     `status`. submit_duel_answer can also raise 'too_early' (an answer
--     before the question could have been served).
--   * profiles.xp is incremented exactly as submit_bot_duel does it (xp only;
--     player_level is NOT recomputed here, same as the bot path today).
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- Drop the unused Design Bible §24 skeleton (never called by the app --
-- re-grepped lib/ and test/ for submit_duel_answer|resolve_duel: no hits).
-- Parameter names change, so create-or-replace can't be used.
-- ---------------------------------------------------------------------------
drop function if exists public.submit_duel_answer(uuid, smallint, smallint, integer);
drop function if exists public.resolve_duel_round(uuid, smallint);
drop function if exists public.resolve_duel(uuid);

-- ============================================================================
-- Small helpers
-- ============================================================================

create or replace function public._duel_side(p_duel public.duels, p_user uuid)
returns text
language plpgsql immutable security definer
set search_path = public
as $$
begin
  if p_user is not null and p_user = p_duel.p1 then
    return 'p1';
  elsif p_user is not null and p_user = p_duel.p2 then
    return 'p2';
  end if;
  raise exception 'not_a_participant';
end;
$$;

create or replace function public._duel_touch(p_duel_id uuid, p_side text)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if p_side = 'p1' then
    update public.duels set p1_seen_at = now()
      where id = p_duel_id and status in ('pending', 'active');
  elsif p_side = 'p2' then
    update public.duels set p2_seen_at = now()
      where id = p_duel_id and status in ('pending', 'active');
  end if;
end;
$$;

create or replace function public._duel_round_count(p_duel_id uuid)
returns integer
language sql stable security definer
set search_path = public
as $$
  select count(*)::integer from public.duel_rounds where duel_id = p_duel_id;
$$;

-- {prompt, options, kind, mediaUrl} -- never the correct index.
create or replace function public._duel_question_json(p_question_id uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'prompt', q.prompt,
    'options', q.options,
    'kind', q.kind,
    'mediaUrl', q.media_url
  )
  from public.questions q
  where q.id = p_question_id;
$$;

-- duel_end payload, built from the persisted row (so finish and abandon
-- send the identical shape).
create or replace function public._duel_end_payload(p_duel_id uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'reason', d.end_reason,
    'cause', d.end_cause,
    'winnerId', d.winner,
    'isRanked', d.is_ranked,
    'forfeitedBy', d.forfeited_by,
    'p1Id', d.p1,
    'p2Id', d.p2,
    'p1Rounds', d.p1_rounds,
    'p2Rounds', d.p2_rounds,
    'p1AvgMs', (select round(avg(r.p1_ms))::integer from public.duel_rounds r where r.duel_id = d.id),
    'p2AvgMs', (select round(avg(r.p2_ms))::integer from public.duel_rounds r where r.duel_id = d.id),
    -- Client contract: eloBefore/eloAfter are never null (unranked /
    -- suppressed / abandoned => eloAfter = eloBefore); coins/xp default 0;
    -- badgeIds defaults to [].
    'p1', jsonb_build_object(
      'eloBefore', coalesce(d.p1_elo_before, p1p.elo, 1200),
      'eloAfter', coalesce(d.p1_elo_after, d.p1_elo_before, p1p.elo, 1200),
      'coins', coalesce(d.p1_coins, 0),
      'xp', coalesce(d.p1_xp, 0),
      'badgeIds', to_jsonb(coalesce(d.p1_badge_ids, '{}'::text[]))
    ),
    'p2', jsonb_build_object(
      'eloBefore', coalesce(d.p2_elo_before, p2p.elo, 1200),
      'eloAfter', coalesce(d.p2_elo_after, d.p2_elo_before, p2p.elo, 1200),
      'coins', coalesce(d.p2_coins, 0),
      'xp', coalesce(d.p2_xp, 0),
      'badgeIds', to_jsonb(coalesce(d.p2_badge_ids, '{}'::text[]))
    )
  )
  from public.duels d
  left join public.profiles p1p on p1p.id = d.p1
  left join public.profiles p2p on p2p.id = d.p2
  where d.id = p_duel_id;
$$;

-- Duel-win badges for one player, via the generic achievement engine. Counts
-- every won duel (bot and live) -- the old inline check counted bot wins only.
create or replace function public._duel_check_achievements(p_user_id uuid)
returns text[]
language plpgsql security definer
set search_path = public
as $$
declare
  v_wins integer;
begin
  select count(*)::integer into v_wins
  from public.duels
  where winner = p_user_id and status = 'complete';

  return coalesce(
    public._evaluate_achievements(
      p_user_id, 'duel_result',
      -- 'totalBotWins' is the engine's (historically named) duel_wins key.
      jsonb_build_object('totalBotWins', v_wins, 'totalDuelWins', v_wins)
    ),
    '{}'::text[]
  );
end;
$$;

-- ============================================================================
-- Duel lifecycle
-- ============================================================================

-- The ONLY way into a live duel (accept, pair, rematch). Locks both players,
-- refuses if either is already in a live duel, picks the questions, creates
-- the duel + rounds, marks both players busy, pulls them out of every other
-- path (queue, outgoing requests, their own other open challenge) and tells
-- both inboxes.
create or replace function public._duel_create(
  p_p1 uuid,
  p_p2 uuid,
  p_subcategory_id uuid,
  p_language text,
  p_origin text,
  p_challenge_id uuid,
  p_rematch_of uuid
)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_rounds integer := least(10, greatest(1, (v_cfg ->> 'rounds')::integer));
  v_qids uuid[];
  v_ranked boolean;
  v_elo1 integer;
  v_elo2 integer;
  v_duel_id uuid;
  v_uid uuid;
  v_challenge uuid;
begin
  if p_p1 is null or p_p2 is null or p_p1 = p_p2 then
    raise exception 'invalid_pair';
  end if;

  -- 1. Both players, ascending user_id.
  perform public._duel_lock_pair(p_p1, p_p2);
  if public._duel_live_duel_id(p_p1) is not null
     or public._duel_live_duel_id(p_p2) is not null then
    raise exception 'already_in_duel';
  end if;

  -- 2. Questions: prefer ones neither player has seen, then random.
  select array_agg(s.id) into v_qids
  from (
    select q.id
    from public.questions q
    where q.subcategory_id = p_subcategory_id
      and q.status = 'live'
      and q.language_code = p_language
      and q.prompt is not null
      and q.options is not null
      and q.correct_index is not null
    order by (
      select count(*) from public.user_question_history h
      where h.question_id = q.id and h.user_id in (p_p1, p_p2)
    ), random()
    limit v_rounds
  ) s;

  if coalesce(array_length(v_qids, 1), 0) < v_rounds then
    raise exception 'topic_unavailable';
  end if;

  -- 3. Anti-farming: a pair's ELO only moves for its first N ranked duels
  --    per rolling 24 h.
  v_ranked := (
    select count(*)
    from public.duels d
    where d.p2 is not null
      and least(d.p1, d.p2) = least(p_p1, p_p2)
      and greatest(d.p1, d.p2) = greatest(p_p1, p_p2)
      and d.is_ranked
      and d.status = 'complete'
      and d.created_at > now() - interval '24 hours'
  ) < (v_cfg ->> 'ranked_pair_cap_per_day')::integer;

  select elo into v_elo1 from public.profiles where id = p_p1;
  select elo into v_elo2 from public.profiles where id = p_p2;

  -- 4. The duel. question_ids deliberately '{}' (see header).
  insert into public.duels (
    p1, p2, is_bot, question_ids, status, origin, challenge_id, rematch_of,
    subcategory_id, language_code, is_ranked, current_round,
    p1_seen_at, p2_seen_at, expires_at, p1_elo_before, p2_elo_before
  ) values (
    p_p1, p_p2, false, '{}'::uuid[], 'pending', p_origin, p_challenge_id, p_rematch_of,
    p_subcategory_id, p_language, v_ranked, 0,
    now(), now(), now() + interval '15 minutes', v_elo1, v_elo2
  )
  returning id into v_duel_id;

  -- 5. Rounds (question ids only; no timing until the round starts).
  insert into public.duel_rounds (duel_id, round, question_id)
  select v_duel_id, o.n::smallint, o.qid
  from unnest(v_qids) with ordinality as o (qid, n);

  -- 6. Both players busy.
  update public.duel_player_state
    set current_duel_id = v_duel_id, updated_at = now()
    where user_id in (p_p1, p_p2);

  -- 7. Out of every other path.
  foreach v_uid in array array[p_p1, p_p2] loop
    delete from public.matchmaking_queue where user_id = v_uid;
    perform public._duel_withdraw_user_requests(v_uid, 'in_duel');
    for v_challenge in
      select id from public.duel_challenges
      where creator_id = v_uid
        and status = 'open'
        and id is distinct from p_challenge_id
    loop
      perform public._duel_delete_challenge(v_challenge, 'challenge_gone');
    end loop;
  end loop;

  -- 8. Tell both inboxes.
  perform public._duel_inbox_send(
    p_p1, 'duel_start', jsonb_build_object('duelId', v_duel_id, 'origin', p_origin)
  );
  perform public._duel_inbox_send(
    p_p2, 'duel_start', jsonb_build_object('duelId', v_duel_id, 'origin', p_origin)
  );

  return v_duel_id;
end;
$$;

-- Schedules a round: starts_at = now() + delay, deadline = starts_at +
-- round_seconds + latency allowance. round_start never carries the question.
create or replace function public._duel_start_round(p_duel_id uuid, p_round smallint, p_delay interval)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_round_seconds integer := (v_cfg ->> 'round_seconds')::integer;
  v_starts timestamptz := now() + p_delay;
  v_deadline timestamptz;
begin
  v_deadline := v_starts
    + v_round_seconds * interval '1 second'
    + (v_cfg ->> 'latency_allowance_ms')::integer * interval '1 millisecond';

  update public.duel_rounds
    set starts_at = v_starts, deadline = v_deadline
    where duel_id = p_duel_id and round = p_round;

  update public.duels set current_round = p_round where id = p_duel_id;

  perform public._duel_room_send(p_duel_id, 'round_start', jsonb_build_object(
    'round', p_round,
    'startsAt', v_starts,
    'deadline', v_deadline,
    'roundSeconds', v_round_seconds,
    'totalRounds', public._duel_round_count(p_duel_id)
  ));
end;
$$;

-- Ends a live duel: forfeit resolution, ELO (K, ranked only, rage-quit
-- clamp), payouts, achievements, frees both players, deletes the challenge
-- card, duel_end. No-op unless the duel is pending/active (idempotent).
create or replace function public._duel_finish(p_duel_id uuid, p_reason text, p_forfeited_by uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_d public.duels;
  v_present text;
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

    update public.duel_rounds
      set outcome = v_present, resolved_at = now()
      where duel_id = p_duel_id and resolved_at is null;

    update public.duels set
      p1_rounds = (select count(*) from public.duel_rounds r
                   where r.duel_id = p_duel_id and r.outcome = 'p1')::smallint,
      p2_rounds = (select count(*) from public.duel_rounds r
                   where r.duel_id = p_duel_id and r.outcome = 'p2')::smallint
      where id = p_duel_id
      returning * into v_d;
  end if;

  -- Winner by rounds; tie = draw.
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

-- Ends a duel with no result (no ELO, no payout): no-show, left before the
-- start, both disconnected, hard expiry. Re-opens the originating challenge
-- when it is still unexpired.
create or replace function public._duel_abandon(p_duel_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_d public.duels;
  v_c public.duel_challenges;
begin
  select * into v_d from public.duels where id = p_duel_id for update;
  if not found or v_d.status not in ('pending', 'active') then
    return;
  end if;

  update public.duels set
    status = 'abandoned',
    end_reason = 'abandoned',
    end_cause = p_reason,
    ended_at = now(),
    p1_elo_after = p1_elo_before,
    p2_elo_after = p2_elo_before,
    p1_coins = 0,
    p2_coins = 0,
    p1_xp = 0,
    p2_xp = 0
    where id = p_duel_id;

  perform public._duel_lock_pair(v_d.p1, v_d.p2);
  update public.duel_player_state
    set current_duel_id = null, updated_at = now()
    where user_id in (v_d.p1, v_d.p2) and current_duel_id = p_duel_id;

  if v_d.challenge_id is not null then
    select * into v_c from public.duel_challenges where id = v_d.challenge_id for update;
    if found and v_c.status = 'matched' and v_c.duel_id is not distinct from p_duel_id then
      if v_c.expires_at > now() and not exists (
        select 1 from public.duel_challenges o
        where o.creator_id = v_c.creator_id and o.status = 'open' and o.id <> v_c.id
      ) then
        update public.duel_challenges
          set status = 'open', duel_id = null, opponent_name = null, opponent_guest_tag = null
          where id = v_c.id;
      else
        perform public._duel_delete_challenge(
          v_c.id, case when v_c.expires_at > now() then 'challenge_gone' else 'expired' end
        );
      end if;
    end if;
  end if;

  perform public._duel_room_send(p_duel_id, 'duel_end', public._duel_end_payload(p_duel_id));
end;
$$;

-- Resolves one round (idempotent: returns null if the duel isn't active or
-- the round is already resolved / not started). Missing answers become
-- timeouts. Then starts the next round after the reveal, or finishes.
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

  v_outcome := case
    when v_p1_ok and not v_p2_ok then 'p1'
    when v_p2_ok and not v_p1_ok then 'p2'
    when v_p1_ok and v_p2_ok then
      case
        when coalesce(v_r.p1_ms, 2147483647) < coalesce(v_r.p2_ms, 2147483647) then 'p1'
        when coalesce(v_r.p2_ms, 2147483647) < coalesce(v_r.p1_ms, 2147483647) then 'p2'
        else 'draw'
      end
    else 'draw'
  end;

  update public.duel_rounds set
    p1_choice = v_r.p1_choice, p1_ms = v_r.p1_ms, p1_locked_at = v_r.p1_locked_at,
    p2_choice = v_r.p2_choice, p2_ms = v_r.p2_ms, p2_locked_at = v_r.p2_locked_at,
    outcome = v_outcome,
    resolved_at = now()
    where duel_id = p_duel_id and round = p_round;

  update public.duels set
    p1_rounds = p1_rounds + (v_outcome = 'p1')::integer,
    p2_rounds = p2_rounds + (v_outcome = 'p2')::integer
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

-- ============================================================================
-- Public RPCs
-- ============================================================================

-- Perspective-mapped snapshot (resume-safe). Touches the caller's liveness.
create or replace function public.get_duel_state(p_duel_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_d public.duels;
  v_side text;
  v_opp uuid;
  v_my_elo integer;
  v_opp_elo integer;
  v_r public.duel_rounds;
  v_question jsonb;
  v_round jsonb;
  v_history jsonb;
  v_result jsonb;
  v_my_avg integer;
  v_opp_avg integer;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  if v_d.status in ('pending', 'active') then
    perform public._duel_touch(p_duel_id, v_side);
  end if;

  v_opp := case when v_side = 'p1' then v_d.p2 else v_d.p1 end;
  -- Never null (client contract): fall back to the live profile ELO.
  v_my_elo := coalesce(
    case when v_side = 'p1' then v_d.p1_elo_before else v_d.p2_elo_before end,
    (select elo from public.profiles where id = v_me),
    1200
  );
  v_opp_elo := case when v_side = 'p1' then v_d.p2_elo_before else v_d.p1_elo_before end;

  if v_d.status = 'active' and v_d.current_round > 0 then
    select * into v_r from public.duel_rounds
      where duel_id = p_duel_id and round = v_d.current_round;
    if found then
      if v_r.starts_at is not null and now() >= v_r.starts_at - interval '500 milliseconds' then
        v_question := public._duel_question_json(v_r.question_id);
      end if;
      v_round := jsonb_build_object(
        'number', v_r.round,
        'startsAt', v_r.starts_at,
        'deadline', v_r.deadline,
        'myLocked', (case when v_side = 'p1' then v_r.p1_locked_at else v_r.p2_locked_at end) is not null,
        'myChoice', case when v_side = 'p1' then v_r.p1_choice else v_r.p2_choice end,
        'myMs', case when v_side = 'p1' then v_r.p1_ms else v_r.p2_ms end,
        'opponentLocked', (case when v_side = 'p1' then v_r.p2_locked_at else v_r.p1_locked_at end) is not null,
        'opponentMs', case when v_side = 'p1' then v_r.p2_ms else v_r.p1_ms end,
        'question', v_question
      );
    end if;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'round', r.round,
           'outcome', case when r.outcome = 'draw' then 'draw'
                           when r.outcome = v_side then 'me'
                           else 'opponent' end,
           -- Rounds that never started (forfeit) keep their answer hidden.
           'correctIndex', case when r.starts_at is not null then q.correct_index end,
           'myChoice', case when v_side = 'p1' then r.p1_choice else r.p2_choice end,
           'opponentChoice', case when v_side = 'p1' then r.p2_choice else r.p1_choice end,
           'myMs', case when v_side = 'p1' then r.p1_ms else r.p2_ms end,
           'opponentMs', case when v_side = 'p1' then r.p2_ms else r.p1_ms end
         ) order by r.round), '[]'::jsonb)
    into v_history
  from public.duel_rounds r
  join public.questions q on q.id = r.question_id
  where r.duel_id = p_duel_id and r.resolved_at is not null;

  if v_d.end_reason is not null then
    select round(avg(case when v_side = 'p1' then r.p1_ms else r.p2_ms end))::integer,
           round(avg(case when v_side = 'p1' then r.p2_ms else r.p1_ms end))::integer
      into v_my_avg, v_opp_avg
    from public.duel_rounds r
    where r.duel_id = p_duel_id;

    v_result := jsonb_build_object(
      'reason', v_d.end_reason,
      'cause', v_d.end_cause,
      'won', coalesce(v_d.winner = v_me, false),
      'draw', v_d.end_reason <> 'abandoned' and v_d.winner is null,
      'eloBefore', v_my_elo,
      'eloAfter', coalesce(case when v_side = 'p1' then v_d.p1_elo_after else v_d.p2_elo_after end, v_my_elo),
      'coins', coalesce(case when v_side = 'p1' then v_d.p1_coins else v_d.p2_coins end, 0),
      'xp', coalesce(case when v_side = 'p1' then v_d.p1_xp else v_d.p2_xp end, 0),
      'badgeIds', to_jsonb(coalesce(case when v_side = 'p1' then v_d.p1_badge_ids else v_d.p2_badge_ids end, '{}'::text[])),
      'opponentForfeited', coalesce(v_d.forfeited_by = v_opp, false),
      'youForfeited', coalesce(v_d.forfeited_by = v_me, false),
      'myAvgMs', v_my_avg,
      'opponentAvgMs', v_opp_avg
    );
  end if;

  return jsonb_build_object(
    'serverNow', now(),
    'duelId', v_d.id,
    'status', v_d.status,
    'mySide', v_side,
    'isRanked', v_d.is_ranked,
    'origin', v_d.origin,
    'topic', public._duel_topic_json(v_d.subcategory_id),
    'me', public._duel_player_json(v_me, v_d.subcategory_id)
          || case when v_my_elo is null then '{}'::jsonb else jsonb_build_object('elo', v_my_elo) end,
    'opponent', case when v_opp is null then null else
                  public._duel_player_json(v_opp, v_d.subcategory_id)
                  || case when v_opp_elo is null then '{}'::jsonb else jsonb_build_object('elo', v_opp_elo) end
                end,
    'config', jsonb_build_object(
      'rounds', public._duel_round_count(p_duel_id),
      'roundSeconds', v_cfg -> 'round_seconds',
      'revealSeconds', v_cfg -> 'reveal_seconds',
      -- extras (not in the plan's list), for screens reached without a lobby snapshot:
      'introSeconds', v_cfg -> 'intro_seconds',
      'duelHeartbeatSeconds', v_cfg -> 'duel_heartbeat_seconds',
      'rematchWindowSeconds', v_cfg -> 'rematch_window_seconds'
    ),
    'currentRound', v_d.current_round,
    'round', v_round,
    'history', v_history,
    'myScore', case when v_side = 'p1' then v_d.p1_rounds else v_d.p2_rounds end,
    'opponentScore', case when v_side = 'p1' then v_d.p2_rounds else v_d.p1_rounds end,
    'result', v_result
  );
end;
$$;

-- Both ready -> active + round 1 after the intro.
create or replace function public.mark_duel_ready(p_duel_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
  v_side text;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id for update;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  if v_d.status in ('pending', 'active') then
    update public.duels set
      p1_ready_at = case when v_side = 'p1' then coalesce(p1_ready_at, now()) else p1_ready_at end,
      p2_ready_at = case when v_side = 'p2' then coalesce(p2_ready_at, now()) else p2_ready_at end,
      p1_seen_at = case when v_side = 'p1' then now() else p1_seen_at end,
      p2_seen_at = case when v_side = 'p2' then now() else p2_seen_at end
      where id = p_duel_id
      returning * into v_d;

    if v_d.status = 'pending' and v_d.p1_ready_at is not null and v_d.p2_ready_at is not null then
      update public.duels set status = 'active' where id = p_duel_id;
      perform public._duel_start_round(
        p_duel_id, 1::smallint, public._duel_cfg_int('intro_seconds') * interval '1 second'
      );
      v_d.status := 'active';
    end if;
  end if;

  return jsonb_build_object('serverNow', now(), 'status', v_d.status);
end;
$$;

-- The current round's question, never before starts_at - 500 ms.
create or replace function public.get_duel_round(p_duel_id uuid, p_round smallint)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
  v_r public.duel_rounds;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id;
  if not found then
    raise exception 'duel_not_found';
  end if;
  perform public._duel_side(v_d, v_me);

  if v_d.status <> 'active' or p_round is distinct from v_d.current_round then
    raise exception 'round_closed';
  end if;

  select * into v_r from public.duel_rounds where duel_id = p_duel_id and round = p_round;
  if not found or v_r.resolved_at is not null then
    raise exception 'round_closed';
  end if;
  if v_r.starts_at is null or now() < v_r.starts_at - interval '500 milliseconds' then
    raise exception 'too_early';
  end if;

  return jsonb_build_object(
    'round', v_r.round,
    'startsAt', v_r.starts_at,
    'deadline', v_r.deadline,
    'question', public._duel_question_json(v_r.question_id),
    'serverNow', now()
  );
end;
$$;

-- Locks the caller's answer for the current round. A null choice (or a
-- client_ms beyond the round) is a timeout. Never reveals correctness.
create or replace function public.submit_duel_answer(
  p_duel_id uuid, p_round smallint, p_choice smallint, p_client_ms integer
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_d public.duels;
  v_side text;
  v_r public.duel_rounds;
  v_round_ms integer;
  v_elapsed integer;
  v_options integer;
  v_choice smallint;
  v_ms integer;
  v_other_locked boolean;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id for update;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  if v_d.status <> 'active' or p_round is distinct from v_d.current_round then
    raise exception 'round_closed';
  end if;

  select * into v_r from public.duel_rounds
    where duel_id = p_duel_id and round = p_round
    for update;
  if not found then
    raise exception 'round_closed';
  end if;
  if (case when v_side = 'p1' then v_r.p1_locked_at else v_r.p2_locked_at end) is not null then
    raise exception 'already_answered';
  end if;
  if v_r.resolved_at is not null or v_r.starts_at is null or now() > v_r.deadline then
    raise exception 'round_closed';
  end if;
  if now() < v_r.starts_at - interval '500 milliseconds' then
    raise exception 'too_early';
  end if;

  if p_choice is not null then
    select jsonb_array_length(q.options) into v_options
      from public.questions q where q.id = v_r.question_id;
    if p_choice < 0 or p_choice >= coalesce(v_options, 0) then
      raise exception 'invalid_choice';
    end if;
  end if;

  v_round_ms := (v_cfg ->> 'round_seconds')::integer * 1000;
  v_elapsed := floor(extract(epoch from (now() - v_r.starts_at)) * 1000)::integer;

  if p_choice is null or p_client_ms is null or p_client_ms > v_round_ms then
    v_choice := null;
    v_ms := null;
  else
    v_choice := p_choice;
    v_ms := least(
      v_round_ms,
      greatest(
        (v_cfg ->> 'min_answer_ms')::integer,
        p_client_ms,
        v_elapsed - (v_cfg ->> 'latency_allowance_ms')::integer
      )
    );
  end if;

  if v_side = 'p1' then
    update public.duel_rounds
      set p1_choice = v_choice, p1_ms = v_ms, p1_locked_at = now()
      where duel_id = p_duel_id and round = p_round;
    v_other_locked := v_r.p2_locked_at is not null;
  else
    update public.duel_rounds
      set p2_choice = v_choice, p2_ms = v_ms, p2_locked_at = now()
      where duel_id = p_duel_id and round = p_round;
    v_other_locked := v_r.p1_locked_at is not null;
  end if;

  perform public._duel_touch(p_duel_id, v_side);
  perform public._duel_room_send(p_duel_id, 'answer_locked', jsonb_build_object(
    'userId', v_me,
    'round', p_round,
    'ms', v_ms
  ));

  if v_other_locked then
    perform public._duel_resolve_round(p_duel_id, p_round);
  end if;

  return jsonb_build_object('accepted', true, 'serverNow', now());
end;
$$;

-- Client-side deadline claim (idempotent). The sweeper is the backstop.
create or replace function public.claim_duel_round_timeout(p_duel_id uuid, p_round smallint)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
  v_side text;
  v_r public.duel_rounds;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id for update;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  if v_d.status = 'pending' then
    raise exception 'too_early';
  end if;
  if v_d.status <> 'active' or p_round < v_d.current_round then
    return jsonb_build_object('resolved', true, 'serverNow', now());
  end if;
  if p_round > v_d.current_round then
    raise exception 'too_early';
  end if;

  select * into v_r from public.duel_rounds where duel_id = p_duel_id and round = p_round;
  if not found or v_r.resolved_at is not null then
    return jsonb_build_object('resolved', true, 'serverNow', now());
  end if;
  if v_r.deadline is null or now() <= v_r.deadline then
    raise exception 'too_early';
  end if;

  perform public._duel_touch(p_duel_id, v_side);
  perform public._duel_resolve_round(p_duel_id, p_round);

  return jsonb_build_object('resolved', true, 'serverNow', now());
end;
$$;

-- Liveness (every duel_heartbeat_seconds). Throttled to one write per second.
create or replace function public.duel_heartbeat(p_duel_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
  v_side text;
  v_my_seen timestamptz;
  v_opp_seen timestamptz;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  v_my_seen := case when v_side = 'p1' then v_d.p1_seen_at else v_d.p2_seen_at end;
  v_opp_seen := case when v_side = 'p1' then v_d.p2_seen_at else v_d.p1_seen_at end;

  if v_d.status in ('pending', 'active')
     and (v_my_seen is null or v_my_seen <= now() - interval '1 second') then
    perform public._duel_touch(p_duel_id, v_side);
  end if;

  return jsonb_build_object(
    'serverNow', now(),
    'opponentSeenAgoMs', case when v_opp_seen is null then null
      else greatest(0, floor(extract(epoch from (now() - v_opp_seen)) * 1000))::integer end,
    -- extra (not in the plan): lets a client that missed duel_end notice.
    'status', v_d.status
  );
end;
$$;

-- pending -> abandoned ('left_before_start'); active -> forfeit.
create or replace function public.leave_duel(p_duel_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id for update;
  if not found then
    raise exception 'duel_not_found';
  end if;
  perform public._duel_side(v_d, v_me);

  if v_d.status = 'pending' then
    perform public._duel_abandon(p_duel_id, 'left_before_start');
  elsif v_d.status = 'active' then
    perform public._duel_finish(p_duel_id, 'forfeit', v_me);
  end if;
end;
$$;

-- Two-sided rematch handshake within rematch_window_seconds of the end.
-- Returns {status:'requested'|'started', duelId, serverNow}.
create or replace function public.request_duel_rematch(p_duel_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
  v_side text;
  v_existing uuid;
  v_other_at timestamptz;
  v_new uuid;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id for update;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  -- Idempotent: a rematch already started from this duel.
  select id into v_existing from public.duels
    where rematch_of = p_duel_id and p1 = v_d.p1 and status in ('pending', 'active')
    order by created_at desc
    limit 1;
  if v_existing is not null then
    return jsonb_build_object('status', 'started', 'duelId', v_existing, 'serverNow', now());
  end if;

  if v_d.is_bot
     or v_d.p2 is null
     or v_d.status <> 'complete'
     or v_d.ended_at is null
     or v_d.ended_at <= now() - public._duel_cfg_int('rematch_window_seconds') * interval '1 second' then
    raise exception 'rematch_unavailable';
  end if;

  if v_side = 'p1' then
    update public.duels set p1_rematch_at = coalesce(p1_rematch_at, now())
      where id = p_duel_id
      returning p2_rematch_at into v_other_at;
  else
    update public.duels set p2_rematch_at = coalesce(p2_rematch_at, now())
      where id = p_duel_id
      returning p1_rematch_at into v_other_at;
  end if;

  if v_other_at is not null then
    begin
      v_new := public._duel_create(
        v_d.p1, v_d.p2, v_d.subcategory_id, v_d.language_code, 'rematch', null, p_duel_id
      );
    exception when raise_exception then
      -- already_in_duel / topic_unavailable / invalid_pair
      raise exception 'rematch_unavailable';
    end;

    update public.duels set p1_rematch_at = null, p2_rematch_at = null where id = p_duel_id;

    perform public._duel_room_send(p_duel_id, 'rematch', jsonb_build_object(
      'status', 'started', 'requestedBy', null, 'by', v_me, 'duelId', v_new
    ));
    return jsonb_build_object('status', 'started', 'duelId', v_new, 'serverNow', now());
  end if;

  perform public._duel_room_send(p_duel_id, 'rematch', jsonb_build_object(
    'status', 'requested', 'requestedBy', v_me, 'by', v_me, 'duelId', null
  ));
  return jsonb_build_object('status', 'requested', 'duelId', null, 'serverNow', now());
end;
$$;

-- Withdraws the caller's own rematch offer (so a later tap by the opponent
-- can't pull someone who left into a new duel) and tells the room.
create or replace function public.decline_duel_rematch(p_duel_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_d public.duels;
  v_side text;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_d from public.duels where id = p_duel_id for update;
  if not found then
    raise exception 'duel_not_found';
  end if;
  v_side := public._duel_side(v_d, v_me);

  update public.duels set
    p1_rematch_at = case when v_side = 'p1' then null else p1_rematch_at end,
    p2_rematch_at = case when v_side = 'p2' then null else p2_rematch_at end
    where id = p_duel_id;

  perform public._duel_room_send(p_duel_id, 'rematch', jsonb_build_object(
    'status', 'declined', 'requestedBy', null, 'by', v_me, 'duelId', null
  ));
end;
$$;

-- ============================================================================
-- submit_bot_duel: + p_subcategory_id (stored on the row), and the duel_wins
-- badge now goes through _duel_check_achievements (counts ALL duel wins, not
-- only bot wins -- defect 2). Everything else unchanged from
-- 20260919194353_real_achievement_engine.sql. The new parameter has a
-- default, so existing app builds (4 named args) keep working.
-- ============================================================================
drop function if exists public.submit_bot_duel(integer, smallint, smallint, jsonb);

create function public.submit_bot_duel(
  p_opponent_elo integer, p_player_rounds_won smallint,
  p_opponent_rounds_won smallint, p_rounds jsonb,
  p_subcategory_id uuid default null
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
    p1_elo_before, p1_elo_after, subcategory_id
  ) values (
    v_user_id, true, '{}', p_player_rounds_won, p_opponent_rounds_won,
    case when v_is_victory then v_user_id else null end, 'complete',
    v_p1_elo, v_elo_after, p_subcategory_id
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

  v_new_badges := public._duel_check_achievements(v_user_id);

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

-- ============================================================================
-- Privileges
-- ============================================================================

revoke execute on function public._duel_side(public.duels, uuid) from public, anon, authenticated;
revoke execute on function public._duel_touch(uuid, text) from public, anon, authenticated;
revoke execute on function public._duel_round_count(uuid) from public, anon, authenticated;
revoke execute on function public._duel_question_json(uuid) from public, anon, authenticated;
revoke execute on function public._duel_end_payload(uuid) from public, anon, authenticated;
revoke execute on function public._duel_check_achievements(uuid) from public, anon, authenticated;
revoke execute on function public._duel_create(uuid, uuid, uuid, text, text, uuid, uuid) from public, anon, authenticated;
revoke execute on function public._duel_start_round(uuid, smallint, interval) from public, anon, authenticated;
revoke execute on function public._duel_finish(uuid, text, uuid) from public, anon, authenticated;
revoke execute on function public._duel_abandon(uuid, text) from public, anon, authenticated;
revoke execute on function public._duel_resolve_round(uuid, smallint) from public, anon, authenticated;

revoke execute on function public.get_duel_state(uuid) from public, anon;
revoke execute on function public.mark_duel_ready(uuid) from public, anon;
revoke execute on function public.get_duel_round(uuid, smallint) from public, anon;
revoke execute on function public.submit_duel_answer(uuid, smallint, smallint, integer) from public, anon;
revoke execute on function public.claim_duel_round_timeout(uuid, smallint) from public, anon;
revoke execute on function public.duel_heartbeat(uuid) from public, anon;
revoke execute on function public.leave_duel(uuid) from public, anon;
revoke execute on function public.request_duel_rematch(uuid) from public, anon;
revoke execute on function public.decline_duel_rematch(uuid) from public, anon;
revoke execute on function public.submit_bot_duel(integer, smallint, smallint, jsonb, uuid) from public, anon;

grant execute on function public.get_duel_state(uuid) to authenticated;
grant execute on function public.mark_duel_ready(uuid) to authenticated;
grant execute on function public.get_duel_round(uuid, smallint) to authenticated;
grant execute on function public.submit_duel_answer(uuid, smallint, smallint, integer) to authenticated;
grant execute on function public.claim_duel_round_timeout(uuid, smallint) to authenticated;
grant execute on function public.duel_heartbeat(uuid) to authenticated;
grant execute on function public.leave_duel(uuid) to authenticated;
grant execute on function public.request_duel_rematch(uuid) to authenticated;
grant execute on function public.decline_duel_rematch(uuid) to authenticated;
grant execute on function public.submit_bot_duel(integer, smallint, smallint, jsonb, uuid) to authenticated;

commit;
