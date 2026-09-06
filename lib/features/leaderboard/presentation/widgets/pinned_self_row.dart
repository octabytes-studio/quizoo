import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The player's own row, pinned **outside the scrollable list, always
/// visible** — a real layout requirement (S-29), not a stylistic choice.
///
/// The caller places this as a fixed sibling of the scrolling roster (never
/// as a `ListView` item), which is what a `PinnedSelfRow`-never-scrolls
/// widget test asserts.
class PinnedSelfRow extends StatelessWidget {
  const PinnedSelfRow({
    required this.isGuest,
    super.key,
    this.entry,
    this.onSignInTap,
  });

  /// Guest branch: no rank exists yet, so the row reads "Not ranked — sign in
  /// to compete" instead of a broken/zero rank.
  final bool isGuest;

  /// Null while [isGuest] is true.
  final LeaderboardEntry? entry;

  final VoidCallback? onSignInTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin.w,
        AppSpacing.xs.h,
        AppSpacing.screenMargin.w,
        AppSpacing.sm.h,
      ),
      child: isGuest
          ? ListRowTile(
              variant: ListRowVariant.self,
              title: l10n.leaderboardSelfGuestTitle,
              subtitle: l10n.leaderboardSelfGuestSubtitle,
              leadingEmoji: '🐼',
              onTap: onSignInTap,
            )
          : ListRowTile(
              variant: ListRowVariant.self,
              title: l10n.leaderboardSelfTitle,
              subtitle: l10n.leaderboardSelfSubtitle(
                entry!.topPercent ?? 0,
                entry!.locationLabel ?? '',
              ),
              leadingEmoji: entry!.avatarEmoji,
              trailingValue: AppFormat.number(entry!.score, localeName),
              trailingLabel: _deltaLabel(entry!.rankDelta),
            ),
    );
  }

  static String? _deltaLabel(int? delta) {
    if (delta == null || delta == 0) return '—';
    return delta > 0 ? '▲ $delta' : '▼ ${delta.abs()}';
  }
}
