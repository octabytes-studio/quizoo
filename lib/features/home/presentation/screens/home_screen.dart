import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/connectivity_cubit.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/content_language/languages_api.dart';
import 'package:quizoo/core/content_language/languages_repository.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/category_section_header.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/subcategory_card.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/home/data/home_api.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/features/home/presentation/bloc/home_cubit.dart';
import 'package:quizoo/features/home/presentation/bloc/home_language_tabs_cubit.dart';
import 'package:quizoo/features/home/presentation/widgets/continue_row.dart';
import 'package:quizoo/features/home/presentation/widgets/home_banner.dart';
import 'package:quizoo/features/home/presentation/widgets/home_content_skeleton.dart';
import 'package:quizoo/features/home/presentation/widgets/home_language_bar.dart';
import 'package:quizoo/features/home/presentation/widgets/home_popular_section.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-04 / S-05 / S-45 — Home.
///
/// One screen with two layouts, not two screens. Which one renders is decided
/// by [SessionCubit] (already provided at the app root), and the content model
/// underneath is the same either way — the guest layout simply has nothing to
/// put in the wallet, Continue and daily slots.
///
/// [HomeCubit] and [HomeLanguageTabsCubit] are scoped here rather than at the
/// root, per CLAUDE.md §3: nothing outside Home reads them.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.forceOffline = false});

  /// S-46's own reserved path forces the offline variant on for design
  /// review, independent of Settings' "Simulate offline" toggle.
  final bool forceOffline;

  @override
  Widget build(BuildContext context) {
    // The session decides what Home asks for, so the Cubit is created with it
    // already known rather than reading it mid-build.
    return BlocBuilder<SessionCubit, SessionState>(
      buildWhen: (previous, current) {
        final wasSignedIn = previous is SessionSignedIn;
        final isSignedIn = current is SessionSignedIn;
        if (wasSignedIn != isSignedIn) return true;
        // Also repaint on an in-place profile edit (Edit Profile's Save),
        // so the top bar's name/avatar reflect it immediately.
        return previous is SessionSignedIn &&
            current is SessionSignedIn &&
            previous.user != current.user;
      },
      builder: (context, session) {
        final isSignedIn = session is SessionSignedIn;
        final contentLanguage = context.read<ContentLanguageCubit>().state;
        return MultiBlocProvider(
          // Keyed on the session only: a content-language change no longer
          // recreates Home (plan 008's old key) — the long-lived HomeCubit
          // reloads through the listener below and keeps a per-language
          // cache, so the chrome stays mounted and revisits are instant
          // (plan 021).
          key: ValueKey(isSignedIn),
          providers: [
            BlocProvider<HomeCubit>(
              create: (_) => HomeCubit(HomeRepository(HomeApi(supabase)))
                ..load(
                  isSignedIn: isSignedIn,
                  languageCode: contentLanguage.code,
                ),
            ),
            BlocProvider<HomeLanguageTabsCubit>(
              create: (_) => HomeLanguageTabsCubit(
                LanguagesRepository(LanguagesApi(supabase)),
              )..load(leadCode: contentLanguage.leadCode),
            ),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<ContentLanguageCubit, ContentLanguageState>(
                listenWhen: (previous, current) =>
                    previous.code != current.code,
                listener: (context, state) => context.read<HomeCubit>().load(
                  isSignedIn: isSignedIn,
                  languageCode: state.code,
                ),
              ),
              BlocListener<ContentLanguageCubit, ContentLanguageState>(
                listenWhen: (previous, current) =>
                    previous.leadCode != current.leadCode,
                listener: (context, state) => context
                    .read<HomeLanguageTabsCubit>()
                    .pinLead(state.leadCode),
              ),
            ],
            child: _HomeView(session: session, forceOffline: forceOffline),
          ),
        );
      },
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.session, required this.forceOffline});

  final SessionState session;
  final bool forceOffline;

  void _openSearch(BuildContext context) => context.push(AppRoutes.search);

  void _openSubcategory(BuildContext context, Subcategory subcategory) {
    if (subcategory.isLocked) return;
    context.push(
      AppRoutes.levelMapPath(subcategory.categoryId, subcategory.id),
    );
  }

  /// One key per body kind, plus the language for loaded content — so a
  /// language switch cross-fades the body while the rail's own
  /// loading→loaded update within one language does not.
  static Key _bodyKey(HomeState state) => ValueKey(switch (state) {
    HomeLoaded(:final languageCode) => 'loaded-$languageCode',
    HomeInitial() || HomeLoading() => 'loading',
    HomeError() => 'error',
  });

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final isOffline =
        forceOffline || context.watch<ConnectivityCubit>().state.isOffline;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            // S-46 keeps its full-area layout with no language row: a pill
            // tap needs the network (plan 021, Scope).
            if (isOffline && state is HomeLoaded) {
              return _HomeOfflineView(state: state);
            }
            // Chrome — the top bar and the language row — renders in every
            // state, never as a skeleton (bible S-45), so the player can
            // always switch away from a failed or empty language. Only the
            // body below swaps.
            return Column(
              children: [
                _HomeTopBar(
                  session: session,
                  state: state,
                  onSearchPressed: () => _openSearch(context),
                ),
                const HomeLanguageBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.durationOf(context, AppMotion.slide),
                    child: KeyedSubtree(
                      key: _bodyKey(state),
                      child: switch (state) {
                        HomeInitial() ||
                        HomeLoading() => const HomeContentSkeleton(),
                        HomeError(:final error) => _HomeError(error: error),
                        HomeLoaded() => _HomeContentView(
                          state: state,
                          onSearchPressed: () => _openSearch(context),
                          onSubcategoryTap: (subcategory) =>
                              _openSubcategory(context, subcategory),
                        ),
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Home's top bar, hoisted out of the per-state bodies (plan 021) so it stays
/// mounted across language switches.
///
/// Shows the real streak/level from the current — or, mid-switch, the
/// previous — content. A signed-in player with no content yet (the
/// pre-first-fetch flash) sees an honest 0 streak/level (plan 019, Design
/// overview Part B); a signed-in session whose content has no currency falls
/// back to the guest-shaped bar, as before.
class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.session,
    required this.state,
    required this.onSearchPressed,
  });

  final SessionState session;
  final HomeState state;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    final content = switch (state) {
      HomeLoaded(:final content) => content,
      HomeLoading(:final previous) => previous,
      HomeError(:final previous) => previous,
      HomeInitial() => null,
    };
    final user = session.user;
    void openEditProfile() => context.push(AppRoutes.editProfile);

    if (session is SessionSignedIn && user != null) {
      if (content == null) {
        return PlayerTopBar(
          name: user.displayName,
          avatarEmoji: user.avatarEmoji,
          dayStreak: 0,
          playerLevel: 0,
          onSearchPressed: onSearchPressed,
          onAvatarTap: openEditProfile,
        );
      }
      if (content.currency != null) {
        return PlayerTopBar(
          name: user.displayName,
          avatarEmoji: user.avatarEmoji,
          dayStreak: content.dayStreak,
          playerLevel: content.playerLevel,
          onSearchPressed: onSearchPressed,
          onAvatarTap: openEditProfile,
        );
      }
    }
    return GuestTopBar(onSearchPressed: onSearchPressed);
  }
}

