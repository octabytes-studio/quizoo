import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.hud` + `.qmeta` — the chrome above every question, in every state.
///
/// It mirrors wholesale under an RTL locale without a single conditional: the
/// dot strip and icon row are each a [Row], so they fill right-to-left, and
/// the pause button and streak badge swap ends, because [Directionality]
/// already decides what "start" and "end" mean here.
class QuizHud extends StatelessWidget {
  const QuizHud({
    required this.run,
    required this.isAudioOn,
    required this.onPausePressed,
    required this.onReportPressed,
    required this.onToggleAudioPressed,
    super.key,
  });

  final QuizRun run;

  /// Backs the speaker icon — persisted via `AppSettings.soundOn` (plan 007,
  /// §4.2), unlike `PauseSheet`'s separate, still-inert sound toggle.
  final bool isAudioOn;

  /// Opens S-17's pause sheet. Quitting is no longer a direct HUD action —
  /// it is reached from inside the pause sheet, so a stray tap can no longer
  /// jump straight to the quit confirmation.
  final VoidCallback onPausePressed;

  /// Opens S-51 (plan 004) — the "⋯" overflow next to the streak badge.
  final VoidCallback onReportPressed;

  /// Toggles TTS read-aloud for future questions, and — mid-speech — stops
  /// the current one and reveals immediately.
  final VoidCallback onToggleAudioPressed;

  /// `.play .hud` icon chrome — 34×34, shared by the pause, audio and
  /// report buttons, and matched by the streak badge's height.
  static const double chromeButtonSize = 34;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 2.h, 18.w, 8.h),
          child: Row(
            children: [
              _ChromeButton(
                // The glyph reads as a close/✕ mark; it pauses rather than
                // quitting outright — quitting now lives one step further
                // in, inside the pause sheet this opens.
                glyph: '✕',
                semanticLabel: l10n.quizPauseLabel,
                onTap: onPausePressed,
              ),
              SizedBox(width: 10.w),
              // Lives are hearts, never a bare number (S-11) — sitting where
              // the dot strip used to, now that the dots have their own row.
              Expanded(
                child: Center(
                  child: Semantics(
                    label: '${run.heartsRemaining}',
                    child: Text(
                      _hearts(run),
                      style: AppTypography.glyph(15.sp),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              _StreakBadge(streak: run.currentStreak),
              SizedBox(width: 10.w),
              _ChromeButton(
                glyph: isAudioOn ? '🔊' : '🔇',
                semanticLabel: isAudioOn
                    ? l10n.quizAudioOnLabel
                    : l10n.quizAudioOffLabel,
                onTap: onToggleAudioPressed,
              ),
              SizedBox(width: 10.w),
              _ChromeButton(
                glyph: '⋯',
                semanticLabel: l10n.quizReportLabel,
                onTap: onReportPressed,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 8.h),
          child: _ProgressDots(run: run),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.h),
          // The two text cells flex rather than sitting at their natural
          // width: a five-figure score late in a level is wider than the gap
          // left for it, and the meta row must give ground before it
          // overflows.
          child: Row(
            children: [
              Expanded(
                child: _MetaText(
                  // The counter never counts past the last question, even
                  // while its verdict banner is up.
                  label: l10n.questionCounter(
                    run.questionNumber.clamp(1, run.questionCount),
                    run.questionCount,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${l10n.quizScore} ',
                    children: [
                      TextSpan(
                        text: AppFormat.number(run.score, localeName),
                        style: textTheme.bodyMedium!.copyWith(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: arena.onArena,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: arena.metaText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `❤️❤️🖤` — filled hearts for what is left, black for what is spent.
  static String _hearts(QuizRun run) {
    const total = 3;
    return '❤️' * run.heartsRemaining.clamp(0, total) +
        '🖤' * (total - run.heartsRemaining).clamp(0, total);
  }
}

/// `.qdots` — the whole level at a glance.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.run});

  final QuizRun run;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final arena = context.arena;

    return Row(
      children: [
        for (var index = 0; index < run.questionCount; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w),
              child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: switch (index) {
                    // Answered: mint when right, raspberry when not — which
                    // includes a timeout, since the question is gone either
                    // way.
                    _ when index < run.answers.length =>
                      run.answers[index].isCorrect ? quizoo.ok : quizoo.bad,
                    // The one being played now.
                    _ when index == run.answers.length => arena.onArena,
                    _ => arena.questionDot,
                  },
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// `.streakb` — dims to near-invisible at zero rather than disappearing, so
/// the HUD does not reflow when a streak breaks.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: streak == 0 ? 0.4 : 1,
      child: Container(
        height: QuizHud.chromeButtonSize.w,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
        ),
        child: Text(
          l10n.quizStreak(streak),
          style: textTheme.bodyMedium!.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: arena.onArena,
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.bodyMedium!.copyWith(
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w700,
        color: arena.metaText,
      ),
    );
  }
}

/// `.play .hud` icon — a translucent square on the arena.
class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.glyph,
    required this.semanticLabel,
    required this.onTap,
  });

  final String glyph;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: QuizHud.chromeButtonSize.w,
          height: QuizHud.chromeButtonSize.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: arena.chrome,
            borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
          ),
          child: Text(
            glyph,
            style: AppTypography.glyph(15.sp, color: arena.onArena),
          ),
        ),
      ),
    );
  }
}
