# Quizoo backend setup — index

Quizoo's design bible (§22) recommends **Supabase** for data, auth, realtime
and storage, plus **Firebase** for client-only services (push, crash
reporting, analytics, remote config) — no Firestore, no Firebase Auth. This
folder is the manual setup that has to happen in the Supabase/Firebase/App
Store/Play Console dashboards before an AI agent (or you) can execute
`.claude/plans/005-backend-foundation-core-loop.md` and
`.claude/plans/006-social-economy-realtime-backend.md`.

Nothing in this folder is code. The SQL that defines the actual database
schema lives in `supabase/migrations/` and `supabase/seed.sql` at the project
root — see that folder's own comments for what each file does and the order
to run them in.

## Order of operations

1. **[01 — Supabase project setup](01-supabase-project-setup.md)**
   Create the project, run the migrations + seed, configure auth providers,
   storage, and the pg_cron schedule.
2. **[02 — Firebase project setup](02-firebase-project-setup.md)**
   Create the Firebase project, add the iOS/Android/Web apps, enable FCM,
   Crashlytics, Analytics and Remote Config.
3. **[03 — Store, IAP & push credentials](03-store-iap-push-setup.md)**
   App Store Connect and Google Play Console: in-app purchase products, the
   APNs key Firebase needs to deliver push to iOS.
4. **[04 — Flutter app configuration](04-flutter-app-configuration.md)**
   Where the config files and keys from steps 1-3 land in the actual Flutter
   project — this is the step that turns "the backend exists" into "the app
   can reach it".

Do these once per environment. If you run a separate staging and production
Supabase/Firebase project pair (recommended — see 01's last section), repeat
steps 1-3 for each and keep both sets of config side by side per 04's
flavor setup.

## What's already decided, and why

These setup docs assume the decisions already recorded in the design bible
and in the two implementation plans:

- **Supabase, not a custom backend.** Postgres + Auth + Realtime + Storage +
  Edge Functions covers everything v1 needs; see the design bible §22 for
  when to revisit this (duel concurrency past ~5,000 simultaneous matches, an
  adaptive-difficulty ML model, or a data-residency requirement).
- **Firebase is client-services-only.** FCM for push, Crashlytics, Analytics,
  Remote Config. Auth and the database are Supabase's job, not Firebase's —
  don't enable Firebase Auth or Firestore for this project.
- **Anti-cheat lives server-side.** The client never sees a question's
  correct answer before submitting; the server rescores every attempt from
  the answer log. This is why `start_level_attempt` / `submit_level_attempt`
  exist as Postgres functions rather than the client reading `questions`
  directly — see `supabase/migrations/20260907120200_functions_and_triggers.sql`.
