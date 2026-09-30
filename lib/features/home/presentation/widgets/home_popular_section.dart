import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/features/home/presentation/widgets/popular_quiz_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// "🔥 Popular this week" — the section header over `.rail-h`, the
/// horizontally scrolling popular rail.
///
/// The rail's cards bleed past the screen's 20px margin, which is what
/// signals "scroll me" (§05). The whole section — header included — is
/// hidden once the rail has loaded empty (plan 021): it collapses with an
/// [AnimatedSize] rather than vanishing abruptly, since emptiness is only
/// known after the network leg returns.
class HomePopularSection extends StatelessWidget {
  const HomePopularSection({
    required this.popular,
    required this.isLoading,
    required this.onSeeAll,
    required this.onQuizTap,
    super.key,
  });

  final List<PopularQuiz> popular;

  /// Shows three skeleton cards in the rail while the network leg is out.
  final bool isLoading;

  final VoidCallback onSeeAll;
  final ValueChanged<PopularQuiz> onQuizTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVisible = isLoading || popular.isNotEmpty;

    return AnimatedSize(
      duration: AppMotion.durationOf(context, AppMotion.slide),
      curve: AppMotion.curveOf(context, AppMotion.slideCurve),
      alignment: AlignmentDirectional.topStart,
      child: isVisible
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l10n.homePopularThisWeek,
                  actionLabel: l10n.homeSeeAll,
                  onActionPressed: onSeeAll,
                ),
                SizedBox(height: AppSpacing.md.h),
                SizedBox(
                  height: PopularQuizCard.height.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin.w,
                    ),
                    itemCount: isLoading ? 3 : popular.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: AppSpacing.md.w),
                    itemBuilder: (context, index) {
                      if (isLoading) {
                        return SkeletonBox(
                          width: PopularQuizCard.width.w,
                          height: PopularQuizCard.height.h,
                          borderRadius: BorderRadius.circular(AppRadius.card.r),
                        );
                      }
                      final quiz = popular[index];
                      return PopularQuizCard(
                        quiz: quiz,
                        onTap: () => onQuizTap(quiz),
                      );
                    },
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h - 2.h),
              ],
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
