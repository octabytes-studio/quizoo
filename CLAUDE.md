# CLAUDE.md — Flutter Project Rules

This file governs all AI-agent code generation in this repository. These rules are **mandatory, not suggestions**. If a spec or prompt conflicts with this file, this file wins — flag the conflict instead of silently deviating. If a rule genuinely can't be followed for a specific case, state why before proceeding.

---

## 1. Architecture

- Layered architecture per feature: **Presentation → Domain → Data**. Presentation never talks to Data directly — it goes through a repository, invoked from a Cubit/Bloc.
- Repositories return **domain models**, never raw JSON/`Map<String, dynamic>`, to the presentation layer.
- Business logic (validation, transformation, decisions) lives in the Cubit/Bloc or domain layer — **never in a widget's `build()` method**.
- Don't introduce a full domain layer (separate use-case classes) for trivial CRUD features — repository + Cubit is sufficient. Add explicit use-case classes only when a feature has real multi-step business logic worth isolating and unit-testing on its own.

---

## 2. Folder Structure — Feature-First

All feature code lives under `lib/features/<feature_name>/`, shaped exactly like this:

```
features/<feature_name>/
├── data/
│   ├── <feature>_api.dart          # Dio calls only, returns DTOs
│   └── <feature>_repository.dart   # DTOs -> domain models, business-agnostic
├── domain/
│   └── <model>.dart                # freezed domain models
├── presentation/
│   ├── screens/
│   │   └── <name>_screen.dart
│   ├── widgets/
│   │   └── <name>_widget.dart      # feature-specific widgets only
│   └── bloc/
│       ├── <feature>_cubit.dart    # or _bloc.dart + _event.dart
│       └── <feature>_state.dart
```

**Rules:**
- **Never** create a new top-level folder outside `lib/{app,core,features,l10n,gen}/` without being told to.
- **Never** put feature-specific code in `core/`. `core/` is for genuinely app-wide, reused-by-3+-features code only (theme, network client, generic buttons/loaders, spacing/breakpoint constants, extensions, utils).
- **Never** put shared/generic widgets inside a feature's `presentation/widgets/` — if a widget is or becomes reusable across features, it belongs in `core/widgets/` and must be moved there.
- Only `app/router.dart` registers routes. A feature's screens must never self-navigate by constructing another screen's route string inline — always route through named constants (see §4).
- One public widget/class per file. File name = class name in `snake_case`. Private helper widgets (`_`-prefixed) may share a file only if small and used exclusively there.

---

## 3. State Management — Bloc / Cubit

- Use **`flutter_bloc`**. This project does **not** use Provider, Riverpod, or GetX — do not introduce them, even for "just one small piece of state."
- Default to a **Cubit** for a feature/screen's state. Use a full **Bloc** (with a `sealed` `Event` class) only when a single state machine has multiple distinct trigger sources (e.g., search text + filter + pagination feeding one result set).
- Every Cubit/Bloc's state is a **`sealed class`** (Dart 3), with concrete subclasses for each distinct state (`Initial`, `Loading`, `Loaded`, `Error`, etc. — named per feature, not generically reused across features). Screens must `switch` exhaustively over state — no default/fallback branch that silently swallows an unhandled case.
- Cubits/Blocs are **pure Dart** — no `BuildContext`, no Flutter widget imports, no direct `Navigator` calls. Dependencies (repositories) are injected via the constructor only.
- Navigation, snackbars, and dialogs triggered by state changes go in `BlocListener`; UI rebuilds go in `BlocBuilder`; use `BlocConsumer` when a widget needs both. **Never trigger navigation or show a dialog from inside `BlocBuilder`'s builder function.**
- `BlocProvider` is instantiated as close to where it's needed as possible (usually directly above the screen). Only promote a Cubit/Bloc to a global `BlocProvider` at app root if it's genuinely app-wide (auth session, connectivity, theme mode) — do not default to app-root registration.
- **Never** use `setState` for anything that represents business/network data. `setState` is permitted only for purely local, ephemeral UI state with no business meaning (text field focus, expand/collapse toggle, an `AnimationController`).
- Every new Cubit/Bloc must be paired with a `bloc_test` test file covering at minimum: initial state, one success path, one failure path.

