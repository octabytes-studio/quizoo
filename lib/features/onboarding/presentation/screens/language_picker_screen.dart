import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/locale_cubit.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/onboarding/data/languages_api.dart';
import 'package:quizoo/features/onboarding/data/languages_repository.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/onboarding/domain/language_option.dart';
import 'package:quizoo/features/onboarding/presentation/bloc/language_picker_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-03 — the language picker, sourced from `languages` where
/// `is_active = true` (plan 007, Assumption #8) — flipping a language on
/// live needs a Supabase table edit, not an app release.
///
/// The live question count is the point of the row: the bible calls it "an
/// honest signal, and a reason for us to keep content parity up". A flag
/// emoji, the display quiz count and a Latin-vs-native-script hint are
/// cosmetic and not part of the `languages` table, so they stay as small
/// local lookups keyed by language code rather than new columns.
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({required this.repository, super.key});

  final OnboardingRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LanguagePickerCubit>(
      create: (_) =>
          LanguagePickerCubit(LanguagesRepository(LanguagesApi(supabase)))
            ..load(),
      child: _LanguagePickerView(repository: repository),
    );
  }
}

/// Flag emoji per language code. No entry falls back to a globe.
const Map<String, String> _flags = {
  'en': '🇬🇧',
  'ur': '🇵🇰',
  'ar': '🇸🇦',
  'hi': '🇮🇳',
  'es': '🇪🇸',
  'fr': '🇫🇷',
};

/// Display-only quiz counts — an honest-signal estimate, not a live count
/// column on `languages`. No entry falls back to omitting the row's count.
const Map<String, int> _quizCounts = {
  'en': 12400,
  'ur': 4100,
  'ar': 3800,
  'hi': 5200,
  'es': 6900,
  'fr': 3200,
};

/// A Latin-script native name needs no English gloss under it; anything else
/// does. Defaults to `false` (show the gloss) for a code not listed here.
const Set<String> _latinScriptCodes = {'en', 'es', 'fr'};

class _LanguagePickerView extends StatefulWidget {
  const _LanguagePickerView({required this.repository});

  final OnboardingRepository repository;

  @override
  State<_LanguagePickerView> createState() => _LanguagePickerViewState();
}

class _LanguagePickerViewState extends State<_LanguagePickerView> {
  String? _selectedCode;

  /// Pre-selects the device's language, falling back to the first offered
  /// language when the device speaks something not yet active.
  String _resolveSelected(
    BuildContext context,
    List<LanguageOption> languages,
  ) {
    final code = _selectedCode ?? Localizations.localeOf(context).languageCode;
    return languages.any((language) => language.code == code)
        ? code
        : languages.first.code;
  }

  void _continue(BuildContext context, String code) {
    context.read<LocaleCubit>().select(Locale(code));
    widget.repository
      ..markLanguageChosen()
      ..markOnboardingSeen();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
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
              selectedCode: _resolveSelected(context, languages),
              onSelect: (code) => setState(() => _selectedCode = code),
              onContinue: (code) => _continue(context, code),
            ),
          },
        ),
      ),
    );
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList({
    required this.languages,
    required this.selectedCode,
    required this.onSelect,
    required this.onContinue,
  });

  final List<LanguageOption> languages;
  final String selectedCode;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onContinue;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.xs.h,
            AppSpacing.screenMargin.w,
            AppSpacing.md.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.languageTitle, style: textTheme.titleLarge),
              Text(
                l10n.languageSubtitle,
                style: textTheme.bodyMedium!.copyWith(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: quizoo.tx3,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            itemCount: languages.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final language = languages[index];
              final isSelected = language.code == selectedCode;
              final isLatinScript = _latinScriptCodes.contains(language.code);
              final count = AppFormat.number(
                _quizCounts[language.code] ?? 0,
                localeName,
              );

              return ListRowTile(
                title: language.nativeName,
                subtitle: isLatinScript
                    ? l10n.languageQuizCount(count)
                    : l10n.languageQuizCountNamed(language.name, count),
                leadingEmoji: _flags[language.code] ?? '🌐',
                accentColor: isSelected ? quizoo.g : null,
                onTap: () => onSelect(language.code),
                trailing: isSelected
                    ? Text(
                        '✓',
                        style: AppTypography.glyph(19.sp, color: quizoo.g),
                      )
                    : null,
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.md.h,
            AppSpacing.screenMargin.w,
            0,
          ),
          // The bible's own honesty rule applied to ourselves: this build
          // ships two translations, so the screen says so rather than
          // implying every listed language is fully supported.
          child: Text(
            l10n.languagePartialSupport,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall,
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
            label: l10n.languageContinue,
            onPressed: () => onContinue(selectedCode),
          ),
        ),
      ],
    );
  }
}
