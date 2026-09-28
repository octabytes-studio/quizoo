-- ============================================================================
-- 20260927120000_duel_arena_schema.sql
--
-- Plan 017 (Real 1v1 duels — challenge arena, matchmaking & live play),
-- Phase 1: schema & config only. No functions here; those follow in
-- 20260927120200 (arena/challenges), 20260927120300 (matchmaking),
-- 20260927120400 (live play) and 20260927120500 (sweeper + cron).
--
-- Phase 0 snapshot (live project, 27 Sep 2026, read-only checks):
--   duels = 1 row (a completed bot duel), matchmaking_queue = 0 rows,
--   duels status check constraint is named `duels_status_check`,
--   pg_cron 1.6.4, no realtime.messages policies, supabase_realtime
--   publication has no tables, last applied migration =
--   activate_hi_ar_fr_es_languages.
--
-- Deviations from the plan's Phase 1 checklist (all additive, flagged in the
-- hand-off report):
--   * The guard_duel_answer_update trigger is DROPPED, not left in place. Its
--     function raises 'rounds/status/winner are server-only' on ANY update
--     that changes p1_rounds/p2_rounds/status/winner -- unconditionally, even
--     when the update comes from a security-definer function (auth.uid() is
--     still the caller's). Left in place it would make every live-duel RPC
--     (mark_duel_ready, round resolution, _duel_finish, _duel_abandon) fail.
--     Its only purpose was policing the client update policy
--     duels_update_participant_active, which this migration also drops, so
--     with no client update path left it guards nothing.
--   * Extra columns: duel_challenges.category_id (so the challenge card's
--     topic carries categoryId like every other topic JSON),
--     duel_join_requests.reason (so a snapshot can replay the reason of a
--     terminal request) and .requester_is_guest (so the incoming-request
--     card's isGuest needs no join), duels.p1_badge_ids / p2_badge_ids (so
--     get_duel_state's result.badgeIds is reproducible after duel_end) and
--     duels.end_cause (why an abandoned duel was abandoned).
--   * Extra indexes: duels_winner_idx (duel-win achievement counting) and two
--     housekeeping indexes on duel_join_requests.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- Tunables. One jsonb row, same "tune live, no redeploy" pattern as
-- boss_level_interval / questions_per_level. Functions read it through
-- _duel_cfg(), which layers it over hard-coded defaults, so a missing key
-- never turns into a null threshold.
-- ---------------------------------------------------------------------------
insert into public.app_settings (key, value, description, updated_at)
values (
  'duel_config',
  '{"challenge_ttl_seconds":300,"challenge_cooldown_seconds":120,"challenge_daily_cap":60,
    "join_window_seconds":5,"join_grace_ms":1500,"join_max_outstanding":3,
    "join_rate_max":20,"join_rate_window_seconds":300,"join_retry_seconds":15,"join_queue_cap":10,
    "lobby_heartbeat_seconds":10,"creator_stale_seconds":25,"lobby_feed_limit":50,"lobby_presence_enabled":true,
    "min_topic_questions":5,
    "mm_heartbeat_seconds":3,"mm_stale_seconds":12,"mm_bot_after_seconds":30,
    "mm_band_start":100,"mm_band_step":50,"mm_band_step_seconds":5,"mm_band_max":600,
    "mm_topic_level_weight":10,"mm_join_rate_max":20,"mm_join_rate_window_seconds":600,
    "rounds":5,"round_seconds":15,"reveal_seconds":2,"intro_seconds":3,
    "latency_allowance_ms":1500,"min_answer_ms":250,
    "ready_timeout_seconds":20,"duel_heartbeat_seconds":5,"disconnect_forfeit_seconds":30,
    "rematch_window_seconds":30,"ranked_pair_cap_per_day":3,
    "rage_quit_forfeits_per_day":3,"elo_k":32,
    "reward_win_coins":200,"reward_win_xp":250,"reward_loss_coins":40,"reward_loss_xp":80,
    "reward_draw_coins":40,"reward_draw_xp":80}'::jsonb,
  'Duel arena / matchmaking / live duel tunables (plan 017)',
  now()
)
on conflict (key) do update
  set value = excluded.value,
      description = excluded.description,
      updated_at = now();

-- ---------------------------------------------------------------------------
-- duel_challenges: the arena feed. One row per posted challenge; the row is
-- DELETED (not archived) when it's cancelled, expires, or its duel ends --
-- the feed only ever shows what is live right now. The display snapshot
-- columns exist so a feed card, and its Realtime broadcast, can be built
-- from the row alone with no joins (the broadcast is sent from a trigger on
-- every insert/delete/state change).
-- ---------------------------------------------------------------------------
create table public.duel_challenges (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles (id) on delete cascade,
  subcategory_id uuid not null references public.subcategories (id) on delete cascade,
  -- [plan 017 addition] so the card's topic JSON carries categoryId like
  -- every other topic payload.
  category_id uuid not null references public.categories (id) on delete cascade,
  language_code text not null references public.languages (code),
  status text not null default 'open' check (status in ('open', 'matched')),
  creator_present boolean not null default true,
  -- Display snapshot (so the feed card and its broadcast need no joins):
  creator_name text,            -- null for a player with no username yet
  creator_guest_tag text,       -- set only when creator_name is null
  creator_avatar text not null,
  creator_elo integer not null,
  creator_league text not null,
  creator_topic_level smallint not null default 0,
  topic_name text not null,
  topic_emoji text not null,
  topic_plate_color text not null,
  category_name text not null,
  category_emoji text not null,
  duel_id uuid references public.duels (id) on delete set null,
  opponent_name text,           -- set when matched ("vs Zara N.")
  opponent_guest_tag text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

comment on table public.duel_challenges is
  'Plan 017 arena feed: one row per live challenge, deleted (not archived) '
  'when cancelled, expired or its duel ends. Snapshot columns let the card '
  'and its Realtime broadcast be built from the row alone. RPC-only access.';

create unique index duel_challenges_one_open_per_creator
  on public.duel_challenges (creator_id) where status = 'open';
create index duel_challenges_feed_idx
  on public.duel_challenges (language_code, created_at desc);
create index duel_challenges_expiry_idx
  on public.duel_challenges (expires_at) where status = 'open';

-- ---------------------------------------------------------------------------
-- duel_join_requests: the per-challenge join queue. The creator is shown one
-- request at a time ('pending', 5 s window); everything behind it waits as
-- 'queued'. Terminal rows linger briefly so the requester's retry cool-down
-- (retry_after) survives a snapshot refetch, then the sweeper deletes them.
-- ---------------------------------------------------------------------------
create table public.duel_join_requests (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.duel_challenges (id) on delete cascade,
  creator_id uuid not null references public.profiles (id) on delete cascade,
  requester_id uuid not null references public.profiles (id) on delete cascade,
  status text not null check (status in ('queued', 'pending', 'accepted', 'declined', 'expired', 'withdrawn')),
  -- [plan 017 addition] why the row reached its current status
  -- ('declined', 'no_response', 'taken', 'creator_away', ...).
  reason text,
  requester_name text,
  requester_guest_tag text,
  -- [plan 017 addition] so the incoming-request card's isGuest needs no join.
  requester_is_guest boolean not null default false,
  requester_avatar text not null,
  requester_elo integer not null,
  requester_league text not null,
  requester_topic_level smallint not null default 0,
  created_at timestamptz not null default now(),
  presented_at timestamptz,
  expires_at timestamptz,
  resolved_at timestamptz,
  retry_after timestamptz
);

comment on table public.duel_join_requests is
  'Plan 017 join-request queue per challenge: one pending (shown to the '
  'creator with a 5 s window) at a time, the rest queued. ON DELETE CASCADE '
  'from duel_challenges means delete paths must notify requesters first '
  '(_duel_delete_challenge does). RPC-only access.';

create unique index duel_join_requests_active_uq
  on public.duel_join_requests (challenge_id, requester_id) where status in ('queued', 'pending');
create unique index duel_join_requests_one_pending
  on public.duel_join_requests (challenge_id) where status = 'pending';
create index duel_join_requests_requester_active
  on public.duel_join_requests (requester_id) where status in ('queued', 'pending');
create index duel_join_requests_pending_expiry
  on public.duel_join_requests (expires_at) where status = 'pending';
-- [plan 017 addition] retry_after lookups + the lobby's myRequests (terminal
-- rows included), and the sweeper's housekeeping delete.
create index duel_join_requests_requester_idx
  on public.duel_join_requests (requester_id, challenge_id);
create index duel_join_requests_resolved_idx
  on public.duel_join_requests (resolved_at) where resolved_at is not null;

-- ---------------------------------------------------------------------------
-- duel_player_state: one row per player who has touched duels. It is the
-- lock target for "one duel at a time" -- current_duel_id is only ever set
-- or cleared under SELECT ... FOR UPDATE on this row (both players' rows,
-- locked in ascending user_id order), by _duel_create / _duel_finish /
-- _duel_abandon.
-- ---------------------------------------------------------------------------
create table public.duel_player_state (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  current_duel_id uuid references public.duels (id) on delete set null,
  last_challenge_at timestamptz,
  lobby_seen_at timestamptz,
  updated_at timestamptz not null default now()
);

comment on table public.duel_player_state is
  'Plan 017 per-player duel state and the row-lock target that makes "one '
  'duel at a time" a lock, not a hope. Also holds the challenge cool-off '
  'clock and the arena heartbeat (lobby_seen_at). RPC-only access.';

-- ---------------------------------------------------------------------------
-- duel_rate_buckets: fixed-window counters behind every anti-spam limit
-- (daily challenge cap, join-request rate, matchmaking-join rate).
-- ---------------------------------------------------------------------------
create table public.duel_rate_buckets (
  user_id uuid not null references public.profiles (id) on delete cascade,
  bucket text not null,
  window_start timestamptz not null,
  hits integer not null default 0,
  primary key (user_id, bucket)
);

comment on table public.duel_rate_buckets is
  'Plan 017 fixed-window rate-limit counters (challenge_day, join, mm_join). '
  'Written only by _duel_rate_hit; stale windows are swept. RPC-only access.';

-- ---------------------------------------------------------------------------
-- duel_rounds: the server-only round ledger for live duels, replacing the
-- client-writable p1_answers/p2_answers arrays. No client policy at all, so
-- neither the question id nor the opponent's choice is readable before the
-- round resolves.
-- ---------------------------------------------------------------------------
create table public.duel_rounds (
  duel_id uuid not null references public.duels (id) on delete cascade,
  round smallint not null check (round between 1 and 10),
  question_id uuid not null references public.questions (id),
  starts_at timestamptz,
  deadline timestamptz,
  p1_choice smallint,
  p1_ms integer,
  p1_locked_at timestamptz,
  p2_choice smallint,
  p2_ms integer,
  p2_locked_at timestamptz,
  outcome text check (outcome in ('p1', 'p2', 'draw')),
  resolved_at timestamptz,
  primary key (duel_id, round)
);

comment on table public.duel_rounds is
  'Plan 017 server-only round ledger for live duels. "Locked" = '
  'pN_locked_at is not null; a null pN_choice with a lock means timeout / '
  'no answer. No client policy: question ids and the opponent''s choice are '
  'never readable before the round resolves.';

-- ---------------------------------------------------------------------------
-- duels: live-duel columns. All nullable or defaulted, so the existing bot
-- rows (and submit_bot_duel's insert) stay valid unchanged.
-- ---------------------------------------------------------------------------
alter table public.duels
  add column subcategory_id uuid references public.subcategories (id),
  add column language_code text references public.languages (code),
  add column origin text not null default 'bot'
    check (origin in ('bot', 'challenge', 'matchmaking', 'rematch')),
  add column challenge_id uuid,           -- no FK: challenge rows are deleted by design
  add column rematch_of uuid references public.duels (id),
  add column is_ranked boolean not null default true,
  add column current_round smallint not null default 0,
  add column p1_ready_at timestamptz,
  add column p2_ready_at timestamptz,
  add column p1_seen_at timestamptz,
  add column p2_seen_at timestamptz,
  add column p1_rematch_at timestamptz,
  add column p2_rematch_at timestamptz,
  add column end_reason text check (end_reason in ('completed', 'forfeit', 'abandoned')),
  -- [plan 017 addition] why an abandoned duel was abandoned ('no_show',
  -- 'left_before_start', 'both_disconnected', 'expired').
  add column end_cause text,
  add column forfeited_by uuid references public.profiles (id),
  add column p1_coins integer,
  add column p2_coins integer,
  add column p1_xp integer,
  add column p2_xp integer,
  -- [plan 017 addition] badges unlocked by this duel, so get_duel_state can
  -- replay duel_end's badgeIds after the fact.
  add column p1_badge_ids text[] not null default '{}',
  add column p2_badge_ids text[] not null default '{}',
  add column ended_at timestamptz;

comment on column public.duels.question_ids is
  'Bot duels: always empty. Live duels (plan 017): also left empty on '
  'purpose -- duels_select_participant lets a participant read this row, '
  'so the question ids live only in the server-only duel_rounds table '
  '(otherwise a client could read all five questions ahead of time).';

alter table public.duels drop constraint duels_status_check;   -- name verified in Phase 0
alter table public.duels add constraint duels_status_check
  check (status in ('pending', 'active', 'complete', 'forfeit', 'abandoned'));

create index duels_live_idx on public.duels (status) where status in ('pending', 'active');
create index duels_pair_idx on public.duels (least(p1, p2), greatest(p1, p2), created_at desc)
  where p2 is not null;
create index duels_forfeited_by_idx on public.duels (forfeited_by, ended_at desc)
  where forfeited_by is not null;
-- [plan 017 addition] duel_wins achievement counting (_duel_check_achievements).
create index duels_winner_idx on public.duels (winner) where winner is not null;

-- The guard trigger is incompatible with server-side duel updates (see
-- header) and guarded only the client update policy dropped below.
drop trigger if exists guard_duel_answer_update on public.duels;
drop function if exists public._guard_duel_answer_update();

-- ---------------------------------------------------------------------------
-- matchmaking_queue: scoped to a (sub-category, language) topic, with a
-- heartbeat. 0 rows verified in Phase 0; the delete makes the NOT NULL adds
-- safe regardless.
-- ---------------------------------------------------------------------------
delete from public.matchmaking_queue;

alter table public.matchmaking_queue
  add column subcategory_id uuid not null references public.subcategories (id) on delete cascade,
  add column language_code text not null references public.languages (code),
  add column topic_level smallint not null default 0,
  add column last_seen_at timestamptz not null default now();

create index matchmaking_queue_topic_idx
  on public.matchmaking_queue (subcategory_id, language_code, elo);

-- ---------------------------------------------------------------------------
-- RLS: RPC-only access for all five new tables (security-definer functions
-- bypass RLS; no client policy on purpose). Drop the client write paths that
-- real play makes unsafe: a participant could append answers with a forged
-- answeredAtMs, and queue rows must be written only by join_matchmaking so
-- the topic/ELO/heartbeat columns can be trusted.
-- ---------------------------------------------------------------------------
alter table public.duel_challenges enable row level security;
alter table public.duel_join_requests enable row level security;
alter table public.duel_player_state enable row level security;
alter table public.duel_rate_buckets enable row level security;
alter table public.duel_rounds enable row level security;

drop policy if exists duels_update_participant_active on public.duels;
drop policy if exists matchmaking_queue_insert_self on public.matchmaking_queue;
drop policy if exists matchmaking_queue_delete_self on public.matchmaking_queue;
-- Kept: duels_select_participant, matchmaking_queue_select_self.

commit;
