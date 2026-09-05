import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// The three configurations of the one row component (§06).
enum ListRowVariant {
  /// A piece of content — rounded-square emoji plate, title, meta, trailing
  /// value.
  content,

  /// Another player — circular avatar, name, location/level, rank.
  player,

  /// The signed-in player's own row. Gets a permanent 2px grape border and is
  /// always pinned visible in leaderboards.
  self,
}

/// The single list row used by every list in the app.
///
/// One component, three configurations — a leaderboard, a category list and a
/// friends list all render this, so their rhythm is identical by construction
/// rather than by discipline.
class ListRowTile extends StatelessWidget {
  const ListRowTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leadingEmoji,
    this.leadingPlateColor,
    this.trailingValue,
    this.trailingLabel,
    this.trailingColor,
    this.trailing,
    this.variant = ListRowVariant.content,
    this.accentColor,
    this.onTap,
    this.padding,
  });

  final String title;
  final String? subtitle;

  /// The glyph inside the leading plate.
  final String? leadingEmoji;

  /// Fill behind [leadingEmoji]. Defaults to the sunken surface.
  final Color? leadingPlateColor;

  /// The bold trailing figure — points, rank, score. Rendered with tabular
  /// figures so a column of them lines up.
  final String? trailingValue;

  /// The small caption under [trailingValue] — "pts", "▲ 3".
  final String? trailingLabel;

  /// Overrides the colour of [trailingValue].
  final Color? trailingColor;

  /// A fully custom trailing widget, used instead of the value/label pair.
  final Widget? trailing;

  final ListRowVariant variant;

  /// Border colour for a highlighted row — the play sheet's primary row uses
  /// mango, the report sheet's chosen reason uses grape. Ignored for
  /// [ListRowVariant.self], which is always grape by definition.
  final Color? accentColor;

  final VoidCallback? onTap;

  /// Overrides `.row`'s 11×14 padding.
  final EdgeInsetsGeometry? padding;

  /// `.row .av` — the content variant's rounded-square plate.
  static const double plateSize = 44;

  /// `.avc` — the player variant's circular avatar.
  static const double avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    final isSelf = variant == ListRowVariant.self;
    final borderColor = isSelf ? quizoo.g : (accentColor ?? quizoo.ln);
    final borderWidth = isSelf || accentColor != null ? 2.0 : 1.0;

    Widget? leading;
    if (leadingEmoji != null) {
      leading = variant == ListRowVariant.content
          ? Container(
              width: plateSize.w,
              height: plateSize.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: leadingPlateColor ?? quizoo.s3,
                borderRadius: BorderRadius.circular(AppRadius.rowAvatar.r),
              ),
              child: Text(leadingEmoji!, style: AppTypography.glyph(22.sp)),
            )
          : Container(
              width: avatarSize.w,
              height: avatarSize.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadingPlateColor ?? quizoo.s3,
                border: Border.all(color: quizoo.s1, width: 2),
              ),
              child: Text(leadingEmoji!, style: AppTypography.glyph(19.sp)),
            );
    }

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && trailingValue != null) {
      trailingWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingValue!,
            style: textTheme.bodyLarge!.copyWith(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w800,
              color: trailingColor ?? quizoo.tx,
            ),
          ),
          if (trailingLabel != null)
            Text(trailingLabel!, style: textTheme.labelSmall),
        ],
      );
    }

    final row = Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: BorderRadius.circular(AppRadius.listRow.r),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading, SizedBox(width: AppSpacing.md.w)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.14,
                    color: quizoo.tx,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge!.copyWith(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: quizoo.tx3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            SizedBox(width: AppSpacing.md.w),
            trailingWidget,
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: row,
      ),
    );
  }
}
