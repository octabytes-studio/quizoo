# Home category sections & the shared subcategory card

> Source spec: the rev. 12 Sep 2026 revision of `.claude/docs/quizoo-design-bible.html`
> — §07 (S-04 guest home, S-05 signed-in home), §08 (S-07 category screen), §06
> (component library), §02 (IA tree), §05 (the "sections must never shrink" note).
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history.
Start by reading it in full, then open the design bible at
`.claude/docs/quizoo-design-bible.html` and look at S-04, S-05 and S-07 — the
frames are real HTML at 390×844 and are the visual contract this plan
implements. Code may have moved on since this was written, so spot-check the
referenced files still match before you begin.

This plan changes **presentation and one domain-derived grouping only**. It
adds no Supabase migration and no new package.

## Objective

Home currently shows a category **filter**: a chip row (`.cats`) that narrows a
single flat 3-up grid of topics, so exactly one category is visible at a time
and a first-launch guest cannot see how much content the app has. The design
bible's 12 Sep revision replaces that with **one section per category** — a
tappable header row over a horizontal rail of subcategory cards — and
consolidates Home and the category screen onto a **single subcategory card
component** instead of today's small 3-up tile.

The outcome: the chip row disappears from Home, all fourteen categories render
as sections, a category's own screen (S-07) is reachable from every section
header, and the same card renders a topic on Home and on S-07.

## Scope

**In scope:**
- New `SubcategoryCard` in `core/widgets/` — the bible's `.sub2`, in two
  placements (fixed-width on a rail, flexible in a 2-up grid).
- New `CategorySectionHeader` in `core/widgets/` — the bible's `.catline`,
  including the See-all pill and its > 10 topics rule.
- Home (S-04/S-05): remove the chip row and the flat grid; render one section
  per category; keep the existing daily banner, Continue row and popular rail
  and their order.
- `HomeContent`: a derived category→topics grouping, with section ordering.
- `HomeCubit`/`HomeLoaded`: remove the now-dead category filter.
- S-07 category screen: 2-up `SubcategoryCard` grid, header stat chips, and a
  "pick up where you left" resume card.
- New l10n keys in both `app_en.arb` and `app_ur.arb`.
- Tests per CLAUDE.md §11 for everything above.

**Out of scope:**
- Any Supabase schema change or migration.
- The category leaderboard rank chip on S-07's header — see open question 4.
- Reconciling the design bible's 20-level ladder text (§19/§21) with the
  implemented 50-level ladder. The screens in this plan print no level total,
  so they are correct either way; the doc reconciliation is its own task.
- The search screen (S-06), which keeps its own filtering behaviour.
- `CategoryTile` itself — it stays in `core/widgets/` and keeps its current
  callers outside this plan's two screens.

## Research findings

Everything below was read directly, not inferred.

**Governance.** `CLAUDE.md` at the repo root is mandatory and wins over any
spec. The rules that bind this work hardest:
- §2 — feature-first folders; **shared widgets belong in `core/widgets/`**, never
  in a feature's `presentation/widgets/`. Both new widgets here are used by
  `features/home` and `features/catalog`, so `core/widgets/` is required, not a
  preference.
- §3 — `flutter_bloc` only; state is a `sealed class`; screens `switch`
  exhaustively with no default branch; Cubits are pure Dart with no
  `BuildContext`.
- §4 — routes only via `AppRoutes` constants; never a raw path string.
- §5 — no hardcoded `Color(0xFF…)`, no ad-hoc `TextStyle`, no magic padding.
  Use `context.quizoo` / `Theme.of(context).textTheme.*` / `AppSpacing.*`.
  A new token must be added to `core/theme/` and used from there.
- §6 — every dimension through `flutter_screenutil` (`.w/.h/.r/.sp`). No raw
  pixel literals, no `MediaQuery.of(context).size` for sizing.
- §7 — extract a widget class (not a `_buildX()` method) once a `build()`
  passes ~150–200 lines.
- §10 — a single feature's change **adds to** `core/theme/*` and
  `app/router.dart`; it does not restructure them.
