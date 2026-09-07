-- ============================================================================
-- Quizoo — Initial schema
--
-- Base tables are transcribed from the Design Bible §23 "Data model" DDL
-- (docs/quizoo-design-bible.html), with additions marked "[APP]" where the
-- actual Flutter domain models (core/models/*.dart, features/*/domain/*.dart)
-- need a column or table the bible's trimmed DDL didn't include. See
-- .claude/plans/005-backend-foundation-core-loop.md and
-- .claude/plans/006-social-economy-realtime-backend.md, "Data model / API
-- changes", for the full reasoning behind each [APP] addition.
--
-- Run order: this file, then 20260907120100_rls_policies.sql, then
-- 20260907120200_functions_and_triggers.sql, then ../seed.sql.
-- ============================================================================

create extension if not exists citext;
create extension if not exists pgcrypto;
create extension if not exists pg_cron;

-- ============================================================================
-- IDENTITY
-- ============================================================================

-- One row per auth.users row, created by a trigger (see functions_and_triggers)
-- the moment a user signs up — including anonymous/guest sign-ins.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,

  -- Null until the player completes S-25 (profile creation). The app's own
  -- AuthUser.isProfileComplete is exactly "username is not null" — see
  -- plan 005. [APP] the bible's DDL has `username ... not null`; relaxed to
  -- nullable because the email sign-in route creates the auth user and the
  -- profiles row *before* the player has chosen one (AuthApi.startEmailSignIn
  -- returns an AuthUser with displayName: '' and isProfileComplete: false).
  username citext unique,
  constraint username_len check (
    username is null or char_length(username::text) between 3 and 20
  ),

  -- Stored as the emoji itself (e.g. '🐼'), matching AuthUser.avatarEmoji /
  -- Subcategory-style "no asset pipeline yet" convention — not a lookup key
  -- into an asset catalogue.
  avatar_key text not null default '🐼',

  country_code char(2),
  -- [APP] ProfileSummary.cityLabel ("🇵🇰 Islamabad") needs a city; the bible's
  -- profiles table has no such column.
  city text,

  locale text not null default 'en',
  is_guest boolean not null default true,

  xp integer not null default 0,
  player_level integer not null default 1,

  coins integer not null default 500,
  gems integer not null default 0,
  hearts smallint not null default 5,
  -- [APP] PlayerCurrency.maxHearts — the bible's `hearts` column has no
  -- accompanying ceiling column; a power-up/purchase could raise it later.
  max_hearts smallint not null default 5,
  hearts_updated_at timestamptz not null default now(),

  streak_days integer not null default 0,
  streak_freezes smallint not null default 2,
  last_played_on date,

  elo integer not null default 1200,
  league text not null default 'bronze'
    check (league in ('bronze', 'silver', 'gold', 'platinum', 'diamond')),

  created_at timestamptz not null default now()
);

comment on column public.profiles.hearts is
  'Authoritative wallet value. Never written by the client directly — see '
  'RLS policies and the spend_hearts/refill_hearts functions.';

-- [APP] ProfileSummary.rankTitle ("Curious Mind" at level 10-14). The bible
-- names this concept ("§19 rank titles") but its trimmed DDL doesn't include
-- the table. Seeded with placeholder bands in seed.sql — replace with the
-- exact ladder from Design Bible §19 before shipping; the app only needs the
-- shape (contiguous, non-overlapping level ranges -> a title) to be right.
create table public.rank_titles (
  min_level integer primary key,
  max_level integer not null check (max_level >= min_level),
  title text not null
);

-- ============================================================================
-- CONTENT
-- ============================================================================

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  emoji text not null,
  -- [APP] Category.colorFrom/colorTo (gradient pair) — the bible's DDL has
  -- these on categories already; kept as-is.
  color_from text not null,
  color_to text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,

  -- [APP] Category.subcategoryCount / questionCount / (player_count backs
  -- CategoryDetail.playerCount). Denormalized counters, kept in sync by
  -- triggers in functions_and_triggers.sql rather than counted on every read
  -- — Home and Browse render these on every screen open.
  subcategory_count integer not null default 0,
  question_count integer not null default 0,
  player_count integer not null default 0
);

create table public.subcategories (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories (id) on delete cascade,
  slug text unique not null,
  emoji text not null,
  -- [APP] Subcategory.plateColor — the tint behind the tile's emoji plate.
  plate_color text not null,
  -- [APP] Subcategory.groupName ("Astronomy" under Science) — empty string
  -- when the topic sits directly under its category, matching the Flutter
  -- default.
  group_name text not null default '',

  -- [APP] Subcategory.questionCount — cached count of live questions, kept in
  -- sync by the same trigger that maintains categories.question_count.
  question_count integer not null default 0,
  play_count integer not null default 0,

  -- [APP] Subcategory.isNew / isLocked — editorial flags the content team
  -- sets explicitly (e.g. on a v1.1 content launch), not derived from
  -- created_at. Locked means "not entitled yet", independent of is_active
  -- (which means "not shipped at all").
  is_new boolean not null default false,
  is_locked boolean not null default false,

  sort_order integer not null default 0,
  is_active boolean not null default true
);

-- Names/descriptions live in a translation table so a category or topic is
-- never English-only (Design Bible: 5 languages incl. Urdu RTL).
create table public.taxonomy_i18n (
  entity_type text not null check (entity_type in ('category', 'subcategory')),
  entity_id uuid not null,
  locale text not null,
  name text not null,
  description text,
  primary key (entity_type, entity_id, locale)
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  subcategory_id uuid not null references public.subcategories (id) on delete cascade,
  kind text not null default 'text' check (kind in ('text', 'image', 'audio', 'figure')),
  difficulty smallint not null check (difficulty between 1 and 5),
  media_url text,
  figure_svg text,
  status text not null default 'draft' check (status in ('draft', 'live', 'suspended')),
  valid_until date,

  -- Live calibration, written nightly by the daily-rollover job.
  seen_count integer not null default 0,
  correct_count integer not null default 0,
  avg_answer_ms integer,

  created_at timestamptz not null default now()
);

create table public.question_i18n (
  question_id uuid not null references public.questions (id) on delete cascade,
  locale text not null,
  prompt text not null,
  -- e.g. ["Tungsten","Tin","Titanium","Uranium"]
  options jsonb not null,
  correct_index smallint not null,
  explanation text not null, -- required — "no explanation, no publish" (§21)
  review_state text not null default 'pending',
  primary key (question_id, locale)
);

create index questions_subcategory_difficulty_live_idx
  on public.questions (subcategory_id, difficulty, status)
  where status = 'live';

-- [APP] HomeContent.popular / PopularQuiz — Home's merchandised "Popular this
-- week" rail is editorial curation with its own title/gradient, distinct from
-- the subcategory's own taxonomy colors (the bible's screens show a card
-- whose colors are NOT its category's). Not in the bible's trimmed DDL.
create table public.featured_quizzes (
  id uuid primary key default gen_random_uuid(),
  subcategory_id uuid not null references public.subcategories (id),
  title text not null,
  emoji text not null,
  color_from text not null,
  color_to text not null,
  played_count integer not null default 0,
  is_hot boolean not null default false,
  sort_order integer not null default 0,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  is_active boolean not null default true
);

-- ============================================================================
-- PROGRESS
-- ============================================================================

create table public.level_progress (
  user_id uuid not null references public.profiles (id) on delete cascade,
  subcategory_id uuid not null references public.subcategories (id),
  level smallint not null check (level between 1 and 20),
  best_score integer not null default 0,
  stars smallint not null default 0 check (stars between 0 and 3),
  attempts integer not null default 0,
  completed_at timestamptz,
  -- [APP] HomeContent.continueEntry needs "the level I most recently
  -- touched but haven't 3-starred" — ordering by last_played_at is how the
  -- fetch-home query finds it without a second table.
  last_played_at timestamptz not null default now(),
  primary key (user_id, subcategory_id, level)
);

-- The audit trail the server scores from. A row here is the only source of
-- truth for a run; QuizRun/AnsweredQuestion on the client are display state
-- built from what this table (via submit-level) hands back.
create table public.level_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  subcategory_id uuid not null references public.subcategories (id),
  level smallint not null,
  -- Server-issued by start-level; fixes the question set + shuffle for this
  -- attempt so submit-level can re-derive correctness without trusting the
  -- client's copy of correct_index.
  seed text not null,
  -- The locale the questions were served in — correctness is re-derived at
  -- submit time from question_i18n for this same locale.
  locale text not null default 'en',
  -- [{questionId, chosenIndex, secondsLeft, action}] as submitted by the
  -- client; action is 'answered' | 'timedOut' | 'skipped'. Populated by
  -- submit_level_attempt, not by the client's own INSERT (there is no client
  -- INSERT — see RLS policies). "outcome" (correct/wrong/timedOut/skipped,
  -- matching Dart's AnswerOutcome) is derived server-side from chosenIndex,
  -- never trusted from the client — see submit_level_attempt.
  answers jsonb not null default '[]',
  client_score integer,     -- display only, never trusted
  server_score integer,     -- authoritative, computed by submit-level
  correct_count smallint,
  stars smallint,
  is_boss boolean not null default false,
  used_power_up boolean not null default false,
  flagged boolean not null default false, -- anti-cheat
  ending text check (ending in ('finished', 'outOfHearts', 'quit')),
  created_at timestamptz not null default now()
);

create index level_attempts_user_idx on public.level_attempts (user_id, created_at desc);

-- ============================================================================
-- LEADERBOARDS
-- ============================================================================

-- One row per scored event (a cleared level, a duel win, a daily challenge).
-- This is the append-only ledger every leaderboard view rolls up — see the
-- Design Bible's own note: "the query Firestore cannot do".
create table public.score_events (
  id bigserial primary key,
  user_id uuid not null references public.profiles (id),
  subcategory_id uuid references public.subcategories (id),
  category_id uuid references public.categories (id),
  country_code char(2),
  points integer not null,
  source text not null default 'level' check (source in ('level', 'daily', 'duel')),
  occurred_at timestamptz not null default now()
);

create index score_events_occurred_idx on public.score_events (occurred_at desc);
create index score_events_user_idx on public.score_events (user_id, occurred_at desc);

-- ============================================================================
-- SOCIAL, DUELS, ECONOMY
-- ============================================================================

create table public.friendships (
  requester_id uuid not null references public.profiles (id),
  addressee_id uuid not null references public.profiles (id),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  primary key (requester_id, addressee_id),
  constraint no_self_friend check (requester_id <> addressee_id)
);

create table public.duels (
  id uuid primary key default gen_random_uuid(),
  p1 uuid not null references public.profiles (id),
  p2 uuid references public.profiles (id), -- null while queued, set on pairing
  is_bot boolean not null default false,
  question_ids uuid[] not null,

  -- Each element: {"round": int, "chosenIndex": int, "answeredAtMs": int,
  -- "correct": bool}. "correct" is populated by resolve-duel only after both
  -- sides have answered a round, never by the client — see RLS policies.
  p1_answers jsonb not null default '[]',
  p2_answers jsonb not null default '[]',

  p1_rounds smallint not null default 0,
  p2_rounds smallint not null default 0,
  winner uuid references public.profiles (id),
  status text not null default 'active' check (status in ('active', 'complete', 'forfeit')),

  p1_elo_before integer,
  p2_elo_before integer,
  p1_elo_after integer,
  p2_elo_after integer,

  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours'
);

create index duels_p1_idx on public.duels (p1);
create index duels_p2_idx on public.duels (p2);

-- Matchmaking queue — matchmake polls/consumes this; resolved rows are
-- deleted once paired.
create table public.matchmaking_queue (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  elo integer not null,
  queued_at timestamptz not null default now()
);

-- Every coin/gem/heart movement, no exceptions — this is what makes the
-- wallet auditable and is the only thing spend/grant functions ever write to
-- besides profiles itself.
create table public.wallet_ledger (
  id bigserial primary key,
  user_id uuid not null references public.profiles (id),
  currency text not null check (currency in ('coins', 'gems', 'hearts')),
  delta integer not null,
  reason text not null, -- e.g. 'level_reward', 'iap', 'ad_reward', 'power_up_spend'
  ref_id uuid,          -- the level_attempts.id / duels.id / iap_transactions.id this ties to
  created_at timestamptz not null default now()
);

create index wallet_ledger_user_idx on public.wallet_ledger (user_id, created_at desc);

create table public.achievements (
  id text primary key,
  name text not null,
  emoji text not null,
  description text not null,
  -- [APP] AppBadge.gradientFrom/gradientTo — the bible's achievements table
  -- has no color columns.
  gradient_from text not null,
  gradient_to text not null,
  -- [APP] BadgeCategory (skill/streak/social/rare) — renamed from the
  -- bible's "family" to match the Flutter enum name directly.
  category text not null check (category in ('skill', 'streak', 'social', 'rare')),
  -- [APP] AppBadge.rarityPercent is a percentage (0-100), not the bible's
  -- free-text "rarity" tier.
  rarity_percent numeric(5, 2) not null default 100,
  coin_reward integer not null default 0,
  gem_reward integer not null default 0,
  -- Machine-checkable unlock rule, evaluated by the submit-level /
  -- resolve-duel / daily-rollover functions. Shape is rule-specific, e.g.
  -- {"type": "level_flawless"} or {"type": "streak_days", "days": 100}.
  criteria jsonb not null
);

create table public.user_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id text not null references public.achievements (id),
  -- [APP] BadgeProgress.closestFractionLabel/closestProgress for a locked
  -- badge's "3 / 8 TOPICS" line — progress is free-form per criteria shape,
  -- e.g. {"current": 3, "target": 8}.
  progress jsonb not null default '{}',
  unlocked_at timestamptz,
  primary key (user_id, achievement_id)
);

create table public.daily_challenges (
  challenge_date date primary key,
  question_ids uuid[] not null, -- same ten for every player worldwide
  -- [APP] DailyChallenge.title/secondsPerQuestion/coinReward/xpReward — the
  -- bible's trimmed DDL only carries question_ids + the histogram; these are
  -- stored per-date (rather than a global constant) so a past day's reward
  -- rules stay accurate if the ruleset changes later.
  title text not null default 'Mixed Bag',
  seconds_per_question smallint not null default 20,
  coin_reward integer not null default 300,
  xp_reward integer not null default 500,
  score_histogram jsonb not null default '{}' -- 5-bucket global spread, §28
);

-- [APP] DailyResult / "playedTodayCount" / "averageCorrect" — one row per
-- player per day. Not in the bible's trimmed DDL; daily_challenges alone has
-- nowhere to record who played and how they did.
create table public.daily_attempts (
  user_id uuid not null references public.profiles (id) on delete cascade,
  challenge_date date not null references public.daily_challenges (challenge_date),
  correct_count smallint not null,
  total_count smallint not null,
  answer_pattern boolean[] not null,
  coins_earned integer not null default 0,
  completed_at timestamptz not null default now(),
  primary key (user_id, challenge_date)
);

-- [APP] StreakStatus.milestones ("14-day streak" -> "1,000 🪙"). Static
-- reward-ladder content, same category as rank_titles.
create table public.streak_milestones (
  days integer primary key,
  reward_label text not null,
  coin_reward integer not null default 0,
  gem_reward integer not null default 0
);

-- [APP] Weekly leagues of ~30 similar-XP players (§19: "leagues are separate
-- from boards"). profiles.league is only the *tier* name; these two tables
-- are the actual weekly cohort daily-rollover assigns players into.
create table public.league_cohorts (
  id uuid primary key default gen_random_uuid(),
  tier text not null check (tier in ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
  week_start date not null,
  unique (tier, week_start, id)
);

create table public.league_memberships (
  cohort_id uuid not null references public.league_cohorts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  points integer not null default 0,
  primary key (cohort_id, user_id)
);

create index league_memberships_user_idx on public.league_memberships (user_id);

create table public.question_reports (
  id bigserial primary key,
  question_id uuid not null references public.questions (id),
  user_id uuid not null references public.profiles (id),
  locale text not null,
  reason text not null,
  note text,
  resolved boolean not null default false,
  created_at timestamptz not null default now()
);

-- [APP] Settings' push-notification registration. Not in the bible's DDL —
-- needed the moment FCM device tokens exist.
create table public.fcm_tokens (
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android', 'web')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

-- [APP] Settings' in-app notification center (features/settings/domain/
-- app_notification.dart) — distinct from FCM push, which merely wakes the
-- app; this is the persisted list S-44 renders.
create table public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (
    kind in ('duelChallenge', 'streakEnding', 'leagueRankDrop', 'newContent', 'rewardClaimed')
  ),
  title text not null,
  body text not null,
  is_read boolean not null default false,
  -- Set only for kind = 'duelChallenge'.
  challenger_id uuid references public.profiles (id),
  duel_id uuid references public.duels (id),
  created_at timestamptz not null default now()
);

create index app_notifications_user_idx on public.app_notifications (user_id, created_at desc);

-- [APP] verify-purchase's idempotency ledger — "credits coins once" (§22)
-- needs somewhere to record which store transaction ids have already been
-- processed.
create table public.iap_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  store text not null check (store in ('app_store', 'play_store')),
  product_id text not null,
  store_transaction_id text not null,
  coins_credited integer not null default 0,
  gems_credited integer not null default 0,
  created_at timestamptz not null default now(),
  unique (store, store_transaction_id)
);
