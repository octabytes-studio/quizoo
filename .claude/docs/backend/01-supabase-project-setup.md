# 01 — Supabase project setup

Manual, one-time (per environment) setup in the Supabase dashboard and CLI.
Budget about an hour, most of it waiting on project provisioning.

## 1. Create the project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard) and sign
   in (create an account if you don't have one — GitHub sign-in is fastest).
2. **New project** → pick an organization (create one if this is your first
   project) → name it `quizoo` (or `quizoo-staging` / `quizoo-prod` if you're
   running two — see §7 below).
3. Choose a **database password** and save it somewhere durable (a password
   manager, not a chat message) — you'll need it once for the CLI link step
   and rarely again, since the app itself never uses it directly.
4. Pick a **region** close to your expected player base (e.g. `ap-south-1`
   Mumbai or `me-central-1` for a Pakistan/Gulf-heavy launch).
5. Wait for provisioning (2-3 minutes).

## 2. Install the Supabase CLI and link the project

On your development machine (not required in the Flutter project itself —
this is a one-time schema push):

```bash
# macOS
brew install supabase/tap/supabase

# or via npm
npm install -g supabase
```

From the Flutter project root (`quizoo/`):

```bash
supabase login
supabase init          # creates a supabase/config.toml if one doesn't exist yet —
                        # the migrations/ and seed.sql this repo already has stay as-is
supabase link --project-ref <your-project-ref>
```

The project ref is in the dashboard URL
(`https://supabase.com/dashboard/project/<project-ref>`) or under
**Project Settings → General**.

## 3. Run the migrations and seed data

```bash
supabase db push        # applies supabase/migrations/*.sql in order
```

Then run `supabase/seed.sql` once. It's idempotent, so re-running it is
harmless either way you do this:

- **Dashboard SQL Editor (no installs needed)** — open the project's **SQL
  Editor**, paste in `supabase/seed.sql`'s contents, and run it. This is the
  fastest path and needs neither Docker nor a local Postgres client.
- **`psql` from your machine** — `supabase status` only reports on a
  **local** Docker/Podman-backed dev stack (`supabase start`), so it won't
  work against a linked remote project and doesn't require Docker to be
  running for this step at all. Instead, get the connection string from
  **Project Settings → Database → Connection string** (URI form, "Session
  pooler" or "Direct connection" both work) and run:

  ```bash
  psql "<connection-string-from-dashboard>" -f supabase/seed.sql
  ```

  This needs the `psql` client installed locally — on macOS, if you don't
  have it: `brew install libpq && brew link --force libpq`.

**Verify:** in the dashboard's **Table Editor**, `categories` should have 6
rows, `subcategories` 26, `questions` 24, `achievements` 14.

## 4. Configure authentication providers

**Authentication → Providers**, matching `AuthProvider` in
`lib/features/auth/domain/auth_user.dart` (google / apple / email):

- **Email**: enable it. Under **Authentication → Providers → Email**, turn
  **off** "Confirm email" only if you want instant sign-in without a
  verification step (the design bible's S-24/S-25 flow doesn't show an
  email-verification screen, so plan on OTP/magic-link rather than
  password — decide with whoever executes plan 005, and record the choice
  in that plan's "Assumptions & open questions" once made).
- **Google**: you need an OAuth client ID from
  [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
  - Create an OAuth 2.0 Client ID of type **Web application** for Supabase's
    own redirect (`https://<project-ref>.supabase.co/auth/v1/callback`),
    plus separate **iOS** and **Android** OAuth client IDs (the Android one
    needs your app's SHA-1 signing fingerprint — get it with
    `cd android && ./gradlew signingReport`).
  - Paste the Web client's ID + secret into Supabase's Google provider
    settings.
- **Apple**: needs an Apple Developer account ($99/year, separate from the
  App Store Connect step in doc 03).
  - **Certificates, Identifiers & Profiles → Identifiers** — enable "Sign In
    with Apple" on your app's App ID.
  - **Keys** — create a new key with "Sign In with Apple" enabled, download
    the `.p8` file (you can only download it once).
  - In Supabase's Apple provider settings, enter your Team ID, the Key ID,
    the Services ID (a separate identifier you register for the web
    redirect), and paste the `.p8` key contents.
  - This is the fiddliest step in this whole document — Apple's own
    [Sign In with Apple for developers](https://developer.apple.com/sign-in-with-apple/)
    page has the current click-path if Supabase's provider screen's inline
    instructions drift from what you see.

**Guest / anonymous play**: **Authentication → Settings → Enable anonymous
sign-ins**. Turn this on — the design bible's Pillar 01 ("no splash gate, no
register wall") depends on it, and `profiles.is_guest` is derived from
whether the underlying `auth.users` row is anonymous (see
`_handle_new_user()` in the functions migration).

## 5. Storage buckets

**Storage → New bucket**:

- `question-media` — public read (question images/figures referenced by
  `questions.media_url`). Public, since these are shown before sign-in.
- `avatars` — public read, authenticated write, for a future custom-avatar
  upload (not in v1's scope per the design bible's emoji-avatar system, but
  cheap to create now so the bucket name is settled).
- `question-audio` — public read (pre-generated question narration clips
  referenced by `questions.audio_url`). Public, for the same reason as
  `question-media`: no signed-URL round trip needed for playback.

## 6. Confirm pg_cron is running

The functions migration schedules two jobs. Verify them:

```sql
select jobname, schedule, active from cron.job;
```

You should see `refresh-lb-weekly` (`*/2 * * * *`) and `daily-rollover`
(`0 0 * * *`), plus `refresh-featured-quizzes` (hourly) and — since plan
017 — `duel-sweeper` (`10 seconds`), the backstop that expires duel
challenges/join requests, drops stale matchmaking rows, and resolves stuck
rounds / disconnect forfeits. Second-granularity schedules need pg_cron
≥ 1.5. If `pg_cron` isn't available on your plan/region, check
**Database → Extensions** — it's enabled by the migration's
`create extension if not exists pg_cron`, but some self-hosted or very
old Supabase projects need it turned on from the dashboard first.

### Duel Realtime authorization (plan 017)

Live duels use **Realtime Broadcast from the database** (`realtime.send`),
not Postgres Changes — no table is added to the `supabase_realtime`
publication. Clients join private channels (`duel-lobby:<lang>`,
`duel-user:<uid>`, `duel:<duelId>`), and RLS policies on
`realtime.messages` (`duel_lobby_receive`, `duel_lobby_presence`,
`duel_inbox_receive`, `duel_room_receive`, `duel_room_presence`) let them
receive broadcasts and track presence but never publish. Check with:

```sql
select policyname from pg_policies where schemaname = 'realtime';
```

## 7. Get your API keys

**Project Settings → API**:

- **Project URL** (`https://<project-ref>.supabase.co`)
- **anon / public key** — this is the one that goes in the Flutter app (safe
  to ship in the client; RLS is what actually protects the data).
- **service_role key** — **never** put this in the Flutter app. It belongs
  only in Edge Function environment variables (Supabase sets this up for you
  automatically for functions deployed to your own project) and, if you ever
  need it, a server-side admin script you run yourself.

Hand the Project URL and anon key to doc **04 — Flutter app configuration**.

## 8. Staging vs. production (recommended, not required for v1)

Running two Supabase projects — `quizoo-staging` and `quizoo-prod` — means
you can test a schema change, a new Edge Function, or a content batch
without risking real players' data. If you do this:

- Repeat steps 1-7 for each project.
- Keep both sets of migrations in sync by always running `supabase db push`
  against staging first, then prod, from the same `supabase/migrations/`
  folder — never hand-edit one project's schema outside the migration files.
- Doc 04 covers wiring both sets of keys into separate Flutter build
  flavors/environments.