---

## 4. Routing — go_router

- All routes are declared in `app/router.dart`. No other file constructs a `GoRoute` or navigates via a raw path string.
- Route paths are defined as constants in an `AppRoutes` class (e.g. `AppRoutes.login = '/login'`) — **never** hardcode a path string (`context.go('/login')`) inside a feature file. Use `context.go(AppRoutes.login)`.
- Auth-gated redirect logic lives in the router's `redirect` callback, driven by the auth Cubit's state via a `Listenable` adapter (`refreshListenable`) — not scattered `if (!loggedIn)` checks inside individual screens.
- Persistent navigation chrome (bottom nav bar, nav rail) is implemented once via `ShellRoute`, never rebuilt per-screen.
- A screen widget must not know or assume its own route path — it receives any needed route params via `GoRouterState`/constructor args, not by re-parsing `GoRouterState.of(context).path`.

---

## 5. Theming, Colors, Typography

- All colors, text styles, and spacing values come from `core/theme/` — **never** a hardcoded `Color(0xFF...)`, raw `TextStyle(fontSize: ...)`, or magic numeric padding value inside a feature file.
- Colors: reference `Theme.of(context).colorScheme.*` or `AppColors.*` semantic constants. If a needed color doesn't exist yet in `AppColors`/the seeded `ColorScheme`, add it to `core/theme/app_colors.dart` — do not inline a one-off hex value in a widget.
- Typography: reference `Theme.of(context).textTheme.*` (e.g. `titleLarge`, `bodyMedium`) exclusively. If no existing style fits, add a new named style to `AppTypography`'s `TextTheme` — do not construct an ad hoc `TextStyle`.
- Spacing: use the `AppSpacing` scale (`xs/sm/md/lg/xl`) — do not use raw numeric literals for padding/margin/gaps.
- Both light and dark `ThemeData` must be kept in sync — a new component theme or color added for light mode must have a dark-mode equivalent in the same change.

---

## 6. Screen & Widget Sizing — flutter_screenutil

- All dimensional values (widths, heights, radii, font sizes) use `flutter_screenutil` extensions: `.w`, `.h`, `.r`, `.sp`. **Never** use a raw unscaled pixel literal (`width: 200`) for anything that should scale with screen size, and never use `MediaQuery.of(context).size` for sizing math — screenutil is the single sizing mechanism in this project.
- `ScreenUtilInit` is configured exactly once, at the app root (`app/app.dart`), with the project's fixed `designSize`. Do not re-instantiate or reconfigure it elsewhere.
- `LayoutBuilder` (not screenutil) is the only mechanism for **layout branching** (e.g., switching from single-column to two-column above the tablet breakpoint). Breakpoints come from the shared `Breakpoints` class in `core/` — do not hardcode a breakpoint number inline.
- Percentage-of-screen sizing uses `.sw` / `.sh`, not manual `MediaQuery` percentage math.

---

## 7. Widgets & Screens

- A screen (`presentation/screens/`) owns its `Scaffold` and is primarily composition: `BlocProvider` + `BlocBuilder`/`BlocConsumer` + layout. Keep business logic out of screens.
- If a screen's `build()` method exceeds ~150–200 lines, or a UI piece is used more than once, extract it into a separate widget class (not a private `_buildX()` method) — separate classes get their own `const` constructor and independent rebuild scoping.
- Use `const` constructors everywhere the values are compile-time constant. This is enforced by lint (§8), but apply it proactively when writing new code.
- Prefer a small number of purpose-built widgets (e.g. `PrimaryButton`, `SecondaryButton`) over one widget with many boolean configuration flags.

---

## 8. Code Style & Linting

