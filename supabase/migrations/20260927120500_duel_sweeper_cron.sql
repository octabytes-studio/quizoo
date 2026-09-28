-- ============================================================================
-- 20260927120500_duel_sweeper_cron.sql
--
-- Plan 017, Phase 6: the pg_cron backstop for everything time-based. The
-- happy path never waits on it -- clients call explicit RPCs at their own
-- deadlines (auto-decline at 0 s, claim_duel_round_timeout, leave) -- the
-- sweeper only catches what is left over: unanswered join requests, stale
-- arena creators, expired/orphaned challenges, stale queue rows, no-show
-- duels, stuck rounds, 30 s disconnect forfeits, hard expiry, housekeeping.
--
-- Every step runs in its own exception block (and every per-row action in
-- a nested one), so one failure logs a warning instead of stalling the rest.
-- Every scan targets a partial index from 20260927120000 (open challenges,
-- pending requests, live duels) or a small table.
--
-- pg_cron 1.6.4 (verified in Phase 0) supports second-granularity
-- '10 seconds' schedules and never overlaps runs of the same job; the
-- advisory lock below is a second guard against manual concurrent calls.
-- ============================================================================

begin;

create or replace function public._duel_sweeper()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_grace interval := (v_cfg ->> 'join_grace_ms')::integer * interval '1 millisecond';
  v_creator_stale interval := (v_cfg ->> 'creator_stale_seconds')::integer * interval '1 second';
  v_mm_stale interval := (v_cfg ->> 'mm_stale_seconds')::integer * interval '1 second';
  v_ready_timeout interval := (v_cfg ->> 'ready_timeout_seconds')::integer * interval '1 second';
  v_disconnect interval := (v_cfg ->> 'disconnect_forfeit_seconds')::integer * interval '1 second';
  v_row record;
