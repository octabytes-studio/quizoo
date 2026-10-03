// Plan 023: receives RevenueCat webhooks. verify_jwt = false
// (supabase/config.toml); the bearer secret below is the only
// authentication, and it is set in the RevenueCat dashboard (owner
// checklist 4). The function fails closed until that secret exists.

import {
  createSupabaseAdmin,
  isQuizooUserId,
  syncCustomer,
} from "../_shared/revenuecat.ts";

/// Event types that always leave the subscriber Pro. After one of these the
/// mirror is verified and the delivery is answered 500 until it agrees, so a
/// RevenueCat read-model lag cannot leave a paying member unbadged.
const GRANTING_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
]);

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!secret) {
    return new Response("Webhook secret not configured", { status: 500 });
  }
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !timingSafeEqual(authHeader, `Bearer ${secret}`)) {
    return new Response("Unauthorized", { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  // RevenueCat wraps every delivery as { api_version, event: {...} }; all
  // fields this handler reads live one level down. Tolerate a bare event
  // object as well, so a hand-posted payload keeps working.
  const nested = body.event;
  const event: Record<string, unknown> =
    typeof nested === "object" && nested !== null
      ? (nested as Record<string, unknown>)
      : body;

  const admin = createSupabaseAdmin();

  // Idempotency: the event id is the primary key; ignore-duplicates makes a
  // redelivered event a no-op row-wise. The sync below deliberately still
  // runs on redelivery: RevenueCat retries are the correction path when its
  // read model lagged the first delivery (see the verification below), and
  // the mirror write itself is idempotent.
  const { error } = await admin
    .from("revenuecat_events")
    .upsert(
      {
        id: event.id,
        type: event.type,
        app_user_id: event.app_user_id ?? null,
        // The whole delivery (envelope included) is kept for auditing.
        payload: body,
      },
      { ignoreDuplicates: true },
    );
  if (error) {
    console.error("revenuecat_events insert failed", error);
    return new Response("Database error", { status: 500 });
  }

  if (event.type === "TEST") {
    return new Response("OK", { status: 200 });
  }

  // Sync every id this event touches: transfers move the entitlement from
  // one id to another, and both sides' badges must update.
  const ids = new Set<string>();
  const add = (v: unknown) => {
    if (typeof v === "string" && v) ids.add(v);
  };
  add(event.app_user_id);
  add(event.original_app_user_id);
  for (const v of (event.aliases as unknown[]) ?? []) add(v);
  for (const v of (event.transferred_from as unknown[]) ?? []) add(v);
  for (const v of (event.transferred_to as unknown[]) ?? []) add(v);

  // Arrival time, not the event's own timestamp: every sync re-reads the
  // live state from RevenueCat, so the moment of application is the right
  // ordering key — and a retried delivery must be able to correct a mirror
  // written by a later client sync (or a stale first attempt), which the
  // mirror's `last_event_at` guard would otherwise reject as out of order.
  const eventAt = new Date().toISOString();

  try {
    for (const id of ids) {
      await syncCustomer(admin, id, eventAt);
    }
  } catch (e) {
    console.error("syncCustomer failed", e);
    // 500 so RevenueCat retries the event.
    return new Response("Sync failed", { status: 500 });
  }

  // A granting event must leave its primary player Pro. RevenueCat's read
  // model can trail the event by a few seconds (observed on the Test Store),
  // in which case the sync above just wrote stale state — 500 so RevenueCat
  // retries; by the retry it is consistent. A late retry of an event whose
  // expiration has already passed is not verified (it is correctly false).
  const primary = typeof event.app_user_id === "string"
    ? event.app_user_id
    : null;
  const expirationAtMs = typeof event.expiration_at_ms === "number"
    ? event.expiration_at_ms
    : null;
  const shouldBeActive =
    GRANTING_EVENT_TYPES.has(String(event.type)) &&
    (expirationAtMs === null || expirationAtMs > Date.now());
  if (primary !== null && shouldBeActive && isQuizooUserId(primary)) {
    const { data: profile, error: readError } = await admin
      .from("profiles")
      .select("is_pro")
      .eq("id", primary)
      .maybeSingle();
    if (readError) {
      console.error("profiles read failed", readError);
      return new Response("Database error", { status: 500 });
    }
    if (profile?.is_pro !== true) {
      console.warn("granting event but is_pro is still false", primary);
      return new Response("Sync not visible yet", { status: 500 });
    }
  }

  return new Response("OK", { status: 200 });
});
