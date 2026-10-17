import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-10 — 3 · 2 · 1 · GO.
///
/// It is a view over [QuizPlayCubit], not a route of its own, because the
/// countdown and the first question are one continuous surface — and because
/// the invariant that matters here is a Cubit invariant: **the gameplay clock
/// does not start until GO has left the screen.** Rendering the countdown as
/// a separate screen with its own timer is exactly how that gets broken.
class CountdownView extends StatelessWidget {
  const CountdownView({required this.state, required this.onSkip, super.key});

  final QuizPlayCountdown state;
  final VoidCallback onSkip;

  /// The bible's own numeral size.
  static const double numeralSize = 150;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    final beat = state.isGo
        ? l10n.countdownGo
        : AppFormat.plain(state.beat, localeName);

    return GestureDetector(
      onTap: onSkip,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // The daily run carries no subcategory/level (plan 025), so it
              // gets its own label rather than a blank "· LEVEL 0".
              state.run.isDaily
                  ? l10n.countdownDailyMeta
                  : l10n.countdownMeta(
                      state.run.subcategoryName.toUpperCase(),
                      state.run.levelNumber,
                    ),
              style: textTheme.labelSmall!.copyWith(
                letterSpacing: 2.1,
                color: arena.onArena.withValues(alpha: 0.6),
              ),
            ),
            Text(
                  beat,
                  style: textTheme.displayLarge!.copyWith(
                    fontSize: numeralSize.sp,
                    height: 1,
                    color: arena.onArena,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: Offset(0, 10.h),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                )
                .animate(
                  // Keying on the beat restarts the pop for every numeral,
                  // which is what makes each one land rather than the first
                  // one animating and the rest appearing.
                  key: ValueKey(state.beat),
                )
                .scale(
                  begin: const Offset(1.6, 1.6),
                  end: const Offset(1, 1),
                  duration: AppMotion.durationOf(context, AppMotion.pop),
                  curve: AppMotion.curveOf(context, AppMotion.popCurve),
                ),
            SizedBox(height: 8.h),
            Text(
              l10n.countdownGetReady,
              style: textTheme.bodyMedium!.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: arena.onArena.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
