import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Stands in for a screen whose real body lands in a later plan.
///
/// Every one of the bible's 54 screen IDs is reachable from the moment the
/// design foundation ships, which is what lets plans 002, 003 and 004 be
/// built and reviewed independently and in any order.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.screen,
    super.key,
    this.isArena = false,
  });

  /// Which of the 54 this is.
  final ScreenRef screen;

  /// Paints the play surface's fixed dark gradient instead of the themed
  /// background.
  ///
  /// The arena is the one place in the app that looks the same in light and
  /// dark, so this branch reads [ArenaColors] and deliberately never touches
  /// `Theme.of(context).brightness`.
  final bool isArena;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final arena = context.arena;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final foreground = isArena ? arena.onArena : quizoo.tx;
    final mutedForeground = isArena
        ? arena.onArena.withValues(alpha: 0.72)
        : quizoo.tx2;

    return Scaffold(
      backgroundColor: isArena ? null : quizoo.s0,
      body: DecoratedBox(
        // The background layer takes no SafeArea — it runs to the physical top
        // of the display (§05). Only the content below insets itself.
        decoration: BoxDecoration(
          gradient: isArena ? arena.base : null,
          color: isArena ? null : quizoo.s0,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.sm.h),
                Row(
                  children: [
                    if (context.canPop())
                      _IconButton(
                        glyph: '←',
                        isArena: isArena,
                        semanticLabel: l10n.commonBack,
                        onTap: context.pop,
                      ),
                    const Spacer(),
                    _IconButton(
                      glyph: '☰',
                      isArena: isArena,
                      semanticLabel: l10n.devScreenIndexTitle,
                      onTap: () => context.push(AppRoutes.screenIndex),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isArena
                        ? arena.chrome
                        : quizoo.g.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    screen.id,
                    style: textTheme.labelSmall!.copyWith(
                      fontFamily: AppTypography.mono,
                      color: isArena ? arena.onArena : quizoo.g,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  screen.name,
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium!.copyWith(color: foreground),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  l10n.devPlaceholderBody(screen.plan),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall!.copyWith(color: mutedForeground),
                ),
                if (screen.isState) ...[
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    l10n.devStateOf(AppRoutes.stateAliases[screen.id]!),
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall!.copyWith(
                      color: mutedForeground,
                    ),
                  ),
                ],
                const Spacer(),
                ChunkyButton.ghost(
                  label: l10n.devScreenIndexTitle,
                  onPressed: () => context.push(AppRoutes.screenIndex),
                ),
                SizedBox(height: AppSpacing.xl.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ib` — the 38px icon button, in its themed and on-arena forms.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.glyph,
    required this.isArena,
    required this.semanticLabel,
    required this.onTap,
  });

  final String glyph;
  final bool isArena;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final arena = context.arena;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38.w,
          height: 38.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isArena ? arena.chrome : quizoo.s1,
            borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
            border: isArena ? null : Border.all(color: quizoo.ln),
            boxShadow: isArena ? null : quizoo.shadow,
          ),
          child: Text(
            glyph,
            style: AppTypography.glyph(
              17.sp,
              color: isArena ? arena.onArena : quizoo.tx,
            ),
          ),
        ),
      ),
    );
  }
}
