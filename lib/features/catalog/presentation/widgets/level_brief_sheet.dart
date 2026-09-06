import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';
import 'package:quizoo/features/catalog/presentation/widgets/serpentine_path.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-09 — the contract before you commit: how many, how fast, how many lives,
/// what you're carrying.
///
/// It is also where the level's twenty questions finish prefetching. That is
/// not decoration: **"Start Level N" stays disabled until the prefetch
/// resolves**, so the state genuinely gets exercised rather than being faked
/// as instantly ready.
class LevelBriefSheet extends StatefulWidget {
  const LevelBriefSheet({
    required this.map,
    required this.level,
    required this.repository,
    required this.languageCode,
    super.key,
  });

  final LevelMap map;
  final Level level;
  final QuizPlayRepository repository;

  /// Which language the questions are prefetched in, passed as a plain code
  /// so nothing below the widget layer needs a `BuildContext`.
  final String languageCode;

  /// Presents the sheet and resolves to true when the player starts the level.
  static Future<bool> show(
    BuildContext context, {
    required LevelMap map,
    required Level level,
    required QuizPlayRepository repository,
  }) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final started = await AppBottomSheet.show<bool>(
      context,
      builder: (_) => LevelBriefSheet(
        map: map,
        level: level,
        repository: repository,
        languageCode: languageCode,
      ),
    );
    return started ?? false;
  }

  @override
  State<LevelBriefSheet> createState() => _LevelBriefSheetState();
}

class _LevelBriefSheetState extends State<LevelBriefSheet> {
  /// Prefetch progress is purely local to this sheet and dies with it, so it
  /// is `setState` rather than a Cubit (CLAUDE.md §3).
  bool _isPreparing = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _isPreparing = true;
      _failed = false;
    });
    try {
      await widget.repository.prepareLevel(
        levelId: widget.level.id,
        subcategoryId: widget.map.subcategory.id,
        levelNumber: widget.level.number,
        languageCode: widget.languageCode,
      );
      if (mounted) setState(() => _isPreparing = false);
    } on ApiException {
      if (mounted) {
        setState(() {
          _isPreparing = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final Subcategory subcategory = widget.map.subcategory;
    final level = widget.level;

    return AppBottomSheet(
      showHandle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.tileFromHex(
                    widget.map.category.colorFrom,
                    widget.map.category.colorTo,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  subcategory.emoji,
                  style: AppTypography.glyph(26.sp),
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.levelBriefTitle(level.number),
                      style: textTheme.headlineLarge,
                    ),
                    Text(
                      l10n.levelBriefSubtitle(
                        subcategory.name,
                        difficultyLabel(l10n, level.difficultyBand),
                      ),
                      style: textTheme.bodySmall!.copyWith(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              AppChip.status(label: l10n.levelBriefStreakMultiplier('1.5')),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _BriefStat(
                value: '${level.questionCount}',
                label: l10n.levelBriefQuestions,
              ),
              SizedBox(width: 9.w),
              _BriefStat(
                value: l10n.levelBriefSeconds(level.secondsPerQuestion),
                label: l10n.levelBriefPerQuestion,
              ),
              SizedBox(width: 9.w),
              _BriefStat(
                value: '${MockPlayer.livesPerLevel}',
                label: l10n.levelBriefLives,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.base.h),
          Text(l10n.levelBriefPowerUps, style: textTheme.labelSmall),
          SizedBox(height: AppSpacing.sm.h),
          Row(
            children: [
              _BriefPowerUp(
                emoji: '🎯',
                label: l10n.quizPowerUpFiftyFifty,
                count: MockPlayer.fiftyFiftyCount,
              ),
              SizedBox(width: 10.w),
              _BriefPowerUp(
                emoji: '⏱️',
                label: l10n.quizPowerUpAddTime,
                count: MockPlayer.addTimeCount,
              ),
              SizedBox(width: 10.w),
              _BriefPowerUp(
                emoji: '⏭️',
                label: l10n.quizPowerUpSkip,
                count: MockPlayer.skipCount,
              ),
              SizedBox(width: 10.w),
              _BriefPowerUp(
                emoji: '➕',
                label: l10n.levelBriefShop,
                count: 0,
                isDimmed: true,
              ),
            ],
          ),
          SizedBox(height: 18.h),
          if (_failed)
            ChunkyButton.ghost(label: l10n.commonRetry, onPressed: _prepare)
          else
            ChunkyButton(
              label: _isPreparing
                  ? l10n.levelBriefPreparing
                  : l10n.levelBriefStart(level.number),
              // Disabled — not hidden — until the questions are in hand.
              onPressed: _isPreparing
                  ? null
                  : () => Navigator.of(context).pop(true),
            ),
        ],
      ),
    );
  }
}

/// `.c.flat` — one of the three flat stat cards.
class _BriefStat extends StatelessWidget {
  const _BriefStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: quizoo.s2,
          border: Border.all(color: quizoo.ln),
          borderRadius: BorderRadius.circular(AppRadius.card.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: textTheme.displayMedium!.copyWith(fontSize: 19.sp),
            ),
            Text(label, style: textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// `.pup` in its themed form — the dock's tile is arena-coloured, this one
/// sits on a sheet.
class _BriefPowerUp extends StatelessWidget {
  const _BriefPowerUp({
    required this.emoji,
    required this.label,
    required this.count,
    this.isDimmed = false,
  });

  final String emoji;
  final String label;
  final int count;
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isDimmed ? 0.5 : 1,
      child: SizedBox(
        width: 56.w,
        height: 52.h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: quizoo.s3,
                border: Border.all(color: quizoo.ln),
                borderRadius: BorderRadius.circular(AppRadius.powerUp.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: AppTypography.glyph(19.sp)),
                  Text(
                    label,
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w800,
                      color: quizoo.tx2,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              PositionedDirectional(
                top: -5.h,
                end: -4.w,
                child: Container(
                  width: 17.w,
                  height: 17.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: quizoo.p,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
