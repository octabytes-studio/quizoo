import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/anchored_banner_ad.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/core/widgets/subcategory_card.dart';
import 'package:quizoo/features/catalog/data/catalog_api.dart';
import 'package:quizoo/features/catalog/data/catalog_repository.dart';
import 'package:quizoo/features/catalog/domain/category_detail.dart';
import 'package:quizoo/features/catalog/presentation/bloc/category_detail_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-07 — a category and its topics.
///
/// The header's colour and emoji come from the category model, never from a
/// switch on its id: the bible is explicit that "new categories ship without
/// an app update".
class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final locale = context.read<ContentLanguageCubit>().state.code;
    return BlocProvider<CategoryDetailCubit>(
      create: (_) => CategoryDetailCubit(
        CatalogRepository(
          CatalogApi(supabase, context.read<LadderConfigRepository>()),
        ),
      )..load(categoryId, locale: locale),
      child: const _CategoryDetailView(),
    );
  }
}

class _CategoryDetailView extends StatelessWidget {
  const _CategoryDetailView();

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: BlocBuilder<CategoryDetailCubit, CategoryDetailState>(
        builder: (context, state) => switch (state) {
          CategoryDetailInitial() ||
          CategoryDetailLoading() => const _CategorySkeleton(),
          CategoryDetailError(:final error) => _CategoryError(error: error),
          CategoryDetailLoaded(:final detail) => _CategoryLoaded(
            detail: detail,
          ),
        },
      ),
      // Only beside real content (plan 022, B2).
      bottomNavigationBar:
          BlocBuilder<CategoryDetailCubit, CategoryDetailState>(
            builder: (context, state) => AnchoredBannerAd(
              placement: AdPlacement.categoryDetailBanner,
              isVisible: switch (state) {
                CategoryDetailLoaded() => true,
                CategoryDetailInitial() ||
                CategoryDetailLoading() ||
                CategoryDetailError() => false,
              },
            ),
          ),
    );
  }
}

class _CategoryLoaded extends StatelessWidget {
  const _CategoryLoaded({required this.detail});

  final CategoryDetail detail;

  void _openTopic(BuildContext context, Subcategory topic) {
    if (topic.isLocked) return;
    context.push(AppRoutes.levelMapPath(topic.categoryId, topic.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryHeader(detail: detail),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              AppSpacing.base.h,
              0,
              AppSpacing.xl.h,
            ),
            children: [
              if (detail.resumeTopic case final topic?) ...[
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin.w,
                  ),
                  child: _ResumeCard(
                    topic: topic,
                    onTap: () => _openTopic(context, topic),
                  ),
                ),
                SizedBox(height: AppSpacing.base.h),
              ],
              SectionHeader(
                title: l10n.categoryTopics,
                actionLabel: l10n.categorySortPopular,
              ),
              SizedBox(height: AppSpacing.md.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin.w,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md.w,
                  mainAxisSpacing: AppSpacing.md.h,
                  // A fixed height rather than an aspect ratio — see the
                  // matching grid on Home for why.
                  mainAxisExtent: SubcategoryCard.railHeight.h,
                ),
                itemCount: detail.topics.length,
                itemBuilder: (context, index) {
                  final topic = detail.topics[index];
                  return SubcategoryCard.forTopic(
                    topic,
                    l10n,
                    onTap: () => _openTopic(context, topic),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.c` "pick up where you left" — S-07's resume card, present only when
/// [CategoryDetail.resumeTopic] is not null (plan 009, assumption 5).
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.topic, required this.onTap});

  final Subcategory topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: l10n.homeContinueTitle(topic.name, topic.levelsCleared + 1),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: AppSpacing.md.h,
          ),
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: quizoo.ln),
            boxShadow: quizoo.shadow,
          ),
          child: Row(
            children: [
              Text(topic.emoji, style: AppTypography.glyph(30.sp)),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.categoryResumeEyebrow,
                      style: textTheme.labelSmall,
                    ),
                    Text(
                      l10n.homeContinueTitle(
                        topic.name,
                        topic.levelsCleared + 1,
                      ),
                      style: textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              ChunkyButton(
                label: l10n.homeResume,
                isSmall: true,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.bleed` — the full-bleed header, which runs under the status bar.
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.detail});

  final CategoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final Category category = detail.category;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The header is a saturated fill whatever the theme, so its status-bar
      // icons are always light.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.tileFromHex(
            category.colorFrom,
            category.colorTo,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            MediaQuery.paddingOf(context).top + 6.h,
            AppSpacing.screenMargin.w,
            18.h,
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: 0,
                top: 20.h,
                child: Opacity(
                  opacity: 0.85,
                  child: Text(
                    category.emoji,
                    style: AppTypography.glyph(44.sp),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _HeaderGlyphButton(
                        glyph: '←',
                        size: 19,
                        semanticLabel: l10n.commonBack,
                        onTap: context.pop,
                      ),
                      const Spacer(),
                      _HeaderGlyphButton(
                        glyph: '⋯',
                        size: 17,
                        semanticLabel: l10n.categoryMore,
                        onTap: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    category.name,
                    style: textTheme.displayMedium!.copyWith(
                      fontSize: 26.sp,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.categoryMeta(
                      detail.topics.length,
                      AppFormat.number(category.questionCount, localeName),
                      AppFormat.compact(detail.playerCount, localeName),
                    ),
                    style: textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  // Stars and levels are derivable from the topics already on
                  // [detail]; rank needs a category-leaderboard read this
                  // phase does not add (plan 009, open question 4), so this
                  // row ships two chips and leaves room for a third.
                  Row(
                    children: [
                      _HeaderStatChip(
                        label: l10n.categoryStatsStars(detail.starsEarned),
                      ),
                      SizedBox(width: AppSpacing.xs.w + 3.w),
                      _HeaderStatChip(
                        label: l10n.categoryStatsLevels(detail.levelsCleared),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.chipf` on a translucent white fill — the header's own variant, since the
/// shared [AppChip.status] chip is s3-only and this sits on a saturated
/// gradient regardless of theme, exactly like the header text beside it.
class _HeaderStatChip extends StatelessWidget {
  const _HeaderStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeaderGlyphButton extends StatelessWidget {
  const _HeaderGlyphButton({
    required this.glyph,
    required this.size,
    required this.semanticLabel,
    required this.onTap,
  });

  final String glyph;
  final double size;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34.w,
          height: 34.w,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              glyph,
              style: AppTypography.glyph(size.sp, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 150.h, borderRadius: BorderRadius.zero),
        SizedBox(height: AppSpacing.lg.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 110.w, height: 20.h),
              SizedBox(height: AppSpacing.md.h),
              SkeletonBox(height: 200.h),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Center(
        child: ErrorStateView(
          title: l10n.contentErrorTitle,
          emoji: '🛰️',
          message: l10n.contentErrorBody,
          action: ChunkyButton.ghost(
            label: l10n.commonBack,
            onPressed: context.pop,
          ),
        ),
      ),
    );
  }
}
