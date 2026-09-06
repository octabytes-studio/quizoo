import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/locale_cubit.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One row of S-03's list.
///
/// The live question count is the point of the row: the bible calls it "an
/// honest signal, and a reason for us to keep content parity up".
class _LanguageOption {
  const _LanguageOption({
    required this.locale,
    required this.flag,
    required this.nativeName,
    required this.englishName,
    required this.quizCount,
    required this.isLatinScript,
  });

  final Locale locale;
  final String flag;

  /// The language's name in itself — اردو, not "Urdu".
  final String nativeName;

  /// Shown as a gloss under a non-Latin native name.
  final String englishName;
  final int quizCount;

  /// A Latin-script name needs no gloss, so its row shows only the count.
  final bool isLatinScript;
}

/// S-03 — the language picker, shown once, pre-selected from device locale.
class LanguagePickerScreen extends StatefulWidget {
  const LanguagePickerScreen({required this.repository, super.key});

  final OnboardingRepository repository;

  static const List<_LanguageOption> _options = [
    _LanguageOption(
      locale: Locale('en'),
      flag: '🇬🇧',
      nativeName: 'English',
      englishName: 'English',
      quizCount: 12400,
      isLatinScript: true,
    ),
    _LanguageOption(
      locale: Locale('ur'),
      flag: '🇵🇰',
      nativeName: 'اردو',
      englishName: 'Urdu',
      quizCount: 4100,
      isLatinScript: false,
    ),
    _LanguageOption(
      locale: Locale('ar'),
      flag: '🇸🇦',
      nativeName: 'العربية',
      englishName: 'Arabic',
      quizCount: 3800,
      isLatinScript: false,
    ),
    _LanguageOption(
      locale: Locale('hi'),
      flag: '🇮🇳',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      quizCount: 5200,
      isLatinScript: false,
    ),
    _LanguageOption(
      locale: Locale('es'),
      flag: '🇪🇸',
      nativeName: 'Español',
      englishName: 'Spanish',
      quizCount: 6900,
      isLatinScript: true,
    ),
  ];

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  Locale? _selected;

  /// Pre-selects the device's language, falling back to English when the
  /// device speaks something this list does not offer.
  _LanguageOption _resolveSelected(BuildContext context) {
    final code =
        _selected?.languageCode ?? Localizations.localeOf(context).languageCode;
    return LanguagePickerScreen._options.firstWhere(
      (option) => option.locale.languageCode == code,
      orElse: () => LanguagePickerScreen._options.first,
    );
  }

  void _continue(BuildContext context, _LanguageOption option) {
    context.read<LocaleCubit>().select(option.locale);
    widget.repository
      ..markLanguageChosen()
      ..markOnboardingSeen();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final selected = _resolveSelected(context);

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
                itemCount: LanguagePickerScreen._options.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final option = LanguagePickerScreen._options[index];
                  final isSelected =
                      option.locale.languageCode ==
                      selected.locale.languageCode;
                  final count = AppFormat.number(option.quizCount, localeName);

                  return ListRowTile(
                    title: option.nativeName,
                    subtitle: option.isLatinScript
                        ? l10n.languageQuizCount(count)
                        : l10n.languageQuizCountNamed(
                            option.englishName,
                            count,
                          ),
                    leadingEmoji: option.flag,
                    accentColor: isSelected ? quizoo.g : null,
                    onTap: () => setState(() => _selected = option.locale),
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
              // implying five working languages.
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
                onPressed: () => _continue(context, selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
