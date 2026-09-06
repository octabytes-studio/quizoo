import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.pq` — a card in Home's "Popular this week" rail.
///
/// The gradient is the card's own, not its category's, and a dark scrim runs
/// from 32% down so white type stays legible over any of them.
class PopularQuizCard extends StatelessWidget {
  const PopularQuizCard({required this.quiz, required this.onTap, super.key});

  final PopularQuiz quiz;
  final VoidCallback onTap;

  /// `.pq` — 172×132.
  static const double width = 172;
  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width.w,
        height: height.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AppGradients.tileFromHex(quiz.colorFrom, quiz.colorTo),
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          boxShadow: quizoo.shadow,
        ),
        child: Stack(
          children: [
            // `.pq::after` — the legibility scrim.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    stops: const [0.32, 1],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.sm.h,
              end: AppSpacing.sm.w,
              child: Text(quiz.emoji, style: AppTypography.glyph(34.sp)),
            ),
            if (quiz.isHot)
              PositionedDirectional(
                top: 10.h,
                start: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: quizoo.bad,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                  child: Text(
                    l10n.homeHotBadge,
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.45,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall!.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    l10n.homePlayedCount(
                      AppFormat.compact(quiz.playedCount, localeName),
                    ),
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 10.5.sp,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
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
