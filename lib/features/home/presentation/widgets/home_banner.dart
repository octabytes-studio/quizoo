import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The full-width gradient card at the top of Home's scroll.
///
/// Two purpose-built wrappers rather than one widget with a mode flag
/// (CLAUDE.md §7): [SaveProgressCard] for a guest and [DailyChallengeBanner]
/// for a signed-in player. They never both appear — that slot is one card.
class _HomeBanner extends StatelessWidget {
  const _HomeBanner({
    required this.emoji,
    required this.title,
    required this.message,
    required this.colorFrom,
    required this.colorTo,
    required this.emojiSize,
    this.action,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String message;
  final String colorFrom;
  final String colorTo;
  final double emojiSize;

  /// The trailing pill, present only on the daily banner.
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
          decoration: BoxDecoration(
            gradient: AppGradients.linear(AppGradients.bannerAngle, [
              AppGradients.hex(colorFrom),
              AppGradients.hex(colorTo),
            ]),
            borderRadius: BorderRadius.circular(AppRadius.card.r),
            boxShadow: quizoo.shadow,
          ),
          child: Row(
            children: [
              Text(emoji, style: AppTypography.glyph(emojiSize.sp)),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall!.copyWith(
                        fontSize: 15.sp,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      message,
                      style: textTheme.bodyMedium!.copyWith(
                        fontSize: 11.5.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                SizedBox(width: AppSpacing.md.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 13.w,
                    vertical: AppSpacing.sm.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(
                      AppRadius.inlineAction.r,
                    ),
                  ),
                  child: Text(
                    action!,
                    style: textTheme.bodyLarge!.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// S-04's grape card. **Informational, never modal** — the bible is explicit
/// that it must not block a tap, so it has no action and no dismiss.
class SaveProgressCard extends StatelessWidget {
  const SaveProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _HomeBanner(
      emoji: '🎁',
      title: l10n.homeSaveProgressTitle,
      message: l10n.homeSaveProgressBody,
      colorFrom: '#7B4DFF',
      colorTo: '#5B2FD6',
      emojiSize: 30,
    );
  }
}

/// S-05's mango banner, the first row a signed-in player sees.
class DailyChallengeBanner extends StatelessWidget {
  const DailyChallengeBanner({
    required this.daily,
    required this.remainingLabel,
    required this.onTap,
    super.key,
  });

  final DailyChallengePreview daily;

  /// Pre-formatted "4h 12m", because the widget has no business doing
  /// duration maths in `build()`.
  final String remainingLabel;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _HomeBanner(
      emoji: '🎯',
      title: l10n.homeDailyChallengeTitle,
      message: l10n.homeDailyChallengeMeta(daily.questionCount, remainingLabel),
      colorFrom: '#FF8A24',
      colorTo: '#FF3D6E',
      emojiSize: 28,
      action: l10n.homeDailyPlay,
      onTap: onTap,
    );
  }
}
