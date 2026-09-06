import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/category_tile.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/home/data/home_api.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/features/home/presentation/bloc/home_cubit.dart';
import 'package:quizoo/features/home/presentation/widgets/continue_row.dart';
import 'package:quizoo/features/home/presentation/widgets/home_banner.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';
import 'package:quizoo/features/home/presentation/widgets/popular_quiz_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-04 / S-05 / S-45 — Home.
///
/// One screen with two layouts, not two screens. Which one renders is decided
/// by [SessionCubit] (already provided at the app root), and the content model
/// underneath is the same either way — the guest layout simply has nothing to
/// put in the wallet, Continue and daily slots.
///
/// [HomeCubit] is scoped here rather than at the root, per CLAUDE.md §3:
/// nothing outside Home reads it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The session decides what Home asks for, so the Cubit is created with it
    // already known rather than reading it mid-build.
    return BlocBuilder<SessionCubit, SessionState>(
      buildWhen: (previous, current) =>
          (previous is SessionSignedIn) != (current is SessionSignedIn),
      builder: (context, session) {
        final isSignedIn = session is SessionSignedIn;
        return BlocProvider<HomeCubit>(
          // Keyed on the session so signing in rebuilds Home against a fresh
          // Cubit rather than leaving a guest's content on screen.
          key: ValueKey(isSignedIn),
          create: (_) =>
              HomeCubit(HomeRepository(HomeApi()))
                ..load(isSignedIn: isSignedIn),
          child: _HomeView(session: session),
        );
      },
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.session});

  final SessionState session;

  void _openSearch(BuildContext context) => context.push(AppRoutes.search);

  void _openSubcategory(BuildContext context, Subcategory subcategory) {
    if (subcategory.isLocked) return;
    context.push(
      AppRoutes.levelMapPath(subcategory.categoryId, subcategory.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => switch (state) {
            HomeInitial() || HomeLoading() => const _HomeSkeleton(),
            HomeError(:final error) => _HomeError(error: error),
            HomeLoaded() => _HomeContentView(
              state: state,
              session: session,
              onSearchPressed: () => _openSearch(context),
              onSubcategoryTap: (subcategory) =>
                  _openSubcategory(context, subcategory),
            ),
          },
        ),
      ),
    );
  }
}

/// The loaded layout — S-04 and S-05 differ only in which rows are present
/// and in what order, which is exactly what this list expresses.
class _HomeContentView extends StatelessWidget {
  const _HomeContentView({
    required this.state,
    required this.session,
    required this.onSearchPressed,
    required this.onSubcategoryTap,
  });

  final HomeLoaded state;
  final SessionState session;
  final VoidCallback onSearchPressed;
  final ValueChanged<Subcategory> onSubcategoryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final content = state.content;
    final user = session.user;
    final currency = content.currency;

