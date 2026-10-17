// Plan 025 Phase 1.2: real account deletion. verify_jwt = true
// (supabase/config.toml) -- the gateway rejects calls without a valid user
// JWT, and the function then re-verifies the token itself before acting.
//
// Flow: verify the caller's JWT -> clean up the rows whose NO ACTION FKs
// would block the profiles cascade (delete_account_data, service-role-only)
// -> delete the auth user, which cascades profiles and every CASCADE child
// -> best-effort leaderboard refresh so the deleted player's matview rows
// do not linger until the 2-minute cron tick.

import { createSupabaseAdmin } from "../_shared/revenuecat.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }
  const token = authHeader.replace(/^Bearer\s+/i, "");

  const admin = createSupabaseAdmin();

  const { data: { user }, error: userError } = await admin.auth.getUser(token);
  if (userError || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const { error: cleanupError } = await admin.rpc("delete_account_data", {
    p_user_id: user.id,
  });
  if (cleanupError) {
    console.error("delete_account_data failed for", user.id, cleanupError);
    return new Response("Account cleanup failed", { status: 500 });
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    // A 404 / not-found means a previous attempt already deleted the user
    // after the client lost the response -- treat that as success.
    const status = (deleteError as { status?: number }).status;
    const message = deleteError.message ?? "";
    const alreadyDeleted = status === 404 ||
      /not\s*found/i.test(message);
    if (!alreadyDeleted) {
      console.error("auth.admin.deleteUser failed for", user.id, deleteError);
      return new Response("Account deletion failed", { status: 500 });
    }
  }

  // Best-effort: the lb_* leaderboards are materialized views and would
  // otherwise keep the deleted player visible until the 2-minute cron tick.
  // A failed refresh must not fail the deletion -- the cron is the backstop.
  try {
    const { error: refreshError } = await admin.rpc("_refresh_leaderboards");
    if (refreshError) {
      console.error("_refresh_leaderboards failed after deletion", refreshError);
    }
  } catch (e) {
    console.error("_refresh_leaderboards threw after deletion", e);
  }

  return Response.json({ deleted: true });
});
