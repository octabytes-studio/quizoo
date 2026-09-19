import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/empty_state_view.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/home/data/home_api.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/presentation/bloc/search_cubit.dart';
import 'package:quizoo/features/home/presentation/widgets/home_top_bar.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-06 — search over the cached taxonomy.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => SearchCubit(
        HomeRepository(HomeApi(supabase)),
        languageCode: context.read<ContentLanguageCubit>().state.code,
      )..loadTrending(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();

  /// Focus is the textbook local UI state `setState` exists for — the grape
  /// border is a purely visual response with no business meaning
  /// (CLAUDE.md §3).
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_isFocused == _focusNode.hasFocus) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    context.read<SearchCubit>().searchNow(query);
  }

  void _openTopic(Subcategory subcategory) => context.push(
    AppRoutes.levelMapPath(subcategory.categoryId, subcategory.id),
  );

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
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
                            style: AppTypography.glyph(
                              20.sp,
                              color: quizoo.tx2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Container(
                      height: 42.h,
                      padding: EdgeInsets.symmetric(horizontal: 13.w),
                      decoration: BoxDecoration(
                        color: quizoo.s1,
                        borderRadius: BorderRadius.circular(
                          AppRadius.buttonSmall.r,
                        ),
                        border: Border.all(
                          color: _isFocused ? quizoo.g : quizoo.ln,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text('🔍', style: AppTypography.glyph(14.sp)),
                          SizedBox(width: AppSpacing.sm.w),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: context
                                  .read<SearchCubit>()
                                  .queryChanged,
                              cursorColor: quizoo.g,
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: quizoo.tx,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: l10n.searchHint,
                                hintStyle: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: quizoo.tx3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) => switch (state) {
                  SearchInitial() => _TrendingCloud(state: state),
                  SearchSearching() => const _SearchSkeleton(),
                  SearchFailure() => _SearchError(state: state),
                  SearchSuccess(isEmpty: true) => _SearchEmpty(state: state),
                  SearchSuccess() => _SearchResults(
                    state: state,
                    onTopicTap: _openTopic,
                    onTrendingTap: _runSearch,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.state,
    required this.onTopicTap,
    required this.onTrendingTap,
  });

  final SearchSuccess state;
  final ValueChanged<Subcategory> onTopicTap;
  final ValueChanged<String> onTrendingTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.xl.h),
      children: [
        _MetaLabel(text: l10n.searchResultCount(state.results.length)),
        SizedBox(height: AppSpacing.md.h),
        for (final result in state.results)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin.w,
              0,
              AppSpacing.screenMargin.w,
              9.h,
            ),
            child: ListRowTile(
              title: result.subcategory.name,
              subtitle: l10n.searchBreadcrumb(
                result.categoryName,
                result.subcategory.groupName.isEmpty
                    ? result.subcategory.name
                    : result.subcategory.groupName,
                result.subcategory.questionCount,
              ),
              leadingEmoji: result.subcategory.emoji,
              leadingPlateColor: AppGradients.hex(
                result.subcategory.plateColor,
              ),
              onTap: () => onTopicTap(result.subcategory),
              trailing: Text(
                l10n.searchPlay,
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: quizoo.p,
                ),
              ),
            ),
          ),
        SizedBox(height: 22.h - 9.h),
        _TrendingChips(trending: state.trending, onTap: onTrendingTap),
      ],
    );
  }
}

/// The chip cloud shown before anything is typed.
class _TrendingCloud extends StatelessWidget {
  const _TrendingCloud({required this.state});

  final SearchInitial state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: AppSpacing.sm.h),
      children: [
        _TrendingChips(
          trending: state.trending,
          onTap: (query) => context.read<SearchCubit>().searchNow(query),
        ),
      ],
    );
  }
}

class _TrendingChips extends StatelessWidget {
  const _TrendingChips({required this.trending, required this.onTap});

  final List<String> trending;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (trending.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchTrending,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: AppSpacing.sm.w,
            runSpacing: AppSpacing.sm.h,
            children: [
              for (final term in trending)
                GestureDetector(
                  onTap: () => onTap(term),
                  behavior: HitTestBehavior.opaque,
                  child: AppChip.status(label: term),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 80.w, height: 13.h),
          SizedBox(height: AppSpacing.md.h),
          for (var row = 0; row < 3; row++) ...[
            SkeletonBox(
              height: 66.h,
              borderRadius: BorderRadius.circular(AppRadius.listRow.r),
            ),
            SizedBox(height: 9.h),
          ],
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({required this.state});

  final SearchSuccess state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      children: [
        SizedBox(height: AppSpacing.xl.h),
        EmptyStateView(
          emoji: '🔍',
          title: l10n.searchEmptyTitle,
          message: l10n.searchEmptyBody,
        ),
        SizedBox(height: AppSpacing.xl.h),
        // Never a dead end: the trending chips stay reachable.
        _TrendingChips(
          trending: state.trending,
          onTap: (query) => context.read<SearchCubit>().searchNow(query),
        ),
      ],
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.state});

  final SearchFailure state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: l10n.contentErrorBody,
        errorCode: state.error.code,
        action: ChunkyButton(
          label: l10n.commonRetry,
          onPressed: () => context.read<SearchCubit>().searchNow(state.query),
        ),
      ),
    );
  }
}
