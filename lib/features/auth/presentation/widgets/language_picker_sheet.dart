import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/content_language/language_flags.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/features/onboarding/presentation/bloc/language_picker_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-25's content-language shortcut — the same live `languages` list
/// onboarding's S-03 offers, sourced through the shared
/// `LanguagesApi`/`LanguagesRepository`/`LanguagePickerCubit` stack (plan
/// 015). Tapping a row calls [ContentLanguageCubit.select] immediately and
/// pops — there is no separate "Continue" step here, since this is one field
/// in a larger form rather than its own onboarding screen.
class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBottomSheet(
      title: l10n.languageTitle,
      child: BlocBuilder<LanguagePickerCubit, LanguagePickerState>(
        builder: (context, state) => switch (state) {
          LanguagePickerLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          LanguagePickerError() => ErrorStateView(
            title: l10n.contentErrorTitle,
            emoji: '🌐',
            message: l10n.contentErrorBody,
            action: ChunkyButton.ghost(
              label: l10n.commonRetry,
              onPressed: () => context.read<LanguagePickerCubit>().load(),
            ),
          ),
          LanguagePickerLoaded(:final languages) => _LanguageList(
            languages: languages,
          ),
        },
      ),
    );
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList({required this.languages});

  final List<LanguageOption> languages;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final selectedCode = context.watch<ContentLanguageCubit>().state.code;

    return ListView.separated(
      shrinkWrap: true,
      itemCount: languages.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final language = languages[index];
        final isSelected = language.code == selectedCode;

        return ListRowTile(
          title: language.nativeName,
          subtitle: language.name,
          leadingEmoji: languageFlags[language.code] ?? '🌐',
          accentColor: isSelected ? quizoo.g : null,
          trailing: isSelected
              ? Text('✓', style: AppTypography.glyph(17.sp, color: quizoo.g))
              : null,
          onTap: () {
            context.read<ContentLanguageCubit>().select(language.code);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
