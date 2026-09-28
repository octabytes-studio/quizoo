import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The duel HUD's ✕ — a translucent square on the arena (`.play .hud .x`),
/// shared by the live duel's intro and round views. It only asks; the
/// screen owns the "Leave the duel?" confirmation.
class DuelQuitButton extends StatelessWidget {
  const DuelQuitButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  /// Matches the quiz HUD's chrome buttons.
  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).duelQuitLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size.w,
          height: size.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: arena.chrome,
            borderRadius: BorderRadius.circular(AppRadius.iconButton.r),
          ),
          child: ExcludeSemantics(
            child: Text(
              '✕',
              style: AppTypography.glyph(15.sp, color: arena.onArena),
            ),
          ),
        ),
      ),
    );
  }
}
