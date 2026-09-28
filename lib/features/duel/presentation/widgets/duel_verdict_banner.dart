import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The duel's reveal verdict — play mode's feedback banner in miniature:
/// "✓ Correct!  +1", "✗ Not quite" or "⏱ Time's up", rising in on the
/// round's reveal (instantly under reduced motion).
class DuelVerdictBanner extends StatelessWidget {
  const DuelVerdictBanner({
    required this.correct,
    required this.timedOut,
    super.key,
  });

  final bool correct;

  /// No answer was locked before the clock ran out.
  final bool timedOut;

  static const Duration _entrance = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final accent = correct ? quizoo.ok : quizoo.bad;
    final (glyph, label) = correct
        ? ('✓', l10n.feedbackCorrect)
        : timedOut
        ? ('⏱', l10n.feedbackTimeout)
        : ('✗', l10n.feedbackWrong);

    final banner = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        boxShadow: quizoo.shadow,
      ),
      child: Row(
        children: [
          Text(glyph, style: AppTypography.glyph(18.sp, color: arena.onArena)),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium!.copyWith(color: arena.onArena),
            ),
          ),
          if (correct)
            Text(
              l10n.feedbackPoints('1'),
              style: textTheme.titleMedium!.copyWith(color: arena.onArena),
            ),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.durationOf(context, _entrance),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Opacity(
          opacity: value.clamp(0, 1),
          child: FractionalTranslation(
            translation: Offset(0, 0.4 * (1 - value)),
            child: child,
          ),
        ),
        child: banner,
      ),
    );
  }
}
