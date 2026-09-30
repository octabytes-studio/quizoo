import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/content_language/language_flags.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/home/presentation/bloc/home_language_tabs_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Home's pinned row of content-language pills, directly under the top bar
/// (plan 021).
///
/// Each pill is the bible's `.cat` chip ([AppChip]) — flag + native name,
/// inverted when selected. Tapping one calls
/// [ContentLanguageCubit.switchTo], which persists it as the default without
/// reordering the row. The row hides entirely when the list failed to load
/// or has fewer than two languages — there is nothing to switch between.
class HomeLanguageBar extends StatelessWidget {
  const HomeLanguageBar({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedCode = context.select(
      (ContentLanguageCubit cubit) => cubit.state.code,
    );

    return BlocBuilder<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      builder: (context, state) => switch (state) {
        HomeLanguageTabsLoading() => const _LanguageBarPadding(
          child: _LanguagePillSkeletonRow(),
        ),
        HomeLanguageTabsError() => const SizedBox.shrink(),
        HomeLanguageTabsLoaded(:final languages) when languages.length < 2 =>
          const SizedBox.shrink(),
        HomeLanguageTabsLoaded(:final languages) => _LanguageBarPadding(
          child: _LanguagePillRow(
            languages: languages,
            selectedCode: selectedCode,
          ),
        ),
      },
    );
  }
}

/// The gap before the body — applied inside the visible branches only, so
/// a hidden row collapses to nothing.
class _LanguageBarPadding extends StatelessWidget {
  const _LanguageBarPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.md.h),
    child: child,
  );
}

class _LanguagePillRow extends StatelessWidget {
  const _LanguagePillRow({required this.languages, required this.selectedCode});

  final List<LanguageOption> languages;
  final String selectedCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: AppChip.categoryHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
        itemCount: languages.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm.w),
        itemBuilder: (context, index) {
          final language = languages[index];
          return AppChip(
            label: language.nativeName,
            leading: languageFlags[language.code] ?? '🌐',
            isSelected: language.code == selectedCode,
            semanticLabel: l10n.homeLanguageTabSemantics(language.name),
            onTap: () =>
                context.read<ContentLanguageCubit>().switchTo(language.code),
          );
        },
      ),
    );
  }
}

class _LanguagePillSkeletonRow extends StatelessWidget {
  const _LanguagePillSkeletonRow();

  static const List<double> _skeletonPillWidths = [96, 84, 104];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppChip.categoryHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
        itemCount: _skeletonPillWidths.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm.w),
        itemBuilder: (context, index) => SkeletonBox(
          width: _skeletonPillWidths[index].w,
          height: AppChip.categoryHeight.h,
          borderRadius: AppRadius.pillAll,
        ),
      ),
    );
  }
}