/// S-46 — Home offline.
///
/// Driven entirely by `ConnectivityCubit` (or [HomeScreen.forceOffline] for
/// design review) — no real `connectivity_plus` package is added (plan 004,
/// Assumption 5).
class _HomeOfflineView extends StatelessWidget {
  const _HomeOfflineView({required this.state});

  final HomeLoaded state;

  /// The fixed subset of topics flagged as "downloaded" — the two topics
  /// with real content behind them (plan 002's Assumption 4 fixture).
  static const Set<String> _downloadedSubcategoryIds = {
    MockCatalog.footballId,
    MockCatalog.solarSystemId,
  };

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final available = [
      for (final subcategory in state.content.subcategories)
        if (_downloadedSubcategoryIds.contains(subcategory.id)) subcategory,
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.base.h,
        AppSpacing.screenMargin.w,
        AppSpacing.xl.h,
      ),
      children: [
        Row(
          children: [
            Text('📡', style: AppTypography.glyph(16.sp)),
            SizedBox(width: AppSpacing.xs.w),
            Text(
              l10n.homeOfflineMode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.base.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.base.w),
          decoration: BoxDecoration(
            color: quizoo.info.withValues(alpha: 0.12),
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: quizoo.info.withValues(alpha: 0.3)),
          ),
          child: Text(
            l10n.homeOfflineWarning(available.length),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(height: 1.4),
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        SectionHeader(title: l10n.homeOfflineAvailable),
        SizedBox(height: AppSpacing.md.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md.w,
            mainAxisSpacing: AppSpacing.md.h,
            mainAxisExtent: SubcategoryCard.railHeight.h,
          ),
          itemCount: available.length,
          itemBuilder: (context, index) {
            final subcategory = available[index];
            return SubcategoryCard.forTopic(
              subcategory,
              l10n,
              onTap: () => context.push(
                AppRoutes.levelMapPath(subcategory.categoryId, subcategory.id),
              ),
            );
          },
        ),
        SizedBox(height: AppSpacing.lg.h),
        Opacity(
          opacity: 0.55,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              color: quizoo.s2,
              borderRadius: AppRadius.cardAll,
              border: Border.all(color: quizoo.ln),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeOfflineNeedsConnection,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.homeOfflineNeedsConnectionList,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The loaded body — S-04 and S-05 differ only in which rows are present and
/// in what order, which is exactly what this list expresses. The top bar and
/// language row sit above it as shared chrome (plan 021).
class _HomeContentView extends StatelessWidget {
  const _HomeContentView({
    required this.state,
    required this.onSearchPressed,
    required this.onSubcategoryTap,
  });

  final HomeLoaded state;
  final VoidCallback onSearchPressed;
  final ValueChanged<Subcategory> onSubcategoryTap;

  /// Bounds [EmptyStateView], which holds its own scroll view.
  static const double _emptyHeight = 280;

  void _openPopularQuiz(BuildContext context, PopularQuiz quiz) {
    final subcategories = state.content.subcategories;
    // Defensive only: a non-empty rail implies non-empty subcategories.
    if (subcategories.isEmpty) return;
    final categoryId = subcategories
        .firstWhere(
          (subcategory) => subcategory.id == quiz.subcategoryId,
          orElse: () => subcategories.first,
        )
        .categoryId;
    context.push(AppRoutes.levelMapPath(categoryId, quiz.subcategoryId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final content = state.content;
    final sections = content.sections;

    // Order is state-dependent (S-05): Popular is first (when it has
    // anything — plan 021), then daily banner → Continue → category
    // sections. A guest gets the informational save-progress card in the
    // banner slot instead, and has nothing in the Continue slot.
    final leading = <Widget>[
      HomePopularSection(
        popular: content.popular,
        isLoading: state.isPopularRailLoading,
        onSeeAll: onSearchPressed,
        onQuizTap: (quiz) => _openPopularQuiz(context, quiz),
      ),
      if (content.daily case final daily?)
        DailyChallengeBanner(
          daily: daily,
          remainingLabel: AppFormat.remaining(daily.remaining, localeName),
          onTap: () => context.go(AppRoutes.daily),
        )
      else
        const SaveProgressCard(),
      if (content.continueEntry case final entry?) ...[
        SizedBox(height: AppSpacing.lg.h - 2.h),
        SectionHeader(title: l10n.homeContinueHeading),
        SizedBox(height: AppSpacing.md.h),
        ContinueRow(
          entry: entry,
          onTap: () => context.push(
            AppRoutes.levelMapPath(
              _categoryIdOf(content, entry.subcategoryId),
              entry.subcategoryId,
            ),
          ),
        ),
      ],
      // A language with no categories at all — the pill row above is the
      // way out, so this is not a dead end.
      if (sections.isEmpty)
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxl.h),
          child: SizedBox(
            height: _emptyHeight.h,
            child: EmptyStateView(
              emoji: '🌱',
              title: l10n.homeLanguageEmptyTitle,
              message: l10n.homeLanguageEmptyBody,
            ),
          ),
        ),
    ];

    // A builder, not a literal children list: fourteen sections each holding
    // their own horizontal rail is Home's real performance risk, so
    // off-screen sections must not be built at all.
    return ListView.builder(
      // Each language keeps its own scroll offset; a new one starts at the top.
      key: PageStorageKey<String>('home-content-${state.languageCode}'),
      padding: EdgeInsets.only(bottom: AppSpacing.xl.h),
      itemCount: leading.length + sections.length,
      itemBuilder: (context, index) {
        if (index < leading.length) return leading[index];
        final section = sections[index - leading.length];
        return _CategorySection(
          section: section,
          isFirst: index == leading.length,
          onHeaderTap: () =>
              context.push(AppRoutes.categoryDetailPath(section.category.id)),
          onTopicTap: onSubcategoryTap,
        );
      },
    );
  }

  static String _categoryIdOf(HomeContent content, String subcategoryId) =>
      content.subcategories
          .firstWhere((subcategory) => subcategory.id == subcategoryId)
          .categoryId;
}

/// `.catline` + `.rail-h` — one category section: a tappable header over a
/// horizontal rail of the same [SubcategoryCard] S-07 uses.
///
/// [isFirst] suppresses the hairline divider the bible draws between
/// sections (`.hr`) — there is none between the popular rail and the first
/// section, only between one section and the next.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.section,
    required this.isFirst,
    required this.onHeaderTap,
    required this.onTopicTap,
  });

  final HomeCategorySection section;
  final bool isFirst;
  final VoidCallback onHeaderTap;
  final ValueChanged<Subcategory> onTopicTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final category = section.category;
    final topics = section.topics;
    final showSeeAll = topics.length > CategorySectionHeader.seeAllThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isFirst ? AppSpacing.lg.h - 2.h : AppSpacing.md.h),
        if (!isFirst) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            child: ColoredBox(
              color: quizoo.ln,
              child: SizedBox(height: 1.h),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
        ],
        CategorySectionHeader(
          name: category.name,
          emoji: category.emoji,
          plateColor: category.colorFrom,
          topicCount: topics.length,
          showSeeAll: showSeeAll,
          onTap: onHeaderTap,
        ),
        SizedBox(height: AppSpacing.md.h),
        SizedBox(
          height: SubcategoryCard.railHeight.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            itemCount: topics.length + (showSeeAll ? 1 : 0),
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
            itemBuilder: (context, index) {
              if (index == topics.length) {
                return SubcategorySeeAllCard(
                  width: SubcategoryCard.railWidth,
                  label: l10n.homeSeeAllCount(topics.length),
                  onTap: onHeaderTap,
                );
              }
              final topic = topics[index];
              return SubcategoryCard.forTopic(
                topic,
                l10n,
                width: SubcategoryCard.railWidth,
                onTap: () => onTopicTap(topic),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// S-48 — Home could not load anything for the selected language. Sits
/// under the chrome, so another language pill is also a way out (plan 021).
class _HomeError extends StatelessWidget {
  const _HomeError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.read<SessionCubit>();

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: l10n.contentErrorBody,
        action: ChunkyButton(
          label: l10n.commonRetry,
          onPressed: () {
            final contentLanguage = context.read<ContentLanguageCubit>().state;
            context.read<HomeCubit>().load(
              isSignedIn: session.state is SessionSignedIn,
              languageCode: contentLanguage.code,
            );
            final tabs = context.read<HomeLanguageTabsCubit>();
            if (tabs.state is HomeLanguageTabsError) {
              tabs.load(leadCode: contentLanguage.leadCode);
            }
          },
        ),
      ),
    );
  }
}
