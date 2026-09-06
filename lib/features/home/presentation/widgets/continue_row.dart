import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-05's Continue rail — "the highest-converting row on the screen".
///
/// One row, not a list: there is exactly one level in progress, and the whole
/// rail is absent when there is none.
class ContinueRow extends StatelessWidget {
  const ContinueRow({required this.entry, required this.onTap, super.key});

  final ContinueEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: ListRowTile(
        title: l10n.homeContinueTitle(entry.subcategoryName, entry.levelNumber),
        subtitle: l10n.homeContinueMeta(
          AppFormat.number(entry.points, localeName),
          entry.livesLeft,
        ),
        leadingEmoji: entry.emoji,
        leadingPlateColor: AppGradients.hex(entry.plateColor),
        onTap: onTap,
        trailing: Text(
          l10n.homeResume,
          style: textTheme.bodyLarge!.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: quizoo.p,
          ),
        ),
      ),
    );
  }
}
