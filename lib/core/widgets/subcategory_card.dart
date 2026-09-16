import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.sub2` — the one subcategory card, in two placements: fixed-[width] on a
/// home section rail, or `width: null` to fill a 2-up grid cell on S-07.
///
/// A topic looks the same wherever the player meets it (plan 009): avatar
/// plate, name, a thin progress bar, and a status line whose left half is
/// progress and right half is stars. [SubcategoryCard.forTopic] derives all
/// four from a [Subcategory] the same way on both screens, so the state
/// switch lives once rather than being copy-pasted at each call site.
class SubcategoryCard extends StatelessWidget {
  const SubcategoryCard({
    required this.name,
    required this.emoji,
    super.key,
    this.plateColor,
    this.progress = 0,
    this.statusLabel,
    this.trailingLabel,
    this.isStarred = false,
    this.width,
    this.onTap,
    this.isLocked = false,
  });

  /// Derives every display field from a [Subcategory], matching the state
  /// table plan 009 carries over from the tile grid it replaces:
  /// locked → "Locked"; never played → question count / "New"; fully cleared
  /// → "Complete" / a flat three stars; otherwise → "Lv N" and the topic's
  /// average stars per cleared level (a muted dash when that average is
  /// zero, since a real per-level rating is not yet tracked).
  factory SubcategoryCard.forTopic(
    Subcategory topic,
    AppLocalizations l10n, {
    Key? key,
    double? width,
    VoidCallback? onTap,
  }) {
    final String statusLabel;
    String? trailingLabel;
    var isStarred = false;
    double progress = topic.progress;

    if (topic.isLocked) {
      statusLabel = l10n.homeLocked;
    } else if (topic.levelsCleared == 0) {
      statusLabel = l10n.homeQuestionCount(topic.questionCount);
      trailingLabel = l10n.homeNew;
      progress = 0;
    } else if (topic.levelsCleared >= topic.levelCount) {
      statusLabel = l10n.homeComplete;
      trailingLabel = '⭐⭐⭐';
      isStarred = true;
      progress = 1;
    } else {
      statusLabel = l10n.homeLevelShort(topic.levelsCleared);
      final rating = (topic.starsEarned / topic.levelsCleared).floor().clamp(
        0,
        3,
      );
      trailingLabel = rating == 0 ? '—' : '⭐' * rating;
      isStarred = rating > 0;
    }

    return SubcategoryCard(
      key: key,
      name: topic.name,
      emoji: topic.emoji,
      plateColor: topic.plateColor,
      progress: progress,
      statusLabel: statusLabel,
      trailingLabel: trailingLabel,
      isStarred: isStarred,
      width: width,
      isLocked: topic.isLocked,
      onTap: onTap,
    );
  }

  final String name;
  final String emoji;

  /// Tint behind the emoji plate, as `#RRGGBB`. Defaults to the sunken
  /// surface.
  final String? plateColor;

  /// 0…1.
  final double progress;

  /// Left half of the meta row — "Lv 12", "400 questions", "Locked".
  final String? statusLabel;

  /// Right half of the meta row — "New", "⭐⭐", "⭐⭐⭐", or a muted dash.
  final String? trailingLabel;

  /// True paints [trailingLabel] gold instead of the meta row's muted tone.
  final bool isStarred;

  /// Fixed width on a rail; null fills the parent, which is how the 2-up
  /// grid on S-07 uses it.
  final double? width;

  final VoidCallback? onTap;
  final bool isLocked;

  /// `.sub2.inrail` — 164.
  static const double railWidth = 164;

  /// The fixed height every card renders at, whether its name wraps to two
  /// lines or not — see the widget-level doc for why this stays constant.
  /// The internal stack's nominal sum (padding + header row + gaps + bar +
  /// meta row) is ~96 with zero slack, which a widget test's fallback test
  /// font happens to fit exactly but the app's real fonts (Baloo2,
  /// PlusJakartaSans) do not — so this carries real headroom above that
  /// nominal sum rather than matching it exactly. Do not tighten this back
  /// down to the nominal value.
  static const double railHeight = 116;

  /// `.sub2 .av` — 38.
  static const double plateSize = 38;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    Widget card = Container(
      width: width?.w,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: AppRadius.tileAll,
        border: Border.all(color: quizoo.ln),
        boxShadow: quizoo.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: plateSize.w,
                height: plateSize.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: plateColor != null
                      ? AppGradients.hex(plateColor!, fallback: quizoo.s3)
                      : quizoo.s3,
                  borderRadius: BorderRadius.circular(
                    AppRadius.subcategoryPlate.r,
                  ),
                ),
                child: Text(emoji, style: AppTypography.glyph(19.sp)),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 12.5.sp,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.125,
                    color: quizoo.tx,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill.r),
            child: SizedBox(
              height: 6.h,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: quizoo.s3)),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [quizoo.g, AppColors.xpGradientEnd],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 7.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (statusLabel != null)
                Flexible(
                  child: Text(
                    statusLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              if (trailingLabel != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: AppSpacing.xs.w),
                  child: Text(
                    trailingLabel!,
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: isStarred ? quizoo.gold : quizoo.tx3,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (isLocked) {
      // `.sub2 .lockx`-equivalent scrim — the card stays laid out underneath
      // (so every card in a rail keeps the same height) but is obscured.
      card = Stack(
        children: [
          card,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: quizoo.s1.withValues(alpha: 0.74),
                borderRadius: AppRadius.tileAll,
              ),
              child: Center(
                child: Text('🔒', style: AppTypography.glyph(20.sp)),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return card;

    return Semantics(
      button: true,
      enabled: !isLocked,
      label: statusLabel == null ? name : '$name, $statusLabel',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }
}

/// `.sub2.inrail.more` — the dashed end-cap appended to a rail once its
/// category passes [CategorySectionHeader.seeAllThreshold] topics.
class SubcategorySeeAllCard extends StatelessWidget {
  const SubcategorySeeAllCard({
    required this.label,
    super.key,
    this.width,
    this.onTap,
  });

  /// "See all · N topics" — already formatted by the caller via
  /// `AppLocalizations.homeSeeAllCount`.
  final String label;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _DashedRRectBorderPainter(
            color: quizoo.ln,
            radius: AppRadius.tile.r,
          ),
          child: Container(
            width: width?.w,
            height: SubcategoryCard.railHeight.h,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: AppSpacing.md.h,
            ),
            decoration: BoxDecoration(
              color: quizoo.s2,
              borderRadius: AppRadius.tileAll,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: SubcategoryCard.plateSize.w,
                  height: SubcategoryCard.plateSize.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: quizoo.s3,
                    borderRadius: BorderRadius.circular(
                      AppRadius.subcategoryPlate.r,
                    ),
                  ),
                  child: Text(
                    '＋',
                    style: AppTypography.glyph(20.sp, color: quizoo.tx2),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall!.copyWith(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: quizoo.tx2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints `.sub2.more`'s dashed rounded-rect outline. Flutter's [BorderStyle]
/// has no dashed variant, and this is the one place in the app that needs
/// one, so it is a small local painter rather than a new dependency.
class _DashedRRectBorderPainter extends CustomPainter {
  const _DashedRRectBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dashWidth = 5;
  static const double _gapWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
