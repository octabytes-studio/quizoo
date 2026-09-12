import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/level_node.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.lvmap` — the vertical serpentine path of twenty level nodes.
///
/// Three things make this the shape it is, all read off the bible's own CSS:
///
/// * **The serpentine is a three-phase cycle**, not a two-phase zigzag. The
///   bible's own frame offsets levels 10–14 by −66, +56, 0, −62, +58 px, which
///   is centre → left → right repeating on `number % 3`. A strict left/right
///   alternation reads as a ladder; the centre beat is what makes it a path.
/// * **Links are dashed and turn mint once cleared** (`.lvlink.done`), so the
///   route already walked is legible at a glance.
/// * **Bands are dividers, not headers** (`.band`) — a hairline either side of
///   the label, mango when the band holds the current level.
class SerpentinePath extends StatelessWidget {
  const SerpentinePath({
    required this.levels,
    required this.onLevelTap,
    super.key,
    this.currentNodeKey,
  });

  final List<Level> levels;

  /// Fired for any node the player is allowed to open — a locked one is inert
  /// rather than tappable-but-refusing.
  final ValueChanged<Level> onLevelTap;

  /// Attached to the current node so the screen can scroll it into view.
  final Key? currentNodeKey;

  /// The three horizontal offsets the path cycles through, in design pixels.
  static const List<double> offsets = [0, -64, 57];

  /// The offset [level] sits at.
  static double offsetFor(int levelNumber) =>
      offsets[levelNumber % offsets.length];

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DifficultyBand? renderedBand;
    final activeBand = levels
        .where((level) => level.status == LevelStatus.current)
        .map((level) => level.difficultyBand)
        .firstOrNull;

    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];

      if (level.difficultyBand != renderedBand) {
        renderedBand = level.difficultyBand;
        children.add(
          _BandDivider(
            band: level.difficultyBand,
            secondsPerQuestion: level.secondsPerQuestion,
            isActive: level.difficultyBand == activeBand,
          ),
        );
      } else if (index > 0) {
        children.add(
          _PathLink(isCleared: levels[index - 1].status == LevelStatus.done),
        );
      }

      children.add(
        _PathStep(
          level: level,
          nodeKey: level.status == LevelStatus.current ? currentNodeKey : null,
          onTap: level.status == LevelStatus.locked
              ? null
              : () => onLevelTap(level),
          // Only the node immediately after the current one names what
          // opens it ("CLEAR LEVEL 12"); the rest just say LOCKED.
          unlocksAfterLevel:
              index > 0 && levels[index - 1].status == LevelStatus.current
              ? levels[index - 1].number
              : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...children,
        SizedBox(height: 10.h),
      ],
    );
  }
}

/// `.lvstep` — one node, its offset, its stars and its label.
class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.level,
    required this.nodeKey,
    required this.onTap,
    required this.unlocksAfterLevel,
  });

  final Level level;
  final Key? nodeKey;
  final VoidCallback? onTap;

  /// The level that unlocks this one, when this is the very next node.
  /// Null on every other node, which is what makes them read "LOCKED".
  final int? unlocksAfterLevel;

  String? _label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (level.status) {
      LevelStatus.done when level.isBoss => l10n.levelMapBossCleared,
      LevelStatus.done when level.starsEarned >= 3 => l10n.levelMapPerfect,
      LevelStatus.done => l10n.levelMapCleared,
      LevelStatus.current => l10n.levelMapCurrent(
        level.questionCount,
        level.secondsPerQuestion,
      ),
      LevelStatus.locked =>
        unlocksAfterLevel == null
            ? l10n.levelMapLocked
            : l10n.levelMapUnlockAfter(unlocksAfterLevel!),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isCurrent = level.status == LevelStatus.current;
    final label = _label(context);

    return Transform.translate(
      offset: Offset(SerpentinePath.offsetFor(level.number).w, 0),
      child: Column(
        children: [
          if (isCurrent) _YouAreHereFlag(label: l10n.levelMapYoureHere),
          LevelNode(
            key: nodeKey,
            number: level.number,
            status: level.status,
            isBoss: level.isBoss,
            starsEarned: level.starsEarned,
            onTap: onTap,
          ),
          SizedBox(height: 7.h),
          if (label != null)
            Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.29,
                color: isCurrent ? quizoo.p : quizoo.tx3,
              ),
            ),
          SizedBox(height: 7.h),
        ],
      ),
    );
  }
}

/// `.youflag` — the mango pennant, with the little downward point under it.
class _YouAreHereFlag extends StatelessWidget {
  const _YouAreHereFlag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: quizoo.p,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.63,
                color: Colors.white,
              ),
            ),
          ),
          CustomPaint(
            size: Size(10.w, 5.h),
            painter: _FlagPointPainter(color: quizoo.p),
          ),
        ],
      ),
    );
  }
}

class _FlagPointPainter extends CustomPainter {
  const _FlagPointPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FlagPointPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// `.lvlink` — the 3×20 dashed connector, mint once the level above it is
/// cleared.
class _PathLink extends StatelessWidget {
  const _PathLink({required this.isCleared});

  final bool isCleared;

  /// `.lvlink` — 3 wide, 20 tall, dashes of 5 on 5 off.
  static const double width = 3;
  static const double height = 20;
  static const double dash = 5;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final color = isCleared ? quizoo.ok : quizoo.ln;

    return SizedBox(
      width: width.w,
      height: height.h,
      child: Column(
        children: [
          for (var segment = 0; segment * dash * 2 < height; segment++)
            Padding(
              padding: EdgeInsets.only(bottom: dash.h),
              child: Container(
                width: width.w,
                height: dash.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.band` — a difficulty divider: a hairline, the label, a hairline.
class _BandDivider extends StatelessWidget {
  const _BandDivider({
    required this.band,
    required this.secondsPerQuestion,
    required this.isActive,
  });

  final DifficultyBand band;
  final int secondsPerQuestion;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final color = isActive ? quizoo.p : quizoo.tx3;
    final ruleColor = isActive ? quizoo.p.withValues(alpha: 0.42) : quizoo.ln;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        14.h,
        AppSpacing.screenMargin.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          Expanded(child: Divider(color: ruleColor, height: 1, thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              l10n.levelMapBand(
                difficultyLabel(l10n, band).toUpperCase(),
                secondsPerQuestion,
              ),
              style: textTheme.labelSmall!.copyWith(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.05,
                color: color,
              ),
            ),
          ),
          Expanded(child: Divider(color: ruleColor, height: 1, thickness: 1)),
        ],
      ),
    );
  }
}

/// §19's band names, resolved from the enum the taxonomy stores.
String difficultyLabel(AppLocalizations l10n, DifficultyBand band) =>
    switch (band) {
      DifficultyBand.warmUp => l10n.difficultyEasy,
      DifficultyBand.steady => l10n.difficultyMedium,
      DifficultyBand.sharp => l10n.difficultyHard,
      DifficultyBand.brutal => l10n.difficultyExpert,
      DifficultyBand.master => l10n.difficultyMaster,
    };
