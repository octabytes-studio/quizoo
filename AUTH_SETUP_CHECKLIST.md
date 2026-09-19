# Signup / Social Auth — Investigation & Setup Checklist

## TL;DR

The Flutter code for signup/social auth is correctly implemented and wired to
the live Supabase project (`ughycvclcheuojifgkwx`). Nothing in `lib/` is
structurally broken. What's missing is **external configuration** that lives
outside this repo — in the Supabase dashboard, Google Cloud Console, and
Apple Developer portal — none of which can be verified or fixed by editing
code. There is also **one real code bug** (§3 below) worth fixing regardless,
because it will make broken auth look like it "worked."

---

## 1. How auth actually works here (context for the checklist below)

- Every guest gets a real **anonymous** Supabase session on app launch
  (`lib/main.dart`). "Signing up" via Google/Apple/email **upgrades that
  anonymous session in place** rather than creating a new account — this is
  intentional (see `AuthApi`'s doc comment, plan 005 Assumption #4), so a
  guest's progress carries over with zero migration. There is no `signUp()`
  call anywhere, and that's by design, not an oversight.
- Google/Apple sign-in goes through Supabase's **generic browser-based OAuth**
  (`auth.signInWithOAuth`), not native vendor SDKs. No `google_sign_in` or
  `sign_in_with_apple` packages are used — this is consistent, not a missing
  dependency.
- `signInWithVendor()` only *launches the browser*; the actual sign-in
  completes out-of-process and returns via a deep link
  (`com.quizoo.play://login-callback`), which `SessionCubit` picks up through
  `authStateChanges`. Both Android (`AndroidManifest.xml` intent-filter) and
  iOS (`Info.plist` `CFBundleURLTypes`) register that scheme correctly.
- `SUPABASE_URL` / `SUPABASE_ANON_KEY` are read via `String.fromEnvironment`
  in `main.dart`, sourced from `--dart-define-from-file=dart_define.json`.
  That file exists, is gitignored, and its `SUPABASE_URL` matches the live
  project (verified via the Supabase MCP `get_project_url`). VS Code's
  `.vscode/launch.json` configs already pass `--dart-define-from-file`
  correctly.

**Given all of the above checks out in code, the most likely explanation for
"signup/social auth isn't working" is one of the dashboard/console steps in
§2 not being done yet** — these can't be verified from the repo, only from
the actual dashboards.

---

## 2. Required manual configuration (your action needed)

None of this can be done by me — I don't have dashboard/console access, and
none of it lives in a file I can edit. Supabase's MCP tools can read schema,
URLs and keys, but not auth-provider enablement, so this must be checked
directly in the dashboard.

### 2.1 Supabase Dashboard — Authentication → Providers

Go to `https://supabase.com/dashboard/project/ughycvclcheuojifgkwx/auth/providers`.

- [ ] **Email** — enabled.
- [ ] **Anonymous sign-ins** — enabled (Authentication → Settings → "Enable
      anonymous sign-ins"). If this is off, the app never gets past its very
      first launch — `main.dart`'s `signInAnonymously()` call at startup will
      fail immediately, and *everything* downstream (including social login)
      will look broken.
- [ ] **Google** — enabled, with a **Client ID** and **Client Secret** pasted
      in (see §2.2 for how to get these — this is very likely the missing
      piece if social sign-in specifically doesn't work).
- [ ] **Apple** — enabled, with **Team ID**, **Key ID**, **Services ID**, and
      the `.p8` key contents pasted in (see §2.3).

### 2.2 Supabase Dashboard — Authentication → URL Configuration

- [ ] Under **Redirect URLs**, add exactly:
      ```
      com.quizoo.play://login-callback
      ```
      If this isn't in the allowlist, Google/Apple will complete the OAuth
      flow on their side and then **fail silently to hand control back to
      the app** — the browser just sits there or shows an error page, and
      nothing happens in Flutter. This is one of the most common causes of
      "the browser opens but I never get signed in."

### 2.3 Google Cloud Console — OAuth client setup

Go to [console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
(same project as Firebase, or a dedicated one).

- [ ] Create an OAuth 2.0 Client ID of type **Web application**, with an
      **Authorized redirect URI** of:
      ```
      https://ughycvclcheuojifgkwx.supabase.co/auth/v1/callback
      ```
      This Web client's **ID + secret** are what go into the Supabase
      dashboard's Google provider settings in §2.1 — Supabase itself talks
      to Google via this Web client, regardless of platform.
- [ ] Create a separate **Android** OAuth client ID. This needs your app's
      SHA-1 signing fingerprint:
      ```bash
      cd android && ./gradlew signingReport
      ```
      Use the **debug** SHA-1 for local testing, and register a **release**
      SHA-1 client separately before shipping (different keystore = different
      fingerprint = a new client entry, not a swap).
- [ ] Create a separate **iOS** OAuth client ID using the app's bundle ID.
- [ ] Confirm the app's package name in these clients matches
      `android/app/build.gradle.kts`'s `applicationId` and the iOS bundle ID
      in Xcode — a mismatch here causes Google to reject the flow with an
      opaque `redirect_uri_mismatch`-style error.

### 2.4 Apple Developer — Sign In with Apple setup

Requires a paid Apple Developer account ($99/yr).
[developer.apple.com/account](https://developer.apple.com/account)

- [ ] **Certificates, Identifiers & Profiles → Identifiers** — open the app's
      App ID and enable the **"Sign In with Apple"** capability.
- [ ] **Identifiers → Services IDs** — register a new Services ID (this is
      what represents the "web" side of Sign In with Apple to Supabase).
      Under its configuration, add the domain
      `ughycvclcheuojifgkwx.supabase.co` and the return URL
      `https://ughycvclcheuojifgkwx.supabase.co/auth/v1/callback`.
- [ ] **Keys** — create a new key with "Sign In with Apple" enabled, download
      the `.p8` file (**you can only download it once** — save it somewhere
      durable immediately).
- [ ] Paste the **Team ID**, the key's **Key ID**, the **Services ID**, and
      the `.p8` file's contents into Supabase's Apple provider settings
      (§2.1).
- [ ] In Xcode, add the **"Sign in with Apple"** capability to the Runner
      target (Signing & Capabilities tab) — without this entitlement, Apple's
      native picker/consent screen won't appear even if the backend config
      above is correct.

### 2.5 Double-check the run/build command actually passes credentials

`SUPABASE_URL`/`SUPABASE_ANON_KEY` silently become **empty strings** if the
app is launched without `--dart-define-from-file=dart_define.json` (or the
equivalent `--dart-define=...` flags) — this breaks *all* auth, not just
social. This is fine when running via the VS Code launch configs already in
`.vscode/launch.json`, but will bite if:
- Running `flutter run` bare from a terminal.
- Building a release APK/IPA or a CI job that doesn't reference
  `dart_define.json` (or a per-flavor equivalent).

`main.dart` already prints diagnostics for exactly this on startup
(`[diag] SUPABASE_URL="..."`, `[diag] SUPABASE_ANON_KEY len=...`) — someone
was apparently already chasing this exact issue. **Check the debug console
output first**: if `SUPABASE_URL` prints empty, that's the whole problem and
none of §2.1–2.4 matter until the run command is fixed.

---

## 3. Code bug found — false "success" feedback on social sign-in

`lib/features/auth/presentation/widgets/save_progress_sheet.dart:70-78`:

```dart
await session.signInWithVendor(provider);
if (!context.mounted) return;
context.pop();
AppSnackbar.show(
  context,
  title: l10n.saveProgressSaved,
  intent: SnackbarIntent.success,
  emoji: '✅',
);
```

`SessionCubit.signInWithVendor()` (`session_cubit.dart:72-79`) only resolves
once the OAuth **browser has been launched** — not once sign-in actually
completes (that arrives later, asynchronously, via a deep link handled in
`_onAuthStateChange`). So this code shows a "Progress saved ✅" toast and
closes the sheet **the instant the browser opens**, regardless of whether the
user ever completes, cancels, or fails the OAuth flow.

**Effect:** even if every dashboard/console step in §2 is done correctly,
this makes real failures look like silent successes (a snackbar says
"saved," but the player is still a guest), and it's likely *why* this reads
as "not working" — there's no positive or negative feedback tied to the
actual outcome. This should be fixed by listening for the real
`SessionSignedIn` / `SessionFailure` transition (e.g. a `BlocListener` on
`SessionCubit`) instead of firing the toast right after the `await` on
`signInWithVendor`.

I did not fix this as part of this investigation — flag if you'd like me to
patch it now.

---

## 4. Minor/stale — not blocking, but worth a note

- `save_progress_sheet.dart:30` and `AuthUser`'s doc comment still say
  *"Sign-in is mocked end to end: no token, no network, no vendor SDK."*
  This is stale — the code is fully wired to real Supabase auth now. Harmless
  but confusing for anyone reading it while debugging this exact issue.
- Supabase's security advisors (checked via MCP) flag **"Leaked Password
  Protection Disabled"** and **"Insufficient MFA Options"** on this project.
  Neither blocks basic signup/social auth from working, so they're not on
  the critical path here — but worth turning on before a public launch:
  Authentication → Providers → Email → enable leaked-password checking;
  Authentication → MFA → enable at least one factor.

---

## 5. How to verify once §2 is done

1. Run via the existing VS Code launch config (or
   `flutter run --dart-define-from-file=dart_define.json`).
2. Confirm the console shows a non-empty `[diag] SUPABASE_URL=...` and a
   `signInAnonymously SUCCEEDED` line.
3. Complete a level to trigger the S-24 save-progress sheet, tap Google or
   Apple, and complete the OAuth flow in the browser.
4. Confirm the app returns to foreground and `SessionCubit` emits
   `SessionSignedIn` (e.g. via a debugger breakpoint or by checking the
   profile screen now shows the signed-in state, once §3's toast is fixed to
   reflect the real outcome).
5. In the Supabase dashboard's **Authentication → Users** table, confirm the
   previously-anonymous user row now shows the linked Google/Apple identity
   and a real email, rather than a new/duplicate row.