- §11 — new Cubit ⇒ `bloc_test` (initial + success + failure); screens with
  several `sealed` branches ⇒ a widget test per branch.

**The stack.** Flutter with `flutter_bloc`, `freezed` + `json_serializable`,
`go_router`, `flutter_screenutil`, `supabase_flutter`, `mocktail` +
`bloc_test` for tests (`pubspec.yaml`). No new dependency is needed.

**Home as it stands** — `lib/features/home/presentation/screens/home_screen.dart`
(574 lines). `HomeScreen` → `BlocProvider<HomeCubit>` keyed on
`(isSignedIn, languageCode)` → `_HomeView` → a `switch` over `HomeState` into
four private widgets: `_HomeSkeleton`, `_HomeError`, `_HomeOfflineView`,
`_HomeContentView`. The pieces this plan replaces all live in
`_HomeContentView`'s `ListView` (lines ~276–339):
- `_PopularRail` (line 355) — **copy this pattern exactly** for the new
  category rails: a `SizedBox(height: …)` wrapping a horizontal
  `ListView.separated` with `padding: EdgeInsets.symmetric(horizontal:
  AppSpacing.screenMargin.w)` and a `SizedBox(width: AppSpacing.md.w)`
  separator. The fixed outer height is what makes a horizontal list inside a
  vertical list legal.
- `_CategoryChips` (line 400) — **delete**.
- `_SubcategoryGrid` (line 439) — **delete**; its `caption:` switch over
  `Subcategory` is the state logic the new card inherits.
- The `SectionHeader(title: l10n.homeCategories, actionLabel:
  l10n.homeAllCategories(...))` block at line 317 — **delete**, including its
  `onActionPressed` that pushes `AppRoutes.categoryDetailPath(...)`. That link
  is the only current route into S-07 and is replaced by the section headers.

**State** — `lib/features/home/presentation/bloc/home_cubit.dart` +
`home_state.dart`. `HomeLoaded` carries `content`, `selectedCategoryId` and
`isPopularRailLoading`, plus a `visibleSubcategories` getter.
`HomeCubit.selectCategory` and the private `_selectedCategoryId` field exist
solely for the chip row. `HomeCubit.load` is deliberately two-stage (cached
paint, then the popular rail) — **do not disturb that**; the sections come from
the cached leg and must paint in the first frame.

**Domain** — `lib/features/home/domain/home_content.dart`. `HomeContent` holds
flat `List<Category> categories` and `List<Subcategory> subcategories` plus a
`subcategoriesIn(String? categoryId)` helper. Home already fetches **every**
category and **every** subcategory for the active content language in one pass
(`HomeApi.fetchCachedHome`), so the grouping this plan needs is a pure
in-memory regroup — no extra query.

**Models** — `lib/core/models/subcategory.dart` carries `name, emoji,
plateColor, questionCount, levelsCleared, levelCount (default 50), bestScore,
starsEarned, isNew, isLocked` and a `progress` getter (`levelsCleared /
levelCount`). Everything the new card renders is already on the model.
`lib/core/models/category.dart` carries `subcategoryCount` — populated in
`HomeApi._categoryFromRow` from `row['subcategory_count'] as int? ?? 0`, i.e.
**it silently defaults to 0 if that column isn't maintained**. See open
question 2.

**Widgets to mirror** — `lib/core/widgets/category_tile.dart` is the closest
analog and the pattern to follow for the new card: a `Container` with
`quizoo.s1` / `AppRadius.tile.r` / `Border.all(color: quizoo.ln)` /
`quizoo.shadow`, an emoji plate built with `AppTypography.glyph(27.sp)`, a
`LinearProgressIndicator` clipped to 4.h with `quizoo.s3` track and `quizoo.ok`
fill, an `isLocked` scrim at `quizoo.s1.withValues(alpha: 0.74)`, and a
`Semantics(button: true, label: '$name, $caption')` wrapper around a
`GestureDetector`. `lib/core/widgets/section_header.dart` shows the
`.sec-t` header pattern the new `.catline` header sits alongside.

