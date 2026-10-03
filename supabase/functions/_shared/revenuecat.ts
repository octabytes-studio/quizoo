// Plan 023: the single bridge between RevenueCat and the quizoo_pro
// entitlement mirror. Both Edge Functions (revenuecat-webhook,
// sync-pro-status) call syncCustomer; the server always fetches the
// customer's real state from RevenueCat's REST API itself — the client
// only ever asks, never tells (plan Assumption 10).

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/// RevenueCat anonymous ids ($RCAnonymousID:…) are not Quizoo accounts.
export function isQuizooUserId(id: string): boolean {
  return UUID_RE.test(id);
}

export function createSupabaseAdmin(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY is not set");
  }
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function planFromProductId(productId: string | null): string | null {
  if (!productId) return null;
  if (productId.includes("monthly")) return "monthly";
  if (productId.includes("yearly")) return "yearly";
  if (productId.includes("lifetime")) return "lifetime";
  return null;
}

export async function syncCustomer(
  admin: SupabaseClient,
  appUserId: string,
  eventAt: string,
): Promise<void> {
  // RevenueCat anonymous ids ($RCAnonymousID:…) are not Quizoo accounts.
  if (!isQuizooUserId(appUserId)) return;

  const secret = Deno.env.get("REVENUECAT_SECRET_KEY");
  if (!secret) {
    // Fail closed: without the secret no status is ever applied.
    throw new Error("REVENUECAT_SECRET_KEY is not set");
  }

  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    {
      headers: {
        Authorization: `Bearer ${secret}`,
        Accept: "application/json",
      },
    },
  );
  if (!res.ok) {
    throw new Error(
      `RevenueCat subscriber fetch failed: ${res.status} ${await res.text()}`,
    );
  }
  const info = await res.json();
  // The v1 envelope is { request_date, subscriber: {...} }; entitlements,
  // subscriptions and non_subscriptions all live one level down.
  const subscriber = info?.subscriber ?? info;

  const entitlement = subscriber?.entitlements?.quizoo_pro;
  const expiresDate: string | null = entitlement?.expires_date ?? null;
  const isActive = !!entitlement &&
    (expiresDate == null || new Date(expiresDate).getTime() > Date.now());

  const productId: string | null = entitlement?.product_identifier ?? null;
  const plan = planFromProductId(productId);

  // Match the entitlement's product against the subscriber's subscriptions
  // (auto-renewing) and non_subscriptions (one-time) to recover store,
  // period type, sandbox flag and cancellation/billing-issue timestamps.
  const candidates: { productId: string; entry: Record<string, unknown> }[] =
    [];
  for (const [pid, entry] of Object.entries(subscriber?.subscriptions ?? {})) {
    candidates.push({ productId: pid, entry: entry as Record<string, unknown> });
  }
  for (const [pid, entries] of Object.entries(subscriber?.non_subscriptions ?? {})) {
    for (const entry of entries as Record<string, unknown>[]) {
      candidates.push({ productId: pid, entry });
    }
  }
  const match = candidates.find((c) => c.productId === productId) ??
    candidates[0] ??
    null;

  const { error } = await admin.rpc("_apply_pro_status", {
    p_user_id: appUserId,
    p_is_active: isActive,
    p_plan: plan,
    p_store: (match?.store as string) ?? null,
    p_product_id: productId,
    p_period_type: (match?.period_type as string) ?? null,
    p_expires_at: expiresDate,
    p_will_renew: isActive &&
      (plan === "monthly" || plan === "yearly") &&
      match?.unsubscribe_detected_at == null,
    p_billing_issue_at: (match?.billing_issues_detected_at as string) ?? null,
    p_environment: match?.is_sandbox ? "SANDBOX" : "PRODUCTION",
    p_event_at: eventAt,
  });
  if (error) {
    throw new Error(`_apply_pro_status failed: ${error.message}`);
  }
}
