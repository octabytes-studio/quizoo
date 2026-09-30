import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/navigation/badge_celebration.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/auth/presentation/widgets/save_progress_sheet.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/result_wash.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/score_breakdown_card.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/stars_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-21 — level complete.
///
/// Sequenced rather than dumped: stars land at 0/200/400 ms, the score rolls
/// up over 900 ms, then the breakdown rows stagger in at 60 ms each.
///
/// **The chain after this screen** is decided by [QuizResultCubit] and
/// executed here as route pushes only — first the Topic Mastered screen if
/// this run just mastered the topic (plan 020), then S-23 if a badge was
/// earned, then S-24 if an account is worth offering. Nothing here imports
/// another feature's code, so plan 003 (or `features/topic_mastery`) landing
/// later changes only what those routes resolve to.
class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({required this.state, super.key});

  final QuizResultCompleted state;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen> {
  bool _hasRunChain = false;

  /// Set once the Topic Mastered screen has been opened, whether by the
  /// chain or by the player tapping "See your trophy 🏆" during the payout —
  /// so the chain never pushes it twice.
  bool _masteryShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChain());
  }

  /// Waits out the payout sequence, then offers whatever this run earned.
  Future<void> _runChain() async {
    if (_hasRunChain) return;
    _hasRunChain = true;

    // The bible budgets the whole payout at ~2.6 s; interrupting it with a
    // sheet halfway through would throw away the moment it exists to create.
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    if (widget.state.result.unlocksMastery) {
      await _openMastery();
      if (!mounted) return;
    }

    await celebrateBadges(context, widget.state.result.newlyEarnedBadgeIds);
    if (!mounted) return;

    if (widget.state.result.shouldOfferSaveProgress) {
      // Recorded before it is shown, so a second run in the same session
      // cannot race it into appearing twice.
      context.read<QuizResultCubit>().markSaveProgressShown();
      await context.push(
        AppRoutes.saveProgress,
        extra: SaveProgressArgs(
          score: widget.state.result.finalScore,
          levelNumber: widget.state.result.run.levelNumber,
        ),
      );
    }
  }

  /// A route push only — no import of `features/topic_mastery`, the same way
  /// S-23's badge celebration is reached.
  Future<void> _openMastery() async {
    if (_masteryShown) return;
    _masteryShown = true;
    final run = widget.state.result.run;
    await context.push(
      AppRoutes.topicMasteredPath(run.categoryId, run.subcategoryId),
    );
  }

  // A `pop`, not a `go` — the play screen reached this one via
  // `pushReplacement`, so the level map is already directly beneath it on the
  // stack. `go` would rebuild the stack from this location alone, dropping
  // the category/level-map history and leaving nothing for a later back
  // press to pop.
  void _close() => context.pop();

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final LevelResult result = widget.state.result;
    final run = result.run;

    return ResultWash(
      accent: quizoo.ok,
      onClose: _close,
      onShare: () => context.push(AppRoutes.share),
      actions: [
        if (result.unlocksMastery) ...[
          ChunkyButton.gold(
            label: l10n.resultSeeTrophy,
            onPressed: _openMastery,
          ),
          if (result.stars < 3) ...[
            SizedBox(height: 9.h),
            ChunkyButton.line(
              label: l10n.resultReplay,
              onPressed: () =>
                  context.pushReplacement(AppRoutes.countdownPath(run.levelId)),
            ),
          ],
        ] else if (result.isFinalLevel) ...[
          ChunkyButton(label: l10n.resultBackToMap, onPressed: _close),
          if (result.stars < 3) ...[
            SizedBox(height: 9.h),
            ChunkyButton.line(
              label: l10n.resultReplay,
              onPressed: () =>
                  context.pushReplacement(AppRoutes.countdownPath(run.levelId)),
            ),
          ],
        ] else ...[
          ChunkyButton(
            label: l10n.resultNextLevel,
            onPressed: () => context.pushReplacement(
              AppRoutes.countdownPath(
                MockCatalog.levelId(run.subcategoryId, run.levelNumber + 1),
              ),
            ),
          ),
          // Offered only when there is still a star to win.
          if (result.stars < 3) ...[
            SizedBox(height: 9.h),
            ChunkyButton.line(
              label: l10n.resultReplay,
              onPressed: () =>
                  context.pushReplacement(AppRoutes.countdownPath(run.levelId)),
            ),
          ],
        ],
      ],
      child: Column(
        children: [
          Text('🎉', style: AppTypography.glyph(54.sp)),
          Text(
            l10n.resultCompleteTitle(run.levelNumber),
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 27.sp,
              color: Colors.white,
            ),
          ),
          StarsRow(stars: result.stars),
          Text(
            result.stars >= 3
                ? l10n.resultStarsPerfect
                : l10n.resultStarsMeta(
                    result.stars,
                    result.correctForThirdStar,
                  ),
            textAlign: TextAlign.center,
            style: textTheme.labelSmall!.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: AppSpacing.base.h),
          ScoreBreakdownCard(result: result),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}
