import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/catalog/data/catalog_api.dart';
import 'package:quizoo/features/catalog/data/catalog_repository.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';
import 'package:quizoo/features/catalog/presentation/bloc/level_map_cubit.dart';
import 'package:quizoo/features/catalog/presentation/widgets/level_brief_sheet.dart';
import 'package:quizoo/features/catalog/presentation/widgets/serpentine_path.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-08 — a topic's twenty escalating levels.
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({
    required this.categoryId,
    required this.subcategoryId,
    super.key,
    this.initialBriefLevelNumber,
  });

  final String categoryId;
  final String subcategoryId;

  /// Opens S-09's brief sheet as soon as the map has loaded.
  ///
  /// This is what makes `/…/levels/12/brief` a real destination rather than a
  /// reserved path: the sheet is a sheet, so it is presented over the map it
  /// belongs to instead of becoming a screen of its own.
  final int? initialBriefLevelNumber;

  @override
  Widget build(BuildContext context) {
    final locale = context.read<ContentLanguageCubit>().state.code;
    return BlocProvider<LevelMapCubit>(
      create: (_) =>
          LevelMapCubit(
            CatalogRepository(
              CatalogApi(supabase, context.read<LadderConfigRepository>()),
            ),
          )..load(
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            locale: locale,
          ),
      child: _LevelMapView(initialBriefLevelNumber: initialBriefLevelNumber),
    );
  }
}

class _LevelMapView extends StatelessWidget {
  const _LevelMapView({this.initialBriefLevelNumber});

  final int? initialBriefLevelNumber;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: BlocBuilder<LevelMapCubit, LevelMapState>(
          builder: (context, state) => switch (state) {
            LevelMapInitial() || LevelMapLoading() => const _LevelMapSkeleton(),
            LevelMapError(:final error) => _LevelMapError(
              errorCode: error.code,
            ),
            LevelMapEmpty(:final map) => _LevelMapEmpty(map: map),
            LevelMapLoaded(:final map) => _LevelMapLoaded(
              map: map,
              initialBriefLevelNumber: initialBriefLevelNumber,
            ),
          },
        ),
      ),
    );
  }
}

class _LevelMapLoaded extends StatefulWidget {
  const _LevelMapLoaded({required this.map, this.initialBriefLevelNumber});

  final LevelMap map;
  final int? initialBriefLevelNumber;

  @override
  State<_LevelMapLoaded> createState() => _LevelMapLoadedState();
}

class _LevelMapLoadedState extends State<_LevelMapLoaded> {
  final GlobalKey _currentNodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // "Opens scrolled so the current node sits at 45% height." Done after the
    // first frame, because until then the path has no geometry to scroll to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealCurrentNode();
      final number = widget.initialBriefLevelNumber;
      if (number != null && mounted) {
        _openBrief(context, _levelNumbered(number));
      }
    });
  }

  Level _levelNumbered(int number) => widget.map.levels.firstWhere(
    (level) => level.number == number,
    orElse: () => widget.map.currentLevel,
  );

  void _revealCurrentNode() {
    final nodeContext = _currentNodeKey.currentContext;
    if (nodeContext == null || !mounted) return;
    Scrollable.ensureVisible(
      nodeContext,
      alignment: 0.45,
      duration: Duration.zero,
    );
  }

  Future<void> _openBrief(BuildContext context, Level level) async {
    final started = await LevelBriefSheet.show(
      context,
      map: widget.map,
      level: level,
      repository: context.read<QuizPlayRepository>(),
    );
    if (!started || !context.mounted) return;
    context.push(AppRoutes.countdownPath(level.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final map = widget.map;
    final current = map.currentLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LevelMapTopBar(map: map),
        _SubcategoryHeaderCard(map: map),
        Expanded(
          child: SingleChildScrollView(
            child: SerpentinePath(
              levels: map.levels,
              currentNodeKey: _currentNodeKey,
              onLevelTap: (level) => _openBrief(context, level),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.md.h,
            AppSpacing.screenMargin.w,
            AppSpacing.sm.h + 2.h,
          ),
          child: ChunkyButton(
            label: l10n.levelMapPlayLevel(current.number),
            subLabel: l10n.levelMapPlaySub(
              difficultyLabel(l10n, current.difficultyBand),
              current.questionCount,
              current.secondsPerQuestion,
            ),
            onPressed: () => _openBrief(context, current),
          ),
        ),
      ],
    );
  }
}

/// `.tb` — back, topic name, parent category.
class _LevelMapTopBar extends StatelessWidget {
  const _LevelMapTopBar({required this.map});

