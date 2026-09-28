import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The arena's fixed "⚡ Quick match" card (plan 017, S-38): auto-pairing
/// with a player near your level, one tap away above the feed.
class QuickMatchCard extends StatelessWidget {
  const QuickMatchCard({required this.onFind, super.key});

  /// Opens the topic picker, then matchmaking.
  final VoidCallback onFind;

  static const double ctaWidth = 128;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: arena.questionCard,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: arena.questionCardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⚡ ${l10n.duelQuickMatchTitle.toUpperCase()}',
                    style: textTheme.labelMedium!.copyWith(
                      color: arena.onArena,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    l10n.duelQuickMatchBody,
                    style: textTheme.bodySmall!.copyWith(color: arena.metaText),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            SizedBox(
              width: ctaWidth.w,
              child: ChunkyButton.gold(
                label: l10n.duelQuickMatchCta,
                isSmall: true,
                onPressed: onFind,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