    return Column(
      children: [
        if (user != null && currency != null)
          PlayerTopBar(
            name: user.displayName.isEmpty ? MockPlayer.name : user.displayName,
            avatarEmoji: user.avatarEmoji,
            currency: currency,
            dayStreak: MockPlayer.dayStreak,
            playerLevel: MockPlayer.playerLevel,
            onSearchPressed: onSearchPressed,
          )
        else
          GuestTopBar(onSearchPressed: onSearchPressed),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: AppSpacing.xl.h),
            children: [
              // Order is state-dependent (S-05): daily banner → Continue →
              // Popular → Categories. A guest gets the informational
              // save-progress card in the banner slot instead.
              if (content.daily case final daily?)
                DailyChallengeBanner(
                  daily: daily,
                  remainingLabel: AppFormat.remaining(
                    daily.remaining,
                    localeName,
                  ),
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
              SizedBox(height: AppSpacing.lg.h - 2.h),
              SectionHeader(
                title: l10n.homePopularThisWeek,
                actionLabel: l10n.homeSeeAll,
                onActionPressed: onSearchPressed,
              ),
              SizedBox(height: AppSpacing.md.h),
              _PopularRail(state: state, content: content),
              SizedBox(height: AppSpacing.lg.h - 2.h),
              SectionHeader(
                title: l10n.homeCategories,
                actionLabel: l10n.homeAllCategories(content.categories.length),
                // The chips filter the grid, exactly as S-04 draws them, so
                // this link is the one affordance that opens a category's own
                // screen (S-07). Tapping a topic tile still reaches the level
                // map in a single tap, which is what keeps §01's
                // "Home → level map in at most two taps" true.
                onActionPressed: () => context.push(
                  AppRoutes.categoryDetailPath(
                    state.selectedCategoryId ?? content.categories.first.id,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              _CategoryChips(state: state),
              SizedBox(height: AppSpacing.lg.h - 2.h),
              _SubcategoryGrid(
                subcategories: state.visibleSubcategories,
                onTap: onSubcategoryTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _categoryIdOf(HomeContent content, String subcategoryId) =>
      content.subcategories
          .firstWhere((subcategory) => subcategory.id == subcategoryId)
          .categoryId;
}

/// `.rail-h` — the horizontally scrolling popular rail.
///
/// Its cards bleed past the screen's 20px margin, which is what signals
/// "scroll me" (§05).
class _PopularRail extends StatelessWidget {
  const _PopularRail({required this.state, required this.content});

  final HomeLoaded state;
  final HomeContent content;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PopularQuizCard.height.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
        itemCount: state.isPopularRailLoading ? 3 : content.popular.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
        itemBuilder: (context, index) {
          if (state.isPopularRailLoading) {
            return SkeletonBox(
              width: PopularQuizCard.width.w,
              height: PopularQuizCard.height.h,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
            );
          }
          final quiz = content.popular[index];
          return PopularQuizCard(
            quiz: quiz,
            onTap: () => context.push(
              AppRoutes.levelMapPath(
                content.subcategories
                    .firstWhere(
                      (subcategory) => subcategory.id == quiz.subcategoryId,
                      orElse: () => content.subcategories.first,
                    )
                    .categoryId,
                quiz.subcategoryId,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// `.cats` — the filter chip row.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.state});

  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<HomeCubit>();

    return SizedBox(
      height: AppChip.categoryHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
        itemCount: state.content.categories.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppChip(
              label: l10n.homeFilterAll,
              isSelected: state.selectedCategoryId == null,
              onTap: () => cubit.selectCategory(null),
            );
          }
          final category = state.content.categories[index - 1];
          return AppChip(
            label: category.name,
            leading: category.emoji,
            isSelected: state.selectedCategoryId == category.id,
            onTap: () => cubit.selectCategory(category.id),
          );
        },
      ),
    );
  }
}

/// `.tiles` — the 3-up topic grid.
class _SubcategoryGrid extends StatelessWidget {
  const _SubcategoryGrid({required this.subcategories, required this.onTap});

  final List<Subcategory> subcategories;
  final ValueChanged<Subcategory> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 11.w,
        mainAxisSpacing: 11.h,
        // A fixed height rather than an aspect ratio. The tile's content is
        // a fixed stack — 52px plate, name, caption, 4px bar — that does not
        // scale with the column's width, so tying its height to that width
        // leaves a tile carrying a progress bar a couple of pixels short.
        mainAxisExtent: 140.h,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final subcategory = subcategories[index];
        return CategoryTile(
          name: subcategory.name,
          emoji: subcategory.emoji,
          plateColor: AppGradients.hex(subcategory.plateColor),
          // A never-played topic has no bar to draw, which is the difference
          // between S-04's grid and S-07's.
          progress: subcategory.levelsCleared == 0
              ? null
              : subcategory.progress,
          caption: switch (subcategory) {
            Subcategory(isLocked: true) => l10n.homeLocked,
            Subcategory(levelsCleared: 0) =>
              subcategory.isNew
                  ? l10n.homeNew
                  : l10n.homeLevelsAvailable(subcategory.levelCount),
            _ => l10n.homeLevelProgress(
              subcategory.levelsCleared,
              subcategory.levelCount,
            ),
          },
          isLocked: subcategory.isLocked,
          onTap: () => onTap(subcategory),
        );
      },
    );
  }
}

/// S-45 — Home's skeleton, shape-matched to the loaded layout.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.base.h),
          SkeletonBox(width: 160.w, height: 26.h),
          SizedBox(height: AppSpacing.lg.h),
          SkeletonBox(height: 64.h),
          SizedBox(height: AppSpacing.xl.h),
          SkeletonBox(width: 180.w, height: 20.h),
          SizedBox(height: AppSpacing.md.h),
          SkeletonBox(height: PopularQuizCard.height.h),
          SizedBox(height: AppSpacing.xl.h),
          SkeletonBox(width: 120.w, height: 20.h),
          SizedBox(height: AppSpacing.md.h),
          SkeletonBox(height: 96.h),
        ],
      ),
    );
  }
}

/// S-48 — Home could not load anything at all.
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
          onPressed: () => context.read<HomeCubit>().load(
            isSignedIn: session.state is SessionSignedIn,
          ),
        ),
      ),
    );
  }
}
