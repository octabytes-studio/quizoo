// Plan 023: the client-triggered sync. verify_jwt = true
// (supabase/config.toml) — the gateway rejects calls without a valid user
// JWT. The server then re-checks RevenueCat itself (plan Assumption 10)
// and returns the public profiles.is_pro flag.

import { createSupabaseAdmin, syncCustomer } from "../_shared/revenuecat.ts";

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

  try {
    await syncCustomer(admin, user.id, new Date().toISOString());
  } catch (e) {
    console.error("syncCustomer failed", e);
    return new Response("Sync failed", { status: 500 });
  }

  const { data, error } = await admin
    .from("profiles")
    .select("is_pro")
    .eq("id", user.id)
    .maybeSingle();
  if (error) {
    console.error("profiles read failed", error);
    return new Response("Database error", { status: 500 });
  }

  return Response.json({ isPro: !!data?.is_pro });
});