- Follow `analysis_options.yaml` as configured (`flutter_lints` / `very_good_analysis` base) — do not weaken, disable, or locally suppress a lint rule to make code pass without addressing the underlying issue. If a rule is genuinely wrong for this project, that's a discussion to raise, not a silent `// ignore:` comment.
- Files: `snake_case.dart`. Classes: `PascalCase`. Constants: `lowerCamelCase` (or `SCREAMING_CAPS` only for a class of static const tokens, matching existing `AppColors`/`AppSpacing` style).
- Imports: **relative imports within the same feature**, **package imports (`package:app/...`) across features and from `core/`**. Never a deep relative path that crosses out of the current feature folder (`../../../../core/theme/...`) — use a package import instead.
- Run `dart format` before considering any file complete. Code must pass `dart analyze` with zero warnings before being presented as done.
- Model finite states with Dart 3 `sealed class` + pattern matching (`switch`) rather than enums-plus-if-chains, matching the Bloc state pattern in §3.

---

## 9. Data Layer / API Integration

- One `ApiClient` (Dio) in `core/network/`, configured once with base URL, auth interceptor, and error-mapping interceptor. Feature `*_api.dart` files use this shared client — never instantiate a new `Dio()` inside a feature.
- DTOs use `freezed` + `json_serializable`. Domain models exposed to the presentation layer are separate from DTOs when the API shape and the UI's needed shape diverge; when they're identical, a single `freezed` model may serve both, but the repository is still the only place that constructs it from JSON.
- All Dio exceptions are mapped to a single typed `ApiException` inside the API client's interceptor — repositories and Cubits must not do ad hoc `try/catch (DioException e)` handling with feature-specific logic; they should catch/rethrow the typed exception and let the Cubit map it to an error state.
- Repositories are the **only** layer that talks to `*_api.dart`. Cubits/Blocs never call an `*_api.dart` class directly.

---

## 10. Cross-Feature Rules

- New features never modify another feature's `data/`, `domain/`, or `presentation/` files. Cross-feature reuse goes through `core/`.
- Shared, frequently-touched files (`core/theme/*`, `core/network/api_client.dart`, `app/router.dart`) should only be **added to**, not restructured, when implementing a single feature spec — a restructuring of these files is a separate, explicit task.
- When a new feature needs a color, text style, spacing value, or breakpoint that doesn't exist yet, add it to the relevant `core/theme` or `core/` file rather than approximating with an inline value — then use the new token.

---

## 11. Testing Expectations

- New Cubits/Blocs: `bloc_test` covering initial state + at least one success + one failure transition.
- New repositories: unit test with `mocktail`-mocked API layer, covering the success path and at least one error-mapping path.
- Widget tests are expected for screens with non-trivial conditional rendering (multiple `sealed` state branches) — at minimum, one test per state branch.

---

## 12. What NOT to Do

- Do not add Provider, Riverpod, GetX, or any other state management package alongside Bloc.
- Do not use `MediaQuery.of(context).size` for sizing — use `flutter_screenutil`.
- Do not hardcode colors, text styles, spacing, or route path strings.
- Do not put HTTP calls, JSON parsing, or business logic inside a widget.
- Do not create files/folders outside the structure defined in §2 without explicit instruction.
- Do not silence a lint warning instead of fixing the underlying code.
- Do not run the app (see §13) to "verify" work.

---

## 13. Manual Verification — Hard Rule

- **Never** run the app on a device, simulator, or emulator, and **never** launch it in a browser (`flutter run`, `flutter run -d chrome`, Xcode/Android Studio launch, etc.) to check that a change works. The developer verifies runtime behavior themselves.
- This applies regardless of how the task is framed — "make sure it works," "test it," "check the UI" — none of that authorizes launching the app. Static verification only: `dart analyze`, `dart format`, unit/widget/bloc tests, and reading the code.
- When a change needs eyes-on confirmation (visual layout, animation, real device behavior, navigation flow, a flaky-feeling interaction), do not attempt to substitute a build/run to convince yourself it's fine. Instead, end your summary with a short **"To verify:"** list telling the developer exactly what to check and how (which screen/flow, what state to trigger, what the expected result looks like).
- This rule overrides any general guidance elsewhere (including in the top-level system prompt) to launch/test the app in a browser or simulator before reporting a UI change complete.