**S-07 as it stands** — `lib/features/catalog/presentation/screens/category_detail_screen.dart`
(335 lines). `_CategoryHeader` already does the full-bleed gradient with
`AnnotatedRegion<SystemUiOverlayStyle>` (light icons, transparent status bar),
`AppGradients.tileFromHex(category.colorFrom, category.colorTo)`, an
`MediaQuery.paddingOf(context).top + 6.h` top inset, a `PositionedDirectional`
watermark emoji at `opacity: 0.85`, and the `l10n.categoryMeta(topics,
questions, players)` line. `_CategoryLoaded` renders a 3-up `CategoryTile`
grid with `mainAxisExtent: 140.h`. Domain is
`lib/features/catalog/domain/category_detail.dart` — `CategoryDetail(category,
topics, playerCount)` plus an unused `TopicSort` enum.

**Theme tokens available** — `core/theme/`: `app_colors.dart`,
`quizoo_colors.dart` (the `context.quizoo` extension: `s0/s1/s2/s3`, `tx/tx2/
tx3`, `ln`, `g`, `p`, `ok`, `gold`, `info`, `shadow`), `app_spacing.dart`
(`xs 4 / sm 8 / md 12 / base 16 / lg 20 / xl 24 / xxl 32`, `screenMargin = 20`
documented as invariant), `app_radius.dart` (`tile 18`, `card 20`,
`emojiPlate`, `pill 999`), `app_gradients.dart` (`hex()`, `tileFromHex()`),
`app_typography.dart` (`glyph()` for emoji).

