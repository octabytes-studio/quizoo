import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/difficulty_label.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/topic_mastery/domain/tier_mastery.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `( EASY ✓ )──( MEDIUM ✓ )──( HARD ✓ )`, with per-tier stars underneath —
/// the Topic Mastered screen's journey recap (plan 020).
///
/// Renders from [tiers] rather than a hardcoded three, so a future ladder
/// change needs no code change here. In RTL the enclosing `Row` mirrors
/// automatically, which is the correct reading order.
class TierJourneyStrip extends StatelessWidget {
  const TierJourneyStrip({required this.tiers, super.key});

  final List<TierMastery> tiers;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tiers.length; i++) {
      if (i > 0) {
        children.add(
          Expanded(
            child: Container(
              height: 2.h,
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
              color: context.quizoo.gold.withValues(alpha: 0.5),
            ),
          ),
        );
      }
      children.add(_TierPill(tier: tiers[i], index: i));
    }

    return Row(children: children);
  }
}

class _TierPill extends StatelessWidget {
  const _TierPill({required this.tier, required this.index});

  final TierMastery tier;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final quizoo = context.quizoo;

    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm.w,
                vertical: 5.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✓',
                    style: textTheme.labelSmall!.copyWith(
                      color: quizoo.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    difficultyLabel(l10n, tier.band).toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '⭐ ${tier.starsEarned}/${tier.starsAvailable}',
              style: textTheme.labelSmall!.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10.sp,
              ),
            ),
          ],
        )
        .animate(delay: Duration(milliseconds: 1050 + index * 120))
        .scale(
          duration: AppMotion.durationOf(context, AppMotion.pop),
          curve: AppMotion.curveOf(context, AppMotion.popCurve),
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
        );
  }
}
