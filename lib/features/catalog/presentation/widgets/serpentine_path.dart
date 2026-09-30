import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/difficulty_label.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/level_node.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.lvmap` — the vertical serpentine path of level nodes.
///
/// Three things make this the shape it is, all read off the bible's own CSS:
///
/// * **The serpentine is a three-phase cycle**, not a two-phase zigzag. The
///   bible's own frame offsets levels 10–14 by −66, +56, 0, −62, +58 px, which
///   is centre → left → right repeating on `number % 3`. A strict left/right
///   alternation reads as a ladder; the centre beat is what makes it a path.
/// * **Links are dashed, curved and turn mint once cleared** (`.lvlink.done`),
///   so the route already walked is legible at a glance and the path reads
///   as one continuous trail rather than a column of disconnected dashes.
/// * **Bands are dividers, not headers** (`.band`) — a hairline either side of
///   a colored pill naming the tier, its question count and its clock. Each
///   tier keeps its own accent (mint/mango/raspberry) regardless of which one
///   is current, so every band reads clearly rather than only the active one.
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
            questionCount: level.questionCount,
            isActive: level.difficultyBand == activeBand,
          ),
        );
      } else if (index > 0) {
        children.add(
          _PathLink(
            isCleared: levels[index - 1].status == LevelStatus.done,
            fromNumber: levels[index - 1].number,
            toNumber: level.number,
          ),
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

/// `.lvlink` — a dashed curve tracing the actual path between the level
/// above and the level below, mint once the level above it is cleared.
///
/// Replaces the old plain vertical dashes (CLAUDE.md: a UI fix, not a
/// reinterpretation of the ladder) — those never actually followed the
/// zigzag the nodes sit on, since they were painted straight down the
/// serpentine's centre regardless of [SerpentinePath.offsetFor]. This curve
/// starts and ends at the exact offsets the nodes above and below it sit at,
/// so the path reads as one continuous trail through the zigzag instead of a
/// column of disconnected marks.
class _PathLink extends StatelessWidget {
  const _PathLink({
    required this.isCleared,
    required this.fromNumber,
    required this.toNumber,
  });

  final bool isCleared;

  /// The level number above this link, whose offset the curve starts from.
  final int fromNumber;

  /// The level number below this link, whose offset the curve ends at.
  final int toNumber;

  /// Taller than the old straight dashes (20) so the curve has room to read
  /// as a curve rather than a steep diagonal.
  static const double height = 34;
  static const double strokeWidth = 3.5;
  static const double dash = 6;
  static const double gap = 5;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final color = isCleared ? quizoo.ok : quizoo.ln;

    // A curve can swing between the widest two offsets
    // (`SerpentinePath.offsets`), so the paint surface needs to be wider than
    // the node column itself. `OverflowBox` lets it paint past its own
    // layout footprint — the same trick `Transform.translate` already
    // relies on for the nodes themselves — without widening the `Column`
    // every step sits in.
    final span =
        (SerpentinePath.offsets.reduce((a, b) => a > b ? a : b) -
                SerpentinePath.offsets.reduce((a, b) => a < b ? a : b))
            .w +
        40.w;

    return SizedBox(
      height: height.h,
      child: OverflowBox(
        minWidth: 0,
        maxWidth: span,
        child: CustomPaint(
          size: Size(span, height.h),
          painter: _CurvedLinkPainter(
            color: color,
            startX: SerpentinePath.offsetFor(fromNumber).w,
            endX: SerpentinePath.offsetFor(toNumber).w,
            strokeWidth: strokeWidth.w,
            dash: dash.w,
            gap: gap.w,
          ),
        ),
      ),
    );
  }
}

class _CurvedLinkPainter extends CustomPainter {
  const _CurvedLinkPainter({
    required this.color,
    required this.startX,
    required this.endX,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double startX;
  final double endX;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final start = Offset(centerX + startX, 0);
    final end = Offset(centerX + endX, size.height);

    // A single S-curve between the two offsets: the control points sit at
    // each end's own x but half-way down, which is what makes it leave each
    // node travelling vertically rather than kinking sideways immediately.
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx,
        size.height * 0.5,
        end.dx,
        size.height * 0.5,
        end.dx,
        end.dy,
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var drawing = true;
      while (distance < metric.length) {
        final next = distance + (drawing ? dash : gap);
        if (drawing) {
          canvas.drawPath(
            metric.extractPath(distance, next.clamp(0, metric.length)),
            paint,
          );
        }
        distance = next;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_CurvedLinkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.startX != startX ||
      oldDelegate.endX != endX;
}

/// `.band` — a difficulty divider: a hairline either side of a colored pill
/// naming the tier, how many questions its levels hold, and its clock.
///
/// Each tier keeps a fixed accent (mint/mango/raspberry, escalating the same
/// way the tiers themselves escalate) rather than only the currently-active
/// band getting color and every other one fading to gray — that was what
/// made the dividers hard to read at a glance. The active band's pill is
/// filled solid; the others are a light tint of the same color, so the
/// "you are here" tier still stands out without the rest going invisible.
class _BandDivider extends StatelessWidget {
  const _BandDivider({
    required this.band,
    required this.secondsPerQuestion,
    required this.questionCount,
    required this.isActive,
  });

  final DifficultyBand band;
  final int secondsPerQuestion;
  final int questionCount;
  final bool isActive;

  Color _accentFor(QuizooColors quizoo) => switch (band) {
    DifficultyBand.warmUp => quizoo.ok,
    DifficultyBand.steady => quizoo.p,
    DifficultyBand.sharp => quizoo.bad,
  };

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final accent = _accentFor(quizoo);
    final ruleColor = accent.withValues(alpha: isActive ? 0.5 : 0.28);
    final titleColor = isActive ? Colors.white : accent;
    final metaColor = isActive
        ? Colors.white.withValues(alpha: 0.88)
        : accent.withValues(alpha: 0.8);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        16.h,
        AppSpacing.screenMargin.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          Expanded(child: Divider(color: ruleColor, height: 1, thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: isActive ? accent : accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillAll,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    difficultyLabel(l10n, band).toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    l10n.levelMapBandMeta(questionCount, secondsPerQuestion),
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: metaColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Divider(color: ruleColor, height: 1, thickness: 1)),
        ],
      ),
    );
  }
}
