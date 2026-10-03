# 03 — Store, IAP & push credentials

Covers the two things only Apple's and Google's own dashboards can issue:
in-app purchase products (for `features/shop`) and the APNs key Firebase
needs to actually deliver push notifications to iOS devices.

## 1. Quizoo Pro products (plan 023)

The old coin-pack shop is gone (plan 013 deleted it); the app's one
purchaseable product line is **Quizoo Pro**, an auto-renewing subscription
(monthly, yearly) plus a lifetime purchase, sold through **RevenueCat**.
All three unlock the single entitlement `quizoo_pro`.

| Plan | App Store product id | Play Store identifier | RevenueCat package |
|---|---|---|---|
| Monthly | `quizoo_pro_monthly` (group "Quizoo Pro") | `quizoo_pro:monthly` (subscription `quizoo_pro`, base plan `monthly`) | `$rc_monthly` |
| Yearly | `quizoo_pro_yearly` (group "Quizoo Pro") | `quizoo_pro:yearly` (base plan `yearly`) | `$rc_annual` |
| Lifetime | `quizoo_pro_lifetime` (non-consumable) | `quizoo_pro_lifetime` (one-time product) | `$rc_lifetime` |

**These identifiers are final — never rename them after release.** In the
App Store subscription group, rank yearly above monthly so upgrades and
downgrades behave correctly. Play's subscription must be
**backwards-compatible off / base-plan based** (RevenueCat SDK 10 uses
Billing Library 6+).

### RevenueCat project (already created)

| Object | Id |
|---|---|
| Project "Quizoo" | `proj66ca87d0` |
| Test Store app | `app4ae025b9bd` |
| Quizoo iOS (App Store) | `app6d4e7125fb` |
| Quizoo Android (Play Store) | `app632311ce98` |
| Entitlement `quizoo_pro` | `entl290e4fc2fe` |
| Offering `default` (current) | `ofrng2dff8fa3f7` |
| Webhook "Supabase – Quizoo Pro" | `whintgr6cac98441b` |

The three Test Store products (`proddd41ad3919` monthly,
`prod59fc6a0fca` yearly, `prod9c538a5aaa` lifetime) are development-only;
their USD prices are placeholders and are **not** the owner's real prices.

### Owner checklist — dashboard only

1. RevenueCat dashboard → **Quizoo iOS**: upload the **App Store Connect
   API key** and the **In-App Purchase key** (`.p8`, key id, issuer id).
2. RevenueCat dashboard → **Quizoo Android**: upload the **Play
   service-account JSON** (with the financial-data and order-management
   permissions RevenueCat lists), and enable Real-time Developer
   Notifications.
3. Create the six real products in both consoles with the exact ids above,
   decide the three prices and whether yearly gets a free trial (7 days is
   the common choice), and register them in RevenueCat. Fill in the App
   Store subscription group's localizations and the review screenshot —
   **the first subscription must be submitted together with an app
   version.**
4. RevenueCat dashboard → the webhook: set the **Authorization header** to
   `Bearer <random secret>`, and create a **secret API key** (v1).
5. RevenueCat → Project settings: confirm restore behaviour is **"Transfer
   to new App User ID"**.
6. Xcode: confirm the **In-App Purchase** capability on the Runner target;
   add sandbox testers in App Store Connect. Play Console: add license
   testers and publish at least an internal-testing build (products are not
   purchasable until one exists).
7. Publish **Terms of Use** and **Privacy Policy** pages and put their URLs
   in `lib/core/subscription/revenuecat_config.dart` (currently
   placeholders); add the Terms link to the App Store description (Apple
   requires it for auto-renewing subscriptions).
8. Update App Store "App Privacy" and Play "Data safety" for purchase
   history, and the store listings to mention Quizoo Pro.
9. Complete the paid-apps agreements, tax and banking in both consoles —
   products cannot be sold without them.

## 2. Edge Function secrets (plan 023)

The two Pro Edge Functions (`revenuecat-webhook`, `sync-pro-status`) fail
**closed** until these are set — a missing secret grants Pro to nobody.

```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET='<the bearer secret from checklist 4>'
supabase secrets set REVENUECAT_SECRET_KEY='<the RevenueCat v1 secret API key>'
```

Then send a test event from the RevenueCat dashboard and confirm a row
appears in `public.revenuecat_events`.

The old `verify-purchase` / `APPLE_*` / `GOOGLE_*` secrets are obsolete —
the coin-pack shop they served was deleted in plan 013. RevenueCat performs
the store verification now.

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
