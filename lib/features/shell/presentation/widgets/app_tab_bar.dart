import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_elevation.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The persistent bottom navigation: four tabs around a centre FAB.
///
/// Built once and hosted by the shell's `Scaffold.bottomNavigationBar` slot,
/// never as the last child of a Column — that is what keeps it pinned to the
/// bottom of the viewport rather than floating up under short content (§05).
///
/// The centre slot is not a tab. It has no page of its own; tapping it opens
/// the play sheet and rotates the FAB 45° into a close icon.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPlayPressed,
    required this.isPlaySheetOpen,
    super.key,
  });

  /// The active branch, 0…3 — Home, Ranks, Daily, You. The FAB is not one of
  /// them.
  final int currentIndex;

  final ValueChanged<int> onTabSelected;
  final VoidCallback onPlayPressed;

  /// Rotates the FAB into its close state.
  final bool isPlaySheetOpen;

  /// `.tabs .fab` — 58×58.
  static const double fabSize = 58;

  /// How far the FAB lifts above the bar.
  static const double fabOverhang = 24;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    final tabs = <(String, String)>[
      ('🏠', l10n.tabHome),
      ('🏆', l10n.tabRanks),
      ('🎯', l10n.tabDaily),
      ('👤', l10n.tabYou),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: quizoo.s1,
        border: Border(top: BorderSide(color: quizoo.ln)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.w, AppSpacing.sm.h, 6.w, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var branch = 0; branch < 2; branch++)
                Expanded(
                  child: _TabButton(
                    emoji: tabs[branch].$1,
                    label: tabs[branch].$2,
                    isActive: currentIndex == branch,
                    onTap: () => onTabSelected(branch),
                  ),
                ),
              Expanded(
                child: _PlayFab(isOpen: isPlaySheetOpen, onTap: onPlayPressed),
              ),
              for (var branch = 2; branch < 4; branch++)
                Expanded(
                  child: _TabButton(
                    emoji: tabs[branch].$1,
                    label: tabs[branch].$2,
                    isActive: currentIndex == branch,
                    onTap: () => onTabSelected(branch),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the four real tabs. Inactive emoji are desaturated and dimmed so the
/// active tab is the only colour in the bar.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.emoji,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// `filter: grayscale(1)` as a colour matrix.
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    Widget glyph = Text(emoji, style: AppTypography.glyph(21.sp, height: 1));
    if (!isActive) {
      glyph = Opacity(
        opacity: 0.55,
        child: ColorFiltered(colorFilter: _grayscale, child: glyph),
      );
    }

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              glyph,
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: isActive ? quizoo.g : quizoo.tx3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centre FAB. Mango on its own 4px ledge, lifted above the bar, and
/// rotated 45° into a ✕ while the play sheet is open.
class _PlayFab extends StatelessWidget {
  const _PlayFab({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final ledge = AppElevation.ledge.h;

    return Semantics(
      button: true,
      expanded: isOpen,
      label: isOpen ? l10n.playSheetClose : l10n.tabPlay,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: Offset(0, -AppTabBar.fabOverhang.h),
          // `heightFactor: 1` is load-bearing: a bare `Center` expands to the
          // full height it is offered, and `bottomNavigationBar` offers the
          // whole screen. Without it the FAB stretches the tab bar to the
          // viewport height and leaves the shell's body nothing to lay out in.
          child: Center(
            heightFactor: 1,
            child: Container(
              width: AppTabBar.fabSize.w,
              height: AppTabBar.fabSize.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: quizoo.p,
                borderRadius: BorderRadius.circular(AppRadius.card.r),
                boxShadow: [
                  BoxShadow(color: quizoo.pShadow, offset: Offset(0, ledge)),
                ],
              ),
              child: AnimatedRotation(
                duration: AppMotion.durationOf(context, AppMotion.sheet),
                curve: AppMotion.curveOf(context, AppMotion.sheetCurve),
                turns: isOpen ? 0.125 : 0,
                child: Text(
                  isOpen ? '✕' : '⚔️',
                  style: AppTypography.glyph(
                    isOpen ? 22.sp : 26.sp,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
