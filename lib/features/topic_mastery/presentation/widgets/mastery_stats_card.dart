import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The 2×2 stats grid: stars, perfect levels, total score, and either days
/// to master or levels cleared (when there is no `startedAt` to measure
/// from) — the Topic Mastered screen's tally (plan 020).
class MasteryStatsCard extends StatelessWidget {
  const MasteryStatsCard({required this.mastery, super.key});

  final TopicMastery mastery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final daysToMaster = mastery.daysToMaster;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.base.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            borderRadius: AppRadius.cardAll,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      emoji: '⭐',
                      value: mastery.starsEarned,
                      suffix: ' / ${mastery.starsAvailable}',
                      caption: l10n.masteryStatStars,
                      localeName: localeName,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      emoji: '🏅',
                      value: mastery.perfectLevels,
                      caption: l10n.masteryStatPerfect,
                      localeName: localeName,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      emoji: '🎯',
                      value: mastery.totalScore,
                      caption: l10n.masteryStatScore,
                      localeName: localeName,
                      grouped: true,
                    ),
                  ),
                  Expanded(
                    child: daysToMaster != null
                        ? _StatCell(
                            emoji: '📅',
                            value: daysToMaster,
                            caption: l10n.masteryStatDays(daysToMaster),
                            localeName: localeName,
                          )
                        : _StatCell(
                            emoji: '🔥',
                            value: mastery.levelsCleared,
                            caption: l10n.masteryStatLevels,
                            localeName: localeName,
                          ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: const Duration(milliseconds: 1450))
        .fadeIn(duration: AppMotion.durationOf(context, AppMotion.slide))
        .slideY(
          begin: 0.15,
          end: 0,
          duration: AppMotion.durationOf(context, AppMotion.slide),
        );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.emoji,
    required this.value,
    required this.caption,
    required this.localeName,
    this.suffix = '',
    this.grouped = false,
  });

  final String emoji;
  final int value;
  final String suffix;
  final String caption;
  final String localeName;
  final bool grouped;

  String _format(int value) =>
      grouped ? AppFormat.number(value, localeName) : '$value';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = AppMotion.reduceMotion(context);

    return Semantics(
      label: '${_format(value)}$suffix $caption',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: AppTypography.glyph(20.sp)),
          SizedBox(height: 2.h),
          reduceMotion
              ? Text(
                  '${_format(value)}$suffix',
                  style: textTheme.titleLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: AppMotion.count,
                  curve: AppMotion.countCurve,
                  builder: (context, animatedValue, _) => Text(
                    '${_format(animatedValue)}$suffix',
                    style: textTheme.titleLarge!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
          SizedBox(height: 2.h),
          Text(
            caption,
            style: textTheme.labelSmall!.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
