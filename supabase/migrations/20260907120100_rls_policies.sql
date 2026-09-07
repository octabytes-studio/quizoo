-- ============================================================================
-- Quizoo — Row Level Security
--
-- Rule of thumb applied throughout: a client may SELECT its own and public
-- data, may INSERT rows that represent "things I did" (an attempt, a report,
-- a friend request), and may almost never UPDATE anything that represents a
-- score, balance, or verdict — those move only through security-definer
-- functions (see 20260907120200_functions_and_triggers.sql) called from
-- Edge Functions with the service role, or from the client via RPC where the
-- function itself re-derives the value rather than accepting it as an
-- argument to trust.
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.rank_titles enable row level security;
alter table public.categories enable row level security;
alter table public.subcategories enable row level security;
alter table public.taxonomy_i18n enable row level security;
alter table public.questions enable row level security;
alter table public.question_i18n enable row level security;
alter table public.featured_quizzes enable row level security;
alter table public.level_progress enable row level security;
alter table public.level_attempts enable row level security;
alter table public.score_events enable row level security;
alter table public.friendships enable row level security;
alter table public.duels enable row level security;
alter table public.matchmaking_queue enable row level security;
alter table public.wallet_ledger enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.daily_challenges enable row level security;
alter table public.daily_attempts enable row level security;
alter table public.streak_milestones enable row level security;
alter table public.league_cohorts enable row level security;
alter table public.league_memberships enable row level security;
alter table public.question_reports enable row level security;
alter table public.fcm_tokens enable row level security;
alter table public.app_notifications enable row level security;
alter table public.iap_transactions enable row level security;

