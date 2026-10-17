# 03 — Store, IAP & push credentials

Covers the two things only Apple's and Google's own dashboards can issue:
in-app purchase products (for `features/shop`) and the APNs key Firebase
needs to actually deliver push notifications to iOS devices.

## 1. Quizoo Pro products (plan 023)

The old coin-pack shop is gone (plan 013 deleted it); the app's one
purchaseable product line is **Quizoo Pro**, an auto-renewing subscription
(monthly, yearly) plus a lifetime purchase, sold through **RevenueCat**.
All three unlock the single entitlement `quizoo_pro`.

**Status 2026-10-17 (plan 025 verified live):** the three iOS products
exist in App Store Connect, are attached to the `quizoo_pro` entitlement
and the `default` offering's `$rc_monthly` / `$rc_annual` / `$rc_lifetime`
packages, and show `READY_TO_SUBMIT`. They are **not yet submitted** — the
first subscription must go to review together with the `1.1.0 (2)` app
version (plan 025 Phase 4.1).

| Plan | App Store product id (live) | US price | Trial | Play Store identifier | RevenueCat package |
|---|---|---|---|---|---|
| Monthly | `com.quizoo.play.monthly` | `$1.99` | 1 week free | `quizoo_pro:monthly` (subscription `quizoo_pro`, base plan `monthly`) | `$rc_monthly` |
| Yearly | `com.quizoo.play.yearly` | `$9.99` | 1 week free | `quizoo_pro:yearly` (base plan `yearly`) | `$rc_annual` |
| Lifetime | `com.quizoo.play.lifetime` | `$29.99` | — | `quizoo_pro_lifetime` (one-time, RevenueCat `prod3baa52e838` — **must be non-consumable**) | `$rc_lifetime` |

**These identifiers are final — never rename them after release.** In the
App Store subscription group, rank yearly above monthly so upgrades and
downgrades behave correctly. Play's subscription must be
**backwards-compatible off / base-plan based** (RevenueCat SDK 10 uses
Billing Library 6+).

Android note (plan 025, Phase 4.2): `prod3baa52e838`
(`quizoo_pro_lifetime`) was created as **consumable** — **fixed
2026-10-17** (now `is_consumable: false` via `update-product`), so Play
restores work. Do not change the Android store SKU.

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

### Sandbox test log

| Date | Build | Result |
|---|---|---|
| — | — | **Not yet run.** Plan 025 Phase 4.3: build with `scripts/build.sh ipa`, upload to TestFlight, purchase/restore on a physical device with a sandbox tester, and record the date and outcome here. |

### Owner checklist — dashboard only

1. ~~RevenueCat dashboard → **Quizoo iOS**: upload the **App Store Connect
   API key** and the **In-App Purchase key** (`.p8`, key id, issuer id).~~
   **Done** — RevenueCat reads live iOS product state (verified 2026-10-17).
2. ~~RevenueCat dashboard → **Quizoo Android**: upload the **Play
   service-account JSON** … and enable Real-time Developer
   Notifications.~~ **Done** — Android products exist and are readable
   (verified 2026-10-17). Remaining Android-only fix: the lifetime
   product's type — **also done 2026-10-17** (see the note above).
3. Create the six real products in both consoles with the exact ids above,
   decide the three prices and whether yearly gets a free trial (7 days is
   the common choice), and register them in RevenueCat. **Products are
   created, priced, trial-enabled and attached** (verified 2026-10-17);
   still to do:
   - attach all three products to the `1.1.0 (2)` version page under
     **In-App Purchases and Subscriptions** (the first subscription must be
     submitted with the version);
   - replace the placeholder subscription review screenshot
     (`filename: SOURCE`) with a real paywall screenshot;
   - set the display names (`Quizoo Pro Monthly`, `Quizoo Pro Yearly`,
     `Quizoo Pro Lifetime`) and rank Yearly above Monthly in the
     subscription group.
4. RevenueCat dashboard → the webhook: set the **Authorization header** to
   `Bearer <random secret>`, and create a **secret API key** (v1).
5. RevenueCat → Project settings: confirm restore behaviour is **"Transfer
   to new App User ID"**.
6. Xcode: confirm the **In-App Purchase** capability on the Runner target;
   add sandbox testers in App Store Connect. Play Console: add license
   testers and publish at least an internal-testing build (products are not
   purchasable until one exists).
7. ~~Publish **Terms of Use** and **Privacy Policy** pages and put their
   URLs in `lib/core/subscription/revenuecat_config.dart` (currently
   placeholders).~~ **Done** — the published `website/` pages are wired into
   the config (2026-10-16). Remaining: add the Terms link to the App Store
   description (Apple requires it for auto-renewing subscriptions).
8. Update App Store "App Privacy" and Play "Data safety" for purchase
   history (and, since plan 025, report/block moderation records), and the
   store listings to mention Quizoo Pro.
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
