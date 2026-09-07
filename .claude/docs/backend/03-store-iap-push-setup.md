# 03 — Store, IAP & push credentials

Covers the two things only Apple's and Google's own dashboards can issue:
in-app purchase products (for `features/shop`) and the APNs key Firebase
needs to actually deliver push notifications to iOS devices.

## 1. In-app purchase products

The shop sells three coin packs
(`lib/features/shop/data/shop_api.dart`'s `_shop.coinPacks`) — create a
matching **consumable** IAP product for each, in both stores, with **the
same product ID in both** so the Flutter-side catalog (Remote Config's
`coin_pack_ids`, doc 02 §3) doesn't need per-platform branching:

| Product ID | Coins | Reference price | Bonus |
|---|---|---|---|
| `quizoo_coins_small` | 500 | $0.99 | — |
| `quizoo_coins_medium` | 2,800 | $4.99 | +20% |
| `quizoo_coins_large` | 6,500 | $9.99 | +50% |

**App Store Connect** (**My Apps → Quizoo → In-App Purchases**):
1. Create your app record first if you haven't (needs a bundle ID matching
   doc 02's iOS registration, a paid Apple Developer Program membership).
2. **+ → Consumable**, one per row above. Reference name can be anything
   internal; **Product ID** must match the table exactly.
3. Add a localization (display name + description) for at least English.
4. Pricing: pick the tier closest to the reference price.
5. Products stay in "Ready to Submit" until your first app binary is
   uploaded — that's expected at this stage, not an error.

**Google Play Console** (**Your app → Monetize → Products → In-app
products**):
1. **Create product**, Product ID matching the table exactly, mark it
   **Managed product** (Play's term for consumable-capable — the app marks
   it consumed after granting coins, via `in_app_purchase`'s
   `completePurchase`).
2. Set a price; **Activate** the product.

The **freeze power-up** (`PowerUp.freeze`, gem-priced) and gem purchases
generally aren't in this table because the shop fixture
(`ShopApi._shop`) only sells coin packs in v1 — gems accumulate from
achievements/duels per the mock data, with no direct gem IAP yet. Add a gem
pack here the same way if that changes.

## 2. Receipt validation secrets

`verify-purchase` (one of the seven Edge Functions — see plan 006) needs
credentials to call each store's server-to-server verification API:

**Apple** — an **App Store Server API key**:
1. App Store Connect → **Users and Access → Integrations → App Store
   Server API** → **Generate API Key**.
2. Download the `.p8` key (once only, like the Sign-In-with-Apple key in
   doc 01 — don't lose it), note the **Key ID** and **Issuer ID**.

**Google** — a **service account** with API access:
1. [Google Play Console API access](https://play.google.com/console) →
   **Setup → API access** → **Create new service account** (this opens
   Google Cloud Console).
2. In Cloud Console, grant the service account the **Pub/Sub Editor** role
   if you also want real-time subscription notifications (optional for v1);
   at minimum it needs access to query purchase state.
3. Back in Play Console, grant that service account **Finance data** view
   access under **API access**.
4. Download its JSON key.

Store both sets of credentials as **Supabase Edge Function secrets** (not in
the Flutter app, not in git):

```bash
supabase secrets set APPLE_ISSUER_ID=... APPLE_KEY_ID=... APPLE_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"
supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON="$(cat play-service-account.json)"
```

(Exact secret names are up to whoever implements `verify-purchase` in plan
006 — this is the credential material it will need, not a fixed contract.)

## 3. APNs key for Firebase Cloud Messaging (iOS push)

Without this, FCM can register an iOS device token but can't actually
deliver a notification to it.

1. [Apple Developer → Certificates, Identifiers & Profiles → Keys](https://developer.apple.com/account/resources/authkeys/list)
   → **+** → enable **Apple Push Notifications service (APNs)** → **Continue
   → Register**.
2. Download the `.p8` key (once only).
3. Firebase console → **Project Settings → Cloud Messaging → Apple app
   configuration → APNs Authentication Key → Upload**. Provide the `.p8`
   file, its **Key ID**, and your **Team ID**.

One key covers every iOS app in your Apple Developer team — you don't need a
separate one per environment if you're running staging/prod Firebase
projects side by side (doc 01 §7 / doc 02); upload the same key to both.

## 4. What NOT to do

- Don't put any of this document's secrets in the Flutter app, in
  `pubspec.yaml`, or in a file that gets committed to git. Everything here
  is server-side-only credential material.
- Don't skip the "same product ID in both stores" convention above unless
  you have a specific reason to branch the shop catalog per platform — it's
  what keeps `features/shop`'s Flutter code store-agnostic.
