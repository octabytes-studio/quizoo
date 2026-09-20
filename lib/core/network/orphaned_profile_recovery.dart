import 'package:supabase_flutter/supabase_flutter.dart';

/// Detects and repairs one specific failure mode: a persisted, non-anonymous
/// Supabase Auth session (Apple/Google/email) whose backing `profiles` row
/// has been deleted server-side — the account itself no longer exists, even
/// though `auth.uid()` still resolves and the session still looks valid.
/// Every feature that fetches the player's own row via
/// `.from('profiles')....eq('id', userId).single()` (auth restore, the "You"
/// screen, ...) hits Postgrest's "no rows" (`PGRST116`) the same way when
/// this happens, so the recovery lives in exactly one place rather than
/// being re-derived per feature.
///
/// Recovery mirrors `main.dart`'s own launch bootstrap: drop the orphaned
/// session and establish a brand new anonymous one, which the database's
/// `on_auth_user_created` trigger immediately backs with a fresh `profiles`
/// row (`supabase/migrations/20260907120200_functions_and_triggers.sql`).
///
/// Returns `true` when [error] was this specific case and recovery ran — the
/// caller should treat the player as a guest (retry its own query once
/// against the new session, or return null/guest directly). Returns `false`
/// for every other error, which the caller maps normally.
Future<bool> recoverFromOrphanedProfile(
  SupabaseClient client,
  Object error,
) async {
  if (error is! PostgrestException || error.code != 'PGRST116') return false;
  final authUser = client.auth.currentUser;
  if (authUser == null || authUser.isAnonymous) return false;
  try {
    await client.auth.signOut();
    await client.auth.signInAnonymously();
  } catch (_) {
    // Best-effort — if this also fails, the caller's normal error mapping
    // takes over on its next attempt.
  }
  return true;
}
