import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// "You have a duel in progress · Rejoin", pinned above the composer while
/// the lobby snapshot reports an active duel (plan 017, S-38).
class RejoinDuelBanner extends StatelessWidget {
  const RejoinDuelBanner({required this.onRejoin, super.key});

  final VoidCallback onRejoin;

  static const double ctaWidth = 104;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.sm.h,
        AppSpacing.screenMargin.w,
        0,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: arena.cardPlate,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: arena.ownCardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: arena.cardLedge,
              offset: Offset(0, AppElevation.ledge.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Text('⚔️', style: AppTypography.glyph(20.sp)),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Text(
                l10n.duelRejoinTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: arena.cardInk,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            SizedBox(
              width: ctaWidth.w,
              child: ChunkyButton.success(
                label: l10n.duelRejoinCta,
                isSmall: true,
                onPressed: onRejoin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