begin
  if not pg_try_advisory_xact_lock(hashtextextended('duel-sweeper', 0)) then
    return;
  end if;

  -- 1. Pending requests past expires_at + grace -> expired (retry cool-down),
  --    then present the next queued request.
  begin
    for v_row in
      select r.id, r.challenge_id
      from public.duel_join_requests r
      where r.status = 'pending' and r.expires_at < now() - v_grace
    loop
      begin
        perform 1 from public.duel_challenges where id = v_row.challenge_id for update;
        if public._duel_resolve_request(v_row.id, 'expired', 'no_response', true) then
          perform public._duel_promote_next_request(v_row.challenge_id);
        end if;
      exception when others then
        raise warning '_duel_sweeper step 1 (request %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 1: %', sqlerrm;
  end;

  -- 2. Stale creators: open, "present" challenges whose creator stopped
  --    heartbeating -> Away (trigger broadcasts) + clear their queue.
  begin
    for v_row in
      select c.id
      from public.duel_challenges c
      left join public.duel_player_state s on s.user_id = c.creator_id
      where c.status = 'open'
        and c.creator_present
        and (s.lobby_seen_at is null or s.lobby_seen_at < now() - v_creator_stale)
    loop
      begin
        update public.duel_challenges
          set creator_present = false
          where id = v_row.id and status = 'open' and creator_present;
        if found then
          perform public._duel_clear_requests_for_challenge(v_row.id, 'creator_away');
        end if;
      exception when others then
        raise warning '_duel_sweeper step 2 (challenge %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 2: %', sqlerrm;
  end;

  -- 3. Expired open challenges -> delete (requesters notified first).
  begin
    for v_row in
      select c.id from public.duel_challenges c
      where c.status = 'open' and c.expires_at < now()
    loop
      begin
        perform public._duel_delete_challenge(v_row.id, 'expired');
      exception when others then
        raise warning '_duel_sweeper step 3 (challenge %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 3: %', sqlerrm;
  end;

  -- 4. Orphaned "In progress" cards: the duel is gone / no longer live, or
  --    the card is implausibly old (5 min TTL + 15 min duel expiry < 30 min).
  begin
    for v_row in
      select c.id
      from public.duel_challenges c
      left join public.duels d on d.id = c.duel_id
      where c.status = 'matched'
        and (d.id is null
             or d.status not in ('pending', 'active')
             or c.created_at < now() - interval '30 minutes')
    loop
      begin
        perform public._duel_delete_challenge(v_row.id, 'challenge_gone');
      exception when others then
        raise warning '_duel_sweeper step 4 (challenge %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 4: %', sqlerrm;
  end;

  -- 5. Stale matchmaking rows (the searcher stopped heartbeating).
  begin
    delete from public.matchmaking_queue where last_seen_at < now() - v_mm_stale;
  exception when others then
    raise warning '_duel_sweeper step 5: %', sqlerrm;
  end;

  -- 6. No-shows: still pending (not both ready) after ready_timeout.
  begin
    for v_row in
      select d.id from public.duels d
      where d.status = 'pending' and d.created_at < now() - v_ready_timeout
    loop
      begin
        perform public._duel_abandon(v_row.id, 'no_show');
      exception when others then
        raise warning '_duel_sweeper step 6 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 6: %', sqlerrm;
  end;

  -- 7. Stuck rounds: current round past its deadline (+2 s) and unresolved
  --    (both clients vanished before claiming the timeout).
  begin
    for v_row in
      select d.id, d.current_round
      from public.duels d
      join public.duel_rounds r on r.duel_id = d.id and r.round = d.current_round
      where d.status = 'active'
        and r.resolved_at is null
        and r.deadline < now() - interval '2 seconds'
    loop
      begin
        perform public._duel_resolve_round(v_row.id, v_row.current_round);
      exception when others then
        raise warning '_duel_sweeper step 7 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 7: %', sqlerrm;
  end;

  -- 8. Disconnects: one side silent > disconnect_forfeit_seconds -> forfeit
  --    (remaining rounds to the present player); both silent -> abandon.
  begin
    for v_row in
      select d.id, d.p1, d.p2,
             (d.p1_seen_at is null or d.p1_seen_at < now() - v_disconnect) as p1_gone,
             (d.p2_seen_at is null or d.p2_seen_at < now() - v_disconnect) as p2_gone
      from public.duels d
      where d.status = 'active'
        and (d.p1_seen_at is null or d.p1_seen_at < now() - v_disconnect
             or d.p2_seen_at is null or d.p2_seen_at < now() - v_disconnect)
    loop
      begin
        if v_row.p1_gone and v_row.p2_gone then
          perform public._duel_abandon(v_row.id, 'both_disconnected');
        elsif v_row.p1_gone then
          perform public._duel_finish(v_row.id, 'forfeit', v_row.p1);
        else
          perform public._duel_finish(v_row.id, 'forfeit', v_row.p2);
        end if;
      exception when others then
        raise warning '_duel_sweeper step 8 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 8: %', sqlerrm;
  end;

  -- 9. Hard expiry: any live duel past duels.expires_at (15 min) -> abandon.
  begin
    for v_row in
      select d.id from public.duels d
      where d.status in ('pending', 'active') and d.expires_at < now()
    loop
      begin
        perform public._duel_abandon(v_row.id, 'expired');
      exception when others then
        raise warning '_duel_sweeper step 9 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 9: %', sqlerrm;
  end;

  -- 10. Housekeeping: terminal join requests older than 10 min whose retry
  --     cool-down has passed; rate buckets whose (<= 24 h) window ended more
  --     than 24 h ago.
  begin
    delete from public.duel_join_requests
      where status not in ('queued', 'pending')
        and resolved_at < now() - interval '10 minutes'
        and (retry_after is null or retry_after < now());
    delete from public.duel_rate_buckets
      where window_start < now() - interval '48 hours';
  exception when others then
    raise warning '_duel_sweeper step 10: %', sqlerrm;
  end;

  -- 11. This job's own run history (8,640 rows/day) older than a day
  --     (plan's Risks section). Only this job's rows are touched.
  begin
    delete from cron.job_run_details
      where jobid in (select jobid from cron.job where jobname = 'duel-sweeper')
        and end_time < now() - interval '1 day';
  exception when others then
    raise warning '_duel_sweeper step 11: %', sqlerrm;
  end;
end;
$$;

revoke execute on function public._duel_sweeper() from public, anon, authenticated;

-- Re-running cron.schedule with the same job name updates it in place.
select cron.schedule('duel-sweeper', '10 seconds', $$select public._duel_sweeper();$$);

commit;