  final LevelMap map;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.xs.h,
        AppSpacing.screenMargin.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.commonBack,
            child: GestureDetector(
              onTap: context.pop,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: HomeIconButton.size.w,
                height: HomeIconButton.size.w,
                child: Center(
                  child: Text(
                    '←',
                    style: AppTypography.glyph(20.sp, color: quizoo.tx2),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  map.subcategory.name,
                  style: textTheme.titleLarge!.copyWith(fontSize: 19.sp),
                ),
                Text(
                  map.category.name,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: quizoo.tx3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The header stat card: icon plate, progress bar, then best score / stars /
/// rank.
class _SubcategoryHeaderCard extends StatelessWidget {
  const _SubcategoryHeaderCard({required this.map});

  final LevelMap map;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final subcategory = map.subcategory;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 13.w,
          vertical: AppSpacing.md.h,
        ),
        decoration: BoxDecoration(
          color: quizoo.s1,
          border: Border.all(color: quizoo.ln),
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          boxShadow: quizoo.shadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppGradients.tileFromHex(
                      map.category.colorFrom,
                      map.category.colorTo,
                    ),
                    borderRadius: BorderRadius.circular(19.r),
                    boxShadow: [
                      BoxShadow(
                        color: quizoo.pShadow,
                        offset: Offset(0, AppElevation.ledge.h),
                      ),
                    ],
                  ),
                  child: Text(
                    subcategory.emoji,
                    style: AppTypography.glyph(29.sp),
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subcategory.name,
                        style: textTheme.titleMedium!.copyWith(
                          fontSize: 16.5.sp,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        l10n.levelMapSubtitle(
                          subcategory.questionCount,
                          subcategory.levelCount,
                        ),
                        style: textTheme.labelSmall!.copyWith(fontSize: 11.sp),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Row(
                        children: [
                          Expanded(
                            child: _ProgressBar(value: subcategory.progress),
                          ),
                          SizedBox(width: AppSpacing.sm.w),
                          Text(
                            '${subcategory.levelsCleared}/'
                            '${subcategory.levelCount}',
                            style: textTheme.labelSmall!.copyWith(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
              child: Divider(color: quizoo.ln, height: 1, thickness: 1),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  _HeaderStat(
                    value: AppFormat.number(subcategory.bestScore, localeName),
                    label: l10n.levelMapBestScore,
                  ),
                  _StatDivider(color: quizoo.ln),
                  _HeaderStat(
                    value: '${subcategory.starsEarned}',
                    suffix: '/${map.starsAvailable}',
                    label: l10n.levelMapStars,
                  ),
                  _StatDivider(color: quizoo.ln),
                  _HeaderStat(
                    value: map.rank == 0 ? '—' : '#${map.rank}',
                    label: l10n.levelMapRank,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.bar.thin.ok` — the mint progress track.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill.r),
      child: SizedBox(
        height: 6.h,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: quizoo.s3)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [quizoo.ok, quizoo.ok.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label, this.suffix});

  final String value;
  final String? suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: value,
              children: [
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: textTheme.displayMedium!.copyWith(
                      fontSize: 11.sp,
                      color: quizoo.tx3,
                    ),
                  ),
              ],
            ),
            style: textTheme.displayMedium!.copyWith(fontSize: 17.sp),
          ),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 1, child: ColoredBox(color: color));
}

class _LevelMapSkeleton extends StatelessWidget {
  const _LevelMapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.base.h),
          SkeletonBox(width: 140.w, height: 24.h),
          SizedBox(height: AppSpacing.base.h),
          SkeletonBox(
            height: 150.h,
            borderRadius: BorderRadius.circular(AppRadius.card.r),
          ),
          SizedBox(height: AppSpacing.xl.h),
          for (var node = 0; node < 3; node++) ...[
            Align(
              alignment: node.isEven
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: SkeletonBox(
                width: 62.w,
                height: 62.w,
                borderRadius: BorderRadius.circular(AppRadius.node.r),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
          ],
        ],
      ),
    );
  }
}

/// S-47 — a real topic with no levels built behind it yet.
class _LevelMapEmpty extends StatelessWidget {
  const _LevelMapEmpty({required this.map});

  final LevelMap map;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _LevelMapTopBar(map: map),
        Expanded(
          child: Center(
            child: EmptyStateView(
              emoji: '🚧',
              title: l10n.searchEmptyTitle,
              message: l10n.contentErrorBody,
              action: ChunkyButton.ghost(
                label: l10n.commonBack,
                onPressed: context.pop,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// S-48 — the topic could not be loaded.
class _LevelMapError extends StatelessWidget {
  const _LevelMapError({required this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: l10n.contentErrorBody,
        errorCode: errorCode,
        action: ChunkyButton.ghost(
          label: l10n.commonBack,
          onPressed: context.pop,
        ),
      ),
    );
  }
}
