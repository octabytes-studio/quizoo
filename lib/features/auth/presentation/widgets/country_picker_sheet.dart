import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-25's country picker — every ISO country from `country_picker`'s bundled
/// dataset, searchable by name, replacing the old tap-to-cycle field over
/// `MockPlayer.countries`' fixed six (plan 015). Tapping a row pops the
/// sheet with that [Country]; backing out without choosing resolves to null,
/// which the caller treats as a no-op — the same convention the avatar and
/// language pickers use.
class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({required this.selectedCode, super.key});

  final String selectedCode;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Country> _countries = CountryService().getAll();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Country> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _countries;
    return [
      for (final country in _countries)
        if (country.name.toLowerCase().contains(query)) country,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filtered;

    return AppBottomSheet(
      title: l10n.profileChooseCountry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 13.w),
            decoration: BoxDecoration(
              color: quizoo.s2,
              borderRadius: BorderRadius.circular(AppRadius.buttonSmall.r),
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
                    controller: _search,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    cursorColor: quizoo.g,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: quizoo.tx,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: l10n.profileCountrySearchHint,
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
          SizedBox(height: AppSpacing.md.h),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl.h),
                    child: Center(
                      child: Text(
                        l10n.profileCountryNoResults,
                        style: textTheme.bodyMedium!.copyWith(
                          color: quizoo.tx3,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final country = filtered[index];
                      final isSelected =
                          country.countryCode == widget.selectedCode;
                      return ListRowTile(
                        title: country.name,
                        leadingEmoji: country.flagEmoji,
                        accentColor: isSelected ? quizoo.g : null,
                        trailing: isSelected
                            ? Text(
                                '✓',
                                style: AppTypography.glyph(
                                  17.sp,
                                  color: quizoo.g,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