**l10n** — `lib/l10n/app_en.arb` + `app_ur.arb`, generated via `l10n.yaml` into
`AppLocalizations`. Existing keys this work reuses or retires:
`homeLevelProgress` ("Lv {cleared}/{total}"), `homeNew` ("New"),
`homeLocked` ("Locked"), `homeLevelsAvailable` ("{count} levels"),
`homeSeeAll` ("See all"), `homeCategories`, `homeAllCategories` ("All
{count}"), `homeFilterAll` ("✨ All"), `categoryTopics`, `categoryMeta`,
`categorySortPopular`.

**Tests** — `test/` mirrors `lib/`. `test/features/home/home_cubit_test.dart`
covers `HomeCubit` including its `selectCategory` behaviour (**this plan
breaks those cases — update them**). `test/core/widgets/core_widgets_test.dart`
is where the two new widgets' tests belong.
`test/features/home/home_screen_test.dart` carries a long header comment
explaining that its loaded-content assertions are already skipped, because
`HomeScreen` constructs a real `HomeApi(supabase)` inline and the test harness
has no injectable client — so full-screen assertions on real content are not
available here, and that coverage belongs at the Cubit level. Do not try to
revive them as part of this plan.
`test/support/pump_screen.dart` is the shared harness.

**Existing plans** — `.claude/plans/001`–`008`. 008
(`content-language-selection-and-filtering`) is the most recent and is why
`HomeScreen`'s `BlocProvider` is keyed on the content language; keep that key
intact. No existing plan covers the home layout, so there is no conflict.

## Assumptions & open questions

1. **Section ordering.** The bible says "state-driven: daily → continue →
   popular → your most-played category → the rest", but the app stores no
   "most played" figure. *Assumption:* promote the category owning
   `content.continueEntry.subcategoryId` to first, and order everything else by
   `Category.order`. This is derivable today and matches the visible intent.
   If a real play-count lands later, it replaces only the comparator.
2. **The > 10 topic count.** The bible says the backend computes a
   `show_see_all` flag and "the client never counts". `Category.subcategoryCount`
   exists but defaults to `0` when `categories.subcategory_count` is absent, and
   Home already holds every subcategory in memory anyway. *Assumption:* derive
   the count from the grouped topic list, falling back to
   `Category.subcategoryCount` only if the group is empty. **Verify against the
   live schema whether `subcategory_count` is actually maintained** — if it is,
   prefer it and treat the derived count as the fallback instead.
3. **No category currently exceeds ten topics.** Per the bible's own §21
   taxonomy the largest category has eight, so on today's content the See-all
   pill never renders and the section header is the only route to S-07. Build
   both paths anyway; the threshold is a named constant so it is one edit to
   change. Do not "fix" this by lowering the threshold without asking.
4. **S-07's rank chip.** The header's stat chips are stars / levels / rank.
   Stars and levels are derivable from the topics already on `CategoryDetail`;
   **rank is not** — it would need a category-leaderboard read. *Open:* either
   add that read to `CatalogApi` or ship two chips. This plan ships two chips
   and leaves the third to a follow-up, rather than inventing a number.
5. **S-07's resume card.** Needs "the topic in this category the player is
   currently on". There is no `last_played_at` on `level_progress`. *Assumption:*
   the topic with the highest `levelsCleared` among those with
   `levelsCleared > 0`, ties broken by `Category.order`/list order. If the
   backend gains a timestamp, swap the comparator only. When no topic in the
   category has been started, the card is **absent**, never an empty shell.
6. **The offline grid (S-46).** `_HomeOfflineView` renders its "Available
   offline" topics through `CategoryTile`. It is migrated to `SubcategoryCard`
   in this plan for consistency, but it is the one step that can be dropped
   without affecting the spec if it causes trouble.

## Design overview

Two new shared widgets, one derived grouping, and the deletion of the filter.

```
core/widgets/
  subcategory_card.dart        NEW  .sub2 — one card, two placements
  category_section_header.dart NEW  .catline + the See-all pill

features/home/
  domain/home_content.dart          + HomeCategorySection, + sections getter
  presentation/bloc/home_state.dart − selectedCategoryId, − visibleSubcategories
  presentation/bloc/home_cubit.dart − selectCategory, − _selectedCategoryId
  presentation/screens/home_screen.dart
                                    − _CategoryChips, − _SubcategoryGrid
                                    + _CategorySection (header + rail)

features/catalog/
  domain/category_detail.dart       + starsEarned/levelsCleared/resumeTopic
  data/catalog_api.dart             + populate those from existing queries
  presentation/screens/category_detail_screen.dart
                                    2-up SubcategoryCard grid, stat chips,
                                    resume card
```

`SubcategoryCard` is the load-bearing piece. It renders, top to bottom: a 38px
emoji plate beside the topic name, a 4px progress bar, and a state line whose
left half is the progress text and right half the stars. Its three content
states come straight from the model and mirror the `caption:` switch being
deleted from `_SubcategoryGrid`:

| Model state | Left | Right | Bar |
|---|---|---|---|
| `isLocked` | `homeLocked` | — | hidden, lock scrim over the card |
| `levelsCleared == 0` | `homeQuestionCount(questionCount)` | `homeNew` | 0% |
| `levelsCleared == levelCount` | `homeComplete` | ⭐⭐⭐ | 100% |
| otherwise | `homeLevelShort(levelsCleared)` | earned stars | `progress` |

**The card must have a deterministic height.** A rail is a horizontal list
inside a vertical list, so it needs a fixed outer height (the
`_PopularRail`/`PopularQuizCard.height` pattern), and a card whose name wraps
to two lines would otherwise overflow it. Give the name `maxLines: 2` in a
fixed-height box so every card is the same height whether the name wraps or
not, and expose that height as `SubcategoryCard.railHeight`.

This is the Flutter form of the bible's §05 note, added in the same revision:
a screen's sections must never be squashed to fit the viewport. Home's body is
already a `ListView`, which is correct — keep it that way. Do **not** convert
it to a `Column` inside an `Expanded`, which distributes a fixed height among
its children and clips their contents.

## Implementation steps

### Phase 1 — the two shared widgets

- [ ] Create `lib/core/widgets/subcategory_card.dart` with a single public
      `SubcategoryCard`. Constructor: `name, emoji, plateColor, progress,
      statusLabel, trailingLabel, isStarred, width, onTap, isLocked`. Statics:
      `railWidth = 164`, `railHeight` (set to whatever the fixed internal stack
      measures — verify on device, expect ~112), `plateSize = 38`.
      A null `width` means "fill the parent", which is how the 2-up grid uses
      it. Follow `category_tile.dart` for the container decoration, the emoji
      plate, the clipped `LinearProgressIndicator`, the lock scrim and the
      `Semantics`/`GestureDetector` wrapper. Every dimension via `.w/.h/.r/.sp`;
      every colour via `context.quizoo`.
- [ ] Add a `SubcategoryCard.seeAll(...)` named constructor (or a private
      `_SeeAllCard` in the same file — CLAUDE.md §2 permits a private helper
      sharing a file): the dashed `.sub2.more` end-cap, `quizoo.s2` fill, a
      `＋` plate and a "See all · N topics" label. Same `railWidth`/`railHeight`.
- [ ] Create `lib/core/widgets/category_section_header.dart` with
      `CategorySectionHeader`. Constructor: `name, emoji, plateColor,
      topicCount, showSeeAll, onTap`. Renders a 30px medallion, the name in
      `textTheme.titleMedium`, and on the trailing edge either the plain
      `homeTopicCount` count or the See-all pill. **The whole row is the tap
      target** — one `GestureDetector`/`InkWell` around the row, not just the
      pill, wrapped in `Semantics(button: true)`. Keep the horizontal padding
      at `AppSpacing.screenMargin.w` so it lines up with `SectionHeader`.
- [ ] Add the threshold as a named constant on `CategorySectionHeader`:
      `static const int seeAllThreshold = 10;` with a doc comment citing the
      bible. Do not inline `10` at a call site.
- [ ] Add any missing token to `core/theme/` rather than inlining it (§5/§10) —
      in particular check whether a dashed-border colour and the 30px medallion
      radius already have homes in `app_radius.dart`/`quizoo_colors.dart`.

### Phase 2 — Home

- [ ] In `lib/features/home/domain/home_content.dart`, add a small
      `HomeCategorySection` (`Category category, List<Subcategory> topics`) and
      a `List<HomeCategorySection> get sections` on `HomeContent` that groups
      `subcategories` by `categoryId`, orders per assumption 1, and drops
      categories with no topics. Keep `subcategoriesIn` — search may still use
      it; delete it only if a repo-wide search shows no remaining caller.
- [ ] In `home_state.dart`, delete `selectedCategoryId`, `visibleSubcategories`
      and the `selectedCategoryId` line from `copyWith`/`props`.
- [ ] In `home_cubit.dart`, delete `selectCategory` and `_selectedCategoryId`,
      and remove the `selectedCategoryId:` arguments from the two `HomeLoaded`
      emissions in `load`. **Leave the two-stage load otherwise untouched.**
- [ ] In `home_screen.dart`, delete `_CategoryChips` and `_SubcategoryGrid`
      entirely, plus the `SectionHeader(title: l10n.homeCategories …)` block and
      its `onActionPressed`.
- [ ] Add a private `_CategorySection` widget to `home_screen.dart`
      (feature-specific composition, so it stays here per §2): a
      `CategorySectionHeader` + `SizedBox(height: AppSpacing.md.h)` + a rail
      built exactly like `_PopularRail` — `SizedBox(height:
      SubcategoryCard.railHeight.h)` wrapping a horizontal `ListView.separated`
      with `screenMargin` padding and `AppSpacing.md.w` separators. Append the
      See-all end-cap card as a final item only when
      `topics.length > CategorySectionHeader.seeAllThreshold`.
- [ ] In `_HomeContentView`, replace the deleted blocks with the section list.
      Convert the outer `ListView(children: [...])` to a `ListView.builder`
      over a prebuilt list of slivers/widgets, or keep `ListView` but build the
      sections with a spread — **prefer the builder**, since fourteen sections
      each holding a horizontal list is the performance risk called out below.
      Separate sections with the hairline divider (`quizoo.ln`) the bible draws
      between them.
- [ ] Keep the existing order above the sections: daily banner (or
      `SaveProgressCard` for a guest) → Continue → popular rail → sections.
- [ ] Point each section header's `onTap` at
      `context.push(AppRoutes.categoryDetailPath(category.id))` (§4 — the
      constant, never a literal).
- [ ] Update `_HomeSkeleton` so its placeholder shapes match the new layout: a
      header-sized box plus a `SubcategoryCard.railHeight` box per section
      stub, instead of the current 96.h grid block.
- [ ] Migrate `_HomeOfflineView`'s "Available offline" grid from `CategoryTile`
      to a 2-up `SubcategoryCard` grid (see assumption 6).

### Phase 3 — S-07 category screen

- [ ] In `lib/features/catalog/domain/category_detail.dart`, add
      `starsEarned`, `levelsCleared` and `Subcategory? resumeTopic` to
      `CategoryDetail` (all defaulted, so existing construction sites keep
      compiling). Regenerate freezed.
- [ ] In `lib/features/catalog/data/catalog_api.dart`, populate those three
      from the data the category query already returns — the per-topic
      `levelsCleared`/`starsEarned` sum, and `resumeTopic` per assumption 5.
      Repository still maps to domain models only (§9).
- [ ] In `category_detail_screen.dart`, replace the 3-up `CategoryTile`
      `GridView` with a 2-up `SubcategoryCard` grid: `crossAxisCount: 2`,
      `crossAxisSpacing`/`mainAxisSpacing` `AppSpacing.md`, and a fixed
      `mainAxisExtent` matching the card's own height rather than an aspect
      ratio (the existing comment at line 117 explains why this project prefers
      a fixed extent — keep that reasoning).
- [ ] Extend `_CategoryHeader` with the stat chip row beneath the meta line:
      stars and levels, using the existing `AppChip`/`.chipf` styling on a
      translucent white fill. Leave room for the rank chip (open question 4).
      Keep the `AnnotatedRegion` and the watermark emoji as they are.
- [ ] Add a `_ResumeCard` private widget above the sort segment, rendered only
      when `detail.resumeTopic != null`, routing to
      `AppRoutes.levelMapPath(topic.categoryId, topic.id)`.

### Phase 4 — strings, format, tests

- [ ] Add to `lib/l10n/app_en.arb` **and** `lib/l10n/app_ur.arb`:
      `homeTopicCount` ("{count} topics"), `homeSeeAllCount` ("See all
      {count}"), `homeQuestionCount` ("{count} questions"), `homeLevelShort`
      ("Lv {level}"), `homeComplete` ("Complete"), plus a semantics label for
      the section header row. Give every placeholder its `type`/`example`
      block, matching the existing entries.
- [ ] Delete `homeFilterAll`, `homeCategories` and `homeAllCategories` from both
      `.arb` files **only after** confirming no remaining caller.
- [ ] Regenerate localizations and check `untranslated_messages.json` is not
      growing.
- [ ] Update `test/features/home/home_cubit_test.dart`: remove the
      `selectCategory` cases, keep initial/success/failure, and add a case
      asserting `sections` groups and orders correctly (including the
      continue-entry promotion and the drop-empty-category rule).
- [ ] Add `SubcategoryCard` and `CategorySectionHeader` cases to
      `test/core/widgets/core_widgets_test.dart`: one per card content state
      from the table above, the locked scrim, the See-all pill appearing at 11
      topics and absent at 10, and the whole header row being tappable.
- [ ] Update `test/features/catalog/catalog_cubit_test.dart` for the three new
      `CategoryDetail` fields, including the "no started topic ⇒ null
      resumeTopic" case.
- [ ] `dart format .` and `dart analyze` must be clean (§8) before this is
      considered done.

## Data model / API changes

No Supabase migration. Domain-only:
- `HomeCategorySection` — new, presentation-facing grouping in
  `features/home/domain/home_content.dart`.
- `CategoryDetail` — three added fields (`starsEarned`, `levelsCleared`,
  `resumeTopic`), all defaulted, populated in `CatalogApi` from queries that
  already run.

## Dependencies

N/A — no new package.

## Testing strategy

Matches CLAUDE.md §11 and the existing suite layout:
- **Cubit** (`bloc_test`, `mocktail`-mocked repository): `HomeCubit` keeps its
  initial/success/failure coverage; add grouping and ordering cases for
  `HomeContent.sections`, which is pure and can also be unit-tested directly
  with no Cubit at all.
- **Widgets**: `core_widgets_test.dart` gains one test per `SubcategoryCard`
  content state plus the threshold behaviour on `CategorySectionHeader`.
- **Screen**: do not attempt new loaded-content assertions in
  `home_screen_test.dart` — read its header comment first; the harness cannot
  inject a fake `HomeApi`. Keep it to the first-frame and error-branch tests it
  already has.
- **Repository**: `CatalogRepository`'s new field mapping gets a success case
  and one error-mapping case with a `mocktail`-mocked `CatalogApi`.

## Edge cases & error handling

- A category with zero topics is dropped from Home entirely, not rendered as an
  empty rail.
- A category with exactly 10 topics shows the plain count; 11 shows the pill
  **and** the end-cap. Assert both boundaries.
- A long topic name wraps to two lines and must not change the card's height —
  this is what keeps a rail's fixed height honest.
- A locked topic renders the scrim and does not navigate (`if (topic.isLocked)
  return;`, as both screens already do).
- Guest vs signed-in: a guest's topics are all `levelsCleared == 0`, so every
  card shows the questions/New state and a 0% bar. The bar is still drawn, so
  the card height matches a started one.
- RTL (S-43): rails must mirror. Use `EdgeInsetsDirectional` and
  `PositionedDirectional`, and let the `›` affordance follow text direction —
  do not hardcode a left/right chevron.
- The popular rail's existing failure behaviour is unchanged: losing it must
  not take Home down. The sections come from the cached leg, so they render
  even when the rail fetch fails.

## Acceptance criteria

- [ ] No chip row on Home; `_CategoryChips`, `_SubcategoryGrid`,
      `HomeCubit.selectCategory` and `HomeLoaded.selectedCategoryId` no longer
      exist.
- [ ] Home renders one section per non-empty category, all of them, ordered per
      assumption 1, each with a horizontal rail of `SubcategoryCard`s.
- [ ] Tapping anywhere on a section header opens that category's S-07 screen.
- [ ] A category with more than 10 topics shows the See-all pill and the rail
      end-cap; 10 or fewer shows `N topics ›` and no end-cap.
- [ ] The same `SubcategoryCard` class renders a topic on Home and on S-07 —
      no second small-tile variant for subcategories.
- [ ] Every card in a rail is the same height, including one whose name wraps.
- [ ] S-07 shows the stat chips, the resume card when a topic is in progress,
      and a 2-up card grid.
- [ ] Home still reaches a playable level in at most two taps (§01's budget):
      topic card → level map.
- [ ] Both themes and both text directions render correctly (§5's light/dark
      parity rule; S-43 for RTL).
- [ ] `dart analyze` clean, `dart format` applied, full suite green.

## Risks & rollout notes

- **Performance is the real risk.** Fourteen sections, each with its own
  horizontal `ListView`, nested inside Home's vertical list. Build the outer
  list with `ListView.builder` so off-screen sections are not built, keep each
  rail a `ListView.builder` too, and profile Home's scroll on a real
  mid-range Android per the bible's performance budget — not a simulator. If
  jank appears, the next lever is `addAutomaticKeepAlives: false` on the rails.
- **Home gets much longer.** With all fourteen categories, most of Home is
  below the fold by design. If that proves wrong in review, the alternatives
  already considered were: cap Home at ~6 ranked categories with a "browse all"
  row, or collapse never-played categories to their header. Both are layout-only
  changes on top of this plan.
- **`CategoryTile` keeps its other callers.** Do not delete it.
- **Docs to update after implementation:** none in the bible — it already
  describes this layout as of the 12 Sep revision. If assumption 1 or 5 is
  resolved differently during execution, record the outcome in the bible's
  §07 callouts so the doc and the code do not drift.
