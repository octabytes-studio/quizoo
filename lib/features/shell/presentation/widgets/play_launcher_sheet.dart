import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-38 — the sheet the centre FAB opens.
///
/// Three ways to start playing, ordered by what the player is most likely to
/// want. Intentionally stateless: it holds no data of its own, it closes
/// itself and routes out through go_router, so the shell stays pure navigation
/// chrome with no Cubit of its own.
class PlayLauncherSheet extends StatelessWidget {
  const PlayLauncherSheet({super.key});

  /// The level a placeholder "Quick Play" drops the player into until the real
  /// tier-matching logic lands in plan 002.
  static const String demoLevelId = 'demo';

  /// Presents the sheet and resolves when it closes.
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      builder: (_) => const PlayLauncherSheet(),
    );
  }

  void _goTo(BuildContext context, String location) {
    Navigator.of(context).pop();
    context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final rowPadding = EdgeInsets.all(14.w);

    return AppBottomSheet(
      title: l10n.playSheetTitle,
      message: l10n.playSheetSubtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListRowTile(
            title: l10n.playSheetDuel,
            subtitle: l10n.playSheetDuelMeta,
            leadingEmoji: '⚔️',
            leadingPlateColor: quizoo.p.withValues(alpha: 0.18),
            accentColor: quizoo.p,
            padding: rowPadding,
            trailing: Text(
              l10n.playSheetGo,
              style: textTheme.bodyLarge!.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: quizoo.p,
              ),
            ),
            onTap: () => _goTo(context, AppRoutes.duelMatchmaking),
          ),
          SizedBox(height: 10.h),
          ListRowTile(
            title: l10n.playSheetQuickPlay,
            subtitle: l10n.playSheetQuickPlayMeta,
            leadingEmoji: '🎲',
            leadingPlateColor: quizoo.g.withValues(alpha: 0.16),
            padding: rowPadding,
            onTap: () => _goTo(context, AppRoutes.quizPlayPath(demoLevelId)),
          ),
          SizedBox(height: 10.h),
          ListRowTile(
            title: l10n.playSheetDaily,
            subtitle: l10n.playSheetDailyMeta,
            leadingEmoji: '🎯',
            leadingPlateColor: quizoo.gold.withValues(alpha: 0.22),
            padding: rowPadding,
            onTap: () => _goTo(context, AppRoutes.daily),
          ),
        ],
      ),
    );
  }
}