-- ── profiles ─────────────────────────────────────────────────────────────
-- Anyone signed in can read any profile (leaderboards, friends, opponents
-- all need to render another player's name/avatar). Only the owning row can
-- be updated, and only its cosmetic columns — coins/gems/hearts/xp/elo/
-- streak/league are excluded from the WITH CHECK column list by using a
-- column-level GRANT instead of trusting the row predicate alone (belt and
-- suspenders: see the REVOKE below).
create policy profiles_select_all on public.profiles
  for select using (true);

create policy profiles_insert_self on public.profiles
  for insert with check (id = auth.uid());

create policy profiles_update_self on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Column-level privilege revoke: even though the row-level policy above
-- would allow an update to a matching row, Postgres also checks column
-- privileges. Authenticated users get UPDATE only on the columns a player is
-- actually allowed to change from S-42/S-25.
revoke update on public.profiles from authenticated;
grant update (username, avatar_key, country_code, city, locale) on public.profiles to authenticated;

-- ── rank_titles / achievements / streak_milestones ─────────────────────────
-- Static reference content: public read, no client writes at all.
create policy rank_titles_select_all on public.rank_titles for select using (true);
create policy achievements_select_all on public.achievements for select using (true);
create policy streak_milestones_select_all on public.streak_milestones for select using (true);

-- ── categories / subcategories / taxonomy_i18n / featured_quizzes ──────────
create policy categories_select_active on public.categories
  for select using (is_active = true);
create policy subcategories_select_active on public.subcategories
  for select using (is_active = true);
create policy taxonomy_i18n_select_all on public.taxonomy_i18n
  for select using (true);
create policy featured_quizzes_select_active on public.featured_quizzes
  for select using (is_active = true and (ends_at is null or ends_at > now()));

-- ── questions / question_i18n ───────────────────────────────────────────
-- Select-only, and only where status = 'live'. correct_index is never
-- shipped ahead of an answer being submitted — real levels are served
-- through the start-level Edge Function (service role, bypasses RLS), which
-- strips correct_index and shuffles options per attempt before returning
-- them. These policies exist as the floor for any other read path (a
-- content-admin tool, a future "practice mode" that reads directly), not as
-- the mechanism gameplay uses.
create policy questions_select_live on public.questions
  for select using (status = 'live');
create policy question_i18n_select_live on public.question_i18n
  for select using (
    exists (
      select 1 from public.questions q
      where q.id = question_i18n.question_id and q.status = 'live'
    )
  );

-- ── level_progress ──────────────────────────────────────────────────────
-- Read: your own rows, or anyone's when building a leaderboard's category
-- progress line (LeaderboardEntry.levelsCleared) — public select is simplest
-- and cheapest; nothing here is sensitive.
create policy level_progress_select_all on public.level_progress
  for select using (true);
-- No direct insert/update policy: every write goes through submit_level(),
-- a security-definer function called by the submit-level Edge Function.
-- (No policy = no access, since RLS defaults deny.)

-- ── level_attempts ──────────────────────────────────────────────────────
-- Read-only for the client. Every row is created and updated by
-- start_level_attempt()/submit_level_attempt() (both SECURITY DEFINER, so
-- they don't need — and the client doesn't get — a direct INSERT/UPDATE
-- policy here at all).
create policy level_attempts_select_self on public.level_attempts
  for select using (user_id = auth.uid());

-- ── score_events ─────────────────────────────────────────────────────────
-- No client write at all — written only by the score_level_attempt()
-- trigger. Select is public (leaderboards read across users).
create policy score_events_select_all on public.score_events
  for select using (true);

-- ── friendships ──────────────────────────────────────────────────────────
create policy friendships_select_own on public.friendships
  for select using (auth.uid() in (requester_id, addressee_id));
create policy friendships_insert_as_requester on public.friendships
  for insert with check (requester_id = auth.uid());
-- Only the addressee can accept/block; only the requester can withdraw
-- (implemented as an update to 'blocked' or a delete respectively).
create policy friendships_update_as_addressee on public.friendships
  for update using (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());
create policy friendships_delete_as_requester on public.friendships
  for delete using (requester_id = auth.uid());

-- ── duels ────────────────────────────────────────────────────────────────
-- Readable only by the two participants.
create policy duels_select_participant on public.duels
  for select using (auth.uid() in (p1, p2));
-- Answer arrays are writable only for your own side, and only while the duel
-- is still active — enforced with a column-scoped check plus the row
-- predicate. Postgres RLS can't restrict *which* column an UPDATE touches
-- directly, so this is paired with a BEFORE UPDATE trigger
-- (guard_duel_answer_update) that raises if anything other than the caller's
-- own *_answers column actually changed.
create policy duels_update_participant_active on public.duels
  for update using (auth.uid() in (p1, p2) and status = 'active')
  with check (auth.uid() in (p1, p2));
-- No insert policy for clients: duels are created only by the matchmake
-- Edge Function (service role).

-- ── matchmaking_queue ────────────────────────────────────────────────────
create policy matchmaking_queue_select_self on public.matchmaking_queue
  for select using (user_id = auth.uid());
create policy matchmaking_queue_insert_self on public.matchmaking_queue
  for insert with check (user_id = auth.uid());
create policy matchmaking_queue_delete_self on public.matchmaking_queue
  for delete using (user_id = auth.uid());

-- ── wallet_ledger ────────────────────────────────────────────────────────
-- Read-only, own rows — this is a statement history, not something a client
-- writes to directly (that would be the same as writing your own balance).
create policy wallet_ledger_select_self on public.wallet_ledger
  for select using (user_id = auth.uid());

-- ── user_achievements ────────────────────────────────────────────────────
create policy user_achievements_select_self on public.user_achievements
  for select using (user_id = auth.uid());
-- No client insert/update: unlocked entirely by server-side rule evaluation
-- inside submit_level()/resolve_duel()/daily rollover.

-- ── daily_challenges / daily_attempts ───────────────────────────────────
create policy daily_challenges_select_all on public.daily_challenges
  for select using (true);
create policy daily_attempts_select_self on public.daily_attempts
  for select using (user_id = auth.uid());
-- No client insert: writing a daily_attempts row is play_daily_challenge()
-- (security definer), called by the client via RPC but computed server-side
-- end to end, exactly like level_attempts.

-- ── league_cohorts / league_memberships ─────────────────────────────────
create policy league_cohorts_select_all on public.league_cohorts
  for select using (true);
create policy league_memberships_select_all on public.league_memberships
  for select using (true);
-- No client writes: cohort assignment and point accrual are both driven by
-- score_level_attempt()'s trigger and the weekly daily-rollover job.

-- ── question_reports ─────────────────────────────────────────────────────
create policy question_reports_insert_self on public.question_reports
  for insert with check (user_id = auth.uid());
create policy question_reports_select_self on public.question_reports
  for select using (user_id = auth.uid());

-- ── fcm_tokens ───────────────────────────────────────────────────────────
create policy fcm_tokens_all_self on public.fcm_tokens
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── app_notifications ────────────────────────────────────────────────────
create policy app_notifications_select_self on public.app_notifications
  for select using (user_id = auth.uid());
-- The client may mark its own rows read, and nothing else (kind, title,
-- body, challenger_id are all server-written).
create policy app_notifications_update_read_self on public.app_notifications
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
revoke update on public.app_notifications from authenticated;
grant update (is_read) on public.app_notifications to authenticated;
-- Deleting a row is how the client dismisses an actioned duel-challenge
-- notification (NotificationsApi.acceptChallenge removes the row).
create policy app_notifications_delete_self on public.app_notifications
  for delete using (user_id = auth.uid());

-- ── iap_transactions ─────────────────────────────────────────────────────
-- Read-only, own rows. Writes happen only inside verify-purchase (service
-- role) — this is the idempotency ledger a client must never be able to
-- forge a row into.
create policy iap_transactions_select_self on public.iap_transactions
  for select using (user_id = auth.uid());
