import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_badge.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/widgets/pro_tick.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-29's top-3 podium — the one place in the whole app that uses variable
/// "plinth" heights; everywhere else is a flat row (the bible's own explicit
/// note).
class Podium extends StatelessWidget {
  const Podium({
    required this.first,
    required this.second,
    required this.third,
    super.key,
    this.onTap,
  });

  final LeaderboardEntry first;
  final LeaderboardEntry second;
  final LeaderboardEntry third;

  final ValueChanged<LeaderboardEntry>? onTap;

  // Taller than a plain rank number needs, since the plinth now also carries
  // the country flag underneath the ordinal label.
  static const double firstPlinth = 76;
  static const double secondPlinth = 60;
  static const double thirdPlinth = 48;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPlace(
              entry: second,
              place: 2,
              plinthHeight: secondPlinth,
              onTap: onTap,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: _PodiumPlace(
              entry: first,
              place: 1,
              plinthHeight: firstPlinth,
              onTap: onTap,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: _PodiumPlace(
              entry: third,
              place: 3,
              plinthHeight: thirdPlinth,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.place,
    required this.plinthHeight,
    this.onTap,
  });

  final LeaderboardEntry entry;

  /// 1, 2 or 3 — which medal/prominence this place gets, independent of
  /// [entry]'s own rank (so ties still render a sensible medal).
  final int place;
  final double plinthHeight;
  final ValueChanged<LeaderboardEntry>? onTap;

  static const double avatarSize = 48;
  static const double firstAvatarSize = 60;

  static String _medalFor(int place) => switch (place) {
    1 => '🥇',
    2 => '🥈',
    _ => '🥉',
  };

  static String _ordinalFor(AppLocalizations l10n, int place) =>
      switch (place) {
        1 => l10n.leaderboardPodiumFirst,
        2 => l10n.leaderboardPodiumSecond,
        _ => l10n.leaderboardPodiumThird,
      };

  /// [LeaderboardEntry.locationLabel] is always `'<flag> <country name>'`
  /// (`LeaderboardApi._locationLabel`) — the flag is everything before the
  /// first space, regardless of how many words the country name itself has.
  static String? _flagOf(LeaderboardEntry entry) {
    final label = entry.locationLabel;
    if (label == null) return null;
    final spaceIndex = label.indexOf(' ');
    return spaceIndex == -1 ? label : label.substring(0, spaceIndex);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final isFirst = place == 1;
    final avatarDiameter = isFirst ? firstAvatarSize : avatarSize;
    // Plan 023: own row, so the local entitlement is OR'd in — see `proBadge`.
    final isPro = proBadge(
      serverIsPro: entry.isPro,
      isSelf: entry.isSelf,
      localIsPro: context.select<SubscriptionCubit, bool>(
        (cubit) => cubit.state.isPro,
      ),
    );
    final flag = _flagOf(entry);

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(entry),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarDiameter.w,
                height: avatarDiameter.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quizoo.s3,
                  border: Border.all(
                    color: isFirst ? quizoo.gold : quizoo.s1,
                    width: isFirst ? 3 : 2,
                  ),
                ),
                child: Text(
                  entry.avatarEmoji,
                  style: AppTypography.glyph(isFirst ? 27.sp : 23.sp),
                ),
              ),
              Positioned(
                bottom: -6.h,
                child: Text(
                  _medalFor(place),
                  style: AppTypography.glyph(isFirst ? 30.sp : 24.sp),
                ),
              ),
              // A crown, tilted right, is 1st place's only extra prominence
              // marker — no background glow (washes out badly in light mode).
              if (isFirst)
                Positioned(
                  top: -16.h,
                  right: -8.w,
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Text('👑', style: AppTypography.glyph(28.sp)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          // Plan 023: name + the gold verified tick, which is the only Pro
          // marker. The tick keeps its own semantics so the name is still
          // read as one word.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: isFirst ? 13.5.sp : 12.5.sp,
                    fontWeight: isFirst ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (isPro) ...[
                SizedBox(width: 3.w),
                ProTick(size: isFirst ? 13.sp : 12.sp),
              ],
            ],
          ),
          Text(
            AppFormat.compact(entry.score, localeName),
            style: textTheme.labelSmall!.copyWith(
              color: isFirst ? quizoo.gold : quizoo.tx3,
              fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Container(
            width: double.infinity,
            height: plinthHeight.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFirst ? quizoo.gold.withValues(alpha: 0.18) : quizoo.s2,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.tile.r),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _ordinalFor(l10n, place),
                  style: textTheme.displayMedium!.copyWith(
                    fontSize: isFirst ? 18.sp : 16.sp,
                    color: isFirst ? quizoo.gold : quizoo.tx2,
                  ),
                ),
                if (flag != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    flag,
                    style: AppTypography.glyph(isFirst ? 22.sp : 17.sp),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
